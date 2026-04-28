# Systolic Array Matrix Multiplication Accelerator

An 8×8 Systolic Array hardware accelerator implemented on the PYNQ-Z2 FPGA. This project optimizes matrix multiplication by leveraging parallel processing elements (PEs) and pipelined data flow to achieve high throughput and low latency.

## Key Features
* **Systolic Architecture:** 8×8 grid of Processing Elements (PEs) designed for parallel MAC (Multiply-Accumulate) operations.
* **AXI-Stream Integration:** Utilizes AXI4-Stream interfaces for high-speed, address-free data streaming.
* **DMA-Powered Transfers:** Leveraging Direct Memory Access for efficient data movement between DDR memory and the FPGA fabric.
* **Ping-Pong Buffering:** Overlaps computation with I/O operations to eliminate idle hardware cycles.
* **Python Control:** Seamless orchestration via Jupyter Notebook using the PYNQ framework and GPIO signaling.

## Architecture Overview
The design consists of a mesh of PEs where data flows rhythmically through the network. Each PE computes a partial product and passes data to its neighbors, minimizing global memory access and maximizing data reuse.

### Data Flow
1. **Input:** Matrix data is sent from Python (Jupyter) to DDR memory.
2. **Transfer:** The DMA engine streams data into the FPGA via the AXI-Stream interface.
3. **Buffering:** Ping-pong buffers hold the current tiles while the next set of data is pre-fetched.
4. **Compute:** The systolic array processes the 8×8 multiplication in a pipelined fashion.
5. **Output:** The result is streamed back to the processor via DMA.

## Hardware Specifications
* **FPGA Board:** PYNQ-Z2 (Zynq-7000 SoC)
* **Matrix Size:** 8×8 (Scalable)
* **Interface:** AXI4-Stream, AXI-Lite (for control)
* **Tools:** Vivado Design Suite, Vitis HLS/Verilog, Jupyter Notebook

## Getting Started
1. **Bitstream Deployment:** Load the `.bit` and `.hwh` files onto your PYNQ-Z2 board.
2. **Python Overlay:** Use the `pynq.Overlay` library to download the hardware logic.
3. **Run Notebook:** Execute the provided Jupyter Notebook to initialize the matrices, trigger the DMA, and verify the results against NumPy.

## Results
The hardware accelerator demonstrates significant speedup compared to software-only execution by exploiting spatial parallelism through the systolic data path.
