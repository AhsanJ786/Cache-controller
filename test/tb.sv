module tb_cache_top;

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter CACHE_SIZE = 1024;
    parameter OFFSET_SIZE = 2;
    parameter INDEX_SIZE = 10;
    parameter ADDRESS_WIDTH = 32;

    // Testbench signals
    logic clk, rst;
    logic CPU_request;
    logic [DATA_WIDTH-1:0] mem_data_in;
    logic [DATA_WIDTH-1:0] mem_data_out;
    logic mem_rd_en, mem_wr_en;
    logic mem_ack;
    logic [ADDRESS_WIDTH-1:0] cpu_addr;
    logic [DATA_WIDTH-1:0] cpu_data_in;
    logic CPU_rd_wr;
    logic Flush;
    logic [DATA_WIDTH-1:0] cpu_data_out;
    logic Stall;

    // Instantiate the cache_top module
    cache_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .CACHE_SIZE(CACHE_SIZE),
        .OFFSET_SIZE(OFFSET_SIZE),
        .INDEX_SIZE(INDEX_SIZE),
        .ADDRESS_WIDTH(ADDRESS_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .CPU_request(CPU_request),
        .mem_data_in(mem_data_in),
        .mem_data_out(mem_data_out),
        .mem_rd_en(mem_rd_en),
        .mem_wr_en(mem_wr_en),
        .mem_ack(mem_ack),
        .cpu_addr(cpu_addr),
        .cpu_data_in(cpu_data_in),
        .CPU_rd_wr(CPU_rd_wr),
        .Flush(Flush),
        .cpu_data_out(cpu_data_out),
        .Stall(Stall)
    );

    // Clock generation
    always #5 clk = ~clk; // 10ns clock period

    // Dummy Processor Task
    task dummy_processor(
        input logic [ADDRESS_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input logic rd_wr, // 0 for read, 1 for write
        input logic flush_signal
    );
        begin
            @(posedge clk);
            cpu_addr = addr;
            cpu_data_in = data;
            CPU_rd_wr = rd_wr;
            Flush = flush_signal;
            CPU_request = 1;
            @(posedge clk);

        end
    endtask

    // Dummy Main Memory Task
    task dummy_memory;
        begin
            mem_ack = 0;
                @(posedge clk);
                if (mem_rd_en) begin
                    // Simulate memory read
                    mem_data_in = $random; // Random data from memory
                    mem_ack = 1;
                end else if (mem_wr_en) begin
                    // Simulate memory write
                    mem_ack = 1;
                end else begin
                    mem_ack = 0;
                end
        end
        
    endtask
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0);
    end
    // Initial setup and test sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        CPU_request = 0;
        cpu_addr = 0;
        cpu_data_in = 0;
        CPU_rd_wr = 0;
        Flush = 0;
        mem_data_in = 0;
        mem_ack = 0;

        // Reset the system
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        rst = 1;

        // Start dummy memory task
        
            
        

        // Test sequence using dummy processor
        fork
        dummy_processor(32'h00000000, 32'hAAAAAAAA, 1, 0); // Write to address 0
        dummy_memory();
        join
        fork
        dummy_processor(32'h00000000, 32'hBBBBBBBB, 1, 0); // Write again to address 0
        dummy_memory();
        join
        fork
        dummy_processor(32'h00000000, 32'h00000000, 0, 0); // Read from address 0
        dummy_memory();
        join
        fork
        dummy_processor(32'h00000004, 32'hCCCCCCCC, 1, 0); // Write to address 4
        dummy_memory();
        join
        fork
        dummy_processor(32'h00000004, 32'h00000000, 0, 0); // Read from address 4
        dummy_memory();
        join
        fork
        dummy_processor(32'h00000000, 32'h00000000, 0, 1); // Flush with read from address 0
        dummy_memory();
        join

        // Finish simulation
        #100 $finish;
    end
endmodule
