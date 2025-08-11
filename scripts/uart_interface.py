import serial.tools.list_ports
from pathlib import Path
import re

root = Path(__file__).resolve().parent.parent
src_dir = root / "src"
mem_src = src_dir / "program.mem"

mem_file = open(mem_src, 'r')

ports = serial.tools.list_ports.comports()
for port in ports:
    print(port.device, port.description)

port = input("Please enter the serial port: ")

ser = serial.Serial(port, 115200, timeout=1)

if ser.is_open:
    print("Connected...")
    confirm_load = input("Load program.mem contents? y/n: ")
    reset_pc = input("Reset program counter after write? y/n: ")
    if confirm_load.lower().strip() == "y":
        ser.write(bytes([0x00, 0x00, 0xFF]))
        for line in mem_file:
            line.strip()
            instr_val = int(line, 2)
            b0 = instr_val & 0xFF
            b1 = (instr_val >> 8) & 0xFF
            b2 = (instr_val >> 16) & 0xFF

            ser.write(bytes([b0, b1, b2]))
        if reset_pc.lower().strip() == "y":
            ser.write(bytes([0x00, 0xFF, 0xFF]))
        else:
            ser.write(bytes([0x00, 0xF0, 0xFF]))

else:
    print("Error: Failed to open serial port.")

mem_file.close()