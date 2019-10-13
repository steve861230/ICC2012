`timescale 1ns/100ps
module NFC(clk, rst, done, F_IO_A, F_CLE_A, F_ALE_A, F_REN_A, F_WEN_A, F_RB_A, F_IO_B, F_CLE_B, F_ALE_B, F_REN_B, F_WEN_B, F_RB_B);

  input clk;
  input rst;
  output done;
  inout [7:0] F_IO_A;
  output F_CLE_A;
  output F_ALE_A;
  output F_REN_A;
  output F_WEN_A;
  input  F_RB_A;
  inout [7:0] F_IO_B;
  output F_CLE_B;
  output F_ALE_B;
  output F_REN_B;
  output F_WEN_B;
  input  F_RB_B;
  /////////////////////////////////////////////////////////////
 reg [3:0] cur_st, nxt_st; 
 parameter IDLE = 4'd0,
			CMD_PRE = 4'd1,
			CMD = 4'd2,
			ADDR1_PRE = 4'd3,
			ADDR1 = 4'd4,
			ADDR2_PRE = 4'd5,
			ADDR2 = 4'd6,
			ADDR3_PRE = 4'd7,
			ADDR3 = 4'd8,
			DATA_PRE = 4'd9,
			DATA = 4'd10,
			CMD_FINISH_PRE = 4'd11,
			CMD_FINISH = 4'd12,
			DONE = 4'd13;
///////////////////////////////////////////////////////////////
reg [8:0] counter_index, counter_page;
reg [7:0] F_IO_A_comb, F_IO_B_comb;

reg F_CLE_A, F_ALE_A, F_REN_A, F_WEN_A;
reg F_CLE_B, F_ALE_B, F_REN_B, F_WEN_B;

reg done;

///////////////////////////////////////////////////////////////
always@(posedge clk or posedge rst)
if(rst)
	cur_st <= IDLE;
else
	cur_st <= nxt_st;
	
	
always@(*)
begin
case(cur_st)
	IDLE : nxt_st = CMD_PRE;
	CMD_PRE : nxt_st = CMD;
	CMD : nxt_st = ADDR1_PRE;
	ADDR1_PRE : nxt_st = ADDR1;
	ADDR1 : nxt_st = ADDR2_PRE;
	ADDR2_PRE : nxt_st = ADDR2;
	ADDR2 : nxt_st = ADDR3_PRE;
	ADDR3_PRE : nxt_st = ADDR3;
	ADDR3 : nxt_st = (F_RB_A)? DATA_PRE : ADDR3;
	DATA_PRE : nxt_st = DATA;
	DATA : nxt_st = (counter_index==9'd511)? CMD_FINISH_PRE : DATA_PRE;
	CMD_FINISH_PRE : nxt_st = CMD_FINISH;
	CMD_FINISH : nxt_st = (F_RB_B)? (counter_page==9'd511)? DONE : IDLE  : CMD_FINISH;
	default : nxt_st = DONE;
endcase
end

always@(posedge clk or posedge rst)
if(rst)
	counter_index <= 0;
else if(cur_st==DATA)
	counter_index <= counter_index + 1;
	
always@(posedge clk or posedge rst)
if(rst)
	counter_page <= 0;
else if(cur_st==CMD_FINISH)
	counter_page <= counter_page + 1;


//////A//////	
always@(posedge clk or posedge rst)
if(rst)
	F_CLE_A <= 0;
else if(nxt_st==CMD_PRE || nxt_st==CMD)
	F_CLE_A <= 1;
else
	F_CLE_A <= 0;
	
always@(posedge clk or posedge rst)
if(rst)
	F_ALE_A <= 0;
else if(nxt_st==ADDR1_PRE || nxt_st==ADDR1 || nxt_st==ADDR2_PRE || nxt_st==ADDR2 || nxt_st==ADDR3_PRE || nxt_st==ADDR3)
	F_ALE_A <= 1;
else
	F_ALE_A <= 0;

always@(posedge clk or posedge rst)
if(rst)
	F_REN_A <= 1;
else if(nxt_st==DATA_PRE)
	F_REN_A <= 0;
else
	F_REN_A <= 1;

always@(posedge clk or posedge rst)
if(rst)
	F_WEN_A <= 1;
else if(nxt_st==CMD_PRE || nxt_st==ADDR1_PRE || nxt_st==ADDR2_PRE || nxt_st==ADDR3_PRE)
	F_WEN_A <= 0;
else
	F_WEN_A <= 1;
////////////////	

//////B/////////
always@(posedge clk or posedge rst)
if(rst)
	F_CLE_B <= 0;
else if(nxt_st==CMD_PRE || nxt_st==CMD || nxt_st==CMD_FINISH_PRE || nxt_st==CMD_FINISH)
	F_CLE_B <= 1;
else
	F_CLE_B <= 0;

always@(posedge clk or posedge rst)
if(rst)
	F_ALE_B <= 0;
else if(nxt_st==ADDR1_PRE || nxt_st==ADDR1 || nxt_st==ADDR2_PRE || nxt_st==ADDR2 || nxt_st==ADDR3_PRE || nxt_st==ADDR3)
	F_ALE_B <= 1;
else
	F_ALE_B <= 0;

always@(posedge clk or posedge rst)
if(rst)
	F_REN_B <= 1;
else
	F_REN_B <= 1;
	
always@(posedge clk or posedge rst)
if(rst)
	F_WEN_B <= 1;
else if(nxt_st==CMD_PRE || nxt_st==ADDR1_PRE || nxt_st==ADDR2_PRE || nxt_st==ADDR3_PRE || nxt_st==DATA_PRE || nxt_st==CMD_FINISH_PRE)
	F_WEN_B <= 0;
else
	F_WEN_B <= 1;
/////////////////

//////////////DATA/////////////
always@(*)
begin
case(cur_st)
	CMD_PRE, CMD : begin
						F_IO_A_comb = 8'h00;
						F_IO_B_comb = 8'h80;
					end
	ADDR1_PRE, ADDR1 : begin
							F_IO_A_comb = 8'h00;
							F_IO_B_comb = 8'h00;
						end
	ADDR2_PRE, ADDR2 : begin
							F_IO_A_comb = counter_page[7:0];
							F_IO_B_comb = counter_page[7:0];
						end
	ADDR3_PRE, ADDR3 : begin
							F_IO_A_comb = {7'd0,counter_page[8]};
							F_IO_B_comb = {7'd0,counter_page[8]};
						end
	DATA_PRE, DATA : begin
							F_IO_A_comb = 'bz;
							F_IO_B_comb = F_IO_A;
						end
	CMD_FINISH_PRE, CMD_FINISH : begin
									F_IO_A_comb = 'bz;
									F_IO_B_comb = 8'h10;
								end
	default : begin
				F_IO_A_comb = 'bz;
				F_IO_B_comb = 'bz;
				end
endcase
end

assign F_IO_A = F_IO_A_comb;
assign F_IO_B = F_IO_B_comb;
////////////////////////////////


always@(posedge clk or posedge rst)
if(rst)
	done <= 0;
else if(cur_st==DONE)
	done <= 1;
else
	done <= 0;

endmodule
