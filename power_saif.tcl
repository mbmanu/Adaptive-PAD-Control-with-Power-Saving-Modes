# power_saif.tcl — Post-implementation power with SAIF (Vivado 2023+)
# Usage:
#   1) Run your XSIM testbench and export activity.saif (see notes below).
#   2) In Vivado Tcl Console (with your project open), run:
#         source power_saif.tcl
#   3) Open power_report_saif.rpt and look for "Total On-Chip Power".

# ---- USER SETTINGS (edit if needed) ----
set rtl_files  [list cmu.v pad_control.v pmu.v top.v]
set top_name   adaptive_pad_system_with_cmu
set clk_port   clk_in
set clk_period 10.0      ;# ns (100 MHz)
set saif_file  activity.saif
set tb_scope   tb_adaptive_pad_system_with_cmu/dut  ;# TB instance path to DUT

# ---- Basic checks ----
if {[catch {current_project}]} {
  puts "ERROR: No Vivado project is open. Please open/create a project (with part/board) and re-run."
  return
}
if {![file exists $saif_file]} {
  puts "WARNING: SAIF file '$saif_file' not found in current directory: [pwd]"
  puts "         You can still run vectorless power (less accurate)."
}

# ---- Read RTL and implement ----
# Clear any prior runs for a clean pass
if {[llength [get_files -quiet]] > 0} {
  puts "INFO: Project already has files; continuing. (This script also reads given RTL files directly)"
}
foreach f $rtl_files {
  if {[file exists $f]} {
    read_verilog $f
  } else {
    puts "WARNING: RTL file '$f' not found in [pwd]"
  }
}

update_compile_order -fileset sources_1

synth_design -top $top_name
opt_design
place_design
route_design

# ---- Clocks (if not already constrained in XDC) ----
# Create only if the port exists and clock not already created
if {[llength [get_ports -quiet $clk_port]]} {
  if {![llength [get_clocks -of_objects [get_ports -quiet $clk_port]]]} {
    create_clock -name sys_clk -period $clk_period [get_ports $clk_port]
  }
}

# ---- Import switching activity (preferred) ----
set used_saif 0
if {[file exists $saif_file]} {
  puts "INFO: Importing SAIF activity from $saif_file (scope=$tb_scope)"
  read_saif $saif_file

  set used_saif 1
} else {
  puts "INFO: Proceeding with vectorless power (no SAIF)."
}

# ---- Optional: operating conditions (edit as needed) ----
# set_operating_conditions -process 1.0 -voltage 1.0 -temp 25

# ---- Report power ----
set rpt_txt power_report_saif.rpt
set rpt_xml power_report_saif.xml

report_power -file $rpt_txt
report_power -file $rpt_xml -format xml

puts "============================================================"
puts "Power report written to: $rpt_txt and $rpt_xml"
if {$used_saif} {
  puts "Activity source: SAIF ($saif_file)"
} else {
  puts "Activity source: Vectorless (less accurate)"
}
puts "Open '$rpt_txt' and look for the line:  \"Total On-Chip Power\""
puts "============================================================"

# ---- Notes: How to generate 'activity.saif' in XSIM ----
# In your testbench (tb.v), add:
#   initial begin
#     $xsim.saif_on(\"activity.saif\");
#     $xsim.saif_start;
#     #10000;   // adjust to cover ACTIVE->SLEEP->DEEP_SLEEP->WAKE
#     $xsim.saif_stop;
#     $xsim.saif_close;
#   end
#
# Then run simulation (Run Behavioral Simulation). The file will be created in the sim directory.
