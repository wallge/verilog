//-----------------------------------------------------------------------------
//
// Title       : Video Pattern Generator Block
// Design      : verilog
// Author      : Geoffrey Wall
// Company     : N/A
//
//-----------------------------------------------------------------------------
//
// File        : video_gen.v
//-----------------------------------------------------------------------------
//
// Description : video pattern generator block with sop, eop, valid, and obeys ready
//
//-----------------------------------------------------------------------------

module video_gen
  #
  (
   //image bit depth
   parameter BITS = 8,
   //image rows
   parameter ROWS = 240,
   //image columns
   parameter COLS = 320,
   //video pattern to be generated
   parameter PATTERN = 0
   )
   (
    input 		    clk, srst, ready,
    output reg [BITS - 1:0] data,
    output reg 		    sop, eop, valid
    );
   
   integer 		    rcount, ccount;
   //size of the checkerboard pattern in pixels
   localparam CHECKER_DIM = 32;
   wire 		    check_x, check_y;
   
   //to generate the checkerboard pattern we must
   //divide the image counters by the size of each checker and then look
   //at the lowest bit in both the x and y quotients.
   //these bits are xor'red together to generate the checkerboard 
   assign check_x = (ccount / CHECKER_DIM) % 2;
   assign check_y = (rcount / CHECKER_DIM) % 2;
   always @(posedge clk) begin
      //if ready is low then this block is stalled 
      if (ready) begin
	 case (PATTERN)
	   //horizontal gradient
	   0: data <= ccount;
	   //vertical gradient
	   1: data <= rcount;
	   //diagonal gradient
	   2: data <= ccount + rcount;
	   //checkerboard pattern
	   3: data <= {BITS{check_x ^ check_y}};
	 endcase
	 valid <= 1;

	 //increment over rows and columns
	 if (ccount < COLS - 1) 
	   ccount <= ccount + 1;
	 else begin
	    ccount <= 0;
	    if (rcount < ROWS - 1) 
	      rcount <= rcount + 1;
	    else
	      rcount <= 0;
	 end

	 //at the zeroth pixel assert start of packet
	 if ((rcount == 0) && (ccount == 0))
	   sop <= 1;
	 else
	   sop <= 0;

	 //at the last pixel assert end of packet
	 if ((rcount == ROWS - 1) && (ccount == COLS - 1))
	   eop <= 1;
	 else
	   eop <= 0;
      end // if (ready)
      
      //do sync resets
      if (srst)
	{sop, eop, data, valid, rcount, ccount} = 0;
   end

endmodule

