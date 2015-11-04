

module stream_latency_1_to_0
  #
  (
   parameter BITS = 8
   )
   (
    input  clk, srst, dout_rdy,  din_sop, din_eop, din_val, [BITS - 1:0] din,
    output din_rdy, dout_sop, dout_eop, dout_val, [BITS - 1:0] dout
    );

   reg [BITS - 1:0] reg_din;
   reg 		    reg_sop, reg_eop, reg_val;
   
   

   assign din_rdy = dout_rdy & ~reg_val;
   
      
   always @(posedge clk) begin
      
      if (din_val & ~dout_rdy) begin
	 reg_val <= 1;
	 reg_din <= din;
	 reg_sop <= din_sop;
	 reg_eop <= din_eop;
      end
      else if (dout_rdy)
	reg_val <= 0;
      
      if (srst)
	reg_val <= 0;
   end

   assign dout_val = din_val | reg_val;
   assign dout = (reg_val ? reg_din : din);
   assign dout_sop = (reg_val ? reg_sop : din_sop);
   assign dout_eop = (reg_val ? reg_eop : din_eop);
      
endmodule

