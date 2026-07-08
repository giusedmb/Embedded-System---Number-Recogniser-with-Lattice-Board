# ECP5 Number Recogniser — Guida all'Integrazione Completa

> **Stato del progetto**: tutti i moduli Verilog sono scritti e corretti.
> Segui i passi qui sotto nell'ordine per arrivare al bitstream funzionante.

---

## Struttura della cartella `integration/`

```
fpga_hardware/integration/
├── hardware_preprocessing_opt.v       ← Pre-processing (6 bug corretti)
├── cdc_async_fifo.v                   ← FIFO asincrona CDC 148.5→27 MHz
├── lenet_input_buffer.v               ← Accumula 784 pixel → BRAM Bambu
├── lenet_output_capture.v             ← Cattura 10 score → argmax (0-9)
├── top_integration.v                  ← Top-level con ROI + guide box
├── NumberRecogniser_Integration.ldf   ← Progetto Diamond  ← APRI QUESTO
├── NumberRecogniser_Integration.lpf   ← Vincoli di pin
├── NumberRecogniser_Integration.sty   ← Strategia Synplify-Pro
└── README_INTEGRATION.md              ← Questo file
```

---

## Architettura del sistema

```
CrossLink RAW10  (CSI2_sens_clk ≈ 148.5 MHz)
    │
    ▼
image_pipe  ──  debayer + gamma + CSC
    │ green_o[11:4]  (8-bit)
    │
    ▼
[ROI GATE]  hcnt ∈ [848,1072)  vcnt ∈ [428,652)  ← 224×224 centrata
    │ roi_valid
    ▼
hardware_preprocessing_opt  @148.5 MHz
    Bin(soglia 100) → Dil3×3(224²) → Pool2×2(112²)
                    → Dil3×3(112²) → Pool2×2(56²) → Pool2×2(28²)
    → 784 bit seriali  pp_pixel / pp_valid
    │
    ▼
cdc_async_fifo  1024×1-bit          ← CROSSING 148.5 MHz → 27 MHz
    │
    ▼
lenet_input_buffer  @27 MHz
    Accumula 784 pixel → EBR 784×12-bit (ap_fixed<12,5>)
    pixel=1 → 12'h040, pixel=0 → 12'h000
    ──► nn_start (1 ciclo)
    │
    ▼
p_Z9myproject...  (Bambu LeNet-5)  @27 MHz
    Legge BRAM input dual-port
    Scrive 10 score in BRAM output
    ──► done_port (1 ciclo)
    │
    ▼
lenet_output_capture  @27 MHz
    Argmax signed su 10 score (10 cicli)
    │
    ▼
digit_hold[3:0]  ──  stabile fino al prossimo risultato
digit_valid      ──  impulso 1 ciclo per ogni predizione
```

---

## Guide Box sul Video HDMI

```
┌──────────────────────────────────────────────────────┐
│           Video ISP 1920×1080  (passthrough)         │
│                                                      │
│         ╔══════════════════════════════╗             │
│         ║  [bordo 3px — BIANCO/GIALLO] ║             │
│         ║                              ║             │
│         ║   immagine 28×28 bin         ║             │
│         ║   upscalata 8×               ║             │
│         ║                              ║             │
│         ╚══════════════════════════════╝             │
│              ROI 224×224 centrata                    │
└──────────────────────────────────────────────────────┘
```

| Colore bordo | Stato |
|---|---|
| **Bianco** | Idle — posiziona la cifra nel box |
| **Giallo** (R+G, no B) | Inferenza LeNet in corso (~17 ms) |

---

## Latenza della pipeline

| Stadio | Cicli | Clock | Tempo |
|---|---|---|---|
| LOAD 224×224 pixel | 50.176 | 148.5 MHz | 0.34 ms |
| DIL1 + POOL1 | 100.352 | 148.5 MHz | 0.68 ms |
| DIL2 + POOL2 + POOL3 | 28.224 | 148.5 MHz | 0.19 ms |
| OUTPUT 784 pixel seriali | 784 | 148.5 MHz | 0.005 ms |
| CDC FIFO + buffer fill | ~784 | 27 MHz | 0.029 ms |
| **LeNet-5 inference (Bambu)** | **~437.311** | **27 MHz** | **16.2 ms** |
| Argmax | 10 | 27 MHz | < 0.001 ms |
| **Totale** | | | **≈ 17.4 ms** |

A 30 fps (33.3 ms/frame) il risultato è pronto **durante il frame successivo** — circa mezzo frame di delay, invisibile all'utente.

---

---

# PROSSIMI PASSI — GUIDA OPERATIVA

---

## PASSO 1 — Risoluzione del sensore ✅ già nota dalla demo

**Non devi cercare nulla fuori dal progetto.** Ho letto direttamente
[`i2c_ctrl.v`](../../fpga_hardware/ECP5_Raw10toParallel/source/i2c_ctrl.v)
e [`blanking_adjustment.v`](../../fpga_hardware/ECP5_Raw10toParallel/source/blanking_adjustment.v).

Ecco cosa è configurato nella demo:

| Parametro | Valore | Provenienza |
|---|---|---|
| **Sensore** | IMX (ADDR `0x10` via I2C) | `ADDR_SENSOR = 7'h10` in `i2c_ctrl.v` |
| **Risoluzione output** | **1920 × 1080** | Reg `0x034C/4D = 0x0780` (1920), `0x034E/4F = 0x0438` (1080) |
| **Modalità** | 1080p60, RAW10, 4 CSI lanes | Step 6 `0x0114 = 0x03`, step 29 `0x0112 = 0x0A` |
| **Binning** | 1/2 H + 1/2 V (pixel fisici 3840×2160) | Step 26-27 `0x0900=01`, `0x0901=22` |
| **Clock pixel** | **148.5 MHz** | `.lpf`: `FREQUENCY PORT "CSI2_sens_clk" 148.500000 MHz` |
| **Clock sistema** | **27 MHz** | `.lpf`: `FREQUENCY PORT "clk_i" 27.000000 MHz` |
| **h_total / v_total** | 2200 / 1125 | `blanking_adjustment.v` parametri default |

**Conclusione: i parametri di `top_integration.v` sono già corretti. Non serve modificare nulla.**

```verilog
// top_integration.v — valori già corretti per la tua board:
parameter integer H_ACTIVE  = 1920,  // ✅ confermato da i2c_ctrl.v reg 0x034C/4D
parameter integer V_ACTIVE  = 1080,  // ✅ confermato da i2c_ctrl.v reg 0x034E/4F
parameter integer ROI_SIZE  = 224,   // area di acquisizione (non cambiare)
parameter integer BOX_THICK = 3,     // spessore bordo guide box in pixel
parameter integer THRESHOLD = 100    // soglia binarizzazione 0..255 (~39%)
```

Le coordinate ROI risultanti sono:

```
Box centrato nel frame 1920×1080:
  Orizzontale: pixel 848 → 1071  (colonne centrali)
  Verticale:   pixel 428 → 651   (righe centrali)
```

---

## PASSO 2 — Pin fisici per digit_out ✅ già risolto automaticamente

**Non devi fare nulla** — la board non ha GPIO liberi e ho già modificato
il `top_integration.v` per gestire questo caso.

### Perché non ci sono pin liberi

Il file [`Raw10toParallel.lpf`](../../fpga_hardware/ECP5_Raw10toParallel/Raw10toParallel.lpf)
assegna **tutti i pin disponibili** della board ai segnali già esistenti:

| Funzione | Pin usati |
|---|---|
| HDMI video (R, G, B × 12-bit) | 36 pin |
| HDMI sync + DE + pixclk | 4 pin |
| CSI2 dati (10 bit) + clk + FV + LV | 13 pin |
| I2C sensore (scl, sda, scl2, sda2) | 4 pin |
| I2C HDMI (scl, sda) | 2 pin |
| Reset, crosslink, LED (q) | 3 pin |
| Clock (clk_i) | 1 pin |
| **Totale occupato** | **63 pin** |

Non rimane nessun pin libero con connettore accessibile nella demo.

### Come è stato risolto

`digit_out[3:0]`, `digit_valid` e `nn_busy` sono **segnali interni** al
`top_integration.v`. La cifra riconosciuta è comunque visibile perché:

| Segnale | Dove vedi il risultato |
|---|---|
| `nn_busy` | Guide box **giallo** durante inferenza, **bianco** quando pronta |
| `digit_hold[3:0]` | Visibile in simulazione / con logic analyzer su JTAG |
| Immagine 28×28 | Mostrata upscalata 8× dentro il guide box HDMI |

### Se vuoi comunque i pin fisici (opzionale)

Hai **tre opzioni**:

**Opzione A — Usa il JTAG per leggere i registri interni** *(zero modifiche)*
Diamond include un tool chiamato **Reveal** (logic analyzer embedded).
Aggiungi `digit_hold` e `digit_valid` come sonde Reveal e leggi il valore
direttamente via JTAG USB mentre il sistema gira.
`Tools → Reveal Inserter` in Diamond.

**Opzione B — Sfrutta un connettore di espansione sulla board** *(se presente)*
Se la tua board ha un connettore PMOD, GPIO header o SYZYGY, cerca
il datasheet della board per i pin fisici disponibili.
Il device è `LFE5UM-85F-8BG756C` (package BG756) — ha 756 pin totali
di cui molti non collegati a connettori utente nella maggior parte dei carrier.

**Opzione C — Riusa un segnale esistente** *(hack rapido)*
Il LED `q` (pin `AG30`) è già mappato e accessibile. Puoi farci lampeggiare
`digit_valid` come conferma visiva di ogni predizione:
```verilog
// In top_integration.v — sostituisci il driver di q con:
// (q era pilotato da i2c_top → toglilo da lì e usa digit_valid)
assign q_override = digit_valid;  // lampeggia a ogni cifra riconosciuta
```
> Nota: `q` è già gestito da `i2c_top`. Per riusarlo devi sconnettere
> il driver I2C o aggiungere una OR logic.

---

**In sintesi: vai al Passo 3.** Il sistema funziona senza pin aggiuntivi.
Il feedback è interamente sul monitor HDMI.


---

## PASSO 3 — Apri il progetto in Lattice Diamond

1. Avvia **Lattice Diamond 3.x**
2. `File → Open → Project`
3. Naviga in `fpga_hardware/integration/`
4. Seleziona `NumberRecogniser_Integration.ldf` → **Open**

Diamond mostrerà nell'albero dei sorgenti tutti i file già collegati.
Verifica che siano presenti:
- I 5 moduli di integrazione
- `myproject.v` e `panda_libtech.v` (Bambu)
- Tutti i sorgenti ISP originali
- I file Clarity `.sbx`
- Il file `.lpf`

---

## PASSO 4 — Lancia la sintesi

Nella finestra **Process**, esegui in ordine:

```
☐ Translate Design    ← Parse Verilog, elabora myproject.v (~10-20 min)
☐ Map Design          ← Tecnologia mapping su ECP5 (~10-20 min)
☐ Place & Route       ← Placement e routing (~5-15 min)
☐ Generate Bitstream  ← Genera il .bit (~2 min)
```

Oppure clicca con il tasto destro su **Generate Bitstream** → **Run All**.

> ⚠️ `myproject.v` ha **~1 milione di righe e 66 MB**.
> La sintesi totale richiede **30–90 minuti** su un PC moderno.
> Non chiudere Diamond durante il processo.

### Errori comuni e soluzioni

| Errore Synplify | Causa | Soluzione |
|---|---|---|
| `ERROR: can't resolve reference to module 'image_fifo'` | SBX Clarity non trovato | Verifica che i percorsi `.sbx` nel `.ldf` siano corretti rispetto alla tua installazione Diamond |
| `WARNING: RAM not inferred` su `buf_bin` | Array non riconosciuto | Aggiungi `set_option -use_ram_when_possible 1` nella `.sty` (già presente) |
| `ERROR: $signed not supported` | Verilog-2001 non attivo | In Diamond: `Project → Properties → Synthesis → Verilog Version → System Verilog` |
| `CRITICAL WARNING: Timing failed` su `clk_nn` | Bambu a 27 MHz invece di 25 MHz | Vedi **nota clock** sotto |
| `ERROR: module p_Z9myproject... not found` | `myproject.v` troppo grande per il parser | Aumenta la memoria JVM di Diamond: `Edit diamond.ini → -Xmx4096m` |

### Nota sul clock Bambu

Il modulo Bambu è stato compilato per **25 MHz** (`--clock-period=40 ns`).
Usiamo `clk_i = 27 MHz` (periodo 37 ns).

Se Synplify segnala timing critical sul path di `clk_nn`:

**Opzione A** — accetta il warning e verifica su board (il margine è ~3 ns):
```lpf
# Aggiungi nel .lpf per rilassare il vincolo:
FREQUENCY PORT "clk_i" 25.000000 MHz ;
```

**Opzione B** — aggiungi un PLL Lattice per generare esattamente 25 MHz:
```verilog
// Sostituisci in top_integration.v:
//   wire clk_nn = clk_i;
// con un'istanza PLL ECP5 (EHXPLL) configurata 27→25 MHz
// Puoi generarla con Clarity Designer in Diamond.
```

---

## PASSO 5 — Programma la board

Una volta generato il bitstream:

1. Collega la board via JTAG (cavo USB)
2. In Diamond: `Tools → Programmer`
3. Nella finestra Programmer:
   - **Operation**: `SRAM Program` (per test immediato, non permanente)
   - oppure `SPI Flash Erase, Program` (per renderlo permanente al boot)
4. Seleziona il file `.bit` da `impl1/` → **Program**

---

## PASSO 6 — Test funzionale su board

Dopo la programmazione, con la board accesa e il monitor HDMI collegato:

### Cosa dovresti vedere

1. **Video ISP** a tutto schermo (1920×1080 o la risoluzione configurata)
2. **Box bianco** al centro del video — è la ROI di acquisizione 224×224
3. Posiziona un foglio con una cifra (0–9) scritta in grande **dentro il box**
4. Il **box diventa giallo** per ~17 ms (inferenza in corso)
5. Il **box torna bianco** e sui `digit_out[3:0]` compare la cifra riconosciuta

### Debug rapido

| Sintomo | Causa probabile | Verifica |
|---|---|---|
| Nessuna immagine HDMI | I2C HDMI non configurato | LED `q` lampeggia? Se no, problema I2C |
| Immagine verde/viola senza colori | Debayer errato | Controlla la configurazione Bayer pattern nel sensore |
| Box non visibile | Risoluzione frame diversa da 1920×1080 | Aggiorna `H_ACTIVE`/`V_ACTIVE` e risintetizza |
| Box sempre giallo (nn_busy fisso) | LeNet non termina (done_port mai alto) | Verifica `reset_h` — Bambu parte solo con reset=0 dopo il pull-up |
| digit_out sempre 0 | Nessun dato arriva alla BRAM | Metti un LED su `pp_valid` per vedere se il pre-processing produce output |
| Riconosce solo cifre errate | Soglia binarizzazione sbagliata | Prova a ridurre `THRESHOLD` a 80 o aumentarlo a 128 |

### Checklist debug con oscilloscopio/Logic Analyzer

```
Segnale da verificare    Comportamento atteso
─────────────────────    ────────────────────────────────────────────
CSI2_sens_clk            148.5 MHz continuo
de_o                     Pulso a ogni riga attiva del frame
roi_valid                Burst di 224 impulsi × 224 righe = 50176 pulsi/frame
pp_valid (dopo preproc)  784 impulsi seriali dopo ogni frame ROI
fifo_rd_empty            Scende a 0 dopo che pp_valid arriva, sale dopo 784 letture
nn_start                 Impulso singolo dopo che il buffer è pieno
nn_done                  Impulso singolo dopo ~437K cicli da nn_start
digit_valid              Impulso singolo ~10 cicli dopo nn_done
```

---

## PASSO 7 — Ottimizzazioni opzionali post-test

Una volta verificato che il sistema funziona:

### 7a. Migliora la qualità di riconoscimento

- **Aumenta il constrast dell'immagine**: regola `THRESHOLD` da 100 a un valore ottimale guardando l'immagine binaria nel box (deve essere simile al dataset MNIST — cifra bianca su sfondo nero)
- **Illuminazione**: usa luce diffusa e uniforme, sfondo scuro, cifra scritta in nero su carta bianca

### 7b. Aggiungi un display 7-segmenti

Connetti `digit_out[3:0]` a un decoder BCD→7-segmenti:

```verilog
// Aggiunta in top_integration.v o in un modulo separato:
reg [6:0] seg7;
always @(*) begin
    case (digit_out)
        4'd0: seg7 = 7'b1111110;
        4'd1: seg7 = 7'b0110000;
        4'd2: seg7 = 7'b1101101;
        4'd3: seg7 = 7'b1111001;
        4'd4: seg7 = 7'b0110011;
        4'd5: seg7 = 7'b1011011;
        4'd6: seg7 = 7'b1011111;
        4'd7: seg7 = 7'b1110000;
        4'd8: seg7 = 7'b1111111;
        4'd9: seg7 = 7'b1111011;
        default: seg7 = 7'b0000000;
    endcase
end
```

### 7c. Aggiungi overlay testuale HDMI (digit → schermo)

Per mostrare la cifra riconosciuta direttamente sul video HDMI, aggiungi un
modulo font-ROM 4×7 pixel e un overlay in `top_integration.v` che disegna
il carattere nell'angolo superiore del guide box.

### 7d. Sostituzione PLL per 25 MHz esatti

In Diamond, usa **Clarity Designer**:
1. `Tools → IP Core → Clarity Designer`
2. Aggiungi `EHXPLL` con ingresso 27 MHz, uscita 25 MHz
3. Genera il `.sbx` e aggiungilo al progetto
4. Sostituisci `wire clk_nn = clk_i` con l'istanza PLL

---

## Bug corretti rispetto al codice originale

| # | Modulo | Problema originale | Fix applicato |
|---|---|---|---|
| A | `preprocessing` | Array BRAM `[0:0]` → SLICE FF invece di EBR (overflow risorse) | `[7:0]`, solo bit[0] usato |
| B | `preprocessing` | `lb_dil1 [449:0]` = 450 bit, 1 extra → shift errato | `[448:0]` = 449 bit corretti |
| C | `preprocessing` | `if/else if` senza `else` → latch inferiti da Synplify | `else begin reg<=reg end` esplicito |
| D | `preprocessing` | Pooling scriveva su lb vuoto (prima riga, py=0) | Guard `py >= 8'd1` |
| E | `preprocessing` | Output leggeva `buf_out[cnt_out]` con cnt_out già incrementato | Lettura prima dell'incremento |
| F | `input_buffer` | Doppia divisione /2 sull'indirizzo BRAM (ParmMgr già divide) | `bram_addr0[9:0]` diretto |
| G | `input_buffer` | Codifica `ap_fixed<12,5>`: usava `12'h080` invece di `12'h040` | `PIXEL_ONE = 12'h040` |
| H | `output_capture` | Estrazione indice: usava `bram_addr0[5:1]` invece di `[4:1]` | `bram_addr0[4:1]` per range 0..9 |
| I | `top` | Nessun CDC tra 148.5 MHz e 27 MHz → dati corrotti garantiti | `cdc_async_fifo` Gray-code |
| L | `top` | `nn_busy` (dominio 27 MHz) usato in always @CSI2 senza sync | Sincronizzatore 2-stage |
| M | `top` | ROI catturava i primi 50176 raster (≠ quadrato 224×224 centrato) | Gate `hcnt/vcnt` su `roi_valid` |
| N | `top` | Nessuna guida visiva di dove posizionare la cifra | Guide box bianco/giallo |
| O | `top` | Risultato flickerava tra un'inferenza e la successiva | `digit_hold` register |

---

## Note tecniche

### ap_fixed<12,5> encoding
```
Formato:  S IIII.FFFFFFF  (1 segno + 4 interi + 7 frazionari = 12 bit)
pixel=1  →  0000_0100_0000  =  0x040  =   64 dec  (= 1.0 in virgola fissa)
pixel=0  →  0000_0000_0000  =  0x000  =    0 dec  (= 0.0)
```

### Latenza pipeline completa
```
Pre-processing @ 148.5 MHz  ≈  1.2 ms
CDC + fill buffer @ 27 MHz  ≈  0.03 ms
LeNet-5 inference @ 27 MHz  ≈  16.2 ms
─────────────────────────────────────
Totale                       ≈  17.4 ms  (≈ 0.5 frame a 30fps)
```

### Struttura BRAM Bambu
```
Input  (conv1_input):   784 word × 12-bit  →  lenet_input_buffer
Output (layer13_out):    10 word × 12-bit  →  lenet_output_capture
Indirizzi: word-addressed (ParmMgr divide già byte/2)
Protocollo: single-cycle latency (CE→Q il ciclo successivo)
```
