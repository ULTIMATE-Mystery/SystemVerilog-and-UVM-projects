class transaction;

  randc bit [1:0] opmode; /// write = 0, read = 1, random = 2
  rand bit we;
  rand bit strb;
  rand bit [7:0] addr;
  rand bit [7:0] wdata;
  bit [7:0] rdata;
  bit ack;
   
   constraint opmode_c {
   opmode >= 0; opmode < 3;
   }
  
   constraint addr_c {
     addr == 7;
   }
   
    function transaction copy();
    copy       = new();
    copy.opmode  = this.opmode;
    copy.we    = this.we;
    copy.strb  = this.strb;
    copy.addr  = this.addr;
    copy.wdata = this.wdata;
    copy.rdata = this.rdata;
    copy.ack   = this.ack;
    endfunction
  
  function void display(input string tag);
    $display("[%0s]: MODE: %0d WE: %0b STRB: %0b ADDR: %0d WDATA: %0d RDATA: %0d", tag, opmode, we,strb,addr,wdata,rdata);
  endfunction
  
  
endclass

/////////////////////////////////////////////////////////////////////////


class generator;
  
  transaction tr;
  mailbox #(transaction) mbxgd;
  event done; /// gen completed sending requested no. of transaction
  event drvnext; /// drv complete its work;
  event sconext; /// scoreboard complete its work
 
   int count = 0;
  
  function new( mailbox #(transaction) mbxgd);
    this.mbxgd = mbxgd;   
    tr =new();
  endfunction
  
    task run();
    
      for(int i=0; i< count; i++) begin
      assert(tr.randomize) else $error("Randomization Failed"); 
      $display("------------------------------------------");
      tr.display("GEN");
      mbxgd.put(tr.copy); 
      @(drvnext);
      @(sconext);
      end
      
    ->done;
      
  endtask
  
   
endclass
///////////////////////////////////////////////////////////

class driver;

virtual wb_if vif;
transaction tr;
event drvnext;

  mailbox #(transaction) mbxgd;

  
  function new( mailbox #(transaction) mbxgd );
    this.mbxgd = mbxgd; 
  endfunction
  
   task reset();
   vif.rst   <= 1'b1;
   vif.we    <= 0;
   vif.addr  <= 0;
   vif.wdata <= 0;
   vif.strb  <= 0;
   repeat(10) @(posedge vif.clk);
   vif.rst <= 1'b0;
   repeat(5) @(posedge vif.clk);
   $display("[DRV]: RESET DONE");
  endtask

  task write();
  @(posedge vif.clk);
  $display("[DRV]: DATA WRITE MODE");
  vif.rst   <= 1'b0;
  vif.we    <= 1'b1;
  vif.strb  <= 1'b1;
  vif.addr  <= tr.addr;
  vif.wdata <= tr.wdata;
  @(posedge vif.ack);
  @(posedge vif.clk);
  ->drvnext;
  endtask
  
  task read();
  @(posedge vif.clk);
  $display("[DRV]: DATA READ MODE");
  vif.rst   <= 1'b0;
  vif.we    <= 1'b0;
  vif.strb  <= 1'b1;
  vif.addr  <= tr.addr;
  @(posedge vif.ack);
  @(posedge vif.clk);
  ->drvnext;
  endtask
  
  task random();
  @(posedge vif.clk);
  $display("[DRV]: RANDOM MODE");
  vif.rst   <= 1'b0;
  vif.we    <= tr.we;
  vif.strb  <= tr.strb;
  vif.addr  <= tr.addr;
  if(tr.we == 1'b1)
  begin
  vif.wdata <= tr.wdata;
  end
  repeat(2)@(posedge vif.clk);
  ->drvnext;
  endtask
  
  
  task run();
   forever begin
     mbxgd.get(tr);
     if(tr.opmode == 0) 
     begin
       write();
     end  
     else if (tr.opmode == 1) 
     begin
       read();
     end  
     else if(tr.opmode == 2) 
     begin
       random();
     end  
   end
  endtask
  
 
endclass

////////////////////////////////////////////////

class monitor;
    
  virtual wb_if vif;
  transaction tr;
  
  mailbox #(transaction) mbxms;

  
  function new( mailbox #(transaction) mbxms );
    this.mbxms = mbxms;
  endfunction
  
  
  task run();
    
    tr = new();
    
    wait (vif.rst == 1'b0); 
    repeat(5) @(posedge vif.clk);
    
    forever begin 
        @(posedge vif.clk);
        #1;
        if(vif.strb == 1'b0)
        begin
        tr.strb = vif.strb;
        repeat(2) @(posedge vif.clk);
        $display("[MON]: STRB IS ZERO");
        mbxms.put(tr);  
        end
        else
        begin
        @(posedge vif.ack);
        tr.we = vif.we;
        tr.strb = vif.strb;
        tr.wdata = vif.wdata;
        tr.addr = vif.addr;
        tr.rdata = vif.rdata; 
        @(posedge vif.clk);
        $display("[MON]: STRB IS VALID");
        mbxms.put(tr);  
        end
      end 
  endtask

endclass
///////////////////////////////////////////////////////////////

class scoreboard;
  transaction tr;
  event sconext;
  
  mailbox #(transaction) mbxms;
  
  bit [7:0] data[256] = '{default:0};
  
    
  function new( mailbox #(transaction) mbxms );
    this.mbxms = mbxms;
  endfunction
  
  task run();
   forever begin
    mbxms.get(tr);
    if(tr.strb == 1'b0) 
            begin
            $display("[SCO]: INVALID STROBE");
            end
    else 
      begin
          
          if(tr.we == 1'b1)
                      begin
                       data[tr.addr] = tr.wdata;
                        $display("[SCO]: DATA WRITE ADDR: %0d DATA: %0d", tr.addr, tr.wdata);
                      end  
          else 
             begin
                    if (tr.rdata == data[tr.addr])
                     begin
                       $display("[SCO]: DATA MATCHED ADDR: %0d RDATA: %0d", tr.addr, tr.rdata);
                     end
                     else
                     begin
                       $display("[SCO]: DATA MISMATCHED ADDR: %0d RDATA: %0d EXPECTED RDATA: %0d", tr.addr, tr.rdata, data[tr.addr]);
                     end 
             end
        end
      $display("------------------------------------------");
     ->sconext; 
   end
  endtask
endclass

///////////////////////////////////////////////////

module tb;
   
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;

  event drvnext, sconext;
  event done;
  
  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxms;
  
  wb_if vif();
  mem_wb dut (vif.clk, vif.we, vif.strb, vif.rst, vif.addr, vif.wdata, vif.rdata, vif.ack);
 
  initial begin
    vif.clk <= 0;
  end
  
  always #5 vif.clk <= ~vif.clk;
  
  initial begin

    mbxgd = new();
    mbxms = new();
    gen = new(mbxgd);
    drv = new(mbxgd);
    mon = new(mbxms);
    sco = new(mbxms);
    gen.count = 20;
    drv.vif = vif;
    mon.vif = vif;
    
    drv.drvnext = drvnext;
    gen.drvnext = drvnext;
    
    gen.sconext = sconext;
    sco.sconext = sconext;
    
  end
  
  initial begin
      drv.reset();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_none  
    wait(gen.done.triggered);
    $finish();
  end
   
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;   
  end
 
endmodule