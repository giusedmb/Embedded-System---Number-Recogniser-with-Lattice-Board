#ifndef MYPROJECT_H_
#define MYPROJECT_H_

#include "ap_fixed.h"
#include "ap_int.h"
#include "hls_stream.h"

#include "defines.h"


// Prototype of top level function for C-synthesis
void myproject(
    input_t conv1_input[28*28*1],
    result_t layer13_out[10]
);

// hls-fpga-machine-learning insert emulator-defines


#endif
