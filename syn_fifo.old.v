

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
   output [USED_WIDTH - 1:0]     used;
   
   reg [ADDR_WIDTH - 1:0]   wptr;
   reg [ADDR_WIDTH - 1:0]   rptr;
   reg [USED_WIDTH - 1:0]   cnt;

   wire 		    fulli, emptyi;
   assign fulli = (cnt == (DEPTH));
   assign emptyi = (cnt == 0);
   assign full = fulli;
   assign empty = emptyi;
   assign used = cnt;
      
   always @(posedge clk) begin 
      if (wen & !fulli)
	wptr <= wptr + 1;

      if (ren & !emptyi)
	rptr <= rptr + 1;
      
      if (wen & !ren & !fulli)
	cnt <= cnt + 1;
      
      if (!wen & ren & !emptyi)
	cnt <= cnt - 1;
      
      if (srst)
	begin
	   wptr <= 0;
	   rptr <= 0;
	   cnt <=0;
	end 
   end

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
      .waddr(wptr),
      .wdata(data_in),
      .raddr(rptr),
      .rdata(data_out)
      );
   
endmodule

