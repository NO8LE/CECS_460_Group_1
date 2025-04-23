// AES Round module
// Implements a single round of the AES encryption algorithm,
// combining SubBytes, ShiftRows, MixColumns, and AddRoundKey operations

module aes_round(
    input wire clk,                // Clock signal
    input wire rst,                // Reset signal
    input wire [127:0] data_in,    // Input state
    input wire [127:0] round_key,  // Round key for this round
    input wire is_final_round,     // Flag to indicate if this is the final round
    output reg [127:0] data_out    // Output state
);
    // Internal wires to connect the transformation modules
    wire [127:0] after_sub_bytes;
    wire [127:0] after_shift_rows;
    wire [127:0] after_mix_columns;
    wire [127:0] current_out;
    
    // SubBytes transformation
    sub_bytes sub_bytes_inst (
        .in(data_in),
        .out(after_sub_bytes)
    );
    
    // ShiftRows transformation
    shift_rows shift_rows_inst (
        .in(after_sub_bytes),
        .out(after_shift_rows)
    );
    
    // MixColumns transformation (skipped in the final round)
    mix_columns mix_columns_inst (
        .in(after_shift_rows),
        .out(after_mix_columns)
    );
    
    // Either use MixColumns output or bypass it depending on is_final_round
    assign current_out = is_final_round ? after_shift_rows ^ round_key : after_mix_columns ^ round_key;
    
    // Register the output for pipelining
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 128'b0;
        end else begin
            data_out <= current_out;
        end
    end
endmodule
