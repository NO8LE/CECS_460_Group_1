`timescale 1ns/1ps

module axi_lite_bram #(
    parameter ADDR_WIDTH = 8,   // for 256-byte BRAM
    parameter DATA_WIDTH = 8
)
(
    input  wire                  ACLK,
    input  wire                  ARESETN,
    
    // Write address channel
    input  wire                  AWVALID,
    output reg                   AWREADY,
    input  wire [ADDR_WIDTH-1:0] AWADDR,
    
    // Write data channel
    input  wire                  WVALID,
    output reg                   WREADY,
    input  wire [DATA_WIDTH-1:0] WDATA,
    input  wire [DATA_WIDTH/8-1:0] WSTRB, // 8-bit data, WSTRB is 1 bit
    
    // Write response channel
    output reg                   BVALID,
    input  wire                  BREADY,
    output reg [1:0]            BRESP,
    
    // Read address channel
    input  wire                  ARVALID,
    output reg                   ARREADY,
    input  wire [ADDR_WIDTH-1:0] ARADDR,
    
    // Read data channel
    output reg                   RVALID,
    input  wire                  RREADY,
    output reg [DATA_WIDTH-1:0] RDATA,
    output reg [1:0]            RRESP
);


    // internal memory (BRAM)
    // 256-depth, 8-bit wide memory
    reg [DATA_WIDTH-1:0] bram [0:(1<<ADDR_WIDTH)-1];

    // Preload memory with a known pattern, e.g. bram[i] = i
    integer i;
    initial begin
        for (i = 0; i < (1<<ADDR_WIDTH); i = i + 1) begin
            bram[i] = i[DATA_WIDTH-1:0];
        end
    end

    // ------ AXI4-Lite State Machines -----
    // write channel handshake logic
    // we can handle AW and W in a simple handshake approach
    // and then generate BVALID.

    // we'll store the address locally once AW is done.
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    
    // Write address handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            AWREADY    <= 1'b0;
            awaddr_reg <= {ADDR_WIDTH{1'b0}};
        end else begin
            // default AWREADY high if we are ready to accept a new address
            if (!AWREADY && AWVALID) begin
                // zccept address
                AWREADY    <= 1'b1;
                awaddr_reg <= AWADDR;
            end else begin
                // Deassert once accepted
                AWREADY <= 1'b0;
            end
        end
    end

    // Write data handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            WREADY <= 1'b0;
        end else begin
            // Default WREADY high if we are ready to accept data
            if (!WREADY && WVALID) begin
                // Accept data
                WREADY <= 1'b1;
            end else begin
                // Deassert once accepted
                WREADY <= 1'b0;
            end
        end
    end

    // BRAM write on successful handshake
    always @(posedge ACLK) begin
        if (ARESETN && AWREADY && AWVALID && WREADY && WVALID) begin
            if (WSTRB[0]) begin
                bram[awaddr_reg] <= WDATA;
            end
        end
    end

    // W response generation
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            BVALID <= 1'b0;
            BRESP  <= 2'b00; // OKAY
        end else begin
            // Once we have AWVALID & WVALID handshake done, raise BVALID
            if (AWREADY && AWVALID && WREADY && WVALID) begin
                BVALID <= 1'b1;
                BRESP  <= 2'b00; // OKAY
            end else if (BREADY && BVALID) begin
                // Once master acknowledges (BREADY), deassert BVALID
                BVALID <= 1'b0;
            end
        end
    end

    // R channel handshake logic
    
    reg [ADDR_WIDTH-1:0] araddr_reg;

    // R address handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            ARREADY    <= 1'b0;
            araddr_reg <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (!ARREADY && ARVALID) begin
                ARREADY    <= 1'b1;
                araddr_reg <= ARADDR;
            end else begin
                ARREADY <= 1'b0;
            end
        end
    end

    // R data valid and data
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            RVALID <= 1'b0;
            RDATA  <= {DATA_WIDTH{1'b0}};
            RRESP  <= 2'b00;  // ok
        end else begin
            if (ARREADY && ARVALID) begin
                // Address handshake done, present data immediately
                RVALID <= 1'b1;
                RDATA  <= bram[araddr_reg];
                RRESP  <= 2'b00; // OKAY
            end else if (RVALID && RREADY) begin
                // Master acknowledges read data
                RVALID <= 1'b0;
            end
        end
    end

endmodule

