// =====================================================================
// FILE: hardware_preprocessing.v
// LINGUAGGIO: Verilog HDL (IEEE 1364-2001)
//
// [ARCHITETTURA AGGIORNATA - STREAMING LINE BUFFERS]
// - Rimossi tutti i divisori hardware (/ e %) per calcolare X,Y.
// - Sostituite le letture multiple in BRAM con Shift Registers (Line Buffers)
//   per garantire 1 sola lettura e 1 sola scrittura per ciclo di clock.
// - Sintesi ultra-rapida e perfetta inferenza nei blocchi EBR.
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

    // Porta INPUT 
    input  wire [7:0]  i_pixel,
    input  wire        i_valid,
    output wire        o_ready,
    input  wire        i_frame_start,

    // Porta OUTPUT 
    output reg         o_pixel,
    output reg         o_valid,
    input  wire        i_ready
);

    // =================================================================
    // COSTANTI DIMENSIONALI
    // =================================================================
    localparam PIXELS_224 = W_224 * W_224;  // 50176
    localparam PIXELS_112 = W_112 * W_112;  // 12544
    localparam PIXELS_56  = W_56  * W_56;   //  3136
    localparam PIXELS_28  = W_28  * W_28;   //   784

    // =================================================================
    // MACCHINA A STATI (FSM)
    // =================================================================
    localparam [3:0]
        S_IDLE   = 4'd0,
        S_LOAD   = 4'd1,
        S_DIL1   = 4'd2,
        S_POOL1  = 4'd3,
        S_DIL2   = 4'd4,
        S_POOL2  = 4'd5,
        S_POOL3  = 4'd6,
        S_OUTPUT = 4'd7;

    reg [3:0] state, next_state;

    // =================================================================
    // MEMORIE BRAM (Lattice EBR)
    // =================================================================
    (* ram_style = "block" *) reg [0:0] buf_bin  [0:PIXELS_224-1];
    (* ram_style = "block" *) reg [0:0] buf_dil1 [0:PIXELS_224-1];
    (* ram_style = "block" *) reg [0:0] buf_pool1[0:PIXELS_112-1];
    (* ram_style = "block" *) reg [0:0] buf_dil2 [0:PIXELS_112-1];
    (* ram_style = "block" *) reg [0:0] buf_pool2[0:PIXELS_56 -1];
    (* ram_style = "block" *) reg [0:0] buf_out  [0:PIXELS_28 -1];

    // =================================================================
    // LINE BUFFERS (Shift Registers per le finestre spaziali)
    // =================================================================
    reg [449:0] lb_dil1;  // 3x3 su 224 (2*224 + 1)
    reg [224:0] lb_pool1; // 2x2 su 224 (224 + 1)
    reg [225:0] lb_dil2;  // 3x3 su 112 (2*112 + 1)
    reg [112:0] lb_pool2; // 2x2 su 112 (112 + 1)
    reg [56:0]  lb_pool3; // 2x2 su 56  (56 + 1)

    // =================================================================
    // CONTATORI UNIFICATI (Senza divisioni hardware!)
    // =================================================================
    reg [15:0] cnt_proc; // Indice di lettura (Sorgente)
    reg [15:0] cnt_out;  // Indice di scrittura (Destinazione)
    reg [7:0]  px;       // Coordinata X
    reg [7:0]  py;       // Coordinata Y

    assign o_ready = (state == S_LOAD) && (cnt_proc < PIXELS_224);

    // =================================================================
    // LOGICA FSM
    // =================================================================
    always @(posedge clk) begin
        if (!rst_n) state <= S_IDLE;
        else        state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:   if (i_frame_start) next_state = S_LOAD;
            S_LOAD:   if (cnt_proc == PIXELS_224 - 1 && i_valid) next_state = S_DIL1;
            
            S_DIL1:   if (cnt_proc == PIXELS_224 - 1) next_state = S_POOL1;
            S_POOL1:  if (cnt_proc == PIXELS_224 - 1) next_state = S_DIL2;  // Legge 224x224
            
            S_DIL2:   if (cnt_proc == PIXELS_112 - 1) next_state = S_POOL2;
            S_POOL2:  if (cnt_proc == PIXELS_112 - 1) next_state = S_POOL3; // Legge 112x112
            
            S_POOL3:  if (cnt_proc == PIXELS_56 - 1)  next_state = S_OUTPUT;// Legge 56x56
            
            S_OUTPUT: if (cnt_out == PIXELS_28 - 1 && i_ready) next_state = S_IDLE;
            default:  next_state = S_IDLE;
        endcase
    end

    // =================================================================
    // GESTIONE CONTATORI E COORDINATE
    // =================================================================
    always @(posedge clk) begin
        if (!rst_n || state == S_IDLE) begin
            cnt_proc <= 0; cnt_out <= 0; px <= 0; py <= 0;
        end else if (state != next_state) begin
            // Reset dei contatori al cambio di stato
            cnt_proc <= 0; cnt_out <= 0; px <= 0; py <= 0;
        end else begin
            case (state)
                S_LOAD: if (i_valid) cnt_proc <= cnt_proc + 1;
                S_DIL1: cnt_proc <= cnt_proc + 1;
                S_POOL1: begin
                    cnt_proc <= cnt_proc + 1;
                    if (px == W_224-1) begin px <= 0; py <= py + 1; end else px <= px + 1;
                    if (px[0] && py[0]) cnt_out <= cnt_out + 1; // <--- Spostato qui
                end
                S_DIL2: cnt_proc <= cnt_proc + 1;
                S_POOL2: begin
                    cnt_proc <= cnt_proc + 1;
                    if (px == W_112-1) begin px <= 0; py <= py + 1; end else px <= px + 1;
                    if (px[0] && py[0]) cnt_out <= cnt_out + 1; // <--- Spostato qui
                end
                S_POOL3: begin
                    cnt_proc <= cnt_proc + 1;
                    if (px == W_56-1) begin px <= 0; py <= py + 1; end else px <= px + 1;
                    if (px[0] && py[0]) cnt_out <= cnt_out + 1; // <--- Spostato qui
                end
                S_OUTPUT: if (i_ready) cnt_out <= cnt_out + 1;
            endcase
        end
    end

    // =================================================================
    // SOMMATORI COMBINATORI PER IL POOLING (1 accesso memoria + 3 da registro)
    // =================================================================
    wire [2:0] sum_p1 = {2'b0, buf_dil1[cnt_proc]}  + {2'b0, lb_pool1[0]} + {2'b0, lb_pool1[223]} + {2'b0, lb_pool1[224]};
    wire [2:0] sum_p2 = {2'b0, buf_dil2[cnt_proc]}  + {2'b0, lb_pool2[0]} + {2'b0, lb_pool2[111]} + {2'b0, lb_pool2[112]};
    wire [2:0] sum_p3 = {2'b0, buf_pool2[cnt_proc]} + {2'b0, lb_pool3[0]} + {2'b0, lb_pool3[55]}  + {2'b0, lb_pool3[56]};

    // =================================================================
    // DATA PATH: IL MOTORE DI ELABORAZIONE PIPELINE
    // =================================================================
    always @(posedge clk) begin
        if (!rst_n || state == S_IDLE) begin
            lb_dil1 <= 0; lb_pool1 <= 0; lb_dil2 <= 0; lb_pool2 <= 0; lb_pool3 <= 0;
            
        end else if (state == S_LOAD && i_valid) begin
            // 1. Caricamento e Binarizzazione
            buf_bin[cnt_proc] <= (i_pixel < THRESHOLD) ? 1'b1 : 1'b0;
        
        end else if (state == S_DIL1) begin
            // 2. Dilatazione su 224
            lb_dil1 <= {lb_dil1[448:0], buf_bin[cnt_proc]};
            buf_dil1[cnt_proc] <= buf_bin[cnt_proc] | lb_dil1[0] | lb_dil1[1] |
                                  lb_dil1[223] | lb_dil1[224] | lb_dil1[225] |
                                  lb_dil1[447] | lb_dil1[448] | lb_dil1[449];
                                  
        end else if (state == S_POOL1) begin
            // 3. Pooling su 224 -> 112 (Registra solo se X e Y sono dispari)
            lb_pool1 <= {lb_pool1[223:0], buf_dil1[cnt_proc]};
            if (px[0] && py[0]) begin
                buf_pool1[cnt_out] <= (sum_p1 >= 2) ? 1'b1 : 1'b0;
                // INCREMENTO SPOSTATO SOPRA
            end
            
        end else if (state == S_DIL2) begin
            // 4. Dilatazione su 112
            lb_dil2 <= {lb_dil2[224:0], buf_pool1[cnt_proc]};
            buf_dil2[cnt_proc] <= buf_pool1[cnt_proc] | lb_dil2[0] | lb_dil2[1] |
                                  lb_dil2[111] | lb_dil2[112] | lb_dil2[113] |
                                  lb_dil2[223] | lb_dil2[224] | lb_dil2[225];
                                  
        end else if (state == S_POOL2) begin
            // 5. Pooling su 112 -> 56
            lb_pool2 <= {lb_pool2[111:0], buf_dil2[cnt_proc]};
            if (px[0] && py[0]) begin
                buf_pool2[cnt_out] <= (sum_p2 >= 2) ? 1'b1 : 1'b0;
                // INCREMENTO SPOSTATO SOPRA
            end
            
        end else if (state == S_POOL3) begin
            // 6. Pooling su 56 -> 28
            lb_pool3 <= {lb_pool3[55:0], buf_pool2[cnt_proc]};
            if (px[0] && py[0]) begin
                buf_out[cnt_out] <= (sum_p3 >= 2) ? 1'b1 : 1'b0;
                // INCREMENTO SPOSTATO SOPRA
            end
        end
    end

    // =================================================================
    // OUTPUT STAGE
    // =================================================================
    always @(posedge clk) begin
        if (!rst_n || state == S_IDLE) begin
            o_valid <= 1'b0;
            o_pixel <= 1'b0;
        end else if (state == S_OUTPUT) begin
            o_valid <= 1'b1;
            o_pixel <= buf_out[cnt_out];
        end else begin
            o_valid <= 1'b0;
        end
    end

endmodule