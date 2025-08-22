import re
from pathlib import Path

# Grabs all directories needed to run scripts and log files.
root = Path(__file__).resolve().parent.parent
script_dir = root / "scripts"
src_dir = root / "src"
sim_src = src_dir / "program.txt"
assembly_src = script_dir / "Program.asm"

src_file = open(assembly_src, 'r')
mem_file = open(sim_src, 'w')

formats = {
    'ADD': {
        "format": ['rd', 'ra', 'rb'],
        "opcode": "0"},
    'SUB': {
        "format": ['rd', 'ra', 'rb'],
        "opcode": "1"},
    'AND': {
        "format": ['rd', 'ra', 'rb'],
        "opcode": "2"},
    'OR': {
        "format": ['rd', 'ra', 'rb'],
        "opcode": "3"},
    'XOR': {
        "format": ['rd', 'ra', 'rb'],
        "opcode": "4"},
    'NOT': {
        "format": ['rd', 'ra'],
        "opcode": "5"},
    'SHL': {
        "format": ['rd', 'ra'],
        "opcode": "6"},
    'SHR': {
        "format": ['rd', 'ra'],
        "opcode": "7"},
    'ADDI': {
        "format": ['rd', 'ra', 'imm'],
        "opcode": "8"},
    'ANDI': {
        "format": ['rd', 'ra', 'imm'],
        "opcode": "9"},
    'LOAD': {
        "format": ['rd', 'ra', 'imm'],
        "opcode": "A"},
    'STORE': {
        "format": ['ra', 'rb', 'imm'],
        "opcode": "B"},
    'BEQ': {
        "format": ['ra', 'rb', 'imm'],
        "opcode": "C"},
    'BNE': {
        "format": ['ra', 'rb', 'imm'],
        "opcode": "D"},
    'JMP': {
        "format": ['ra', 'imm'],
        "opcode": "E"},
    'HALT': {
        "format": ['imm'],
        "opcode": "F"}
}

def reg_to_hex(reg):
    if not reg.startswith('R'):
        raise ValueError(f"Invalid register: {reg}")
    num = int(reg[1:])
    if num > 15 or num < 0:
        raise ValueError(f"Invalid register: {reg}")
    return f"{num:X}"

def imm_to_hex(imm):
    val = int(imm)
    if val > 127 or val < -128:
        raise ValueError(f"Invalid immediate value: {imm}")
    elif val < 0:
        val = (1<<8) + val
    return f"{val:02X}"

for line in src_file:
    line = line.split(';')[0].strip()
    if not line:
        continue
    tokens = re.split(r'[,\s]+', line)
    tokens = [t for t in tokens if t]
    if tokens[0] not in formats:
        print("Invalid instruction:", tokens[0])
        continue

    opcode = formats[tokens[0]]["opcode"]
    ra_hex = rb_hex = rd_hex = "0"
    imm_hex = "00"

    if len(tokens[1:]) != len(formats[tokens[0]]["format"]):
        raise ValueError(f"Invalid number of arguments for instruction {tokens[0]}")

    for operand_type, operand_value in zip(formats[tokens[0]]["format"], tokens[1:]):
        if operand_type == 'rd':
            rd_hex = reg_to_hex(operand_value)
        elif operand_type == 'ra':
            ra_hex = reg_to_hex(operand_value)
        elif operand_type == 'rb':
            rb_hex = reg_to_hex(operand_value)
        elif operand_type == 'imm':
            imm_hex = imm_to_hex(operand_value)

    mem_file.write(f"send_uart_byte(8'h{imm_hex});\n")
    mem_file.write(f"send_uart_byte(8'h{rb_hex}{rd_hex});\n")
    mem_file.write(f"send_uart_byte(8'h{opcode}{ra_hex});\n\n")

src_file.close()
mem_file.close()