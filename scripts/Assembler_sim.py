import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
script_dir = root / "scripts"
src_dir = root / "src"

assembly_src = script_dir / "Program.asm"
sim_src = src_dir / "program.txt"

formats = {
    "ADD":   {"format":["rd","ra","rb"],  "opcode":"0000"},
    "SUB":   {"format":["rd","ra","rb"],  "opcode":"0001"},
    "AND":   {"format":["rd","ra","rb"],  "opcode":"0010"},
    "OR":    {"format":["rd","ra","rb"],  "opcode":"0011"},
    "XOR":   {"format":["rd","ra","rb"],  "opcode":"0100"},
    "NOT":   {"format":["rd","ra"],       "opcode":"0101"},
    "SHL":   {"format":["rd","ra"],       "opcode":"0110"},
    "SHR":   {"format":["rd","ra"],       "opcode":"0111"},
    "ADDI":  {"format":["rd","ra","imm"], "opcode":"1000"},
    "ANDI":  {"format":["rd","ra","imm"], "opcode":"1001"},
    "LOAD":  {"format":["rd","ra","imm"], "opcode":"1010"},
    "STORE": {"format":["ra","rb","imm"], "opcode":"1011"},
    "BEQ":   {"format":["ra","rb","imm"], "opcode":"1100", "pc_relative": True},
    "BNE":   {"format":["ra","rb","imm"], "opcode":"1101", "pc_relative": True},
    "JMP":   {"format":["ra","imm"],      "opcode":"1110"},
    "HALT":  {"format":["imm"],           "opcode":"1111"},
}

expansions = {
    # Pseudoinstructions
    "NOP": [["ADD", "R0", "R0", "R0"]],
    "MOV": [["ADD", "{0}", "{1}", "R0"]],
    "CLR": [["ADD", "{0}", "R0", "R0"]],
    "INC": [["ADDI", "{0}", "{0}", "1"]],
    "DEC": [["ADDI", "{0}", "{0}", "-1"]],
    "NEG": [["SUB", "{0}", "R0", "{0}"]],
    "RJMP": [["BEQ", "R0", "R0", "{0}"]],
    "BEQZ": [["BEQ", "{0}", "R0", "{1}"]],
    "BNEZ": [["BNE", "{0}", "R0", "{1}"]],
    "LDI": [["ADDI", "{0}", "R0", "{1}"]],
    "JMPA": [["JMP", "R0", "{0}"]],

    # Macros
    "NOR": [
        ["OR", "{0}", "{1}", "{2}"],
        ["NOT", "{0}", "{0}"]
    ],
    "NAND": [
        ["AND", "{0}", "{1}", "{2}"],
        ["NOT", "{0}", "{0}"]
    ],
    "XNOR": [
        ["XOR", "{0}", "{1}", "{2}"],
        ["NOT", "{0}", "{0}"]
    ],
    "SWAP": [
        ["XOR", "{0}", "{1}", "{0}"],
        ["XOR", "{1}", "{0}", "{1}"],
        ["XOR", "{0}", "{1}", "{0}"]
    ]
}

def reg_to_bin(reg):
    if not reg.startswith("R"):
        raise ValueError(f"Invalid register {reg}")

    num = int(reg[1:])
    if not (0 <= num <= 15):
        raise ValueError(f"Invalid register {reg}")

    return f"{num:04b}"

def imm_to_bin(val):
    if isinstance(val, str):
        val_str = val.strip()
        # Handle explicit unsigned prefix 'u' or 'U' (e.g., "u255", "u0xFF")
        if val_str.lower().startswith('u'):
            val = int(val_str[1:], 0)
        else:
            val = int(val_str, 0)
    else:
        val = int(val)

    # Handle negative numbers (two's complement in 8 bits)
    if val < 0:
        val = val & 0xFF

    # Validate that it fits in an 8-bit field (0 to 255)
    if not (0 <= val <= 255):
        raise ValueError(f"Immediate out of range ({val})")

    return f"{val:08b}"

def expand_instruction(tokens):
    mnemonic = tokens[0]
    operands = tokens[1:]

    if mnemonic in expansions:
        templates = expansions[mnemonic]
    else:
        return [tokens]

    expanded = []
    for instruction in templates:
        expanded.append(
            [field.format(*operands) for field in instruction]
        )

    return expanded

# ----------------------------
# PASS 1
# ----------------------------

labels = {}
constants = {
    # MMIO registers placed in upper system memory bank (>= 0x0100)
    "MMIO_LED_LO" : "0x0100",
    "MMIO_LED_HI" : "0x0101",
    "MMIO_UART_RX": "0x0102",
    "MMIO_UART_TX": "0x0103",
    "MMIO_UART_ST": "0x0104",
    "MMIO_GPHC_ST": "0x0105",
    "MMIO_VRAM_AD": "0x0106",

    # Graphics formats with Trigger (Bit 7 = 1) + Format (Bits 6:4 = 1-7)
    "FMT_OFF"       : "0x00",
    "FMT_32x32_1BPP": "0x90",
    "FMT_32x16_2BPP": "0xA0",
    "FMT_16x16_4BPP": "0xB0",
    "FMT_64x32_1BPP": "0xC0",
    "FMT_32x32_2BPP": "0xD0",
    "FMT_32x16_4BPP": "0xE0",
    "FMT_16x16_8BPP": "0xF0",
}
program = []

pc = 0

with open(assembly_src) as src:
    for line in src:
        line = line.split(";")[0].strip()
        if not line:
            continue

        if line.lower().startswith(".equ"):
            _, name, value = [t.strip() for t in re.split(r"[,\s]+", line) if t]
            if name in labels or name in constants:
                raise ValueError(f"Duplicate symbol '{name}'")
            constants[name] = value
            continue

        while ":" in line:
            label, remainder = line.split(":", 1)
            label = label.strip()
            if label in labels:
                raise ValueError(f"Duplicate label '{label}'")
            labels[label] = pc
            line = remainder.strip()

        if line:
            tokens = [t for t in re.split(r"[,\s]+", line) if t]
            expanded = expand_instruction(tokens)
            program.extend(expanded)
            pc += len(expanded)

# ----------------------------
# PASS 2
# ----------------------------

with open(sim_src, "w") as mem:
    for pc, tokens in enumerate(program):
        mnemonic = tokens[0]

        if mnemonic not in formats:
            raise ValueError(f"Unknown instruction '{mnemonic}'")

        opcode = formats[mnemonic]["opcode"]

        rd_bin = "0000"
        ra_bin = "0000"
        rb_bin = "0000"
        imm_bin = "00000000"

        operands = tokens[1:]
        expected = formats[mnemonic]["format"]

        if len(operands) != len(expected):
            raise ValueError(f"{mnemonic}: wrong number of operands")

        # 1. Pass over operands to resolve immediate/address for mem_space check
        mem_space = 0
        for operand_type, operand in zip(expected, operands):
            resolved_op = operand
            while resolved_op in constants:
                resolved_op = constants[resolved_op]

            if operand_type == "imm":
                if resolved_op in labels:
                    val_check = labels[resolved_op]
                    if formats[mnemonic].get("pc_relative", False):
                        val_check -= (pc + 1)
                else:
                    val_check = resolved_op

                try:
                    int_val = int(str(val_check), 0)
                except ValueError:
                    int_val = 0

                if int_val >= 0x0100:
                    mem_space = 1

        # 2. Standard operand encoding
        for operand_type, operand in zip(expected, operands):
            resolved_op = operand
            while resolved_op in constants:
                resolved_op = constants[resolved_op]

            if operand_type == "rd":
                rd_bin = reg_to_bin(resolved_op)
            elif operand_type == "ra":
                ra_bin = reg_to_bin(resolved_op)
            elif operand_type == "rb":
                rb_bin = reg_to_bin(resolved_op)
            elif operand_type == "imm":
                if resolved_op in labels:
                    value = labels[resolved_op]
                    if formats[mnemonic].get("pc_relative", False):
                        value -= (pc + 1)
                else:
                    value = resolved_op

                if mnemonic in ["LOAD", "STORE"]:
                    numeric_val = int(str(value), 0)
                    value = numeric_val & 0xFF

                imm_bin = imm_to_bin(value)

        # 3. Inject mem_space attribute bit into unused register fields for LOAD/STORE
        if mnemonic == "STORE":
            rd_bin = f"000{mem_space}"
        elif mnemonic == "LOAD":
            rb_bin = f"000{mem_space}"

        # Convert final binary fields to hex nibbles/bytes for simulation
        imm_hex = f"{int(imm_bin, 2):02X}"
        ra_rb_hex = f"{int(ra_bin + rb_bin, 2):02X}"
        opcode_rd_hex = f"{int(opcode + rd_bin, 2):02X}"

        # Simulation testbench stimulus format
        mem.write(f"send_uart_byte(8'h{imm_hex});\n")
        mem.write(f"send_uart_byte(8'h{ra_rb_hex});\n")
        mem.write(f"send_uart_byte(8'h{opcode_rd_hex});\n\n")