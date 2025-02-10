`timescale 1ns / 1ps

module top(
    input wire clk,
    input wire rst,
    input wire btn,
    input wire [3:0] sw,
    output wire led_red,
    output wire led_green
    
);

    game_logic game_logic_inst (
        .clk(clk),
        .rst(rst),
        .btn(btn),
        .sw(sw),
        .led_red(led_red),
        .led_green(led_green)
        
    );

endmodule
