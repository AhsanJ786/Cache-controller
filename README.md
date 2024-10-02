# Cache Controller Design

This repository contains the Verilog/SystemVerilog implementation of a cache controller along with its corresponding datapath modules. The design follows a direct-mapped, write-back cache architecture to interface between a CPU and main memory. The cache controller is yet to be integrated with the AXI4-Lite interface.

## Overview

The cache controller is a key component in the memory hierarchy, aiming to bridge the gap between the CPU and slower main memory. It handles memory requests from the CPU efficiently to provide fast access to frequently used data. The repository includes the following modules:

- `cache_top.sv`: Top-level module that connects the CPU to the cache datapath and controller.
- `cache_controller.sv`: Implements the control logic for cache management.
- `cache_datapath.sv`: Implements the data storage and transfer mechanisms for the cache.

## Features

- **Direct-Mapped Cache**: The cache architecture is direct-mapped, which means each memory block is mapped to exactly one cache line.
- **Write-Back Policy**: This cache uses a write-back policy, meaning data modifications are written back to the main memory only when necessary.
- **Flush and Allocation Logic**: Supports flush operations and allocation for cache lines.
- **Interfaces**: The current version of the design includes CPU signals for read and write, as well as stall signals for memory access. AXI4-Lite integration is under development.


## Modules

### `cache_top.sv`
The top-level module connecting the CPU, cache datapath, and cache controller. It handles the following:

- Interface signals with the CPU (`cpu_data_in`, `cpu_data_out`, `cpu_addr`, etc.)
- Cache operations such as data read/write, flush, and allocation.

### `cache_controller.sv`
Contains the control logic for managing cache hits, cache misses, write-back operations, and interfacing with the cache datapath for data management.

### `cache_datapath.sv`
The datapath that stores the actual cache lines, manages the read and write operations from/to memory, and interacts with the cache controller.

## AXI4-Lite Integration

The AXI4-Lite interface is planned to provide communication between the cache and main memory. This integration will enable efficient data transfer to and from the cache. The implementation is currently in progress.

## Future Work

- Complete the AXI4-Lite integration for interfacing with main memory.
- Develop testbenches for functional verification of the cache design.
- Add support for configurable cache sizes and associativity levels.





