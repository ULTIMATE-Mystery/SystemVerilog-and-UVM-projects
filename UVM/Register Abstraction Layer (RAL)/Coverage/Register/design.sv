module top(
input clk, rst,
input wr,addr,
  input [7:0] din,
  output [7:0] dout
);
  
  reg [7:0] tempin;
  reg [7:0] tempout;
  
  always@(posedge clk)
    begin
      if(rst)
        begin
        tempin <= 8'h00;
        tempout <= 8'h00;  
        end  
      else if (wr == 1'b1)
        begin
          if(addr == 1'b0)
           tempin <= din;
          end  
      else if(wr == 1'b0)
           if(addr == 1'b0)
           tempout <= tempin;
          end  
        
  
  assign dout = tempout;
  
endmodule
 
 
//////////////////////////////////////
 
interface top_if ;
  
  logic clk, rst;
  logic wr;
  logic addr;
  logic [7:0] din;
  logic [7:0] dout;
  
  
endinterface