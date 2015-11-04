//-----------------------------------------------------------------------------
//
// Title       : async_fifo_tb
// Design      : verilog
// Author      : Geoffrey Wall
// Company     : N/A
//
//-----------------------------------------------------------------------------
//
// Description : Async fifo test bench with video pipeline
//
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps
module async_fifo_tb;
//Parameters declaration: 
   parameter WIDTH = 10;
   parameter DEPTH = 16;
   localparam USED_WIDTH = $clog2(DEPTH)+1;

//Internal signals declarations:
   reg wclk;
   reg wrst;
   wire wen;
   wire ren;
   reg  ren_d;
   reg 	rclk;
   reg 	rrst;
   wire wfull;
   wire wempty;
   wire rfull;
   wire rempty;
   wire [WIDTH-1:0] din;
   wire [WIDTH-1:0] dout;
   wire [USED_WIDTH-1:0] wused;
   wire [USED_WIDTH-1:0] rused;
   wire 		 vgen_ready;
   wire 		 cap_ready;
   wire [7:0] 		 vgen_data;
   wire 		 sop, eop, valid;
   wire 		 cap_sop, cap_eop, cap_valid;
   wire [7:0] 		 cap_data;
   wire 		 rdy_cnvrt;
   

   //init some vars at beginning of time
   initial begin
      wclk = 0;
      rclk = 0;
      wrst = 1;
      rrst = 1;
      //create the write clock
      forever
	#21 wclk = ~wclk;
   end // initial begin

   //create the read clock
   always begin
      #10 rclk = ~rclk;
   end

   //create resets
   always begin
      #1000  wrst = 0;
   end
   
   always begin
      #700  rrst = 0;
   end

   //instantiate the video pattern generator
   video_gen
     #
     (
      //generate 8 bit video
      .BITS(8), 
      .ROWS(240), 
      .COLS(320),
      //create checkerboard pattern video
      .PATTERN(3)
      )
   VIDEO_GEN
     (
      //video generated on the write clock
      .clk(wclk), 
      .srst(wrst), 
      .ready(vgen_ready),
      .data(vgen_data),
      .sop(sop), 
      .eop(eop), 
      .valid(valid)
      );
   
   //create combinational version of wen which obeys reset and full signals
   assign wen = valid & ~wfull & ~wrst;
   assign vgen_ready = ~wfull & ~wrst;
   //shove sop, eop, and pixel data into the fifo
   assign din = {sop, eop, vgen_data};
   
   // our async fifo
   async_fifo 
     #
     (
      .WIDTH(10),
      .DEPTH(DEPTH)
      )
   UUT
     (
      .wclk(wclk),
      .wrst(wrst),
      .wen(wen),
      .ren(ren),
      .rclk(rclk),
      .rrst(rrst),
      .wfull(wfull),
      .wempty(wempty),
      .rfull(rfull),
      .rempty(rempty),
      .din(din),
      .dout(dout),
      .wused(wused),
      //rused is currently not being computed correctly
      .rused(rused)
      );
   
   //create a combinational version fo ren which obeys empty and rsts and ready
   assign ren = rdy_cnvrt & ~rempty & ~rrst;
   
   //create a registered version of ren, since it represents data valid coming out of the fifo
   //in otherwords if ren_d is high, then the output of the fifo is a valid pixel
   always @(posedge rclk) begin
      ren_d <= ren & ~rrst;
   end
   
   //instantiate a "ready latency" converter. This is needed because of the fact that
   //when ren_d goes high, we cannot backpressure it.
   //below is basically a 1 deep fifo since the async fifo only obeys ready 1 clock in advance.
   stream_latency_1_to_0
     #
     (
      .BITS(8)
      )
   STREAM_LATENCY_1_TO_0
     (
      .clk(rclk), 
      .srst(rrst), 
      .dout_rdy(cap_ready), 
      .din(dout[7:0]), 
      .din_sop(dout[9]), 
      .din_eop(dout[8]), 
      .din_val(ren_d),
      .din_rdy(rdy_cnvrt), 
      .dout(cap_data), 
      .dout_sop(cap_sop), 
      .dout_eop(cap_eop), 
      .dout_val(cap_valid)
      );

   //block which saves images to disk in PGM format
   vid_to_file
     #
     (
      .BITS(8),
      .ROWS(240),
      .COLS(320),
      //image name
      .fname("my_image"),
      //percentage of the time that ready is high (0 to 100)
      .ready_perc(10)
      )
   VID_TO_FILE
     (
      .clk(rclk), 
      .srst(rrst), 
      .data(cap_data),
      .sop(cap_sop), 
      .eop(cap_eop), 
      .valid(cap_valid),
      .ready(cap_ready)
      );
   
endmodule
