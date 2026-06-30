// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Prototypes for DPI import and export functions.
//
// Verilator includes this file in all generated .cpp files that use DPI functions.
// Manually include this file where DPI .c import functions are declared to ensure
// the C functions match the expectations of the DPI imports.

#ifndef VERILATED_VBAMBU_TESTBENCH__DPI_H_
#define VERILATED_VBAMBU_TESTBENCH__DPI_H_  // guard

#include "svdpi.h"

#ifdef __cplusplus
extern "C" {
#endif


    // DPI IMPORTS
    // DPI import at HLS_output/simulation/bambu_testbench.v:144:31
    extern int m_fini();
    // DPI import at HLS_output/simulation/bambu_testbench.v:143:40
    extern unsigned int m_next(unsigned int state);
    // DPI import at HLS_output/simulation/bambu_testbench.v:363:31
    extern int m_read(unsigned short id, svLogicVecVal* data, unsigned short bitsize, unsigned int addr, char cmd);
    // DPI import at HLS_output/simulation/bambu_testbench.v:365:31
    extern int m_state(unsigned short id, int data);
    // DPI import at HLS_output/simulation/bambu_testbench.v:364:31
    extern int m_write(unsigned short id, const svLogicVecVal* data, unsigned short bitsize, unsigned int addr, char cmd);

#ifdef __cplusplus
}
#endif

#endif  // guard
