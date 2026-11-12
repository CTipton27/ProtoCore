import serial
import serial.tools.list_ports
import time
import sys

BAUD = 115200


def send_cmd(ser, data, description):
    """Send a command byte sequence with a small delay."""
    ser.write(bytes(data))
    time.sleep(0.005)
    hex_str = ' '.join(f'0x{x:02X}' for x in data)
    print(f"Sent: {hex_str} - {description}")


def get_target_port():
    # If the central hub passed the port as an argument, use it automatically!
    if len(sys.argv) > 1:
        return sys.argv[1]

    # Otherwise, prompt manually if run standalone
    ports = list(serial.tools.list_ports.comports())
    if not ports:
        print("No serial ports found.")
        sys.exit(1)

    print("Available ports:")
    for i, p in enumerate(ports):
        print(f"{i}: {p.device} - {p.description}")

    port_choice = int(input("Select port: "))
    return ports[port_choice].device


def main():
    port = get_target_port()

    try:
        with serial.Serial(port, BAUD, timeout=1) as ser:
            print(f"Connected to {port}")

            while True:
                print("\n--- Serial / Debug Interface ---")
                print("1 - MMIO display")
                print("2 - Register display")
                print("3 - Enter debug mode")
                print("4 - Exit debug mode")
                print("5 - Reset PC")
                print("6 - Step CPU")
                print("q - Quit to Python Interface")

                cmd = input("> ").strip().lower()

                if cmd == "1":
                    send_cmd(ser, [0x00, 0x00, 0xF4], "MMIO display mode")
                elif cmd == "2":
                    send_cmd(ser, [0x00, 0x00, 0xF5], "Register display mode")
                elif cmd == "3":
                    send_cmd(ser, [0x00, 0x01, 0xF6], "Enter debug mode")
                elif cmd == "4":
                    send_cmd(ser, [0x00, 0x00, 0xF6], "Exit debug mode")
                elif cmd == "5":
                    send_cmd(ser, [0x00, 0x00, 0xF7], "Reset PC")
                elif cmd == "6" or cmd == "":
                    send_cmd(ser, [0x00, 0x00, 0xF8], "Step CPU")
                elif cmd == "q":
                    print("Exiting serial interface back to Hub...")
                    break
                else:
                    print("Unknown command.")

    except serial.SerialException as e:
        print(f"UART error: {e}")


if __name__ == "__main__":
    main()