# sim_saif.tcl — Generate SAIF using XSIM Tcl (Vivado 2023+)
# Usage from Vivado Simulation Tcl Console or xsim:
#   source sim_saif.tcl
#
# Assumes your snapshot is already loaded. If running from Vivado GUI after "Run Simulation",
# just 'source' this file in the XSIM Tcl Console.

# Open SAIF file for logging
open_saif activity.saif

# Log all signals under the testbench scope (adjust if your TB name differs)
log_saif /tb_adaptive_pad_system_with_cmu/*

# Run simulation for 20,000 ns as requested
run 20000 ns

# Close SAIF and exit (comment 'exit' if running from GUI and you don't want to close)
close_saif
# exit
