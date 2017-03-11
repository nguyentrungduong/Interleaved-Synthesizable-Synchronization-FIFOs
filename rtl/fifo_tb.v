////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2016, University of British Columbia (UBC)  All rights reserved. //
//                                                                                //
// Redistribution  and  use  in  source   and  binary  forms,   with  or  without //
// modification,  are permitted  provided that  the following conditions are met: //
//   * Redistributions   of  source   code  must  retain   the   above  copyright //
//     notice,  this   list   of   conditions   and   the  following  disclaimer. //
//   * Redistributions  in  binary  form  must  reproduce  the  above   copyright //
//     notice, this  list  of  conditions  and the  following  disclaimer in  the //
//     documentation and/or  other  materials  provided  with  the  distribution. //
//   * Neither the name of the University of British Columbia (UBC) nor the names //
//     of   its   contributors  may  be  used  to  endorse  or   promote products //
//     derived from  this  software without  specific  prior  written permission. //
//                                                                                //
// THIS  SOFTWARE IS  PROVIDED  BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" //
// AND  ANY EXPRESS  OR IMPLIED WARRANTIES,  INCLUDING,  BUT NOT LIMITED TO,  THE //
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE //
// DISCLAIMED.  IN NO  EVENT SHALL University of British Columbia (UBC) BE LIABLE //
// FOR ANY DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,  EXEMPLARY, OR CONSEQUENTIAL //
// DAMAGES  (INCLUDING,  BUT NOT LIMITED TO,  PROCUREMENT OF  SUBSTITUTE GOODS OR //
// SERVICES;  LOSS OF USE,  DATA,  OR PROFITS;  OR BUSINESS INTERRUPTION) HOWEVER //
// CAUSED AND ON ANY THEORY OF LIABILITY,  WHETHER IN CONTRACT, STRICT LIABILITY, //
// OR TORT  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE //
// OF  THIS SOFTWARE,  EVEN  IF  ADVISED  OF  THE  POSSIBILITY  OF  SUCH  DAMAGE. //
////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////
//    fifo_tb.v: gate-level-simulation (GLS) testbench for the interleaved FIFO   //
//             Author: Ameer Abdelhadi (ameer.abdelhadi@gmail.com)                //
// Cell-based interleaved FIFO :: The University of British Columbia :: Nov. 2016 //
////////////////////////////////////////////////////////////////////////////////////

// Setup Timescale
`timescale 1ps/1ps

// include configuration file; generated by scr/do
`include "./rtl/config.h"

`define MAX(p,q) (((p)>(q))?(p):(q))

module fifo_tb;

  // simulation parameters

  parameter NV            = `VERSTG                                  ; // number of vertical fifo stages
  parameter NH            = `HORSTG                                  ; // number of horizontal fifo stages
  parameter DW            = `DATAWD                                  ; // data width
  parameter SD            = `SYNCDP                                  ; // brute-force synchronizer depth
  parameter NS            = NV*NH                                    ; // number of fifo stages
  parameter DATALN        = `SIMDATALN                               ; // simulation data stream length
  parameter PUTPERSCL     = `SIMPUTPERSCL                            ; // put clock period scale
  parameter GETPERSCL     = `SIMGETPERSCL                            ; // get clock period scale
  parameter SDF_FN        = {"./sta/",`RUNNAM,".sdf"}                ; // SDF file name
  parameter PUTSKW        = `PUTSKW-48                               ; // put clock phase shift 
  parameter GETSKW        = `GETSKW-48                               ; // get clock phase shift
  parameter PUTPH1        = PUTPERSCL*(  `SIMPUTDTYCYC)*(1E6/`OPRFRQ); // put clock phase 1 length
  parameter PUTPH2        = PUTPERSCL*(1-`SIMPUTDTYCYC)*(1E6/`OPRFRQ); // put clock phase 2 length
  parameter GETPH1        = GETPERSCL*(  `SIMGETDTYCYC)*(1E6/`OPRFRQ); // get clock phase 1 length
  parameter GETPH2        = GETPERSCL*(1-`SIMGETDTYCYC)*(1E6/`OPRFRQ); // get clock phase 2 length
  parameter TIMEOT        = 1E4*`MAX(PUTPH1+PUTPH2,GETPH1+GETPH2)    ; // simulation run timeout
  parameter JITTPRCNT     = 2                                        ; // clock jitter percentage (of full clock period)
  parameter get_ackR2reqF = 500                                      ; // get acknowledge rise to request fall delay
  parameter get_ackF2reqR = 500                                      ; // get acknowledge fall to request rise delay
  parameter put_ackR2reqF = 500                                      ; // put acknowledge rise to request fall delay 
  parameter put_ackF2reqR = 500                                      ; // put acknowledge fall to request rise delay
  parameter finish_hold   = 500                                      ; // hold simulation before finish

  // local registers and wires
  reg           rst;
  reg           settle;
  reg           clk_put;
  reg           clk_put_p;
  reg           clk_get;
  reg           clk_get_p;
  reg           req_put;
  reg           req_get;
  wire          ack_put;
  wire          ack_get;
  reg  [DW-1:0] datain;
  wire [DW-1:0] dataout;
  wire          datav;
  reg  [15:0]   put_cnt;
  reg  [15:0]   get_cnt;
  reg  [15:0]   used_slots;
  reg  [15:0]   failure_cnt;
  reg           get_enb;
  reg           put_enb;
  reg  [DW-1:0] refmem [DATALN-1:0];
  reg  [31:0]   last_get_time;
  reg  [31:0]   start_time;
  reg  [31:0]   finish_time;
  reg  [31:0]   sim_time;
  reg  [8*3:0]  fifo_status;
  reg  [31:0]   passed_cnt;
  reg  [31:0]   passed_percent;
  reg  [31:0]   user_latency;
  reg  [31:0]   fifo_latency;
  reg  [31:0]   fifo_throughput;
  reg  [31:0]   put_prv_time        ;
  reg  [31:0]   forward_latency_sum ;
  reg  [31:0]   forward_latency_cnt ;
  reg  [31:0]   get_prv_time        ;
  reg  [31:0]   backward_latency_sum;
  reg  [31:0]   backward_latency_cnt;
  reg           is_put_empty_fifo   ;
  reg           is_get_full_fifo    ;

  initial begin
    $timeformat(-12, 0, "ps", 10);
    $printtimescale;
    $write("\n\n*** Testing FIFO ...");
    $write(  "\n*** Put PH1=%.2f, PH2=%.2f, SKW=%d; Get PH1=%.2f, PH2=%.2f, SKW=%d",PUTPH1,PUTPH2,PUTSKW,GETPH1,GETPH2,GETSKW);
    // sdf back-annotation
    //$sdf_annotate(SDF_FN                   , fifo_tb.fifo_inst, , , "maximum"); // VCS
      $sdf_annotate({"./sta/",`RUNNAM,".sdf"}, fifo_tb.fifo_inst, , , "maximum"); // nc-verilog
    // dump to vcd
    $dumpfile({"./sim/",`RUNNAM,".",`MOD,".vcd"});
    $dumpvars;
    // initialize variables
    clk_put              = 1'b0   ;
    clk_put_p            = 1'b0   ;
    clk_get              = 1'b0   ;
    clk_get_p            = 1'b0   ;
    datain               = $random;
    put_cnt              = 0      ;
    get_cnt              = 0      ;
    used_slots           = 0      ;
    fifo_status          = "EMP"  ;
    failure_cnt          = 0      ;
    req_put              = 1'b0   ;
    req_get              = 1'b0   ;
    last_get_time        = $time  ;
    start_time           = 0      ;
    finish_time          = 0      ;
    sim_time             = 0      ;
    put_prv_time         = 0      ;
    forward_latency_sum  = 0      ;
    forward_latency_cnt  = 0      ;
    get_prv_time         = 0      ;
    backward_latency_sum = 0      ;
    backward_latency_cnt = 0      ;
    is_put_empty_fifo    = 1      ;
    is_get_full_fifo     = 0      ;
  end

  // generate clk_put
  always fork
    #((PUTPH1       )*((100.0+$random%(JITTPRCNT+1))/100.0)) clk_put = 1'b1;
    #((PUTPH1+PUTPH2)*((100.0+$random%(JITTPRCNT+1))/100.0)) clk_put = 1'b0;
  join

  // phase-shifed clk_put
//  always @(clk_put) clk_put_p <= #(PUTSKW*PUTPH1/4.0) clk_put;
  always @(clk_put) clk_put_p <= #(PUTPH1/2.0) clk_put;


  // generate clk_get
  always fork
    #((GETPH1       )*((100.0+$random%(JITTPRCNT+1))/100.0)) clk_get = 1'b0;
    #((GETPH1+GETPH2)*((100.0+$random%(JITTPRCNT+1))/100.0)) clk_get = 1'b1;
  join

  // phase-shifed clk_get
  always @(clk_get) clk_get_p <= #(GETSKW*PUTPH1/4.0) clk_get;

  // Generate reset
  initial begin
    rst  <= 1'b1;
    settle <= 1'b0;
    #(20*`MAX(PUTPERSCL,GETPERSCL)*`MAX(PUTPH1+PUTPH2,GETPH1+GETPH2)) rst  <= 1'b0;
                                                                      $write("\n*** Reset finished @%0t\n",$time);
    #(20*`MAX(PUTPERSCL,GETPERSCL)*`MAX(PUTPH1+PUTPH2,GETPH1+GETPH2)) settle <= 1'b1 ;
  end

  /////////////////////////////////////
  // clkd -> clkd fifo instantiation //
  /////////////////////////////////////

  fifo fifo_inst (
    .rst   (rst      ),
    // clkd put interface
    .datain  (datain ),
    .req_put (req_put),
    .clk_put (clk_put),
    .spaceav (spaceav),
    // clkd get interface
    .dataout (dataout),
    .req_get (req_get),
    .clk_get (clk_get),
    .datav   (datav  )
  ); 

  //////////////////////////
  // handle clkd put data //
  //////////////////////////

  // raise req_put and update input data on rising clk_put edge, if sapce_avail and get_enb
  always @(negedge clk_put) begin // _p?
  //#(PUTPH1/2.0)
    // generate put enabler
    case (`MOD)
      "FST"  : put_enb = 1'b1                             ;
      "RND"  : put_enb = {$random}%2                      ;
      "EMP"  : put_enb = (used_slots==0)                  ;
      "MID"  : put_enb = (used_slots<NS-1)|(NS==2);
      "FLL"  : put_enb = (used_slots<NS)              ;
      default: $display("Error in SEL")                   ;
    endcase
    if (settle & spaceav & put_enb & (put_cnt < DATALN-1)) begin
      req_put <= 1'b1   ;
      datain  <= $random;
    end
      else req_put <= 1'b0;
  end

  // on clk_put falling edge, if req_put is enabled, report put and update generic FIFO
  // since the actual FIFO writing happens of the falling edge of clk_put
  always @(posedge clk_put)
    if (req_put) begin
      refmem[put_cnt] <= datain;

      if (put_cnt==0) start_time <= $time;
      put_prv_time      = $time;
      is_put_empty_fifo = (used_slots==0)?1'b1:1'b0;

      put_cnt     = put_cnt + 1      ;
      used_slots  = put_cnt - get_cnt;
      fifo_status = (used_slots == 0)?"EMP":((used_slots == NS)?"FLL":"MID");
      $write("\n>>> put #%04d @%0t\t >>> %h wrote by clkd  sender (FIFO:%02d/%02d:%0s)           ",put_cnt,$time,datain,used_slots,NS,fifo_status);
    end

  always @(posedge spaceav)
    if (is_get_full_fifo) begin
      backward_latency_sum = backward_latency_sum + $time - get_prv_time;
      backward_latency_cnt = backward_latency_cnt + 1                   ;
    end

  //////////////////////////
  // handle clkd get data //
  //////////////////////////

  // generate get enabler
  always @(negedge clk_get) begin // _p?
    case (`MOD)
      "FST"  : get_enb = 1'b1                                    ;
      "RND"  : get_enb = {$random}%2                             ; 
      "EMP"  : get_enb = (used_slots>0)                          ; 
      "MID"  : get_enb = (used_slots>1)|(put_cnt==DATALN)        ; 
      "FLL"  : get_enb = (used_slots==NS)|(put_cnt==DATALN-1); 
      default: $display("Error in SEL")                           ;
    endcase
    req_get = settle & datav & get_enb;
  end

  // try to get data on rising clk_get
  always @(negedge clk_get) begin // _?p
    if (req_get) begin

      get_prv_time = $time;
      is_get_full_fifo = (used_slots==NS)?1'b1:1'b0;

      get_cnt = get_cnt + 1 ;
      used_slots   = put_cnt - get_cnt;
      fifo_status = (used_slots == 0)?"EMP":((used_slots==NS)?"FLL":"MID");
      last_get_time <= $time;
      $write("\n<<< get #%04d @%0t\t <<< %h read by clkd reciever (FIFO:%02d/%02d:%0s), ",get_cnt,$time,dataout,used_slots,NS,fifo_status);
      if (dataout == refmem[get_cnt-1]) $write("matching!");
      else begin
        $write("FAILURE !");
        failure_cnt <= failure_cnt + 1;
      end

      finish_time     = $time;
      sim_time        = finish_time-start_time;
      passed_cnt      = get_cnt+1-failure_cnt;
      passed_percent  = (100.0*passed_cnt)/(1.0*DATALN);
      user_latency    = 0;
      fifo_latency    = sim_time-DATALN*user_latency; 
      fifo_throughput = (get_cnt+1)/(fifo_latency*1E-6);

      if (get_cnt == DATALN-1) begin
        $write("\n\n*** SIMULATION FINISHED!");
        $write(  "\n*** %0d out of %0d \(%.0f%%\) data chunks passed FIFO within %0t",passed_cnt,DATALN,passed_percent,fifo_latency);
        $write(  "\n*** Throughput       is: %4.0fMhz",fifo_throughput                         );
        $write(  "\n*** Forward  latency is: %.0fps" ,forward_latency_sum/forward_latency_cnt  );
        $write(  "\n*** Backward latency is: %.0fps" ,backward_latency_sum/backward_latency_cnt);
      $write(  "\n*** Put clk phase shift: %3.2f phases" ,PUTSKW/4.0);
      $write(  "\n*** Get clk phase shift: %3.2f phases" ,GETSKW/4.0);
        $write("\n\n");
        #finish_hold $finish;
      end
    end

    if (($time - last_get_time) > TIMEOT) begin
      $write("\n\n*** SIMULATION TIME OUT!");
      $write(  "\n*** %0d out of %0d \(%.0f%%\) data chunks passed FIFO within %0t",passed_cnt,DATALN,passed_percent,fifo_latency);
      $write(  "\n*** Throughput       is: %4.0fMhz",fifo_throughput                         );
      $write(  "\n*** Forward  latency is: %.0fps" ,forward_latency_sum/forward_latency_cnt  );
      $write(  "\n*** Backward latency is: %.0fps" ,backward_latency_sum/backward_latency_cnt);
      $write(  "\n*** Put clk phase shift: %3.2f phases" ,PUTSKW/4.0);
      $write(  "\n*** Get clk phase shift: %3.2f phases" ,GETSKW/4.0);
      $write("\n\n");
      #finish_hold $finish;   
    end

  end

  always @(posedge datav)
    if (is_put_empty_fifo) begin
      forward_latency_sum = forward_latency_sum + $time - put_prv_time;
      forward_latency_cnt = forward_latency_cnt + 1                   ;
    end

endmodule

