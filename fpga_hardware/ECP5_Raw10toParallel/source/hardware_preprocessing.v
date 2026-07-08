// =====================================================================
// FILE: hardware_preprocessing.v   VERSIONE FINALE v6
// IEEE Verilog 1364-2001
//
// FIX CRITICO v6: padding a potenza di 2 per eliminare l'hang del mapper
// =====================================================================
// STORIA DEI FIX:
//   #1 Parentesi mancanti negli indici di pooling
//   #2 Overflow somma pooling [1:0]->[2:0]
//   #3 FSM sincronizzata a i_frame_start
//   #4 Padding statico (elimina clamping dinamico)
//   #5 Driver unici per ogni variabile (elimina CL172)
//   #6 QUESTO FIX: W_224P e W_112P portati a potenza di 2
//
// CAUSA DELL'HANG (v5):
//   W_224P=226 e W_112P=114 NON sono potenze di 2.
//   L'indirizzo BRAM contiene (y+1)*226: il mapper deve sintetizzare
//   la moltiplicazione per 226 come rete di addizionatori, che diventa
//   l'indirizzo dinamico di 9 BRAM contemporaneamente.
//   Risultato: 4.2GB RAM, CPU 100%, mai termina.
//
// SOLUZIONE:
//   W_224P = 256  (potenza di 2 >= 226)
//   W_112P = 128  (potenza di 2 >= 114)
//   L'indirizzo (y+1)*256 + (x+1) e' uno shift di 8 bit:
//   il mapper lo sintetizza come concatenazione di fili -> costo zero.
//   Costo memoria: buf_bin 256x256=65536 bit invece di 226x226=51076
//   (+14KB su 468KB totali EBR ECP5UM-85F = +3%, trascurabile).
//
// MAPPA DRIVER (un always per variabile, regola Synplify CL172):
//   always A  : state
//   always B  : next_state (combinatorio *)
//   always C  : cnt_clear, cnt_load, buf_bin, buf_dil1, buf_pool1, buf_dil2
//   always E  : cnt_proc
//   always F  : buf_pool2
//   always G  : buf_out
//   always H  : o_pixel, o_valid, o_frame_done
//
// PIPELINE:
//   1. Binarizzazione   (verde < THRESHOLD -> 1 nero)
//   2. Dilatazione 3x3  (OR morfologico 224x224)
//   3. Pooling 2x2      (maggioranza 224->112)
//   4. Dilatazione 3x3  (OR morfologico 112x112)
//   5. Pooling 2x2      (maggioranza 112->56)
//   6. Pooling 2x2      (maggioranza 56->28)
// =====================================================================

`timescale 1ns/1ps

module hardware_preprocessing #(
    parameter W_224     = 224,
    parameter W_112     = 112,
    parameter W_56      = 56,
    parameter W_28      = 28,
    parameter THRESHOLD = 100
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  i_pixel,
    input  wire        i_valid,
    output wire        o_ready,
    input  wire        i_frame_start,
    output reg         o_pixel,
    output reg         o_valid,
    input  wire        i_ready,
    output reg         o_frame_done
);

    // -----------------------------------------------------------------
    // Parametri derivati
    //
    // W_224P = 256 = 2^8  (prossima potenza di 2 >= 224+2=226)
    // W_112P = 128 = 2^7  (prossima potenza di 2 >= 112+2=114)
    //
    // Indirizzo con potenza di 2:
    //   addr(y,x) = (y+1)*256 + (x+1) = {(y+1), (x+1)[7:0]}
    //   -> shift puro, nessuna rete di addizionatori
    //   -> il mapper lo riduce a concatenazione di fili: costo ZERO
    //
    // Il bordo "inutile" (colonne 225..255 e righe 225..255) resta a 0
    // per tutto il frame: nessun effetto sul risultato della dilatazione
    // perche' i vicini di un pixel sul bordo reale (y=0 o y=223) che
    // cadono nel padding sono sempre 0 -> OR non li modifica.
    // -----------------------------------------------------------------
    // Tutti i buffer usano larghezze a potenza di 2 per eliminare
    // moltiplicazioni non-potenza-di-2 negli indirizzi BRAM.
    // Il mapper sintetizza (y << SHIFT) come semplice concatenazione
    // di fili — costo zero, zero loop di ottimizzazione.
    localparam W_224P = 256;   // 2^8 >= 224+2=226
    localparam W_112P = 128;   // 2^7 >= 112+2=114
    localparam W_56P  = 64;    // 2^6 >= 56   (buf_pool2 non ha padding, ma usiamo pow2 per coerenza)
    localparam W_28P  = 32;    // 2^5 >= 28   (buf_out)

    localparam SHIFT_224P = 8; // log2(256)
    localparam SHIFT_112P = 7; // log2(128)
    localparam SHIFT_56P  = 6; // log2(64)
    localparam SHIFT_28P  = 5; // log2(32)

    localparam PIXELS_224  = W_224  * W_224;    // 50176
    localparam PIXELS_224P = W_224P * W_224P;   // 65536 (256x256)
    localparam PIXELS_112  = W_112  * W_112;    // 12544
    localparam PIXELS_112P = W_112P * W_112P;   // 16384 (128x128)
    localparam PIXELS_56P  = W_56P  * W_56P;   //  4096 (64x64,  reale 56x56 nell'angolo)
    localparam PIXELS_28P  = W_28P  * W_28P;   //  1024 (32x32,  reale 28x28 nell'angolo)

    // ADDR_W: 16 bit coprono il buffer piu' grande (65536 = 2^16)
    localparam ADDR_W = 16;

    // -----------------------------------------------------------------
    // FSM
    // -----------------------------------------------------------------
    localparam [3:0]
        S_IDLE   = 4'd0,
        S_CLEAR1 = 4'd1,
        S_LOAD   = 4'd2,
        S_DIL1   = 4'd3,
        S_CLEAR2 = 4'd4,
        S_POOL1  = 4'd5,
        S_DIL2   = 4'd6,
        S_CLEAR3 = 4'd7,
        S_POOL2  = 4'd8,
        S_POOL3  = 4'd9,
        S_OUTPUT = 4'd10;

    reg [3:0] state, next_state;

    // -----------------------------------------------------------------
    // Buffer BRAM
    // -----------------------------------------------------------------
    (* ram_style = "block" *) reg [0:0] buf_bin  [0:PIXELS_224P-1]; // 256x256
    (* ram_style = "block" *) reg [0:0] buf_dil1 [0:PIXELS_224P-1]; // 256x256
    (* ram_style = "block" *) reg [0:0] buf_pool1[0:PIXELS_112P-1]; // 128x128
    (* ram_style = "block" *) reg [0:0] buf_dil2 [0:PIXELS_112P-1]; // 128x128
    (* ram_style = "block" *) reg [0:0] buf_pool2[0:PIXELS_56P -1]; // 64x64 (area utile 56x56)
    (* ram_style = "block" *) reg [0:0] buf_out  [0:PIXELS_28P -1]; // 32x32 (area utile 28x28)

    // -----------------------------------------------------------------
    // Contatori
    // -----------------------------------------------------------------
    reg [ADDR_W-1:0] cnt_clear;
    reg [ADDR_W-1:0] cnt_load;
    reg [ADDR_W-1:0] cnt_proc;

    assign o_ready = (state == S_LOAD);

    // =================================================================
    // always A — stato FSM
    // =================================================================
    always @(posedge clk) begin
        if (!rst_n) state <= S_IDLE;
        else        state <= next_state;
    end

    // =================================================================
    // always B — transizioni FSM (combinatorio)
    //
    // Cicli di clear:
    //   S_CLEAR1: PIXELS_224P = 65536 cicli (azzera intero buf_bin)
    //   S_CLEAR2: 2*W_224P + W_224 = 736 cicli (perimetro buf_dil1+buf_pool1)
    //   S_CLEAR3: 2*W_112P + W_112 = 368 cicli (perimetro buf_dil2)
    // =================================================================
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:   if (i_frame_start)                             next_state = S_CLEAR1;
            S_CLEAR1: if (cnt_clear == PIXELS_224P - 1)              next_state = S_LOAD;
            S_LOAD:   if (cnt_load  == PIXELS_224  - 1 && i_valid)   next_state = S_DIL1;
            S_DIL1:   if (cnt_proc  == PIXELS_224  - 1)              next_state = S_CLEAR2;
            S_CLEAR2: if (cnt_clear == 2*W_224P + W_224 - 1)         next_state = S_POOL1;
            S_POOL1:  if (cnt_proc  == PIXELS_112  - 1)              next_state = S_DIL2;
            S_DIL2:   if (cnt_proc  == PIXELS_112  - 1)              next_state = S_CLEAR3;
            S_CLEAR3: if (cnt_clear == 2*W_112P + W_112 - 1)         next_state = S_POOL2;
            S_POOL2:  if (cnt_proc  == PIXELS_56   - 1)              next_state = S_POOL3;  // scrive 56*56 pixel nell'area utile di buf_pool2
            S_POOL3:  if (cnt_proc  == PIXELS_28   - 1)              next_state = S_OUTPUT; // scrive 28*28 pixel nell'area utile di buf_out
            S_OUTPUT: if (cnt_proc  == PIXELS_28   - 1 && i_ready)   next_state = S_IDLE;
            default:                                                  next_state = S_IDLE;
        endcase
    end

    // =================================================================
    // always C — driver unico per:
    //   cnt_clear, cnt_load, buf_bin, buf_dil1, buf_pool1, buf_dil2
    //
    // INDIRIZZI CON POTENZA DI 2 (cuore del fix #6):
    //
    //   buf_bin/buf_dil1 (256x256):
    //     centro  = {(y+1)[7:0], (x+1)[7:0]}  (= (y+1)<<8 + (x+1))
    //     su/giu' = centro +/- 256             (= centro +/- W_224P)
    //     sx/dx   = centro +/- 1
    //     -> TUTTE SOMME CON COSTANTI 1 e 256, nessuna moltiplicazione
    //
    //   buf_pool1/buf_dil2 (128x128):
    //     centro  = {(y+1)[6:0], (x+1)[6:0]}  (= (y+1)<<7 + (x+1))
    //     su/giu' = centro +/- 128
    //     sx/dx   = centro +/- 1
    // =================================================================

    // ---- Indirizzi load (buf_bin, area utile 224x224 dentro 256x256) ----
    wire [7:0]        load_x    = cnt_load[7:0] % W_224;   // 0..223
    wire [7:0]        load_y    = cnt_load[7:0] / W_224;   // potrebbe overflow, usiamo full width
    // Per W_224=224 servono 8 bit per x e 8 bit per y:
    // Usiamo divisione/modulo su cnt_load a larghezza piena
    wire [ADDR_W-1:0] load_x_w  = cnt_load % W_224;
    wire [ADDR_W-1:0] load_y_w  = cnt_load / W_224;
    // Indirizzo con shift: (y+1)*256 + (x+1) = {load_y_w+1, load_x_w+1} su 16 bit
    wire [ADDR_W-1:0] load_addr = ((load_y_w + 1) << SHIFT_224P) | (load_x_w + 1);

    // ---- Indirizzi dilatazione 1 (buf_bin->buf_dil1, 256x256) ----
    wire [ADDR_W-1:0] dy1_y_w = cnt_proc / W_224;
    wire [ADDR_W-1:0] dy1_x_w = cnt_proc % W_224;
    wire [ADDR_W-1:0] dy1_c   = ((dy1_y_w + 1) << SHIFT_224P) | (dy1_x_w + 1);
    // I 9 vicini sono dy1_c +/- 1 e +/- W_224P(=256): COSTANTI
    // Synplify le vede come semplici somme di costanti -> mapping diretto BRAM

    // ---- Indirizzi pooling 1 (buf_dil1->buf_pool1, 256x256->128x128) ----
    wire [ADDR_W-1:0] p1_y_w  = cnt_proc / W_112;
    wire [ADDR_W-1:0] p1_x_w  = cnt_proc % W_112;
    // I 4 pixel 2x2 nel buffer 256x256 centrato a (2*p1_y, 2*p1_x):
    wire [ADDR_W-1:0] p1_a00  = ((p1_y_w*2    +1) << SHIFT_224P) | (p1_x_w*2    +1);
    wire [ADDR_W-1:0] p1_a01  = ((p1_y_w*2    +1) << SHIFT_224P) | (p1_x_w*2+1  +1);
    wire [ADDR_W-1:0] p1_a10  = ((p1_y_w*2+1  +1) << SHIFT_224P) | (p1_x_w*2    +1);
    wire [ADDR_W-1:0] p1_a11  = ((p1_y_w*2+1  +1) << SHIFT_224P) | (p1_x_w*2+1  +1);
    wire [2:0]        p1_sum  = {2'b0, buf_dil1[p1_a00]} + {2'b0, buf_dil1[p1_a01]}
                               + {2'b0, buf_dil1[p1_a10]} + {2'b0, buf_dil1[p1_a11]};
    // Scrittura pooling1 nel buffer 128x128:
    wire [ADDR_W-1:0] p1_wr   = ((p1_y_w + 1) << SHIFT_112P) | (p1_x_w + 1);

    // ---- Indirizzi dilatazione 2 (buf_pool1->buf_dil2, 128x128) ----
    wire [ADDR_W-1:0] dy2_y_w = cnt_proc / W_112;
    wire [ADDR_W-1:0] dy2_x_w = cnt_proc % W_112;
    wire [ADDR_W-1:0] dy2_c   = ((dy2_y_w + 1) << SHIFT_112P) | (dy2_x_w + 1);

    always @(posedge clk) begin
        if (!rst_n || state == S_IDLE) begin
            cnt_clear <= 0;
            cnt_load  <= 0;

        // ---- S_CLEAR1: azzera tutto buf_bin (65536 cicli) ----
        end else if (state == S_CLEAR1) begin
            buf_bin[cnt_clear] <= 1'b0;
            cnt_clear <= cnt_clear + 1;
            cnt_load  <= 0;

        // ---- S_LOAD: binarizza -> area utile buf_bin ----
        end else if (state == S_LOAD) begin
            cnt_clear <= 0;
            if (i_valid) begin
                buf_bin[load_addr] <= (i_pixel < THRESHOLD) ? 1'b1 : 1'b0;
                cnt_load <= cnt_load + 1;
            end

        // ---- S_DIL1: OR 3x3 buf_bin -> buf_dil1 ----
        end else if (state == S_DIL1) begin
            cnt_clear <= 0;
            buf_dil1[dy1_c] <=
                buf_bin[dy1_c - W_224P - 1] | buf_bin[dy1_c - W_224P] | buf_bin[dy1_c - W_224P + 1] |
                buf_bin[dy1_c          - 1] | buf_bin[dy1_c]          | buf_bin[dy1_c          + 1] |
                buf_bin[dy1_c + W_224P - 1] | buf_bin[dy1_c + W_224P] | buf_bin[dy1_c + W_224P + 1];

        // ---- S_CLEAR2: perimetro buf_dil1 + buf_pool1 ----
        end else if (state == S_CLEAR2) begin
            // -- perimetro buf_dil1 (256 wide, bordo reale a x=0,255 e y=0,255) --
            if (cnt_clear < W_224P) begin
                buf_dil1[cnt_clear] <= 1'b0;                                             // riga y=0
            end else if (cnt_clear < 2*W_224P) begin
                buf_dil1[(W_224+1)*W_224P + (cnt_clear - W_224P)] <= 1'b0;               // riga y=225
            end else begin
                buf_dil1[(cnt_clear - 2*W_224P + 1) * W_224P + 0]         <= 1'b0;       // col x=0
                buf_dil1[(cnt_clear - 2*W_224P + 1) * W_224P + (W_224+1)] <= 1'b0;       // col x=225
            end
            // -- perimetro buf_pool1 (128 wide) in parallelo --
            if (cnt_clear < W_112P) begin
                buf_pool1[cnt_clear] <= 1'b0;
            end else if (cnt_clear < 2*W_112P) begin
                buf_pool1[(W_112+1)*W_112P + (cnt_clear - W_112P)] <= 1'b0;
            end else if (cnt_clear < 2*W_112P + W_112) begin
                buf_pool1[(cnt_clear - 2*W_112P + 1) * W_112P + 0]         <= 1'b0;
                buf_pool1[(cnt_clear - 2*W_112P + 1) * W_112P + (W_112+1)] <= 1'b0;
            end
            cnt_clear <= cnt_clear + 1;

        // ---- S_POOL1: 2x2 buf_dil1 -> buf_pool1 ----
        end else if (state == S_POOL1) begin
            cnt_clear <= 0;
            buf_pool1[p1_wr] <= (p1_sum >= 2) ? 1'b1 : 1'b0;

        // ---- S_DIL2: OR 3x3 buf_pool1 -> buf_dil2 ----
        end else if (state == S_DIL2) begin
            cnt_clear <= 0;
            buf_dil2[dy2_c] <=
                buf_pool1[dy2_c - W_112P - 1] | buf_pool1[dy2_c - W_112P] | buf_pool1[dy2_c - W_112P + 1] |
                buf_pool1[dy2_c           - 1] | buf_pool1[dy2_c]          | buf_pool1[dy2_c           + 1] |
                buf_pool1[dy2_c + W_112P - 1]  | buf_pool1[dy2_c + W_112P] | buf_pool1[dy2_c + W_112P + 1];

        // ---- S_CLEAR3: perimetro buf_dil2 ----
        end else if (state == S_CLEAR3) begin
            if (cnt_clear < W_112P) begin
                buf_dil2[cnt_clear] <= 1'b0;
            end else if (cnt_clear < 2*W_112P) begin
                buf_dil2[(W_112+1)*W_112P + (cnt_clear - W_112P)] <= 1'b0;
            end else begin
                buf_dil2[(cnt_clear - 2*W_112P + 1) * W_112P + 0]         <= 1'b0;
                buf_dil2[(cnt_clear - 2*W_112P + 1) * W_112P + (W_112+1)] <= 1'b0;
            end
            cnt_clear <= cnt_clear + 1;
        end
    end

    // =================================================================
    // always E — driver unico per cnt_proc
    // =================================================================
    always @(posedge clk) begin
        if (!rst_n || state == S_IDLE || state == S_CLEAR1 ||
            state == S_LOAD  || state == S_CLEAR2 || state == S_CLEAR3)
            cnt_proc <= 0;
        else begin
            case (state)
                S_DIL1:   cnt_proc <= (cnt_proc == PIXELS_224-1) ? 0 : cnt_proc + 1;
                S_POOL1:  cnt_proc <= (cnt_proc == PIXELS_112-1) ? 0 : cnt_proc + 1;
                S_DIL2:   cnt_proc <= (cnt_proc == PIXELS_112-1) ? 0 : cnt_proc + 1;
                S_POOL2:  cnt_proc <= (cnt_proc == PIXELS_56 -1) ? 0 : cnt_proc + 1;
                S_POOL3:  cnt_proc <= (cnt_proc == PIXELS_28 -1) ? 0 : cnt_proc + 1;
                S_OUTPUT: if (i_ready)
                    cnt_proc <= (cnt_proc == PIXELS_28-1) ? 0 : cnt_proc + 1;
                default:  cnt_proc <= 0;
            endcase
        end
    end

    // =================================================================
    // always F — driver unico per buf_pool2 (POOL2: 112x112->56x56)
    // Legge da buf_dil2 (128x128), scrive in buf_pool2 (56x56, no pad).
    // =================================================================
    // POOL2: 112x112 -> 56x56
    // Legge da buf_dil2 (128x128, shift 7).
    // Scrive in buf_pool2 (64x64, shift 6): addr = (y << 6) | x
    // cnt_proc scorre 0..PIXELS_56-1 = 0..3135 (56*56 pixel utili)
    wire [ADDR_W-1:0] p2_y_w  = cnt_proc / W_56;   // 0..55
    wire [ADDR_W-1:0] p2_x_w  = cnt_proc % W_56;   // 0..55
    // Lettura da buf_dil2 (128x128, padding +1): addr=(y+1)<<7|(x+1)
    wire [ADDR_W-1:0] p2_a00  = ((p2_y_w*2    +1) << SHIFT_112P) | (p2_x_w*2    +1);
    wire [ADDR_W-1:0] p2_a01  = ((p2_y_w*2    +1) << SHIFT_112P) | (p2_x_w*2+1  +1);
    wire [ADDR_W-1:0] p2_a10  = ((p2_y_w*2+1  +1) << SHIFT_112P) | (p2_x_w*2    +1);
    wire [ADDR_W-1:0] p2_a11  = ((p2_y_w*2+1  +1) << SHIFT_112P) | (p2_x_w*2+1  +1);
    wire [2:0]        p2_sum  = {2'b0, buf_dil2[p2_a00]} + {2'b0, buf_dil2[p2_a01]}
                               + {2'b0, buf_dil2[p2_a10]} + {2'b0, buf_dil2[p2_a11]};
    // Scrittura in buf_pool2 (64x64): addr = (y << 6) | x
    wire [ADDR_W-1:0] p2_wr   = (p2_y_w << SHIFT_56P) | p2_x_w;

    always @(posedge clk) begin
        if (state == S_POOL2)
            buf_pool2[p2_wr] <= (p2_sum >= 2) ? 1'b1 : 1'b0;
    end

    // =================================================================
    // always G — driver unico per buf_out (POOL3: 56x56->28x28)
    // Entrambi i buffer senza padding: indici lineari semplici.
    // p3_y*2+1 non contiene moltiplicazioni per costanti non-pow2:
    // W_56=56=8*7, ma qui non moltiplichiamo per W_56 nell'indirizzo
    // di lettura, solo per W_56 nell'indirizzo di scrittura che e'
    // sequenziale (cnt_proc). Il calcolo p3_y*W_56 + p3_x per la
    // lettura e' ancora presente; W_56=56=64-8, sintetizzabile
    // efficacemente come (p3_y<<6) - (p3_y<<3). Synplify lo gestisce.
    // =================================================================
    // POOL3: 56x56 -> 28x28
    // Legge da buf_pool2 (64x64, shift 6): addr = (y << 6) | x
    // Scrive in buf_out  (32x32, shift 5): addr = (y << 5) | x
    // cnt_proc scorre 0..PIXELS_28-1 = 0..783 (28*28 pixel utili)
    wire [ADDR_W-1:0] p3_y_w = cnt_proc / W_28;   // 0..27
    wire [ADDR_W-1:0] p3_x_w = cnt_proc % W_28;   // 0..27
    // Lettura da buf_pool2 (64x64): i 4 pixel 2x2 a (2*y, 2*x)
    wire [ADDR_W-1:0] p3_a00 = ( p3_y_w*2      << SHIFT_56P) |  p3_x_w*2;
    wire [ADDR_W-1:0] p3_a01 = ( p3_y_w*2      << SHIFT_56P) | (p3_x_w*2+1);
    wire [ADDR_W-1:0] p3_a10 = ((p3_y_w*2+1)   << SHIFT_56P) |  p3_x_w*2;
    wire [ADDR_W-1:0] p3_a11 = ((p3_y_w*2+1)   << SHIFT_56P) | (p3_x_w*2+1);
    wire [2:0] p3_sum =
        {2'b0, buf_pool2[p3_a00]} + {2'b0, buf_pool2[p3_a01]} +
        {2'b0, buf_pool2[p3_a10]} + {2'b0, buf_pool2[p3_a11]};
    // Scrittura in buf_out (32x32): addr = (y << 5) | x
    wire [ADDR_W-1:0] p3_wr = (p3_y_w << SHIFT_28P) | p3_x_w;

    always @(posedge clk) begin
        if (state == S_POOL3)
            buf_out[p3_wr] <= (p3_sum >= 2) ? 1'b1 : 1'b0;
    end

    // =================================================================
    // always H — driver unico per o_pixel, o_valid, o_frame_done
    // =================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            o_pixel      <= 1'b0;
            o_valid      <= 1'b0;
            o_frame_done <= 1'b0;
        end else if (state == S_OUTPUT) begin
            // Legge buf_out (32x32): addr = (y << 5) | x
            // cnt_proc 0..783, y=cnt_proc/28, x=cnt_proc%28
            o_valid      <= 1'b1;
            o_pixel      <= buf_out[((cnt_proc / W_28) << SHIFT_28P) | (cnt_proc % W_28)];
            o_frame_done <= (cnt_proc == PIXELS_28-1) && i_ready;
        end else begin
            o_valid      <= 1'b0;
            o_frame_done <= 1'b0;
        end
    end

endmodule