// =====================================================================
// Acceleratore Hardware HLS (Bambu) per Pre-Processing LeNet
// =====================================================================

#define W_224 224
#define W_112 112
#define W_56  56
#define W_28  28
#define THRESHOLD 100

// ---------------------------------------------------------------------
// 1. Binarizzazione (Soglia sul Canale Verde)
// ---------------------------------------------------------------------
void binarize(unsigned char img_in[W_224][W_224], unsigned char img_bin[W_224][W_224]) {
    for (int y = 0; y < W_224; y++) {
        for (int x = 0; x < W_224; x++) {
            // Inchiostro scuro (Verde < 100) -> 1, Sfondo chiaro -> 0
            if (img_in[y][x] < THRESHOLD) {
                img_bin[y][x] = 1;
            } else {
                img_bin[y][x] = 0;
            }
        }
    }
}

// ---------------------------------------------------------------------
// 2. Dilatazione Morfologica 3x3 (Generica)
// In hardware diventa un OR a 9 ingressi
// ---------------------------------------------------------------------
template <int SIZE>
void dilate_3x3(unsigned char img_in[SIZE][SIZE], unsigned char img_out[SIZE][SIZE]) {
    for (int y = 0; y < SIZE; y++) {
        for (int x = 0; x < SIZE; x++) {
            unsigned char pixel_result = 0;
            
            // Finestra scorrevole 3x3
            for (int dy = -1; dy <= 1; dy++) {
                for (int dx = -1; dx <= 1; dx++) {
                    int ny = y + dy;
                    int nx = x + dx;
                    
                    // Controllo dei bordi (per non leggere fuori dalla memoria)
                    if (ny >= 0 && ny < SIZE && nx >= 0 && nx < SIZE) {
                        pixel_result = pixel_result | img_in[ny][nx]; // OR Logico
                    }
                }
            }
            img_out[y][x] = pixel_result;
        }
    }
}

// ---------------------------------------------------------------------
// 3. Pooling 2x2 a Maggioranza (Generico)
// In hardware diventa un sommatore e un comparatore
// ---------------------------------------------------------------------
template <int IN_SIZE, int OUT_SIZE>
void pool_2x2_majority(unsigned char img_in[IN_SIZE][IN_SIZE], unsigned char img_out[OUT_SIZE][OUT_SIZE]) {
    for (int y = 0; y < OUT_SIZE; y++) {
        for (int x = 0; x < OUT_SIZE; x++) {
            
            // Sommiamo i 4 pixel del blocco 2x2
            unsigned char sum = img_in[y*2][x*2]     + img_in[y*2+1][x*2] +
                                img_in[y*2][x*2+1]   + img_in[y*2+1][x*2+1];
            
            // Voto a maggioranza (se >= 2 neri, diventa nero)
            if (sum >= 2) {
                img_out[y][x] = 1;
            } else {
                img_out[y][x] = 0;
            }
        }
    }
}

// =====================================================================
// FUNZIONE PRINCIPALE (Top-Level)
// Questa è la funzione che Bambu trasformerà nel vostro blocco hardware
// =====================================================================
void hardware_preprocessing(unsigned char img_in_green[W_224][W_224], unsigned char img_out_28[W_28][W_28]) {
    
    // Memorie interne temporanee (Bambu le allocherà come BRAM/EBR nell'FPGA)
    static unsigned char buf_bin[W_224][W_224];
    static unsigned char buf_dil1[W_224][W_224];
    static unsigned char buf_pool1[W_112][W_112];
    static unsigned char buf_dil2[W_112][W_112];
    static unsigned char buf_pool2[W_56][W_56];

    // Esecuzione in cascata della pipeline (esattamente come nel vostro Python)
    
    // Stadio 1: 224x224
    binarize(img_in_green, buf_bin);
    dilate_3x3<W_224>(buf_bin, buf_dil1);
    pool_2x2_majority<W_224, W_112>(buf_dil1, buf_pool1);
    
    // Stadio 2: 112x112
    dilate_3x3<W_112>(buf_pool1, buf_dil2);
    pool_2x2_majority<W_112, W_56>(buf_dil2, buf_pool2);
    
    // Stadio 3: 56x56 -> 28x28 (Nessuna dilatazione)
    pool_2x2_majority<W_56, W_28>(buf_pool2, img_out_28);
}
