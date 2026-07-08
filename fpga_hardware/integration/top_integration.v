// ============================================================================
// FILE    : top_integration.v
// PROJECT : ECP5 Number Recogniser — Full System Integration
// TARGET  : Lattice ECP5 @ LFE5UM-85F-8BG756C (Lattice Diamond / Synplify-Pro)
//
// NOTA PORTE: la board originale non ha pin GPIO liberi da mappare su
// digit_out/digit_valid/nn_busy. Questi segnali sono quindi interni:
//   - digit_hold[3:0]  : cifra stabile (leggibile in simulazione)
//   - nn_busy          : pilota il colore del guide box (giallo = inferenza)
// Il risultato è visibile sul monitor HDMI tramite il guide box colorato.
//
// ── NOVITÀ RISPETTO ALLA VERSIONE PRECEDENTE ─────────────────────────────────
//
//  [1] ROI CENTRATA: il preprocessing non cattura più i primi 224×224 pixel
//      in raster-scan (che su un frame 1920-wide sarebbero i primi 26 rows),
//      ma solo i pixel nell'area rettangolare centrata nel frame:
//        ROI_X = [848 .. 1071], ROI_Y = [428 .. 651]  (224×224 pixel)
//      Questo si ottiene agendo su i_valid del preprocessore con la guard
//      (hcnt ∈ [ROI_X_START, ROI_X_END) && vcnt ∈ [ROI_Y_START, ROI_Y_END))
//
//  [2] GUIDE BOX: disegna un rettangolo bianco 224×224 centrato nel frame
//      HDMI per indicare dove puntare la cifra. Il bordo è 2 pixel di
//      spessore. Quando l'inferenza è in corso il box diventa giallo.
//
//  [3] GESTIONE DELAY PIPELINE:
//      La pipeline ha una latenza totale di circa:
//        LOAD (50176 cy @ 148.5 MHz) ≈ 0.34 ms
//        DIL1+POOL1+DIL2+POOL2+POOL3 (≈ 128K cy) ≈ 0.86 ms
//        CDC FIFO + lenet_input_buffer fill ≈ 0.03 ms
//        LeNet-5 inference (437K cy @ 27 MHz) ≈ 16.2 ms
//        Total ≈ 17.4 ms ≈ 0.52 frame @30fps
//      Il risultato mostrato si riferisce alla frame PRECEDENTE (normale).
//      La cifra riconosciuta viene BLOCCATA (latched) su result_valid e
//      rimane visibile fino al prossimo risultato valido.
//      Aggiunto: RESULT HOLD REGISTER per evitare flicker.
//
// ── ALTRI DETTAGLI INVARIATI ─────────────────────────────────────────────────
//      ISP pipeline, CDC FIFO, lenet_input_buffer, lenet_output_capture,
//      Bambu top-level, I2C controllers, pin constraints.
// ============================================================================

`timescale 1ns / 1ps

`define BAMBU_TOP p_Z9myprojectP8ac_fixedILi12ELi5ELb1EL9ac_q_mode0EL9ac_o_mode0EES3_s

module top_integration #(
    // ── Risoluzione frame ISP ────────────────────────────────────────────
    parameter integer H_ACTIVE = 1920,
    parameter integer V_ACTIVE = 1080,

    // ── Dimensione area di acquisizione (deve essere 224) ────────────────
    parameter integer ROI_SIZE  = 224,

    // ── Spessore bordo guide box (pixel) ────────────────────────────────
    parameter integer BOX_THICK = 3,

    // ── Soglia binarizzazione ────────────────────────────────────────────
    parameter integer THRESHOLD = 100
)(
    input  wire        clk_i,

    input  wire        CSI2_sens_clk,
    input  wire        CSI2_sens_fv,
    input  wire        CSI2_sens_lv,
    input  wire [9:0]  CSI2_sens_data,

    output reg  [11:0] pix_red,
    output reg  [11:0] pix_green,
    output reg  [11:0] pix_blue,
    output reg         hsync,
    output reg         vsync,
    output reg         data_enable,
    output wire        pixclk_out,

    inout  wire        scl,
    inout  wire        sda,
    inout  wire        scl2,
    inout  wire        sda2,
    inout  wire        HDMI_scl,
    inout  wire        HDMI_sda,

    input  wire        reset_n,
    output wire        reset_sensor,
    output wire        reset_crosslink,
    output wire        q
);

    // Segnali interni (precedentemente porte)
    wire [3:0] digit_out;
    wire       digit_valid;
    wire       nn_busy;

    // =========================================================================
    // COSTANTI ROI (calcolate da parametri — Synplify le semplifica a costanti)
    // =========================================================================
    localparam integer ROI_X_START = (H_ACTIVE - ROI_SIZE) / 2;  // 848
    localparam integer ROI_X_END   = ROI_X_START + ROI_SIZE;      // 1072
    localparam integer ROI_Y_START = (V_ACTIVE - ROI_SIZE) / 2;  // 428
    localparam integer ROI_Y_END   = ROI_Y_START + ROI_SIZE;      // 652

    // ── Coordinate bordi del guide box (BOX_THICK pixel di spessore) ────
    localparam integer BOX_L  = ROI_X_START;
    localparam integer BOX_R  = ROI_X_END   - 1;
    localparam integer BOX_T  = ROI_Y_START;
    localparam integer BOX_B  = ROI_Y_END   - 1;

    // =========================================================================
    // CLOCK E RESET
    // =========================================================================
    wire clk_nn   = clk_i;       // 27 MHz per Bambu (vedi README)
    wire reset_h  = ~reset_n;    // attivo alto per Bambu

    // =========================================================================
    // 1. REGISTRAZIONE CSI2
    // =========================================================================
    reg fv_r, lv_r;
    reg [9:0] data_r;
    always @(posedge CSI2_sens_clk or negedge reset_n) begin
        if (!reset_n) begin fv_r<=0; lv_r<=0; data_r<=0; end
        else          begin fv_r<=CSI2_sens_fv; lv_r<=CSI2_sens_lv; data_r<=CSI2_sens_data; end
    end

    // =========================================================================
    // 2. ISP PIPELINE
    // =========================================================================
    wire [35:0] rgb_isp;
    wire [11:0] red_o   = rgb_isp[35:24];
    wire [11:0] green_o = rgb_isp[23:12];
    wire [11:0] blue_o  = rgb_isp[11:0];
    wire        hsync_o, vsync_o, de_o;
    assign pixclk_out = ~CSI2_sens_clk;

    image_pipe image_pipe_inst (
        .reset_n    (reset_n),
        .clk        (CSI2_sens_clk),
        .frame_valid(fv_r),
        .line_valid (lv_r),
        .pixdata    ({data_r, 2'b00}),
        .vsync      (vsync_o),
        .hsync      (hsync_o),
        .de         (de_o),
        .rgb_data   (rgb_isp)
    );

    // =========================================================================
    // 3. CONTATORI PIXEL nel dominio CSI2_sens_clk
    //    hcnt: 0..H_ACTIVE-1 per ogni riga attiva (de_o=1)
    //    vcnt: 0..V_ACTIVE-1 riga corrente (incrementa su fronte discesa de_o)
    // =========================================================================
    reg [11:0] hcnt, vcnt;
    reg        de_prev;
    always @(posedge CSI2_sens_clk or negedge reset_n) begin
        if (!reset_n) begin
            hcnt <= 12'd0; vcnt <= 12'd0; de_prev <= 1'b0;
        end else begin
            de_prev <= de_o;

            // Gestione hcnt
            if (vsync_o) begin
                hcnt <= 12'd0;
            end else if (~de_prev && de_o) begin
                // Fronte salita DE: inizio nuova riga, reset colonna
                hcnt <= 12'd0;
            end else if (de_o) begin
                hcnt <= hcnt + 12'd1;
            end

            // Gestione vcnt
            if (vsync_o) begin
                vcnt <= 12'd0;
            end else if (de_prev && ~de_o) begin
                // Fronte discesa DE: fine riga, incrementa riga
                vcnt <= vcnt + 12'd1;
            end
        end
    end

    // =========================================================================
    // 4. FRAME START PULSE (fronte salita vsync_o)
    // =========================================================================
    reg vsync_prev;
    always @(posedge CSI2_sens_clk or negedge reset_n) begin
        if (!reset_n) vsync_prev <= 1'b0;
        else          vsync_prev <= vsync_o;
    end
    wire frame_start = vsync_o & ~vsync_prev;

    // =========================================================================
    // 5. ROI VALID: pixel_valid solo nell'area centrata 224×224  [FIX-1]
    //    Corregge il bug dell'originale dove i_valid = de_o catturava
    //    i primi 50176 pixel in raster-scan (non una regione quadrata).
    // =========================================================================
    wire roi_active = (hcnt >= ROI_X_START) && (hcnt < ROI_X_END) &&
                      (vcnt >= ROI_Y_START) && (vcnt < ROI_Y_END);
    wire roi_valid  = de_o && roi_active;

    // =========================================================================
    // 6. PRE-PROCESSING (dominio CSI2_sens_clk, 148.5 MHz)
    //    i_valid gated da roi_valid → cattura esattamente 224×224 pixel centrali
    // =========================================================================
    wire pp_pixel, pp_valid;

    hardware_preprocessing_opt #(
        .W_224     (224),
        .W_112     (112),
        .W_56      (56),
        .W_28      (28),
        .THRESHOLD (THRESHOLD)
    ) u_preproc (
        .clk           (CSI2_sens_clk),
        .rst_n         (reset_n),
        .i_pixel       (green_o[11:4]),
        .i_valid       (roi_valid),      // ← solo i pixel nella ROI
        .o_ready       (),               // non usato: roi_valid fa da gate
        .i_frame_start (frame_start),
        .o_pixel       (pp_pixel),
        .o_valid       (pp_valid),
        .i_ready       (1'b1)
    );

    // =========================================================================
    // 7. CDC ASYNC FIFO — 148.5 MHz → 27 MHz
    // =========================================================================
    wire fifo_wr_full, fifo_rd_empty;
    wire fifo_rd_pixel, fifo_rd_en;

    cdc_async_fifo #(
        .DATA_WIDTH (1),
        .DEPTH_LOG2 (10)   // 1024 celle ≫ 784 pixel
    ) u_cdc_fifo (
        .wr_clk   (CSI2_sens_clk),
        .wr_rst_n (reset_n),
        .wr_en    (pp_valid && !fifo_wr_full),
        .wr_data  (pp_pixel),
        .wr_full  (fifo_wr_full),

        .rd_clk   (clk_nn),
        .rd_rst_n (reset_n),
        .rd_en    (fifo_rd_en),
        .rd_data  (fifo_rd_pixel),
        .rd_empty (fifo_rd_empty)
    );

    // =========================================================================
    // 8. LENET INPUT BUFFER (dominio clk_nn, 27 MHz)
    // =========================================================================
    wire        nn_start, nn_done;
    wire [12:0] bram_in_addr0, bram_in_addr1;
    wire        bram_in_ce0,   bram_in_ce1;
    wire [11:0] bram_in_q0,    bram_in_q1;

    lenet_input_buffer #(
        .N_PIXELS  (784),
        .ADDR_BITS (10)
    ) u_input_buf (
        .clk        (clk_nn),
        .rst_n      (reset_n),
        .fifo_pixel (fifo_rd_pixel),
        .fifo_valid (~fifo_rd_empty),
        .fifo_rd_en (fifo_rd_en),
        .nn_start_o (nn_start),
        .nn_done_i  (nn_done),
        .bram_addr0 (bram_in_addr0),
        .bram_addr1 (bram_in_addr1),
        .bram_ce0   (bram_in_ce0),
        .bram_ce1   (bram_in_ce1),
        .bram_q0    (bram_in_q0),
        .bram_q1    (bram_in_q1),
        .busy_o     (nn_busy)
    );

    // =========================================================================
    // 9. BAMBU LENET-5 (dominio clk_nn, 27 MHz)
    // =========================================================================
    wire [5:0]  bram_out_addr0, bram_out_addr1;
    wire        bram_out_ce0,   bram_out_ce1;
    wire        bram_out_we0,   bram_out_we1;
    wire [11:0] bram_out_d0,    bram_out_d1;

    `BAMBU_TOP u_lenet (
        .clock                (clk_nn),
        .reset                (reset_h),
        .start_port           (nn_start),
        .done_port            (nn_done),
        .conv1_input_q0       (bram_in_q0),
        .conv1_input_q1       (bram_in_q1),
        .conv1_input_address0 (bram_in_addr0),
        .conv1_input_address1 (bram_in_addr1),
        .conv1_input_ce0      (bram_in_ce0),
        .conv1_input_ce1      (bram_in_ce1),
        .layer13_out_address0 (bram_out_addr0),
        .layer13_out_address1 (bram_out_addr1),
        .layer13_out_ce0      (bram_out_ce0),
        .layer13_out_ce1      (bram_out_ce1),
        .layer13_out_we0      (bram_out_we0),
        .layer13_out_we1      (bram_out_we1),
        .layer13_out_d0       (bram_out_d0),
        .layer13_out_d1       (bram_out_d1)
    );

    // =========================================================================
    // 10. OUTPUT CAPTURE + ARGMAX (dominio clk_nn, 27 MHz)
    // =========================================================================
    wire [3:0] digit_raw;
    wire       digit_valid_raw;

    lenet_output_capture u_output_cap (
        .clk           (clk_nn),
        .rst_n         (reset_n),
        .bram_addr0    (bram_out_addr0),
        .bram_addr1    (bram_out_addr1),
        .bram_ce0      (bram_out_ce0),
        .bram_ce1      (bram_out_ce1),
        .bram_we0      (bram_out_we0),
        .bram_we1      (bram_out_we1),
        .bram_d0       (bram_out_d0),
        .bram_d1       (bram_out_d1),
        .done_i        (nn_done),
        .digit_o       (digit_raw),
        .result_valid_o(digit_valid_raw)
    );

    // =========================================================================
    // 11. RESULT HOLD REGISTER  [FIX-3 — gestione delay]
    //
    //  La latenza totale della pipeline è:
    //    Pre-processing  : ~178K cicli @ 148.5 MHz ≈ 1.2 ms
    //    CDC + fill buf  :   ~784 cicli @ 27 MHz   ≈ 0.03 ms
    //    LeNet inference :  ~437K cicli @ 27 MHz   ≈ 16.2 ms
    //    ─────────────────────────────────────────────────────
    //    Totale          :                         ≈ 17.4 ms
    //
    //  A 30 fps il periodo frame è 33.3 ms → la cifra visualizzata si
    //  riferisce alla frame precedente con un ritardo di ~17 ms.
    //  Questo è accettabile per l'uso interattivo.
    //
    //  Il registro di hold mantiene l'ultima cifra valida visibile a schermo
    //  tra un risultato e il successivo (nessun flicker a schermo).
    // =========================================================================
    reg [3:0] digit_hold;       // ultima cifra stabile
    reg       digit_valid_hold; // flag: almeno un risultato ricevuto

    always @(posedge clk_nn or negedge reset_n) begin
        if (!reset_n) begin
            digit_hold       <= 4'd0;
            digit_valid_hold <= 1'b0;
        end else if (digit_valid_raw) begin
            digit_hold       <= digit_raw;
            digit_valid_hold <= 1'b1;
        end
    end

    assign digit_out   = digit_hold;        // risultato stabile (0-9)
    assign digit_valid = digit_valid_raw;   // impulso a ogni nuova predizione
    // nn_busy: usato internamente per il colore guide box (non portato fuori)

    // =========================================================================
    // 12. DISPLAY BUFFER 28×28  (dominio CSI2_sens_clk)
    //     Accumula i pixel del preprocessing per l'upscale HDMI nell'area ROI.
    // =========================================================================
    reg [783:0] display_buf;
    reg [9:0]   disp_wr_cnt;

    always @(posedge CSI2_sens_clk or negedge reset_n) begin
        if (!reset_n) begin
            disp_wr_cnt <= 10'd0;
            display_buf <= {784{1'b0}};
        end else if (frame_start) begin
            disp_wr_cnt <= 10'd0;
        end else if (pp_valid) begin
            display_buf[disp_wr_cnt] <= pp_pixel;
            disp_wr_cnt <= (disp_wr_cnt == 10'd783) ? 10'd0 : disp_wr_cnt + 10'd1;
        end
    end

    // Calcolo indirizzo upscale 8×:
    // pixel 28×28 [r,c] mostrato in blocco 8×8 centrato nel frame
    // col_28 = (hcnt - ROI_X_START) / 8 = (hcnt - ROI_X_START)[7:3]
    // row_28 = (vcnt - ROI_Y_START) / 8 = (vcnt - ROI_Y_START)[7:3]
    wire [11:0] hcnt_roi   = hcnt - ROI_X_START;  // offset nella ROI
    wire [11:0] vcnt_roi   = vcnt - ROI_Y_START;
    wire [4:0]  disp_col   = hcnt_roi[7:3];       // 0..27
    wire [4:0]  disp_row   = vcnt_roi[7:3];       // 0..27
    // row*28 come shift-add senza moltiplicatore hardware:
    // 28 = 32 - 4 = (row<<5) - (row<<2)
    wire [9:0]  row_x28    = ({5'b0,disp_row} << 5) - ({5'b0,disp_row} << 2);
    wire [9:0]  disp_addr  = row_x28 + {5'b0,disp_col};
    wire        pp_disp_pix = display_buf[disp_addr];

    // =========================================================================
    // 13. SINCRONIZZATORI CDC → dominio display  (clk_nn → CSI2_sens_clk)
    // =========================================================================
    reg nn_busy_s1,  nn_busy_s2;
    reg dv_hold_s1,  dv_hold_s2;   // digit_valid_hold sincronizzato
    reg [3:0] digit_s1, digit_s2;  // digit_hold sincronizzato

    always @(posedge CSI2_sens_clk or negedge reset_n) begin
        if (!reset_n) begin
            nn_busy_s1 <= 0; nn_busy_s2 <= 0;
            dv_hold_s1 <= 0; dv_hold_s2 <= 0;
            digit_s1   <= 0; digit_s2   <= 0;
        end else begin
            nn_busy_s1 <= nn_busy;      nn_busy_s2 <= nn_busy_s1;
            dv_hold_s1 <= digit_valid_hold; dv_hold_s2 <= dv_hold_s1;
            digit_s1   <= digit_hold;   digit_s2   <= digit_s1;
        end
    end

    // =========================================================================
    // 14. GUIDE BOX LOGIC  [FIX-2]
    //
    //  Disegna un bordo rettangolare di BOX_THICK pixel nell'area ROI:
    //    - Bianco (12'hFFF) quando in attesa di acquisizione / risultato stabile
    //    - Giallo (R=FFF G=FFF B=000) durante l'inferenza (nn_busy)
    //    - Verde  (R=000 G=FFF B=000) per 1 frame dopo un risultato valido
    //    - La ROI interna mostra l'immagine pre-processata upscalata 8×
    //
    //  Il bordo è attivo quando:
    //    on_box_left_edge   : hcnt ∈ [BOX_L, BOX_L+BOX_THICK)
    //    on_box_right_edge  : hcnt ∈ (BOX_R-BOX_THICK, BOX_R]
    //    on_box_top_edge    : vcnt ∈ [BOX_T, BOX_T+BOX_THICK)
    //    on_box_bottom_edge : vcnt ∈ (BOX_B-BOX_THICK, BOX_B]
    // =========================================================================

    // Pixel sulla cornice del box
    wire on_h_edge = (hcnt >= BOX_L) && (hcnt <= BOX_R) &&
                     ( (vcnt >= BOX_T && vcnt < BOX_T + BOX_THICK) ||
                       (vcnt > BOX_B - BOX_THICK && vcnt <= BOX_B) );

    wire on_v_edge = (vcnt >= BOX_T) && (vcnt <= BOX_B) &&
                     ( (hcnt >= BOX_L && hcnt < BOX_L + BOX_THICK) ||
                       (hcnt > BOX_R - BOX_THICK && hcnt <= BOX_R) );

    wire on_box_border = on_h_edge || on_v_edge;

    // Pixel all'interno della ROI (esclusa la cornice)
    wire in_roi_inner = roi_active && !on_box_border;

    // Colore del bordo (dipende dallo stato)
    // Giallo = inferenza; Verde = risultato appena arrivato; Bianco = idle
    wire [11:0] box_r, box_g, box_b;
    assign box_r = 12'hFFF;
    assign box_g = 12'hFFF;
    assign box_b = nn_busy_s2 ? 12'h000 : 12'hFFF;  // giallo se busy, bianco altrimenti

    // Pixel interno: immagine binaria upscalata (bianco/nero)
    wire [11:0] pp_ch = {12{pp_disp_pix}};  // 12'hFFF o 12'h000

    // =========================================================================
    // 15. MUX HDMI OUTPUT  (dominio CSI2_sens_clk, registrato)
    // =========================================================================
    always @(posedge CSI2_sens_clk or negedge reset_n) begin
        if (!reset_n) begin
            pix_red <= 0; pix_green <= 0; pix_blue <= 0;
            hsync <= 0; vsync <= 0; data_enable <= 0;
        end else begin
            hsync       <= hsync_o;
            vsync       <= vsync_o;
            data_enable <= de_o;

            if (on_box_border) begin
                // ── Bordo guide box ──────────────────────────────────────
                pix_red   <= box_r;
                pix_green <= box_g;
                pix_blue  <= box_b;

            end else if (in_roi_inner) begin
                // ── Interno ROI: pre-processing upscalato 8× ────────────
                pix_red   <= pp_ch;
                pix_green <= pp_ch;
                pix_blue  <= pp_ch | (nn_busy_s2 ? 12'h030 : 12'h000);

            end else begin
                // ── Fuori ROI: passthrough ISP ───────────────────────────
                pix_red   <= red_o;
                pix_green <= green_o;
                pix_blue  <= blue_o;
            end
        end
    end

    // =========================================================================
    // 16. I2C CONTROLLERS (invariati)
    // =========================================================================
    i2c_top i2c_inst (
        .clk_i          (clk_i),
        .rst_n          (reset_n),
        .scl            (scl),
        .sda            (sda),
        .scl2           (scl2),
        .sda2           (sda2),
        .reset_sensor   (reset_sensor),
        .reset_crosslink(reset_crosslink),
        .q              (q),
        .config_done    ()
    );

    hdmi_i2c_top hdmi_i2c_inst (
        .rst_n      (reset_n),
        .clk        (clk_i),
        .scl        (HDMI_scl),
        .sda        (HDMI_sda),
        .config_done()
    );

endmodule
