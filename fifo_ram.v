//-----------------------------------------------------------------------------
//
// Title       : FIFO RAM
// Design      : verilog
// Author      : Geoffrey Wall
// Company     : N/A
//
//-----------------------------------------------------------------------------
//
// File        : fifo_ram.v
//-----------------------------------------------------------------------------
//
// Description : inferred 1 clk memory for synchronous fifo
//
//-----------------------------------------------------------------------------

module fifo_ram 
  (
   clk,
   we,
   waddr,
   wdata,
   raddr,
   rdata
   );
   parameter WIDTH = 8;
   parameter DEPTH = 256;
   parameter ADDR_WIDTH = $clog2(DEPTH);
   
   input we, clk;
   input [ADDR_WIDTH - 1:0] waddr, raddr;
   input [WIDTH - 1:0] 	    wdata;
   output reg [WIDTH - 1:0] rdata;
   reg [WIDTH - 1:0] 	    ram [DEPTH - 1:0];
   
   always @(posedge clk) begin 
      if (we)
	ram[waddr] <= wdata;
      rdata <= ram[raddr];
   end

endmodule

