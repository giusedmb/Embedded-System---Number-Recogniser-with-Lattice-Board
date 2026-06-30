# Verilated -*- Makefile -*-
# DESCRIPTION: Verilator output: Make include file with class lists
#
# This file lists generated Verilated files, for including in higher level makefiles.
# See Vbambu_testbench.mk for the caller.

### Switches...
# C11 constructs required?  0/1 (always on now)
VM_C11 = 1
# Timing enabled?  0/1
VM_TIMING = 0
# Coverage output mode?  0/1 (from --coverage)
VM_COVERAGE = 0
# Parallel builds?  0/1 (from --output-split)
VM_PARALLEL_BUILDS = 1
# Tracing output mode?  0/1 (from --trace/--trace-fst)
VM_TRACE = 0
# Tracing output mode in VCD format?  0/1 (from --trace)
VM_TRACE_VCD = 0
# Tracing output mode in FST format?  0/1 (from --trace-fst)
VM_TRACE_FST = 0

### Object file lists...
# Generated module classes, fast-path, compile with highest optimization
VM_CLASSES_FAST += \
	Vbambu_testbench \
	Vbambu_testbench___024root__DepSet_h7321823f__0 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__0 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__1 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__2 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__3 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__4 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__5 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__6 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__7 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__8 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__9 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__10 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__11 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__12 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__13 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__14 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__15 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__16 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__17 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__18 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__19 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__20 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__21 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__22 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__23 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__24 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__25 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__26 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__27 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__28 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__29 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__30 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__31 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__32 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__33 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__34 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__35 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__36 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__37 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__38 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__39 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__40 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__41 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__42 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__43 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__44 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__45 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__46 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__47 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__48 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__49 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__50 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__51 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__52 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__53 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__54 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__55 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__56 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__57 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__58 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__59 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__60 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__61 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__62 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__63 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__64 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__65 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__66 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__67 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__68 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__69 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__70 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__71 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__72 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__73 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__74 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__75 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__76 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__77 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__78 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__79 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__80 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__81 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__82 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__83 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__84 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__85 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__86 \
	Vbambu_testbench___024root__DepSet_hb4350c9a__87 \

# Generated module classes, non-fast-path, compile with low/medium optimization
VM_CLASSES_SLOW += \
	Vbambu_testbench__ConstPool_0 \
	Vbambu_testbench___024root__Slow \
	Vbambu_testbench___024root__DepSet_h7321823f__0__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__0__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__1__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__2__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__3__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__4__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__5__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__6__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__7__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__8__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__9__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__10__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__11__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__12__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__13__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__14__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__15__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__16__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__17__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__18__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__19__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__20__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__21__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__22__Slow \
	Vbambu_testbench___024root__DepSet_hb4350c9a__23__Slow \
	Vbambu_testbench___024unit__Slow \
	Vbambu_testbench___024unit__DepSet_he63e5f61__0__Slow \

# Generated support classes, fast-path, compile with highest optimization
VM_SUPPORT_FAST += \
	Vbambu_testbench__Dpi \

# Generated support classes, non-fast-path, compile with low/medium optimization
VM_SUPPORT_SLOW += \
	Vbambu_testbench__Syms \

# Global classes, need linked once per executable, fast-path, compile with highest optimization
VM_GLOBAL_FAST += \
	verilated \
	verilated_dpi \
	verilated_threads \

# Global classes, need linked once per executable, non-fast-path, compile with low/medium optimization
VM_GLOBAL_SLOW += \


# Verilated -*- Makefile -*-
