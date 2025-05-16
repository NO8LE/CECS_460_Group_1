// AES Serial Interface Wrapper
// This module provides a serial interface to the AES encryption/decryption core,
// reducing the I/O pin count to fit within the constraints of the ZYBO Z7-10 FPGA.

`timescale 1ns / 1ps

module aes_serial_interface (
    input wire clk,               // System clock
    input wire rst,               // Reset signal
    input wire [7:0] data_in,     // 8-bit input data bus
    output reg [7:0] data_out,    // 8-bit output data bus
    input wire [4:0] addr,        // 5-bit address bus (0-15 for data, 16-31 for key)
    input wire wr_en,             // Write enable for loading data_in/key
    input wire start,             // Start the encryption/decryption operation
    input wire decrypt,           // 1 for decryption, 0 for encryption
    output reg busy,              // Indicates the core is busy
    output reg valid,             // Indicates data_out contains valid output data
    output reg done               // Operation complete indicator
);

    // State machine states
    localparam IDLE = 3'd0;
    localparam LOAD_DATA = 3'd1;
    localparam PROCESS = 3'd2;
    localparam READ_DATA = 3'd3;
    localparam COMPLETE = 3'd4;
    
    // Registers to hold the full 128-bit data and key
    reg [127:0] full_data_in;
    reg [127:0] full_key;
    reg [127:0] full_data_out;
    
    // Internal signals for interfacing with the AES core
    wire aes_valid_out;
    wire [127:0] aes_data_out;
    reg aes_enable;
    
    // State machine registers
    reg [2:0] state;
    reg [4:0] byte_counter;
    
    // AES core instantiation
    aes_pipelined aes_core (
        .clk(clk),
        .rst(rst),
        .enable(aes_enable),
        .data_in(full_data_in),
        .key(full_key),
        .decrypt(decrypt),
        .valid_out(aes_valid_out),
        .data_out(aes_data_out)
    );
    
    // State machine for control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            byte_counter <= 5'd0;
            busy <= 1'b0;
            valid <= 1'b0;
            done <= 1'b0;
            aes_enable <= 1'b0;
            data_out <= 8'd0;
            full_data_in <= 128'd0;
            full_key <= 128'd0;
            full_data_out <= 128'd0;
        end else begin
            case (state)
                IDLE: begin
                    // Handle loading of data and key bytes in IDLE state
                    if (wr_en) begin
                        if (addr < 5'd16) begin
                            // Loading data_in bytes (addr 0-15)
                            full_data_in[127-8*addr[3:0] -: 8] <= data_in;
                        end else if (addr < 5'd32) begin
                            // Loading key bytes (addr 16-31)
                            full_key[127-8*(addr[3:0]) -: 8] <= data_in;
                        end
                    end
                    
                    // Start operation when requested
                    if (start) begin
                        state <= PROCESS;
                        busy <= 1'b1;
                        valid <= 1'b0;
                        done <= 1'b0;
                        aes_enable <= 1'b1;
                    end else begin
                        busy <= 1'b0;
                        aes_enable <= 1'b0;
                    end
                end
                
                PROCESS: begin
                    // Wait for AES core to complete processing
                    aes_enable <= 1'b0;  // Only need to assert enable for one cycle
                    
                    if (aes_valid_out) begin
                        full_data_out <= aes_data_out;
                        byte_counter <= 5'd0;
                        state <= READ_DATA;
                        valid <= 1'b1;
                    end
                end
                
                READ_DATA: begin
                    // Output the result one byte at a time when addr matches byte_counter
                    if (addr == byte_counter) begin
                        data_out <= full_data_out[127-8*byte_counter[3:0] -: 8];
                    end
                    
                    // Move to next state when all bytes have been made available
                    if (byte_counter == 5'd15) begin
                        state <= COMPLETE;
                        done <= 1'b1;
                    end else begin
                        byte_counter <= byte_counter + 1'b1; // Use explicit 1-bit value
                    end
                end
                
                COMPLETE: begin
                    // Operation is complete, can still read output bytes
                    if (addr < 5'd16) begin
                        data_out <= full_data_out[127-8*addr[3:0] -: 8];
                    end
                    
                    // Return to IDLE when start is released
                    if (!start) begin
                        state <= IDLE;
                        valid <= 1'b0;
                        done <= 1'b0;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
endmodule
