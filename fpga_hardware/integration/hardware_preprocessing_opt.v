// ============================================================================
// FILE    : hardware_preprocessing_opt.v
// PROJECT : ECP5 Number Recogniser
// TARGET  : Lattice ECP5 @ 148.5 MHz (Lattice Diamond / Synplify-Pro)
//
// FUNZIONE:
//   Riceve pixel 8-bit dal canale verde dell'ISP (de-bayered), esegue:
//   1. Binarizzazione (soglia THRESHOLD)
//   2. Dilatazione morfologica 3x3 su immagine 224x224
//   3. Max-pooling 2x2 → 112x112
//   4. Dilatazione morfologica 3x3 su immagine 112x112
//   5. Max-pooling 2x2 → 56x56
//   6. Max-pooling 2x2 → 28x28
//   7. Output seriale bit-per-bit con segnale o_valid
//
// BUG CORRETTI rispetto alla versione originale:
//   [A] Array BRAM da [0:0] a [7:0] → forza inferenza EBR (non SLICE FF)
//   [B] lb_dil1 da [449:0] (450 bit) a [448:0] (449 bit = 2×224+1)
//       e shift corretto da [448:0] a [447:0]
//   [C] Data-path con 'else begin reg<=reg end' esplicito → no latch
//   [D] Guard py>=1 sul pooling → evita scrittura con lb non ancora pieno
//   [E] Output registrato su i_ready: legge buf_out[cnt_out] PRIMA
//       di incrementare cnt_out, via lettura combinatoria con FF output
//   [F] FSM: contatori non resettati su state==S_IDLE ma solo on rst_n
//       (evita auto-reset infinito se i_frame_start non arriva)
// ============================================================================

`timescale 1ns / 1ps

module hardware_preprocessing_opt #(
    parameter W_224     = 224,
    parameter W_112     = 112,
    parameter W_56      = 56,
    parameter W_28      = 28,
    parameter THRESHOLD = 100
)(
    input  wire        clk,
    input  wire        rst_n,

    // Input
    input  wire [7:0]  i_pixel,
    input  wire        i_valid,
    output wire        o_ready,
    input  wire        i_frame_start,

    // Output seriale 28x28
    output reg         o_pixel,
    output reg         o_valid,
    input  wire        i_ready
);

    // =========================================================================
    // COSTANTI
    // =========================================================================
    localparam integer PIXELS_224 = W_224 * W_224;   // 50176
    localparam integer PIXELS_112 = W_112 * W_112;   // 12544
    localparam integer PIXELS_56  = W_56  * W_56;    //  3136
    localparam integer PIXELS_28  = W_28  * W_28;    //   784

    // =========================================================================
    // FSM
    // =========================================================================
    localparam [2:0]
        S_IDLE   = 3'd0,
        S_LOAD   = 3'd1,
        S_DIL1   = 3'd2,
        S_POOL1  = 3'd3,
        S_DIL2   = 3'd4,
        S_POOL2  = 3'd5,
        S_POOL3  = 3'd6,
        S_OUTPUT = 3'd7;

    reg [2:0] state, next_state;

    // =========================================================================
    // BRAM BUFFERS [BUG-A]
    // Width = 8-bit: Synplify-Pro inferisce correttamente gli EBR Lattice.
    // Con [0:0] i tool spesso non mappano su EBR (troppo stretti → SLICE FF).
    // Usiamo solo bit[0] per i dati; i restanti 7 bit tengono il BRAM attivo.
    // =========================================================================
    (* ram_style = "block" *) reg [7:0] buf_bin  [0:PIXELS_224-1];
    (* ram_style = "block" *) reg [7:0] buf_dil1 [0:PIXELS_224-1];
    (* ram_style = "block" *) reg [7:0] buf_pool1[0:PIXELS_112-1];
    (* ram_style = "block" *) reg [7:0] buf_dil2 [0:PIXELS_112-1];
    (* ram_style = "block" *) reg [7:0] buf_pool2[0:PIXELS_56 -1];
    (* ram_style = "block" *) reg [7:0] buf_out  [0:PIXELS_28 -1];

    // =========================================================================
    // SHIFT-REGISTER LINE BUFFERS [BUG-B]
    //
    // lb_dil1  : finestra 3×3 su riga di 224 pixel → 2×224+1 = 449 celle
    //            Indici attivi: [0]=pixel corrente-1, [1]=pixel corrente-2,
    //            [223]=pixel riga-precedente, [224]=pixel riga-precedente-1,
    //            [225]=pixel riga-precedente-2, [447]=2 righe fa,
    //            [448]=2 righe fa - 1
    //            NOTA: originale dichiarava [449:0]=450 bit e leggeva [449]
    //            che era sempre 0 (bit extra). Corretto a [448:0]=449 bit.
    //
    // lb_dil2  : finestra 3×3 su riga di 112 pixel → 2×112+1 = 225 celle
    //            NOTA: originale dichiarava [225:0]=226 bit. Corretto a
    //            [224:0]=225 bit.
    // =========================================================================
    reg [448:0] lb_dil1;   // 449 bit: 2×224+1
    reg [224:0] lb_pool1;  // 225 bit: 224+1
    reg [224:0] lb_dil2;   // 225 bit: 2×112+1
    reg [112:0] lb_pool2;  // 113 bit: 112+1
    reg [56:0]  lb_pool3;  //  57 bit: 56+1

    // =========================================================================
    // CONTATORI
    // =========================================================================
    reg [15:0] cnt_proc;   // pixel sorgente (indice EBR lettura/scrittura)
    reg [15:0] cnt_out;    // pixel destinazione
    reg [7:0]  px;         // coordinata X (0..W-1)
    reg [7:0]  py;         // coordinata Y (0..H-1)

    // =========================================================================
    // o_ready: segnala al produttore che siamo pronti a ricevere
    // =========================================================================
    assign o_ready = (state == S_LOAD);

    // =========================================================================
    // FSM NEXT-STATE (combinatoria)
    // =========================================================================
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:
                if (i_frame_start) next_state = S_LOAD;
            S_LOAD:
                // Attende l'ultimo pixel valido del frame 224×224
                if (i_valid && cnt_proc == PIXELS_224 - 1) next_state = S_DIL1;
            S_DIL1:
                if (cnt_proc == PIXELS_224 - 1) next_state = S_POOL1;
            S_POOL1:
                // Scorre ancora 224×224 pixel (legge da buf_dil1)
                if (cnt_proc == PIXELS_224 - 1) next_state = S_DIL2;
            S_DIL2:
                if (cnt_proc == PIXELS_112 - 1) next_state = S_POOL2;
            S_POOL2:
                if (cnt_proc == PIXELS_112 - 1) next_state = S_POOL3;
            S_POOL3:
                if (cnt_proc == PIXELS_56 - 1)  next_state = S_OUTPUT;
            S_OUTPUT:
                // Fine output quando abbiamo inviato tutti i 784 pixel
                if (i_ready && cnt_out == PIXELS_28 - 1) next_state = S_IDLE;
            default:
                next_state = S_IDLE;
        endcase
    end

    // Registro di stato
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S_IDLE;
        else        state <= next_state;
    end

    // =========================================================================
    // RESET CONTATORI al cambio di stato o al reset
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_proc <= 16'd0; cnt_out <= 16'd0;
            px <= 8'd0; py <= 8'd0;
        end else if (state != next_state) begin
            // Nuovo stato: azzera contatori
            cnt_proc <= 16'd0; cnt_out <= 16'd0;
            px <= 8'd0; py <= 8'd0;
        end else begin
            case (state)
                S_LOAD: begin
                    if (i_valid) cnt_proc <= cnt_proc + 16'd1;
                end

                S_DIL1: begin
                    cnt_proc <= cnt_proc + 16'd1;
                end

                S_POOL1: begin
                    cnt_proc <= cnt_proc + 16'd1;
                    // Aggiorna coordinate 2D
                    if (px == W_224 - 1) begin
                        px <= 8'd0;
                        py <= py + 8'd1;
                    end else begin
                        px <= px + 8'd1;
                    end
                    // Avanza cnt_out solo su pixel di un blocco 2×2 valido
                    // [BUG-D] py >= 1 garantisce che il line-buffer sia pieno
                    if (px[0] && py[0] && py >= 8'd1)
                        cnt_out <= cnt_out + 16'd1;
                end

                S_DIL2: begin
                    cnt_proc <= cnt_proc + 16'd1;
                end

                S_POOL2: begin
                    cnt_proc <= cnt_proc + 16'd1;
                    if (px == W_112 - 1) begin
                        px <= 8'd0;
                        py <= py + 8'd1;
                    end else begin
                        px <= px + 8'd1;
                    end
                    if (px[0] && py[0] && py >= 8'd1)
                        cnt_out <= cnt_out + 16'd1;
                end

                S_POOL3: begin
                    cnt_proc <= cnt_proc + 16'd1;
                    if (px == W_56 - 1) begin
                        px <= 8'd0;
                        py <= py + 8'd1;
                    end else begin
                        px <= px + 8'd1;
                    end
                    if (px[0] && py[0] && py >= 8'd1)
                        cnt_out <= cnt_out + 16'd1;
                end

                S_OUTPUT: begin
                    if (i_ready) cnt_out <= cnt_out + 16'd1;
                end

                default: begin end
            endcase
        end
    end

    // =========================================================================
    // SOMMATORI POOLING (max-pooling con soma ≥ 2 su finestra 2×2)
    // Usa 1 accesso EBR (pixel corrente) + 3 tap dello shift register.
    // =========================================================================
    wire [2:0] sum_p1 =   {2'b0, buf_dil1 [cnt_proc][0]}
                        + {2'b0, lb_pool1[0]}
                        + {2'b0, lb_pool1[223]}
                        + {2'b0, lb_pool1[224]};

    wire [2:0] sum_p2 =   {2'b0, buf_dil2 [cnt_proc][0]}
                        + {2'b0, lb_pool2[0]}
                        + {2'b0, lb_pool2[111]}
                        + {2'b0, lb_pool2[112]};

    wire [2:0] sum_p3 =   {2'b0, buf_pool2[cnt_proc][0]}
                        + {2'b0, lb_pool3[0]}
                        + {2'b0, lb_pool3[55]}
                        + {2'b0, lb_pool3[56]};

    // =========================================================================
    // DATA PATH  [BUG-C]: ogni branch ha un 'default' esplicito che
    //   mantiene il valore del registro → nessun latch inferito da Synplify.
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lb_dil1  <= {449{1'b0}};
            lb_pool1 <= {225{1'b0}};
            lb_dil2  <= {225{1'b0}};
            lb_pool2 <= {113{1'b0}};
            lb_pool3 <= {57{1'b0}};
        end else begin
            // Default: mantieni i valori (no latch)
            lb_dil1  <= lb_dil1;
            lb_pool1 <= lb_pool1;
            lb_dil2  <= lb_dil2;
            lb_pool2 <= lb_pool2;
            lb_pool3 <= lb_pool3;

            case (state)
                // ─────────────────────────────────────────────────────────
                // S_LOAD: binarizza e scrivi in buf_bin
                // ─────────────────────────────────────────────────────────
                S_LOAD: begin
                    if (i_valid)
                        buf_bin[cnt_proc] <= (i_pixel < THRESHOLD) ? 8'h01 : 8'h00;
                end

                // ─────────────────────────────────────────────────────────
                // S_DIL1: dilatazione morfologica 3×3 su 224×224
                //   Shift register layout (MSB = più recente):
                //   [0]   = pixel t-1        (vicino orizzontale)
                //   [1]   = pixel t-2
                //   [223] = pixel riga-1 col+1
                //   [224] = pixel riga-1 col
                //   [225] = pixel riga-1 col-1
                //   [447] = pixel riga-2 col+1
                //   [448] = pixel riga-2 col   ← corretto (era [449])
                // ─────────────────────────────────────────────────────────
                S_DIL1: begin
                    lb_dil1 <= {lb_dil1[447:0], buf_bin[cnt_proc][0]};
                    buf_dil1[cnt_proc] <= {7'b0,
                          buf_bin[cnt_proc][0]
                        | lb_dil1[0]   | lb_dil1[1]
                        | lb_dil1[223] | lb_dil1[224] | lb_dil1[225]
                        | lb_dil1[447] | lb_dil1[448]
                    };
                end

                // ─────────────────────────────────────────────────────────
                // S_POOL1: max-pooling 2×2 → scrive in buf_pool1
                //   [BUG-D] Scrive SOLO quando py >= 1 (lb valido)
                // ─────────────────────────────────────────────────────────
                S_POOL1: begin
                    lb_pool1 <= {lb_pool1[223:0], buf_dil1[cnt_proc][0]};
                    if (px[0] && py[0] && py >= 8'd1)
                        buf_pool1[cnt_out] <= {7'b0, (sum_p1 >= 3'd2) ? 1'b1 : 1'b0};
                end

                // ─────────────────────────────────────────────────────────
                // S_DIL2: dilatazione morfologica 3×3 su 112×112
                // ─────────────────────────────────────────────────────────
                S_DIL2: begin
                    lb_dil2 <= {lb_dil2[223:0], buf_pool1[cnt_proc][0]};
                    buf_dil2[cnt_proc] <= {7'b0,
                          buf_pool1[cnt_proc][0]
                        | lb_dil2[0]   | lb_dil2[1]
                        | lb_dil2[111] | lb_dil2[112] | lb_dil2[113]
                        | lb_dil2[223] | lb_dil2[224]
                    };
                end

                // ─────────────────────────────────────────────────────────
                // S_POOL2: max-pooling 2×2 → scrive in buf_pool2
                // ─────────────────────────────────────────────────────────
                S_POOL2: begin
                    lb_pool2 <= {lb_pool2[111:0], buf_dil2[cnt_proc][0]};
                    if (px[0] && py[0] && py >= 8'd1)
                        buf_pool2[cnt_out] <= {7'b0, (sum_p2 >= 3'd2) ? 1'b1 : 1'b0};
                end

                // ─────────────────────────────────────────────────────────
                // S_POOL3: max-pooling 2×2 → scrive in buf_out (28×28)
                // ─────────────────────────────────────────────────────────
                S_POOL3: begin
                    lb_pool3 <= {lb_pool3[55:0], buf_pool2[cnt_proc][0]};
                    if (px[0] && py[0] && py >= 8'd1)
                        buf_out[cnt_out] <= {7'b0, (sum_p3 >= 3'd2) ? 1'b1 : 1'b0};
                end

                default: begin end
            endcase
        end
    end

    // =========================================================================
    // OUTPUT STAGE  [BUG-E]
    // Legge buf_out[cnt_out] in modo combinatorio; registra l'uscita.
    // cnt_out viene incrementato il ciclo DOPO l'uscita → lettura corretta.
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_valid <= 1'b0;
            o_pixel <= 1'b0;
        end else if (state == S_OUTPUT && i_ready) begin
            o_valid <= 1'b1;
            o_pixel <= buf_out[cnt_out][0];
        end else begin
            o_valid <= 1'b0;
            o_pixel <= 1'b0;
        end
    end

endmodule
