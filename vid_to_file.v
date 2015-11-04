//-----------------------------------------------------------------------------
//
// Title       : Save video to PGM file
// Design      : system verilog
// Author      : Geoffrey Wall
// Company     : N/A
//
//-----------------------------------------------------------------------------
//
// File        : vid_to_file.v
//-----------------------------------------------------------------------------
//
// Description : save video to PGM file
//
//-----------------------------------------------------------------------------

module vid_to_file
  #
  (
   parameter BITS = 8,
   parameter ROWS = 240,
   parameter COLS = 320,
   parameter string fname = "image",
   parameter ready_perc = 50
   
   )
   (
    input 	       clk, srst, 
    input [BITS - 1:0] data,
    input 	       sop, eop, valid,
    output reg 	       ready
    );
   // row and col counts
   integer     rcount, ccount;
   //frame number counter
   integer     frame_num;
   //generate random numbers using this variable
   integer     rand_num;
   //our video frame variable
   reg [BITS - 1:0] vid_frame [ROWS-1:0][COLS-1:0];
   //states defs for our state machine
   typedef enum     {
		     //FSM stays in reset and does nothing until srst is deasserted
		     RESET,
		     //receive the frame and store pixels in this state
		     RECEIVE_FRAME,
		     //generate the text string that represents the file name in this state
		     WRITE_FNAME,
		     //write the frame variable out to disk in this state
		     WRITE_FRAME
		     } 
		    state_type;
   //state machine variable
   state_type state;
   //string for storing the file name
   string 	    fname_string;
   //registers for detecting errors
   reg 		    sop_err, eop_err;
   
   //task for writing the 8 bit PGM image
   task write_image8;
      input [BITS - 1:0] vid_frame [ROWS-1:0][COLS-1:0];
      input string 	 filename;
      integer 		 i,j, file;
    
      file = $fopen(filename, "w");
      $fwrite(file,"P2\n#%s created by vid_to_file.v\n%0d %0d\n255\n", filename, COLS, ROWS);
            
      for (i = 0; i < ROWS; i=i+1)
	for (j = 0; j < COLS; j=j+1)
	  $fwrite(file,"%0d\n", vid_frame[i][j]);
      $fclose(file);
   endtask // write_image8

   //compute the absolute value in verilog
   //apparently there is no library for doing this
   function integer abs;
      input integer 	 value;
      if (value < 0)
	abs = -value;
      else
	abs = value;
   endfunction
       
   always @(posedge clk) begin

      case (state)
	//////////////////////////////////////////////
	RESET:begin
	   //once we come out of reset we can start receiving video
	   if (~srst) begin
	      state <= RECEIVE_FRAME;
	      {ready, frame_num} = 0;
	      {rcount, ccount} = 0;
	   end
	end
	//////////////////////////////////////////////
	RECEIVE_FRAME:begin
	   //receive the frame of video in this state
	   //generate random numbers to determine whether or not
	   //ready will be high on the next clock cycle
	   rand_num = $random % 101;
	   if (ready_perc >= abs(rand_num))
	     ready <= 1;
	   else
	     ready <= 0;

	   //only receive video when ready is high
	   if (ready) begin
	      //video is accepted when valid is asserted 
	      if (valid) begin
		 //save the pixel to its place in the video frame variable
		 vid_frame[rcount][ccount] <= data;

		 //increment the rows, col counters
		 if (ccount < COLS - 1) 
		   ccount <= ccount + 1;
		 else begin
		    ccount <= 0;
		    if (rcount < ROWS - 1) 
		      rcount <= rcount + 1;
		    else begin
		       //at the end of the frame, deassert ready and go to the next state
		       state <= WRITE_FNAME;
		       rcount <= 0;
		       ready <= 0;
		    end
		 end // else: !if(ccount < COLS - 1)
		 
		 //detect errors relating to SOP and EOP
		 if ((rcount == 0) && (ccount == 0) && (!sop)) begin
		   $error("SOP should have been high!\n");
		    sop_err <= 1;
		 end
		 
		 if ((rcount == ROWS - 1) && (ccount == COLS - 1) && (!eop)) begin
		   $error("EOP should have been high!\n");
		    eop_err <= 1;
		 end
		 
	      end
	   end // if (ready)
	end // case: RECEIVE_FRAME
	//////////////////////////////////////////////
	//create the text string for the file name in this state and increment the frame counter
	WRITE_FNAME:begin
	   ready <= 0;
	   fname_string <= {fname, $sformatf("_%0d", frame_num), ".pgm"};
	   frame_num <= frame_num + 1;
	   state <= WRITE_FRAME;
	   
	end
	//////////////////////////////////////////////
	//in this state write the file to disk
	WRITE_FRAME:begin
	   ready <= 0;
	   state <= RECEIVE_FRAME;
	   //need to write other functions to handle greater bitwidth images.. including color PPM images
	   if (BITS <= 8)
	     write_image8(vid_frame, fname_string);
	end
      endcase // case (state)
      
      //handle sync reset
      if (srst) begin
	 {ready, frame_num} = 0;
	 {rcount, ccount} = 0;
	 {sop_err, eop_err} = 0;
	 state <= RESET;
      end

   end
    
endmodule

