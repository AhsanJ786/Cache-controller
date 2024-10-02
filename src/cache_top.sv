module cache_top#(
    parameter DATA_WIDTH = 32,   // Data bus width
    parameter CACHE_SIZE = 1024, // Cache size (number of blocks)
    parameter OFFSET_SIZE = 2,   // Block size in words
    parameter INDEX_SIZE = 10,   // Index size (log2(CACHE_SIZE))
    parameter ADDRESS_WIDTH = 32 // Width of the address bus
)(
    input  logic clk,
    input  logic rst,
    input  logic CPU_request,
    input  logic [DATA_WIDTH-1:0] mem_data_in,
    output logic [DATA_WIDTH-1:0] mem_data_out,
    output logic mem_rd_en,
    output logic mem_wr_en,
    input  logic mem_ack,
    input  logic [ADDRESS_WIDTH-1:0] cpu_addr,
    input  logic [DATA_WIDTH-1:0] cpu_data_in,
    input  logic CPU_rd_wr,
    input  logic Flush,                     // Flush signal from CPU or external source
    output logic [DATA_WIDTH-1:0] cpu_data_out,
    output logic Stall                      // Signal to stall CPU if necessary
);

    // Internal signals
    logic Cache_hit, Dirty_bit;
    logic cache_flush, cache_writeback, cache_allocate;
    logic flush_done ; // Simple flush_done signal
    logic cache_enable;

    // Instantiate the datapath
    cache_datapath #(
        .DATA_WIDTH(DATA_WIDTH),
        .CACHE_SIZE(CACHE_SIZE),
        .OFFSET_SIZE(OFFSET_SIZE),
        .INDEX_SIZE(INDEX_SIZE),
        .ADDRESS_WIDTH(ADDRESS_WIDTH)
    ) datapath (
        .clk(clk),
        .rst(rst),
        .cpu_addr(cpu_addr),
        .cpu_data_in(cpu_data_in),
        .CPU_rd_wr(CPU_rd_wr),
        .cache_enable(cache_enable),
        .cache_flush(cache_flush),
        .cache_writeback(cache_writeback),
        .cache_allocate(cache_allocate),
        .Cache_hit(Cache_hit),
        .Dirty_bit(Dirty_bit),
        .cpu_data_out(cpu_data_out),
        .mem_data_in(mem_data_in),   // This should be connected to the main memory data bus
        .mem_data_out(mem_data_out), // This should be connected to the main memory data bus
        .flush_done(flush_done)
    );

    // Instantiate the controller
    cache_controller controller (
        .clk(clk),
        .rst(rst),
        .CPU_request(CPU_request),
        .Cache_hit(Cache_hit),
        .Dirty_bit(Dirty_bit),
        .Main_mem_ack(mem_ack),
        .flush_done(flush_done),
        .Flush(Flush),
        .cache_flush(cache_flush),
        .cache_writeback(cache_writeback),
        .cache_allocate(cache_allocate),
        .Stall(Stall),
        .cache_enable(cache_enable),
        .mem_rd_en(mem_rd_en),
        .mem_wr_en(mem_wr_en)
    );
endmodule