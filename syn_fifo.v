//-----------------------------------------------------------------------------
//
// Title       : Synchronous FIFO
// Design      : verilog
// Author      : Geoffrey Wall
// Company     : N/A
//
//-----------------------------------------------------------------------------
//
// File        : syn_fifo.v
//-----------------------------------------------------------------------------
//
// Description : synchronous FIFO block
//
//-----------------------------------------------------------------------------

module syn_fifo
  (
   clk,
   srst,
   wen,
   data_in,
   ren,
   data_out,
   full,
   empty,
   used
   );
   parameter WIDTH = 8;
   parameter DEPTH = 256;
   parameter ADDR_WIDTH = $clog2(DEPTH);
   parameter USED_WIDTH = $clog2(DEPTH+1);
      
   input clk, srst, wen, ren;
   output full, empty;
   input [WIDTH - 1:0] data_in;
   output [WIDTH - 1:0] data_out;
   output [USED_WIDTH - 1:0] used;
   //pointers have one extra MSB that will be used for 
   //determining if the write address has wrapped around or not
   //see this paper to explain this
   //http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf
   reg [ADDR_WIDTH:0] 	     wptr;
   reg [ADDR_WIDTH:0] 	     rptr;
   wire 		     fulli, emptyi;

   //from here: http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf
   //if the MSBs are not equal, but the rest of the ptrs are equal, then the write 
   //pointer is catching up with the read pointer after having wrapped around
   //this indicates that the fifo is filed
   assign fulli = ({~wptr[ADDR_WIDTH], wptr[ADDR_WIDTH - 1:0]}==rptr);
   assign emptyi = (wptr==rptr);
   
   assign full = fulli;
   assign empty = emptyi;
   assign used = wptr - rptr;
         
   always @(posedge clk) begin
      //if write is asserted and we are not full increment the "next-to-write" pointer
      if (wen & !fulli)
	wptr <= wptr + 1;

      //if read is asserted and we are not empty increment the "next-to-read" pointer
      if (ren & !emptyi)
	rptr <= rptr + 1;

      if (srst)
	begin
	   wptr <= 0;
	   rptr <= 0;
	end 
   end

   //instantiation of our synchronous FIFO RAM
   fifo_ram
     #
     (
      .WIDTH(WIDTH),
      .DEPTH(DEPTH)
      )
   FIFO_RAM
     (
      .clk(clk),
      .we(wen),
      //strip off the MSB of the pointers since they are only used for determining full / empty
      .waddr(wptr[ADDR_WIDTH - 1:0]),
      .wdata(data_in),
      .raddr(rptr[ADDR_WIDTH - 1:0]),
      .rdata(data_out)
      );
   
endmodule

