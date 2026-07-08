// ============================================================================
// FILE    : cdc_async_fifo.v
// PROJECT : ECP5 Number Recogniser
// TARGET  : Lattice ECP5 (Lattice Diamond / Synplify-Pro)
//
// FUNZIONE:
//   FIFO asincrona (Async FIFO) per il crossing di dominio di clock.
//
//   DOMINIO SCRITTURA (wr_clk): 148.5 MHz — uscita del pre-processing
//   DOMINIO LETTURA  (rd_clk): 25 MHz     — clock del modulo Bambu LeNet-5
//
//   Profondità: 1024 parole (abbondante per un frame 28×28 = 784 pixel).
//   Implementazione con Gray-code pointer synchronization (standard CDC).
//
// PARAMETRI:
//   DATA_WIDTH : larghezza del dato (default 1: un bit = un pixel)
//   DEPTH_LOG2 : log2 della profondità FIFO (default 10 → 1024 celle)
// ============================================================================

`timescale 1ns / 1ps

module cdc_async_fifo #(
    parameter DATA_WIDTH = 1,
    parameter DEPTH_LOG2 = 10   // profondità = 2^10 = 1024
)(
    // Porta di scrittura (dominio veloce: CSI2_sens_clk ≈ 148.5 MHz)
    input  wire                  wr_clk,
    input  wire                  wr_rst_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  wr_full,

    // Porta di lettura (dominio lento: 25 MHz — clock Bambu)
    input  wire                  rd_clk,
    input  wire                  rd_rst_n,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output wire                  rd_empty
);

    localparam DEPTH = (1 << DEPTH_LOG2);

    // ─────────────────────────────────────────────────────────────────────────
    // RAM interna (inferita come LUT-RAM su ECP5; depth=1024 < EBR threshold)
    // ─────────────────────────────────────────────────────────────────────────
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // ─────────────────────────────────────────────────────────────────────────
    // Puntatori binari
    // ─────────────────────────────────────────────────────────────────────────
    reg [DEPTH_LOG2:0] wr_ptr_bin;   // write pointer (binario, +1 bit per full/empty)
    reg [DEPTH_LOG2:0] rd_ptr_bin;   // read pointer

    // ─────────────────────────────────────────────────────────────────────────
    // Puntatori Gray (per il crossing CDC)
    // ─────────────────────────────────────────────────────────────────────────
    wire [DEPTH_LOG2:0] wr_ptr_gray = wr_ptr_bin ^ (wr_ptr_bin >> 1);
    wire [DEPTH_LOG2:0] rd_ptr_gray = rd_ptr_bin ^ (rd_ptr_bin >> 1);

    // ─────────────────────────────────────────────────────────────────────────
    // Sincronizzatori a 2 stadi (standard CDC)
    // ─────────────────────────────────────────────────────────────────────────
    // write pointer sync → dominio rd_clk
    reg [DEPTH_LOG2:0] wr_ptr_gray_s1_rd, wr_ptr_gray_s2_rd;
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_s1_rd <= {(DEPTH_LOG2+1){1'b0}};
            wr_ptr_gray_s2_rd <= {(DEPTH_LOG2+1){1'b0}};
        end else begin
            wr_ptr_gray_s1_rd <= wr_ptr_gray;
            wr_ptr_gray_s2_rd <= wr_ptr_gray_s1_rd;
        end
    end

    // read pointer sync → dominio wr_clk
    reg [DEPTH_LOG2:0] rd_ptr_gray_s1_wr, rd_ptr_gray_s2_wr;
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_s1_wr <= {(DEPTH_LOG2+1){1'b0}};
            rd_ptr_gray_s2_wr <= {(DEPTH_LOG2+1){1'b0}};
        end else begin
            rd_ptr_gray_s1_wr <= rd_ptr_gray;
            rd_ptr_gray_s2_wr <= rd_ptr_gray_s1_wr;
        end
    end

    // ─────────────────────────────────────────────────────────────────────────
    // Logica FULL (nel dominio di scrittura)
    // FIFO piena quando wr_ptr_gray == {~rd_ptr_gray_sync[top:top-1], rd_ptr_gray_sync[top-2:0]}
    // ─────────────────────────────────────────────────────────────────────────
    assign wr_full = (wr_ptr_gray == {~rd_ptr_gray_s2_wr[DEPTH_LOG2:DEPTH_LOG2-1],
                                       rd_ptr_gray_s2_wr[DEPTH_LOG2-2:0]});

    // ─────────────────────────────────────────────────────────────────────────
    // Logica EMPTY (nel dominio di lettura)
    // ─────────────────────────────────────────────────────────────────────────
    assign rd_empty = (rd_ptr_gray == wr_ptr_gray_s2_rd);

    // ─────────────────────────────────────────────────────────────────────────
    // Write port
    // ─────────────────────────────────────────────────────────────────────────
    always @(posedge wr_clk) begin
        if (wr_en && !wr_full) begin
            mem[wr_ptr_bin[DEPTH_LOG2-1:0]] <= wr_data;
        end
    end
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) wr_ptr_bin <= {(DEPTH_LOG2+1){1'b0}};
        else if (wr_en && !wr_full) wr_ptr_bin <= wr_ptr_bin + 1'b1;
    end

    // ─────────────────────────────────────────────────────────────────────────
    // Read port
    // ─────────────────────────────────────────────────────────────────────────
    always @(posedge rd_clk) begin
        if (rd_en && !rd_empty) begin
            rd_data <= mem[rd_ptr_bin[DEPTH_LOG2-1:0]];
        end
    end
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) rd_ptr_bin <= {(DEPTH_LOG2+1){1'b0}};
        else if (rd_en && !rd_empty) rd_ptr_bin <= rd_ptr_bin + 1'b1;
    end

    // ─────────────────────────────────────────────────────────────────────────
    // Occupancy (nel dominio rd, per debug)
    // ─────────────────────────────────────────────────────────────────────────
    // (non connessa esternamente in questo progetto)

endmodule
