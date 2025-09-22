module tb;
 
  
 reg a ;///x
 
  
  initial begin
    $assertoff();
    a = 0;
    #50;
    $asserton();
    a = 1;
  end
  
  always@(*)
    begin
      A1: assert (a == 1) $info("Success at %0t", $time); else $error("Failure at %0t", $time);
    end
  
  
initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    #100;
    $finish;
  end
   
endmodule