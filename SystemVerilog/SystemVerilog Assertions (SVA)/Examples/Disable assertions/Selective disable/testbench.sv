//////SIA do not support disable assertion
///// ODIA + FDIA support disable
 
module tb;
 
  
 reg a;
 reg rst;
 
  initial 
  begin
    rst = 1;
    #50;
    rst = 0;
  end
  
  initial 
  begin
    a = 0;
    #50;
    a = 1;
  end
  
  
  always@(*)
    begin
      if(rst == 1'b0)
        begin
        A1: assert (a == 1) $info("Success at %0t", $time); else $error("Failure at %0t", $time);
        end
    end
 
  
  /*
  always@(*)
    begin
      A1: assert final (a == 1) $info("Success at %0t", $time); else $error("Failure at %0t", $time);
      
      if(rst == 1'b1)
        disable A1;  
      
    end
*/
  
  
initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    #100;
    $finish;
  end
  
  
endmodule