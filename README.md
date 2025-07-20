# ProtoCore

**A Custom 8-bit CPU Core with 24-bit Instruction Format for Learning and Exploration**

ProtoCore is a RISC-inspired CPU core implemented in Verilog, designed as an educational platform for learning CPU architecture and hardware design. The project aims to grow into a comprehensive CPU ecosystem, including hardware, software tools, testbenches, and simulation frameworks.

---

## Features

- 24-bit fixed-width instruction format  
- Load/store architecture with 16 general-purpose 8-bit registers  
- Supports indirect jumps with register + immediate offset  
- Simple, uniform instruction encoding: OPCODE_RA_RB_RD_IMM  
- Modular Verilog design for easy experimentation and extension  
- Basic memory interface for instruction and data fetch/store, supporting up to 256x8-bit RAM  
- Custom Instruction Set Architecture with documented examples  
- Support for a custom assembly language via the included `Assembler.py` script
- Automated `run_tests.py` script to execute testbenches and generate formatted Excel logs for result validation


---

## Project Goals

- Serve as a hands-on learning platform for CPU architecture concepts  
- Provide a clean codebase for experimenting with ISA design and hardware implementation  
- Develop testbenches for verification and debugging  
- Expand gradually with software toolchain support (assembler, simulator)  

---

## Tools Used

- Xilinx Vivado Design Suite  
- Basys-3 FPGA development board with:  
  - 100 MHz clock  
  - 4x 7-segment display
  - 16x LEDs  
  - 4x switches  
  - 2x buttons  

---

## Getting Started

### Requirements

- Xilinx Vivado Design Suite (or another Verilog-compatible FPGA toolchain)*  
- Basic familiarity with Verilog and CPU architecture  
- FPGA development board (Basys-3 recommended for seamless integration)  

> **Note:** The Xilinx Synthesis Tool (XST) supports synthesizing ROM using `$readmemb`. Some other toolchains or IDEs may not support this feature, which can prevent accurate ROM synthesis. This limitation is intended to be addressed in future updates.

### Building

1. Clone the repository:  
   ```bash
   git clone https://github.com/CTipton27/ProtoCore.git
   ```
2. Create the project in your IDE:
- Add all source files; deselect “copy files into project” if possible.
- Optionally add simulation sources from the testbenches folder.
- Import the constraint file for Basys-3, or the appropriate constraints for your target device.
3. Generate the bitstream and program your FPGA.

---

## Usage
- Press BtnC (center D-Pad) to manually reset the CPU, setting the PC to 0.
- The seven-segment display outputs the current PC address.
- The 16 LEDs display the data contents of registers RB and RA, respectively.
