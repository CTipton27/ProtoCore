import serial.tools.list_ports
from pathlib import Path
import time

root = Path(__file__).resolve().parent.parent
src_dir = root / "src"
mem_src = src_dir / "program.mem"

ports = list(serial.tools.list_ports.comports())
for p in ports:
    print(p.device, p.description)

try:
    with serial.Serial(ports[0].device, 115200, timeout=1) as ser:
        print("Connected...")
        reset_pc = input("Reset program counter after write? y/n: ")
        display = input ("Display mode (reg / mmio): ")
        ser.write(bytes([0xF1]))
        time.sleep(0.005)
        print("0xF1 - Begin write")
        with open(mem_src, "r") as mem_file:
            for line in mem_file:
                line = line.strip()
                if not line:
                    continue
                instr_val = int(line, 2)
                b0 = instr_val & 0xFF
                b1 = (instr_val >> 8) & 0xFF
                b2 = (instr_val >> 16) & 0xFF

                ser.write(bytes([b0, b1, b2]))
                print(f"{b0:02X} {b1:02X} {b2:02X}")
                time.sleep(0.005)

        #send display_mode parameter
        if display.lower().strip() == "reg":
            ser.write(bytes([0xF5]))
            time.sleep(0.005)
            print("0xF5 - Register display mode")
        elif display.lower().strip() == "mmio":
            ser.write(bytes([0xF4]))
            time.sleep(0.005)
            print("0xF4 - MMIO display mode")

        #Send reset_pc parameter
        if reset_pc.lower().strip() == "y":
            ser.write(bytes([0xF3]))
            print("0xF3 - Reset PC")
        else:
            ser.write(bytes([0xF2]))
            print("0xF2 - Maintain PC")

except serial.SerialException as e:
    print(f"Error: Failed to open serial port: {e}")