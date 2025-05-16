// Fully Pipelined AES Implementation
// This module implements a fully pipelined version of AES-128
// allowing for maximum throughput of one block per clock cycle
// with support for both encryption and decryption

`timescale 1ns / 1ps

module aes_pipelined(
    input wire clk,               // System clock
    input wire rst,               // Reset signal
    input wire enable,            // Enable signal
    input wire [127:0] data_in,   // Input data block
    input wire [127:0] key,       // Input key
    input wire decrypt,           // 1 for decryption, 0 for encryption
    output wire valid_out,        // Output valid indicator
    output wire [127:0] data_out  // Output data block
);
    // Replace wire array with flattened bus and individual wires
    wire [1407:0] round_keys_flat;
    wire [127:0] round_keys [0:10];
    
    // Pipeline stage registers
    reg [127:0] r0_data_out;                      // Initial AddRoundKey output
    reg [127:0] r1_data_in, r1_data_out;          // Round 1 registers
    reg [127:0] r2_data_in, r2_data_out;          // Round 2 registers
    reg [127:0] r3_data_in, r3_data_out;          // Round 3 registers
    reg [127:0] r4_data_in, r4_data_out;          // Round 4 registers
    reg [127:0] r5_data_in, r5_data_out;          // Round 5 registers
    reg [127:0] r6_data_in, r6_data_out;          // Round 6 registers
    reg [127:0] r7_data_in, r7_data_out;          // Round 7 registers
    reg [127:0] r8_data_in, r8_data_out;          // Round 8 registers
    reg [127:0] r9_data_in, r9_data_out;          // Round 9 registers
    reg [127:0] r10_data_in, r10_data_out;        // Round 10 registers (final round)
    
    // Pipeline control registers
    reg r0_valid, r1_valid, r2_valid, r3_valid, r4_valid;
    reg r5_valid, r6_valid, r7_valid, r8_valid, r9_valid, r10_valid;
    
    // Store decrypt mode through pipeline stages
    reg r0_decrypt, r1_decrypt, r2_decrypt, r3_decrypt, r4_decrypt;
    reg r5_decrypt, r6_decrypt, r7_decrypt, r8_decrypt, r9_decrypt, r10_decrypt;
    
    // Intermediate signals for rounds
    wire [127:0] r1_round_out, r2_round_out, r3_round_out, r4_round_out, r5_round_out;
    wire [127:0] r6_round_out, r7_round_out, r8_round_out, r9_round_out, r10_round_out;
    
    // Instantiate key expansion module with flattened bus
    key_expansion key_exp_inst (
        .clk(clk),
        .rst(rst),
        .key(key),
        .round_keys_flat(round_keys_flat)
    );
    
    // Unflatten the bus back into an array
    assign round_keys[0] = round_keys_flat[127:0];
    assign round_keys[1] = round_keys_flat[255:128];
    assign round_keys[2] = round_keys_flat[383:256];
    assign round_keys[3] = round_keys_flat[511:384];
    assign round_keys[4] = round_keys_flat[639:512];
    assign round_keys[5] = round_keys_flat[767:640];
    assign round_keys[6] = round_keys_flat[895:768];
    assign round_keys[7] = round_keys_flat[1023:896];
    assign round_keys[8] = round_keys_flat[1151:1024];
    assign round_keys[9] = round_keys_flat[1279:1152];
    assign round_keys[10] = round_keys_flat[1407:1280];
    
    // Initial round (just AddRoundKey)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r0_data_out <= 128'b0;
            r0_valid <= 1'b0;
            r0_decrypt <= 1'b0;
        end else if (enable) begin
            // For encryption: apply round_key[0], for decryption: apply round_key[10]
            r0_data_out <= decrypt ? (data_in ^ round_keys[10]) : (data_in ^ round_keys[0]);
            r0_valid <= 1'b1;
            r0_decrypt <= decrypt;
        end else begin
            r0_valid <= 1'b0;
        end
    end
    
    // Round 1
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r1_data_in <= 128'b0;
            r1_valid <= 1'b0;
            r1_decrypt <= 1'b0;
        end else begin
            r1_data_in <= r0_data_out;
            r1_valid <= r0_valid;
            r1_decrypt <= r0_decrypt;
        end
    end
    
    // Encryption round 1
    wire [127:0] r1_enc_out;
    aes_round enc_round1_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r1_data_in),
        .round_key(round_keys[1]),
        .is_final_round(1'b0),
        .data_out(r1_enc_out)
    );
    
    // Decryption round 1
    wire [127:0] r1_dec_out;
    aes_inv_round dec_round1_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r1_data_in),
        .round_key(round_keys[9]),
        .is_first_round(1'b0),
        .data_out(r1_dec_out)
    );
    
    // Select between encryption and decryption output
    assign r1_round_out = r1_decrypt ? r1_dec_out : r1_enc_out;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r1_data_out <= 128'b0;
        end else begin
            r1_data_out <= r1_round_out;
        end
    end
    
    // Round 2
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r2_data_in <= 128'b0;
            r2_valid <= 1'b0;
            r2_decrypt <= 1'b0;
        end else begin
            r2_data_in <= r1_data_out;
            r2_valid <= r1_valid;
            r2_decrypt <= r1_decrypt;
        end
    end
    
    // Encryption round 2
    wire [127:0] r2_enc_out;
    aes_round enc_round2_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r2_data_in),
        .round_key(round_keys[2]),
        .is_final_round(1'b0),
        .data_out(r2_enc_out)
    );
    
    // Decryption round 2
    wire [127:0] r2_dec_out;
    aes_inv_round dec_round2_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r2_data_in),
        .round_key(round_keys[8]),
        .is_first_round(1'b0),
        .data_out(r2_dec_out)
    );
    
    // Select between encryption and decryption output
    assign r2_round_out = r2_decrypt ? r2_dec_out : r2_enc_out;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r2_data_out <= 128'b0;
        end else begin
            r2_data_out <= r2_round_out;
        end
    end
    
    // Round 3
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r3_data_in <= 128'b0;
            r3_valid <= 1'b0;
            r3_decrypt <= 1'b0;
        end else begin
            r3_data_in <= r2_data_out;
            r3_valid <= r2_valid;
            r3_decrypt <= r2_decrypt;
        end
    end
    
    // Encryption round 3
    wire [127:0] r3_enc_out;
    aes_round enc_round3_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r3_data_in),
        .round_key(round_keys[3]),
        .is_final_round(1'b0),
        .data_out(r3_enc_out)
    );
    
    // Decryption round 3
    wire [127:0] r3_dec_out;
    aes_inv_round dec_round3_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r3_data_in),
        .round_key(round_keys[7]),
        .is_first_round(1'b0),
        .data_out(r3_dec_out)
    );
    
    // Select between encryption and decryption output
    assign r3_round_out = r3_decrypt ? r3_dec_out : r3_enc_out;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r3_data_out <= 128'b0;
        end else begin
            r3_data_out <= r3_round_out;
        end
    end
    
    // Round 4
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r4_data_in <= 128'b0;
            r4_valid <= 1'b0;
            r4_decrypt <= 1'b0;
        end else begin
            r4_data_in <= r3_data_out;
            r4_valid <= r3_valid;
            r4_decrypt <= r3_decrypt;
        end
    end
    
    // Encryption round 4
    wire [127:0] r4_enc_out;
    aes_round enc_round4_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r4_data_in),
        .round_key(round_keys[4]),
        .is_final_round(1'b0),
        .data_out(r4_enc_out)
    );
    
    // Decryption round 4
    wire [127:0] r4_dec_out;
    aes_inv_round dec_round4_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r4_data_in),
        .round_key(round_keys[6]),
        .is_first_round(1'b0),
        .data_out(r4_dec_out)
    );
    
    // Select between encryption and decryption output
    assign r4_round_out = r4_decrypt ? r4_dec_out : r4_enc_out;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r4_data_out <= 128'b0;
        end else begin
            r4_data_out <= r4_round_out;
        end
    end
    
    // Round 5
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r5_data_in <= 128'b0;
            r5_valid <= 1'b0;
            r5_decrypt <= 1'b0;
        end else begin
            r5_data_in <= r4_data_out;
            r5_valid <= r4_valid;
            r5_decrypt <= r4_decrypt;
        end
    end
    
    // Encryption round 5
    wire [127:0] r5_enc_out;
    aes_round enc_round5_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r5_data_in),
        .round_key(round_keys[5]),
        .is_final_round(1'b0),
        .data_out(r5_enc_out)
    );
    
    // Decryption round 5
    wire [127:0] r5_dec_out;
    aes_inv_round dec_round5_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r5_data_in),
        .round_key(round_keys[5]),
        .is_first_round(1'b0),
        .data_out(r5_dec_out)
    );
    
    // Select between encryption and decryption output
    assign r5_round_out = r5_decrypt ? r5_dec_out : r5_enc_out;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r5_data_out <= 128'b0;
        end else begin
            r5_data_out <= r5_round_out;
        end
    end
    
    // Round 6
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r6_data_in <= 128'b0;
            r6_valid <= 1'b0;
            r6_decrypt <= 1'b0;
        end else begin
            r6_data_in <= r5_data_out;
            r6_valid <= r5_valid;
            r6_decrypt <= r5_decrypt;
        end
    end
    
    // Encryption round 6
    wire [127:0] r6_enc_out;
    aes_round enc_round6_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r6_data_in),
        .round_key(round_keys[6]),
        .is_final_round(1'b0),
        .data_out(r6_enc_out)
    );
    
    // Decryption round 6
    wire [127:0] r6_dec_out;
    aes_inv_round dec_round6_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r6_data_in),
        .round_key(round_keys[4]),
        .is_first_round(1'b0),
        .data_out(r6_dec_out)
    );
    
    // Select between encryption and decryption output
    assign r6_round_out = r6_decrypt ? r6_dec_out : r6_enc_out;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r6_data_out <= 128'b0;
        end else begin
            r6_data_out <= r6_round_out;
        end
    end
    
    // Round 7
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r7_data_in <= 128'b0;
            r7_valid <= 1'b0;
            r7_decrypt <= 1'b0;
        end else begin
            r7_data_in <= r6_data_out;
            r7_valid <= r6_valid;
            r7_decrypt <= r6_decrypt;
        end
    end
    
    // Encryption round 7
    wire [127:0] r7_enc_out;
    aes_round enc_round7_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r7_data_in),
        .round_key(round_keys[7]),
        .is_final_round(1'b0),
        .data_out(r7_enc_out)
    );
    
    // Decryption round 7
    wire [127:0] r7_dec_out;
    aes_inv_round dec_round7_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r7_data_in),
        .round_key(round_keys[3]),
        .is_first_round(1'b0),
        .data_out(r7_dec_out)
    );
    
    // Select between encryption and decryption output
    assign r7_round_out = r7_decrypt ? r7_dec_out : r7_enc_out;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r7_data_out <= 128'b0;
        end else begin
            r7_data_out <= r7_round_out;
        end
    end
    
    // Round 8
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r8_data_in <= 128'b0;
            r8_valid <= 1'b0;
            r8_decrypt <= 1'b0;
        end else begin
            r8_data_in <= r7_data_out;
            r8_valid <= r7_valid;
            r8_decrypt <= r7_decrypt;
        end
    end
    
    // Encryption round 8
    wire [127:0] r8_enc_out;
    aes_round enc_round8_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r8_data_in),
        .round_key(round_keys[8]),
        .is_final_round(1'b0),
        .data_out(r8_enc_out)
    );
    
    // Decryption round 8
    wire [127:0] r8_dec_out;
    aes_inv_round dec_round8_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r8_data_in),
        .round_key(round_keys[2]),
        .is_first_round(1'b0),
        .data_out(r8_dec_out)
    );
    
    // Select between encryption and decryption output
    assign r8_round_out = r8_decrypt ? r8_dec_out : r8_enc_out;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r8_data_out <= 128'b0;
        end else begin
            r8_data_out <= r8_round_out;
        end
    end
    
    // Round 9
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r9_data_in <= 128'b0;
            r9_valid <= 1'b0;
            r9_decrypt <= 1'b0;
        end else begin
            r9_data_in <= r8_data_out;
            r9_valid <= r8_valid;
            r9_decrypt <= r8_decrypt;
        end
    end
    
    // Encryption round 9
    wire [127:0] r9_enc_out;
    aes_round enc_round9_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r9_data_in),
        .round_key(round_keys[9]),
        .is_final_round(1'b0),
        .data_out(r9_enc_out)
    );
    
    // Decryption round 9
    wire [127:0] r9_dec_out;
    aes_inv_round dec_round9_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r9_data_in),
        .round_key(round_keys[1]),
        .is_first_round(1'b0),
        .data_out(r9_dec_out)
    );
    
    // Select between encryption and decryption output
    assign r9_round_out = r9_decrypt ? r9_dec_out : r9_enc_out;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r9_data_out <= 128'b0;
        end else begin
            r9_data_out <= r9_round_out;
        end
    end
    
    // Round 10 (Final/First round)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r10_data_in <= 128'b0;
            r10_valid <= 1'b0;
            r10_decrypt <= 1'b0;
        end else begin
            r10_data_in <= r9_data_out;
            r10_valid <= r9_valid;
            r10_decrypt <= r9_decrypt;
        end
    end
    
    // Encryption round 10 (final round)
    wire [127:0] r10_enc_out;
    aes_round enc_round10_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r10_data_in),
        .round_key(round_keys[10]),
        .is_final_round(1'b1),  // This is the final round for encryption
        .data_out(r10_enc_out)
    );
    
    // Decryption round 10 (first round of decryption)
    wire [127:0] r10_dec_out;
    aes_inv_round dec_round10_inst (
        .clk(clk),
        .rst(rst),
        .data_in(r10_data_in),
        .round_key(round_keys[0]),
        .is_first_round(1'b1),  // This is the first round for decryption
        .data_out(r10_dec_out)
    );
    
    // Select between encryption and decryption output
    assign r10_round_out = r10_decrypt ? r10_dec_out : r10_enc_out;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r10_data_out <= 128'b0;
        end else begin
            r10_data_out <= r10_round_out;
        end
    end
    
    // Output assignments
    assign data_out = r10_data_out;
    assign valid_out = r10_valid;
    
    // This pipelined implementation:
    // - Supports both encryption and decryption
    // - Takes 10 clock cycles to fill the pipeline
    // - After that, produces one result per clock cycle (throughput = 1 block/cycle)
    // - Has a latency of 10 cycles from input to output
    // - Can process multiple blocks in parallel at different pipeline stages
endmodule
