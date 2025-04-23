// Inverse AES Round module
// Implements a single round of the AES decryption algorithm,
// combining InvShiftRows, InvSubBytes, AddRoundKey, and InvMixColumns operations

module aes_inv_round(
    input wire clk,                // Clock signal
    input wire rst,                // Reset signal
    input wire [127:0] data_in,    // Input state
    input wire [127:0] round_key,  // Round key for this round
    input wire is_first_round,     // Flag to indicate if this is the first round
    output reg [127:0] data_out    // Output state
);
    // Internal wires to connect the transformation modules
    wire [127:0] after_inv_shift_rows;
    wire [127:0] after_inv_sub_bytes;
    wire [127:0] after_add_round_key;
    wire [127:0] after_inv_mix_columns;
    wire [127:0] current_out;
    
    // Inverse ShiftRows transformation
    inv_shift_rows inv_shift_rows_inst (
        .in(data_in),
        .out(after_inv_shift_rows)
    );
    
    // Inverse SubBytes transformation
    inv_sub_bytes inv_sub_bytes_inst (
        .in(after_inv_shift_rows),
        .out(after_inv_sub_bytes)
    );
    
    // AddRoundKey
    assign after_add_round_key = after_inv_sub_bytes ^ round_key;
    
    // Inverse MixColumns transformation (skipped in the first round)
    inv_mix_columns inv_mix_columns_inst (
        .in(after_add_round_key),
        .out(after_inv_mix_columns)
    );
    
    // Either use InvMixColumns output or bypass it depending on is_first_round
    assign current_out = is_first_round ? after_add_round_key : after_inv_mix_columns;
    
    // Register the output for pipelining
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 128'b0;
        end else begin
            data_out <= current_out;
        end
    end
endmodule
