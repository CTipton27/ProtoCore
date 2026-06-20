import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
script_dir = root / "scripts"
src_dir = root / "src"

assembly_src = script_dir / "Program.asm"
mem_src = src_dir / "program.mem"

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
    "BEQ":   {"format":["ra","rb","imm"], "opcode":"1100"},
    "BNE":   {"format":["ra","rb","imm"], "opcode":"1101"},
    "JMP":   {"format":["ra","imm"],      "opcode":"1110"},
    "HALT":  {"format":["imm"],           "opcode":"1111"},
}

def reg_to_bin(reg):
    if not reg.startswith("R"):
        raise ValueError(f"Invalid register {reg}")

    num = int(reg[1:])
    if not (0 <= num <= 15):
        raise ValueError(f"Invalid register {reg}")

    return f"{num:04b}"

def imm_to_bin(val):
    val = int(val)

    if not (-128 <= val <= 127):
        raise ValueError(f"Immediate out of range ({val})")

    if val < 0:
        val = (1 << 8) + val

    return f"{val:08b}"


# ----------------------------
# PASS 1
# ----------------------------

labels = {}
program = []

pc = 0

with open(assembly_src) as src:

    for line in src:

        line = line.split(";")[0].strip()

        if not line:
            continue

        # Keep consuming labels until there aren't any left.
        while ":" in line:
            label, remainder = line.split(":", 1)
            label = label.strip()

            if label in labels:
                raise ValueError(f"Duplicate label '{label}'")

            labels[label] = pc

            line = remainder.strip()

        # If there's still text, it's an instruction.
        if line:
            program.append(line)
            pc += 1


# ----------------------------
# PASS 2
# ----------------------------

with open(mem_src, "w") as mem:

    for pc, line in enumerate(program):

        tokens = [t for t in re.split(r"[,\s]+", line) if t]

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

        for operand_type, operand in zip(expected, operands):

            if operand_type == "rd":
                rd_bin = reg_to_bin(operand)

            elif operand_type == "ra":
                ra_bin = reg_to_bin(operand)

            elif operand_type == "rb":
                rb_bin = reg_to_bin(operand)

            elif operand_type == "imm":

                if operand in labels:
                    value = labels[operand]
                else:
                    value = operand

                imm_bin = imm_to_bin(value)

        mem.write(f"{opcode}{ra_bin}{rb_bin}{rd_bin}{imm_bin}\n")