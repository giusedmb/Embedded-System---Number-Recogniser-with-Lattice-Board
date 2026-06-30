#!/bin/bash
echo "Fix 0: INIT_VALUE e hls_stream.h"
find firmware/ac_types/ -type f -name "*.h" -exec sed -i 's/\/\*__INIT_VALUE\*\// = 0/g' {} +
sed -i '59s/.*/\/\/ &/' firmware/ac_types/hls_stream.h
sed -i '63s/.*/\/\/ &/' firmware/ac_types/hls_stream.h
echo "Fix 1: ac_int.h"
sed -i 's/usnigned/unsigned/g' firmware/ac_types/ac_int.h
echo "Fix 2 & 3: nnet_mult.h"
sed -i '32s/-> decltype(-a) {/-> x_T {/' firmware/nnet_utils/nnet_mult.h
sed -i '44s/-> decltype(-w) {/-> w_T {/' firmware/nnet_utils/nnet_mult.h
sed -i '56s/-> decltype(-a) {/-> x_T {/' firmware/nnet_utils/nnet_mult.h
sed -i '70s/-> decltype(a \* w) {/-> ap_fixed<32, 12> {/' firmware/nnet_utils/nnet_mult.h
sed -i '79s/.*/    using r_T = ap_fixed<64, 32>;/' firmware/nnet_utils/nnet_mult.h
echo "Fix 4: pragma interface"
sed -i 's/#pragma HLS interface mode=valid/\/\/ &/g' firmware/myproject.cpp
echo "Fix 5 (IL SALVA-BRAM): Rimuovi completamente unrolling e pipeline"
sed -i 's/#pragma HLS unroll.*/\/\/ &/g' firmware/nnet_utils/nnet_conv2d.h
sed -i 's/#pragma HLS pipeline.*/\/\/ &/g' firmware/nnet_utils/nnet_conv2d.h
echo "Fix 6: Rimuovi std::cout"
sed -i '371s/.*/\/\/ &/' firmware/nnet_utils/nnet_helpers.h
echo "Fix 7: Elimina ARRAY_PARTITION"
find firmware/ -type f \( -name "*.cpp" -o -name "*.h" \) -exec sed -i '/#pragma HLS ARRAY_PARTITION/d' {} +
echo "Tutti i fix applicati!"
