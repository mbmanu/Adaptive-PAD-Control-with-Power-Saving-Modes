`timescale 1ns/1ps
module power_management_unit #(
    parameter DEEP_WAKE_CYCLES = 8, // N=0 disables deep-wake ramp
    parameter         ACTIVE_OUTPUT_MODE = 1 // 1: OE=1, IE=0 in ACTIVE
) (
    input  wire clk,
    input  wire rst_n,

    input  wire sleep_req,
    input  wire deep_sleep_req,
    input  wire wakeup_req,

    input  wire cfg_ds,          // DS request for ACTIVE (1=strong,0=weak)

    output reg  [1:0] power_state, // 00 ACTIVE, 01 SLEEP, 10 DEEP_SLEEP, 11 DEEP_WAKE
    output reg        IE,
    output reg        OE,
    output reg        DS,           // advertised drive strength (ACTIVE only)
    output reg        VDD_ON,
    output reg        RTN_LEVEL,
    output reg        ISO_EN,       // Isolation enable
    output reg        LSBIAS,       // Level-shifter bias enable

    output wire       enter_active  // 1 on the cycle we transition into ACTIVE
);
    localparam [1:0] ACTIVE     = 2'b00;
    localparam [1:0] SLEEP      = 2'b01;
    localparam [1:0] DEEP_SLEEP = 2'b10;
    localparam [1:0] DEEP_WAKE  = 2'b11;

    reg [1:0] next_state;
    reg [7:0] dw_cnt;
    
    // Next-state (combinational) - UNCHANGED
    always @(*) begin
        next_state = power_state;
        case (power_state)
            ACTIVE: begin
                if (deep_sleep_req) next_state = DEEP_SLEEP;
                else if (sleep_req) next_state = SLEEP;
            end
            SLEEP: begin
                if (wakeup_req)          next_state = ACTIVE;
                else if (deep_sleep_req) next_state = DEEP_SLEEP;
            end
            DEEP_SLEEP: begin
                if (wakeup_req) begin
                    next_state = (DEEP_WAKE_CYCLES==0) ? ACTIVE : DEEP_WAKE;
                end else if (sleep_req) begin
                    next_state = SLEEP;
                end
            end
            DEEP_WAKE: begin
                next_state = (dw_cnt==0) ? ACTIVE : DEEP_WAKE;
            end
            default: next_state = ACTIVE;
        endcase
    end

    // State register + deep-wake counter - UNCHANGED
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            power_state <= ACTIVE;
            dw_cnt      <= 8'd0;
        end else begin
            power_state <= next_state;
            if (power_state==DEEP_SLEEP && wakeup_req && (DEEP_WAKE_CYCLES!=0))
                dw_cnt <= DEEP_WAKE_CYCLES[7:0];
            else if (power_state==DEEP_WAKE && next_state==DEEP_WAKE && dw_cnt!=0)
                dw_cnt <= dw_cnt - 8'd1;
            else if (next_state!=DEEP_WAKE)
                dw_cnt <= 8'd0;
        end
    end

    // Enter-ACTIVE pulse - UNCHANGED
    assign enter_active = (power_state != ACTIVE) && (next_state == ACTIVE);
    
    // *** MODIFIED OUTPUT LOGIC ***
    always @(*) begin
        // defaults based on your new rules
        IE=1'b0;
        OE=1'b0; DS=1'b0; VDD_ON=1'b1; RTN_LEVEL=1'b0;
        ISO_EN = 1'b0; 
        LSBIAS = 1'b0;

        case (power_state)
            ACTIVE: begin
                VDD_ON    = 1'b1;
                RTN_LEVEL = 1'b0;
                DS        = cfg_ds;
                ISO_EN    = 1'b0;
                LSBIAS    = 1'b0;
                if (ACTIVE_OUTPUT_MODE) begin OE=1'b1; IE=1'b0; end
                else                    begin OE=1'b0; IE=1'b1; end
            end
            SLEEP: begin
                VDD_ON    = 1'b0;
                RTN_LEVEL = 1'b1; // PER REQUEST
                OE        = 1'b0;
                IE        = 1'b0;
                DS        = 1'b0;
                ISO_EN    = 1'b0; // PER REQUEST
                LSBIAS    = 1'b0; // PER REQUEST
            end
            DEEP_SLEEP: begin
                VDD_ON    = 1'b0;
                RTN_LEVEL = 1'b1; // PER REQUEST
                OE        = 1'b0;
                IE        = 1'b0;
                DS        = 1'b0;
                ISO_EN    = 1'b1; // PER REQUEST
                LSBIAS    = 1'b1; // PER REQUEST
            end
            DEEP_WAKE: begin
                VDD_ON    = 1'b1;
                RTN_LEVEL = 1'b0; // PER REQUEST
                OE        = 1'b0;
                IE        = 1'b0;
                DS        = 1'b0;
                ISO_EN    = 1'b0; // PER REQUEST
                LSBIAS    = 1'b0; // PER REQUEST
            end
        endcase
    end
endmodule