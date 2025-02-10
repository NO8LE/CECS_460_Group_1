`timescale 1ns / 1ps

module game_tb;

    reg clk;
    reg rst;
    reg btn;
    reg [3:0] sw;
    wire led_red;
    wire led_green;

    // Instantiate the game logic
    game_logic uut (
        .clk(clk),
        .rst(rst),
        .btn(btn),
        .sw(sw),
        .led_red(led_red),
        .led_green(led_green)
    );

    always #5 clk = ~clk; // Clock toggles every 5 ns

    initial begin
        clk = 0;
        rst = 1;
        btn = 0;
        sw = 4'b0000;
        
        #10 rst = 0; // Release reset after 10ns

        repeat (10) begin
            #10;
            sw = uut.correct_answer; // Use the value directly from BRAM
            btn = 1;
            #10 btn = 0;
            #20;
        end

        $finish;
    end
endmodule
