from pathlib import Path

# Match UART interface directory structure
root = Path(__file__).resolve().parent.parent

# Input file location
mem_src = root / "src" / "program.mem"

# Output file
output_file = Path(__file__).resolve().parent / "program_bytes.txt"

bytes_out = []

# Convert 24-bit instructions into UART byte order
with open(mem_src, "r") as mem:
    for line in mem:
        line = line.strip()

        if not line:
            continue

        instr_val = int(line, 2)

        # Same byte order as UART loader
        b0 = instr_val & 0xFF
        b1 = (instr_val >> 8) & 0xFF
        b2 = (instr_val >> 16) & 0xFF

        bytes_out.extend([b0, b1, b2])


with open(output_file, "w") as out:

    # ----------------------------
    # C Version
    # ----------------------------
    out.write("// C Array\n")
    out.write("#include <avr/pgmspace.h>\n\n")
    out.write(f"#define PROGRAM_SIZE {len(bytes_out)}\n\n")

    out.write("const uint8_t program[] PROGMEM = {\n")

    for i in range(0, len(bytes_out), 12):
        chunk = bytes_out[i:i+12]
        out.write("    ")
        out.write(", ".join(f"0x{x:02X}" for x in chunk))
        out.write(",\n")

    out.write("};\n\n\n")


    # ----------------------------
    # Assembly Version
    # ----------------------------
    out.write("; AVR Assembly Array\n")
    out.write(f"; Program size: {len(bytes_out)} bytes\n\n")

    out.write("program:\n")

    for i in range(0, len(bytes_out), 12):
        chunk = bytes_out[i:i+12]
        out.write("    .db ")
        out.write(", ".join(f"0x{x:02X}" for x in chunk))
        out.write("\n")


print(f"Input:  {mem_src}")
print(f"Output: {output_file}")
print(f"Converted {len(bytes_out)//3} instructions ({len(bytes_out)} bytes)")