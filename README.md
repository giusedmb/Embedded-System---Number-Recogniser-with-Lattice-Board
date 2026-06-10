# Progetto Embedded Systems - Pre-Processing su ECP5

## 📂 Struttura del Progetto

* **`model_and_prototypes/`**: Contiene lo stack software (notebook Python, modello Keras e prototipo C++).
* **`fpga_hardware/`**: Contiene il progetto sorgente per Lattice Diamond. All'interno si trova il file Top-Level modificato (`RAW10toParallel.v`) in cui abbiamo "dirottato" il segnale video della telecamera per passarlo al modulo di pre-processing e mostrarlo via HDMI.

## 🚀 Per avviare la Sintesi

1. Caricare il progetto aprendo il file: `fpga_hardware/ECP5_Raw10toParallel/Raw10toParallel.ldf`.
2. Fare doppio clic su **Synthesize Design**.

