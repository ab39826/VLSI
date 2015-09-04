module TOP(
PSEL,
PWRITE,
PWDATA,
PRDATA,
CLEAR_B,
PCLK);

parameter DATA_WIDTH = 8;

   wire PSEL, PWRITE,  CLEAR_B;
   wire PCLK;
   wire [DATA_WIDTH -1:0] PWDATA;
   wire [DATA_WIDTH-1:0] TxDaty;
   wire SSPTXINTR;
   wire SSPTXEMPTY;
   wire SSPOE_B;
   wire SSPTXD;
   wire SSPFSSOUT;
   wire SSPCLKOUT;
   wire ready;
   wire SPOEB;  
   wire [DATA_WIDTH -1:0] PRDATA; 
   wire [DATA_WIDTH-1:0] RxData;   
	
input PCLK;	
input PWRITE;
input [DATA_WIDTH -1: 0] PWDATA;
input CLEAR_B;
input PSEL;

output [DATA_WIDTH -1 : 0] PRDATA;

/*
    

always begin
	#3 PCLK = !PCLK;

end

initial
      begin
         
	PSEL = 1;
 	PWRITE = 0;
	PWDATA = 8'hA7;
	CLEAR_B = 1;
	PCLK = 0;
			
	#1
	PWRITE = 1;
	PWDATA = 8'hA4;
	#6

	PWRITE = 0;	
	PWDATA = 8'hB6;

	#6

	PWRITE = 1;
	PWDATA = 8'hC7;
	#6
	PWRITE = 0;
	PWDATA = 8'hF2;
        CLEAR_B = 0;
	#6

	PWDATA = 8'h23;
	 
      end

   // Run simulation for 15 ns.  
   initial #265 $finish;
   
   // Dump all waveforms to d_latch.dump
   initial
      begin
         $dumpfile ("ssptop.dump");
         $dumpvars (0, TOP);
      end // initial begin
*/
tlogic tloge(SSPOE_B,SSPTXD,SSPFSSOUT,SSPCLKOUT,PCLK,TxDaty,SSPTXEMPTY,ready,eightBity,loadReady,RxData);
txfifo tFife(PSEL, PWRITE, PWDATA, CLEAR_B, PCLK, TxDaty, SSPTXINTR, SSPTXEMPTY, ready,eightBity);

rxfifo rxfify(PSEL,PWRITE,PRDATA,CLEAR_B,PCLK,RxData,SSPRXINTR,SSPRXEMPTY,loadReady);


endmodule

module tlogic (
SSPOE_B,
SSPTXD,
SSPFSSOUT,
SSPCLKOUT,
PCLK,
TxData,
SSPTXEMPTY,
ready,
eightBity,
loadReady,
RxData);

parameter DATA_WIDTH = 8;


input PCLK;
input [DATA_WIDTH -1: 0] TxData;
input SSPTXEMPTY;

output SSPOE_B;
output SSPTXD;
output SSPFSSOUT;
output SSPCLKOUT;
output ready; 
output  eightBity;
output loadReady;
output [DATA_WIDTH -1: 0] RxData;

wire PCLK;
wire SSPTXEMPTY;


/*Output registers*/
reg SSPFSSOUT; //these might be regs. make sure later
reg SSPCLKOUT;
reg SSPTXD;
reg SSPOE_B;
reg ready;


/*Internal variables*/
reg [DATA_WIDTH -1 :0] TLRegister;
reg [DATA_WIDTH -1 :0] eightBitcounter;
assign eightBity = (eightBitcounter == 7);

initial begin
ready = 1;
SSPTXD =0;
SSPFSSOUT = 0;
SSPCLKOUT = 0;
TLRegister = 0;
eightBitcounter =0;
SSPOE_B = 1;
end

always @( posedge PCLK) begin: SSPCLK_logic
	SSPCLKOUT <= !(SSPCLKOUT);
end

always @( SSPCLKOUT) begin: SPOE_b_logic
if(!SSPCLKOUT) begin
if(eightBitcounter == 0)begin
  SSPOE_B <= 0; 
end 
else if (eightBitcounter == 7) begin
  SSPOE_B <= 1;
end

end
end



always @( SSPCLKOUT) begin: eight_bit_counter
if(SSPCLKOUT) begin
if(!ready)begin
  eightBitcounter <= eightBitcounter +1;
end else if(ready) begin
eightBitcounter <= 0;
end
end
end

always @(posedge PCLK) begin: ready_logic
if(SSPCLKOUT) begin
if(SSPFSSOUT)begin
  ready <= 0;
end
else if(eightBitcounter  == 7)begin
	ready <= 1; 
end
end
end

always @(SSPCLKOUT) begin: fssout_logic
if(SSPCLKOUT) begin
if((!SSPTXEMPTY) &&(ready))begin
SSPFSSOUT <= 1;
end
else begin
SSPFSSOUT <= 0;
end
end
end

always@(SSPCLKOUT) begin: TLReg_logic
if(SSPCLKOUT) begin
if((!SSPTXEMPTY) &&(ready))begin
TLRegister <= TxData;  
end

if(!ready)begin
SSPTXD <= TLRegister[7];
TLRegister <= {TLRegister[6:0], 1'b0};
end

end
end

//now need to take care of SSPOE_B
rlogic rlogica(SSPCLKOUT,SSPFSSOUT,SSPTXD,loadReady,RxData);
endmodule

module txfifo (
PSEL,
PWRITE,
PWDATA,
CLEAR_B,
PCLK,
TxData,
SSPTXINTR,
SSPTXEMPTY,
ready,
bC);

parameter DATA_WIDTH = 8;
parameter FIFO_SIZE = 4;

//Input Variables
input PSEL;
input PWRITE;
input [DATA_WIDTH-1:0] PWDATA;
input CLEAR_B;
input PCLK;
input ready;
input  bC;


//Output Variables
output [DATA_WIDTH -1:0] TxData;
output SSPTXINTR; //interrupt signal when full
output SSPTXEMPTY;     // interrupt signal when empty
wire SSPTXINTR;
wire SSPTXEMPTY;
wire CLEAR_B;




// Internal Variables
reg [DATA_WIDTH -1:0] Tx1; //registers in FIFO. TXL is the thing that drives the output (TxData for logic operations in the Tranfer Logic block)
reg [DATA_WIDTH -1:0] Tx2;
reg [DATA_WIDTH -1:0] Tx3;
reg [DATA_WIDTH -1:0] Tx4;

reg [FIFO_SIZE -1 : 0] FIFOPOINTER;
reg [FIFO_SIZE -1 : 0] fifoCounter;
reg eightFlag;

assign SSPTXINTR = (FIFOPOINTER == FIFO_SIZE +1);
assign SSPTXEMPTY = (FIFOPOINTER == 1);


assign TxData = Tx1;

initial begin
FIFOPOINTER = 1;
Tx1 = 0;
Tx2 = 0;
Tx3 = 0;
Tx4 = 0;
end

always@(posedge PCLK) begin: eight_bito
 
if((bC ==1) &&(!eightFlag))begin
eightFlag <= 1;
end
else begin
eightFlag <=0;
end

end 

always@(posedge PCLK)begin: update_pointer
if (!(CLEAR_B)) begin
FIFOPOINTER <=0;
Tx1 <= 0;
Tx2 <= 0;
Tx3 <= 0;
Tx4 <= 0;
end else if(eightFlag) begin
//(!SSPTXEMPTY)&&(ready)
FIFOPOINTER <= FIFOPOINTER -1;

  Tx1 <= Tx2;
    Tx2 <= Tx3; 
    Tx3 <= Tx4;
end  else if( PSEL && PWRITE && (!SSPTXINTR)) begin
FIFOPOINTER <= FIFOPOINTER +1;
case(FIFOPOINTER)
1: Tx1 <= PWDATA;
2: Tx2 <= PWDATA;
3: Tx3 <= PWDATA;
4: Tx4 <= PWDATA;
endcase


end
end



endmodule


module rlogic (
SSPCLKIN,
SSPFSSIN,
SSPRXD,
loadReady,
RxL);

parameter DATA_WIDTH = 8;

input SSPCLKIN;
input SSPRXD;
input SSPFSSIN;

output loadReady;
output[DATA_WIDTH -1:0] RxL;

reg [DATA_WIDTH-1:0] RxL;
reg[DATA_WIDTH-1:0] eightCount;
reg shifty;
reg loadReady;


initial begin
RxL <= 0;
eightCount <=0;
end

always@(posedge SSPCLKIN)begin:counter_logic
if(SSPFSSIN)begin
eightCount <= 0;
shifty <= 1;
end
else if (eightCount == 7)begin
eightCount <=0;
shifty <=0;
end else if(shifty ==1) begin 
eightCount <= eightCount +1;
end
end

always @(posedge SSPCLKIN)begin
if((shifty == 1) &&(eightCount ==7))begin
loadReady <= 1;
end
else begin 
loadReady <= 0;
end
end



always@(posedge SSPCLKIN)begin:shift_reg_logic
RxL[7] <= RxL[6];
RxL[6] <= RxL[5];
RxL[5] <= RxL[4];
RxL[4] <= RxL[3];
RxL[3] <= RxL[2];
RxL[2] <= RxL[1];
RxL[1] <= RxL[0];
RxL[0] <= SSPRXD;
end

endmodule


module rxfifo (
PSEL,
PWRITE,
PRDATA,
CLEAR_B,
PCLK,
RxData,
SSPRXINTR,
SSPRXEMPTY,
loadReady);

parameter DATA_WIDTH = 8;
parameter FIFO_SIZE = 4;

//Input Variables
input PSEL;
input PWRITE;
input CLEAR_B;
input PCLK;
input [DATA_WIDTH -1:0] RxData;
input loadReady;


//Output Variables
output SSPRXINTR; //interrupt signal when full
output SSPRXEMPTY;     // interrupt signal when empty
output [DATA_WIDTH-1:0] PRDATA;

wire SSPRXINTR;
wire SSPRXEMPTY;
wire CLEAR_B;




// Internal Variables
reg [DATA_WIDTH -1:0] Rx1; //registers in FIFO. TXL is the thing that drives the output (TxData for logic operations in the Tranfer Logic block)
reg [DATA_WIDTH -1:0] Rx2;
reg [DATA_WIDTH -1:0] Rx3;
reg [DATA_WIDTH -1:0] Rx4;

reg [FIFO_SIZE -1 : 0] FIFOPOINTER;


assign SSPRXINTR = (FIFOPOINTER == FIFO_SIZE +1);
assign SSPRXEMPTY = (FIFOPOINTER == 1);


assign PRDATA = Rx1;

initial begin
FIFOPOINTER = 1;
Rx1 = 0;
Rx2 = 0;
Rx3 = 0;
Rx4 = 0;
end

always@(posedge PCLK)begin: update_pointer
if (!(CLEAR_B)) begin
FIFOPOINTER <=0;
Rx1 <= 0;
Rx2 <= 0;
Rx3 <= 0;
Rx4 <= 0;
end else if(PSEL && (!PWRITE) &&(!SSPRXEMPTY)) begin
//(!SSPRXEMPTY)&&(ready)
FIFOPOINTER <= FIFOPOINTER -1;
  Rx1 <= Rx2;
    Rx2 <= Rx3; 
    Rx3 <= Rx4;
end  else if(PSEL && (!SSPRXINTR) && loadReady) begin
FIFOPOINTER <= FIFOPOINTER +1;
case(FIFOPOINTER)
1: Rx1 <= RxData;
2: Rx2 <= RxData;
3: Rx3 <= RxData;
4: Rx4 <= RxData;
endcase
end
end



endmodule