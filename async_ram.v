//-----------------------------------------------------------------------------
//
// Title       : 2 clock inferred ram with read and write port
// Design      : verilog
// Author      : Geoffrey Wall
// Company     : N/A
//
//-----------------------------------------------------------------------------
//
// File        : async_ram.v
//-----------------------------------------------------------------------------
//
// Description : 2 clock RAM with a read and write port. Used for async FIFO block.
//
//-----------------------------------------------------------------------------

module async_ram
  #
  (
   parameter WIDTH = 8,
   parameter DEPTH = 256
   )
   (
    input 		     we, wclk, rclk,
    input [$clog2(DEPTH) - 1:0] waddr, raddr,
    input [WIDTH - 1:0]      wdata,
    output reg [WIDTH - 1:0] rdata
   );
   reg [WIDTH - 1:0] 	     ram [DEPTH - 1:0];
   
   always @(posedge wclk) begin 
      if (we)
	ram[waddr] <= wdata;
   end

   always @(posedge rclk) begin 
      rdata <= ram[raddr];
   end

endmodule

