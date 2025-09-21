module top (
input clk, wr,
input [3:0] addr,
input [7:0] din,
output reg [7:0] dout  
);
 
  reg [7:0] mem [16];
 
  ///first 4 locations store commands
  /// rest 12 locations store data
 
 
 
  always@(posedge clk)
    begin
      if(wr)
        mem[addr] <= din;
      else
        dout      <= mem[addr];
    end
 
 
endmodule
 
//////////////////////////////interface
 
 
interface top_if;
  
  logic clk, wr;
  logic [3:0] addr;
  logic [7:0] din;
  logic [7:0] dout ;
    
endinterface