//-----------------------------------------------------------------------------
//
// Title       : Async FIFO
// Design      : verilog
// Author      : Geoffrey Wall
// Company     : N/A
//
//-----------------------------------------------------------------------------
//
// File        : async_fifo.v
//-----------------------------------------------------------------------------
//
// Description : asynchronous FIFO block
//
//-----------------------------------------------------------------------------
module async_fifo
  #
  (
   parameter WIDTH = 8,
   parameter DEPTH = 256
   )
  (
   input 		wclk, wrst, wen, ren, rclk, rrst, 
   output 		wfull, wempty, rfull, rempty,
   input [WIDTH - 1:0] 	din,
   output [WIDTH - 1:0] dout,
   output [$clog2(DEPTH):0] 	wused, rused
   );

   wire [$clog2(DEPTH):0] wptr, rptr;
   wire [$clog2(DEPTH)-1:0] waddr, raddr;
 
    ptr_ctrl
      #
      (
       .ADDR_WIDTH($clog2(DEPTH))
       )
   WPTR_CTRL
     (
      .clk(wclk), 
      .srst(wrst),
      .inc(wen & !wfull),
      .ptr_in(rptr),
      .full(wfull),
      .empty(wempty),
      .addr(waddr),
      .ptr_out(wptr),
      .used(wused)
      );
   
   
   async_ram
     #
     (
      .WIDTH(WIDTH),
      .DEPTH(DEPTH)
      )
   FIFO_RAM
     (
      .wclk(wclk),
      .we(wen & ~wfull),
      .waddr(waddr),
      .wdata(din),
      .rclk(rclk),
      .raddr(raddr),
      .rdata(dout)
      );
   
    ptr_ctrl
      #
      (
       .ADDR_WIDTH($clog2(DEPTH))
       )
   RPTR_CTRL
     (
      .clk(rclk), 
      .srst(rrst),
      .inc(ren & ~rempty),
      .ptr_in(wptr),
      .full(rfull),
      .empty(rempty),
      .addr(raddr),
      .ptr_out(rptr),
      .used(rused)
      );
   
   
endmodule

