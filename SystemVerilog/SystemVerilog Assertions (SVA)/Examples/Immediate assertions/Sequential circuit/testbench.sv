module tb;
  reg d = 0;
  reg clk = 0;
  reg rstn = 0;
  wire q, qbar;
  
  dff dut (d,rstn, clk, q, qbar);
  
  always #5 clk = ~clk;
  
  always #13 d = ~d;
  
  initial begin
    rstn = 0;
    #30;
    rstn = 1;
  end
  
  
    initial begin 
    #200;
    $finish();
  end
     
endmodule