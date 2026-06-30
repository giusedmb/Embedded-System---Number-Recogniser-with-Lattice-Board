// ==================================================================
// Copyright (c) 2017 by Lattice Semiconductor Corporation
// ALL RIGHTS RESERVED
// ------------------------------------------------------------------
// MODIFICHE DI INTEGRAZIONE (rispetto alla demo originale Lattice):
//   - Istanza di hardware_preprocessing collegata all'uscita ISP
//   - Contatore pixel (hcnt/vcnt) sincronizzato a DE e vsync
//   - Display buffer 784 bit (28x28) per il risultato preprocessing
//   - MUX visivo sull'uscita HDMI (localparam MUX_SEL_PREPROCESSING)
//
// PER ABILITARE LA VISUALIZZAZIONE DEL PREPROCESSING:
//   Cambia la localparam MUX_SEL_PREPROCESSING da 1'b0 a 1'b1
//   e risintetizza. Con 1'b0 il flusso ISP originale e' invariato.
// ==================================================================

module RAW10toParallel (
    input           clk_i,
    input           reset_n,

    // Raw10 input from Crosslink
    input           CSI2_sens_clk,
    input           CSI2_sens_fv,
    input           CSI2_sens_lv,
    input  [9:0]    CSI2_sens_data,

    // Parallel video to SiI1136
    output reg [11:0] pix_red,
    output reg [11:0] pix_green,
    output reg [11:0] pix_blue,
    output reg        hsync,
    output reg        vsync,
    output reg        data_enable,
    output            pixclk_out,

    // Sensor configuration
    inout  wire     scl,
    inout  wire     sda,
    inout  wire     scl2,
    inout  wire     sda2,

    // HDMI configuration
    inout           HDMI_scl,
    inout           HDMI_sda,

    output wire     reset_sensor,
    output wire     reset_crosslink,

    // blinking led
    output          q
);

    // ==================================================================
    // [INTEGRAZIONE] MUX SELECTOR
    // 1'b0 = passthrough ISP originale (default, demo invariata)
    // 1'b1 = mostra l'immagine 28x28 upscalata 8x sull'uscita HDMI
    // ==================================================================
    localparam MUX_SEL_PREPROCESSING = 1'b1;

    // ==================================================================
    // Registrazione ingresso video (dal Crosslink RAW10)
    // ==================================================================
    reg        fv_i;
    reg        lv_i;
    reg [9:0]  data_i;

    always @ (posedge CSI2_sens_clk or negedge reset_n)
        if (!reset_n) begin
            fv_i   <= 0;
            lv_i   <= 0;
            data_i <= 0;
        end else begin
            fv_i   <= CSI2_sens_fv;
            lv_i   <= CSI2_sens_lv;
            data_i <= CSI2_sens_data;
        end

    // ==================================================================
    // Uscite ISP (wire pre-registro, dalla image_pipe)
    // ==================================================================
    wire [35:0] rgb;
    wire [11:0] red_o, green_o, blue_o;
    wire        hsync_o;
    wire        vsync_o;
    wire        data_enable_o;

    assign pixclk_out = ~CSI2_sens_clk;
    assign red_o   = rgb[35:24];
    assign green_o = rgb[23:12];
    assign blue_o  = rgb[11:0];

    // ==================================================================
    // [INTEGRAZIONE] Rilevamento fronte di salita di vsync_o
    // Genera un impulso di 1 ciclo = i_frame_start per il modulo
    // di preprocessing. Segnala l'inizio di un nuovo frame ISP.
    // ==================================================================
    reg vsync_o_prev;
    always @(posedge CSI2_sens_clk or negedge reset_n) begin
        if (!reset_n) vsync_o_prev <= 1'b0;
        else          vsync_o_prev <= vsync_o;
    end
    wire frame_start_pulse = vsync_o & ~vsync_o_prev;  // impulso 1 ciclo

    // ==================================================================
    // [INTEGRAZIONE] Contatori pixel nel dominio CSI2_sens_clk
    // ==================================================================
    reg [11:0] hcnt;      // [FIX] 12-bit per supportare schermi fino a 4K!
    reg [11:0] vcnt;      // [FIX] 12-bit
    reg        de_o_prev; 

    always @(posedge CSI2_sens_clk or negedge reset_n) begin
        if (!reset_n) begin
            hcnt      <= 12'd0;
            vcnt      <= 12'd0;
            de_o_prev <= 1'b0;
        end else begin
            de_o_prev <= data_enable_o;

            if (vsync_o) begin
                vcnt <= 12'd0;
            end else if (~de_o_prev & data_enable_o) begin
                hcnt <= 12'd0;
            end else if (data_enable_o) begin
                hcnt <= hcnt + 12'd1;
            end

            if (de_o_prev & ~data_enable_o) begin
                vcnt <= vcnt + 12'd1;
            end
        end
    end

    // ==================================================================
    // [INTEGRAZIONE] Istanza hardware_preprocessing
    //
    // i_pixel  <- canale verde 12-bit ISP, top 8 bit (MSB-aligned)
    // i_valid  <- data_enable_o (DE pre-registro, attivo sui pixel validi)
    // i_frame_start <- impulso 1 ciclo su rising edge vsync
    // i_ready  <- 1'b1: accettiamo sempre l'output (va in display_buf)
    // ==================================================================
    wire       pp_o_ready;
    wire       pp_o_pixel;
    wire       pp_o_valid;

    hardware_preprocessing #(
        .W_224    (224),
        .W_112    (112),
        .W_56     (56),
        .W_28     (28),
        .THRESHOLD(100)
    ) u_preprocessing (
        .clk           (CSI2_sens_clk),
        .rst_n         (reset_n),
        // Input: canale verde 8-bit (bit 11:4 = MSB del dato 12-bit ISP)
        .i_pixel       (green_o[11:4]),
        .i_valid       (data_enable_o),
        .o_ready       (pp_o_ready),
        .i_frame_start (frame_start_pulse),
        // Output: pixel binario 28x28 — accettato sempre
        .o_pixel       (pp_o_pixel),
        .o_valid       (pp_o_valid),
        .i_ready       (1'b1)
    );

    // ==================================================================
    // [INTEGRAZIONE] Display buffer 28x28
    // ==================================================================
    reg [783:0] display_buf;   // 28*28 = 784 bit
    reg [9:0]   disp_wr_cnt;   // contatore scrittura (0..783)

    always @(posedge CSI2_sens_clk or negedge reset_n) begin
        if (!reset_n) begin
            disp_wr_cnt <= 10'd0;
            display_buf <= 784'b0;
        end else if (frame_start_pulse) begin
            // [FIX] Sincronizzazione perfetta! Azzera l'indice ad ogni nuovo frame
            disp_wr_cnt <= 10'd0; 
        end else if (pp_o_valid) begin
            display_buf[disp_wr_cnt] <= pp_o_pixel;
            disp_wr_cnt <= (disp_wr_cnt == 10'd783) ? 10'd0 : disp_wr_cnt + 10'd1;
        end
    end    
	
	// ==================================================================
    // [INTEGRAZIONE] Indirizzo di lettura del display buffer
    //
    // Upscale 8x: ogni pixel 28x28 copre un blocco 8x8 nell'immagine
    // originale 224x224. hcnt[7:3] = hcnt/8 (colonna 28x28, 0..27)
    //                    vcnt[7:3] = vcnt/8  (riga    28x28, 0..27)
    //
    // disp_addr = row*28 + col, calcolato come shifts+adds da Synplify.
    // In-range: solo per hcnt < 224 e vcnt < 224 (area 224x224).
    // ==================================================================
    wire [4:0] disp_col  = hcnt[7:3];             // 0..27
    wire [4:0] disp_row  = vcnt[7:3];             // 0..27
    wire [9:0] disp_row10 = {5'b0, disp_row};     // estendi a 10 bit
    wire [9:0] disp_addr  = (disp_row10 * 10'd28) + {5'b0, disp_col};

    // Pixel dal display buffer (lettura combinatoria)
    wire       pp_disp_pix = display_buf[disp_addr];

    // Area valida 224x224: fuori da questa zona si mostra il segnale ISP
	wire        in_active_area = (hcnt < 12'd224) & (vcnt < 12'd224);
    // Pixel da mostrare se MUX = preprocessing:
    // bianco (12'hFFF) o nero (12'h000) in base al bit binario
    wire [11:0] pp_channel = {12{pp_disp_pix}};   // 12'hFFF o 12'h000

    // ==================================================================
    // Registrazione uscita video verso HDMI (MUX incluso)
    //
    // generate if/else su localparam: Synplify rimuove il ramo morto
    // staticamente a compile-time (zero overhead a runtime).
    // ==================================================================
    always @ (posedge CSI2_sens_clk or negedge reset_n)
        if (!reset_n) begin
            pix_red     <= 12'd0;
            pix_green   <= 12'd0;
            pix_blue    <= 12'd0;
            hsync       <= 1'b0;
            vsync       <= 1'b0;
            data_enable <= 1'b0;
        end else begin
            hsync       <= hsync_o;
            vsync       <= vsync_o;
            data_enable <= data_enable_o;

            if (MUX_SEL_PREPROCESSING) begin
                // ---- Modalita' PREPROCESSING ----
                // Nell'area 224x224: mostra l'immagine binaria 28x28 upscalata
                // Fuori dall'area 224x224: passthrough ISP (per risoluz. > 224)
                if (in_active_area) begin
                    pix_red   <= pp_channel;
                    pix_green <= pp_channel;
                    pix_blue  <= pp_channel;
                end else begin
                    pix_red   <= red_o;
                    pix_green <= green_o;
                    pix_blue  <= blue_o;
                end
            end else begin
                // ---- Modalita' PASSTHROUGH (default) ----
                // Demo originale Lattice, nessuna modifica al segnale HDMI
                pix_red   <= red_o;
                pix_green <= green_o;
                pix_blue  <= blue_o;
            end
        end

    // ==================================================================
    // Pipeline ISP (image_pipe: debayer + gamma + CSC + FIFO)
    // ==================================================================
    image_pipe image_pipe_inst (
        .reset_n    (reset_n),
        .clk        (CSI2_sens_clk),
        .frame_valid(fv_i),
        .line_valid (lv_i),
        .pixdata    ({data_i, 2'b00}),
        .vsync      (vsync_o),
        .hsync      (hsync_o),
        .de         (data_enable_o),
        .rgb_data   (rgb)
    );

    // ==================================================================
    // I2C controller: configurazione sensori
    // ==================================================================
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

    // ==================================================================
    // I2C controller: configurazione HDMI SiI1136
    // ==================================================================
    hdmi_i2c_top hdmi_i2c_top_inst (
        .rst_n      (reset_n),
        .clk        (clk_i),
        .scl        (HDMI_scl),
        .sda        (HDMI_sda),
        .config_done()
    );

endmodule
