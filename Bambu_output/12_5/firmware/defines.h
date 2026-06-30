#ifndef DEFINES_H_
#define DEFINES_H_

#include "ap_fixed.h"
#include "ap_int.h"
#include "nnet_utils/nnet_types.h"
#include <array>
#include <cstddef>
#include <cstdio>
#include <tuple>
#include <tuple>


// hls-fpga-machine-learning insert numbers

// hls-fpga-machine-learning insert layer-precision
typedef ap_fixed<12,5> input_t;
typedef ap_fixed<12,5> conv1_accum_t;
typedef ap_fixed<12,5> layer2_t;
typedef ap_fixed<12,5> conv1_weight_t;
typedef ap_fixed<12,5> conv1_bias_t;
typedef ap_fixed<12,5> layer3_t;
typedef ap_fixed<18,8> conv1_relu_table_t;
typedef ap_fixed<12,5> pool1_accum_t;
typedef ap_fixed<12,5> layer4_t;
typedef ap_fixed<12,5> conv2_accum_t;
typedef ap_fixed<12,5> layer5_t;
typedef ap_fixed<12,5> conv2_weight_t;
typedef ap_fixed<12,5> conv2_bias_t;
typedef ap_fixed<12,5> layer6_t;
typedef ap_fixed<18,8> conv2_relu_table_t;
typedef ap_fixed<12,5> pool2_accum_t;
typedef ap_fixed<12,5> layer7_t;
typedef ap_fixed<12,5> fc1_accum_t;
typedef ap_fixed<12,5> layer9_t;
typedef ap_fixed<12,5> fc1_weight_t;
typedef ap_fixed<12,5> fc1_bias_t;
typedef ap_uint<1> layer9_index;
typedef ap_fixed<12,5> layer10_t;
typedef ap_fixed<18,8> fc1_relu_table_t;
typedef ap_fixed<12,5> fc2_accum_t;
typedef ap_fixed<12,5> layer11_t;
typedef ap_fixed<12,5> fc2_weight_t;
typedef ap_fixed<12,5> fc2_bias_t;
typedef ap_uint<1> layer11_index;
typedef ap_fixed<12,5> layer12_t;
typedef ap_fixed<18,8> fc2_relu_table_t;
typedef ap_fixed<12,5> output_accum_t;
typedef ap_fixed<12,5> result_t;
typedef ap_fixed<12,5> output_weight_t;
typedef ap_fixed<12,5> output_bias_t;
typedef ap_uint<1> layer13_index;

// hls-fpga-machine-learning insert emulator-defines


#endif
