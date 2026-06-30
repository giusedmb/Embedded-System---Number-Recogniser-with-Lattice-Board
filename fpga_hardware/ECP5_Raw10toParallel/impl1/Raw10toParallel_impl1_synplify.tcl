#-- Lattice Semiconductor Corporation Ltd.
#-- Synplify OEM project file

#device options
set_option -technology ECP5UM
set_option -part LFE5UM_85F
set_option -package BG756C
set_option -speed_grade -8

#compilation/mapping options
set_option -symbolic_fsm_compiler true
set_option -resource_sharing true

#use verilog 2001 standard option
set_option -vlog_std v2001

#map options
set_option -frequency auto
set_option -maxfan 1000
set_option -auto_constrain_io 0
set_option -disable_io_insertion false
set_option -retiming false; set_option -pipe true
set_option -force_gsr false
set_option -compiler_compatible 0
set_option -dup false

set_option -default_enum_encoding default

#simulation options


#timing analysis options



#automatic place and route (vendor) options
set_option -write_apr_constraint 1

#synplifyPro options
set_option -fix_gated_and_generated_clocks 1
set_option -update_models_cp 0
set_option -resolve_multiple_driver 0


set_option -seqshift_no_replicate 0

#-- add_file options
set_option -hdl_define -set SBP_SYNTHESIS
set_option -include_path {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/RAW10toParallel.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/ab.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/blanking_adjustment.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/debayer.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/gamma_correction.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/hdmi_i2c_core.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/hdmi_i2c_ctrl.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/hdmi_i2c_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/i2c_core.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/i2c_ctrl.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/i2c_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/image_pipe.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/dp_ram/debayer_dpram/debayer_dpram.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/dp_ram/rb_ram/rb_ram.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/dp_ram/dp_ram.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/gammaCorrector/gammaCorrector_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/Gamma/Gamma.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/image_fifo/sc_fifo/sc_fifo.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/image_fifo/image_fifo.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/color.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/CSC/colorspace/colorspace_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/CSC/colorspace/colorspace_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/CSC/colorspace/colorspace_top.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/CSC/colorspace/colorspace_bb.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/clarity/CSC/CSC.v}
add_file -verilog -vlog_std v2001 {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/source/hardware_preprocessing.v}

#-- top module name
set_option -top_module RAW10toParallel

#-- set result format/file last
project -result_file {/home/busacca/Dual_CSI-2_Camera_to_HDMI_Bridge_Demo/ECP5_Raw10toParallel/impl1/Raw10toParallel_impl1.edi}

#-- error message log file
project -log_file {Raw10toParallel_impl1.srf}

#-- set any command lines input by customer


#-- run Synplify with 'arrange HDL file'
project -run
