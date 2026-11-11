import serial
import serial.tools.list_ports
import time

BAUD = 115200

def send_cmd(ser, data, description):
    """Send a command byte sequence with a small delay."""
    ser.write(bytes(data))
    time.sleep(0.005)
    print(f"Sent: {' '.join(f'0x{x:02X}' for x in data)} - {description}")

ports = list(serial.tools.list_ports.comports())

if not ports:
    print("No serial ports found.")
    exit(1)

print("Available ports:")
for i, p in enumerate(ports):
    print(f"{i}: {p.device} - {p.description}")

port_choice = int(input("Select port: "))
port = ports[port_choice].device

try:
    with serial.Serial(port, BAUD, timeout=1) as ser:
        print(f"Connected to {port}")

        while True:
            print("\nCommands:")
            print("1 - MMIO display")
            print("2 - Register display")
            print("3 - Enter debug mode")
            print("4 - Exit debug mode")
            print("5 - Reset PC")
            print("6 - Step CPU")
            print("q - Quit")

            cmd = input("> ").strip().lower()

            if cmd == "1":
                # 3rd byte is 0xF4 (MMIO display)
                send_cmd(ser, [0x00, 0x00, 0xF4], "MMIO display mode")

            elif cmd == "2":
                # 3rd byte is 0xF5 (Register display) [Comma fixed here]
                send_cmd(ser, [0x00, 0x00, 0xF5], "Register display mode")

            elif cmd == "3":
                # 3rd byte is 0xF6 (Debug mode), byte 2 carries argument 0x01 (Enable)
                send_cmd(ser, [0x00, 0x01, 0xF6], "Enter debug mode")

            elif cmd == "4":
                # 3rd byte is 0xF6 (Debug mode), byte 2 carries argument 0x00 (Disable)
                send_cmd(ser, [0x00, 0x00, 0xF6], "Exit debug mode")

            elif cmd == "5":
                # 3rd byte is 0xF7 (Reset PC)
                send_cmd(ser, [0x00, 0x00, 0xF7], "Reset PC")

            elif cmd == "6" or cmd == "":
                # 3rd byte is 0xF8 (Step CPU)
                send_cmd(ser, [0x00, 0x00, 0xF8], "Step CPU")

            elif cmd == "q":
                print("Closing.")
                break

            else:
                print("Unknown command.")

except serial.SerialException as e:
    print(f"UART error: {e}")