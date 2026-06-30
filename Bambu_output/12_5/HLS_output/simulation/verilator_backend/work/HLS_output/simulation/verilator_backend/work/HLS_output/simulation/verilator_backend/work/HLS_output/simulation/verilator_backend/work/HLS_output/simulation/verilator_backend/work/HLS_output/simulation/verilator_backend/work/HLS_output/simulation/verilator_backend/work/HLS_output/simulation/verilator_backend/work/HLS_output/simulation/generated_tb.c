/*
 * Politecnico di Milano
 * Code created using PandA - Version: PandA 2025.07 - Revision 2be902d264e7996b4fbc47153a26c8dba6e25ec0-feature/CSROA-and-predication - Date 2026-06-20T17:33:19
 * Bambu executed with: 'bambu' '--top-fname=myproject' '-I' 'firmware/ac_types' '--generate-interface=INFER' '--clock-period=40' '--bambu-parameter=inline-max-cost=0' '--simulate' '--generate-tb=myproject_test.cpp' '--verbosity=4' 'firmware/myproject.cpp'
 */

#define _FILE_OFFSET_BITS 64

#define __Inf (1.0 / 0.0)
#define __Nan (0.0 / 0.0)

#include <stdbool.h>
#ifdef __cplusplus
#undef printf

#include <cstdio>
#include <cstdlib>
#else
#include <stdio.h>
#include <stdlib.h>

extern void exit(int status);
#endif

#include <sys/types.h>

#ifdef __AC_NAMESPACE
using namespace __AC_NAMESPACE;
#endif

#define _Z9myprojectP8ac_fixedILi12ELi5ELb1EL9ac_q_mode0EL9ac_o_mode0EES3_ __keep_your_declaration_out_of_my_code
#define main __keep_your_main_out_of_my_code
#include "../../firmware/ac_types/ac_fixed.h"
#undef _Z9myprojectP8ac_fixedILi12ELi5ELb1EL9ac_q_mode0EL9ac_o_mode0EES3_
#undef main


#ifndef CDECL
#ifdef __cplusplus
#define CDECL extern "C"
#else
#define CDECL
#endif
#endif

#ifndef EXTERN_CDECL
#ifdef __cplusplus
#define EXTERN_CDECL extern "C"
#else
#define EXTERN_CDECL extern
#endif
#endif

#define __mem_bambu_artificial_idx 2
#define conv1_input_bambu_artificial_idx 0
#define layer13_out_bambu_artificial_idx 1
#define conv1_input_bambu_artificial_align 2
#define layer13_out_bambu_artificial_align 2
#include <mdpi/mdpi_user.h>

CDECL void _Z9myprojectP8ac_fixedILi12ELi5ELb1EL9ac_q_mode0EL9ac_o_mode0EES3_(ac_fixed<12, 5>*, ac_fixed<12, 5>*);


