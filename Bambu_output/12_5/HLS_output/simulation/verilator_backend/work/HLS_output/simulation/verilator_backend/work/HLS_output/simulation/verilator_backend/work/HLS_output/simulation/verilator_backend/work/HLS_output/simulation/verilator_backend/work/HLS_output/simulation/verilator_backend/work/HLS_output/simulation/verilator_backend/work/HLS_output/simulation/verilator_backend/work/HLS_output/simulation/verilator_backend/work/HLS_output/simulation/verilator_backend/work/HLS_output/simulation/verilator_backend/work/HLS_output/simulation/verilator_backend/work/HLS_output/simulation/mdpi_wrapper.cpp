/*
 * Politecnico di Milano
 * Code created using PandA - Version: PandA 2025.07 - Revision 2be902d264e7996b4fbc47153a26c8dba6e25ec0-feature/CSROA-and-predication - Date 2026-06-20T17:29:42
 * Bambu executed with: 'bambu' '--top-fname=myproject' '-I' 'firmware/ac_types' '--generate-interface=INFER' '--clock-period=40' '--bambu-parameter=inline-max-cost=0' '--simulate' '--generate-tb=myproject_test.cpp' '--verbosity=4' 'firmware/myproject.cpp'
 */

#if !defined(__cplusplus) || __cplusplus < 201103L
#error This file must be compiled with C++ 11 standard
#endif

#define _FILE_OFFSET_BITS 64

#undef printf

#include <cstdbool>
#include <cstdio>
#include <cstdlib>
#include <sys/types.h>

#ifndef _Bool
#define _Bool bool
#endif

#ifdef __AC_NAMESPACE
using namespace __AC_NAMESPACE;
#endif

#include <mdpi/mdpi_wrapper.h>
#define _Z9myprojectP8ac_fixedILi12ELi5ELb1EL9ac_q_mode0EL9ac_o_mode0EES3_ __keep_your_declaration_out_of_my_code
#define main __keep_your_main_out_of_my_code
#include "../../firmware/ac_types/ac_fixed.h"
#undef _Z9myprojectP8ac_fixedILi12ELi5ELb1EL9ac_q_mode0EL9ac_o_mode0EES3_
#undef main


#ifndef CDECL
#define CDECL extern "C"
#endif

#ifndef EXTERN_CDECL
#define EXTERN_CDECL extern "C"
#endif

#define __mem_bambu_artificial_idx 2
#define conv1_input_bambu_artificial_idx 0
#define layer13_out_bambu_artificial_idx 1
#define conv1_input_bambu_artificial_align 2
#define layer13_out_bambu_artificial_align 2
CDECL void _Z9myprojectP8ac_fixedILi12ELi5ELb1EL9ac_q_mode0EL9ac_o_mode0EES3_(ac_fixed<12, 5>* P0, ac_fixed<12, 5>* P1);
#ifndef MDPI_MEMMAP_MODE
#define MDPI_MEMMAP_MODE MDPI_MEMMAP_DEVICE
#endif

#ifdef __cplusplus
#include <cstring>
#else
#include <string.h>
#endif
#ifndef BAMBU_SKIP_VERIFICATION
EXTERN_CDECL void _Z13__m_myprojectP8ac_fixedILi12ELi5ELb1EL9ac_q_mode0EL9ac_o_mode0EES3_(ac_fixed<12, 5>*, ac_fixed<12, 5>*);
#endif
#ifdef PP_VERIFICATION
EXTERN_CDECL void __m_pp__Z9myprojectP8ac_fixedILi12ELi5ELb1EL9ac_q_mode0EL9ac_o_mode0EES3_(const struct ac_fixed*, struct ac_fixed*);
#endif

typedef struct
{
   const char* filename;
   size_t size;
   const ptr_t addrmap;
   void* addr;
} __m_memmap_t;

typedef struct
{
   void* addr;
   size_t align;
   void* map_addr;
} __m_argmap_t;

static void __m_memsetup(__m_argmap_t args[], size_t args_count)
{
   int error = 0;
   size_t i;
   const ptr_t align = 8;
   static __m_memmap_t memmap_init[] = {
   };
   ptr_t base_addr = 1073741824;
   
   __m_memmap_init(MDPI_MEMMAP_MODE);
   
   
   // Memory-mapped internal variables initialization
   for(i = 0; i < sizeof(memmap_init) / sizeof(*memmap_init); ++i)
   {
      FILE* fp = fopen(memmap_init[i].filename, "rb");
      if(!fp)
      {
         error("Unable to open file: %s\n", memmap_init[i].filename);
         perror("Unable to open memory variable initialization file");
         error |= 2;
         continue;
      }
      if(memmap_init[i].addr == NULL)
      {
         memmap_init[i].addr = malloc(memmap_init[i].size);
      }
      size_t nbytes = fread(memmap_init[i].addr, 1, memmap_init[i].size, fp);
      if(nbytes != memmap_init[i].size)
      {
         error("Only %zu/%zu bytes were read from file: %s\n", nbytes, memmap_init[i].size, memmap_init[i].filename);
         if(ferror(fp))
         {
            perror("Unable to read from memory variable initialization file");
         }
         error |= 4;
         fclose(fp);
         continue;
      }
      fclose(fp);
      error |= __m_memmap(memmap_init[i].addrmap, memmap_init[i].addr, memmap_init[i].size);
   }
   
   for(i = 0; i < args_count; ++i)
   {
      if(args[i].map_addr == NULL)
      {
         args[i].map_addr = args[i].addr;
         continue;
      }
      const size_t arg_size = __m_param_size(i);
      size_t map_size = arg_size;
      base_addr += (align - 1) - ((base_addr - 1) % align);
      args[i].map_addr = args[i].addr;
      if(arg_size % args[i].align)
      {
         map_size = arg_size + (args[i].align - 1) - ((arg_size - 1) % args[i].align);
         info("Parameter %zu map size extended: %zu bytes -> %zu bytes\n", i, arg_size, map_size);
         args[i].map_addr = malloc(map_size);
         memcpy(args[i].map_addr, args[i].addr, arg_size);
      }
      error |= __m_memmap(base_addr, args[i].map_addr, map_size);
      base_addr += map_size;
   }
   if(error)
   {
      __m_abort();
   }
   
}

static void __m_argmap_fini(__m_argmap_t args[], size_t args_count)
{
   size_t i = 0;
   for(i = 0; i < args_count; i++)
   {
      if(args[i].map_addr != args[i].addr)
      {
         memcpy(args[i].addr, args[i].map_addr, __m_param_size(i));
         free(args[i].map_addr);
         args[i].map_addr = args[i].addr;
      }
   }
}

void _Z9myprojectP8ac_fixedILi12ELi5ELb1EL9ac_q_mode0EL9ac_o_mode0EES3_(ac_fixed<12, 5>* P0, ac_fixed<12, 5>* P1)
{
   const long double max_ulp = 1;
   size_t i;
   __m_argmap_t args[] = {
      {(void*)P0, 2, m_map_array((void*)P0)},
      {(void*)P1, 2, m_map_array((void*)P1)}};
   __m_param_alloc(0, 6272);
   __m_param_alloc(1, 80);
   __m_memsetup(args, 2);
   
   m_interface_array(0, args[0].map_addr, 12, 2);
   m_interface_array(1, args[1].map_addr, 12, 2);
   __m_interface_mem();
   
   __m_sim_start();
   
   #ifndef BAMBU_SKIP_VERIFICATION
   _Z13__m_myprojectP8ac_fixedILi12ELi5ELb1EL9ac_q_mode0EL9ac_o_mode0EES3_((ac_fixed<12, 5>*)P0_gold, (ac_fixed<12, 5>*)P1_gold);
   #endif
   
   #ifdef PP_VERIFICATION
   __m_pp__Z9myprojectP8ac_fixedILi12ELi5ELb1EL9ac_q_mode0EL9ac_o_mode0EES3_((const struct ac_fixed*)P0_pp, (struct ac_fixed*)P1_pp);
   #endif
   
   __m_sim_end();
   __m_interface_fini();
   
   
   #ifdef __clang__
   #pragma clang diagnostic push
   #pragma clang diagnostic ignored "-Wpointer-type-mismatch"
   #endif
   
   __m_argmap_fini(args, 2);
   
   size_t mismatch_count = 0;
   m_argcmp(0, val);
   m_argcmp(1, val);
   
   
   if(mismatch_count)
   {
      error("Memory parameter mismatch has been found.\n");
      __m_abort();
   }
   
   m_call_next();
   
   #ifdef __clang__
   #pragma clang diagnostic pop
   #endif
}


