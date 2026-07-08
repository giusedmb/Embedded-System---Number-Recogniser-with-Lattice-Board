// ============================================================================
// FILE    : lenet_output_capture.v
// PROJECT : ECP5 Number Recogniser
// TARGET  : Lattice ECP5 @ 25 MHz (Lattice Diamond / Synplify-Pro)
//
// FUNZIONE:
//   Cattura il risultato della LeNet-5 (10 score in ap_fixed<12,5>) scritti
//   da Bambu attraverso l'interfaccia BRAM dual-port (layer13_out).
//   Dopo done_port, esegue argmax sequenziale (10 cicli) e produce:
//     digit_o       [3:0] — cifra riconosciuta (0–9)
//     result_valid_o      — impulso 1 ciclo quando digit_o è valido
//
// INTERFACCIA BAMBU (dual-port sync BRAM, write-only per Bambu):
//   layer13_out_address{0,1} [5:0] — indirizzo WORD (parole da 2 byte)
//   layer13_out_ce{0,1}            — chip enable
//   layer13_out_we{0,1}            — write enable
//   layer13_out_d{0,1}  [11:0]     — dato (ap_fixed<12,5>, signed)
//
// NOTA INDIRIZZI:
//   Il ParmMgr di Bambu per layer13_out NON fa la divisione /2.
//   Verifica dalla definizione del modulo:
//     output [5:0] p_layer13_out_address0
//   L'array C++ è `result_t layer13_out_ap[10]` → 10 elementi × 2 byte = 20 byte.
//   Bambu accede in byte (indirizzi 0,2,4,...,18) → word address = byte/2 = 0..9.
//   Usiamo bram_addr0[4:1] per ottenere l'indice (0..9).
// ============================================================================

`timescale 1ns / 1ps

module lenet_output_capture (
    input  wire        clk,
    input  wire        rst_n,

    // ── BRAM write interface (da Bambu) ──────────────────────────────────
    input  wire [5:0]  bram_addr0,
    input  wire [5:0]  bram_addr1,
    input  wire        bram_ce0,
    input  wire        bram_ce1,
    input  wire        bram_we0,
    input  wire        bram_we1,
    input  wire [11:0] bram_d0,
    input  wire [11:0] bram_d1,

    // ── Controllo ─────────────────────────────────────────────────────────
    input  wire        done_i,         // done_port da Bambu (1 ciclo)

    // ── Risultato ─────────────────────────────────────────────────────────
    output reg  [3:0]  digit_o,
    output reg         result_valid_o
);

    // =========================================================================
    // Score RAM: 10 × 12-bit (inferita come LUT-RAM, troppo piccola per EBR)
    // Profondità 16 (prossima potenza di 2 ≥ 10) per semplicità
    // =========================================================================
    reg [11:0] score_ram [0:15];
    integer k;
    initial begin
        for (k = 0; k < 16; k = k + 1)
            score_ram[k] = 12'h800;  // valore minimo signed (0x800 = -2048)
    end

    // ─────────────────────────────────────────────────────────────────────────
    // Write port A: bram_addr0[4:1] → word index 0..9
    // ─────────────────────────────────────────────────────────────────────────
    always @(posedge clk) begin
        if (bram_ce0 && bram_we0)
            score_ram[bram_addr0[4:1]] <= bram_d0;
    end

    // ─────────────────────────────────────────────────────────────────────────
    // Write port B
    // ─────────────────────────────────────────────────────────────────────────
    always @(posedge clk) begin
        if (bram_ce1 && bram_we1)
            score_ram[bram_addr1[4:1]] <= bram_d1;
    end

    // =========================================================================
    // Argmax sequenziale — 10 cicli dopo done_i
    // Confronto signed: ap_fixed<12,5> è complemento a 2
    // =========================================================================
    reg [3:0]  scan_idx;
    reg [3:0]  max_idx;
    reg [11:0] max_val;
    reg        scanning;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_idx       <= 4'd0;
            max_idx        <= 4'd0;
            max_val        <= 12'h800;   // più negativo: -2048
            scanning       <= 1'b0;
            digit_o        <= 4'd0;
            result_valid_o <= 1'b0;
        end else begin
            result_valid_o <= 1'b0;   // default: de-assert

            if (done_i) begin
                // Avvia la scansione argmax
                scan_idx <= 4'd0;
                max_val  <= 12'h800;
                max_idx  <= 4'd0;
                scanning <= 1'b1;
            end else if (scanning) begin
                // Confronto signed
                if ($signed(score_ram[scan_idx]) > $signed(max_val)) begin
                    max_val <= score_ram[scan_idx];
                    max_idx <= scan_idx;
                end

                if (scan_idx == 4'd9) begin
                    // Scansione completata
                    scanning       <= 1'b0;
                    digit_o        <= max_idx;
                    result_valid_o <= 1'b1;
                end else begin
                    scan_idx <= scan_idx + 4'd1;
                end
            end
        end
    end

endmodule
