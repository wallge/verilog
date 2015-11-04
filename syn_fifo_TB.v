//-----------------------------------------------------------------------------
//
// Title       : syn_fifo_tb
// Design      : verilog
// Author      : Geoffrey Wall
// Company     : N/A
//
//-----------------------------------------------------------------------------
//
// Description : Test bench for sync fifo
//
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps
module syn_fifo_tb;
   parameter WIDTH = 16;
   parameter DEPTH = 8;
   parameter USED_WIDTH = $clog2(DEPTH+1);

   //Internal signals declarations:
   reg clk;
   reg 	srst;
   reg 	weni;
   reg [WIDTH-1:0] data_in;
   reg 		   reni;
   wire [WIDTH-1:0] data_out;
   wire 	    full;
   wire 	    empty;
   wire [USED_WIDTH-1:0] used;

   integer cnt;
   reg 	[2:0]   do_read, do_write;
   reg [2:0] 	rcmp, wcmp;
   reg [WIDTH-1:0] data_cnt;
   wire 	   wen, ren;

   //reset everything at the beginning of time
   initial begin
      clk = 0;
      srst = 1;
      cnt = 0;
      weni = 0;
      reni = 0;
      data_in = 0;
      data_cnt = 0;
      //create the clock
      forever
	#100 clk = ~clk;
   end

   //deassrted reset after awhile
  always begin
     #1000  srst = 0;
  end

   //create the combinational version of write enable which takes full into account
   assign wen = weni & !full;
   //create the combinational version of read enable which takes empty into account
   assign ren = reni & !empty;
      
   always @(posedge clk) begin
      cnt <= cnt + 1;
      //generate random numbers to determine whether reads or write will occur
      rcmp <= $random;
      wcmp <= $random; 
      do_read <= $random; 
      do_write <= $random;
      weni<= 0;
      reni <= 0;

      //assert writes
      if ((do_write < wcmp)& !full)
	weni <= 1;

      //increment the data counter
      if (wen)
	data_in <= data_in + 1;

      //assert reads
      if ((do_read < rcmp) & !empty)
	reni <= 1;

      //increment the data read counter
      if (ren)
	data_cnt <= data_cnt + 1;

      //reset everything when reset is asserted
      if (srst)
	begin
	   do_read <= 0;
	   do_write <= 0;
	   cnt <= 0;
	   weni <= 0;
	   reni <= 0;
	   data_in <= 0;
	   data_cnt <= 0;
	   rcmp <= 0;
	   wcmp <= 0;
	end
   end 
   
   //instantiate the FIFO
   syn_fifo 
     #
     (
      .WIDTH(WIDTH),
      .DEPTH(DEPTH)
      )
   SYN_FIFO 
     (
      .clk(clk),
      .srst(srst),
      .wen(wen),
      .data_in(data_in),
      .ren(ren),
      .data_out(data_out),
      .full(full),
      .empty(empty),
      .used(used)
      );
   
endmodule
