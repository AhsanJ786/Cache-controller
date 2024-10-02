module cache_controller (
    input  logic clk,
    input  logic rst,
    input  logic CPU_request,          // Signal indicating CPU has a request
    input  logic Cache_hit,            // Signal indicating a cache hit
    input  logic Dirty_bit,            // Signal indicating dirty bit is set
    input  logic Main_mem_ack,         // Signal indicating acknowledgment from main memory
    input  logic flush_done,           // Signal indicating flush is done
    input  logic Flush,                // Signal indicating a flush command (from fence)
    output logic cache_flush,          // Control signal to flush cache
    output logic cache_writeback,      // Control signal to perform write-back
    output logic cache_allocate,       // Control signal to allocate cache
    output logic Stall,                 // Signal to stall CPU if necessary
    output logic cache_enable,
    output logic mem_rd_en,
    output logic mem_wr_en
);

    // State encoding
    typedef enum logic [2:0] {
        Idle = 3'b000,
        Process_Request = 3'b001,
        Cache_Allocate = 3'b010,
        Writeback = 3'b011,
        Flush_State = 3'b100
    } state_t;

    state_t current_state, next_state;

    // State transition logic
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= Idle;
        end else begin
            current_state <= next_state;
        end
    end

    // Next state logic and outputs
    always_comb begin
        // Default outputs
        cache_flush     = 0;
        cache_writeback = 0;
        cache_allocate  = 0;
        Stall           = 0;
        cache_enable    = 0;
        mem_rd_en       = 0;
        mem_wr_en       = 0;

        case (current_state)
            Idle: begin
                if (CPU_request) 
                begin
                    if (Cache_hit & ~Dirty_bit) 
                    begin
                        cache_enable    = 1'b1;
                        Stall           = 1'b0;
                        cache_flush     = 0;
                        cache_writeback = 0;
                        cache_allocate  = 0;
                        mem_rd_en       = 0;
                        mem_wr_en       = 0;
                        next_state      = Idle; // Stay in Idle if there's a cache hit
                    end 
                    else if (Dirty_bit & ~Cache_hit) 
                    begin
                        next_state      = Writeback;
                        cache_enable    = 1'b0;
                        cache_writeback = 1'b0;
                        Stall           = 1'b0;   // Stall CPU during write-back
                        cache_allocate  = 0;
                        cache_flush     = 0;
                        mem_rd_en       = 0;
                        mem_wr_en       = 0;
                    end
                    else if ((~Dirty_bit & ~Cache_hit) )
                    begin
                        next_state      = Cache_Allocate;
                        cache_allocate  = 0;
                        Stall           = 0; // Stall CPU during cache allocation
                        cache_enable    = 0;
                        cache_writeback = 1'b0;
                        cache_flush     = 0;
                        mem_rd_en       = 0;
                        mem_wr_en       = 0;
                    end
                    else 
                    begin
                        cache_enable    = 1'b1;
                        Stall           = 1'b0;
                        cache_flush     = 0;
                        cache_writeback = 1;
                        cache_allocate  = 0;
                        mem_rd_en       = 0;
                        mem_wr_en       = 1;
                        next_state      = Idle; // Stay in Idle if there's a cache hit
                        
                    end
                end 
                else if (Flush) 
                begin
                    next_state       = Flush_State;
                end
            end

            Writeback: begin
                if (Main_mem_ack & ~Flush) 
                begin
                    next_state     = Cache_Allocate;
                    cache_allocate = 1;
                    Stall          = 1; // Continue stalling CPU
                    cache_enable   = 0;
                    cache_writeback= 0;
                    cache_flush    = 0;
                    mem_rd_en      = 1;
                    mem_wr_en      = 0;
                end
                else if (Main_mem_ack & Flush) 
                begin
                    next_state     = Flush_State;
                    cache_allocate = 0;
                    Stall          = 1; // Continue stalling CPU
                    cache_enable   = 0;
                    cache_flush    = 1;
                    cache_writeback= 0;
                    mem_rd_en      = 0;
                    mem_wr_en      = 1;
                    
                end
                else 
                begin
                    next_state     = Writeback;
                    cache_enable   = 0;
                    cache_writeback= 1;
                    cache_allocate = 0;
                    Stall          = 1; // Continue stalling CPU  
                    mem_rd_en      = 0;
                    mem_wr_en      = 1;
                end
            end

            Cache_Allocate: begin
                if (Main_mem_ack) 
                begin
                    next_state     = Idle;
                    Stall          = 1; // Resume CPU operations
                    cache_enable   = 1;
                    cache_allocate = 0;
                    cache_writeback= 0;
                    mem_rd_en      = 0;
                    mem_wr_en      = 0;
                end 
                else 
                begin
                    next_state     = Cache_Allocate;
                    Stall          = 1; // Stall CPU 
                    cache_enable   = 0;
                    cache_allocate = 1;
                    cache_flush    = 0;
                    cache_writeback= 0;
                    mem_rd_en      = 1;
                    mem_wr_en      = 0;
                end
            end

            Flush_State: begin
                cache_flush = 1;
                if (flush_done) begin
                    next_state      = Idle;
                    cache_flush     = 0;
                    cache_writeback = 0;
                    cache_allocate  = 0;
                    Stall           = 0;
                    cache_enable    = 1;
                    mem_rd_en       = 0;
                    mem_wr_en       = 0;
                end
                else 
                begin
                    cache_flush     = 1;
                    cache_writeback = 0;
                    cache_allocate  = 0;
                    Stall           = 1;
                    cache_enable    = 0;
                    mem_rd_en       = 0;
                    mem_wr_en       = 1; 
                    next_state      = Flush_State;                   
                end
            end

            default: next_state = Idle;
        endcase
    end

endmodule
