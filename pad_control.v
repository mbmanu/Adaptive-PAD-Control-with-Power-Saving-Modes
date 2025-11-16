`timescale 1ns/1ps
module pad_controller (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [1:0] power_state,  // 00 ACTIVE, 01 SLEEP, 10 DEEP_SLEEP, 11 DEEP_WAKE
    input  wire       A,            // core-side data
    input  wire       IE,
    input  wire       OE,
    input  wire       DS,           // visibility/future use
    input  wire       VDD_ON,
    input  wire       enter_active, // NEW: one-cycle pulse on ACTIVE entry

    output reg        pad_out
);
    localparam [1:0] ACTIVE     = 2'b00;
    localparam [1:0] SLEEP      = 2'b01;
    localparam [1:0] DEEP_SLEEP = 2'b10;
    localparam [1:0] DEEP_WAKE  = 2'b11;

    // Retained value (what was actually driven in ACTIVE)
    reg a_ret;

    // Capture policy:
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) a_ret <= 1'b0;
        else if (enter_active) a_ret <= A;
        else if (VDD_ON && (power_state==ACTIVE) && OE) a_ret <= A;
    end

    // Output policy priority:
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pad_out <= 1'b0;
        end else if (enter_active) begin
            pad_out <= A; // immediate follow on ACTIVE entry
        end else if (!VDD_ON) begin
            pad_out <= a_ret; // retention while "off"
        end else begin
            case (power_state)
                ACTIVE:     pad_out <= (OE ? A : a_ret);
                SLEEP:      pad_out <= a_ret;
                DEEP_SLEEP: pad_out <= a_ret;
                DEEP_WAKE:  pad_out <= a_ret; // rail up, still retaining
                default:    pad_out <= a_ret;
            endcase
        end
    end
endmodule