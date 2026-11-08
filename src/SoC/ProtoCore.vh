`ifndef PROTOCORE_VH
`define PROTOCORE_VH


//----------------------------
// System Clock
//----------------------------
`define SYS_CLK_HZ 100_000_000

//----------------------------
// UART
//----------------------------
`define UART_BAUD_RATE 115200

//----------------------------
// MMIO Addresses
//----------------------------
`define MMIO_LED_LO  8'h00
`define MMIO_LED_HI  8'h01
`define MMIO_UART_RX 8'h02
`define MMIO_UART_TX 8'h03
`define MMIO_UART_ST 8'h04
`define MMIO_GPHC_ST 8'h05
`define MMIO_VRAM_AD 8'h06

//----------------------------
// Graphics
//----------------------------
`define FMT_OFF         3'h0

// Tier 1: 128 Bytes (Double-buffer friendly)
`define FMT_32x32_1BPP  3'h1
`define FMT_32x16_2BPP  3'h2
`define FMT_16x16_4BPP  3'h3

// Tier 2: 256 Bytes (Max single frame)
`define FMT_64x32_1BPP  3'h4
`define FMT_32x32_2BPP  3'h5
`define FMT_32x16_4BPP  3'h6
`define FMT_16x16_8BPP  3'h7

//----------------------------
// System Commands
//----------------------------
`define SYS_CMD_PROG        8'hF1
`define SYS_CMD_END_PROG_KP 8'hF2
`define SYS_CMD_END_PROG_RS 8'hF3
`define SYS_CMD_MMIO_LED    8'hF4
`define SYS_CMD_REG_LED     8'hF5
`define SYS_CMD_DEBUG       8'hF6
`define SYS_CMD_RST_CPU     8'hF7
`define SYS_CMD_STEP_PC     8'hF8

//----------------------------
// Instruction Set
//----------------------------
`define OP_ADD   4'b0000
`define OP_SUB   4'b0001
`define OP_AND   4'b0010
`define OP_OR    4'b0011
`define OP_XOR   4'b0100
`define OP_NOT   4'b0101
`define OP_SHL   4'b0110
`define OP_SHR   4'b0111
`define OP_ADDI  4'b1000
`define OP_ANDI  4'b1001
`define OP_LOAD  4'b1010
`define OP_STORE 4'b1011
`define OP_BEQ   4'b1100
`define OP_BNE   4'b1101
`define OP_JMP   4'b1110
`define OP_HALT  4'b1111

`endif