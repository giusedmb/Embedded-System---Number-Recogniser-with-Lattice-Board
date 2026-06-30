// 
// Politecnico di Milano
// Code created using PandA - Version: PandA 2025.07 - Revision 2be902d264e7996b4fbc47153a26c8dba6e25ec0-feature/CSROA-and-predication - Date 2026-06-20T17:29:44
// Bambu executed with: 'bambu' '--top-fname=myproject' '-I' 'firmware/ac_types' '--generate-interface=INFER' '--clock-period=40' '--bambu-parameter=inline-max-cost=0' '--simulate' '--generate-tb=myproject_test.cpp' '--verbosity=4' 'firmware/myproject.cpp'
// 
// Send any bug to: panda-info@polimi.it
// ************************************************************************
// The following text holds for all the components tagged with PANDA_LGPLv3.
// They are all part of the PandA/Bambu IP LIBRARY.
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 3 of the License, or (at your option) any later version.
// 
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with the PandA framework; see the files COPYING.LIBv3
// If not, see <http://www.gnu.org/licenses/>.
// ************************************************************************


`ifndef _SIM_HAVE_CLOG2
`ifdef __ICARUS__
  `define _SIM_HAVE_CLOG2
`endif
`ifdef VERILATOR
  `define _SIM_HAVE_CLOG2
`endif
`ifdef MODEL_TECH
  `define _SIM_HAVE_CLOG2
`endif
`ifdef VCS
  `define _SIM_HAVE_CLOG2
`endif
`ifdef NCVERILOG
  `define _SIM_HAVE_CLOG2
`endif
`ifdef XILINX_SIMULATOR
  `define _SIM_HAVE_CLOG2
`endif
`ifdef XILINX_ISIM
  `define _SIM_HAVE_CLOG2
`endif
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _register_SE_DEFINED
`define _register_SE_DEFINED
`timescale 1ns / 1ps
module register_SE(clock,
  reset,
  in1,
  wenable,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input clock;
  input reset;
  input [BITSIZE_in1-1:0] in1;
  input wenable;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  
  reg [BITSIZE_out1-1:0] reg_out1 =0;
  assign out1 = reg_out1;
  always @(posedge clock)
    if (wenable)
      reg_out1 <= in1;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2020-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _STD_SDP_BRAM_DEFINED
`define _STD_SDP_BRAM_DEFINED
`timescale 1ns / 1ps
module STD_SDP_BRAM(clock,
  write_enable,
  data_in,
  address_inr,
  address_inw,
  data_out);
  parameter BITSIZE_data_in=1,
    BITSIZE_address_inr=1,
    BITSIZE_address_inw=1,
    BITSIZE_data_out=1,
    MEMORY_INIT_file="array_a.mem",
    n_elements=32,
    READ_ONLY_MEMORY=0,
    HIGH_LATENCY=0;
  // IN
  input clock;
  input write_enable;
  input [BITSIZE_data_in-1:0] data_in;
  input [BITSIZE_address_inr-1:0] address_inr;
  input [BITSIZE_address_inw-1:0] address_inw;
  // OUT
  output [BITSIZE_data_out-1:0] data_out;
  
  wire [BITSIZE_address_inr-1:0] address_inr_mem;
  reg [BITSIZE_address_inr-1:0] address_inr1;
  wire [BITSIZE_address_inw-1:0] address_inw_mem;
  reg [BITSIZE_address_inw-1:0] address_inw1;
  
  wire write_enable_mem;
  reg write_enable1;
  
  reg [BITSIZE_data_out-1:0] data_out_mem;
  reg [BITSIZE_data_out-1:0] data_out1;
  
  wire [BITSIZE_data_in-1:0] data_in_mem;
  reg [BITSIZE_data_in-1:0] data_in1;
  integer index;
  
  reg [BITSIZE_data_out-1:0] memory [0:n_elements-1]/* synthesis syn_ramstyle =  "no_rw_check" */;
  
  initial
  begin
    if (MEMORY_INIT_file != "")
      $readmemb(MEMORY_INIT_file, memory, 0, n_elements-1);
    else
    begin
      for(index=0; index<n_elements; index=index+1)
      begin
        memory[index] = 0;
      end
    end
  end
  
  always @(posedge clock)
  begin
    if(READ_ONLY_MEMORY==0)
    begin
      if (write_enable_mem)
        memory[address_inw_mem] <= data_in_mem;
    end
    data_out_mem <= memory[address_inr_mem];
  end
  
  assign data_out = HIGH_LATENCY==0 ? data_out_mem : data_out1;
  always @(posedge clock)
    data_out1 <= data_out_mem;
  
  
  generate
    if(HIGH_LATENCY==2)
    begin
      always @ (posedge clock)
      begin
         address_inr1 <= address_inr;
         address_inw1 <= address_inw;
         write_enable1 <= write_enable;
         data_in1 <= data_in;
      end
      assign address_inr_mem = address_inr1;
      assign address_inw_mem = address_inw1;
      assign write_enable_mem = write_enable1;
      assign data_in_mem = data_in1;
    end
    else
    begin
      assign address_inr_mem = address_inr;
      assign address_inw_mem = address_inw;
      assign write_enable_mem = write_enable;
      assign data_in_mem = data_in;
    end
  endgenerate

endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2020-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _STD_SDP_BRAMFW_DEFINED
`define _STD_SDP_BRAMFW_DEFINED
`timescale 1ns / 1ps
module STD_SDP_BRAMFW(clock,
  write_enable,
  data_in,
  address_inr,
  address_inw,
  data_out);
  parameter BITSIZE_data_in=1,
    BITSIZE_address_inr=1,
    BITSIZE_address_inw=1,
    BITSIZE_data_out=1,
    MEMORY_INIT_file="array_a.mem",
    n_elements=32,
    READ_ONLY_MEMORY=0,
    HIGH_LATENCY=0;
  // IN
  input clock;
  input write_enable;
  input [BITSIZE_data_in-1:0] data_in;
  input [BITSIZE_address_inr-1:0] address_inr;
  input [BITSIZE_address_inw-1:0] address_inw;
  // OUT
  output [BITSIZE_data_out-1:0] data_out;
  
  wire [BITSIZE_address_inr-1:0] address_inr_mem;
  reg [BITSIZE_address_inr-1:0] address_inr1;
  reg [BITSIZE_address_inr-1:0] address_inr_mem1;
  wire [BITSIZE_address_inw-1:0] address_inw_mem;
  reg [BITSIZE_address_inw-1:0] address_inw1;
  reg [BITSIZE_address_inw-1:0] address_inw_mem1;
  
  wire write_enable_mem;
  reg write_enable1;
  reg write_enable_mem1;
  
  reg [BITSIZE_data_out-1:0] data_out_mem_temp;
  reg [BITSIZE_data_out-1:0] data_out1;
  wire [BITSIZE_data_out-1:0] data_out_mem;
  
  wire [BITSIZE_data_in-1:0] data_in_mem;
  reg [BITSIZE_data_in-1:0] data_in1;
  reg [BITSIZE_data_in-1:0] data_in_mem1;
  
  integer index;
  
  reg [BITSIZE_data_out-1:0] memory [0:n_elements-1]/* synthesis syn_ramstyle =  "no_rw_check" */;
  
  initial
  begin
    if (MEMORY_INIT_file != "")
      $readmemb(MEMORY_INIT_file, memory, 0, n_elements-1);
    else
    begin
      for(index=0; index<n_elements; index=index+1)
      begin
        memory[index] = 0;
      end
    end
  end
  
  always @(posedge clock)
  begin
    if(READ_ONLY_MEMORY==0)
    begin
      if (write_enable_mem)
        memory[address_inw_mem] <= data_in_mem;
    end
    data_out_mem_temp <= memory[address_inr_mem];
  end
  
  assign data_out_mem = write_enable_mem1 && (address_inr_mem1 == address_inw_mem1) ? data_in_mem1 : data_out_mem_temp;
  
  assign data_out = HIGH_LATENCY==0 ? data_out_mem : data_out1;
  always @(posedge clock)
    data_out1 <= data_out_mem;
  
  always @ (posedge clock)
  begin
    address_inr_mem1 <= address_inr_mem;
    address_inw_mem1 <= address_inw_mem;
    write_enable_mem1 <= write_enable_mem;
    data_in_mem1 <= data_in_mem;
  end
  
  generate
    if(HIGH_LATENCY==2)
    begin
      always @ (posedge clock)
      begin
         address_inr1 <= address_inr;
         address_inw1 <= address_inw;
         write_enable1 <= write_enable;
         data_in1 <= data_in;
      end
      assign address_inr_mem = address_inr1;
      assign address_inw_mem = address_inw1;
      assign write_enable_mem = write_enable1;
      assign data_in_mem = data_in1;
    end
    else
    begin
      assign address_inr_mem = address_inr;
      assign address_inw_mem = address_inw;
      assign write_enable_mem = write_enable;
      assign data_in_mem = data_in;
    end
  endgenerate

endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2013-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _STD_NR_BRAM_DEFINED
`define _STD_NR_BRAM_DEFINED
`timescale 1ns / 1ps
module STD_NR_BRAM(clock,
  write_enable,
  address_inr,
  address_inw,
  data_in,
  data_out);
  parameter BITSIZE_address_inr=1, PORTSIZE_address_inr=1,
    BITSIZE_address_inw=1,
    BITSIZE_data_in=1,
    BITSIZE_data_out=1, PORTSIZE_data_out=1,
    MEMORY_INIT_file="array_a.mem",
    n_elements=32,
    forwarding=0,
    READ_ONLY_MEMORY=0,
    HIGH_LATENCY=0;
  // IN
  input clock;
  input write_enable;
  input [(PORTSIZE_address_inr*BITSIZE_address_inr)+(-1):0] address_inr;
  input [BITSIZE_address_inw-1:0] address_inw;
  input [BITSIZE_data_in-1:0] data_in;
  // OUT
  output [(PORTSIZE_data_out*BITSIZE_data_out)+(-1):0] data_out;
  
  generate
  genvar i1;
    for (i1=0; i1<PORTSIZE_address_inr; i1=i1+1)
    begin : L1
      if(forwarding)
      begin
        STD_SDP_BRAMFW #(
          .BITSIZE_address_inr(BITSIZE_address_inr),
          .BITSIZE_address_inw(BITSIZE_address_inw),
          .BITSIZE_data_in(BITSIZE_data_in),
          .BITSIZE_data_out(BITSIZE_data_out),
          .MEMORY_INIT_file(MEMORY_INIT_file),
          .n_elements(n_elements),
          .READ_ONLY_MEMORY(READ_ONLY_MEMORY),
          .HIGH_LATENCY(HIGH_LATENCY)
          )
        STD_SDP_BRAMFW_instance (
          .clock(clock),
          .write_enable(write_enable),
          .address_inr(address_inr[(i1+1)*BITSIZE_address_inr-1:i1*BITSIZE_address_inr]),
          .address_inw(address_inw),
          .data_in(data_in),
          .data_out(data_out[(i1+1)*BITSIZE_data_out-1:i1*BITSIZE_data_out]));
      end
      else
      begin
        STD_SDP_BRAM #(
          .BITSIZE_address_inr(BITSIZE_address_inr),
          .BITSIZE_address_inw(BITSIZE_address_inw),
          .BITSIZE_data_in(BITSIZE_data_in),
          .BITSIZE_data_out(BITSIZE_data_out),
          .MEMORY_INIT_file(MEMORY_INIT_file),
          .n_elements(n_elements),
          .READ_ONLY_MEMORY(READ_ONLY_MEMORY),
          .HIGH_LATENCY(HIGH_LATENCY)
          )
        STD_SDP_BRAM_instance (
          .clock(clock),
          .write_enable(write_enable),
          .address_inr(address_inr[(i1+1)*BITSIZE_address_inr-1:i1*BITSIZE_address_inr]),
          .address_inw(address_inw),
          .data_in(data_in),
          .data_out(data_out[(i1+1)*BITSIZE_data_out-1:i1*BITSIZE_data_out]));
      end
    end
  endgenerate
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2023-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _STD_NRNW_BRAM_XOR_DEFINED
`define _STD_NRNW_BRAM_XOR_DEFINED
`timescale 1ns / 1ps
module STD_NRNW_BRAM_XOR(clock,
  write_enable,
  address_inr,
  address_inw,
  data_in,
  dout_value);
  parameter BITSIZE_write_enable=1, PORTSIZE_write_enable=1,
    BITSIZE_address_inr=1, PORTSIZE_address_inr=1,
    BITSIZE_address_inw=1, PORTSIZE_address_inw=1,
    BITSIZE_data_in=1, PORTSIZE_data_in=1,
    BITSIZE_dout_value=1, PORTSIZE_dout_value=1,
    MEMORY_INIT_file="array_a.mem",
    n_elements=32,
    READ_ONLY_MEMORY=0,
    HIGH_LATENCY=0;
  // IN
  input clock;
  input [PORTSIZE_write_enable-1:0] write_enable;
  input [(PORTSIZE_address_inr*BITSIZE_address_inr)+(-1):0] address_inr;
  input [(PORTSIZE_address_inw*BITSIZE_address_inw)+(-1):0] address_inw;
  input [(PORTSIZE_data_in*BITSIZE_data_in)+(-1):0] data_in;
  // OUT
  output [(PORTSIZE_dout_value*BITSIZE_dout_value)+(-1):0] dout_value;
  
  `ifndef _SIM_HAVE_CLOG2
    function integer log2;
       input integer value;
       integer temp_value;
      begin
        temp_value = value-1;
        for (log2=0; temp_value>0; log2=log2+1)
          temp_value = temp_value>>1;
      end
    endfunction
  `endif
  `ifdef _SIM_HAVE_CLOG2
    localparam nbit_write = PORTSIZE_address_inw == 1 ? 1 : $clog2(PORTSIZE_address_inw);
  `else
    localparam nbit_write = PORTSIZE_address_inw == 1 ? 1 : log2(PORTSIZE_address_inw);
  `endif
  
  reg [PORTSIZE_data_in*BITSIZE_data_in-1:0] WriteFeedBackData;
  wire [BITSIZE_dout_value*(PORTSIZE_address_inw*(PORTSIZE_address_inw-1))-1:0] ReadFeedBackData;
  reg [BITSIZE_address_inw*(PORTSIZE_address_inw*(PORTSIZE_address_inw-1))-1:0] ReadFeedBackAddr;
  reg [BITSIZE_dout_value*PORTSIZE_dout_value-1:0] ReadData;
  wire [BITSIZE_dout_value*PORTSIZE_dout_value*PORTSIZE_address_inw-1:0] ReadDataOut;
  
  wire [PORTSIZE_write_enable-1:0] write_enable_mem;
  wire [PORTSIZE_address_inw*BITSIZE_address_inw-1:0] address_inw_mem;
  wire [PORTSIZE_address_inr*BITSIZE_address_inr-1:0] address_inr_mem;
  wire [PORTSIZE_data_in*BITSIZE_data_in-1:0] data_in_mem;
  wire [PORTSIZE_dout_value*BITSIZE_dout_value-1:0] dout_value_mem;
  reg [PORTSIZE_dout_value*BITSIZE_dout_value-1:0] dout_value_mem1;
  
  reg [PORTSIZE_write_enable-1:0] write_enable_mem1;
  reg [PORTSIZE_address_inw*BITSIZE_address_inw-1:0] address_inw_mem1;
  reg [PORTSIZE_data_in*BITSIZE_data_in-1:0] data_in_mem1;
  
  reg [PORTSIZE_write_enable-1:0] write_enable1;
  reg [PORTSIZE_address_inw*BITSIZE_address_inw-1:0] address_inw1;
  reg [PORTSIZE_address_inr*BITSIZE_address_inr-1:0] address_inr1;
  reg [PORTSIZE_data_in*BITSIZE_data_in-1:0] data_in1;
  
  assign dout_value = HIGH_LATENCY==0 ? dout_value_mem : dout_value_mem1;
  always @(posedge clock)
    dout_value_mem1 <= dout_value_mem;
  
  
  generate
    if(HIGH_LATENCY==2)
    begin
      always @ (posedge clock)
      begin
         address_inr1 <= address_inr;
         address_inw1 <= address_inw;
         write_enable1 <= write_enable;
         data_in1 <= data_in;
      end
      assign address_inr_mem = address_inr1;
      assign address_inw_mem = address_inw1;
      assign write_enable_mem = write_enable1;
      assign data_in_mem = data_in1;
    end
    else
    begin
      assign address_inr_mem = address_inr;
      assign address_inw_mem = address_inw;
      assign write_enable_mem = write_enable;
      assign data_in_mem = data_in;
    end
  endgenerate
  
  always @(posedge clock)
  begin
    write_enable_mem1 <= write_enable_mem;
    address_inw_mem1 <= address_inw_mem;
    data_in_mem1 <= data_in_mem;
  end
  
  assign dout_value_mem = ReadData;
  
  generate
  genvar ii1;
    for (ii1=0; ii1<PORTSIZE_address_inw; ii1=ii1+1)
    begin : L1
      STD_NR_BRAM #(
        .PORTSIZE_address_inr(PORTSIZE_address_inw-1),
        .BITSIZE_address_inr(BITSIZE_address_inr),
        .BITSIZE_address_inw(BITSIZE_address_inw),
        .BITSIZE_data_in(BITSIZE_data_in),
        .BITSIZE_data_out(BITSIZE_dout_value),
        .PORTSIZE_data_out(PORTSIZE_address_inw-1),
        .MEMORY_INIT_file(ii1 == 0 ? MEMORY_INIT_file : ""),
        .n_elements(n_elements),
        .forwarding(1),
        .READ_ONLY_MEMORY(READ_ONLY_MEMORY),
        .HIGH_LATENCY(0)
      )
      STD_NR_BRAM_FB_instance (
        .clock(clock),
        .write_enable(write_enable_mem1[ii1]),
        .address_inr(ReadFeedBackAddr[ii1*(BITSIZE_address_inw*(PORTSIZE_address_inw-1))+:(BITSIZE_address_inw*(PORTSIZE_address_inw-1))]),
        .address_inw(address_inw_mem1[ii1*BITSIZE_address_inw+:BITSIZE_address_inw]),
        .data_in(WriteFeedBackData[ii1*BITSIZE_data_in+:BITSIZE_data_in]),
        .data_out(ReadFeedBackData[ii1*BITSIZE_dout_value*(PORTSIZE_address_inw-1)+:BITSIZE_dout_value*(PORTSIZE_address_inw-1)]));
  
      STD_NR_BRAM #(
        .PORTSIZE_address_inr(PORTSIZE_address_inr),
        .BITSIZE_address_inr(BITSIZE_address_inr),
        .BITSIZE_address_inw(BITSIZE_address_inw),
        .BITSIZE_data_in(BITSIZE_data_in),
        .BITSIZE_data_out(BITSIZE_dout_value),
        .PORTSIZE_data_out(PORTSIZE_address_inr),
        .MEMORY_INIT_file(ii1 == 0 ? MEMORY_INIT_file : ""),
        .n_elements(n_elements),
        .forwarding(1),
        .READ_ONLY_MEMORY(READ_ONLY_MEMORY),
        .HIGH_LATENCY(0)
      )
      STD_NR_BRAM_instance (
        .clock(clock),
        .write_enable(write_enable_mem1[ii1]),
        .address_inr(address_inr_mem),
        .address_inw(address_inw_mem1[ii1*BITSIZE_address_inw+:BITSIZE_address_inw]),
        .data_in(WriteFeedBackData[ii1*BITSIZE_data_in+:BITSIZE_data_in]),
        .data_out(ReadDataOut[ii1*BITSIZE_dout_value*(PORTSIZE_address_inr)+:BITSIZE_dout_value*(PORTSIZE_address_inr)]));
    end
  endgenerate
  integer i1,i2,i3;
  always @(*)
  begin
    for(i1=0;i1<PORTSIZE_address_inr;i1=i1+1)
    begin
      ReadData[i1*BITSIZE_dout_value+:BITSIZE_dout_value] = ReadDataOut[i1*BITSIZE_dout_value+:BITSIZE_dout_value];
      for(i2=1;i2<PORTSIZE_address_inw;i2=i2+1)
      begin
        ReadData[i1*BITSIZE_dout_value+:BITSIZE_dout_value] = ReadData[i1*BITSIZE_dout_value+:BITSIZE_dout_value]^ReadDataOut[(i2*PORTSIZE_address_inw+i1)*BITSIZE_dout_value+:BITSIZE_dout_value];
      end
    end
    for(i1=0;i1<PORTSIZE_address_inw;i1=i1+1)
      WriteFeedBackData[i1*BITSIZE_data_in+:BITSIZE_data_in] = data_in_mem1[i1*BITSIZE_data_in+:BITSIZE_data_in];
    for(i1=0;i1<PORTSIZE_address_inw;i1=i1+1)
    begin
      i3 = 0;
      for(i2=0;i2<PORTSIZE_address_inw-1;i2=i2+1)
      begin
        i3=i3+(i2==i1);
        ReadFeedBackAddr[(i1*(PORTSIZE_address_inw-1)+i2)*BITSIZE_address_inw+:BITSIZE_address_inw] = address_inw_mem[i3*BITSIZE_address_inw+:BITSIZE_address_inw];
        WriteFeedBackData[i3*BITSIZE_data_in+:BITSIZE_data_in] = WriteFeedBackData[i3*BITSIZE_data_in+:BITSIZE_data_in]^ReadFeedBackData[(i1*(PORTSIZE_address_inw-1)+i2)*BITSIZE_data_in+:BITSIZE_data_in];
        i3=i3+1;
      end
    end
  end

endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2023-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _STD_DP_BRAM_DEFINED
`define _STD_DP_BRAM_DEFINED
`timescale 1ns / 1ps
module STD_DP_BRAM(clock,
  write_enable,
  data_in,
  address_in,
  data_out);
  parameter BITSIZE_write_enable=1, PORTSIZE_write_enable=1,
    BITSIZE_data_in=1, PORTSIZE_data_in=1,
    BITSIZE_address_in=1, PORTSIZE_address_in=1,
    BITSIZE_data_out=1, PORTSIZE_data_out=1,
    MEMORY_INIT_file="array_a.mem",
    n_elements=32,
    READ_ONLY_MEMORY=0,
    HIGH_LATENCY=0;
  // IN
  input clock;
  input [PORTSIZE_write_enable-1:0] write_enable;
  input [(PORTSIZE_data_in*BITSIZE_data_in)+(-1):0] data_in;
  input [(PORTSIZE_address_in*BITSIZE_address_in)+(-1):0] address_in;
  // OUT
  output [(PORTSIZE_data_out*BITSIZE_data_out)+(-1):0] data_out;
  
  wire [2*BITSIZE_address_in-1:0] address_in_mem;
  reg [2*BITSIZE_address_in-1:0] address_in1;
  
  wire [1:0] write_enable_mem;
  reg [1:0] write_enable1;
  
  reg [2*BITSIZE_data_out-1:0] data_out_mem;
  reg [2*BITSIZE_data_out-1:0] data_out1;
  
  wire [2*BITSIZE_data_in-1:0] data_in_mem;
  reg [2*BITSIZE_data_in-1:0] data_in1;
  
  reg [BITSIZE_data_out-1:0] memory [0:n_elements-1] /* synthesis syn_ramstyle = "no_rw_check" */;
  
  initial
  begin
    if (MEMORY_INIT_file != "")
      $readmemb(MEMORY_INIT_file, memory, 0, n_elements-1);
  end
  
  assign data_out = HIGH_LATENCY==0 ? data_out_mem : data_out1;
  always @(posedge clock)
    data_out1 <= data_out_mem;
  
  generate
    if(HIGH_LATENCY==2)
    begin
      always @ (posedge clock)
      begin
         address_in1 <= address_in;
         write_enable1 <= write_enable;
         data_in1 <= data_in;
      end
      assign address_in_mem = address_in1;
      assign write_enable_mem = write_enable1;
      assign data_in_mem = data_in1;
    end
    else
    begin
      assign address_in_mem = address_in;
      assign write_enable_mem = write_enable;
      assign data_in_mem = data_in;
    end
  endgenerate
  
  generate
    if (n_elements==1)
    begin
      always @(posedge clock)
      begin
        if(READ_ONLY_MEMORY==0)
        begin
          if(write_enable_mem[0])
            memory[address_in_mem[BITSIZE_address_in*0+:BITSIZE_address_in]] <= data_in_mem[BITSIZE_data_in*0+:BITSIZE_data_in];
        end
        data_out_mem[BITSIZE_data_out*0+:BITSIZE_data_out] <= memory[address_in_mem[BITSIZE_address_in*0+:BITSIZE_address_in]];
        if(READ_ONLY_MEMORY==0)
        begin
          if(write_enable_mem[1])
            memory[address_in_mem[BITSIZE_address_in*1+:BITSIZE_address_in]] <= data_in_mem[BITSIZE_data_in*1+:BITSIZE_data_in];
        end
        data_out_mem[BITSIZE_data_out*1+:BITSIZE_data_out] <= memory[address_in_mem[BITSIZE_address_in*1+:BITSIZE_address_in]];
      end
    end
    else
    begin
      always @(posedge clock)
      begin
        if(READ_ONLY_MEMORY==0)
        begin
          if(write_enable_mem[0])
            memory[address_in_mem[BITSIZE_address_in*0+:BITSIZE_address_in]] <= data_in_mem[BITSIZE_data_in*0+:BITSIZE_data_in];
        end
        data_out_mem[BITSIZE_data_out*0+:BITSIZE_data_out] <= memory[address_in_mem[BITSIZE_address_in*0+:BITSIZE_address_in]];
      end
      always @(posedge clock)
      begin
        if(READ_ONLY_MEMORY==0)
        begin
          if(write_enable_mem[1])
            memory[address_in_mem[BITSIZE_address_in*1+:BITSIZE_address_in]] <= data_in_mem[BITSIZE_data_in*1+:BITSIZE_data_in];
        end
        data_out_mem[BITSIZE_data_out*1+:BITSIZE_data_out] <= memory[address_in_mem[BITSIZE_address_in*1+:BITSIZE_address_in]];
      end
    end
  endgenerate
  

endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2023-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _STD_NRNW_BRAM_GEN_DEFINED
`define _STD_NRNW_BRAM_GEN_DEFINED
`timescale 1ns / 1ps
module STD_NRNW_BRAM_GEN(clock,
  write_enable,
  address_inr,
  address_inw,
  data_in,
  dout_value);
  parameter BITSIZE_write_enable=1, PORTSIZE_write_enable=1,
    BITSIZE_address_inr=1, PORTSIZE_address_inr=1,
    BITSIZE_address_inw=1, PORTSIZE_address_inw=1,
    BITSIZE_data_in=1, PORTSIZE_data_in=1,
    BITSIZE_dout_value=1, PORTSIZE_dout_value=1,
    MEMORY_INIT_file="array_a.mem",
    n_elements=32,
    READ_ONLY_MEMORY=0,
    HIGH_LATENCY=0;
  // IN
  input clock;
  input [PORTSIZE_write_enable-1:0] write_enable;
  input [(PORTSIZE_address_inr*BITSIZE_address_inr)+(-1):0] address_inr;
  input [(PORTSIZE_address_inw*BITSIZE_address_inw)+(-1):0] address_inw;
  input [(PORTSIZE_data_in*BITSIZE_data_in)+(-1):0] data_in;
  // OUT
  output [(PORTSIZE_dout_value*BITSIZE_dout_value)+(-1):0] dout_value;
  
  parameter nbit_addr = BITSIZE_address_inr > BITSIZE_address_inw ? BITSIZE_address_inr : BITSIZE_address_inw;
  wire [2*nbit_addr-1:0] address_in;
  generate
  if(PORTSIZE_address_inw == 1)
  begin
    STD_NR_BRAM #(
        .PORTSIZE_address_inr(PORTSIZE_address_inr),
        .BITSIZE_address_inr(BITSIZE_address_inr),
        .BITSIZE_address_inw(BITSIZE_address_inw),
        .BITSIZE_data_in(BITSIZE_data_in),
        .BITSIZE_data_out(BITSIZE_dout_value),
        .PORTSIZE_data_out(PORTSIZE_dout_value),
        .MEMORY_INIT_file(MEMORY_INIT_file),
        .n_elements(n_elements),
        .forwarding(0),
        .READ_ONLY_MEMORY(READ_ONLY_MEMORY),
        .HIGH_LATENCY(HIGH_LATENCY)
      )
      STD_NR_BRAM_FB_instance (
        .clock(clock),
        .write_enable(write_enable[0]),
        .address_inr(address_inr),
        .address_inw(address_inw[0+:BITSIZE_address_inw]),
        .data_in(data_in[0+:BITSIZE_data_in]),
        .data_out(dout_value));
  end
  else if(PORTSIZE_address_inr == 2 && PORTSIZE_address_inw == 2)
  begin
    assign address_in[0+:nbit_addr] = write_enable[0] ? address_inw[0+:BITSIZE_address_inw] : address_inr[0+:BITSIZE_address_inr];
    assign address_in[nbit_addr+:nbit_addr] = write_enable[1] ? address_inw[BITSIZE_address_inw+:BITSIZE_address_inw] : address_inr[BITSIZE_address_inr+:BITSIZE_address_inr];
    STD_DP_BRAM #(
      .PORTSIZE_write_enable(PORTSIZE_write_enable),
      .BITSIZE_write_enable(1),
      .PORTSIZE_data_in(PORTSIZE_data_in),
      .BITSIZE_data_in(BITSIZE_data_in),
      .PORTSIZE_data_out(PORTSIZE_dout_value),
      .BITSIZE_data_out(BITSIZE_dout_value),
      .PORTSIZE_address_in(2),
      .BITSIZE_address_in(nbit_addr),
      .n_elements(n_elements),
      .MEMORY_INIT_file(MEMORY_INIT_file),
      .READ_ONLY_MEMORY(READ_ONLY_MEMORY),
      .HIGH_LATENCY(HIGH_LATENCY)
    ) STD_DP_BRAM_instance (
      .clock(clock),
      .write_enable(write_enable),
      .data_in(data_in),
      .address_in(address_in),
      .data_out(dout_value)
    );
  end
  else
  begin
    STD_NRNW_BRAM_XOR #(
      .PORTSIZE_write_enable(PORTSIZE_write_enable),
      .BITSIZE_write_enable(BITSIZE_write_enable),
      .PORTSIZE_address_inr(PORTSIZE_address_inr),
      .BITSIZE_address_inr(BITSIZE_address_inr),
      .PORTSIZE_address_inw(PORTSIZE_address_inw),
      .BITSIZE_address_inw(BITSIZE_address_inw),
      .PORTSIZE_data_in(PORTSIZE_data_in),
      .BITSIZE_data_in(BITSIZE_data_in),
      .PORTSIZE_dout_value(PORTSIZE_dout_value),
      .BITSIZE_dout_value(BITSIZE_dout_value),
      .MEMORY_INIT_file(MEMORY_INIT_file),
      .n_elements(n_elements),
      .READ_ONLY_MEMORY(READ_ONLY_MEMORY),
      .HIGH_LATENCY(HIGH_LATENCY)
    ) STD_NRNW_BRAM_inst (
      .clock(clock),
      .write_enable(write_enable),
      .data_in(data_in),
      .address_inr(address_inr),
      .address_inw(address_inw),
      .dout_value(dout_value)
    );
  end
  endgenerate

endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ARRAY_1D_STD_BRAM_NN_SDS_BASE_DEFINED
`define _ARRAY_1D_STD_BRAM_NN_SDS_BASE_DEFINED
`timescale 1ns / 1ps
module ARRAY_1D_STD_BRAM_NN_SDS_BASE(clock,
  reset,
  in1,
  in2r,
  in2w,
  in3r,
  in3w,
  in4r,
  in4w,
  out1,
  sel_LOAD,
  sel_STORE,
  S_oe_ram,
  S_we_ram,
  S_addr_ram,
  S_Wdata_ram,
  Sin_Rdata_ram,
  Sout_Rdata_ram,
  S_data_ram_size,
  Sin_DataRdy,
  Sout_DataRdy,
  proxy_in1,
  proxy_in2r,
  proxy_in2w,
  proxy_in3r,
  proxy_in3w,
  proxy_in4r,
  proxy_in4w,
  proxy_sel_LOAD,
  proxy_sel_STORE,
  proxy_out1);
  parameter BITSIZE_in1=1, PORTSIZE_in1=1,
    BITSIZE_in2r=1, PORTSIZE_in2r=1,
    BITSIZE_in2w=1, PORTSIZE_in2w=1,
    BITSIZE_in3r=1, PORTSIZE_in3r=1,
    BITSIZE_in3w=1, PORTSIZE_in3w=1,
    BITSIZE_in4r=1, PORTSIZE_in4r=1,
    BITSIZE_in4w=1, PORTSIZE_in4w=1,
    BITSIZE_sel_LOAD=1, PORTSIZE_sel_LOAD=1,
    BITSIZE_sel_STORE=1, PORTSIZE_sel_STORE=1,
    BITSIZE_S_oe_ram=1, PORTSIZE_S_oe_ram=1,
    BITSIZE_S_we_ram=1, PORTSIZE_S_we_ram=1,
    BITSIZE_out1=1, PORTSIZE_out1=1,
    BITSIZE_S_addr_ram=1, PORTSIZE_S_addr_ram=1,
    BITSIZE_S_Wdata_ram=8, PORTSIZE_S_Wdata_ram=1,
    BITSIZE_Sin_Rdata_ram=8, PORTSIZE_Sin_Rdata_ram=1,
    BITSIZE_Sout_Rdata_ram=8, PORTSIZE_Sout_Rdata_ram=1,
    BITSIZE_S_data_ram_size=1, PORTSIZE_S_data_ram_size=1,
    BITSIZE_Sin_DataRdy=1, PORTSIZE_Sin_DataRdy=1,
    BITSIZE_Sout_DataRdy=1, PORTSIZE_Sout_DataRdy=1,
    MEMORY_INIT_file="array.mem",
    n_elements=1,
    data_size=32,
    address_space_begin=0,
    address_space_rangesize=4,
    BUS_PIPELINED=1,
    PRIVATE_MEMORY=0,
    READ_ONLY_MEMORY=0,
    USE_SPARSE_MEMORY=1,
    HIGH_LATENCY=0,
    ALIGNMENT=32,
    BITSIZE_proxy_in1=1, PORTSIZE_proxy_in1=1,
    BITSIZE_proxy_in2r=1, PORTSIZE_proxy_in2r=1,
    BITSIZE_proxy_in2w=1, PORTSIZE_proxy_in2w=1,
    BITSIZE_proxy_in3r=1, PORTSIZE_proxy_in3r=1,
    BITSIZE_proxy_in3w=1, PORTSIZE_proxy_in3w=1,
    BITSIZE_proxy_in4r=1, PORTSIZE_proxy_in4r=1,
    BITSIZE_proxy_in4w=1, PORTSIZE_proxy_in4w=1,
    BITSIZE_proxy_sel_LOAD=1, PORTSIZE_proxy_sel_LOAD=1,
    BITSIZE_proxy_sel_STORE=1, PORTSIZE_proxy_sel_STORE=1,
    BITSIZE_proxy_out1=1, PORTSIZE_proxy_out1=1;
  // IN
  input clock;
  input reset;
  input [(PORTSIZE_in1*BITSIZE_in1)+(-1):0] in1;
  input [(PORTSIZE_in2r*BITSIZE_in2r)+(-1):0] in2r;
  input [(PORTSIZE_in2w*BITSIZE_in2w)+(-1):0] in2w;
  input [(PORTSIZE_in3r*BITSIZE_in3r)+(-1):0] in3r;
  input [(PORTSIZE_in3w*BITSIZE_in3w)+(-1):0] in3w;
  input [PORTSIZE_in4r-1:0] in4r;
  input [PORTSIZE_in4w-1:0] in4w;
  input [PORTSIZE_sel_LOAD-1:0] sel_LOAD;
  input [PORTSIZE_sel_STORE-1:0] sel_STORE;
  input [PORTSIZE_S_oe_ram-1:0] S_oe_ram;
  input [PORTSIZE_S_we_ram-1:0] S_we_ram;
  input [(PORTSIZE_S_addr_ram*BITSIZE_S_addr_ram)+(-1):0] S_addr_ram;
  input [(PORTSIZE_S_Wdata_ram*BITSIZE_S_Wdata_ram)+(-1):0] S_Wdata_ram;
  input [(PORTSIZE_Sin_Rdata_ram*BITSIZE_Sin_Rdata_ram)+(-1):0] Sin_Rdata_ram;
  input [(PORTSIZE_S_data_ram_size*BITSIZE_S_data_ram_size)+(-1):0] S_data_ram_size;
  input [PORTSIZE_Sin_DataRdy-1:0] Sin_DataRdy;
  input [(PORTSIZE_proxy_in1*BITSIZE_proxy_in1)+(-1):0] proxy_in1;
  input [(PORTSIZE_proxy_in2r*BITSIZE_proxy_in2r)+(-1):0] proxy_in2r;
  input [(PORTSIZE_proxy_in2w*BITSIZE_proxy_in2w)+(-1):0] proxy_in2w;
  input [(PORTSIZE_proxy_in3r*BITSIZE_proxy_in3r)+(-1):0] proxy_in3r;
  input [(PORTSIZE_proxy_in3w*BITSIZE_proxy_in3w)+(-1):0] proxy_in3w;
  input [(PORTSIZE_proxy_in4r*BITSIZE_proxy_in4r)+(-1):0] proxy_in4r;
  input [(PORTSIZE_proxy_in4w*BITSIZE_proxy_in4w)+(-1):0] proxy_in4w;
  input [PORTSIZE_proxy_sel_LOAD-1:0] proxy_sel_LOAD;
  input [PORTSIZE_proxy_sel_STORE-1:0] proxy_sel_STORE;
  // OUT
  output [(PORTSIZE_out1*BITSIZE_out1)+(-1):0] out1;
  output [(PORTSIZE_Sout_Rdata_ram*BITSIZE_Sout_Rdata_ram)+(-1):0] Sout_Rdata_ram;
  output [PORTSIZE_Sout_DataRdy-1:0] Sout_DataRdy;
  output [(PORTSIZE_proxy_out1*BITSIZE_proxy_out1)+(-1):0] proxy_out1;
  
  `ifndef _SIM_HAVE_CLOG2
    function integer log2;
       input integer value;
       integer temp_value;
      begin
        temp_value = value-1;
        for (log2=0; temp_value>0; log2=log2+1)
          temp_value = temp_value>>1;
      end
    endfunction
  `endif
  parameter n_byte_on_databus = ALIGNMENT/8;
  parameter nbit_addr_r = BITSIZE_in2r > BITSIZE_proxy_in2r ? BITSIZE_in2r : BITSIZE_proxy_in2r;
  parameter nbit_addr_w = BITSIZE_in2w > BITSIZE_proxy_in2w ? BITSIZE_in2w : BITSIZE_proxy_in2w;
  `ifdef _SIM_HAVE_CLOG2
    localparam nbit_read_addr = n_elements == 1 ? 1 : $clog2(n_elements);
    localparam nbits_byte_offset = n_byte_on_databus<=1 ? 0 : $clog2(n_byte_on_databus);
  `else
    localparam nbit_read_addr = n_elements == 1 ? 1 : log2(n_elements);
    localparam nbits_byte_offset = n_byte_on_databus<=1 ? 0 : log2(n_byte_on_databus);
  `endif
  parameter max_n_writes = READ_ONLY_MEMORY ? 1 : PORTSIZE_sel_STORE;
  parameter max_n_reads = PORTSIZE_sel_LOAD;
  
  wire [nbit_read_addr*max_n_reads-1:0] memory_addr_a_r;
  wire [nbit_read_addr*max_n_writes-1:0] memory_addr_a_w;
  
  wire [max_n_writes-1:0] bram_write;
  
  wire [data_size*max_n_reads-1:0] dout_a;
  wire [nbit_addr_r*max_n_reads-1:0] relative_addr_r;
  wire [nbit_addr_w*max_n_writes-1:0] relative_addr_w;
  wire [nbit_addr_r*max_n_reads-1:0] tmp_addr_r;
  wire [nbit_addr_w*max_n_writes-1:0] tmp_addr_w;
  wire [data_size*max_n_writes-1:0] din_a;
  wire [data_size*max_n_writes-1:0] din_a_mem;
  reg [data_size*max_n_writes-1:0] din_a1;
  
  STD_NRNW_BRAM_GEN #(
    .PORTSIZE_write_enable(max_n_writes),
    .BITSIZE_write_enable(1),
    .PORTSIZE_data_in(max_n_writes),
    .BITSIZE_data_in(data_size),
    .PORTSIZE_dout_value(max_n_reads),
    .BITSIZE_dout_value(data_size),
    .PORTSIZE_address_inr(max_n_reads),
    .BITSIZE_address_inr(nbit_read_addr),
    .PORTSIZE_address_inw(max_n_writes),
    .BITSIZE_address_inw(nbit_read_addr),
    .n_elements(n_elements),
    .MEMORY_INIT_file(MEMORY_INIT_file),
    .READ_ONLY_MEMORY(READ_ONLY_MEMORY),
    .HIGH_LATENCY(HIGH_LATENCY)
  ) STD_NRNW_BRAM_GEN_instance (
    .clock(clock),
    .write_enable(bram_write),
    .data_in(din_a),
    .address_inr(memory_addr_a_r),
    .address_inw(memory_addr_a_w),
    .dout_value(dout_a)
  );
  
  generate
  genvar i14;
    for (i14=0; i14<max_n_writes; i14=i14+1)
    begin : L14
      assign din_a[(i14+1)*data_size-1:i14*data_size] = (proxy_sel_STORE[i14] && proxy_in4w[i14]) ? proxy_in1[(i14+1)*BITSIZE_proxy_in1-1:i14*BITSIZE_proxy_in1] : in1[(i14+1)*BITSIZE_in1-1:i14*BITSIZE_in1];
    end
  endgenerate
  
  generate
  genvar i21;
    for (i21=0; i21<max_n_writes; i21=i21+1)
    begin : L21
        assign bram_write[i21] = (sel_STORE[i21] && in4w[i21]) || (proxy_sel_STORE[i21] && proxy_in4w[i21]);
    end
  endgenerate
  
  generate
  genvar ind2r;
  for (ind2r=0; ind2r<max_n_reads; ind2r=ind2r+1)
    begin : Lind2r
      assign tmp_addr_r[(ind2r+1)*nbit_addr_r-1:ind2r*nbit_addr_r] = (proxy_sel_LOAD[ind2r] && proxy_in4r[ind2r]) ? proxy_in2r[(ind2r+1)*BITSIZE_proxy_in2r-1:ind2r*BITSIZE_proxy_in2r] : in2r[(ind2r+1)*BITSIZE_in2r-1:ind2r*BITSIZE_in2r];
    end
  endgenerate
  
  generate
  genvar ind2w;
  for (ind2w=0; ind2w<max_n_writes; ind2w=ind2w+1)
    begin : Lind2w
      assign tmp_addr_w[(ind2w+1)*nbit_addr_w-1:ind2w*nbit_addr_w] = (proxy_sel_STORE[ind2w] && proxy_in4w[ind2w]) ? proxy_in2w[(ind2w+1)*BITSIZE_proxy_in2w-1:ind2w*BITSIZE_proxy_in2w] : in2w[(ind2w+1)*BITSIZE_in2w-1:ind2w*BITSIZE_in2w];
    end
  endgenerate
  
  generate
  genvar i6r;
    for (i6r=0; i6r<max_n_reads; i6r=i6r+1)
    begin : L6r
      if(USE_SPARSE_MEMORY==1)
        assign relative_addr_r[(i6r+1)*nbit_addr_r-1:i6r*nbit_addr_r] = tmp_addr_r[(i6r+1)*nbit_addr_r-1:i6r*nbit_addr_r];
      else
        assign relative_addr_r[(i6r+1)*nbit_addr_r-1:i6r*nbit_addr_r] = tmp_addr_r[(i6r+1)*nbit_addr_r-1:i6r*nbit_addr_r]-address_space_begin;
    end
  endgenerate
  
  generate
  genvar i6w;
    for (i6w=0; i6w<max_n_writes; i6w=i6w+1)
    begin : L6w
      if(USE_SPARSE_MEMORY==1)
        assign relative_addr_w[(i6w+1)*nbit_addr_w-1:i6w*nbit_addr_w] = tmp_addr_w[(i6w+1)*nbit_addr_w-1:i6w*nbit_addr_w];
      else
        assign relative_addr_w[(i6w+1)*nbit_addr_w-1:i6w*nbit_addr_w] = tmp_addr_w[(i6w+1)*nbit_addr_w-1:i6w*nbit_addr_w]-address_space_begin;
    end
  endgenerate
  
  generate
  genvar i7r;
    for (i7r=0; i7r<max_n_reads; i7r=i7r+1)
    begin : L7_Ar
      if (n_elements==1)
        assign memory_addr_a_r[(i7r+1)*nbit_read_addr-1:i7r*nbit_read_addr] = {nbit_read_addr{1'b0}};
      else
        assign memory_addr_a_r[(i7r+1)*nbit_read_addr-1:i7r*nbit_read_addr] = relative_addr_r[nbit_read_addr+nbits_byte_offset-1+i7r*nbit_addr_r:nbits_byte_offset+i7r*nbit_addr_r];
    end
  endgenerate
  
  generate
  genvar i7w;
    for (i7w=0; i7w<max_n_writes; i7w=i7w+1)
    begin : L7_Aw
      if (n_elements==1)
        assign memory_addr_a_w[(i7w+1)*nbit_read_addr-1:i7w*nbit_read_addr] = {nbit_read_addr{1'b0}};
      else
        assign memory_addr_a_w[(i7w+1)*nbit_read_addr-1:i7w*nbit_read_addr] = relative_addr_w[nbit_read_addr+nbits_byte_offset-1+i7w*nbit_addr_w:nbits_byte_offset+i7w*nbit_addr_w];
    end
  endgenerate
  
  generate
  genvar i20;
    for (i20=0; i20<max_n_reads; i20=i20+1)
    begin : L20
      assign out1[(i20+1)*BITSIZE_out1-1:i20*BITSIZE_out1] = dout_a[(i20+1)*data_size-1:i20*data_size];
      assign proxy_out1[(i20+1)*BITSIZE_proxy_out1-1:i20*BITSIZE_proxy_out1] = dout_a[(i20+1)*data_size-1:i20*data_size];
    end
  endgenerate
  
  assign Sout_Rdata_ram =Sin_Rdata_ram;
  assign Sout_DataRdy = Sin_DataRdy;
  // Add assertion here
  // psl default clock = (posedge clock);
  // psl ERROR_CONCURRENT_WRITE_SAME_ADDR: assert never {max_n_writes == 2 && sel_STORE[0] && sel_STORE[1] && in4w[0] && in4w[1] && memory_addr_a_w[nbit_read_addr**(max_n_writes-1)+:nbit_read_addr] == memory_addr_a_w[nbit_read_addr*0+:nbit_read_addr]};
  // psl ERROR_CONCURRENT_WRITE_SAME_ADDR_PROXY: assert never {max_n_writes == 2 && proxy_sel_STORE[0] && proxy_sel_STORE[1] && proxy_in4w[0] && proxy_in4w[1] && memory_addr_a_w[nbit_read_addr*(max_n_writes-1)+:nbit_read_addr] == memory_addr_a_w[nbit_read_addr*0+:nbit_read_addr]};
  // psl ERROR_READONLY: assert never {READ_ONLY_MEMORY && (sel_STORE[0] || sel_STORE[1] || proxy_sel_STORE[0] || proxy_sel_STORE[1])};

endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ARRAY_1D_STD_BRAM_NN_SDS_DEFINED
`define _ARRAY_1D_STD_BRAM_NN_SDS_DEFINED
`timescale 1ns / 1ps
module ARRAY_1D_STD_BRAM_NN_SDS(clock,
  reset,
  in1,
  in2r,
  in2w,
  in3r,
  in3w,
  in4r,
  in4w,
  out1,
  sel_LOAD,
  sel_STORE,
  S_oe_ram,
  S_we_ram,
  S_addr_ram,
  S_Wdata_ram,
  Sin_Rdata_ram,
  Sout_Rdata_ram,
  S_data_ram_size,
  Sin_DataRdy,
  Sout_DataRdy,
  proxy_in1,
  proxy_in2r,
  proxy_in2w,
  proxy_in3r,
  proxy_in3w,
  proxy_in4r,
  proxy_in4w,
  proxy_sel_LOAD,
  proxy_sel_STORE,
  proxy_out1);
  parameter BITSIZE_in1=1, PORTSIZE_in1=1,
    BITSIZE_in2r=1, PORTSIZE_in2r=1,
    BITSIZE_in2w=1, PORTSIZE_in2w=1,
    BITSIZE_in3r=1, PORTSIZE_in3r=1,
    BITSIZE_in3w=1, PORTSIZE_in3w=1,
    BITSIZE_in4r=1, PORTSIZE_in4r=1,
    BITSIZE_in4w=1, PORTSIZE_in4w=1,
    BITSIZE_sel_LOAD=1, PORTSIZE_sel_LOAD=1,
    BITSIZE_sel_STORE=1, PORTSIZE_sel_STORE=1,
    BITSIZE_S_oe_ram=1, PORTSIZE_S_oe_ram=1,
    BITSIZE_S_we_ram=1, PORTSIZE_S_we_ram=1,
    BITSIZE_out1=1, PORTSIZE_out1=1,
    BITSIZE_S_addr_ram=1, PORTSIZE_S_addr_ram=1,
    BITSIZE_S_Wdata_ram=8, PORTSIZE_S_Wdata_ram=1,
    BITSIZE_Sin_Rdata_ram=8, PORTSIZE_Sin_Rdata_ram=1,
    BITSIZE_Sout_Rdata_ram=8, PORTSIZE_Sout_Rdata_ram=1,
    BITSIZE_S_data_ram_size=1, PORTSIZE_S_data_ram_size=1,
    BITSIZE_Sin_DataRdy=1, PORTSIZE_Sin_DataRdy=1,
    BITSIZE_Sout_DataRdy=1, PORTSIZE_Sout_DataRdy=1,
    MEMORY_INIT_file="array.mem",
    n_elements=1,
    data_size=32,
    address_space_begin=0,
    address_space_rangesize=4,
    BUS_PIPELINED=1,
    PRIVATE_MEMORY=0,
    READ_ONLY_MEMORY=0,
    USE_SPARSE_MEMORY=1,
    ALIGNMENT=32,
    BITSIZE_proxy_in1=1, PORTSIZE_proxy_in1=1,
    BITSIZE_proxy_in2r=1, PORTSIZE_proxy_in2r=1,
    BITSIZE_proxy_in2w=1, PORTSIZE_proxy_in2w=1,
    BITSIZE_proxy_in3r=1, PORTSIZE_proxy_in3r=1,
    BITSIZE_proxy_in3w=1, PORTSIZE_proxy_in3w=1,
    BITSIZE_proxy_in4r=1, PORTSIZE_proxy_in4r=1,
    BITSIZE_proxy_in4w=1, PORTSIZE_proxy_in4w=1,
    BITSIZE_proxy_sel_LOAD=1, PORTSIZE_proxy_sel_LOAD=1,
    BITSIZE_proxy_sel_STORE=1, PORTSIZE_proxy_sel_STORE=1,
    BITSIZE_proxy_out1=1, PORTSIZE_proxy_out1=1;
  // IN
  input clock;
  input reset;
  input [(PORTSIZE_in1*BITSIZE_in1)+(-1):0] in1;
  input [(PORTSIZE_in2r*BITSIZE_in2r)+(-1):0] in2r;
  input [(PORTSIZE_in2w*BITSIZE_in2w)+(-1):0] in2w;
  input [(PORTSIZE_in3r*BITSIZE_in3r)+(-1):0] in3r;
  input [(PORTSIZE_in3w*BITSIZE_in3w)+(-1):0] in3w;
  input [PORTSIZE_in4r-1:0] in4r;
  input [PORTSIZE_in4w-1:0] in4w;
  input [PORTSIZE_sel_LOAD-1:0] sel_LOAD;
  input [PORTSIZE_sel_STORE-1:0] sel_STORE;
  input [PORTSIZE_S_oe_ram-1:0] S_oe_ram;
  input [PORTSIZE_S_we_ram-1:0] S_we_ram;
  input [(PORTSIZE_S_addr_ram*BITSIZE_S_addr_ram)+(-1):0] S_addr_ram;
  input [(PORTSIZE_S_Wdata_ram*BITSIZE_S_Wdata_ram)+(-1):0] S_Wdata_ram;
  input [(PORTSIZE_Sin_Rdata_ram*BITSIZE_Sin_Rdata_ram)+(-1):0] Sin_Rdata_ram;
  input [(PORTSIZE_S_data_ram_size*BITSIZE_S_data_ram_size)+(-1):0] S_data_ram_size;
  input [PORTSIZE_Sin_DataRdy-1:0] Sin_DataRdy;
  input [(PORTSIZE_proxy_in1*BITSIZE_proxy_in1)+(-1):0] proxy_in1;
  input [(PORTSIZE_proxy_in2r*BITSIZE_proxy_in2r)+(-1):0] proxy_in2r;
  input [(PORTSIZE_proxy_in2w*BITSIZE_proxy_in2w)+(-1):0] proxy_in2w;
  input [(PORTSIZE_proxy_in3r*BITSIZE_proxy_in3r)+(-1):0] proxy_in3r;
  input [(PORTSIZE_proxy_in3w*BITSIZE_proxy_in3w)+(-1):0] proxy_in3w;
  input [PORTSIZE_proxy_in4r-1:0] proxy_in4r;
  input [PORTSIZE_proxy_in4w-1:0] proxy_in4w;
  input [PORTSIZE_proxy_sel_LOAD-1:0] proxy_sel_LOAD;
  input [PORTSIZE_proxy_sel_STORE-1:0] proxy_sel_STORE;
  // OUT
  output [(PORTSIZE_out1*BITSIZE_out1)+(-1):0] out1;
  output [(PORTSIZE_Sout_Rdata_ram*BITSIZE_Sout_Rdata_ram)+(-1):0] Sout_Rdata_ram;
  output [PORTSIZE_Sout_DataRdy-1:0] Sout_DataRdy;
  output [(PORTSIZE_proxy_out1*BITSIZE_proxy_out1)+(-1):0] proxy_out1;
  
  ARRAY_1D_STD_BRAM_NN_SDS_BASE #(
    .BITSIZE_in1(BITSIZE_in1),
    .PORTSIZE_in1(PORTSIZE_in1),
    .BITSIZE_in2r(BITSIZE_in2r),
    .PORTSIZE_in2r(PORTSIZE_in2r),
    .BITSIZE_in2w(BITSIZE_in2w),
    .PORTSIZE_in2w(PORTSIZE_in2w),
    .BITSIZE_in3r(BITSIZE_in3r),
    .PORTSIZE_in3r(PORTSIZE_in3r),
    .BITSIZE_in3w(BITSIZE_in3w),
    .PORTSIZE_in3w(PORTSIZE_in3w),
    .BITSIZE_in4r(BITSIZE_in4r),
    .PORTSIZE_in4r(PORTSIZE_in4r),
    .BITSIZE_in4w(BITSIZE_in4w),
    .PORTSIZE_in4w(PORTSIZE_in4w),
    .BITSIZE_sel_LOAD(BITSIZE_sel_LOAD),
    .PORTSIZE_sel_LOAD(PORTSIZE_sel_LOAD),
    .BITSIZE_sel_STORE(BITSIZE_sel_STORE),
    .PORTSIZE_sel_STORE(PORTSIZE_sel_STORE),
    .BITSIZE_S_oe_ram(BITSIZE_S_oe_ram),
    .PORTSIZE_S_oe_ram(PORTSIZE_S_oe_ram),
    .BITSIZE_S_we_ram(BITSIZE_S_we_ram),
    .PORTSIZE_S_we_ram(PORTSIZE_S_we_ram),
    .BITSIZE_out1(BITSIZE_out1),
    .PORTSIZE_out1(PORTSIZE_out1),
    .BITSIZE_S_addr_ram(BITSIZE_S_addr_ram),
    .PORTSIZE_S_addr_ram(PORTSIZE_S_addr_ram),
    .BITSIZE_S_Wdata_ram(BITSIZE_S_Wdata_ram),
    .PORTSIZE_S_Wdata_ram(PORTSIZE_S_Wdata_ram),
    .BITSIZE_Sin_Rdata_ram(BITSIZE_Sin_Rdata_ram),
    .PORTSIZE_Sin_Rdata_ram(PORTSIZE_Sin_Rdata_ram),
    .BITSIZE_Sout_Rdata_ram(BITSIZE_Sout_Rdata_ram),
    .PORTSIZE_Sout_Rdata_ram(PORTSIZE_Sout_Rdata_ram),
    .BITSIZE_S_data_ram_size(BITSIZE_S_data_ram_size),
    .PORTSIZE_S_data_ram_size(PORTSIZE_S_data_ram_size),
    .BITSIZE_Sin_DataRdy(BITSIZE_Sin_DataRdy),
    .PORTSIZE_Sin_DataRdy(PORTSIZE_Sin_DataRdy),
    .BITSIZE_Sout_DataRdy(BITSIZE_Sout_DataRdy),
    .PORTSIZE_Sout_DataRdy(PORTSIZE_Sout_DataRdy),
    .MEMORY_INIT_file(MEMORY_INIT_file),
    .n_elements(n_elements),
    .data_size(data_size),
    .address_space_begin(address_space_begin),
    .address_space_rangesize(address_space_rangesize),
    .BUS_PIPELINED(BUS_PIPELINED),
    .PRIVATE_MEMORY(PRIVATE_MEMORY),
    .READ_ONLY_MEMORY(READ_ONLY_MEMORY),
    .USE_SPARSE_MEMORY(USE_SPARSE_MEMORY),
    .HIGH_LATENCY(0),
    .ALIGNMENT(ALIGNMENT),
    .BITSIZE_proxy_in1(BITSIZE_proxy_in1),
    .PORTSIZE_proxy_in1(PORTSIZE_proxy_in1),
    .BITSIZE_proxy_in2r(BITSIZE_proxy_in2r),
    .PORTSIZE_proxy_in2r(PORTSIZE_proxy_in2r),
    .BITSIZE_proxy_in2w(BITSIZE_proxy_in2w),
    .PORTSIZE_proxy_in2w(PORTSIZE_proxy_in2w),
    .BITSIZE_proxy_in3r(BITSIZE_proxy_in3r),
    .PORTSIZE_proxy_in3r(PORTSIZE_proxy_in3r),
    .BITSIZE_proxy_in3w(BITSIZE_proxy_in3w),
    .PORTSIZE_proxy_in3w(PORTSIZE_proxy_in3w),
    .BITSIZE_proxy_in4r(BITSIZE_proxy_in4r),
    .PORTSIZE_proxy_in4r(PORTSIZE_proxy_in4r),
    .BITSIZE_proxy_in4w(BITSIZE_proxy_in4w),
    .PORTSIZE_proxy_in4w(PORTSIZE_proxy_in4w),
    .BITSIZE_proxy_sel_LOAD(BITSIZE_proxy_sel_LOAD),
    .PORTSIZE_proxy_sel_LOAD(PORTSIZE_proxy_sel_LOAD),
    .BITSIZE_proxy_sel_STORE(BITSIZE_proxy_sel_STORE),
    .PORTSIZE_proxy_sel_STORE(PORTSIZE_proxy_sel_STORE),
    .BITSIZE_proxy_out1(BITSIZE_proxy_out1),
    .PORTSIZE_proxy_out1(PORTSIZE_proxy_out1)) ARRAY_1D_STD_BRAM_NN_instance (.out1(out1),
    .Sout_Rdata_ram(Sout_Rdata_ram),
    .Sout_DataRdy(Sout_DataRdy),
    .proxy_out1(proxy_out1),
    .clock(clock),
    .reset(reset),
    .in1(in1),
    .in2r(in2r),
    .in2w(in2w),
    .in3r(in3r),
    .in3w(in3w),
    .in4r(in4r),
    .in4w(in4w),
    .sel_LOAD(sel_LOAD),
    .sel_STORE(sel_STORE),
    .S_oe_ram(S_oe_ram),
    .S_we_ram(S_we_ram),
    .S_addr_ram(S_addr_ram),
    .S_Wdata_ram(S_Wdata_ram),
    .Sin_Rdata_ram(Sin_Rdata_ram),
    .S_data_ram_size(S_data_ram_size ),
    .Sin_DataRdy(Sin_DataRdy),
    .proxy_in1(proxy_in1),
    .proxy_in2r(proxy_in2r),
    .proxy_in2w(proxy_in2w),
    .proxy_in3r(proxy_in3r),
    .proxy_in3w(proxy_in3w),
    .proxy_in4r(proxy_in4r),
    .proxy_in4w(proxy_in4w),
    .proxy_sel_LOAD(proxy_sel_LOAD),
    .proxy_sel_STORE(proxy_sel_STORE));
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ARRAY_1D_STD_DISTRAM_NN_SDS_DEFINED
`define _ARRAY_1D_STD_DISTRAM_NN_SDS_DEFINED
`timescale 1ns / 1ps
module ARRAY_1D_STD_DISTRAM_NN_SDS(clock,
  reset,
  in1,
  in2r,
  in2w,
  in3r,
  in3w,
  in4r,
  in4w,
  out1,
  sel_LOAD,
  sel_STORE,
  S_oe_ram,
  S_we_ram,
  S_addr_ram,
  S_Wdata_ram,
  Sin_Rdata_ram,
  Sout_Rdata_ram,
  S_data_ram_size,
  Sin_DataRdy,
  Sout_DataRdy,
  proxy_in1,
  proxy_in2r,
  proxy_in2w,
  proxy_in3r,
  proxy_in3w,
  proxy_in4r,
  proxy_in4w,
  proxy_sel_LOAD,
  proxy_sel_STORE,
  proxy_out1);
  parameter BITSIZE_in1=1, PORTSIZE_in1=1,
    BITSIZE_in2r=1, PORTSIZE_in2r=1,
    BITSIZE_in2w=1, PORTSIZE_in2w=1,
    BITSIZE_in3r=1, PORTSIZE_in3r=1,
    BITSIZE_in3w=1, PORTSIZE_in3w=1,
    BITSIZE_in4r=1, PORTSIZE_in4r=1,
    BITSIZE_in4w=1, PORTSIZE_in4w=1,
    BITSIZE_sel_LOAD=1, PORTSIZE_sel_LOAD=1,
    BITSIZE_sel_STORE=1, PORTSIZE_sel_STORE=1,
    BITSIZE_S_oe_ram=1, PORTSIZE_S_oe_ram=1,
    BITSIZE_S_we_ram=1, PORTSIZE_S_we_ram=1,
    BITSIZE_out1=1, PORTSIZE_out1=1,
    BITSIZE_S_addr_ram=1, PORTSIZE_S_addr_ram=1,
    BITSIZE_S_Wdata_ram=8, PORTSIZE_S_Wdata_ram=1,
    BITSIZE_Sin_Rdata_ram=8, PORTSIZE_Sin_Rdata_ram=1,
    BITSIZE_Sout_Rdata_ram=8, PORTSIZE_Sout_Rdata_ram=1,
    BITSIZE_S_data_ram_size=1, PORTSIZE_S_data_ram_size=1,
    BITSIZE_Sin_DataRdy=1, PORTSIZE_Sin_DataRdy=1,
    BITSIZE_Sout_DataRdy=1, PORTSIZE_Sout_DataRdy=1,
    MEMORY_INIT_file="array.mem",
    n_elements=1,
    data_size=32,
    address_space_begin=0,
    address_space_rangesize=4,
    BUS_PIPELINED=1,
    PRIVATE_MEMORY=0,
    READ_ONLY_MEMORY=0,
    USE_SPARSE_MEMORY=1,
    ALIGNMENT=32,
    BITSIZE_proxy_in1=1, PORTSIZE_proxy_in1=1,
    BITSIZE_proxy_in2r=1, PORTSIZE_proxy_in2r=1,
    BITSIZE_proxy_in2w=1, PORTSIZE_proxy_in2w=1,
    BITSIZE_proxy_in3r=1, PORTSIZE_proxy_in3r=1,
    BITSIZE_proxy_in3w=1, PORTSIZE_proxy_in3w=1,
    BITSIZE_proxy_in4r=1, PORTSIZE_proxy_in4r=1,
    BITSIZE_proxy_in4w=1, PORTSIZE_proxy_in4w=1,
    BITSIZE_proxy_sel_LOAD=1, PORTSIZE_proxy_sel_LOAD=1,
    BITSIZE_proxy_sel_STORE=1, PORTSIZE_proxy_sel_STORE=1,
    BITSIZE_proxy_out1=1, PORTSIZE_proxy_out1=1;
  // IN
  input clock;
  input reset;
  input [(PORTSIZE_in1*BITSIZE_in1)+(-1):0] in1;
  input [(PORTSIZE_in2r*BITSIZE_in2r)+(-1):0] in2r;
  input [(PORTSIZE_in2w*BITSIZE_in2w)+(-1):0] in2w;
  input [(PORTSIZE_in3r*BITSIZE_in3r)+(-1):0] in3r;
  input [(PORTSIZE_in3w*BITSIZE_in3w)+(-1):0] in3w;
  input [PORTSIZE_in4r-1:0] in4r;
  input [PORTSIZE_in4w-1:0] in4w;
  input [PORTSIZE_sel_LOAD-1:0] sel_LOAD;
  input [PORTSIZE_sel_STORE-1:0] sel_STORE;
  input [PORTSIZE_S_oe_ram-1:0] S_oe_ram;
  input [PORTSIZE_S_we_ram-1:0] S_we_ram;
  input [(PORTSIZE_S_addr_ram*BITSIZE_S_addr_ram)+(-1):0] S_addr_ram;
  input [(PORTSIZE_S_Wdata_ram*BITSIZE_S_Wdata_ram)+(-1):0] S_Wdata_ram;
  input [(PORTSIZE_Sin_Rdata_ram*BITSIZE_Sin_Rdata_ram)+(-1):0] Sin_Rdata_ram;
  input [(PORTSIZE_S_data_ram_size*BITSIZE_S_data_ram_size)+(-1):0] S_data_ram_size;
  input [PORTSIZE_Sin_DataRdy-1:0] Sin_DataRdy;
  input [(PORTSIZE_proxy_in1*BITSIZE_proxy_in1)+(-1):0] proxy_in1;
  input [(PORTSIZE_proxy_in2r*BITSIZE_proxy_in2r)+(-1):0] proxy_in2r;
  input [(PORTSIZE_proxy_in2w*BITSIZE_proxy_in2w)+(-1):0] proxy_in2w;
  input [(PORTSIZE_proxy_in3r*BITSIZE_proxy_in3r)+(-1):0] proxy_in3r;
  input [(PORTSIZE_proxy_in3w*BITSIZE_proxy_in3w)+(-1):0] proxy_in3w;
  input [(PORTSIZE_proxy_in4r*BITSIZE_proxy_in4r)+(-1):0] proxy_in4r;
  input [(PORTSIZE_proxy_in4w*BITSIZE_proxy_in4w)+(-1):0] proxy_in4w;
  input [PORTSIZE_proxy_sel_LOAD-1:0] proxy_sel_LOAD;
  input [PORTSIZE_proxy_sel_STORE-1:0] proxy_sel_STORE;
  // OUT
  output [(PORTSIZE_out1*BITSIZE_out1)+(-1):0] out1;
  output [(PORTSIZE_Sout_Rdata_ram*BITSIZE_Sout_Rdata_ram)+(-1):0] Sout_Rdata_ram;
  output [PORTSIZE_Sout_DataRdy-1:0] Sout_DataRdy;
  output [(PORTSIZE_proxy_out1*BITSIZE_proxy_out1)+(-1):0] proxy_out1;
  
  `ifndef _SIM_HAVE_CLOG2
      function integer log2;
        input integer value;
        integer temp_value;
        begin
        temp_value = value-1;
        for (log2=0; temp_value>0; log2=log2+1)
          temp_value = temp_value>>1;
        end
      endfunction
  `endif
  parameter n_byte_on_databus = ALIGNMENT/8;
  parameter nbit_addr_r = BITSIZE_in2r > BITSIZE_proxy_in2r ? BITSIZE_in2r : BITSIZE_proxy_in2r;
  parameter nbit_addr_w = BITSIZE_in2w > BITSIZE_proxy_in2w ? BITSIZE_in2w : BITSIZE_proxy_in2w;
  `ifdef _SIM_HAVE_CLOG2
    localparam nbit_read_addr = n_elements == 1 ? 1 : $clog2(n_elements);
    localparam nbits_byte_offset = n_byte_on_databus<=1 ? 0 : $clog2(n_byte_on_databus);
  `else
    localparam nbit_read_addr = n_elements == 1 ? 1 : log2(n_elements);
    localparam nbits_byte_offset = n_byte_on_databus<=1 ? 0 : log2(n_byte_on_databus);
  `endif
  parameter max_n_writes = PORTSIZE_sel_STORE;
  parameter max_n_reads = PORTSIZE_sel_LOAD;
  
  wire [max_n_writes-1:0] bram_write;
  
  wire [nbit_read_addr*max_n_reads-1:0] memory_addr_a_r;
  wire [nbit_read_addr*max_n_writes-1:0] memory_addr_a_w;
  
  wire [data_size*max_n_writes-1:0] din_value_aggregated;
  wire [data_size*max_n_reads-1:0] dout_a;
  wire [nbit_addr_r*max_n_reads-1:0] tmp_addr_r;
  wire [nbit_addr_w*max_n_writes-1:0] tmp_addr_w;
  wire [nbit_addr_r*max_n_reads-1:0] relative_addr_r;
  wire [nbit_addr_w*max_n_writes-1:0] relative_addr_w;
  integer index2;
  
  reg [data_size-1:0] memory [0:n_elements-1] /* synthesis syn_ramstyle = "no_rw_check" */;
  
  initial
  begin
    $readmemb(MEMORY_INIT_file,memory,0,n_elements-1);
  end
  
  generate
  genvar ind2_r;
  for (ind2_r=0; ind2_r<max_n_reads; ind2_r=ind2_r+1)
    begin : Lind2_r
      assign tmp_addr_r[(ind2_r+1)*nbit_addr_r-1:ind2_r*nbit_addr_r] = (proxy_sel_LOAD[ind2_r] && proxy_in4r[ind2_r]) ? proxy_in2r[(ind2_r+1)*BITSIZE_proxy_in2r-1:ind2_r*BITSIZE_proxy_in2r] : in2r[(ind2_r+1)*BITSIZE_in2r-1:ind2_r*BITSIZE_in2r];
    end
  endgenerate
  
  generate
  genvar ind2_w;
  for (ind2_w=0; ind2_w<max_n_writes; ind2_w=ind2_w+1)
    begin : Lind2_w
      assign tmp_addr_w[(ind2_w+1)*nbit_addr_w-1:ind2_w*nbit_addr_w] = (proxy_sel_STORE[ind2_w] && proxy_in4w[ind2_w]) ? proxy_in2w[(ind2_w+1)*BITSIZE_proxy_in2w-1:ind2_w*BITSIZE_proxy_in2w] : in2w[(ind2_w+1)*BITSIZE_in2w-1:ind2_w*BITSIZE_in2w];
    end
  endgenerate
  
  generate
  genvar i6_r;
    for (i6_r=0; i6_r<max_n_reads; i6_r=i6_r+1)
    begin : L6_r
      if(USE_SPARSE_MEMORY==1)
        assign relative_addr_r[(i6_r+1)*nbit_addr_r-1:i6_r*nbit_addr_r] = tmp_addr_r[(i6_r+1)*nbit_addr_r-1:i6_r*nbit_addr_r];
      else
        assign relative_addr_r[(i6_r+1)*nbit_addr_r-1:i6_r*nbit_addr_r] = tmp_addr_r[(i6_r+1)*nbit_addr_r-1:i6_r*nbit_addr_r]-address_space_begin;
    end
  endgenerate
  
  generate
  genvar i6_w;
    for (i6_w=0; i6_w<max_n_writes; i6_w=i6_w+1)
    begin : L6_w
      if(USE_SPARSE_MEMORY==1)
        assign relative_addr_w[(i6_w+1)*nbit_addr_w-1:i6_w*nbit_addr_w] = tmp_addr_w[(i6_w+1)*nbit_addr_w-1:i6_w*nbit_addr_w];
      else
        assign relative_addr_w[(i6_w+1)*nbit_addr_w-1:i6_w*nbit_addr_w] = tmp_addr_w[(i6_w+1)*nbit_addr_w-1:i6_w*nbit_addr_w]-address_space_begin;
    end
  endgenerate
  
  generate
  genvar i7_r;
    for (i7_r=0; i7_r<max_n_reads; i7_r=i7_r+1)
    begin : L7_A_r
      if (n_elements==1)
        assign memory_addr_a_r[(i7_r+1)*nbit_read_addr-1:i7_r*nbit_read_addr] = {nbit_read_addr{1'b0}};
      else
        assign memory_addr_a_r[(i7_r+1)*nbit_read_addr-1:i7_r*nbit_read_addr] = relative_addr_r[nbit_read_addr+nbits_byte_offset-1+i7_r*nbit_addr_r:nbits_byte_offset+i7_r*nbit_addr_r];
    end
  endgenerate
  
  generate
  genvar i7_w;
    for (i7_w=0; i7_w<max_n_writes; i7_w=i7_w+1)
    begin : L7_A_w
      if (n_elements==1)
        assign memory_addr_a_w[(i7_w+1)*nbit_read_addr-1:i7_w*nbit_read_addr] = {nbit_read_addr{1'b0}};
      else
        assign memory_addr_a_w[(i7_w+1)*nbit_read_addr-1:i7_w*nbit_read_addr] = relative_addr_w[nbit_read_addr+nbits_byte_offset-1+i7_w*nbit_addr_w:nbits_byte_offset+i7_w*nbit_addr_w];
    end
  endgenerate
  
  generate
  genvar i14;
    for (i14=0; i14<max_n_writes; i14=i14+1)
    begin : L14
      assign din_value_aggregated[(i14+1)*data_size-1:i14*data_size] = (proxy_sel_STORE[i14] && proxy_in4w[i14]) ? proxy_in1[(i14+1)*BITSIZE_proxy_in1-1:i14*BITSIZE_proxy_in1] : in1[(i14+1)*BITSIZE_in1-1:i14*BITSIZE_in1];
    end
  endgenerate
  
  generate
  genvar i11;
    for (i11=0; i11<max_n_reads; i11=i11+1)
    begin : asynchronous_read
      assign dout_a[data_size*i11+:data_size] = memory[memory_addr_a_r[nbit_read_addr*i11+:nbit_read_addr]];
    end
  endgenerate
  
  generate if(READ_ONLY_MEMORY==0)
    always @(posedge clock)
    begin
      for (index2=0; index2<max_n_writes; index2=index2+1)
      begin
        if(bram_write[index2])
          memory[memory_addr_a_w[nbit_read_addr*index2+:nbit_read_addr]] <= din_value_aggregated[data_size*index2+:data_size];
      end
    end
  endgenerate
  
  generate
  genvar i21;
    for (i21=0; i21<max_n_writes; i21=i21+1)
    begin : L21
        assign bram_write[i21] = (sel_STORE[i21] && in4w[i21]) || (proxy_sel_STORE[i21] && proxy_in4w[i21]);
    end
  endgenerate
  
  generate
  genvar i20;
    for (i20=0; i20<max_n_reads; i20=i20+1)
    begin : L20
      assign out1[(i20+1)*BITSIZE_out1-1:i20*BITSIZE_out1] = dout_a[(i20+1)*data_size-1:i20*data_size];
      assign proxy_out1[(i20+1)*BITSIZE_proxy_out1-1:i20*BITSIZE_proxy_out1] = dout_a[(i20+1)*data_size-1:i20*data_size];
    end
  endgenerate
  assign Sout_Rdata_ram =Sin_Rdata_ram;
  assign Sout_DataRdy = Sin_DataRdy;
  // Add assertion here
  // psl default clock = (posedge clock);
  // psl ERROR_CONCURRENT_WRITE_SAME_ADDR: assert never {sel_STORE[0] && sel_STORE[1] && in4w[0] && in4w[1] && memory_addr_a_w[nbit_read_addr*1+:nbit_read_addr] == memory_addr_a_w[nbit_read_addr*0+:nbit_read_addr]};

endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ARRAY_1D_STD_BRAM_NN_SDS_BUS_BASE_DEFINED
`define _ARRAY_1D_STD_BRAM_NN_SDS_BUS_BASE_DEFINED
`timescale 1ns / 1ps
module ARRAY_1D_STD_BRAM_NN_SDS_BUS_BASE(clock,
  reset,
  in1,
  in2,
  in3,
  out1,
  sel_LOAD,
  sel_STORE,
  S_oe_ram,
  S_we_ram,
  S_addr_ram,
  S_Wdata_ram,
  Sin_Rdata_ram,
  Sout_Rdata_ram,
  S_data_ram_size,
  Sin_DataRdy,
  Sout_DataRdy,
  proxy_in1,
  proxy_in2,
  proxy_in3,
  proxy_sel_LOAD,
  proxy_sel_STORE,
  proxy_out1);
  parameter BITSIZE_in1=1, PORTSIZE_in1=1,
    BITSIZE_in2=1, PORTSIZE_in2=1,
    BITSIZE_in3=1, PORTSIZE_in3=1,
    BITSIZE_sel_LOAD=1, PORTSIZE_sel_LOAD=1,
    BITSIZE_sel_STORE=1, PORTSIZE_sel_STORE=1,
    BITSIZE_S_oe_ram=1, PORTSIZE_S_oe_ram=1,
    BITSIZE_S_we_ram=1, PORTSIZE_S_we_ram=1,
    BITSIZE_out1=1, PORTSIZE_out1=1,
    BITSIZE_S_addr_ram=1, PORTSIZE_S_addr_ram=1,
    BITSIZE_S_Wdata_ram=8, PORTSIZE_S_Wdata_ram=1,
    BITSIZE_Sin_Rdata_ram=8, PORTSIZE_Sin_Rdata_ram=1,
    BITSIZE_Sout_Rdata_ram=8, PORTSIZE_Sout_Rdata_ram=1,
    BITSIZE_S_data_ram_size=1, PORTSIZE_S_data_ram_size=1,
    BITSIZE_Sin_DataRdy=1, PORTSIZE_Sin_DataRdy=1,
    BITSIZE_Sout_DataRdy=1, PORTSIZE_Sout_DataRdy=1,
    MEMORY_INIT_file="array.mem",
    n_elements=1,
    data_size=32,
    address_space_begin=0,
    address_space_rangesize=4,
    BUS_PIPELINED=1,
    PRIVATE_MEMORY=0,
    READ_ONLY_MEMORY=0,
    USE_SPARSE_MEMORY=1,
    HIGH_LATENCY=0,
    ALIGNMENT=32,
    BITSIZE_proxy_in1=1, PORTSIZE_proxy_in1=1,
    BITSIZE_proxy_in2=1, PORTSIZE_proxy_in2=1,
    BITSIZE_proxy_in3=1, PORTSIZE_proxy_in3=1,
    BITSIZE_proxy_sel_LOAD=1, PORTSIZE_proxy_sel_LOAD=1,
    BITSIZE_proxy_sel_STORE=1, PORTSIZE_proxy_sel_STORE=1,
    BITSIZE_proxy_out1=1, PORTSIZE_proxy_out1=1;
  // IN
  input clock;
  input reset;
  input [(PORTSIZE_in1*BITSIZE_in1)+(-1):0] in1;
  input [(PORTSIZE_in2*BITSIZE_in2)+(-1):0] in2;
  input [(PORTSIZE_in3*BITSIZE_in3)+(-1):0] in3;
  input [PORTSIZE_sel_LOAD-1:0] sel_LOAD;
  input [PORTSIZE_sel_STORE-1:0] sel_STORE;
  input [PORTSIZE_S_oe_ram-1:0] S_oe_ram;
  input [PORTSIZE_S_we_ram-1:0] S_we_ram;
  input [(PORTSIZE_S_addr_ram*BITSIZE_S_addr_ram)+(-1):0] S_addr_ram;
  input [(PORTSIZE_S_Wdata_ram*BITSIZE_S_Wdata_ram)+(-1):0] S_Wdata_ram;
  input [(PORTSIZE_Sin_Rdata_ram*BITSIZE_Sin_Rdata_ram)+(-1):0] Sin_Rdata_ram;
  input [(PORTSIZE_S_data_ram_size*BITSIZE_S_data_ram_size)+(-1):0] S_data_ram_size;
  input [PORTSIZE_Sin_DataRdy-1:0] Sin_DataRdy;
  input [(PORTSIZE_proxy_in1*BITSIZE_proxy_in1)+(-1):0] proxy_in1;
  input [(PORTSIZE_proxy_in2*BITSIZE_proxy_in2)+(-1):0] proxy_in2;
  input [(PORTSIZE_proxy_in3*BITSIZE_proxy_in3)+(-1):0] proxy_in3;
  input [PORTSIZE_proxy_sel_LOAD-1:0] proxy_sel_LOAD;
  input [PORTSIZE_proxy_sel_STORE-1:0] proxy_sel_STORE;
  // OUT
  output [(PORTSIZE_out1*BITSIZE_out1)+(-1):0] out1;
  output [(PORTSIZE_Sout_Rdata_ram*BITSIZE_Sout_Rdata_ram)+(-1):0] Sout_Rdata_ram;
  output [PORTSIZE_Sout_DataRdy-1:0] Sout_DataRdy;
  output [(PORTSIZE_proxy_out1*BITSIZE_proxy_out1)+(-1):0] proxy_out1;
  
  `ifndef _SIM_HAVE_CLOG2
    function integer log2;
       input integer value;
       integer temp_value;
      begin
        temp_value = value-1;
        for (log2=0; temp_value>0; log2=log2+1)
          temp_value = temp_value>>1;
      end
    endfunction
  `endif
  parameter n_byte_on_databus = ALIGNMENT/8;
  parameter nbit_addr = BITSIZE_in2 > BITSIZE_proxy_in2 ? BITSIZE_in2 : BITSIZE_proxy_in2;
  `ifdef _SIM_HAVE_CLOG2
    localparam nbit_read_addr = n_elements == 1 ? 1 : $clog2(n_elements);
    localparam nbits_address_space_rangesize = $clog2(address_space_rangesize);
    localparam nbits_byte_offset = n_byte_on_databus<=1 ? 0 : $clog2(n_byte_on_databus);
  `else
    localparam nbit_read_addr = n_elements == 1 ? 1 : log2(n_elements);
    localparam nbits_address_space_rangesize = log2(address_space_rangesize);
    localparam nbits_byte_offset = n_byte_on_databus<=1 ? 0 : log2(n_byte_on_databus);
  `endif
  parameter max_n_writes = PORTSIZE_sel_STORE;
  parameter max_n_reads = PORTSIZE_sel_LOAD;
  parameter max_n_rw = max_n_writes > max_n_reads ? max_n_writes : max_n_reads;
  parameter n_bus_ports = PORTSIZE_S_addr_ram;
  
  wire [nbit_read_addr*max_n_rw-1:0] memory_addr_a;
  
  wire [max_n_writes-1:0] bram_write;
  wire [data_size*max_n_reads-1:0] dout_a;
  wire [n_bus_ports-1:0] cs;
  wire [n_bus_ports-1:0] oe_ram_cs;
  wire [n_bus_ports-1:0] we_ram_cs;
  reg [n_bus_ports-1:0] we_ram_cs_delayed;
  reg [n_bus_ports-1:0] oe_ram_cs_delayed;
  reg [n_bus_ports-1:0] oe_ram_cs_delayed_registered;
  reg [n_bus_ports-1:0] oe_ram_cs_delayed_registered1;
  wire [nbit_addr*max_n_rw-1:0] relative_addr;
  wire [nbit_addr*max_n_rw-1:0] tmp_addr;
  wire [data_size*max_n_writes-1:0] din_a;
  wire [data_size*max_n_writes-1:0] din_a_mem;
  reg [data_size*max_n_writes-1:0] din_a1;
  wire [data_size*PORTSIZE_S_Wdata_ram-1:0] S_Wdata_ram_int;
  
  STD_NRNW_BRAM_GEN #(
    .PORTSIZE_write_enable(max_n_writes),
    .BITSIZE_write_enable(1),
    .PORTSIZE_data_in(max_n_writes),
    .BITSIZE_data_in(data_size),
    .PORTSIZE_dout_value(max_n_reads),
    .BITSIZE_dout_value(data_size),
    .PORTSIZE_address_inr(max_n_rw),
    .BITSIZE_address_inr(nbit_read_addr),
    .PORTSIZE_address_inw(max_n_rw),
    .BITSIZE_address_inw(nbit_read_addr),
    .n_elements(n_elements),
    .MEMORY_INIT_file(MEMORY_INIT_file),
    .READ_ONLY_MEMORY(READ_ONLY_MEMORY),
    .HIGH_LATENCY(HIGH_LATENCY)
  ) STD_NRNW_BRAM_GEN_instance (
    .clock(clock),
    .write_enable(bram_write),
    .data_in(din_a),
    .address_inr(memory_addr_a),
    .address_inw(memory_addr_a),
    .dout_value(dout_a)
  );
  
  generate
  genvar ind2;
  for (ind2=0; ind2<max_n_rw; ind2=ind2+1)
    begin : Lind2
      assign tmp_addr[(ind2+1)*nbit_addr-1:ind2*nbit_addr] = (proxy_sel_LOAD[ind2]||proxy_sel_STORE[ind2]) ? proxy_in2[(ind2+1)*BITSIZE_proxy_in2-1:ind2*BITSIZE_proxy_in2] : in2[(ind2+1)*BITSIZE_in2-1:ind2*BITSIZE_in2];
    end
  endgenerate
  
  generate
  genvar i3;
    for (i3=0; i3<n_bus_ports; i3=i3+1)
    begin : L3
      if(PRIVATE_MEMORY==0 && USE_SPARSE_MEMORY==0)
        assign cs[i3] = (S_addr_ram[(i3+1)*BITSIZE_S_addr_ram-1:i3*BITSIZE_S_addr_ram] >= (address_space_begin)) && (S_addr_ram[(i3+1)*BITSIZE_S_addr_ram-1:i3*BITSIZE_S_addr_ram] < (address_space_begin+address_space_rangesize));
      else if(PRIVATE_MEMORY==0 && nbits_address_space_rangesize < 32)
        assign cs[i3] = S_addr_ram[(i3+1)*BITSIZE_S_addr_ram-1:i3*BITSIZE_S_addr_ram+nbits_address_space_rangesize] == address_space_begin[((nbit_addr-1) < 32 ? (nbit_addr-1) : 31):nbits_address_space_rangesize];
      else
        assign cs[i3] = 1'b0;
    end
  endgenerate
  
  generate
  genvar i4;
    for (i4=0; i4<n_bus_ports; i4=i4+1)
    begin : L4
      assign oe_ram_cs[i4] = S_oe_ram[i4] & cs[i4];
    end
  endgenerate
  
  generate
  genvar i5;
    for (i5=0; i5<n_bus_ports; i5=i5+1)
    begin : L5
      assign we_ram_cs[i5] = S_we_ram[i5] & cs[i5];
    end
  endgenerate
  
  generate
  genvar i6;
    for (i6=0; i6<max_n_rw; i6=i6+1)
    begin : L6
      if(PRIVATE_MEMORY==0 && USE_SPARSE_MEMORY==0 && i6< n_bus_ports)
        assign relative_addr[(i6+1)*nbit_addr-1:i6*nbit_addr] = ((i6 < max_n_writes && (sel_STORE[i6]==1'b1 || proxy_sel_STORE[i6]==1'b1)) || (i6 < max_n_reads && (sel_LOAD[i6]==1'b1 || proxy_sel_LOAD[i6]==1'b1))) ? tmp_addr[(i6+1)*BITSIZE_in2-1:i6*BITSIZE_in2]-address_space_begin: S_addr_ram[(i6+1)*BITSIZE_S_addr_ram-1:i6*BITSIZE_S_addr_ram]-address_space_begin;
      else if(PRIVATE_MEMORY==0 && i6< n_bus_ports)
        assign relative_addr[(i6)*nbit_addr+nbits_address_space_rangesize-1:i6*nbit_addr] = ((i6 < max_n_writes && (sel_STORE[i6]==1'b1 || proxy_sel_STORE[i6]==1'b1)) || (i6 < max_n_reads && (sel_LOAD[i6]==1'b1 || proxy_sel_LOAD[i6]==1'b1))) ? tmp_addr[(i6)*BITSIZE_in2+nbits_address_space_rangesize-1:i6*BITSIZE_in2] : S_addr_ram[(i6)*BITSIZE_S_addr_ram+nbits_address_space_rangesize-1:i6*BITSIZE_S_addr_ram];
      else if(USE_SPARSE_MEMORY==1)
        assign relative_addr[(i6)*nbit_addr+nbits_address_space_rangesize-1:i6*nbit_addr] = tmp_addr[(i6)*BITSIZE_in2+nbits_address_space_rangesize-1:i6*BITSIZE_in2];
      else
        assign relative_addr[(i6+1)*nbit_addr-1:i6*nbit_addr] = tmp_addr[(i6+1)*BITSIZE_in2-1:i6*BITSIZE_in2]-address_space_begin;
    end
  endgenerate
  
  generate
  genvar i7;
    for (i7=0; i7<max_n_rw; i7=i7+1)
    begin : L7_A
      if (n_elements==1)
        assign memory_addr_a[(i7+1)*nbit_read_addr-1:i7*nbit_read_addr] = {nbit_read_addr{1'b0}};
      else
        assign memory_addr_a[(i7+1)*nbit_read_addr-1:i7*nbit_read_addr] = relative_addr[nbit_read_addr+nbits_byte_offset-1+i7*nbit_addr:nbits_byte_offset+i7*nbit_addr];
    end
  endgenerate
  
  generate
  genvar i13;
    for (i13=0; i13<n_bus_ports; i13=i13+1)
    begin : L13
      if (BITSIZE_S_Wdata_ram < data_size)
        assign S_Wdata_ram_int[data_size*(i13+1)-1:data_size*i13] = {{data_size-BITSIZE_S_Wdata_ram{1'b0}}, S_Wdata_ram[(i13+1)*BITSIZE_S_Wdata_ram-1:BITSIZE_S_Wdata_ram*i13]};
      else
        assign S_Wdata_ram_int[data_size*(i13+1)-1:data_size*i13] = S_Wdata_ram[data_size+BITSIZE_S_Wdata_ram*i13-1:BITSIZE_S_Wdata_ram*i13];
    end
  endgenerate
  
  generate
  genvar i14;
    for (i14=0; i14<max_n_writes; i14=i14+1)
    begin : L14
      if(PRIVATE_MEMORY==0 && i14 < n_bus_ports)
        assign din_a[(i14+1)*data_size-1:i14*data_size] = proxy_sel_STORE[i14] ? proxy_in1[(i14+1)*BITSIZE_proxy_in1-1:i14*BITSIZE_proxy_in1] : (sel_STORE[i14] ? in1[(i14+1)*BITSIZE_in1-1:i14*BITSIZE_in1] : S_Wdata_ram_int[data_size*(i14+1)-1:data_size*i14]);
      else
        assign din_a[(i14+1)*data_size-1:i14*data_size] = proxy_sel_STORE[i14] ? proxy_in1[(i14+1)*BITSIZE_proxy_in1-1:i14*BITSIZE_proxy_in1] : in1[(i14+1)*BITSIZE_in1-1:i14*BITSIZE_in1];
    end
  endgenerate
  
  generate
  genvar i20;
    for (i20=0; i20<max_n_reads; i20=i20+1)
    begin : L20
      assign out1[(i20+1)*BITSIZE_out1-1:i20*BITSIZE_out1] = dout_a[(i20+1)*data_size-1:i20*data_size];
      assign proxy_out1[(i20+1)*BITSIZE_proxy_out1-1:i20*BITSIZE_proxy_out1] = dout_a[(i20+1)*data_size-1:i20*data_size];
    end
  endgenerate
  
  generate
  genvar i16;
    for (i16=0; i16<n_bus_ports; i16=i16+1)
    begin : L16
      always @(posedge clock )
      begin
        if(reset == 1'b0)
          begin
            oe_ram_cs_delayed[i16] <= 1'b0;
            if(HIGH_LATENCY!=0) oe_ram_cs_delayed_registered[i16] <= 1'b0;
            if(HIGH_LATENCY == 2) oe_ram_cs_delayed_registered1[i16] <= 1'b0;
          end
        else
          begin
            if(HIGH_LATENCY==0)
              oe_ram_cs_delayed[i16] <= oe_ram_cs[i16] & (!oe_ram_cs_delayed[i16] | BUS_PIPELINED);
            else if(HIGH_LATENCY==1)
            begin
              oe_ram_cs_delayed_registered[i16] <= oe_ram_cs[i16] & ((!oe_ram_cs_delayed_registered[i16] & !oe_ram_cs_delayed[i16]) | BUS_PIPELINED);
              oe_ram_cs_delayed[i16] <= oe_ram_cs_delayed_registered[i16];
            end
            else
            begin
              oe_ram_cs_delayed_registered1[i16] <= oe_ram_cs[i16] & ((!oe_ram_cs_delayed_registered1[i16] & !oe_ram_cs_delayed_registered[i16]) | BUS_PIPELINED);
              oe_ram_cs_delayed_registered[i16] <= oe_ram_cs_delayed_registered1[i16];
              oe_ram_cs_delayed[i16] <= oe_ram_cs_delayed_registered[i16];
            end
          end
      end
    end
  endgenerate
  
  generate
  genvar i17;
    for (i17=0; i17<n_bus_ports; i17=i17+1)
    begin : L17
      always @(posedge clock )
      begin
        if(reset == 1'b0)
          we_ram_cs_delayed[i17] <= 1'b0;
        else
          we_ram_cs_delayed[i17] <= we_ram_cs[i17] & !we_ram_cs_delayed[i17];
      end
    end
  endgenerate
  
  generate
  genvar i18;
    for (i18=0; i18<n_bus_ports; i18=i18+1)
    begin : L18
      if(PRIVATE_MEMORY==1)
        assign Sout_Rdata_ram[(i18+1)*BITSIZE_Sout_Rdata_ram-1:i18*BITSIZE_Sout_Rdata_ram] = Sin_Rdata_ram[(i18+1)*BITSIZE_Sin_Rdata_ram-1:i18*BITSIZE_Sin_Rdata_ram];
      else if (BITSIZE_Sout_Rdata_ram <= data_size)
        assign Sout_Rdata_ram[(i18+1)*BITSIZE_Sout_Rdata_ram-1:i18*BITSIZE_Sout_Rdata_ram] = oe_ram_cs_delayed[i18] ? dout_a[BITSIZE_Sout_Rdata_ram+i18*data_size-1:i18*data_size] : Sin_Rdata_ram[(i18+1)*BITSIZE_Sin_Rdata_ram-1:i18*BITSIZE_Sin_Rdata_ram];
      else
        assign Sout_Rdata_ram[(i18+1)*BITSIZE_Sout_Rdata_ram-1:i18*BITSIZE_Sout_Rdata_ram] = oe_ram_cs_delayed[i18] ? {{BITSIZE_S_Wdata_ram-data_size{1'b0}}, dout_a[(i18+1)*data_size-1:i18*data_size]} : Sin_Rdata_ram[(i18+1)*BITSIZE_Sin_Rdata_ram-1:i18*BITSIZE_Sin_Rdata_ram];
    end
  endgenerate
  
  generate
  genvar i19;
    for (i19=0; i19<n_bus_ports; i19=i19+1)
    begin : L19
      if(PRIVATE_MEMORY==0)
        assign Sout_DataRdy[i19] = (i19 < n_bus_ports && oe_ram_cs_delayed[i19]) | Sin_DataRdy[i19] | (i19 < n_bus_ports && we_ram_cs_delayed[i19]);
      else
        assign Sout_DataRdy[i19] = Sin_DataRdy[i19];
    end
  endgenerate
  
  generate
  genvar i21;
    for (i21=0; i21<max_n_writes; i21=i21+1)
    begin : L21
      if(i21 < n_bus_ports)
        assign bram_write[i21] = (sel_STORE[i21] || proxy_sel_STORE[i21] || we_ram_cs[i21]);
      else
        assign bram_write[i21] = (sel_STORE[i21] || proxy_sel_STORE[i21]);
    end
  endgenerate
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ARRAY_1D_STD_BRAM_NN_SDS_BUS_DEFINED
`define _ARRAY_1D_STD_BRAM_NN_SDS_BUS_DEFINED
`timescale 1ns / 1ps
module ARRAY_1D_STD_BRAM_NN_SDS_BUS(clock,
  reset,
  in1,
  in2,
  in3,
  in4,
  out1,
  sel_LOAD,
  sel_STORE,
  S_oe_ram,
  S_we_ram,
  S_addr_ram,
  S_Wdata_ram,
  Sin_Rdata_ram,
  Sout_Rdata_ram,
  S_data_ram_size,
  Sin_DataRdy,
  Sout_DataRdy,
  proxy_in1,
  proxy_in2,
  proxy_in3,
  proxy_sel_LOAD,
  proxy_sel_STORE,
  proxy_out1);
  parameter BITSIZE_in1=1, PORTSIZE_in1=1,
    BITSIZE_in2=1, PORTSIZE_in2=1,
    BITSIZE_in3=1, PORTSIZE_in3=1,
    BITSIZE_in4=1, PORTSIZE_in4=1,
    BITSIZE_sel_LOAD=1, PORTSIZE_sel_LOAD=1,
    BITSIZE_sel_STORE=1, PORTSIZE_sel_STORE=1,
    BITSIZE_S_oe_ram=1, PORTSIZE_S_oe_ram=1,
    BITSIZE_S_we_ram=1, PORTSIZE_S_we_ram=1,
    BITSIZE_out1=1, PORTSIZE_out1=1,
    BITSIZE_S_addr_ram=1, PORTSIZE_S_addr_ram=1,
    BITSIZE_S_Wdata_ram=8, PORTSIZE_S_Wdata_ram=1,
    BITSIZE_Sin_Rdata_ram=8, PORTSIZE_Sin_Rdata_ram=1,
    BITSIZE_Sout_Rdata_ram=8, PORTSIZE_Sout_Rdata_ram=1,
    BITSIZE_S_data_ram_size=1, PORTSIZE_S_data_ram_size=1,
    BITSIZE_Sin_DataRdy=1, PORTSIZE_Sin_DataRdy=1,
    BITSIZE_Sout_DataRdy=1, PORTSIZE_Sout_DataRdy=1,
    MEMORY_INIT_file="array.mem",
    n_elements=1,
    data_size=32,
    address_space_begin=0,
    address_space_rangesize=4,
    BUS_PIPELINED=1,
    PRIVATE_MEMORY=0,
    READ_ONLY_MEMORY=0,
    USE_SPARSE_MEMORY=1,
    ALIGNMENT=32,
    BITSIZE_proxy_in1=1, PORTSIZE_proxy_in1=1,
    BITSIZE_proxy_in2=1, PORTSIZE_proxy_in2=1,
    BITSIZE_proxy_in3=1, PORTSIZE_proxy_in3=1,
    BITSIZE_proxy_sel_LOAD=1, PORTSIZE_proxy_sel_LOAD=1,
    BITSIZE_proxy_sel_STORE=1, PORTSIZE_proxy_sel_STORE=1,
    BITSIZE_proxy_out1=1, PORTSIZE_proxy_out1=1;
  // IN
  input clock;
  input reset;
  input [(PORTSIZE_in1*BITSIZE_in1)+(-1):0] in1;
  input [(PORTSIZE_in2*BITSIZE_in2)+(-1):0] in2;
  input [(PORTSIZE_in3*BITSIZE_in3)+(-1):0] in3;
  input [PORTSIZE_in4-1:0] in4;
  input [PORTSIZE_sel_LOAD-1:0] sel_LOAD;
  input [PORTSIZE_sel_STORE-1:0] sel_STORE;
  input [PORTSIZE_S_oe_ram-1:0] S_oe_ram;
  input [PORTSIZE_S_we_ram-1:0] S_we_ram;
  input [(PORTSIZE_S_addr_ram*BITSIZE_S_addr_ram)+(-1):0] S_addr_ram;
  input [(PORTSIZE_S_Wdata_ram*BITSIZE_S_Wdata_ram)+(-1):0] S_Wdata_ram;
  input [(PORTSIZE_Sin_Rdata_ram*BITSIZE_Sin_Rdata_ram)+(-1):0] Sin_Rdata_ram;
  input [(PORTSIZE_S_data_ram_size*BITSIZE_S_data_ram_size)+(-1):0] S_data_ram_size;
  input [PORTSIZE_Sin_DataRdy-1:0] Sin_DataRdy;
  input [(PORTSIZE_proxy_in1*BITSIZE_proxy_in1)+(-1):0] proxy_in1;
  input [(PORTSIZE_proxy_in2*BITSIZE_proxy_in2)+(-1):0] proxy_in2;
  input [(PORTSIZE_proxy_in3*BITSIZE_proxy_in3)+(-1):0] proxy_in3;
  input [PORTSIZE_proxy_sel_LOAD-1:0] proxy_sel_LOAD;
  input [PORTSIZE_proxy_sel_STORE-1:0] proxy_sel_STORE;
  // OUT
  output [(PORTSIZE_out1*BITSIZE_out1)+(-1):0] out1;
  output [(PORTSIZE_Sout_Rdata_ram*BITSIZE_Sout_Rdata_ram)+(-1):0] Sout_Rdata_ram;
  output [PORTSIZE_Sout_DataRdy-1:0] Sout_DataRdy;
  output [(PORTSIZE_proxy_out1*BITSIZE_proxy_out1)+(-1):0] proxy_out1;
  ARRAY_1D_STD_BRAM_NN_SDS_BUS_BASE #(
    .BITSIZE_in1(BITSIZE_in1),
    .PORTSIZE_in1(PORTSIZE_in1),
    .BITSIZE_in2(BITSIZE_in2),
    .PORTSIZE_in2(PORTSIZE_in2),
    .BITSIZE_in3(BITSIZE_in3),
    .PORTSIZE_in3(PORTSIZE_in3),
    .BITSIZE_sel_LOAD(BITSIZE_sel_LOAD),
    .PORTSIZE_sel_LOAD(PORTSIZE_sel_LOAD),
    .BITSIZE_sel_STORE(BITSIZE_sel_STORE),
    .PORTSIZE_sel_STORE(PORTSIZE_sel_STORE),
    .BITSIZE_S_oe_ram(BITSIZE_S_oe_ram),
    .PORTSIZE_S_oe_ram(PORTSIZE_S_oe_ram),
    .BITSIZE_S_we_ram(BITSIZE_S_we_ram),
    .PORTSIZE_S_we_ram(PORTSIZE_S_we_ram),
    .BITSIZE_out1(BITSIZE_out1),
    .PORTSIZE_out1(PORTSIZE_out1),
    .BITSIZE_S_addr_ram(BITSIZE_S_addr_ram),
    .PORTSIZE_S_addr_ram(PORTSIZE_S_addr_ram),
    .BITSIZE_S_Wdata_ram(BITSIZE_S_Wdata_ram),
    .PORTSIZE_S_Wdata_ram(PORTSIZE_S_Wdata_ram),
    .BITSIZE_Sin_Rdata_ram(BITSIZE_Sin_Rdata_ram),
    .PORTSIZE_Sin_Rdata_ram(PORTSIZE_Sin_Rdata_ram),
    .BITSIZE_Sout_Rdata_ram(BITSIZE_Sout_Rdata_ram),
    .PORTSIZE_Sout_Rdata_ram(PORTSIZE_Sout_Rdata_ram),
    .BITSIZE_S_data_ram_size(BITSIZE_S_data_ram_size),
    .PORTSIZE_S_data_ram_size(PORTSIZE_S_data_ram_size),
    .BITSIZE_Sin_DataRdy(BITSIZE_Sin_DataRdy),
    .PORTSIZE_Sin_DataRdy(PORTSIZE_Sin_DataRdy),
    .BITSIZE_Sout_DataRdy(BITSIZE_Sout_DataRdy),
    .PORTSIZE_Sout_DataRdy(PORTSIZE_Sout_DataRdy),
    .MEMORY_INIT_file(MEMORY_INIT_file),
    .n_elements(n_elements),
    .data_size(data_size),
    .address_space_begin(address_space_begin),
    .address_space_rangesize(address_space_rangesize),
    .BUS_PIPELINED(BUS_PIPELINED),
    .PRIVATE_MEMORY(PRIVATE_MEMORY),
    .READ_ONLY_MEMORY(READ_ONLY_MEMORY),
    .USE_SPARSE_MEMORY(USE_SPARSE_MEMORY),
    .HIGH_LATENCY(0),
    .ALIGNMENT(ALIGNMENT),
    .BITSIZE_proxy_in1(BITSIZE_proxy_in1),
    .PORTSIZE_proxy_in1(PORTSIZE_proxy_in1),
    .BITSIZE_proxy_in2(BITSIZE_proxy_in2),
    .PORTSIZE_proxy_in2(PORTSIZE_proxy_in2),
    .BITSIZE_proxy_in3(BITSIZE_proxy_in3),
    .PORTSIZE_proxy_in3(PORTSIZE_proxy_in3),
    .BITSIZE_proxy_sel_LOAD(BITSIZE_proxy_sel_LOAD),
    .PORTSIZE_proxy_sel_LOAD(PORTSIZE_proxy_sel_LOAD),
    .BITSIZE_proxy_sel_STORE(BITSIZE_proxy_sel_STORE),
    .PORTSIZE_proxy_sel_STORE(PORTSIZE_proxy_sel_STORE),
    .BITSIZE_proxy_out1(BITSIZE_proxy_out1),
    .PORTSIZE_proxy_out1(PORTSIZE_proxy_out1)) ARRAY_1D_STD_BRAM_NN_instance (.out1(out1),
    .Sout_Rdata_ram(Sout_Rdata_ram),
    .Sout_DataRdy(Sout_DataRdy),
    .proxy_out1(proxy_out1),
    .clock(clock),
    .reset(reset),
    .in1(in1),
    .in2(in2),
    .in3(in3),
    .sel_LOAD(sel_LOAD & in4),
    .sel_STORE(sel_STORE & in4),
    .S_oe_ram(S_oe_ram),
    .S_we_ram(S_we_ram),
    .S_addr_ram(S_addr_ram),
    .S_Wdata_ram(S_Wdata_ram),
    .Sin_Rdata_ram(Sin_Rdata_ram),
    .S_data_ram_size(S_data_ram_size ),
    .Sin_DataRdy(Sin_DataRdy),
    .proxy_in1(proxy_in1),
    .proxy_in2(proxy_in2),
    .proxy_in3(proxy_in3),
    .proxy_sel_LOAD(proxy_sel_LOAD),
    .proxy_sel_STORE(proxy_sel_STORE));
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _addr_node_FU_DEFINED
`define _addr_node_FU_DEFINED
`timescale 1ns / 1ps
module addr_node_FU(in1,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _multi_read_cond_FU_DEFINED
`define _multi_read_cond_FU_DEFINED
`timescale 1ns / 1ps
module multi_read_cond_FU(in1,
  out1);
  parameter BITSIZE_in1=1, PORTSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input [(PORTSIZE_in1*BITSIZE_in1)+(-1):0] in1;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2016-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _lut_node_FU_DEFINED
`define _lut_node_FU_DEFINED
`timescale 1ns / 1ps
module lut_node_FU(in1,
  in2,
  in3,
  in4,
  in5,
  in6,
  in7,
  in8,
  in9,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input in2;
  input in3;
  input in4;
  input in5;
  input in6;
  input in7;
  input in8;
  input in9;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  reg[7:0] cleaned_in0;
  wire [7:0] in0;
  wire[BITSIZE_in1-1:0] shifted_s;
  assign in0 = {in9, in8, in7, in6, in5, in4, in3, in2};
  generate
    genvar i0;
    for (i0=0; i0<8; i0=i0+1)
    begin : L0
          always @(*)
          begin
             if (in0[i0] == 1'b1)
                cleaned_in0[i0] = 1'b1;
             else
                cleaned_in0[i0] = 1'b0;
          end
    end
  endgenerate
  assign shifted_s = in1 >> cleaned_in0;
  assign out1[0] = shifted_s[0];
  generate
     if(BITSIZE_out1 > 1)
       assign out1[BITSIZE_out1-1:1] = 0;
  endgenerate

endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _UUdata_converter_FU_DEFINED
`define _UUdata_converter_FU_DEFINED
`timescale 1ns / 1ps
module UUdata_converter_FU(in1,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  generate
  if (BITSIZE_out1 <= BITSIZE_in1)
  begin
    assign out1 = in1[BITSIZE_out1-1:0];
  end
  else
  begin
    assign out1 = {{(BITSIZE_out1-BITSIZE_in1){1'b0}},in1};
  end
  endgenerate
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2020-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ui_extract_bit_node_FU_DEFINED
`define _ui_extract_bit_node_FU_DEFINED
`timescale 1ns / 1ps
module ui_extract_bit_node_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output out1;
  assign out1 = (in1 >> in2)&1;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ASSIGN_UNSIGNED_FU_DEFINED
`define _ASSIGN_UNSIGNED_FU_DEFINED
`timescale 1ns / 1ps
module ASSIGN_UNSIGNED_FU(in1,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _UIdata_converter_FU_DEFINED
`define _UIdata_converter_FU_DEFINED
`timescale 1ns / 1ps
module UIdata_converter_FU(in1,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  // OUT
  output signed [BITSIZE_out1-1:0] out1;
  generate
  if (BITSIZE_out1 <= BITSIZE_in1)
  begin
    assign out1 = in1[BITSIZE_out1-1:0];
  end
  else
  begin
    assign out1 = {{(BITSIZE_out1-BITSIZE_in1){1'b0}},in1};
  end
  endgenerate
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _IUdata_converter_FU_DEFINED
`define _IUdata_converter_FU_DEFINED
`timescale 1ns / 1ps
module IUdata_converter_FU(in1,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input signed [BITSIZE_in1-1:0] in1;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  generate
  if (BITSIZE_out1 <= BITSIZE_in1)
  begin
    assign out1 = in1[BITSIZE_out1-1:0];
  end
  else
  begin
    assign out1 = {{(BITSIZE_out1-BITSIZE_in1){in1[BITSIZE_in1-1]}},in1};
  end
  endgenerate
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _IIdata_converter_FU_DEFINED
`define _IIdata_converter_FU_DEFINED
`timescale 1ns / 1ps
module IIdata_converter_FU(in1,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input signed [BITSIZE_in1-1:0] in1;
  // OUT
  output signed [BITSIZE_out1-1:0] out1;
  generate
  if (BITSIZE_out1 <= BITSIZE_in1)
  begin
    assign out1 = in1[BITSIZE_out1-1:0];
  end
  else
  begin
    assign out1 = {{(BITSIZE_out1-BITSIZE_in1){in1[BITSIZE_in1-1]}},in1};
  end
  endgenerate
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _BMEMORY_CTRLN_DEFINED
`define _BMEMORY_CTRLN_DEFINED
`timescale 1ns / 1ps
module BMEMORY_CTRLN(clock,
  in1,
  in2,
  in3,
  in4,
  sel_LOAD,
  sel_STORE,
  out1,
  Min_oe_ram,
  Mout_oe_ram,
  Min_we_ram,
  Mout_we_ram,
  Min_addr_ram,
  Mout_addr_ram,
  M_Rdata_ram,
  Min_Wdata_ram,
  Mout_Wdata_ram,
  Min_data_ram_size,
  Mout_data_ram_size,
  M_DataRdy);
  parameter BITSIZE_in1=1, PORTSIZE_in1=1,
    BITSIZE_in2=1, PORTSIZE_in2=1,
    BITSIZE_in3=1, PORTSIZE_in3=1,
    BITSIZE_in4=1, PORTSIZE_in4=1,
    BITSIZE_sel_LOAD=1, PORTSIZE_sel_LOAD=1,
    BITSIZE_sel_STORE=1, PORTSIZE_sel_STORE=1,
    BITSIZE_out1=1, PORTSIZE_out1=1,
    BITSIZE_Min_oe_ram=1, PORTSIZE_Min_oe_ram=1,
    BITSIZE_Min_we_ram=1, PORTSIZE_Min_we_ram=1,
    BITSIZE_Mout_oe_ram=1, PORTSIZE_Mout_oe_ram=1,
    BITSIZE_Mout_we_ram=1, PORTSIZE_Mout_we_ram=1,
    BITSIZE_M_DataRdy=1, PORTSIZE_M_DataRdy=1,
    BITSIZE_Min_addr_ram=1, PORTSIZE_Min_addr_ram=1,
    BITSIZE_Mout_addr_ram=1, PORTSIZE_Mout_addr_ram=1,
    BITSIZE_M_Rdata_ram=8, PORTSIZE_M_Rdata_ram=1,
    BITSIZE_Min_Wdata_ram=8, PORTSIZE_Min_Wdata_ram=1,
    BITSIZE_Mout_Wdata_ram=8, PORTSIZE_Mout_Wdata_ram=1,
    BITSIZE_Min_data_ram_size=1, PORTSIZE_Min_data_ram_size=1,
    BITSIZE_Mout_data_ram_size=1, PORTSIZE_Mout_data_ram_size=1;
  // IN
  input clock;
  input [(PORTSIZE_in1*BITSIZE_in1)+(-1):0] in1;
  input [(PORTSIZE_in2*BITSIZE_in2)+(-1):0] in2;
  input [(PORTSIZE_in3*BITSIZE_in3)+(-1):0] in3;
  input [PORTSIZE_in4-1:0] in4;
  input [PORTSIZE_sel_LOAD-1:0] sel_LOAD;
  input [PORTSIZE_sel_STORE-1:0] sel_STORE;
  input [PORTSIZE_Min_oe_ram-1:0] Min_oe_ram;
  input [PORTSIZE_Min_we_ram-1:0] Min_we_ram;
  input [(PORTSIZE_Min_addr_ram*BITSIZE_Min_addr_ram)+(-1):0] Min_addr_ram;
  input [(PORTSIZE_M_Rdata_ram*BITSIZE_M_Rdata_ram)+(-1):0] M_Rdata_ram;
  input [(PORTSIZE_Min_Wdata_ram*BITSIZE_Min_Wdata_ram)+(-1):0] Min_Wdata_ram;
  input [(PORTSIZE_Min_data_ram_size*BITSIZE_Min_data_ram_size)+(-1):0] Min_data_ram_size;
  input [PORTSIZE_M_DataRdy-1:0] M_DataRdy;
  // OUT
  output [(PORTSIZE_out1*BITSIZE_out1)+(-1):0] out1;
  output [PORTSIZE_Mout_oe_ram-1:0] Mout_oe_ram;
  output [PORTSIZE_Mout_we_ram-1:0] Mout_we_ram;
  output [(PORTSIZE_Mout_addr_ram*BITSIZE_Mout_addr_ram)+(-1):0] Mout_addr_ram;
  output [(PORTSIZE_Mout_Wdata_ram*BITSIZE_Mout_Wdata_ram)+(-1):0] Mout_Wdata_ram;
  output [(PORTSIZE_Mout_data_ram_size*BITSIZE_Mout_data_ram_size)+(-1):0] Mout_data_ram_size;
  
  parameter max_n_writes = PORTSIZE_sel_STORE > PORTSIZE_Mout_we_ram ? PORTSIZE_sel_STORE : PORTSIZE_Mout_we_ram;
  parameter max_n_reads = PORTSIZE_sel_LOAD > PORTSIZE_Mout_oe_ram ? PORTSIZE_sel_STORE : PORTSIZE_Mout_oe_ram;
  parameter max_n_rw = max_n_writes > max_n_reads ? max_n_writes : max_n_reads;
  wire  [(PORTSIZE_in2*BITSIZE_in2)-1:0] tmp_addr;
  wire [PORTSIZE_sel_LOAD-1:0] int_sel_LOAD;
  wire [PORTSIZE_sel_STORE-1:0] int_sel_STORE;
  assign int_sel_LOAD = sel_LOAD & in4;
  assign int_sel_STORE = sel_STORE & in4;
  assign tmp_addr = in2;
  generate
  genvar i;
    for (i=0; i<max_n_rw; i=i+1)
    begin : L0
      assign Mout_addr_ram[(i+1)*BITSIZE_Mout_addr_ram-1:i*BITSIZE_Mout_addr_ram] = ((i < PORTSIZE_sel_LOAD && int_sel_LOAD[i]) || (i < PORTSIZE_sel_STORE && int_sel_STORE[i])) ? (tmp_addr[(i+1)*BITSIZE_in2-1:i*BITSIZE_in2]) : Min_addr_ram[(i+1)*BITSIZE_Min_addr_ram-1:i*BITSIZE_Min_addr_ram];
    end
    endgenerate
  assign Mout_oe_ram = int_sel_LOAD | Min_oe_ram;
  assign Mout_we_ram = int_sel_STORE | Min_we_ram;
  generate
    for (i=0; i<max_n_reads; i=i+1)
    begin : L1
      assign out1[(i+1)*BITSIZE_out1-1:i*BITSIZE_out1] = M_Rdata_ram[i*BITSIZE_M_Rdata_ram+BITSIZE_out1-1:i*BITSIZE_M_Rdata_ram];
  end
  endgenerate
  generate
    for (i=0; i<max_n_rw; i=i+1)
    begin : L2
      assign Mout_Wdata_ram[(i+1)*BITSIZE_Mout_Wdata_ram-1:i*BITSIZE_Mout_Wdata_ram] = int_sel_STORE[i] ? in1[(i+1)*BITSIZE_in1-1:i*BITSIZE_in1] : Min_Wdata_ram[(i+1)*BITSIZE_Min_Wdata_ram-1:i*BITSIZE_Min_Wdata_ram];
  end
  endgenerate
  generate
    for (i=0; i<max_n_rw; i=i+1)
    begin : L3
      assign Mout_data_ram_size[(i+1)*BITSIZE_Mout_data_ram_size-1:i*BITSIZE_Mout_data_ram_size] = ((i < PORTSIZE_sel_LOAD && int_sel_LOAD[i]) || (i < PORTSIZE_sel_STORE && int_sel_STORE[i])) ? (in3[(i+1)*BITSIZE_in3-1:i*BITSIZE_in3]) : Min_data_ram_size[(i+1)*BITSIZE_Min_data_ram_size-1:i*BITSIZE_Min_data_ram_size];
    end
    endgenerate

endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _add_node_FU_DEFINED
`define _add_node_FU_DEFINED
`timescale 1ns / 1ps
module add_node_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input signed [BITSIZE_in1-1:0] in1;
  input signed [BITSIZE_in2-1:0] in2;
  // OUT
  output signed [BITSIZE_out1-1:0] out1;
  assign out1 = in1 + in2;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _max_node_FU_DEFINED
`define _max_node_FU_DEFINED
`timescale 1ns / 1ps
module max_node_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input signed [BITSIZE_in1-1:0] in1;
  input signed [BITSIZE_in2-1:0] in2;
  // OUT
  output signed [BITSIZE_out1-1:0] out1;
  assign out1 = in1 > in2 ? in1 : in2;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _select_node_FU_DEFINED
`define _select_node_FU_DEFINED
`timescale 1ns / 1ps
module select_node_FU(in1,
  in2,
  in3,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_in3=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input signed [BITSIZE_in2-1:0] in2;
  input signed [BITSIZE_in3-1:0] in3;
  // OUT
  output signed [BITSIZE_out1-1:0] out1;
  assign out1 = in1 != 0 ? in2 : in3;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _shr_node_FU_DEFINED
`define _shr_node_FU_DEFINED
`timescale 1ns / 1ps
module shr_node_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1,
    PRECISION=1;
  // IN
  input signed [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output signed [BITSIZE_out1-1:0] out1;
  `ifndef _SIM_HAVE_CLOG2
    function integer log2;
       input integer value;
       integer temp_value;
      begin
        temp_value = value-1;
        for (log2=0; temp_value>0; log2=log2+1)
          temp_value = temp_value>>1;
      end
    endfunction
  `endif
  `ifdef _SIM_HAVE_CLOG2
    localparam arg2_bitsize = $clog2(PRECISION);
  `else
    localparam arg2_bitsize = log2(PRECISION);
  `endif
  generate
    if(BITSIZE_in2 > arg2_bitsize)
      assign out1 = in1 >>> (in2[arg2_bitsize-1:0]);
    else
      assign out1 = in1 >>> in2;
  endgenerate
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ui_add_node_FU_DEFINED
`define _ui_add_node_FU_DEFINED
`timescale 1ns / 1ps
module ui_add_node_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1 + in2;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ui_and_node_FU_DEFINED
`define _ui_and_node_FU_DEFINED
`timescale 1ns / 1ps
module ui_and_node_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1 & in2;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2016-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ui_concat_bit_node_FU_DEFINED
`define _ui_concat_bit_node_FU_DEFINED
`timescale 1ns / 1ps
module ui_concat_bit_node_FU(in1,
  in2,
  in3,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_in3=1,
    BITSIZE_out1=1,
    OFFSET_PARAMETER=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  input [BITSIZE_in3-1:0] in3;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  localparam nbit_out = BITSIZE_out1 > OFFSET_PARAMETER ? BITSIZE_out1 : 1+OFFSET_PARAMETER;
  wire [nbit_out-1:0] tmp_in1;
  wire [OFFSET_PARAMETER-1:0] tmp_in2;
  generate
    if(BITSIZE_in1 >= nbit_out)
      assign tmp_in1=in1[nbit_out-1:0];
    else
      assign tmp_in1={{(nbit_out-BITSIZE_in1){1'b0}},in1};
  endgenerate
  generate
    if(BITSIZE_in2 >= OFFSET_PARAMETER)
      assign tmp_in2=in2[OFFSET_PARAMETER-1:0];
    else
      assign tmp_in2={{(OFFSET_PARAMETER-BITSIZE_in2){1'b0}},in2};
  endgenerate
  assign out1 = {tmp_in1[nbit_out-1:OFFSET_PARAMETER] , tmp_in2};
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ui_eq_node_FU_DEFINED
`define _ui_eq_node_FU_DEFINED
`timescale 1ns / 1ps
module ui_eq_node_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1 == in2;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ui_gep_node_FU_DEFINED
`define _ui_gep_node_FU_DEFINED
`timescale 1ns / 1ps
module ui_gep_node_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1,
    LSB_PARAMETER=-1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  wire [BITSIZE_out1-1:0] in1_tmp;
  wire [BITSIZE_out1-1:0] in2_tmp;
  assign in1_tmp = in1;
  assign in2_tmp = in2;generate if (BITSIZE_out1 > LSB_PARAMETER) assign out1[BITSIZE_out1-1:LSB_PARAMETER] = (in1_tmp[BITSIZE_out1-1:LSB_PARAMETER] + in2_tmp[BITSIZE_out1-1:LSB_PARAMETER]); else assign out1 = 0; endgenerate
  generate if (LSB_PARAMETER != 0 && BITSIZE_out1 > LSB_PARAMETER) assign out1[LSB_PARAMETER-1:0] = 0; endgenerate
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ui_lt_node_FU_DEFINED
`define _ui_lt_node_FU_DEFINED
`timescale 1ns / 1ps
module ui_lt_node_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1 < in2;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ui_mul_node_FU_DEFINED
`define _ui_mul_node_FU_DEFINED
`timescale 1ns / 1ps
module ui_mul_node_FU(clock,
  in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1,
    PIPE_PARAMETER=0;
  // IN
  input clock;
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  
  generate
    if(PIPE_PARAMETER==1)
    begin
      reg [BITSIZE_out1-1:0] out1_reg;
      assign out1 = out1_reg;
      always @(posedge clock)
      begin
        out1_reg <= in1 * in2;
      end
    end
    else if(PIPE_PARAMETER>1)
    begin
      reg [BITSIZE_in1-1:0] in1_in;
      reg [BITSIZE_in2-1:0] in2_in;
      wire [BITSIZE_out1-1:0] mult_res;
      reg [BITSIZE_out1-1:0] mul [PIPE_PARAMETER-2:0];
      integer i;
      assign mult_res = in1_in * in2_in;
      always @(posedge clock)
      begin
        in1_in <= in1;
        in2_in <= in2;
        mul[PIPE_PARAMETER-2] <= mult_res;
        for (i=0; i<PIPE_PARAMETER-2; i=i+1)
          mul[i] <= mul[i+1];
      end
      assign out1 = mul[0];
    end
    else
    begin
      assign out1 = in1 * in2;
    end
  endgenerate

endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ui_or_node_FU_DEFINED
`define _ui_or_node_FU_DEFINED
`timescale 1ns / 1ps
module ui_or_node_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1 | in2;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ui_select_node_FU_DEFINED
`define _ui_select_node_FU_DEFINED
`timescale 1ns / 1ps
module ui_select_node_FU(in1,
  in2,
  in3,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_in3=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  input [BITSIZE_in3-1:0] in3;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1 != 0 ? in2 : in3;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ui_shl_node_FU_DEFINED
`define _ui_shl_node_FU_DEFINED
`timescale 1ns / 1ps
module ui_shl_node_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1,
    PRECISION=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  `ifndef _SIM_HAVE_CLOG2
    function integer log2;
       input integer value;
       integer temp_value;
      begin
        temp_value = value-1;
        for (log2=0; temp_value>0; log2=log2+1)
          temp_value = temp_value>>1;
      end
    endfunction
  `endif
  `ifdef _SIM_HAVE_CLOG2
    localparam arg2_bitsize = $clog2(PRECISION);
  `else
    localparam arg2_bitsize = log2(PRECISION);
  `endif
  generate
    if(BITSIZE_in2 > arg2_bitsize)
      assign out1 = in1 << in2[arg2_bitsize-1:0];
    else
      assign out1 = in1 << in2;
  endgenerate
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ui_shr_node_FU_DEFINED
`define _ui_shr_node_FU_DEFINED
`timescale 1ns / 1ps
module ui_shr_node_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1,
    PRECISION=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  `ifndef _SIM_HAVE_CLOG2
    function integer log2;
       input integer value;
       integer temp_value;
      begin
        temp_value = value-1;
        for (log2=0; temp_value>0; log2=log2+1)
          temp_value = temp_value>>1;
      end
    endfunction
  `endif
  `ifdef _SIM_HAVE_CLOG2
    localparam arg2_bitsize = $clog2(PRECISION);
  `else
    localparam arg2_bitsize = log2(PRECISION);
  `endif
  generate
    if(BITSIZE_in2 > arg2_bitsize)
      assign out1 = in1 >> (in2[arg2_bitsize-1:0]);
    else
      assign out1 = in1 >> in2;
  endgenerate

endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _ui_ternary_add_node_FU_DEFINED
`define _ui_ternary_add_node_FU_DEFINED
`timescale 1ns / 1ps
module ui_ternary_add_node_FU(in1,
  in2,
  in3,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_in3=1,
    BITSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  input [BITSIZE_in3-1:0] in3;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1 + in2 + in3;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2013-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _SPROXY_CTRLN_DEFINED
`define _SPROXY_CTRLN_DEFINED
`timescale 1ns / 1ps
module SPROXY_CTRLN(in1,
  in2r,
  in2w,
  in3r,
  in3w,
  in4r,
  in4w,
  sel_LOAD,
  sel_STORE,
  out1,
  proxy_in1,
  proxy_in2r,
  proxy_in2w,
  proxy_in3r,
  proxy_in3w,
  proxy_in4r,
  proxy_in4w,
  proxy_sel_LOAD,
  proxy_sel_STORE,
  proxy_out1);
  parameter BITSIZE_in1=1, PORTSIZE_in1=1,
    BITSIZE_in2r=1, PORTSIZE_in2r=1,
    BITSIZE_in2w=1, PORTSIZE_in2w=1,
    BITSIZE_in3r=1, PORTSIZE_in3r=1,
    BITSIZE_in3w=1, PORTSIZE_in3w=1,
    BITSIZE_in4r=1, PORTSIZE_in4r=1,
    BITSIZE_in4w=1, PORTSIZE_in4w=1,
    BITSIZE_sel_LOAD=1, PORTSIZE_sel_LOAD=1,
    BITSIZE_sel_STORE=1, PORTSIZE_sel_STORE=1,
    BITSIZE_out1=1, PORTSIZE_out1=1,
    BITSIZE_proxy_in1=1, PORTSIZE_proxy_in1=1,
    BITSIZE_proxy_in2r=1, PORTSIZE_proxy_in2r=1,
    BITSIZE_proxy_in2w=1, PORTSIZE_proxy_in2w=1,
    BITSIZE_proxy_in3r=1, PORTSIZE_proxy_in3r=1,
    BITSIZE_proxy_in3w=1, PORTSIZE_proxy_in3w=1,
    BITSIZE_proxy_in4r=1, PORTSIZE_proxy_in4r=1,
    BITSIZE_proxy_in4w=1, PORTSIZE_proxy_in4w=1,
    BITSIZE_proxy_sel_LOAD=1, PORTSIZE_proxy_sel_LOAD=1,
    BITSIZE_proxy_sel_STORE=1, PORTSIZE_proxy_sel_STORE=1,
    BITSIZE_proxy_out1=1, PORTSIZE_proxy_out1=1;
  // IN
  input [(PORTSIZE_in1*BITSIZE_in1)+(-1):0] in1;
  input [(PORTSIZE_in2r*BITSIZE_in2r)+(-1):0] in2r;
  input [(PORTSIZE_in2w*BITSIZE_in2w)+(-1):0] in2w;
  input [(PORTSIZE_in3r*BITSIZE_in3r)+(-1):0] in3r;
  input [(PORTSIZE_in3w*BITSIZE_in3w)+(-1):0] in3w;
  input [PORTSIZE_in4r-1:0] in4r;
  input [PORTSIZE_in4w-1:0] in4w;
  input [PORTSIZE_sel_LOAD-1:0] sel_LOAD;
  input [PORTSIZE_sel_STORE-1:0] sel_STORE;
  input [(PORTSIZE_proxy_out1*BITSIZE_proxy_out1)+(-1):0] proxy_out1;
  // OUT
  output [(PORTSIZE_out1*BITSIZE_out1)+(-1):0] out1;
  output [(PORTSIZE_proxy_in1*BITSIZE_proxy_in1)+(-1):0] proxy_in1;
  output [(PORTSIZE_proxy_in2r*BITSIZE_proxy_in2r)+(-1):0] proxy_in2r;
  output [(PORTSIZE_proxy_in2w*BITSIZE_proxy_in2w)+(-1):0] proxy_in2w;
  output [(PORTSIZE_proxy_in3r*BITSIZE_proxy_in3r)+(-1):0] proxy_in3r;
  output [(PORTSIZE_proxy_in3w*BITSIZE_proxy_in3w)+(-1):0] proxy_in3w;
  output [PORTSIZE_proxy_in4r-1:0] proxy_in4r;
  output [PORTSIZE_proxy_in4w-1:0] proxy_in4w;
  output [PORTSIZE_proxy_sel_LOAD-1:0] proxy_sel_LOAD;
  output [PORTSIZE_proxy_sel_STORE-1:0] proxy_sel_STORE;
  
  wire [PORTSIZE_sel_LOAD-1:0] int_sel_LOAD;
  wire [PORTSIZE_sel_STORE-1:0] int_sel_STORE;
  assign int_sel_LOAD = sel_LOAD & in4r;
  assign int_sel_STORE = sel_STORE & in4w;
  generate
  genvar i0;
  for (i0=0; i0<PORTSIZE_out1; i0=i0+1)
    begin : L0
      assign out1[(i0+1)*BITSIZE_out1-1:i0*BITSIZE_out1] = proxy_out1[(i0+1)*BITSIZE_proxy_out1-1:i0*BITSIZE_proxy_out1];
    end
  endgenerate
  generate
  genvar i1;
  for (i1=0; i1<PORTSIZE_in1; i1=i1+1)
    begin : L1
      assign proxy_in1[(i1+1)*BITSIZE_proxy_in1-1:i1*BITSIZE_proxy_in1] = int_sel_STORE[i1] ? in1[(i1+1)*BITSIZE_in1-1:i1*BITSIZE_in1] : 0;
    end
  endgenerate
  generate
  genvar i2r;
  for (i2r=0; i2r<PORTSIZE_in2r; i2r=i2r+1)
    begin : L2r
      assign proxy_in2r[(i2r+1)*BITSIZE_proxy_in2r-1:i2r*BITSIZE_proxy_in2r] = int_sel_LOAD[i2r] ? in2r[(i2r+1)*BITSIZE_in2r-1:i2r*BITSIZE_in2r] : 0;
    end
  endgenerate
  
  generate
  genvar i2w;
  for (i2w=0; i2w<PORTSIZE_in2w; i2w=i2w+1)
    begin : L2w
      assign proxy_in2w[(i2w+1)*BITSIZE_proxy_in2w-1:i2w*BITSIZE_proxy_in2w] = int_sel_STORE[i2w] ? in2w[(i2w+1)*BITSIZE_in2w-1:i2w*BITSIZE_in2w] : 0;
    end
  endgenerate
  
  generate
  genvar i3r;
  for (i3r=0; i3r<PORTSIZE_in3r; i3r=i3r+1)
    begin : L3r
      assign proxy_in3r[(i3r+1)*BITSIZE_proxy_in3r-1:i3r*BITSIZE_proxy_in3r] = int_sel_LOAD[i3r] ? in3r[(i3r+1)*BITSIZE_in3r-1:i3r*BITSIZE_in3r] : 0;
    end
  endgenerate
  
  generate
  genvar i3w;
  for (i3w=0; i3w<PORTSIZE_in3w; i3w=i3w+1)
    begin : L3w
      assign proxy_in3w[(i3w+1)*BITSIZE_proxy_in3w-1:i3w*BITSIZE_proxy_in3w] = int_sel_STORE[i3w] ? in3w[(i3w+1)*BITSIZE_in3w-1:i3w*BITSIZE_in3w] : 0;
    end
  endgenerate
  
  assign proxy_in4r = int_sel_LOAD;
  assign proxy_in4w = int_sel_STORE;
  assign proxy_sel_LOAD = int_sel_LOAD;
  assign proxy_sel_STORE = int_sel_STORE;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _gt_node_FU_DEFINED
`define _gt_node_FU_DEFINED
`timescale 1ns / 1ps
module gt_node_FU(in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input signed [BITSIZE_in1-1:0] in1;
  input signed [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  assign out1 = in1 > in2;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2024-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _MUX2_GATE_DEFINED
`define _MUX2_GATE_DEFINED
`timescale 1ns / 1ps
module MUX2_GATE(sel,
  in1,
  in2,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_in2=1,
    BITSIZE_out1=1;
  // IN
  input sel;
  input [BITSIZE_in1-1:0] in1;
  input [BITSIZE_in2-1:0] in2;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  
  reg [BITSIZE_out1-1:0] out1;
  always @(*)
  begin
    if (sel == 1'b0)
    begin
      out1 = in2;
    end
    else
    begin
      out1 = in1;
    end
  end

endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _register_AR_DEFINED
`define _register_AR_DEFINED
`timescale 1ns / 1ps
module register_AR(clock,
  reset,
  in1,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input clock;
  input reset;
  input [BITSIZE_in1-1:0] in1;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  
  reg [BITSIZE_out1-1:0] reg_out1 =0;
  assign out1 = reg_out1;
  always @(posedge clock or negedge reset)
    if (reset == 1'b0)
      reg_out1 <= {BITSIZE_out1{1'b0}};
    else
      reg_out1 <= in1;
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2013-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _bus_merger_DEFINED
`define _bus_merger_DEFINED
`timescale 1ns / 1ps
module bus_merger(in1,
  out1);
  parameter BITSIZE_in1=1, PORTSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input [(PORTSIZE_in1*BITSIZE_in1)+(-1):0] in1;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  
  function [BITSIZE_out1-1:0] merge;
    input [BITSIZE_in1*PORTSIZE_in1-1:0] m;
    reg [BITSIZE_out1-1:0] res;
    integer i1;
  begin
    res={BITSIZE_in1{1'b0}};
    for(i1 = 0; i1 < PORTSIZE_in1; i1 = i1 + 1)
    begin
      res = res | m[i1*BITSIZE_in1 +:BITSIZE_in1];
    end
    merge = res;
  end
  endfunction
  
  assign out1 = merge(in1);
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _join_signal_DEFINED
`define _join_signal_DEFINED
`timescale 1ns / 1ps
module join_signal(in1,
  out1);
  parameter BITSIZE_in1=1, PORTSIZE_in1=1,
    BITSIZE_out1=1;
  // IN
  input [(PORTSIZE_in1*BITSIZE_in1)+(-1):0] in1;
  // OUT
  output [BITSIZE_out1-1:0] out1;
  
  generate
  genvar i1;
  for (i1=0; i1<PORTSIZE_in1; i1=i1+1)
    begin : L1
      assign out1[(i1+1)*(BITSIZE_out1/PORTSIZE_in1)-1:i1*(BITSIZE_out1/PORTSIZE_in1)] = in1[(i1+1)*BITSIZE_in1-1:i1*BITSIZE_in1];
    end
  endgenerate
endmodule
`endif

// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2004-2025 Politecnico di Milano
// Author(s): Fabrizio Ferrandi <fabrizio.ferrandi@polimi.it>
// License: PANDA_LGPLv3
`ifndef _split_signal_DEFINED
`define _split_signal_DEFINED
`timescale 1ns / 1ps
module split_signal(in1,
  out1);
  parameter BITSIZE_in1=1,
    BITSIZE_out1=1, PORTSIZE_out1=1;
  // IN
  input [BITSIZE_in1-1:0] in1;
  // OUT
  output [(PORTSIZE_out1*BITSIZE_out1)+(-1):0] out1;
  assign out1 = in1;
endmodule
`endif


