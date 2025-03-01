`timescale 1ns / 1ps

module master_module(
    input wire clk,              // 90 MHz clock domain
    input wire rst_n,            // Active low reset
    // Interface to Async FIFO for commands (master to memory)
    output reg cmd_fifo_wr_en,
    output reg [16:0] cmd_fifo_data,  // [16] = op_type (0=read, 1=write), [15:8] = address, [7:0] = write_data
    input wire cmd_fifo_full,
    // Interface to Async FIFO for results (memory to master)
    output reg resp_fifo_rd_en,
    input wire [7:0] resp_fifo_data,  // Response data (read results)
    input wire resp_fifo_empty,
    // Status and control
    input wire start_operations,  // Signal to start the test pattern
    output reg busy,              // Indicates operations in progress
    output reg [7:0] debug_data,  // Debug data output
    output reg operation_success  // Indicates if read data matches expected values
);

    // Define states
    localparam IDLE = 0,
               WRITE_DATA = 1,
               WAIT_WRITE_COMPLETE = 2,
               READ_DATA = 3,
               WAIT_READ_RESPONSE = 4,
               VERIFY_DATA = 5,
               DONE = 6;
               
    reg [2:0] state;
    reg [7:0] test_addr;         // Current test address
    reg [7:0] expected_data;     // Expected data to be read
    reg [3:0] operation_count;   // Counts operations completed
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            test_addr <= 8'h00;
            cmd_fifo_wr_en <= 1'b0;
            cmd_fifo_data <= 17'h00000;
            resp_fifo_rd_en <= 1'b0;
            busy <= 1'b0;
            debug_data <= 8'h00;
            operation_success <= 1'b1;
            operation_count <= 4'h0;
            expected_data <= 8'h00;
        end else begin
            // Default signal states
            cmd_fifo_wr_en <= 1'b0;
            resp_fifo_rd_en <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (start_operations) begin
                        busy <= 1'b1;
                        state <= WRITE_DATA;
                        test_addr <= 8'h10; // Start with address 0x10
                        operation_count <= 4'h0;
                        operation_success <= 1'b1;
                    end else begin
                        busy <= 1'b0;
                    end
                end
                
                WRITE_DATA: begin
                    if (!cmd_fifo_full) begin
                        // Prepare write command: [16]=1 (write), [15:8]=address, [7:0]=data
                        cmd_fifo_data <= {1'b1, test_addr, test_addr + 8'h5A}; // Write data pattern is addr + 0x5A
                        cmd_fifo_wr_en <= 1'b1;
                        expected_data <= test_addr + 8'h5A; // Store expected data for verification
                        state <= WAIT_WRITE_COMPLETE;
                    end
                end
                
                WAIT_WRITE_COMPLETE: begin
                    // Small delay to ensure write completes
                    state <= READ_DATA;
                end
                
                READ_DATA: begin
                    if (!cmd_fifo_full) begin
                        // Prepare read command: [16]=0 (read), [15:8]=address, [7:0]=don't care
                        cmd_fifo_data <= {1'b0, test_addr, 8'h00};
                        cmd_fifo_wr_en <= 1'b1;
                        state <= WAIT_READ_RESPONSE;
                    end
                end
                
                WAIT_READ_RESPONSE: begin
                    if (!resp_fifo_empty) begin
                        resp_fifo_rd_en <= 1'b1;
                        state <= VERIFY_DATA;
                    end
                end
                
                VERIFY_DATA: begin
                    debug_data <= resp_fifo_data; // Output read data for debugging
                    
                    // Check if read data matches expected data
                    if (resp_fifo_data != expected_data) begin
                        operation_success <= 1'b0; // Mismatch detected
                    end
                    
                    // Increment address and operation counter
                    test_addr <= test_addr + 8'h10;
                    operation_count <= operation_count + 4'h1;
                    
                    // Decide if we're done or continue with more operations
                    if (operation_count == 4'hF) begin
                        state <= DONE;
                    end else begin
                        state <= WRITE_DATA;
                    end
                end
                
                DONE: begin
                    busy <= 1'b0;
                    if (start_operations) begin
                        // Remain in DONE until start is deasserted
                    end else begin
                        state <= IDLE; // Return to IDLE when start is deasserted
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
</kodu_content>