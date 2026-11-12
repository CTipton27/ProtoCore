import serial.tools.list_ports
from pathlib import Path
import time
import sys

root = Path(__file__).resolve().parent.parent
src_dir = root / "src"
mem_src = src_dir / "program.mem"

BAUD = 115200


def get_target_port():
    # If passed via command line from the central hub, use it
    if len(sys.argv) > 1 and sys.argv[1]:
        return sys.argv[1]

    # Otherwise, let the user explicitly choose or enter it
    ports = list(serial.tools.list_ports.comports())
    if not ports:
        print("[!] No serial ports automatically detected.")
        manual_port = input("Enter serial port manually (e.g. COM3): ").strip()
        return manual_port if manual_port else "COM3"

    print("\nAvailable Serial Ports:")
    for i, p in enumerate(ports):
        print(f"  {i}: {p.device} - {p.description}")

    choice = input("\nSelect port index: ").strip()
    try:
        return ports[int(choice)].device
    except (ValueError, IndexError):
        print("[!] Invalid selection, defaulting to first available port.")
        return ports[0].device


port = get_target_port()

try:
    with serial.Serial(port, BAUD, timeout=1) as ser:
        print(f"Connected to {port}...")
        reset_pc = input("Reset program counter after write? y/n: ")
        display = input("Display mode (reg / mmio): ")

        ser.write(bytes([0x00, 0x00, 0xF1]))
        time.sleep(0.005)
        print("0xF1 - Begin write")

        # Read from piped stdin if available, otherwise fall back to program.mem
        if not sys.stdin.isatty():
            lines = sys.stdin.read().splitlines()
        else:
            if mem_src.exists():
                with open(mem_src, "r") as mem_file:
                    lines = mem_file.read().splitlines()
            else:
                print(f"[Error] {mem_src} not found and no piped input.")
                sys.exit(1)

        for line in lines:
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

        # Send display_mode parameter
        if display.lower().strip() == "reg":
            ser.write(bytes([0x00, 0x00, 0xF5]))
            time.sleep(0.005)
            print("0xF5 - Register display mode")
        elif display.lower().strip() == "mmio":
            ser.write(bytes([0x00, 0x00, 0xF4]))
            time.sleep(0.005)
            print("0xF4 - MMIO display mode")

        # Send reset_pc parameter
        if reset_pc.lower().strip() == "y":
            ser.write(bytes([0x00, 0x00, 0xF3]))
            print("0xF3 - Reset PC")
        else:
            ser.write(bytes([0x00, 0x00, 0xF2]))
            print("0xF2 - Maintain PC")

except serial.SerialException as e:
    print(f"Error: Failed to open serial port: {e}")