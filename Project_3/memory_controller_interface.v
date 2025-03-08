`timescale 1ns / 1ps

module memory_controller_interface(
    input wire clk,              // 65 MHz clock domain
    input wire rst_n,            // Active low reset
    // Interface to Async FIFO for commands (from master)
    output reg cmd_fifo_rd_en,
    input wire [16:0] cmd_fifo_data,  // [16] = op_type (0=read, 1=write), [15:8] = address, [7:0] = write_data
    input wire cmd_fifo_empty,
    // Interface to Async FIFO for results (to master)
    output reg resp_fifo_wr_en,
    output reg [7:0] resp_fifo_data,  // Response data (read results)
    input wire resp_fifo_full,
    // Interface to BRAM
    output reg [7:0] bram_address,
    output reg [7:0] bram_data_in,
    input wire [7:0] bram_data_out,
    output reg bram_wr_en,
    output reg bram_rd_en,
    input wire bram_op_done
);

    // Define states
    localparam IDLE = 0,
               READ_CMD = 1,
               EXECUTE_WRITE = 2,
               EXECUTE_READ = 3,
               WAIT_BRAM_DONE = 4,
               SEND_RESPONSE = 5;
               
    reg [2:0] state;
    reg op_type;  // 0 = read, 1 = write
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cmd_fifo_rd_en <= 1'b0;
            resp_fifo_wr_en <= 1'b0;
            resp_fifo_data <= 8'h00;
            bram_address <= 8'h00;
            bram_data_in <= 8'h00;
            bram_wr_en <= 1'b0;
            bram_rd_en <= 1'b0;
            op_type <= 1'b0;
        end else begin
            // Default signal states
            cmd_fifo_rd_en <= 1'b0;
            resp_fifo_wr_en <= 1'b0;
            bram_wr_en <= 1'b0;
            bram_rd_en <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (!cmd_fifo_empty) begin
                        state <= READ_CMD;
                    end
                end
                
                READ_CMD: begin
                    // Read the command from FIFO
                    cmd_fifo_rd_en <= 1'b1;
                    // Parse command fields
                    op_type <= cmd_fifo_data[16];        // Operation type
                    bram_address <= cmd_fifo_data[15:8]; // Address
                    bram_data_in <= cmd_fifo_data[7:0];  // Write data (if op_type is write)
                    
                    // Determine next state based on operation type
                    if (cmd_fifo_data[16]) begin  // Write operation
                        state <= EXECUTE_WRITE;
                    end else begin               // Read operation
                        state <= EXECUTE_READ;
                    end
                end
                
                EXECUTE_WRITE: begin
                    // Execute BRAM write operation
                    bram_wr_en <= 1'b1;
                    state <= WAIT_BRAM_DONE;
                end
                
                EXECUTE_READ: begin
                    // Execute BRAM read operation
                    bram_rd_en <= 1'b1;
                    state <= WAIT_BRAM_DONE;
                end
                
                WAIT_BRAM_DONE: begin
                    // Wait for BRAM operation to complete
                    if (bram_op_done) begin
                        if (op_type) begin
                            // For write operations, no response needed
                            state <= IDLE;
                        end else begin
                            // For read operations, send response back
                            state <= SEND_RESPONSE;
                            resp_fifo_data <= bram_data_out;
                        end
                    end
                end
                
                SEND_RESPONSE: begin
                    // Write read result to response FIFO if not full
                    if (!resp_fifo_full) begin
                        resp_fifo_wr_en <= 1'b1;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
