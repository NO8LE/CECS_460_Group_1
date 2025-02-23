`timescale 1ns/1ps

module axi_lite_bram_tb();

    // tb parameters
    localparam ADDR_WIDTH = 8;
    localparam DATA_WIDTH = 8;

    // clk / rst
    reg ACLK;
    reg ARESETN;

    // AXI4-Lite Slave signals
    reg                  AWVALID;
    wire                 AWREADY;
    reg [ADDR_WIDTH-1:0] AWADDR;
    
    reg                  WVALID;
    wire                 WREADY;
    reg [DATA_WIDTH-1:0] WDATA;
    reg [DATA_WIDTH/8-1:0] WSTRB;
    
    wire                 BVALID;
    reg                  BREADY;
    wire [1:0]           BRESP;
    
    reg                  ARVALID;
    wire                 ARREADY;
    reg [ADDR_WIDTH-1:0] ARADDR;
    
    wire                 RVALID;
    reg                  RREADY;
    wire [DATA_WIDTH-1:0] RDATA;
    wire [1:0]           RRESP;

    // instantiate the DUT
    axi_lite_bram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .ACLK(ACLK),
        .ARESETN(ARESETN),

        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .AWADDR(AWADDR),

        .WVALID(WVALID),
        .WREADY(WREADY),
        .WDATA(WDATA),
        .WSTRB(WSTRB),

        .BVALID(BVALID),
        .BREADY(BREADY),
        .BRESP(BRESP),

        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .ARADDR(ARADDR),

        .RVALID(RVALID),
        .RREADY(RREADY),
        .RDATA(RDATA),
        .RRESP(RRESP)
    );

    // clk generation
    initial begin
        ACLK = 0;
        forever #5 ACLK = ~ACLK; // 100MHz => 10ns period
    end

    // rst sequence
    initial begin
        ARESETN = 0;
        #30;
        ARESETN = 1;
    end

    // Test scenario
    initial begin
        // Initialize signals
        AWVALID = 0;
        AWADDR  = 0;
        WVALID  = 0;
        WDATA   = 0;
        WSTRB   = 1'b1; // 8-bit :. write byte
        BREADY  = 0;

        ARVALID = 0;
        ARADDR  = 0;
        RREADY  = 0;

        // Wait for reset deassert
        @(posedge ARESETN);

        // W/R sequence
        // Write to address 4 => data 8'hAB
        axi_write(8'h04, 8'hAB);
        // Read back from address 4
        axi_read(8'h04);

        // write => address 10 => data 8'h69
        axi_write(8'h0A, 8'h69);
        // Read back from address 10
        axi_read(8'h0A);

        // Concurrent read and write 
        // Write to address 8'h0F => data 8'h77
        // Read from address 8'h0F at the same time
        fork
            begin
                axi_write(8'h0F, 8'h77);
            end
            begin
                axi_read(8'h0F);
            end
        join

        // Check if new data updated
        axi_read(8'h0F);

        #50;
        $finish;
    end

    // AXI Write
    task axi_write(
        input [ADDR_WIDTH-1:0] waddr,
        input [DATA_WIDTH-1:0] wdata
    );
    begin
        // Address phase
        @(posedge ACLK);
        AWVALID <= 1'b1;
        AWADDR  <= waddr;
        // wait until AWREADY
        while (!AWREADY) @(posedge ACLK);
        @(posedge ACLK);
        AWVALID <= 1'b0;

        // Data phase
        WVALID <= 1'b1;
        WDATA  <= wdata;
        while (!WREADY) @(posedge ACLK);
        @(posedge ACLK);
        WVALID <= 1'b0;

        // Response phase
        // wait for BVALID
        while (!BVALID) @(posedge ACLK);
        BREADY <= 1'b1;
        @(posedge ACLK);
        BREADY <= 1'b0;

        $display("[WRITE] Addr=0x%0h, Data=0x%0h at time %t", waddr, wdata, $time);
    end
    endtask

    // AXI Read
    task axi_read(
        input [ADDR_WIDTH-1:0] raddr
    );
    begin
        // Address phase
        @(posedge ACLK);
        ARVALID <= 1'b1;
        ARADDR  <= raddr;
        // wait until ARREADY
        while (!ARREADY) @(posedge ACLK);
        @(posedge ACLK);
        ARVALID <= 1'b0;

        // Data phase
        // wait for RVALID
        while (!RVALID) @(posedge ACLK);
        RREADY <= 1'b1;
        @(posedge ACLK);
        RREADY <= 1'b0;

        $display("[READ ] Addr=0x%0h, Data=0x%0h at time %t", raddr, RDATA, $time);
    end
    endtask

endmodule