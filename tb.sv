`timescale 1ns/1ps
module tb_adaptive_pad_system_with_cmu;

  // Match DUT encodings
  localparam [1:0] ACTIVE     = 2'b00;
  localparam [1:0] SLEEP      = 2'b01;
  localparam [1:0] DEEP_SLEEP = 2'b10;
  localparam [1:0] DEEP_WAKE  = 2'b11;

  // DUT I/O
  reg  clk_in, rst_n_in;
  reg  sleep_req, deep_sleep_req, wakeup_req;
  reg  cfg_ds;
  reg  [3:0] A; 

  wire [1:0] power_state;
  wire [3:0] pad_out; 
  wire IE, OE, DS, VDD_ON, RTN_LEVEL;
  wire ISO_EN, LSBIAS; 

  // Instantiate TOP
  adaptive_pad_system_with_cmu dut (
    .clk_in(clk_in),
    .rst_n_in(rst_n_in),
    .sleep_req(sleep_req),
    .deep_sleep_req(deep_sleep_req),
    .wakeup_req(wakeup_req),
    .cfg_ds(cfg_ds),
    .A(A),
    .power_state(power_state),
    .pad_out(pad_out),
    .IE(IE), .OE(OE),
    .DS(DS),
    .VDD_ON(VDD_ON),
    .RTN_LEVEL(RTN_LEVEL),
    .ISO_EN(ISO_EN),
    .LSBIAS(LSBIAS)
  );
  
  // Clock
  initial begin
    clk_in = 1'b0;
    forever #5 clk_in = ~clk_in;
  end

  // ---------------- Helpers ----------------
  task wait_cycles; input integer n; integer i;
  begin
    for (i=0; i<n; i=i+1) @(posedge clk_in);
  end endtask

  task check1; input [127:0] tag; input exp;
  input got; begin
    if (got !== exp) $display("[%0t] ERROR %s exp=%0b got=%0b", $time, tag, exp, got);
    else             $display("[%0t] OK    %s = %0b",           $time, tag, got);
  end endtask

  task check_vec; input [127:0] tag; input [3:0] exp;
  input [3:0] got; begin
    if (got !== exp) $display("[%0t] ERROR %s exp=%0h got=%0h", $time, tag, exp, got);
    else             $display("[%0t] OK    %s = %0h",           $time, tag, got);
  end endtask

  // *** UPDATED CHECK TASKS ***
  task to_active; begin
    wakeup_req = 1'b1; @(posedge clk_in); wakeup_req = 1'b0;
    @(posedge clk_in);
    check1("state ACTIVE?", 1'b1, (power_state==ACTIVE));
    check1("VDD_ON=1?",     1'b1, VDD_ON);
    check1("OE=1?",         1'b1, OE);
    check1("RTN_LEVEL=0?",  1'b0, RTN_LEVEL);
    check1("ISO_EN=0?",     1'b0, ISO_EN);
    check1("LSBIAS=0?",     1'b0, LSBIAS);
  end endtask

  task to_sleep;
  begin
    sleep_req = 1'b1; @(posedge clk_in); sleep_req = 1'b0;
    @(posedge clk_in);
    check1("state SLEEP?", 1'b1, (power_state==SLEEP));
    check1("VDD_ON=0 in SLEEP?", 1'b0, VDD_ON);
    check1("RTN_LEVEL=1 in SLEEP?", 1'b1, RTN_LEVEL); // PER REQUEST
    check1("ISO_EN=0 in SLEEP?", 1'b0, ISO_EN);     // PER REQUEST
    check1("LSBIAS=0 in SLEEP?", 1'b0, LSBIAS);   // PER REQUEST
  end endtask

  task to_deep; begin
    deep_sleep_req = 1'b1; @(posedge clk_in);
    deep_sleep_req = 1'b0;
    @(posedge clk_in);
    check1("state DEEP_SLEEP?", 1'b1, (power_state==DEEP_SLEEP));
    check1("VDD_ON=0 in DEEP_SLEEP?", 1'b0, VDD_ON);
    check1("RTN_LEVEL=1 in DEEP_SLEEP?", 1'b1, RTN_LEVEL); // PER REQUEST
    check1("ISO_EN=1 in DEEP_SLEEP?", 1'b1, ISO_EN);     // PER REQUEST
    check1("LSBIAS=1 in DEEP_SLEEP?", 1'b1, LSBIAS);   // PER REQUEST
  end endtask

  // ---------------- Stimulus ----------------
  integer i;
  integer k;
  time    t0;
  reg [3:0] retained; 
  
  initial begin
    // init
    rst_n_in=1'b0; sleep_req=1'b0; deep_sleep_req=1'b0; wakeup_req=1'b0;
    cfg_ds=1'b1; A=4'h0;
    wait_cycles(4); rst_n_in=1'b1; wait_cycles(2);

    // === ACTIVE sanity ===
    to_active();
    A=4'h5;
    @(posedge clk_in); check_vec("ACTIVE: pad_out==A (5)", 4'h5, pad_out);
    A=4'hA; 
    @(posedge clk_in); check_vec("ACTIVE: pad_out==A (A)", 4'hA, pad_out);
    
    // === SLEEP retention & wake ===
    A=4'hC;
    @(posedge clk_in);
    retained = pad_out; 
    to_sleep();
    for (i=0; i<4; i=i+1) begin
      A = ~A; 
      @(posedge clk_in);
      check_vec("SLEEP retention", retained, pad_out);
    end
    A = ~retained; 
    @(posedge clk_in);
    t0 = $time;
    wakeup_req=1'b1; @(posedge clk_in); wakeup_req=1'b0;
    check_vec("SLEEP wake immediate handoff", A, pad_out);
    $display("[SLEEP] wake-to-handoff ~ %0t ns", $time - t0);

    // === DEEP_SLEEP retention & DEEP_WAKE ramp ===
    to_active();
    A=4'h9; 
    @(posedge clk_in);
    retained = pad_out;
    to_deep();
    for (i=0; i<3; i=i+1) begin
      A = ~A;
      @(posedge clk_in);
      check_vec("DEEP_SLEEP retention", retained, pad_out);
    end

    t0 = $time;
    wakeup_req=1'b1; @(posedge clk_in); wakeup_req=1'b0;
    while (power_state==DEEP_SLEEP) @(posedge clk_in);
    $display("[INFO] Entered DEEP_WAKE at %0t ns", $time);
    
    // *** CHECK SIGNALS IN DEEP_WAKE ***
    check1("DEEP_WAKE: VDD_ON=1?", 1'b1, VDD_ON);
    check1("DEEP_WAKE: RTN_LEVEL=0?", 1'b0, RTN_LEVEL); // PER REQUEST
    check1("DEEP_WAKE: ISO_EN=0?", 1'b0, ISO_EN);     // PER REQUEST
    check1("DEEP_WAKE: LSBIAS=0?", 1'b0, LSBIAS);   // PER REQUEST

    k = 0;
    // NOTE: Retention will fail here because RTN_LEVEL=0
    while (power_state==DEEP_WAKE) begin
      A = ~A; @(posedge clk_in);
      // check_vec("DEEP_WAKE retention", retained, pad_out); // This check will fail
      k = k + 1;
    end
    $display("[INFO] DEEP_WAKE cycles observed = %0d", k);
    
    check_vec("DEEP_SLEEP wake immediate handoff", A, pad_out);
    $display("[DEEP_SLEEP] wake-to-handoff (incl. ramp) ~ %0t ns", $time - t0);

    $display("\n--- TEST DONE ---");
    wait_cycles(4); $finish;
  end
initial begin
  $dumpfile("activity.vcd");
  $dumpvars(0, tb_adaptive_pad_system_with_cmu);
end

endmodule