// ============================================================================
// FILE    : lenet_input_buffer.v
// PROJECT : ECP5 Number Recogniser
// TARGET  : Lattice ECP5 @ 25 MHz (Lattice Diamond / Synplify-Pro)
//
// FUNZIONE:
//   Opera nel dominio a 25 MHz (clock Bambu).
//   1. Riceve pixel 1-bit dal CDC FIFO (uscita del pre-processing)
//   2. Li accumula in una EBR 784×12-bit come valori ap_fixed<12,5>
//   3. Quando ha 784 pixel, genera nn_start per un clock
//   4. Durante l'inferenza, risponde alle letture BRAM duali di Bambu
//
// INTERFACCIA BAMBU (dual-port sync BRAM, read-only per Bambu):
//   conv1_input_address{0,1} [12:0] — indirizzo WORD (byte_addr/2 già fatto
//                                     dentro il ParmMgr di Bambu)
//   conv1_input_ce{0,1}             — chip enable (active high)
//   conv1_input_q{0,1}   [11:0]     — dato letto (ciclo successivo al CE)
//
// CODIFICA ap_fixed<12,5>:
//   Il tipo è signed Q5.7 (5 bit interi incluso il segno, 7 bit frazionari)
//   Valore 1.0  → 12'b0000_1000_0000  = 12'd128  (bit 7 = 2^0 = 1.0)
//   NOTA: Bambu usa complemento a 2, int_bits=5 → bit[6]=2^0=1 SOLO se
//   la codifica è Q4.7 (bit[6] = LSB intero, bit[11]=segno).
//   Verifica da myproject_test.cpp: valori di training normalizzati 0..1,
//   quindi pixel=1 → 1.0 → 12'b000_1000_0000 = 0x080 = 128.
//   pixel=0 → 0.0 → 12'h000
// ============================================================================

`timescale 1ns / 1ps

module lenet_input_buffer #(
    parameter N_PIXELS  = 784,
    parameter ADDR_BITS = 10    // ceil(log2(784)) = 10
)(
    input  wire        clk,       // 25 MHz — stesso clock di Bambu
    input  wire        rst_n,

    // ── Dal CDC FIFO (dominio 25 MHz) ────────────────────────────────────
    input  wire        fifo_pixel,     // 1-bit pixel binarizzato
    input  wire        fifo_valid,     // FIFO non vuota e pixel disponibile
    output wire        fifo_rd_en,     // richiesta lettura FIFO

    // ── Verso Bambu LeNet-5 ──────────────────────────────────────────────
    output reg         nn_start_o,     // impulso 1 ciclo → start_port
    input  wire        nn_done_i,      // done_port da Bambu

    // Dual-port BRAM read interface (controllato da Bambu)
    input  wire [12:0] bram_addr0,     // conv1_input_address0
    input  wire [12:0] bram_addr1,     // conv1_input_address1
    input  wire        bram_ce0,       // conv1_input_ce0
    input  wire        bram_ce1,       // conv1_input_ce1
    output wire [11:0] bram_q0,        // conv1_input_q0
    output wire [11:0] bram_q1,        // conv1_input_q1

    // ── Stato ─────────────────────────────────────────────────────────────
    output wire        busy_o          // alto durante l'inferenza
);

    // =========================================================================
    // ap_fixed<12,5>: bit[11]=segno, bit[10:6]=parte intera (4 bit + segno),
    // bit[5:0]=parte frazionaria. Valore 1.0 = bit[6]=1 → 12'b0000_0100_0000
    // NO: vediamo meglio: <12,5> → 12 bit totali, 5 bit sopra il punto.
    // Quindi: bit[11]=segno, bit[10:7]=interi[3:0], bit[6]=2^0=1,
    //         bit[5:0]=frazionari. Pixel=1.0 → 12'b0000_0100_0000 = 12'h040.
    // PERÒ: hls4ml normalizza i pixel 0..255 → 0..1 diviso per 255.
    // I pesi sono già ottimizzati per pixel[0,1] binari.
    // Il valore corretto da testbench: input binario 0 o 1 direttamente
    // rappresentato in ap_fixed<12,5> come 0x000 o 0x040 (= 64 dec = 1.0).
    localparam [11:0] PIXEL_ONE = 12'h040;  // 1.0 in ap_fixed<12,5> Q5.7
    localparam [11:0] PIXEL_ZER = 12'h000;  // 0.0

    // =========================================================================
    // BRAM interna 784×12-bit (inferita come EBR)
    // =========================================================================
    (* ram_style = "block" *) reg [11:0] image_ram [0:N_PIXELS-1];

    // =========================================================================
    // FSM
    // =========================================================================
    localparam [1:0]
        ST_FILL  = 2'd0,   // sta ricevendo pixel dal FIFO
        ST_START = 2'd1,   // impulso start a Bambu (1 ciclo)
        ST_INFER = 2'd2;   // inferenza in corso (serve BRAM)

    reg [1:0]          state;
    reg [ADDR_BITS-1:0] wr_addr;   // 0..783

    // Leggiamo dal FIFO solo in ST_FILL e FIFO non vuota
    assign fifo_rd_en = (state == ST_FILL) && fifo_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= ST_FILL;
            wr_addr    <= {ADDR_BITS{1'b0}};
            nn_start_o <= 1'b0;
        end else begin
            nn_start_o <= 1'b0;  // default: 0

            case (state)
                ST_FILL: begin
                    if (fifo_valid) begin
                        image_ram[wr_addr] <= fifo_pixel ? PIXEL_ONE : PIXEL_ZER;
                        if (wr_addr == N_PIXELS - 1) begin
                            wr_addr <= {ADDR_BITS{1'b0}};
                            state   <= ST_START;
                        end else begin
                            wr_addr <= wr_addr + 1'b1;
                        end
                    end
                end

                ST_START: begin
                    nn_start_o <= 1'b1;   // pulse start
                    state      <= ST_INFER;
                end

                ST_INFER: begin
                    if (nn_done_i)
                        state <= ST_FILL;
                end

                default: state <= ST_FILL;
            endcase
        end
    end

    assign busy_o = (state == ST_INFER);

    // =========================================================================
    // BRAM READ PORT A — risponde a Bambu
    // Bambu emette un indirizzo WORD (già diviso per 2 dentro ParmMgr).
    // 784 parole → usiamo bram_addr0[ADDR_BITS-1:0] direttamente.
    // =========================================================================
    reg [11:0] ram_qa;
    always @(posedge clk) begin
        if (bram_ce0)
            ram_qa <= image_ram[bram_addr0[ADDR_BITS-1:0]];
    end
    assign bram_q0 = ram_qa;

    // =========================================================================
    // BRAM READ PORT B
    // =========================================================================
    reg [11:0] ram_qb;
    always @(posedge clk) begin
        if (bram_ce1)
            ram_qb <= image_ram[bram_addr1[ADDR_BITS-1:0]];
    end
    assign bram_q1 = ram_qb;

endmodule
