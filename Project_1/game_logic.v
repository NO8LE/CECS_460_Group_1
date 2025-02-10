`timescale 1ns / 1ps

module game_logic(
    input wire clk,
    input wire rst,
    input wire btn,
    input wire [3:0] sw,        // 4-bit player guess
    output reg led_red,         // LED1: Incorrect guess indicator
    output reg led_green        // LED0: Correct guess indicator
);

    reg [3:0] index;  // Tracks current BRAM address
    wire [3:0] correct_answer;
    reg btn_last;      // ? Declare btn_last to store previous button state

    // Instantiate BRAM module
    BRAM_Module bram_inst (
        .clk(clk),
        .address(index),
        .data_out(correct_answer)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            index <= 4'b0000;
            led_red <= 1'b0;
            led_green <= 1'b0;
            btn_last <= 1'b0; // ? Initialize btn_last
        end 
        else begin
            // Detect button press only on rising edge (transition from 0 to 1)
            if (btn && !btn_last) begin  
                led_red <= 1'b0;   // Reset LEDs before checking guess
                led_green <= 1'b0; 

                if (sw == correct_answer) begin
                    led_green <= 1'b1; // ? Correct guess ? Green LED ON
                end 
                else begin
                    led_red <= 1'b1;   // ? Incorrect guess ? Red LED ON
                end

                // Move to the next BRAM entry, looping back after 10 addresses
                if (index == 4'b1001)  
                    index <= 4'b0000;  
                else
                    index <= index + 4'b0001; 
            end
        end
    end

    // Store the previous state of `btn` for edge detection
    always @(posedge clk) begin
        btn_last <= btn;  // ? Tracks previous button state
    end

endmodule
