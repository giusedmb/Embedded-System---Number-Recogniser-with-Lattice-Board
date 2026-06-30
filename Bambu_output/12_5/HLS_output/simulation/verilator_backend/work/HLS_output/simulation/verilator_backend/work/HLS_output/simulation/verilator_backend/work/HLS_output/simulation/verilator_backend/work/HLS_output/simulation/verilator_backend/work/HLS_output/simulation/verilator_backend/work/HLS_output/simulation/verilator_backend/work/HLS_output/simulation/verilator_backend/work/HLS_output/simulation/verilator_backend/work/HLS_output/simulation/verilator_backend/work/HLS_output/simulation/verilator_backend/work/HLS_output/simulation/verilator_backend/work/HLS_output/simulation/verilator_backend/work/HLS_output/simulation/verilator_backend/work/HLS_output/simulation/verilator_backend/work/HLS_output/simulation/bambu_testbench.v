// verilator lint_off BLKANDNBLK
// verilator lint_off BLKSEQ

`timescale 1ns / 1ps
// CONSTANTS DECLARATION
`define MAX_COMMENT_LENGTH 1000
`define INIT_TIME 100


`ifdef __M64
typedef longint unsigned ptr_t;
`else
typedef int unsigned ptr_t;
`endif

// 
// Politecnico di Milano
// Code created using PandA - Version: PandA 2025.07 - Revision 2be902d264e7996b4fbc47153a26c8dba6e25ec0-feature/CSROA-and-predication - Date 2026-06-20T17:33:19
// Bambu executed with: 'bambu' '--top-fname=myproject' '-I' 'firmware/ac_types' '--generate-interface=INFER' '--clock-period=40' '--bambu-parameter=inline-max-cost=0' '--simulate' '--generate-tb=myproject_test.cpp' '--verbosity=4' 'firmware/myproject.cpp'
// 
// Send any bug to: panda-info@polimi.it

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
// Copyright (C) 2023-2025 Politecnico di Milano
// Author(s): Michele Fiorito <michele.fiorito@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module TestbenchDUT(clock,
  reset,
  start_port,
  conv1_input_q0,
  conv1_input_q1,
  done_port,
  conv1_input_address0,
  conv1_input_address1,
  conv1_input_ce0,
  conv1_input_ce1,
  layer13_out_address0,
  layer13_out_address1,
  layer13_out_ce0,
  layer13_out_ce1,
  layer13_out_we0,
  layer13_out_we1,
  layer13_out_d0,
  layer13_out_d1);
  // IN
  input clock;
  input reset;
  input start_port;
  input [11:0] conv1_input_q0;
  input [11:0] conv1_input_q1;
  // OUT
  output done_port;
  output [12:0] conv1_input_address0;
  output [12:0] conv1_input_address1;
  output conv1_input_ce0;
  output conv1_input_ce1;
  output [5:0] layer13_out_address0;
  output [5:0] layer13_out_address1;
  output layer13_out_ce0;
  output layer13_out_ce1;
  output layer13_out_we0;
  output layer13_out_we1;
  output [11:0] layer13_out_d0;
  output [11:0] layer13_out_d1;
  
  
  p_Z9myprojectP8ac_fixedILi12ELi5ELb1EL9ac_q_mode0EL9ac_o_mode0EES3_s top(
    .clock(clock),
    .reset(reset),
    .start_port(start_port),
    .conv1_input_q0(conv1_input_q0),
    .conv1_input_q1(conv1_input_q1),
    .done_port(done_port),
    .conv1_input_address0(conv1_input_address0),
    .conv1_input_address1(conv1_input_address1),
    .conv1_input_ce0(conv1_input_ce0),
    .conv1_input_ce1(conv1_input_ce1),
    .layer13_out_address0(layer13_out_address0),
    .layer13_out_address1(layer13_out_address1),
    .layer13_out_ce0(layer13_out_ce0),
    .layer13_out_ce1(layer13_out_ce1),
    .layer13_out_we0(layer13_out_we0),
    .layer13_out_we1(layer13_out_we1),
    .layer13_out_d0(layer13_out_d0),
    .layer13_out_d1(layer13_out_d1));

endmodule


// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2023-2025 Politecnico di Milano
// Author(s): Michele Fiorito <michele.fiorito@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module TestbenchFSM(clock,
  done_port,
  reset,
  setup_port,
  start_port);
  parameter RESFILE="results.txt",
    RESET_ACTIVE=0,
    RESET_CYCLES=1,
    RESET_ALWAYS=0,
    CLOCK_PERIOD=2.0,
    MAX_SIM_CYCLES=200000000;
  // IN
  input clock;
  input done_port;
  // OUT
  output reset;
  output setup_port;
  output start_port;
  `ifdef VERILATOR
  timeunit 1ps;
  timeprecision 1ps;
  `endif
  
  import "DPI-C" function int unsigned m_next(input int unsigned state);
  import "DPI-C" function int m_fini();
  
  localparam [6:0] 
    STATE_READY   =7'b0000001,
    STATE_SETUP   =7'b0000010,
    STATE_RUNNING =7'b0000100,
    STATE_END     =7'b0001000,
    STATE_ERROR   =7'b0010000,
    STATE_ABORT   =7'b0100000,
    SIM_DONE      =7'b1000000;
  reg [$bits(STATE_READY)-1:0] state, state_next, state_succ, state_succ_next;
  
  reg rst, rst_next, setup, setup_next, start, start_next;
  integer rst_count, rst_count_next;
  time over_time;
  
  initial
  begin
    // Open file results will be written
    automatic integer res_file;
    res_file = $fopen(RESFILE, "w");
    if (res_file == 0)
    begin
      $display("ERROR - Error opening the res_file");
      $finish;// Terminate
    end
    $fwrite(res_file, "");
    $fclose(res_file);
    
    state = STATE_READY;
    state_next = STATE_READY;
    state_succ = STATE_READY;
    state_succ_next = STATE_READY;
    rst = RESET_ACTIVE;
    rst_next = RESET_ACTIVE;
    rst_count = RESET_CYCLES;
    rst_count_next = RESET_CYCLES;
    setup = 0;
    setup_next = 0;
    start = 0;
    start_next = 0;
    over_time = 0;
    
    $display("Results file: %s", RESFILE);
    $display("Reset active: %0s", RESET_ACTIVE ? "HIGH" : "LOW");
  end
  
  assign reset = rst;
  assign setup_port = setup;
  assign start_port = start;
  
  always @(posedge clock)
  begin
    state <= state_next;
    state_succ <= state_succ_next;
    rst <= rst_next;
    rst_count <= rst_count_next;
    setup <= setup_next;
    start <= start_next;
    case(state_next)
    STATE_READY:
      begin
        automatic integer unsigned next_state = m_next(STATE_READY);
        `ifndef NDEBUG
        $display("Sim: next state: %0d (retval: %0d)", next_state[$bits(state_succ)-1:0], next_state[15:8]);
        `endif
        state_succ <= next_state[$bits(state_succ)-1:0];
      end
    STATE_SETUP:
      begin
        automatic time start_time = $time + CLOCK_PERIOD;
        automatic time start_cycle = $rtoi($itor(start_time)/CLOCK_PERIOD);
        automatic integer res_file;
        if(setup_next)
        begin
          res_file = $fopen(RESFILE, "a");
          $fwrite(res_file, "%0d|", start_time);
          $fclose(res_file);
          `ifndef NDEBUG
          $display("Sim: Argument setup\nSim: Simulation started at cycle %0d", start_cycle);
          `endif
        end
        over_time <= start_cycle + MAX_SIM_CYCLES;
      end
    STATE_RUNNING:
      begin
        automatic time curr_cycle = $rtoi($itor($time)/CLOCK_PERIOD);
        if(curr_cycle >= over_time)
        begin
          automatic integer res_file;
          res_file = $fopen(RESFILE, "a");
          $fwrite(res_file, "X");
          $fclose(res_file);
          $display("Sim: Simulation exceeds %0d cycles", MAX_SIM_CYCLES);
          $finish;
        end
      end
    SIM_DONE:
      begin
        automatic time curr_time = $time;
        automatic time curr_cycle = $rtoi($itor(curr_time)/CLOCK_PERIOD);
        automatic integer res_file;
        res_file = $fopen(RESFILE, "a");
        $fwrite(res_file, "%0d,", curr_time);
        $fclose(res_file);
        `ifndef NDEBUG
        $display("Sim: DUT port writeback\nSim: Simulation ended at cycle %0d", curr_cycle);
        `endif
      end
    STATE_END:
      begin
        automatic integer r = m_fini();
        automatic integer res_file;
        res_file = $fopen(RESFILE, "a");
        $fwrite(res_file, "\n%0d\n", r[15:8]);
        $fclose(res_file);
        $display("Sim: Driver terminated with code: %0d", r[15:8]);
        $finish;
      end
    STATE_ABORT:
      begin
        automatic integer r = m_fini();
        automatic integer res_file;
        res_file = $fopen(RESFILE, "a");
        $fwrite(res_file, "\nA\n");
        $fclose(res_file);
        $display("Sim: Driver aborted");
        $finish;
      end
    default:
      begin
      end
    endcase
  end
  
  always @(*)
  begin
    rst_next = rst;
    rst_count_next = rst_count;
    setup_next = setup;
    start_next = start;
    state_next = state;
    state_succ_next = state_succ;
    case(state)
    STATE_READY:
      begin
        state_next = state_succ;
        if(state_succ == STATE_SETUP)
        begin
          if(RESET_ALWAYS || rst_count > 0)
          begin
            rst_next = RESET_ACTIVE;
            rst_count_next = RESET_CYCLES;
          end
          else
          begin
            rst_count_next = 1;
          end
        end
      end
    STATE_SETUP:
      begin
        if(rst_count > 1)
        begin
          setup_next = rst_count == 0;
          rst_next = RESET_ACTIVE;
          rst_count_next = rst_count - 1;
        end
        else if(rst_count == 1)
        begin
          setup_next = 1;
          rst_next = ~RESET_ACTIVE;
          rst_count_next = 0;
        end
        else
        begin
          state_next = STATE_RUNNING;
          setup_next = 0;
          start_next = 1;
        end
      end
    STATE_RUNNING:
      begin
        start_next = 0;
        if(done_port)
        begin
          state_next = SIM_DONE;
        end
      end
    SIM_DONE:
      begin
        // A clock cycle must pass to allow interface modules 
        // finalization operations
        state_next = STATE_READY;
      end
    STATE_END:
      begin
      end
    STATE_ABORT:
      begin
      end
    default:
      begin
        state_next = STATE_READY;
      end
    endcase
  end
endmodule


// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2023-2025 Politecnico di Milano
// Author(s): Michele Fiorito <michele.fiorito@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module if_utils();
  parameter ID=0,
    BITSIZE_data=32;
  
  import "DPI-C" function int m_read (input shortint unsigned id, output logic [4095:0] data, input shortint unsigned bitsize, input ptr_t addr, input byte signed cmd);
  import "DPI-C" function int m_write (input shortint unsigned id, input logic [4095:0] data, input shortint unsigned bitsize, input ptr_t addr, input byte signed cmd);
  import "DPI-C" function int m_state (input shortint unsigned id, input int data);
  
  function automatic integer log2;
    input integer value;
    `ifdef _SIM_HAVE_CLOG2
      log2 = $clog2(value);
    `else
      automatic integer temp_value = value-1;
      for (log2=0; temp_value > 0; log2=log2+1)
        temp_value = temp_value >> 1;
    `endif
  endfunction
  
  localparam BITSIZE_strobe=log2(BITSIZE_data) > 3 ? (1<<(log2(BITSIZE_data)-3)) : 1;
  
  function automatic [BITSIZE_data-1:0] read();
    automatic reg [4095:0] _data = 0;
    void'(m_read(ID, _data, BITSIZE_data, 0, 0));
    return _data[BITSIZE_data-1:0];
  endfunction
  
  function automatic [BITSIZE_data-1:0] read_a(input ptr_t addr);
    automatic reg [4095:0] _data = 0;
    void'(m_read(ID, _data, BITSIZE_data, addr, 0));
    return _data[BITSIZE_data-1:0];
  endfunction
  
  function automatic [BITSIZE_data-1:0] read_i(output int info);
    automatic reg [4095:0] _data = 0;
    info = m_read(ID, _data, BITSIZE_data, 0, 0);
    return _data[BITSIZE_data-1:0];
  endfunction
  
  function automatic [BITSIZE_data-1:0] read_ai(input ptr_t addr, output int info);
    automatic reg [4095:0] _data = 0;
    info = m_read(ID, _data, BITSIZE_data, addr, 0);
    return _data[BITSIZE_data-1:0];
  endfunction
  
  function automatic [BITSIZE_data-1:0] pop(output int info);
    automatic reg [4095:0] _data = 0;
    info = m_read(ID, _data, BITSIZE_data, 0, 1);
    return _data[BITSIZE_data-1:0];
  endfunction
  
  function automatic int write(input logic [BITSIZE_data-1:0] data);
    automatic reg [4095:0] _data = 0;
    _data[BITSIZE_data-1:0] = data;
    return m_write(ID, _data, BITSIZE_data, 0, 0);
  endfunction
  
  function automatic int write_a(input logic [BITSIZE_data-1:0] data, input ptr_t addr);
    automatic reg [4095:0] _data = 0;
    _data[BITSIZE_data-1:0] = data;
    return m_write(ID, _data, BITSIZE_data, addr, 0);
  endfunction
  
  function automatic int write_sa(input logic [BITSIZE_data-1:0] data, input shortint unsigned bitsize, input ptr_t addr);
    automatic reg [4095:0] _data = 0;
    _data[BITSIZE_data-1:0] = data;
    return m_write(ID, _data, bitsize, addr, 0);
  endfunction
  
  function automatic int write_strobe(input logic [BITSIZE_data-1:0] data, input logic [BITSIZE_strobe-1:0] strobe, input ptr_t addr);
    automatic shortint unsigned size = 0;
    
    while(strobe != 0 && !strobe[0])
    begin
      addr = addr + 1;
      strobe = strobe >> 1;
    end
    while(strobe[0])
    begin
      size = size + 8;
      strobe = strobe >> 1;
    end
    if(strobe != 0)
    begin
      $display("Scattered strobe write operations not supported");
      $finish;
    end
  
    return write_sa(data, size, addr);
  endfunction
  
  function automatic int push(input logic [BITSIZE_data-1:0] data);
    automatic reg [4095:0] _data = 0;
    _data[BITSIZE_data-1:0] = data;
    return m_write(ID, _data, BITSIZE_data, 0, -1);
  endfunction
  
  function automatic int state(input int data);
    return m_state(ID, data);
  endfunction
endmodule


// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2023-2025 Politecnico di Milano
// Author(s): Michele Fiorito <michele.fiorito@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module TestbenchMEMMinimal(clock,
  reset,
  done_port,
  M_DataRdy,
  M_Rdata_ram,
  M_back_pressure,
  M_tag,
  Mout_oe_ram,
  Mout_we_ram,
  Mout_addr_ram,
  Mout_data_ram_size,
  Mout_Wdata_ram,
  Mout_back_pressure,
  Mout_tag,
  Sout_DataRdy,
  Sout_Rdata_ram,
  S_oe_ram,
  S_we_ram,
  S_addr_ram,
  S_data_ram_size,
  S_Wdata_ram);
  parameter index=0,
    MEM_DELAY_READ=2,
    MEM_DELAY_WRITE=1,
    EMULATE_BRAM=0,
    base_addr=1073741824,
    MEM_DUMP=0,
    MEM_DUMP_FILE="memdump.csv",
    QUEUE_SIZE=4,
    BITSIZE_M_DataRdy=1,
    BITSIZE_M_Rdata_ram=8,
    BITSIZE_M_back_pressure=1,
    BITSIZE_M_tag=1,
    BITSIZE_Mout_oe_ram=1,
    BITSIZE_Mout_we_ram=1,
    BITSIZE_Mout_addr_ram=1,
    BITSIZE_Mout_data_ram_size=4,
    BITSIZE_Mout_Wdata_ram=8,
    BITSIZE_Mout_back_pressure=1,
    BITSIZE_Mout_tag=1,
    BITSIZE_Sout_DataRdy=1,
    BITSIZE_Sout_Rdata_ram=8,
    BITSIZE_S_oe_ram=1,
    BITSIZE_S_we_ram=1,
    BITSIZE_S_addr_ram=1,
    BITSIZE_S_data_ram_size=4,
    BITSIZE_S_Wdata_ram=8;
  // IN
  input clock;
  input reset;
  input done_port;
  input [BITSIZE_M_back_pressure-1:0] M_back_pressure;
  input [BITSIZE_Mout_oe_ram-1:0] Mout_oe_ram;
  input [BITSIZE_Mout_we_ram-1:0] Mout_we_ram;
  input [BITSIZE_Mout_addr_ram-1:0] Mout_addr_ram;
  input [BITSIZE_Mout_data_ram_size-1:0] Mout_data_ram_size;
  input [BITSIZE_Mout_Wdata_ram-1:0] Mout_Wdata_ram;
  input [BITSIZE_Mout_tag-1:0] Mout_tag;
  input [BITSIZE_Sout_DataRdy-1:0] Sout_DataRdy;
  input [BITSIZE_Sout_Rdata_ram-1:0] Sout_Rdata_ram;
  // OUT
  output [BITSIZE_M_DataRdy-1:0] M_DataRdy;
  output [BITSIZE_M_Rdata_ram-1:0] M_Rdata_ram;
  output [BITSIZE_M_tag-1:0] M_tag;
  output [BITSIZE_Mout_back_pressure-1:0] Mout_back_pressure;
  output [BITSIZE_S_oe_ram-1:0] S_oe_ram;
  output [BITSIZE_S_we_ram-1:0] S_we_ram;
  output [BITSIZE_S_addr_ram-1:0] S_addr_ram;
  output [BITSIZE_S_data_ram_size-1:0] S_data_ram_size;
  output [BITSIZE_S_Wdata_ram-1:0] S_Wdata_ram;
  
  function automatic integer log2;
    input integer value;
    `ifdef _SIM_HAVE_CLOG2
      log2 = $clog2(value);
    `else
      automatic integer temp_value = value-1;
      for (log2=0; temp_value > 0; log2=log2+1)
        temp_value = temp_value >> 1;
    `endif
  endfunction
  
  localparam MEM_DELAY_MAX= MEM_DELAY_READ > MEM_DELAY_WRITE ? MEM_DELAY_READ : MEM_DELAY_WRITE,
    ACTIVE_READ= MEM_DELAY_READ > 1 ? (MEM_DELAY_READ-2) : 0,
    ACTIVE_WRITE= MEM_DELAY_WRITE > 1 ? (MEM_DELAY_WRITE-2) : 0,
    CHANNELS_NUMBER=BITSIZE_Mout_oe_ram,
    BITSIZE_oe=1,
    BITSIZE_we=1,
    BITSIZE_addr=BITSIZE_Mout_addr_ram/CHANNELS_NUMBER,
    BITSIZE_Wsize=BITSIZE_Mout_data_ram_size/CHANNELS_NUMBER,
    BITSIZE_Wdata=BITSIZE_Mout_Wdata_ram/CHANNELS_NUMBER,
    BITSIZE_Rdata=BITSIZE_M_Rdata_ram/CHANNELS_NUMBER,
    BITSIZE_tag=BITSIZE_Mout_tag/CHANNELS_NUMBER,
    BITSIZE_item=BITSIZE_tag+BITSIZE_Wdata+BITSIZE_Wsize+BITSIZE_addr+BITSIZE_we+BITSIZE_oe,
    OFFSET_oe=0,
    OFFSET_we=OFFSET_oe+BITSIZE_oe,
    OFFSET_addr=OFFSET_we+BITSIZE_we,
    OFFSET_Wsize=OFFSET_addr+BITSIZE_addr,
    OFFSET_Wdata=OFFSET_Wsize+BITSIZE_Wsize,
    OFFSET_tag = OFFSET_Wdata+BITSIZE_Wdata,
    BITSIZE_S_Rdata=BITSIZE_Sout_Rdata_ram/BITSIZE_S_oe_ram,
    BITSIZE_S_ready=1,
    SLAVE_VALID=BITSIZE_Mout_oe_ram == BITSIZE_S_oe_ram,
    QUEUE_BITSIZE=QUEUE_SIZE > 1 ? log2(QUEUE_SIZE) : 1;
  
  genvar i;
  integer dump_file;
  wire [BITSIZE_M_Rdata_ram-1:0] _M_Rdata_ram;
  
  assign S_oe_ram = Mout_oe_ram;
  assign S_we_ram = Mout_we_ram;
  assign S_addr_ram = Mout_addr_ram;
  assign S_data_ram_size = Mout_data_ram_size;
  assign S_Wdata_ram = Mout_Wdata_ram;
  assign M_Rdata_ram = _M_Rdata_ram;
  
  generate
    if(MEM_DUMP)
    begin
      initial
      begin
        dump_file = $fopen(MEM_DUMP_FILE, "w");
        $fwrite(dump_file, "Channel,Operation,Address,Bitwidth,Data\n");
      end
  
      always@(posedge clock)
      begin
        if(done_port)
        begin
          $fflush(dump_file);
        end
      end
    end
  endgenerate
  
  if_utils #(index, BITSIZE_Rdata) m_utils();
  
  generate
    for(i = 0; i < CHANNELS_NUMBER; i = i + 1)
    begin : channel
      wire [BITSIZE_item-1:0] new_elem;
      reg [MEM_DELAY_MAX*BITSIZE_item-1:0] queue;
      wire [MEM_DELAY_MAX*BITSIZE_item-1:0] queue_next;
      wire [BITSIZE_oe-1:0] oe;
      wire [BITSIZE_we-1:0] we;
      ptr_t Waddr, Raddr;
      shortint unsigned Wsize;
      wire [BITSIZE_Wdata-1:0] Wdata;
      reg Wready, Rready;
      reg [BITSIZE_Rdata-1:0] Rdata;
  
      reg [QUEUE_BITSIZE-1:0] queue_counter;
      wire [QUEUE_BITSIZE-1:0] queue_counter_next;
  
      assign new_elem = Mout_back_pressure[i] ? {BITSIZE_item{1'b0}} : {Mout_tag[BITSIZE_tag*i+:BITSIZE_tag],Mout_Wdata_ram[BITSIZE_Wdata*i+:BITSIZE_Wdata],Mout_data_ram_size[BITSIZE_Wsize*i+:BITSIZE_Wsize],Mout_addr_ram[BITSIZE_addr*i+:BITSIZE_addr],Mout_we_ram[BITSIZE_we*i+:BITSIZE_we],Mout_oe_ram[BITSIZE_oe*i+:BITSIZE_oe]};
      assign queue_next = M_back_pressure[i] ? queue[MEM_DELAY_MAX*BITSIZE_item-1:0] : {queue[(MEM_DELAY_MAX-1)*BITSIZE_item-1:0],new_elem};
     
      always@(posedge clock)
      begin
        if(reset == 1'b0)
        begin
          queue <= 0;
        end
        else
        begin
          queue <= queue_next;
        end
      end
  
      assign oe = queue_next[ACTIVE_READ*BITSIZE_item+OFFSET_oe+:BITSIZE_oe];
      assign Raddr = queue_next[ACTIVE_READ*BITSIZE_item+OFFSET_addr+:BITSIZE_addr];
      assign _M_Rdata_ram[BITSIZE_Rdata*i+:BITSIZE_Rdata] = Rdata | (Sout_Rdata_ram[BITSIZE_S_Rdata*i*SLAVE_VALID+:BITSIZE_S_Rdata] & {BITSIZE_S_Rdata{Sout_DataRdy[BITSIZE_S_ready*i*SLAVE_VALID+:BITSIZE_S_ready] === 1'b1}});
  
      always@(posedge clock)
      begin : read_channel
        automatic reg [BITSIZE_Rdata-1:0] data;
        Rready <= 0;
        Rdata <= 0;
        if(oe && base_addr <= Raddr)
        begin
          data = m_utils.read_a(Raddr);
          Rdata <= data;
          Rready <= 1;
          if(MEM_DUMP)
          begin
            $fwrite(dump_file, "%0d,r,%0X,%0d,%0X\n", i, Raddr, BITSIZE_Rdata, data);
          end
        end
      end
  
      assign we = queue_next[ACTIVE_WRITE*BITSIZE_item+OFFSET_we+:BITSIZE_we];
      assign Waddr = queue_next[ACTIVE_WRITE*BITSIZE_item+OFFSET_addr+:BITSIZE_addr];
      assign Wsize = {{16-BITSIZE_Wsize{1'b0}}, queue_next[ACTIVE_WRITE*BITSIZE_item+OFFSET_Wsize+:BITSIZE_Wsize]};
      assign Wdata = queue_next[ACTIVE_WRITE*BITSIZE_item+OFFSET_Wdata+:BITSIZE_Wdata];
  
      always@(posedge clock)
      begin : write_channel
        Wready <= 0;
        if(we && base_addr <= Waddr)
        begin
          void'(m_utils.write_sa(Wdata, Wsize, Waddr));
          Wready <= 1;
          if(MEM_DUMP)
          begin
            $fwrite(dump_file, "%0d,w,%0X,%0d,%0X\n", i, Waddr, Wsize, Wdata);
          end
        end
      end
  
      if(EMULATE_BRAM)
      begin
        assign Mout_back_pressure[i] = 0; // No back pressure with BRAM
      end
      else
      begin
        wire _M_DataRdy, _M_DataRdy_wire;
        assign M_DataRdy[i] = _M_DataRdy;
        assign _M_DataRdy = Wready | Rready | (Sout_DataRdy[BITSIZE_S_ready*i*SLAVE_VALID+:BITSIZE_S_ready] === 1'b1);
        assign _M_DataRdy_wire = Wready | Rready; // Used to update at posedge clock of the queue_counter;
  
        always @(posedge clock)
        begin
          if(reset == 1'b0)
          begin
            queue_counter <= 0;
          end
          else
          begin
            queue_counter <= queue_counter_next;
          end
        end
  
        if(QUEUE_SIZE > 1)
        begin
          assign queue_counter_next = queue_counter + (((Mout_we_ram[i] || Mout_oe_ram[i]) && !Mout_back_pressure[i] && base_addr <= Mout_addr_ram[i*BITSIZE_addr +: BITSIZE_addr]) && (queue_counter == 0 ? 1 : (queue_counter  - (_M_DataRdy_wire && !M_back_pressure[i])) < (QUEUE_SIZE - 1))) - (_M_DataRdy_wire && !M_back_pressure[i]);
        end
        else 
        begin
          assign queue_counter_next = ((Mout_we_ram[i] || Mout_oe_ram[i]) && !Mout_back_pressure[i] && base_addr <= Mout_addr_ram[i*BITSIZE_addr +: BITSIZE_addr]) || (queue_counter && !_M_DataRdy_wire && !M_back_pressure[i]);
        end
  
        if(QUEUE_SIZE > 1)
        begin
          assign Mout_back_pressure[i] = M_back_pressure[i] || (queue_counter == 0 ? 0 : (queue_counter - _M_DataRdy_wire) == (QUEUE_SIZE - 1));
        end
        else 
        begin
          assign Mout_back_pressure[i] = M_back_pressure[i] || (queue_counter && !_M_DataRdy_wire);
        end
  
        reg [BITSIZE_tag-1:0] Rtag, Wtag;
        wire [BITSIZE_tag-1:0] _M_tag;
        assign _M_tag = Wtag | Rtag;
        assign M_tag[BITSIZE_tag*i+:BITSIZE_tag] = _M_tag;
  
        always@(posedge clock)
        begin 
          Rtag <= 0;
          if(oe && base_addr <= Raddr)
          begin
            Rtag <= queue_next[ACTIVE_READ*BITSIZE_item+OFFSET_tag+:BITSIZE_tag];
          end
        end
  
        always@(posedge clock)
        begin 
          Wtag <= 0;
          if(we && base_addr <= Waddr)
          begin
            Wtag <= queue_next[ACTIVE_WRITE*BITSIZE_item+OFFSET_tag+:BITSIZE_tag];
          end
        end
      end
  
      always @(posedge clock)
      begin
        if (we & oe)
        begin
          $display("ERROR - Mout_we_ram and Mout_oe_ram both enabled on channel %0d!", i);
          $finish;
        end
      end
    end
  endgenerate
endmodule


// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2023-2025 Politecnico di Milano
// Author(s): Michele Fiorito <michele.fiorito@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module TestbenchArrayImpl(clock,
  setup_port,
  ce,
  we,
  address,
  d,
  q);
  parameter index=0,
    WRITE_DELAY=1,
    READ_DELAY=2,
    BITSIZE_ce=1, PORTSIZE_ce=1,
    BITSIZE_we=1, PORTSIZE_we=1,
    BITSIZE_address=1, PORTSIZE_address=1,
    BITSIZE_d=1, PORTSIZE_d=1,
    BITSIZE_q=1, PORTSIZE_q=1;
  // IN
  input clock;
  input setup_port;
  input [(PORTSIZE_ce*BITSIZE_ce)+(-1):0] ce;
  input [(PORTSIZE_we*BITSIZE_we)+(-1):0] we;
  input [(PORTSIZE_address*BITSIZE_address)+(-1):0] address;
  input [(PORTSIZE_d*BITSIZE_d)+(-1):0] d;
  // OUT
  output [(PORTSIZE_q*BITSIZE_q)+(-1):0] q;
  
  localparam CHANNELS_NUMBER=PORTSIZE_ce,
    BITSIZE_dq=BITSIZE_d > BITSIZE_q ? BITSIZE_d : BITSIZE_q,
    BITSIZE_item=BITSIZE_d+BITSIZE_address+BITSIZE_ce+BITSIZE_we,
    BITSIZE_chunk=BITSIZE_item*CHANNELS_NUMBER,
    OFFSET_ce=0,
    OFFSET_we=OFFSET_ce+BITSIZE_ce,
    OFFSET_address=OFFSET_we+BITSIZE_we,
    OFFSET_data=OFFSET_address+BITSIZE_address,
    LAST_READ_item=READ_DELAY > 1 ? READ_DELAY-2 : 0,
    LAST_READ_size=READ_DELAY > 1 ? READ_DELAY-1 : 1;
  genvar i;
  
  if_utils #(index, BITSIZE_dq) m_utils();
  
  wire [BITSIZE_chunk-1:0] current;
  reg [BITSIZE_chunk*WRITE_DELAY-1:0] queue = 0, queue_next = 0;
  reg [CHANNELS_NUMBER*BITSIZE_q*LAST_READ_size-1:0] _q_next = 0;
  reg [CHANNELS_NUMBER*BITSIZE_q*LAST_READ_size-1:0] _q = 0;
  
  generate
    for(i = 0; i < CHANNELS_NUMBER; i = i + 1)
    begin
      assign current[BITSIZE_item*i+:BITSIZE_item] = {d[BITSIZE_d*i+:BITSIZE_d], address[BITSIZE_address*i+:BITSIZE_address], we[BITSIZE_we*i+:BITSIZE_we], ce[BITSIZE_ce*i+:BITSIZE_ce]};
      assign q[BITSIZE_q*i+:BITSIZE_q] = _q[LAST_READ_item*BITSIZE_q*CHANNELS_NUMBER+BITSIZE_q*i+:BITSIZE_q];
    end
  endgenerate
  
  generate
    if(WRITE_DELAY > 1)
    begin
      always @(posedge clock)
      begin
        if(setup_port)
        begin
          queue[BITSIZE_chunk*WRITE_DELAY-1:BITSIZE_chunk] <= 0;
          queue[BITSIZE_chunk-1:0] <= current;
        end
        else
        begin
          queue[BITSIZE_chunk*WRITE_DELAY-1:BITSIZE_chunk] <= queue_next[BITSIZE_chunk*WRITE_DELAY-1:BITSIZE_chunk];
          queue[BITSIZE_chunk-1:0] <= current;
        end
      end
      always @(*)
      begin
        queue_next[BITSIZE_chunk*WRITE_DELAY-1:BITSIZE_chunk] = queue[BITSIZE_chunk*(WRITE_DELAY-1)-1:0];
        queue_next[BITSIZE_chunk-1:0] = 0;
      end
    end
  endgenerate
  
  generate
    for(i = 0; i < CHANNELS_NUMBER; i = i + 1)
    begin : write_port
      if(WRITE_DELAY > 1)
      begin
        always @(posedge clock)
        begin
          automatic ptr_t address = queue_next[(WRITE_DELAY-1)*BITSIZE_chunk+BITSIZE_item*i+OFFSET_address+:BITSIZE_address];
          automatic reg [BITSIZE_d-1:0] data = queue_next[(WRITE_DELAY-1)*BITSIZE_chunk+BITSIZE_item*i+OFFSET_data+:BITSIZE_d];
          if(queue_next[(WRITE_DELAY-1)*BITSIZE_chunk+BITSIZE_item*i+OFFSET_ce+:BITSIZE_ce] === 1'b1
            && queue_next[(WRITE_DELAY-1)*BITSIZE_chunk+BITSIZE_item*i+OFFSET_we+:BITSIZE_we] === 1'b1)
          begin
            void'(m_utils.write_a(data, address));
          end
        end
      end
      else
      begin
        always @(posedge clock)
        begin
          automatic ptr_t address = current[BITSIZE_item*i+OFFSET_address+:BITSIZE_address];
          automatic reg [BITSIZE_d-1:0] data = current[BITSIZE_item*i+OFFSET_data+BITSIZE_d-1:BITSIZE_item*i+OFFSET_data];
          if(current[BITSIZE_item*i+OFFSET_ce+:BITSIZE_ce] === 1'b1 && current[BITSIZE_item*i+OFFSET_we+:BITSIZE_we] === 1'b1)
          begin
            void'(m_utils.write_a(data, address));
          end
        end
      end
    end
  endgenerate
  
  generate
    if(READ_DELAY > 2)
    begin : shift_output_queue1
      always @(*)
      begin
        _q_next[(READ_DELAY-1)*CHANNELS_NUMBER*BITSIZE_q-1:BITSIZE_q*CHANNELS_NUMBER] = _q[LAST_READ_item*CHANNELS_NUMBER*BITSIZE_q-1:0];
      end
    end
  endgenerate
  generate
    if(READ_DELAY > 2)
    begin : shift_output_queue2
      always @(posedge clock)
      begin
        _q[(READ_DELAY-1)*CHANNELS_NUMBER*BITSIZE_q-1:BITSIZE_q*CHANNELS_NUMBER] <= _q_next[(READ_DELAY-1)*CHANNELS_NUMBER*BITSIZE_q-1:BITSIZE_q*CHANNELS_NUMBER];
      end
    end
  endgenerate
  generate
    for(i = 0; i < CHANNELS_NUMBER; i = i + 1)
    begin : read_port
      if(READ_DELAY > 1)
      begin
        always @(posedge clock)
        begin
          if(current[BITSIZE_item*i+OFFSET_ce+:BITSIZE_ce] === 1'b1
              && current[BITSIZE_item*i+OFFSET_we+:BITSIZE_we] === 1'b0)
          begin
            automatic ptr_t address = current[BITSIZE_item*i+OFFSET_address+:BITSIZE_address];
            _q[BITSIZE_q*i+:BITSIZE_q] <= m_utils.read_a(address);
          end
          else
          begin
            _q[BITSIZE_q*i+:BITSIZE_q] <= 0;
          end
        end
      end
      else
      begin
        always @(*)
        begin
          if(current[BITSIZE_item*i+OFFSET_ce+:BITSIZE_ce] === 1'b1 && current[BITSIZE_item*i+OFFSET_we+:BITSIZE_we] === 1'b0)
          begin
            automatic ptr_t address = current[BITSIZE_item*i+OFFSET_address+:BITSIZE_address];
            _q[BITSIZE_q*i+:BITSIZE_q] = m_utils.read_a(address);
          end
        end
      end
    end
  endgenerate

endmodule


// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2023-2025 Politecnico di Milano
// Author(s): Michele Fiorito <michele.fiorito@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module if_array_conv1_input(clock,
  setup_port,
  conv1_input_address0,
  conv1_input_ce0,
  conv1_input_q0,
  conv1_input_address1,
  conv1_input_ce1,
  conv1_input_q1);
  parameter index=0,
    WRITE_DELAY=1,
    READ_DELAY=2,
    BITSIZE_conv1_input_address0=1,
    BITSIZE_conv1_input_ce0=1,
    BITSIZE_conv1_input_q0=1,
    BITSIZE_conv1_input_address1=1,
    BITSIZE_conv1_input_ce1=1,
    BITSIZE_conv1_input_q1=1;
  // IN
  input clock;
  input setup_port;
  input [BITSIZE_conv1_input_address0-1:0] conv1_input_address0;
  input conv1_input_ce0;
  input [BITSIZE_conv1_input_address1-1:0] conv1_input_address1;
  input conv1_input_ce1;
  // OUT
  output [BITSIZE_conv1_input_q0-1:0] conv1_input_q0;
  output [BITSIZE_conv1_input_q1-1:0] conv1_input_q1;
  localparam CHANNELS_NUMBER=2,
    BITSIZE_address=BITSIZE_conv1_input_address0,
    BITSIZE_dq=BITSIZE_conv1_input_q0;
  
  TestbenchArrayImpl #(.index(index),
    .WRITE_DELAY(WRITE_DELAY),
    .READ_DELAY(READ_DELAY),
    .PORTSIZE_address(CHANNELS_NUMBER),
    .BITSIZE_address(BITSIZE_address),
    .PORTSIZE_ce(CHANNELS_NUMBER),
    .PORTSIZE_we(CHANNELS_NUMBER),
    .PORTSIZE_d(CHANNELS_NUMBER),
    .BITSIZE_d(BITSIZE_dq),
    .PORTSIZE_q(CHANNELS_NUMBER),
    .BITSIZE_q(BITSIZE_dq)) array_impl(.clock(clock),
    .setup_port(setup_port),
    .ce({conv1_input_ce0,conv1_input_ce1}),
    .we({1'b0,1'b0}),
    .address({conv1_input_address0,conv1_input_address1}),
    .d({{BITSIZE_dq{1'b0}},{BITSIZE_dq{1'b0}}}),
    .q({conv1_input_q0,conv1_input_q1}));

endmodule


// This component is part of the PANDA/BAMBU IP LIBRARY
// Copyright (C) 2023-2025 Politecnico di Milano
// Author(s): Michele Fiorito <michele.fiorito@polimi.it>
// License: PANDA_LGPLv3
`timescale 1ns / 1ps
module if_array_layer13_out(clock,
  setup_port,
  layer13_out_address0,
  layer13_out_ce0,
  layer13_out_we0,
  layer13_out_d0,
  layer13_out_address1,
  layer13_out_ce1,
  layer13_out_we1,
  layer13_out_d1);
  parameter index=0,
    WRITE_DELAY=1,
    READ_DELAY=2,
    BITSIZE_layer13_out_address0=1,
    BITSIZE_layer13_out_ce0=1,
    BITSIZE_layer13_out_we0=1,
    BITSIZE_layer13_out_d0=1,
    BITSIZE_layer13_out_address1=1,
    BITSIZE_layer13_out_ce1=1,
    BITSIZE_layer13_out_we1=1,
    BITSIZE_layer13_out_d1=1;
  // IN
  input clock;
  input setup_port;
  input [BITSIZE_layer13_out_address0-1:0] layer13_out_address0;
  input layer13_out_ce0;
  input layer13_out_we0;
  input [BITSIZE_layer13_out_d0-1:0] layer13_out_d0;
  input [BITSIZE_layer13_out_address1-1:0] layer13_out_address1;
  input layer13_out_ce1;
  input layer13_out_we1;
  input [BITSIZE_layer13_out_d1-1:0] layer13_out_d1;
  localparam CHANNELS_NUMBER=2,
    BITSIZE_address=BITSIZE_layer13_out_address0,
    BITSIZE_dq=BITSIZE_layer13_out_d0;
  
  TestbenchArrayImpl #(.index(index),
    .WRITE_DELAY(WRITE_DELAY),
    .READ_DELAY(READ_DELAY),
    .PORTSIZE_address(CHANNELS_NUMBER),
    .BITSIZE_address(BITSIZE_address),
    .PORTSIZE_ce(CHANNELS_NUMBER),
    .PORTSIZE_we(CHANNELS_NUMBER),
    .PORTSIZE_d(CHANNELS_NUMBER),
    .BITSIZE_d(BITSIZE_dq),
    .PORTSIZE_q(CHANNELS_NUMBER),
    .BITSIZE_q(BITSIZE_dq)) array_impl(.clock(clock),
    .setup_port(setup_port),
    .ce({layer13_out_ce0,layer13_out_ce1}),
    .we({layer13_out_we0,layer13_out_we1}),
    .address({layer13_out_address0,layer13_out_address1}),
    .d({layer13_out_d0,layer13_out_d1}));

endmodule


// Testbench top component
// This component has been derived from the input source code and so it does not fall under the copyright of PandA framework, but it follows the input source code copyright, and constitutes a Combined Work that is statically linked with the PANDA/BAMBU SYNTHESIZABLE IP LIBRARY, and may be aggregated with components of the PANDA/BAMBU IP LIBRARY. 
// Author(s): Component automatically generated by bambu
// License: THIS COMPONENT IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
`timescale 1ns / 1ps
module bambu_testbench_impl(clock);
  // IN
  input clock;
  // Component and signal declarations
  wire [12:0] sig_conv1_input_address0;
  wire [12:0] sig_conv1_input_address1;
  wire sig_conv1_input_ce0;
  wire sig_conv1_input_ce1;
  wire [11:0] sig_conv1_input_q0;
  wire [11:0] sig_conv1_input_q1;
  wire sig_done_port;
  wire [5:0] sig_layer13_out_address0;
  wire [5:0] sig_layer13_out_address1;
  wire sig_layer13_out_ce0;
  wire sig_layer13_out_ce1;
  wire [11:0] sig_layer13_out_d0;
  wire [11:0] sig_layer13_out_d1;
  wire sig_layer13_out_we0;
  wire sig_layer13_out_we1;
  wire sig_reset;
  wire sig_setup_port;
  wire sig_start_port;
  
  TestbenchDUT DUT (.done_port(sig_done_port),
    .conv1_input_address0(sig_conv1_input_address0),
    .conv1_input_address1(sig_conv1_input_address1),
    .conv1_input_ce0(sig_conv1_input_ce0),
    .conv1_input_ce1(sig_conv1_input_ce1),
    .layer13_out_address0(sig_layer13_out_address0),
    .layer13_out_address1(sig_layer13_out_address1),
    .layer13_out_ce0(sig_layer13_out_ce0),
    .layer13_out_ce1(sig_layer13_out_ce1),
    .layer13_out_we0(sig_layer13_out_we0),
    .layer13_out_we1(sig_layer13_out_we1),
    .layer13_out_d0(sig_layer13_out_d0),
    .layer13_out_d1(sig_layer13_out_d1),
    .clock(clock),
    .reset(sig_reset),
    .start_port(sig_start_port),
    .conv1_input_q0(sig_conv1_input_q0),
    .conv1_input_q1(sig_conv1_input_q1));
  TestbenchFSM #(.RESFILE("results.txt"),
    .RESET_ACTIVE(0),
    .RESET_CYCLES(1),
    .RESET_ALWAYS(0),
    .CLOCK_PERIOD(2.0),
    .MAX_SIM_CYCLES(200000000)) SystemFSM (.reset(sig_reset),
    .setup_port(sig_setup_port),
    .start_port(sig_start_port),
    .clock(clock),
    .done_port(sig_done_port));
  TestbenchMEMMinimal #(.index(2),
    .MEM_DELAY_READ(2),
    .MEM_DELAY_WRITE(1),
    .EMULATE_BRAM(1),
    .base_addr(1073741824),
    .MEM_DUMP(0),
    .MEM_DUMP_FILE("memdump.csv"),
    .QUEUE_SIZE(4),
    .BITSIZE_M_DataRdy(1),
    .BITSIZE_M_Rdata_ram(8),
    .BITSIZE_M_back_pressure(1),
    .BITSIZE_M_tag(1),
    .BITSIZE_Mout_oe_ram(1),
    .BITSIZE_Mout_we_ram(1),
    .BITSIZE_Mout_addr_ram(1),
    .BITSIZE_Mout_data_ram_size(4),
    .BITSIZE_Mout_Wdata_ram(8),
    .BITSIZE_Mout_back_pressure(1),
    .BITSIZE_Mout_tag(1),
    .BITSIZE_Sout_DataRdy(1),
    .BITSIZE_Sout_Rdata_ram(8),
    .BITSIZE_S_oe_ram(1),
    .BITSIZE_S_we_ram(1),
    .BITSIZE_S_addr_ram(1),
    .BITSIZE_S_data_ram_size(4),
    .BITSIZE_S_Wdata_ram(8)) SystemMEM (.clock(clock),
    .reset(sig_reset),
    .done_port(sig_done_port));
  if_array_conv1_input #(.index(0),
    .WRITE_DELAY(1),
    .READ_DELAY(2),
    .BITSIZE_conv1_input_address0(13),
    .BITSIZE_conv1_input_ce0(1),
    .BITSIZE_conv1_input_q0(12),
    .BITSIZE_conv1_input_address1(13),
    .BITSIZE_conv1_input_ce1(1),
    .BITSIZE_conv1_input_q1(12)) if_array_conv1_input_fu (.conv1_input_q0(sig_conv1_input_q0),
    .conv1_input_q1(sig_conv1_input_q1),
    .clock(clock),
    .setup_port(sig_setup_port),
    .conv1_input_address0(sig_conv1_input_address0),
    .conv1_input_ce0(sig_conv1_input_ce0),
    .conv1_input_address1(sig_conv1_input_address1),
    .conv1_input_ce1(sig_conv1_input_ce1));
  if_array_layer13_out #(.index(1),
    .WRITE_DELAY(1),
    .READ_DELAY(2),
    .BITSIZE_layer13_out_address0(6),
    .BITSIZE_layer13_out_ce0(1),
    .BITSIZE_layer13_out_we0(1),
    .BITSIZE_layer13_out_d0(12),
    .BITSIZE_layer13_out_address1(6),
    .BITSIZE_layer13_out_ce1(1),
    .BITSIZE_layer13_out_we1(1),
    .BITSIZE_layer13_out_d1(12)) if_array_layer13_out_fu (.clock(clock),
    .setup_port(sig_setup_port),
    .layer13_out_address0(sig_layer13_out_address0),
    .layer13_out_ce0(sig_layer13_out_ce0),
    .layer13_out_we0(sig_layer13_out_we0),
    .layer13_out_d0(sig_layer13_out_d0),
    .layer13_out_address1(sig_layer13_out_address1),
    .layer13_out_ce1(sig_layer13_out_ce1),
    .layer13_out_we1(sig_layer13_out_we1),
    .layer13_out_d1(sig_layer13_out_d1));

endmodule



// MODULE DECLARATION
module bambu_testbench(clock);

  input clock;
  
  initial
  begin
    `ifndef VERILATOR
    // VCD file generation
    $dumpfile("HLS_output/simulation/test.vcd");
    `ifdef GENERATE_VCD
    $dumpvars;
    `endif
    `endif
  end
  
  bambu_testbench_impl system(.clock(clock));
  
endmodule

`ifndef VERILATOR
module clocked_bambu_testbench;
parameter HALF_CLOCK_PERIOD=1.0;
  
  reg clock;
  initial clock = 1;
  always # HALF_CLOCK_PERIOD clock = !clock;
  
  bambu_testbench bambu_testbench(.clock(clock));
  
endmodule
`endif

// verilator lint_on BLKANDNBLK
// verilator lint_on BLKSEQ
