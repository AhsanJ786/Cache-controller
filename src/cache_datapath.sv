module cache_datapath#(
    parameter DATA_WIDTH = 32,              // Data bus width
    parameter CACHE_SIZE = 1024,            // Cache size (number of blocks)
    parameter OFFSET_SIZE = 2,              // Block size in words
    parameter INDEX_SIZE = 10,              // Index size (log2(CACHE_SIZE))
    parameter ADDRESS_WIDTH = 32            // Width of the address bus
)(
    input  logic clk, rst,
    input  logic [ADDRESS_WIDTH-1:0] cpu_addr,
    input  logic [DATA_WIDTH-1:0] cpu_data_in,
    input  logic CPU_rd_wr,
    input  logic cache_enable,
    input  logic cache_flush,               // Flush control signal from controller
    input  logic cache_writeback,           // Write-back control signal from controller
    input  logic cache_allocate,            // Cache allocate control signal from controller
    output logic Cache_hit, Dirty_bit,      // Cache hit and dirty bit outputs to controller
    output logic [DATA_WIDTH-1:0] cpu_data_out,
    input  logic [DATA_WIDTH-1:0] mem_data_in,
    output logic [DATA_WIDTH-1:0] mem_data_out,
    output logic flush_done
);

    // Internal storage
    logic [DATA_WIDTH-1:0] cache_memory [0:CACHE_SIZE-1];                         
    logic [ADDRESS_WIDTH-OFFSET_SIZE-INDEX_SIZE-1:0] tag_memory [0:CACHE_SIZE-1]; 
    logic [0:CACHE_SIZE-1] valid_bit_vector, dirty_bit_vector;
    logic [ADDRESS_WIDTH-OFFSET_SIZE-20-1:0] index_memory [0:CACHE_SIZE-1]; 

    // Cache memory decomposition
    logic [OFFSET_SIZE-1:0] offset;
    logic [INDEX_SIZE-1:0] index;
    logic [ADDRESS_WIDTH-INDEX_SIZE-OFFSET_SIZE-1:0] tag;
    logic [31:0] wb_addr;

    assign offset = cpu_addr[OFFSET_SIZE-1:0];
    assign index  = cpu_addr[INDEX_SIZE+OFFSET_SIZE-1:OFFSET_SIZE];
    assign tag    = cpu_addr[ADDRESS_WIDTH-1:INDEX_SIZE+OFFSET_SIZE];

    // Cache memory initialization
    always_ff @(posedge clk or negedge rst) begin
        if (~rst) begin
            for (int i = 0; i < CACHE_SIZE; i++) begin
                valid_bit_vector[i] <= 0;
                dirty_bit_vector[i] <= 0;
                tag_memory[i]       <= 0;
                cache_memory[i]     <= 32'b0;
                mem_data_out        <= 0;
            end
        end
    end

    // Cache hit logic
    assign Cache_hit = valid_bit_vector[index] & (tag_memory[index] == tag);
    assign Dirty_bit = dirty_bit_vector[index];

    // Cache read operation
    always_ff @(posedge clk) begin
        if (cache_enable && !CPU_rd_wr ) begin
            cpu_data_out <= cache_memory[index];
        end
    end

    // Cache write operation
    always_ff @(posedge clk) begin
        if (cache_enable && CPU_rd_wr) begin
            cache_memory[index]     <= cpu_data_in;
            dirty_bit_vector[index] <= 1;
            valid_bit_vector[index] <= 1;
        end
    end

    // Cache allocate (on cache miss) mechanism
    always_ff @(posedge clk) begin
        if (cache_allocate ) begin
            cache_memory[index]     <= mem_data_in[cpu_addr];
            tag_memory[index]       <= tag;
            valid_bit_vector[index] <= 1;
            dirty_bit_vector[index] <= 0;
        end
    end

    // Write-back mechanism (initiated by controller)
    always_ff @(posedge clk) begin
        if (cache_writeback) begin
    // Write the block back to memory
            mem_data_out[cpu_addr]  <= cache_memory[index];
            dirty_bit_vector[index] <= 0; 
        end
    end

    // Flush operation (initiated by controller)
    always_ff @(posedge clk) begin
        if (cache_flush) begin
            flush_done = 1'b0;
            for (int i = 0; i < CACHE_SIZE; i++) begin
                wb_addr = {tag_memory[i],i[9:0],2'b0};
                if( dirty_bit_vector[i] == 1)
                begin
                    mem_data_out[wb_addr]  <= cache_memory[index];
                end
                valid_bit_vector[i] <= 0;
                dirty_bit_vector[i] <= 0;
                tag_memory[i] <= 0;
                cache_memory[i] <= 32'b0;
            end
            flush_done = 1'b1;
        end
    end

endmodule
