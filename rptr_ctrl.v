

module rptr_ctrl
  #
  (
   parameter ADDR_WIDTH = 4,
   parameter ISWRI
   )
   (
    input 		       rinc, rclk, rrst,
    //the unsynchronized read pointer (gray coded)
    input [ADDR_WIDTH :0]      rptr,
    //full and empty flags
    output reg 		       rfull,
    output reg 		       rempty,
    //the write address to be connected to the block ram's write port
    output [ADDR_WIDTH-1:0]    raddr,
    //the write pointer (gray coded)
    output reg [ADDR_WIDTH :0] rptr
    );
   localparam HELLO = 0;
   
   reg [ADDR_WIDTH:0] 	  rbin;
   wire [ADDR_WIDTH:0] 	  rgraynext, rbinnext;
   wire [ADDR_WIDTH:0] 	  rptr_sync;
      
   shift_register
     #
     (
      .WIDTH(ADDR_WIDTH+1),
      .STAGES(2)
      )
   SHIFT_REGISTER
     (
      .clk(rclk),
      .srst(rrst),
      .din(rptr),
      .dout(rptr_sync)
      );

  
   // Memory write-address pointer (okay to use binary to address memory)
   assign raddr = rbin[ADDR_WIDTH-1:0];
   assign rbinnext = rbin + (rinc & ~rfull);
   assign rgraynext = (rbinnext>>1) ^ rbinnext;
   // GRAYSTYLE2 pointer
   always @(posedge rclk) begin
      {rbin, rptr} <= {rbinnext, rgraynext};
      //------------------------------------------------------------------
      // Simplified version of the three necessary full-tests:
      // assign wfull_val=((wgnext[ADDR_WIDTH] !=wq2_rptr[ADDR_WIDTH] ) &&
      // (wgnext[ADDR_WIDTH-1] !=wq2_rptr[ADDR_WIDTH-1]) &&
      // (wgnext[ADDR_WIDTH-2:0]==wq2_rptr[ADDR_WIDTH-2:0]));
      //------------------------------------------------------------------
      rfull <= (rgraynext=={~rptr_sync[ADDR_WIDTH:ADDR_WIDTH-1], rptr_sync[ADDR_WIDTH-2:0]});
      rempty <= (rgraynext == rptr_sync);

    
      if (rrst) begin
	 rbin <= 0;
	 rptr <= 0;
	 rfull <= 0;
	 rempty <= 0;
      end
   end
    
endmodule
