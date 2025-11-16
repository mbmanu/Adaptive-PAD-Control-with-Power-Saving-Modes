`timescale 1ns/1ps
module adaptive_pad_system_with_cmu (
    input  wire       clk_in,
    input  wire       rst_n_in,
    input  wire       sleep_req,
    input  wire       deep_sleep_req,
    input  wire       wakeup_req,
    input  wire       cfg_ds,         // DS request for ACTIVE
    input  wire [3:0] A,              // 4-bit

    output wire [1:0] power_state,
    output wire [3:0] pad_out,        // 4-bit
    output wire       IE,
    output wire       OE,
    output wire       DS,
    output wire       VDD_ON,
    output wire       RTN_LEVEL,
    output wire       ISO_EN,         
    output wire       LSBIAS          
);
    wire clk, rst_n;
    wire enter_active; 

    // CMU (Unchanged)
    clock_management_unit cmu_i (
        .clk_in   (clk_in),
        .rst_n_in (rst_n_in),
        .clk_out  (clk),
        .rst_n_out(rst_n)
    );

    // PMU (Unchanged)
    power_management_unit #(
        .DEEP_WAKE_CYCLES(8),
        .ACTIVE_OUTPUT_MODE(1)
    ) pmu_i (
        .clk          (clk),
        .rst_n        (rst_n),
        .sleep_req    (sleep_req),
        .deep_sleep_req(deep_sleep_req),
        .wakeup_req   (wakeup_req),
        .cfg_ds       (cfg_ds),
        .power_state  (power_state),
        .IE           (IE),
        .OE           (OE),
        .DS           (DS),
        .VDD_ON       (VDD_ON),
        .RTN_LEVEL    (RTN_LEVEL),
        .ISO_EN       (ISO_EN),
        .LSBIAS       (LSBIAS),
        .enter_active (enter_active)
    );

    // PAD controller (4 instances via generate)
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : pad_gen
            pad_controller pad_i (
                .clk        (clk),
                .rst_n      (rst_n),
                .power_state(power_state),
                .A          (A[i]),
                .IE         (IE),
                .OE         (OE),
                .DS         (DS),
                .VDD_ON     (VDD_ON),
                .enter_active(enter_active),
                .pad_out    (pad_out[i])
            );
        end
    endgenerate
endmodule