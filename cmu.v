`timescale 1ns/1ps
module clock_management_unit (
    input  wire clk_in,
    input  wire rst_n_in,    // async active-low
    output wire clk_out,
    output wire rst_n_out    // sync deasserted
);
    assign clk_out = clk_in;

    // 2FF reset synchronizer (async assert, sync deassert)
    reg [1:0] rst_sync;
    always @(posedge clk_in or negedge rst_n_in) begin
        if (!rst_n_in) rst_sync <= 2'b00;
        else           rst_sync <= {rst_sync[0], 1'b1};
    end
    assign rst_n_out = rst_sync[1];
endmodule