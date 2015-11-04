//-----------------------------------------------------------------------------
//
// Title       : Shift Register
// Design      : verilog
// Author      : Geoffrey Wall
// Company     : N/A
//
//-----------------------------------------------------------------------------
//
// File        : shift_register.v
//-----------------------------------------------------------------------------
//
// Description : shift register with variable width and shift stages
//
//-----------------------------------------------------------------------------

module shift_register
  #(
    parameter WIDTH = 16,
    parameter STAGES = 3
    )
   (
    input 		 clk, srst,
    input [WIDTH - 1:0]  din,
    output [WIDTH - 1:0] dout
    );
   reg [STAGES - 1:0] [WIDTH - 1:0] regs;
   
   always @(posedge clk) begin
      regs <= {regs[STAGES - 2:0], din};
   
      if (srst)
	regs <= 0;
   end
   
   assign dout = regs[STAGES - 1];
      
endmodule

