// =====================================================================
// FILE: hardware_preprocessing.v
// LINGUAGGIO: Verilog HDL (IEEE 1364-2001)
//
// COSA FA QUESTO FILE:
//   Descrive un CIRCUITO DIGITALE (non un programma!) che implementa
//   la pipeline di pre-processing per LeNet su FPGA ECP5 Lattice.
//
//   Riceve in ingresso un'immagine 224x224 (canale verde, 8 bit/pixel)
//   e produce in uscita un'immagine binaria 28x28 (1 bit/pixel),
//   eseguendo in sequenza:
//     1. Binarizzazione   (verde < 100 -> nero, altrimenti -> bianco)
//     2. Dilatazione 3x3  (OR morfologico su 224x224)
//     3. Pooling 2x2      (maggioranza su 224x224 -> 112x112)
//     4. Dilatazione 3x3  (OR morfologico su 112x112)
//     5. Pooling 2x2      (maggioranza su 112x112 -> 56x56)
//     6. Pooling 2x2      (maggioranza su 56x56 -> 28x28)
//
// COME FUNZIONA IN HARDWARE:
//   - I dati arrivano UN PIXEL PER CICLO DI CLOCK, in ordine raster
//     (pixel (0,0), (0,1), ..., (0,223), (1,0), ..., (223,223))
//   - I buffer intermedi sono allocati come BRAM (Block RAM EBR)
//     dell'ECP5, non come registri generici
//   - Una macchina a stati (FSM) coordina quale stadio è attivo
// =====================================================================

`timescale 1ns/1ps
// ^--- Direttiva di simulazione. Dice: "l'unità di tempo è 1 nanosecondo,
//      la precisione è 1 picosecondo". NON cambia nulla in sintesi,
//      serve solo al simulatore per interpretare i ritardi #10 ecc.

// =====================================================================
// DICHIARAZIONE DEL MODULO
// In Verilog, un "module" è l'equivalente di una classe/funzione in C:
// descrive un blocco circuitale con porte di ingresso e uscita.
// #(...) sono i PARAMETRI (costanti configurabili a compile-time, come
// i template in C++). (...) sono le PORTE (i fili che entrano/escono).
// =====================================================================
module hardware_preprocessing #(
    parameter W_224     = 224,   // Larghezza/altezza immagine input (pixel)
    parameter W_112     = 112,   // Dopo il primo pooling 2x2
    parameter W_56      = 56,    // Dopo il secondo pooling 2x2
    parameter W_28      = 28,    // Immagine output per LeNet
    parameter THRESHOLD = 100    // Soglia binarizzazione (verde < 100 -> nero)
)(
    // --- Segnali di controllo globali ---
    input  wire        clk,    // Clock: il cuore del circuito.
                               // Ad ogni fronte di salita (0->1) tutti i
                               // flip-flop aggiornano il loro valore.
    input  wire        rst_n,  // Reset sincrono ATTIVO BASSO.
                               // Quando rst_n=0, il circuito si azzera.
                               // Quando rst_n=1, funziona normalmente.
                               // La "n" finale indica "negato" (active low).

    // --- Porta di INPUT (stream pixel verde 8-bit) ---
    // Il mittente (es. camera o controller DMA) invia i pixel uno per uno.
    // Usa il protocollo "valid/ready" (handshake):
    //   - Il mittente alza i_valid=1 quando il dato in i_pixel è valido
    //   - Questo modulo risponde con o_ready=1 quando può riceverlo
    //   - Il trasferimento avviene SOLO quando ENTRAMBI sono 1
    input  wire [7:0]  i_pixel,  // Valore del pixel (0-255, canale verde)
    input  wire        i_valid,  // 1 = il dato in i_pixel è valido ora
    output wire        o_ready,  // 1 = siamo pronti a ricevere un pixel

    // --- Porta di OUTPUT (stream pixel binario 28x28) ---
    // Stessa logica handshake, ma al contrario:
    //   - Questo modulo alza o_valid=1 quando o_pixel contiene un pixel valido
    //   - Il ricevitore (LeNet) segnala i_ready=1 quando può accettarlo
    output reg         o_pixel,  // Valore del pixel binario (0 o 1)
    output reg         o_valid,  // 1 = il dato in o_pixel è valido ora
    input  wire        i_ready   // 1 = LeNet è pronta a ricevere
);

    // =================================================================
    // SEZIONE 1: PARAMETRI DERIVATI
    // Calcoliamo le dimensioni totali dei buffer e i bit necessari
    // per gli indirizzi.
    // =================================================================

    localparam PIXELS_224 = W_224 * W_224;  // 50176 pixel totali 224x224
    localparam PIXELS_112 = W_112 * W_112;  // 12544 pixel totali 112x112
    localparam PIXELS_56  = W_56  * W_56;   //  3136 pixel totali 56x56
    localparam PIXELS_28  = W_28  * W_28;   //   784 pixel totali 28x28

    // Bit necessari per indirizzare ogni buffer:
    // 2^16 = 65536 >= 50176  -> 16 bit per 224x224
    // 2^14 = 16384 >= 12544  -> 14 bit per 112x112
    // 2^12 =  4096 >=  3136  -> 12 bit per 56x56
    // 2^10 =  1024 >=   784  -> 10 bit per 28x28
    localparam ADDR_224 = 16;
    localparam ADDR_112 = 14;
    localparam ADDR_56  = 12;
    localparam ADDR_28  = 10;

    // =================================================================
    // SEZIONE 2: DEFINIZIONE DELLA FSM (Finite State Machine)
    // Una FSM è un circuito che si trova sempre in uno stato preciso
    // e cambia stato in base agli ingressi. Qui controlla quale stadio
    // della pipeline è attivo.
    //
    //  IDLE -> LOAD -> DIL1 -> POOL1 -> DIL2 -> POOL2 -> POOL3 -> OUTPUT
    //    ^                                                             |
    //    +-------------------------------------------------------------+
    //                       (ciclo per frame successivo)
    // =================================================================
    localparam [3:0]
        S_IDLE   = 4'd0,  // Circuito in attesa, nessuna elaborazione
        S_LOAD   = 4'd1,  // Ricezione pixel input + binarizzazione live
        S_DIL1   = 4'd2,  // Dilatazione morfologica 3x3 su 224x224
        S_POOL1  = 4'd3,  // Pooling 2x2 maggioranza: 224x224 -> 112x112
        S_DIL2   = 4'd4,  // Dilatazione morfologica 3x3 su 112x112
        S_POOL2  = 4'd5,  // Pooling 2x2 maggioranza: 112x112 -> 56x56
        S_POOL3  = 4'd6,  // Pooling 2x2 maggioranza:   56x56 -> 28x28
        S_OUTPUT = 4'd7,  // Invio stream output 28x28 verso LeNet
        S_DONE   = 4'd8;  // Stato finale (non usato, futuro uso)
    // [3:0] significa "vettore di 4 bit" -> può contenere valori 0-15

    reg [3:0] state;       // Stato CORRENTE della FSM (registro, mantiene valore)
    reg [3:0] next_state;  // Stato PROSSIMO (calcolato combinatoriamente)
    // "reg" in Verilog = elemento che mantiene un valore (flip-flop o latch)
    // "wire" in Verilog = filo, non mantiene nulla, valore sempre calcolato

    // =================================================================
    // SEZIONE 3: BUFFER INTERNI (BRAM / EBR ECP5)
    //
    // Questi array vengono sintetizzati come BLOCK RAM embedded dell'ECP5
    // grazie all'attributo (* ram_style = "block" *).
    // Senza quell'attributo, il sintetizzatore potrebbe usare LUT-RAM
    // (più lenta e costosa in termini di LUT).
    //
    // Ogni cella è 1 bit (pixel binario). Sono indicizzati con un
    // indirizzo lineare: addr = y * WIDTH + x
    // =================================================================

    // Buffer dopo binarizzazione (224x224 = 50176 bit = ~6.1 KB)
    (* ram_style = "block" *) reg [0:0] buf_bin  [0:PIXELS_224-1];

    // Buffer dopo prima dilatazione (224x224)
    (* ram_style = "block" *) reg [0:0] buf_dil1 [0:PIXELS_224-1];

    // Buffer dopo primo pooling (112x112 = 12544 bit = ~1.5 KB)
    (* ram_style = "block" *) reg [0:0] buf_pool1[0:PIXELS_112-1];

    // Buffer dopo seconda dilatazione (112x112)
    (* ram_style = "block" *) reg [0:0] buf_dil2 [0:PIXELS_112-1];

    // Buffer dopo secondo pooling (56x56 = 3136 bit = ~0.4 KB)
    (* ram_style = "block" *) reg [0:0] buf_pool2[0:PIXELS_56-1];

    // Buffer output finale (28x28 = 784 bit = ~0.1 KB)
    (* ram_style = "block" *) reg [0:0] buf_out  [0:PIXELS_28-1];

    // =================================================================
    // SEZIONE 4: CONTATORI
    // I contatori tracciano "dove siamo" nell'elaborazione.
    // In Verilog si usano registri che si incrementano ogni ciclo.
    // =================================================================

    // Conta i pixel ricevuti in ingresso (0 .. 50175)
    reg [ADDR_224-1:0] cnt_load;

    // Contatore generico per gli stadi di elaborazione
    // (conta pixel processati in DIL1, POOL1, DIL2, POOL2, POOL3)
    reg [ADDR_224-1:0] cnt_proc;

    // Conta i pixel inviati in uscita (0 .. 783)
    reg [ADDR_28-1:0]  cnt_out;

    // =================================================================
    // SEZIONE 5: SEGNALE o_ready
    //
    // "assign" crea un collegamento COMBINATORIO: o_ready è sempre
    // uguale all'espressione a destra, aggiornato istantaneamente.
    // Siamo pronti a ricevere pixel solo durante S_LOAD e se non
    // abbiamo ancora riempito il buffer.
    // =================================================================
    assign o_ready = (state == S_LOAD) && (cnt_load < PIXELS_224);

    // =================================================================
    // SEZIONE 6: REGISTRO DI STATO FSM
    //
    // "always @(posedge clk)" = blocco che si esegue ad OGNI fronte
    // di salita del clock. Questo è il modo in Verilog di descrivere
    // un FLIP-FLOP: aggiorna il valore solo sul fronte di clock.
    // =================================================================
    always @(posedge clk) begin
        if (!rst_n)         // Se reset attivo (rst_n=0)...
            state <= S_IDLE; // ...torna allo stato iniziale
        else
            state <= next_state; // Altrimenti vai allo stato calcolato
        // "<=" è assegnamento NON-BLOCCANTE: tutti gli "<=" nel blocco
        // vengono calcolati PRIMA e assegnati DOPO, tutti insieme.
        // È il modo corretto per descrivere flip-flop.
    end

    // =================================================================
    // SEZIONE 7: LOGICA DI TRANSIZIONE FSM (COMBINATORIA)
    //
    // "always @(*)" = blocco COMBINATORIO: ricalcolato ogni volta che
    // un segnale in ingresso cambia. Descrive logica pura, no flip-flop.
    // Qui calcoliamo next_state in base allo stato corrente e ai contatori.
    // =================================================================
    always @(*) begin
        next_state = state; // Default: rimani nello stato attuale
        case (state)
            S_IDLE:
                // Da IDLE si va subito a LOAD (inizia acquisizione frame)
                next_state = S_LOAD;

            S_LOAD:
                // Rimani in LOAD finché non hai ricevuto tutti i 50176 pixel.
                // La transizione avviene sull'ultimo pixel valido.
                if (cnt_load == PIXELS_224 - 1 && i_valid)
                    next_state = S_DIL1;

            S_DIL1:
                // Dilatazione 224x224: finita quando hai processato 50176 pixel
                if (cnt_proc == PIXELS_224 - 1)
                    next_state = S_POOL1;

            S_POOL1:
                // Pooling 224->112: finito quando hai scritto 12544 pixel output
                if (cnt_proc == PIXELS_112 - 1)
                    next_state = S_DIL2;

            S_DIL2:
                // Dilatazione 112x112: finita quando hai processato 12544 pixel
                if (cnt_proc == PIXELS_112 - 1)
                    next_state = S_POOL2;

            S_POOL2:
                // Pooling 112->56: finito quando hai scritto 3136 pixel output
                if (cnt_proc == PIXELS_56 - 1)
                    next_state = S_POOL3;

            S_POOL3:
                // Pooling 56->28: finito quando hai scritto 784 pixel output
                if (cnt_proc == PIXELS_28 - 1)
                    next_state = S_OUTPUT;

            S_OUTPUT:
                // Output: finito quando hai inviato tutti i 784 pixel E
                // il ricevitore (LeNet) li ha accettati (i_ready=1)
                if (cnt_out == PIXELS_28 - 1 && i_ready)
                    next_state = S_IDLE; // Torna a IDLE per il frame successivo

            default:
                next_state = S_IDLE; // Sicurezza: stato sconosciuto -> reset
        endcase
    end

    // =================================================================
    // SEZIONE 8: STADIO LOAD + BINARIZZAZIONE
    //
    // Ad ogni ciclo di clock, se siamo in S_LOAD e arriva un pixel
    // valido (i_valid=1), lo binarizziamo e scriviamo in buf_bin.
    // La binarizzazione avviene "inline": confrontiamo i_pixel con
    // THRESHOLD e scriviamo 1 o 0 direttamente in BRAM.
    // Questo è l'equivalente hardware della funzione binarize() del C++.
    // =================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt_load <= 0; // Reset contatore
        end else if (state == S_LOAD) begin
            if (i_valid) begin
                // i_pixel < THRESHOLD: inchiostro scuro -> pixel NERO (1)
                // i_pixel >= THRESHOLD: sfondo chiaro   -> pixel BIANCO (0)
                // Il risultato (1 o 0) va scritto nell'indirizzo cnt_load
                // del buffer buf_bin (indirizzo lineare, raster order)
                buf_bin[cnt_load] <= (i_pixel < THRESHOLD) ? 1'b1 : 1'b0;

                // Avanza il contatore. Se siamo all'ultimo pixel (50175),
                // torna a 0 (ready per il frame successivo)
                cnt_load <= (cnt_load == PIXELS_224-1) ? 0 : cnt_load + 1;
            end
            // Se i_valid=0 il contatore non avanza: aspettiamo il dato
        end else if (state == S_IDLE) begin
            cnt_load <= 0; // Azzera all'inizio di ogni frame
        end
    end

    // =================================================================
    // SEZIONE 9: CONTATORE GENERICO DI ELABORAZIONE (cnt_proc)
    //
    // Questo contatore viene usato da tutti gli stadi DIL e POOL.
    // Avanza di 1 ogni ciclo durante gli stadi attivi.
    // Quando raggiunge il massimo per quello stadio, torna a 0.
    // =================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt_proc <= 0;
        end else begin
            case (state)
                S_DIL1:
                    // Conta fino a 50175 (224x224 pixel)
                    cnt_proc <= (cnt_proc == PIXELS_224-1) ? 0 : cnt_proc + 1;

                S_POOL1:
                    // Conta fino a 12543 (112x112 pixel output)
                    cnt_proc <= (cnt_proc == PIXELS_112-1) ? 0 : cnt_proc + 1;

                S_DIL2:
                    // Conta fino a 12543 (112x112 pixel)
                    cnt_proc <= (cnt_proc == PIXELS_112-1) ? 0 : cnt_proc + 1;

                S_POOL2:
                    // Conta fino a 3135 (56x56 pixel output)
                    cnt_proc <= (cnt_proc == PIXELS_56-1) ? 0 : cnt_proc + 1;

                S_POOL3:
                    // Conta fino a 783 (28x28 pixel output)
                    cnt_proc <= (cnt_proc == PIXELS_28-1) ? 0 : cnt_proc + 1;

                default:
                    cnt_proc <= 0; // Azzera in tutti gli altri stati
            endcase
        end
    end

    // =================================================================
    // SEZIONE 10: DILATAZIONE 3x3 su 224x224 (buf_bin -> buf_dil1)
    //
    // COSA FA: per ogni pixel (y,x), calcola l'OR logico dei 9 pixel
    // nella finestra 3x3 centrata su (y,x). Questo "dilata" le zone
    // nere: un pixel bianco vicino a un pixel nero diventa nero.
    // Equivale alla funzione dilate_3x3<224>() del C++.
    //
    // FUNZIONE addr224: calcola l'indirizzo lineare di un pixel (y,x)
    // con gestione dei bordi (clamp: se y<0 usa y=0, se y>=224 usa y=223).
    // "function" in Verilog descrive logica combinatoria riutilizzabile.
    // =================================================================
    function [ADDR_224-1:0] addr224;
        input integer y, x;
        integer cy, cx;
        begin
            // Clamp sulle righe: porta y nel range [0, W_224-1]
            cy = (y < 0) ? 0 : (y >= W_224 ? W_224-1 : y);
            // Clamp sulle colonne: porta x nel range [0, W_224-1]
            cx = (x < 0) ? 0 : (x >= W_224 ? W_224-1 : x);
            // Indirizzo lineare: riga*larghezza + colonna
            addr224 = cy * W_224 + cx;
        end
    endfunction

    // Coordinate (y,x) del pixel corrente ricavate dal contatore lineare
    // NOTA: divisione e modulo per costante vengono sintetizzati come
    // shift e sottrattori dall'ECP5 synthesizer (Yosys).
    wire signed [8:0] dy1_y = cnt_proc / W_224; // Riga corrente (0..223)
    wire signed [8:0] dy1_x = cnt_proc % W_224; // Colonna corrente (0..223)

    always @(posedge clk) begin
        if (state == S_DIL1) begin
            // OR dei 9 pixel nella finestra 3x3 attorno a (dy1_y, dy1_x).
            // In hardware questo diventa una porta OR a 9 ingressi
            // collegata alle uscite di 9 celle di BRAM.
            // Riga sopra  (-1): (dy1_y-1, dx-1), (dy1_y-1, dx), (dy1_y-1, dx+1)
            // Riga media  ( 0): (dy1_y,   dx-1), (dy1_y,   dx), (dy1_y,   dx+1)
            // Riga sotto  (+1): (dy1_y+1, dx-1), (dy1_y+1, dx), (dy1_y+1, dx+1)
            buf_dil1[cnt_proc] <=
                buf_bin[addr224(dy1_y-1, dy1_x-1)] | buf_bin[addr224(dy1_y-1, dy1_x)] | buf_bin[addr224(dy1_y-1, dy1_x+1)] |
                buf_bin[addr224(dy1_y,   dy1_x-1)] | buf_bin[addr224(dy1_y,   dy1_x)] | buf_bin[addr224(dy1_y,   dy1_x+1)] |
                buf_bin[addr224(dy1_y+1, dy1_x-1)] | buf_bin[addr224(dy1_y+1, dy1_x)] | buf_bin[addr224(dy1_y+1, dy1_x+1)];
            // ↑ Scrive il risultato in buf_dil1 all'indirizzo lineare corrente
        end
    end

    // =================================================================
    // SEZIONE 11: POOLING 2x2 MAGGIORANZA 224->112 (buf_dil1 -> buf_pool1)
    //
    // COSA FA: divide l'immagine 224x224 in blocchi 2x2.
    // Per ogni blocco somma i 4 pixel. Se la somma >= 2 (maggioranza),
    // il pixel output è 1 (nero), altrimenti 0 (bianco).
    // Equivale a pool_2x2_majority<224,112>() del C++.
    //
    // I 4 pixel del blocco 2x2 con angolo in alto a sinistra (y*2, x*2):
    //   (y*2, x*2)   (y*2, x*2+1)
    //   (y*2+1, x*2) (y*2+1, x*2+1)
    // =================================================================

    // Coordinate del pixel OUTPUT nel buffer 112x112
    wire [6:0] p1_y = cnt_proc / W_112; // Riga output (0..111)
    wire [6:0] p1_x = cnt_proc % W_112; // Colonna output (0..111)

    // Somma dei 4 pixel del blocco 2x2 corrispondente in buf_dil1 (224x224)
    // {1'b0, ...} aggiunge uno zero davanti per evitare overflow nella somma
    // p1_sum può valere 0, 1, 2, 3, 4 -> serve almeno 3 bit (usiamo 2 bit
    // per la somma parziale, ma in hardware Verilog espande automaticamente)
    wire [1:0] p1_sum =
        {1'b0, buf_dil1[p1_y*2   * W_224 + p1_x*2  ]} +  // pixel (2y,   2x)
        {1'b0, buf_dil1[p1_y*2+1 * W_224 + p1_x*2  ]} +  // pixel (2y+1, 2x)
        {1'b0, buf_dil1[p1_y*2   * W_224 + p1_x*2+1]} +  // pixel (2y,   2x+1)
        {1'b0, buf_dil1[p1_y*2+1 * W_224 + p1_x*2+1]};   // pixel (2y+1, 2x+1)

    always @(posedge clk) begin
        if (state == S_POOL1)
            // Voto a maggioranza: se 2 o più pixel su 4 sono neri -> nero
            buf_pool1[cnt_proc] <= (p1_sum >= 2) ? 1'b1 : 1'b0;
    end

    // =================================================================
    // SEZIONE 12: DILATAZIONE 3x3 su 112x112 (buf_pool1 -> buf_dil2)
    // Identica alla sezione 10 ma opera su 112x112.
    // =================================================================
    function [ADDR_112-1:0] addr112;
        input integer y, x;
        integer cy, cx;
        begin
            cy = (y < 0) ? 0 : (y >= W_112 ? W_112-1 : y);
            cx = (x < 0) ? 0 : (x >= W_112 ? W_112-1 : x);
            addr112 = cy * W_112 + cx;
        end
    endfunction

    wire signed [7:0] dy2_y = cnt_proc / W_112; // Riga corrente (0..111)
    wire signed [7:0] dy2_x = cnt_proc % W_112; // Colonna corrente (0..111)

    always @(posedge clk) begin
        if (state == S_DIL2) begin
            // Stessa logica di DIL1 ma legge buf_pool1 e scrive buf_dil2
            buf_dil2[cnt_proc] <=
                buf_pool1[addr112(dy2_y-1, dy2_x-1)] | buf_pool1[addr112(dy2_y-1, dy2_x)] | buf_pool1[addr112(dy2_y-1, dy2_x+1)] |
                buf_pool1[addr112(dy2_y,   dy2_x-1)] | buf_pool1[addr112(dy2_y,   dy2_x)] | buf_pool1[addr112(dy2_y,   dy2_x+1)] |
                buf_pool1[addr112(dy2_y+1, dy2_x-1)] | buf_pool1[addr112(dy2_y+1, dy2_x)] | buf_pool1[addr112(dy2_y+1, dy2_x+1)];
        end
    end

    // =================================================================
    // SEZIONE 13: POOLING 2x2 MAGGIORANZA 112->56 (buf_dil2 -> buf_pool2)
    // =================================================================
    wire [5:0] p2_y = cnt_proc / W_56;  // Riga output (0..55)
    wire [5:0] p2_x = cnt_proc % W_56;  // Colonna output (0..55)

    wire [1:0] p2_sum =
        {1'b0, buf_dil2[p2_y*2   * W_112 + p2_x*2  ]} +
        {1'b0, buf_dil2[p2_y*2+1 * W_112 + p2_x*2  ]} +
        {1'b0, buf_dil2[p2_y*2   * W_112 + p2_x*2+1]} +
        {1'b0, buf_dil2[p2_y*2+1 * W_112 + p2_x*2+1]};

    always @(posedge clk) begin
        if (state == S_POOL2)
            buf_pool2[cnt_proc] <= (p2_sum >= 2) ? 1'b1 : 1'b0;
    end

    // =================================================================
    // SEZIONE 14: POOLING 2x2 MAGGIORANZA 56->28 (buf_pool2 -> buf_out)
    // Terzo e ultimo pooling. Nessuna dilatazione prima (come nel C++).
    // =================================================================
    wire [4:0] p3_y = cnt_proc / W_28;  // Riga output (0..27)
    wire [4:0] p3_x = cnt_proc % W_28;  // Colonna output (0..27)

    wire [1:0] p3_sum =
        {1'b0, buf_pool2[p3_y*2   * W_56 + p3_x*2  ]} +
        {1'b0, buf_pool2[p3_y*2+1 * W_56 + p3_x*2  ]} +
        {1'b0, buf_pool2[p3_y*2   * W_56 + p3_x*2+1]} +
        {1'b0, buf_pool2[p3_y*2+1 * W_56 + p3_x*2+1]};

    always @(posedge clk) begin
        if (state == S_POOL3)
            buf_out[cnt_proc] <= (p3_sum >= 2) ? 1'b1 : 1'b0;
    end

    // =================================================================
    // SEZIONE 15: STADIO OUTPUT
    // Legge buf_out (28x28) e invia i pixel uno per uno verso LeNet
    // tramite handshake o_valid / i_ready.
    // =================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt_out  <= 0;
            o_valid  <= 0;
            o_pixel  <= 0;
        end else if (state == S_OUTPUT) begin
            o_valid <= 1'b1;                 // Segnala che il dato è valido
            o_pixel <= buf_out[cnt_out];     // Metti sul bus il pixel corrente

            if (i_ready) begin
                // Il ricevitore ha accettato il pixel: avanza al prossimo
                cnt_out <= (cnt_out == PIXELS_28-1) ? 0 : cnt_out + 1;
                // Se era l'ultimo pixel, torna a 0 (pronto per frame successivo)
            end
            // Se i_ready=0, il ricevitore non è pronto: aspettiamo
            // (cnt_out non avanza, o_pixel rimane stabile)
        end else begin
            o_valid <= 1'b0; // Non siamo in OUTPUT: dati non validi
            cnt_out <= 0;
        end
    end

endmodule
// =====================================================================
// FINE DEL MODULO
// Questo file descrive interamente il circuito di pre-processing.
// Il sintetizzatore Yosys (via nextpnr per ECP5) lo trasformerà in
// una netlist di porte logiche e la mapperà sulle risorse dell'ECP5:
//   - LUT4 per la logica combinatoria (OR, confrontatori, mux)
//   - FF (Flip-Flop) per tutti i registri (state, cnt_*, ecc.)
//   - EBR (Embedded Block RAM) per i buffer buf_*
// =====================================================================
