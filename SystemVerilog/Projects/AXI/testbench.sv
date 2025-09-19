//////////////////////////Testbench Components
/////////////////////////////////////////////////

class transaction;
  
  rand bit [3:0] id;
  
  rand bit awvalid;
  bit awready;
  bit [3:0] awid;
  rand bit [3:0] awlen;
  rand bit [2:0] awsize; //4byte =010
  rand bit [31:0] awaddr;
  rand bit [1:0] awburst;
  
  bit wvalid;
  bit wready;
  bit [3:0] wid;
  rand bit [31:0] wdata;
  rand bit [3:0] wstrb;
  bit wlast;
  
  bit bready;
  bit bvalid;
  bit [3:0] bid;
  bit [1:0] bresp;
  
  
  rand bit arvalid;  /// master is sending new address  
  bit arready;  /// slave is ready to accept request
  bit [3:0] arid; ////// unique ID for each transaction
  rand bit [3:0] arlen; ////// burst length AXI3 : 1 to 16, AXI4 : 1 to 256
  bit [2:0] arsize; ////unique transaction size : 1,2,4,8,16 ...128 bytes
  rand bit [31:0] araddr; ////write adress of transaction
  rand bit [1:0] arburst; ////burst type : fixed , INCR , WRAP
  
  /////////// read data channel (r)
  
  bit rvalid; //// master is sending new data
  bit rready; //// slave is ready to accept new data 
  bit [3:0] rid; /// unique id for transaction
  bit [31:0] rdata; //// data 
  bit [3:0] rstrb; //// lane having valid data
  bit rlast; //// last transfer in write burst
  bit [1:0] rresp; ///status of read transfer

 /* 
  constraint adr_c {
   awvalid == 0;
   arvalid == 1; 
  
  }
  */
  
  constraint valid_c {
   arvalid != awvalid;
  }
  
  constraint addr_c {
   awaddr == 5;
  //awaddr > 0; awaddr < 15;
   
  }
  
  constraint awsize_c {
  
  awsize >= 0; awsize < 3;
  }
  
  constraint awburst_c {
   awburst == 2;
  //awburst >= 0; awburst < 3; 
  }
  
  
  constraint arlen_c {
    arlen > 0; arlen <= 7;
  }
  
  
  constraint araddr_c {
    araddr == 5;
   // araddr > 0; araddr <= 7;
  }
  
  constraint arburst_c {
  arburst == 2;
  //arburst >= 0; arburst < 3; 
  }
  
endclass



//////////////////////////////////
class generator;
  
  transaction tr;
  mailbox #(transaction) mbxgd;
  
  event done; ///gen completed sending requested no. of transaction
  event drvnext; /// dr complete its wor;
  event sconext; ///scoreboard complete its work
 
   int count = 0;
  
  function new( mailbox #(transaction) mbxgd);
    this.mbxgd = mbxgd;   
    tr =new();
  endfunction
  
    task run();
    
    for(int i=0; i <= count; i++) begin
      assert(tr.randomize) else $error("Randomization Failed"); 
      
      if(tr.awburst == 2'b10)
        begin
          tr.awlen = 4'b0111;
        end
      
      
      if(tr.arburst == 2'b10)
        begin
          tr.arlen = 4'b0111;
        end
      
     // $display("[GEN] : WRITE : %0b READ : %0b BURST MODE : %0d",tr.awvalid, tr.arvalid, tr.awburst);
      $display("[GEN] : WR :%0b RD:%0b WRBUR : %0d RDBUR: %0d WRADDR :%0d RDADDR : %0d WLEN :%0d RLEN :%0d",tr.awvalid, tr.arvalid, tr.awburst, tr.arburst, tr.awaddr, tr.araddr, tr.awlen, tr.arlen);
      mbxgd.put(tr);
      @(drvnext);
      @(sconext);
    end
    ->done;
  endtask
  
   
endclass


/////////////////////////////////////


class driver;
  
  virtual axi_if vif;
  
  transaction tr;
  
  event drvnext;
  event monnext;
  
  mailbox #(transaction) mbxgd;

  
  function new( mailbox #(transaction) mbxgd );
    this.mbxgd = mbxgd; 
  endfunction
  
  //////////////////Resetting System
  task reset();
    
     vif.resetn <= 1'b0;
      
     vif.awvalid <= 1'b0;
     vif.awid <= 0;
     vif.awlen <= 0;
     vif.awsize <= 0;
     vif.awaddr <= 0;
     vif.awburst <= 0;
     
     vif.wvalid <= 0;
     vif.wid <= 0;
     vif.wdata <= 0;
     vif.wstrb <= 0;
     vif.wlast <= 0;
    
     vif.bready <= 0;

    
     vif.arvalid <= 1'b0;
     vif.arid <= 0;
     vif.arlen <= 0;
     vif.arsize <= 0;
     vif.araddr <= 0;
     vif.arburst <= 0;
    
    repeat(5) @(posedge vif.clk);
    vif.resetn <= 1'b1;
    $display("[DRV] : RESET DONE"); 
  endtask
  
  
  ///////////////////////////////write data in Fixed Mode 
  task fixed_write(input transaction tr);
      int len = 0;
      len = tr.awlen + 1;  //8
      $display("[DRV] : FIXED MODE -> DATA WRITE DONE");
      @(posedge vif.clk);     
      vif.resetn <= 1'b1;
      vif.awvalid <= 1'b1;
      vif.arvalid <= 1'b0;  ////disable read
      vif.awid    <= tr.id;
      vif.awlen   <= tr.awlen;
      vif.awsize  <= 3'b010;   ///4 byte 
      vif.awburst <= 2'b00;   //00
      vif.wvalid <= 1'b1;
      vif.wid    <= tr.id; 
      vif.wstrb  <= 4'b1111;
      vif.bready <= 1'b1;
      vif.awaddr  <= tr.awaddr;
      vif.wdata  <= $urandom_range(1,100);
      
      @(posedge vif.wready);
      @(posedge vif.clk);
    
    
    for(int i = 1; i< len ; i++) begin /// 1 2 3 4 5 6 7
      vif.awaddr  <= tr.awaddr;
      vif.wdata  <= $urandom_range(1,100);
      @(posedge vif.wready);
      @(posedge vif.clk);
      end
      
      vif.wlast  <= 1'b1;
      vif.awvalid <= 1'b0;
      vif.arvalid <= 1'b0;
      vif.wvalid   <= 1'b0;
      @(posedge vif.clk);
      vif.wlast  <= 1'b0;
      @(negedge vif.bvalid);
      ->drvnext;
     endtask
  
  ///////////////////////////Write data in Incr Mode //////
   
  task incr_write(input transaction tr);
      int len = 0;
      len = tr.awlen + 1;  //8
       $display("[DRV] : INCR MODE -> DATA WRITE DONE");
      @(posedge vif.clk);
      vif.resetn <= 1'b1;
      vif.arvalid <= 1'b0; ////disable read 
      vif.awvalid <= 1'b1;
      vif.awid    <= tr.id;
      vif.awlen   <= tr.awlen;
      vif.awsize  <= 3'b010;    
      vif.awburst <= 2'b01;   
      vif.wvalid <= 1'b1;
      vif.wid    <= tr.id; 
      vif.wstrb  <= 4'b1111;
      vif.bready <= 1'b1;
      vif.awaddr  <= tr.awaddr;
      vif.wdata  <= $urandom_range(1,100);
      
      @(posedge vif.wready);
      @(posedge vif.clk);
    
   for(int i = 1; i< len; i++) begin  ///i < 8  1 2 3 4 5 6 7
      vif.awaddr  <= tr.awaddr + 4*i;
      vif.wdata  <= $urandom_range(1,100);
      @(posedge vif.wready);
      @(posedge vif.clk);
    end
      
      vif.wlast   <= 1'b1;  
      vif.awvalid <= 1'b0;
      vif.arvalid <= 1'b0;
      vif.wvalid  <= 1'b0;
      @(posedge vif.clk);
      vif.wlast  <= 1'b0;
      @(negedge vif.bvalid);
   
    
      ->drvnext;
     endtask
  
   //////////////////////////////Write data in Wrap Mode
  
    task wrap_write(input transaction tr);
      int len = 0;
      len = tr.awlen + 1;  //8
      $display("[DRV] : WRAP MODE -> DATA WRITE DONE");
      @(posedge vif.clk);
      vif.arvalid <= 1'b0;  ///disable read
      vif.resetn <= 1'b1;
      vif.awvalid <= 1'b1;
      vif.awid    <= tr.id;
      vif.awlen   <= tr.awlen;
      vif.awsize  <= 3'b010;    
      vif.awburst <= 2'b10;   
      vif.wvalid <= 1'b1;
      vif.wid    <= tr.id; 
      vif.wstrb  <= 4'b1111;
      vif.bready <= 1'b1;
      
      
      vif.awaddr <= tr.awaddr;
      vif.wdata  <= $urandom_range(1,100);
      @(posedge vif.wready);
      @(posedge vif.clk);
    
      for(int i = 0; i < 7; i++) begin  ///0 1 2 3 4 5 6
      vif.awaddr  <= vif.addr_wrapwr;
      vif.wdata  <= $urandom_range(1,100);
      @(posedge vif.wready);
      @(posedge vif.clk);
      end
      
      vif.wlast  <= 1'b1;  
      @(posedge vif.clk);
      vif.wlast  <= 1'b0;
      vif.awvalid <= 1'b0;
      vif.arvalid <= 1'b0;
      vif.wvalid  <= 1'b0;
      @(negedge vif.bvalid);
   
      ->drvnext;
     endtask
  
  /////////////////////////////////read fixed mode
  
  task fixed_read(input transaction tr);
    
    int len = 0;
    len = tr.arlen + 1; //8
    $display("[DRV] : FIXED MODE -> DATA READ");
      @(posedge vif.clk);
      vif.awvalid <= 1'b0;  /////disable write transaction
      vif.resetn  <= 1'b1;
      vif.arvalid <= 1'b1;
      vif.arid    <= tr.id;
      vif.arlen   <= tr.arlen;
      vif.arsize  <= 3'b010;    
      vif.arburst <= 2'b00;
      vif.rready  <= 1'b1;
        
      for(int i = 0; i < len; i++) begin // 0 1  2 3 4 5 6 7
       vif.araddr  <= tr.araddr;
       @(posedge vif.arready);
       @(posedge vif.clk);
      end
       
     @(negedge vif.rlast);
     vif.arvalid <= 1'b0;
     vif.rready  <= 1'b0;
     
    ->drvnext;
    
    
    
  endtask
  
  
  
  ///////////////////////////////read incr mode
  
    task incr_read(input transaction tr);
      
      int len = 0;
      len = tr.arlen + 1;
      $display("[DRV] : INCR MODE -> DATA READ");
      @(posedge vif.clk);
      vif.awvalid <= 1'b0;  /////disable write transaction
      vif.resetn  <= 1'b1;
      vif.arvalid <= 1'b1;
      vif.arid    <= tr.id;
      vif.arlen   <= tr.arlen;
      vif.arsize  <= 3'b010;    
      vif.arburst <= 2'b01;
      vif.rready  <= 1'b1;
      
  
        
      for(int i = 0; i< len; i++) begin
       vif.araddr  <= tr.araddr + 4*i;
       @(posedge vif.arready);
       @(posedge vif.clk);
      end
       
     @(negedge vif.rlast);
     vif.arvalid <= 1'b0;
     vif.rready  <= 1'b0;
      
     ->drvnext;
    
    
    
  endtask
  
  
  
  //////////////////////////////////////////wrap mode
  
    task wrap_read(input transaction tr);
    
      int len = 0;
      len = 8;
      $display("[DRV] : WRAP MODE -> DATA READ COMPLETE");
      @(posedge vif.clk);
      vif.awvalid <= 1'b0;  /////disable write transaction
      vif.resetn  <= 1'b1;
      vif.arvalid <= 1'b1;
      vif.arid    <= tr.id;
      vif.arlen   <= 4'b0111;
      vif.arsize  <= 3'b010;    
      vif.arburst <= 2'b10;
      vif.rready  <= 1'b1;     
      vif.araddr  <= tr.araddr;
      @(posedge vif.rvalid);
      @(posedge vif.clk);
      
 
  
        
      for(int i = 0; i< 7; i++) begin /// 0123456  
        vif.araddr  <= vif.addr_wraprd;      
        @(posedge vif.rvalid);
        @(posedge vif.clk);
      end
       
     @(negedge vif.rlast);
     vif.arvalid <= 1'b0;
     vif.rready  <= 1'b0;

     ->drvnext;
    
  endtask
  
  ///////////////////////////////////////////////////////main task
  
  task run();
    
    forever begin
             
      mbxgd.get(tr);
     /////////////////////////write mode check and sig gen 
      if(tr.awvalid == 1'b1) begin
              if(tr.awburst == 2'b00)
                begin
                 fixed_write(tr);
                end
              else if (tr.awburst == 2'b01)
                begin
                incr_write(tr);
                end
              else if (tr.awburst == 2'b10)
                begin
                wrap_write(tr);
                end

      end   
     
     
   /////////////////////////////read mode check and sig gen
      
       if(tr.arvalid == 1'b1) begin
                 if(tr.arburst  == 2'b00)
                begin
                  fixed_read(tr);
                end
            else if (tr.arburst == 2'b01)
                begin
                incr_read(tr);
                end
            else if (tr.arburst == 2'b10)
                begin
                wrap_read(tr);
                end
                
          end  
    end
  endtask
  
    
  
endclass
///////////////////////////////////////////////////////
///////////////////////////////////////////////////

class monitor;
    
  virtual axi_if vif;

  
  transaction tr;

  event sconext;
  int len = 0;
  
  mailbox #(transaction) mbxms;

  
  function new( mailbox #(transaction) mbxms );
    this.mbxms = mbxms;
  endfunction
  
  
  task run();
    
    tr = new();
    
    forever 
      begin
        
        
      @(posedge vif.clk);
        
      //////////////////////////write logic  
        
    if(vif.awvalid == 1'b1) begin 
         len = vif.awlen + 1;  
         tr.awvalid = vif.awvalid;
         tr.arvalid = vif.arvalid;
         
         
      for(int i = 0; i< len; i++) begin
       @(posedge vif.wready); 
       @(posedge vif.clk);
       tr.awaddr = vif.awaddr;
       tr.wdata  = vif.wdata;
       tr.awburst = vif.awburst;   
       mbxms.put(tr);
       $display("[MON] : ADDR : %0x DATA : %0x BURST TYPE : %0d",tr.awaddr, tr.wdata, tr.awburst);    
      end
       
      @(posedge vif.clk);
      @(negedge vif.bvalid);
      @(posedge vif.clk);
      $display("[MON] : Transaction Complete");  
   end

     /////////////////////read logic   
        
       if(vif.arvalid == 1'b1)
        begin
         len = vif.arlen + 1;    
         tr.awvalid = vif.awvalid;
         tr.arvalid = vif.arvalid;
         
     
      for(int i = 0; i< len; i++) begin  
       @(posedge  vif.rvalid);
       @(posedge vif.clk);
       tr.rdata  = vif.rdata;
       tr.arburst = vif.arburst;
       tr.araddr = vif.araddr;
       mbxms.put(tr); 
       $display("[MON] : ADDR : %0x DATA : %0x BURST TYPE : %0d",tr.araddr, tr.rdata, tr.arburst);
       end
       
      @(posedge vif.clk);
      @(negedge vif.rlast);
      @(posedge vif.clk);
      $display("[MON] : Transaction Complete");
      end
       ->sconext; 
      end 
  endtask

  
  
endclass

///////////////////////////////////////


class scoreboard;
  
  transaction tr;
 
  
  mailbox #(transaction) mbxms;
  

  
  bit [31:0] temp;
  
  bit [7:0] data[128] = '{default:0};
  
  int count = 0;
  int len   = 0;
  

  
  function new( mailbox #(transaction) mbxms );
    this.mbxms = mbxms;
  endfunction
  
  
  task run();
    
    forever 
      begin  
        
      
      mbxms.get(tr);

      
     if(tr.awvalid == 1'b1) begin
        data[tr.awaddr]     = tr.wdata[7:0];
        data[tr.awaddr + 1] = tr.wdata[15:8];
        data[tr.awaddr + 2] = tr.wdata[23:16];
        data[tr.awaddr + 3] = tr.wdata[31:24]; 
        
        $display("[SCO] : DATA STORED ADDR :%0x and DATA :%0x", tr.awaddr, tr.wdata[7:0]);
        end     
        
        if(tr.arvalid == 1'b1) begin
            temp = {data[tr.araddr + 3],data[tr.araddr + 2],data[tr.araddr + 1],data[tr.araddr] };
           
        $display("[SCO] : DATA READ ADDR :%0x and DATA :%0x MEM :%0x", tr.araddr, tr.rdata, temp);
          
          if (tr.rdata == temp)
          begin
           $display("[SCO] : DATA MATCHED");
          end
          else
           begin
           $display("[SCO] : DATA MISMATCHED");
           end
      
        end
        
     
    end
  endtask
  
  
endclass


///////////////////////////////////////////////////

 module tb;
   
  monitor mon; 
  generator gen;
  driver drv;
  scoreboard sco;
   
   
  event nextgd;
  event nextgm;
  

  
  mailbox #(transaction) mbxgd, mbxms;
  
  axi_if vif();
  axi_slave dut (vif.clk, vif.resetn, vif.awvalid, vif.awready,  vif.awid, vif.awlen, vif.awsize, vif.awaddr,  vif.awburst, vif.wvalid, vif.wready, vif.wid, vif.wdata, vif.wstrb, vif.wlast, vif.bready, vif.bvalid, vif.bid, vif.bresp , vif.arready, vif.arid, vif.araddr, vif.arlen, vif.arsize, vif.arburst, vif.arvalid, vif.rid, vif.rdata, vif.rresp,vif.rlast,  vif.rvalid, vif.rready);
 
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
    
    drv.drvnext = nextgd;
    gen.drvnext = nextgd;
    
    gen.sconext = nextgm;
    mon.sconext = nextgm;
    
  end
  
  initial begin
    drv.reset();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_any  
    wait(gen.done.triggered);
    $finish;
  end
   
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;   
  end
 
assign vif.addr_wrapwr = dut.retaddr;
assign vif.addr_wraprd = dut.rdretaddr;  
   
endmodule