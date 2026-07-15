import re
from pathlib import Path

# ----------------------------
# Paths
# ----------------------------

root = Path(__file__).resolve().parent.parent
script_dir = root / "scripts"
src_dir = root / "src"

assembly_src = script_dir / "Program.asm"
sim_src = src_dir / "program.txt"

formats = {
    'ADD':   {"format": ['rd', 'ra', 'rb'],  "opcode": "0"},
    'SUB':   {"format": ['rd', 'ra', 'rb'],  "opcode": "1"},
    'AND':   {"format": ['rd', 'ra', 'rb'],  "opcode": "2"},
    'OR':    {"format": ['rd', 'ra', 'rb'],  "opcode": "3"},
    'XOR':   {"format": ['rd', 'ra', 'rb'],  "opcode": "4"},
    'NOT':   {"format": ['rd', 'ra'],        "opcode": "5"},
    'SHL':   {"format": ['rd', 'ra'],        "opcode": "6"},
    'SHR':   {"format": ['rd', 'ra'],        "opcode": "7"},
    'ADDI':  {"format": ['rd', 'ra', 'imm'], "opcode": "8"},
    'ANDI':  {"format": ['rd', 'ra', 'imm'], "opcode": "9"},
    'LOAD':  {"format": ['rd', 'ra', 'imm'], "opcode": "A"},
    'STORE': {"format": ['ra', 'rb', 'imm'], "opcode": "B"},
    'BEQ':   {"format": ['ra', 'rb', 'imm'], "opcode": "C"},
    'BNE':   {"format": ['ra', 'rb', 'imm'], "opcode": "D"},
    'JMP':   {"format": ['ra', 'imm'],       "opcode": "E"},
    'HALT':  {"format": ['imm'],             "opcode": "F"}
}

# ----------------------------
# Helpers
# ----------------------------

def reg_to_hex(reg):
    if not reg.startswith("R"):
        raise ValueError(f"Invalid register {reg}")

    num = int(reg[1:])

    if not (0 <= num <= 15):
        raise ValueError(f"Invalid register {reg}")

    return f"{num:X}"


def imm_to_hex(value):
    value = int(value)

    if not (-128 <= value <= 127):
        raise ValueError(f"Immediate out of range ({value})")

    if value < 0:
        value = (1 << 8) + value

    return f"{value:02X}"


# ----------------------------
# PASS 1 -- Collect labels
# ----------------------------

labels = {}
program = []

pc = 0

with open(assembly_src) as src:

    for line in src:

        line = line.split(";")[0].strip()

        if not line:
            continue

        while ":" in line:
            label, remainder = line.split(":", 1)
            label = label.strip()

            if label in labels:
                raise ValueError(f"Duplicate label '{label}'")

            labels[label] = pc
            line = remainder.strip()

        if line:
            program.append(line)
            pc += 1

# ----------------------------
# PASS 2 -- Assemble
# ----------------------------

with open(sim_src, "w") as mem:

    for pc, line in enumerate(program):

        tokens = [t for t in re.split(r"[,\s]+", line) if t]

        mnemonic = tokens[0]

        if mnemonic not in formats:
            raise ValueError(f"Unknown instruction '{mnemonic}'")

        opcode = formats[mnemonic]["opcode"]

        ra_hex = "0"
        rb_hex = "0"
        rd_hex = "0"
        imm_hex = "00"

        operands = tokens[1:]
        expected = formats[mnemonic]["format"]

        if len(operands) != len(expected):
            raise ValueError(
                f"{mnemonic}: expected {len(expected)} operands, got {len(operands)}"
            )

        for operand_type, operand in zip(expected, operands):

            if operand_type == "rd":
                rd_hex = reg_to_hex(operand)

            elif operand_type == "ra":
                ra_hex = reg_to_hex(operand)

            elif operand_type == "rb":
                rb_hex = reg_to_hex(operand)

            elif operand_type == "imm":

                # Resolve labels
                if operand in labels:
                    value = labels[operand]
                else:
                    value = operand

                imm_hex = imm_to_hex(value)

        # UART output format
        mem.write(f"send_uart_byte(8'h{imm_hex});\n")
        mem.write(f"send_uart_byte(8'h{rb_hex}{rd_hex});\n")
        mem.write(f"send_uart_byte(8'h{opcode}{ra_hex});\n\n")