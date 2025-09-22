module mux(
  input a,b,c,d,
  input [1:0] sel,
  output reg y
);
  
  ////adding rtl logic
  always@(*)
    begin
      case(sel)
        2'b00: y = a;
        2'b01: y = b;
        2'b10: y = c;
        2'b11: y = d;
      endcase
    end
 
  
  //////adding assertion checks 
  always@(*)
   begin
      case(sel)
      2'b00: y_equal_a:assert(y == a) else $error("y is not equal to a at %0t",$time);
      2'b01: y_equal_b:assert(y == b) else $error("y is not equal to b at %0t",$time);
      2'b10: y_equal_c:assert(y == c) else $error("y is not equal to c at %0t",$time);
      2'b11: y_equal_d:assert(y == d) else $error("y is not equal to d at %0t",$time); 
      endcase
    end
  
endmodule