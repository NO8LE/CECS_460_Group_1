// Key Expansion module for AES-128
// Generates round keys from the initial 128-bit key

`timescale 1ns / 1ps

module key_expansion(
    input wire clk,          // Clock signal
    input wire rst,          // Reset signal
    input wire [127:0] key,  // Initial 128-bit key
    // Replace array output with flattened bus
    output reg [1407:0] round_keys_flat  // 11 keys × 128 bits = 1408 bits
);
    // Internal array for calculation
    reg [127:0] round_keys [0:10];  // 11 round keys (including initial key)
    // Round constants (Rcon) used in key expansion
    reg [7:0] rcon [0:9];
    
    // Initialize the round constants
    initial begin
        rcon[0] = 8'h01;
        rcon[1] = 8'h02;
        rcon[2] = 8'h04;
        rcon[3] = 8'h08;
        rcon[4] = 8'h10;
        rcon[5] = 8'h20;
        rcon[6] = 8'h40;
        rcon[7] = 8'h80;
        rcon[8] = 8'h1b;
        rcon[9] = 8'h36;
    end
    
    // Internal variables
    reg [127:0] temp_round_keys [0:10];
    wire [31:0] temp_word;
    reg [31:0] temp_word_reg;
    wire [31:0] rotated_word, subbed_word;
    
    // Define the SubWord function (apply S-box to each byte of a word)
    wire [7:0] subbed_byte0, subbed_byte1, subbed_byte2, subbed_byte3;
    
    sbox sbox_inst0 (
        .in(rotated_word[31:24]),
        .out(subbed_byte0)
    );
    
    sbox sbox_inst1 (
        .in(rotated_word[23:16]),
        .out(subbed_byte1)
    );
    
    sbox sbox_inst2 (
        .in(rotated_word[15:8]),
        .out(subbed_byte2)
    );
    
    sbox sbox_inst3 (
        .in(rotated_word[7:0]),
        .out(subbed_byte3)
    );
    
    // RotWord function (rotate the word by one byte to the left)
    assign rotated_word = {temp_word_reg[23:0], temp_word_reg[31:24]};
    
    // Connect temp_word to the last word of previous round key
    assign temp_word = temp_word_reg;
    
    // Combine the substituted bytes
    assign subbed_word = {subbed_byte0, subbed_byte1, subbed_byte2, subbed_byte3};
    
    // Key expansion logic
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all round keys
            for (i = 0; i <= 10; i = i + 1) begin
                round_keys[i] <= 128'b0;
            end
        end else begin
            // The first round key is the initial key
            round_keys[0] <= key;
            
            // Generate remaining round keys
            for (i = 1; i <= 10; i = i + 1) begin
                // Extract words from the previous round key
                temp_word_reg = round_keys[i-1][31:0];  // Last word of previous round key
                
                // Apply RotWord and SubWord, then XOR with Rcon
                // Use a separate variable for the result to avoid Set/Reset conflict
                round_keys[i][127:96] = round_keys[i-1][127:96] ^ {subbed_byte0 ^ rcon[i-1], subbed_byte1, subbed_byte2, subbed_byte3};
                
                // First word is already generated above
                
                // Generate the remaining words
                round_keys[i][95:64] = round_keys[i-1][95:64] ^ round_keys[i][127:96];
                round_keys[i][63:32] = round_keys[i-1][63:32] ^ round_keys[i][95:64];
                round_keys[i][31:0] = round_keys[i-1][31:0] ^ round_keys[i][63:32];
            end
        end
    end
    
    // Add this at the end to flatten the array
    always @(*) begin
        round_keys_flat = {
            round_keys[10],
            round_keys[9],
            round_keys[8],
            round_keys[7],
            round_keys[6],
            round_keys[5],
            round_keys[4],
            round_keys[3],
            round_keys[2],
            round_keys[1],
            round_keys[0]
        };
    end
endmodule
