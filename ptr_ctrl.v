//-----------------------------------------------------------------------------
//
// Title       : Pointer Control 
// Design      : verilog
// Author      : Geoffrey Wall
// Company     : N/A
//
//-----------------------------------------------------------------------------
//
// File        : ptr_ctrl.v
//-----------------------------------------------------------------------------
//
// Description : This block generates full and empty flags and implements pointer incrementing logic.
//               Logic in this block is inspired by ideas from here:
//               //http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf
//               This block is currently used for both read and write pointer logic 
//
//-----------------------------------------------------------------------------

module ptr_ctrl
  #
  (
   parameter ADDR_WIDTH = 4
   )
   (
    input 		       inc, clk, srst,
    //the unsynchronized pointer (gray coded) - this comes from the other clock domain
    //could be the read or write clock domain since this block is used to generate pointer logic on both sides
    input [ADDR_WIDTH :0]      ptr_in,
    //full and empty flags
    output reg 		       full,
    output reg 		       empty,
    //the write address to be connected to the block ram's write port
    output [ADDR_WIDTH-1:0]    addr,
    //the write pointer (gray coded)
    output reg [ADDR_WIDTH :0] ptr_out,
    //number of elements used in the fifo
    //currently this number is correct only for the write side of the fifo
    //needs to be computed differently for the read side
    output reg [ADDR_WIDTH :0] used
    );
     
   reg [ADDR_WIDTH:0] 	  bin;
   wire [ADDR_WIDTH:0] 	  graynext, binnext;
   wire [ADDR_WIDTH:0] 	  ptr_in_synced;
   wire [ADDR_WIDTH:0] 	  ptr_in_synced_bin;

   //function to convert gray coded numbers back to regular binary numbers
   function [ADDR_WIDTH:0] gray2bin;
      input [ADDR_WIDTH:0] gray_val;
      integer 		   i;
      gray2bin[ADDR_WIDTH] = gray_val[ADDR_WIDTH];
      for (i = ADDR_WIDTH - 1; i >= 0; i = i - 1)
	gray2bin[i] = gray_val[i] ^ gray2bin[i + 1];
   endfunction
    
   //two stage shift register to register the gray coded pointer into this clock domain
   //once registered it will be used to compute full and empty
   shift_register
     #
     (
      .WIDTH(ADDR_WIDTH+1),
      .STAGES(2)
      )
   SHIFT_REGISTER
     (
      .clk(clk),
      .srst(srst),
      .din(ptr_in),
      .dout(ptr_in_synced)
      );
  
   // Memory write-address pointer (use this ptr to address the block ram externally)
   assign addr = bin[ADDR_WIDTH-1:0];
   //combinational logic for incrementing the pointer (this is registered below)
   assign binnext = bin + inc;
   //combinational logic for computing the gray code of the incremented pointer (this is registered below)
   assign graynext = (binnext>>1) ^ binnext;
   //compute the binary version of the synchronized gray code pointer after having been synchronized into this block's clock domain
   assign ptr_in_synced_bin = gray2bin(ptr_in_synced);
   always @(posedge clk) begin
      //register in the combinational logic computed above
      {bin, ptr_out} <= {binnext, graynext};
      //if the top two bits are not equal and the rest of the bits are equal, then we are full
      full <= (graynext=={~ptr_in_synced[ADDR_WIDTH:ADDR_WIDTH-1], ptr_in_synced[ADDR_WIDTH-2:0]});
      //if the two pointers (including the MSBs are equal, then the FIFO is empty)
      empty <= (graynext == ptr_in_synced);
      //this used count is only corrent for the write side of the fifo
      //it needs to be inverted for the read side of the FIFO
      used <= binnext - ptr_in_synced_bin;
      
      //handle synchronous reset      
      if (srst) begin
	 {bin, ptr_out, full, empty, used} <= 0;
      end
   end
    
endmodule
