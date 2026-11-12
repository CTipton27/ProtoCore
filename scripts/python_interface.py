import os
import subprocess
import sys
import serial.tools.list_ports

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
UART_PROGRAMS_DIR = os.path.join(SCRIPTS_DIR, "uart_programs")
NORMAL_ASSEMBLER = os.path.join(SCRIPTS_DIR, "Assembler.py")
SIM_ASSEMBLER = os.path.join(SCRIPTS_DIR, "Assembler_sim.py")
UART_INTERFACE = os.path.join(SCRIPTS_DIR, "uart_interface.py")
SERIAL_INTERFACE = os.path.join(SCRIPTS_DIR, "serial_interface.py")


def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')


def list_programs():
    if not os.path.exists(UART_PROGRAMS_DIR):
        return []
    return sorted([f for f in os.listdir(UART_PROGRAMS_DIR) if f.endswith(".asm")])


def select_port():
    """Allows the user to select or manually type their serial port right at startup."""
    clear_screen()
    print("==========================================")
    print("       PROTOCORE PYTHON INTERFACE         ")
    print("==========================================")

    ports = list(serial.tools.list_ports.comports())

    if not ports:
        print("[!] No serial ports automatically detected.")
        manual_port = input("Enter your serial port manually (e.g. COM3): ").strip()
        return manual_port if manual_port else "COM3"

    print("\nAvailable Serial Ports:")
    for i, p in enumerate(ports):
        print(f"  {i}: {p.device} - {p.description}")

    choice = input("\nSelect port index (or type port name directly): ").strip()

    # Allow typing a port name directly (e.g. COM3) or picking by index
    if choice.upper().startswith("COM") or "/" in choice:
        return choice

    try:
        return ports[int(choice)].device
    except (ValueError, IndexError):
        print("[!] Invalid selection, defaulting to first available port.")
        return ports[0].device


def main():
    # User decides the port first thing when launching the interface
    active_port = select_port()

    while True:
        clear_screen()
        print("==========================================")
        print("       PROTOCORE PYTHON INTERFACE         ")
        print("==========================================")
        print(f"Active Serial Port: {active_port}")

        programs = list_programs()
        if not programs:
            print("\n[!] No .asm programs found in 'uart_programs/' folder.")
            input("\nPress Enter to exit...")
            break

        print("\n[Step 1] Select a program:")
        for idx, prog in enumerate(programs, 1):
            print(f"  {idx}. {prog}")
        print("  0. Exit Interface")

        choice = input(f"\nEnter choice (0-{len(programs)}): ").strip()
        if choice == '0':
            print("Exiting ProtoCore Python Interface. Goodbye!")
            break

        try:
            choice_idx = int(choice) - 1
            if choice_idx < 0 or choice_idx >= len(programs):
                raise ValueError()
        except ValueError:
            input("\n[!] Invalid selection. Press Enter to try again...")
            continue

        selected_program_name = programs[choice_idx]
        selected_program_path = os.path.join(UART_PROGRAMS_DIR, selected_program_name)

        # Step 2: Choose Assembler Mode
        print("\n[Step 2] Choose Target Mode:")
        print("  1. Normal / Hardware (Assemble & pipe directly to board via UART)")
        print("  2. Sim    (Generate program.txt for testbench)")

        mode_choice = input("\nEnter choice (1 or 2): ").strip()

        if mode_choice == '2':
            # --- SIM MODE ---
            print(f"\n[Step 3] Running Sim Assembler on '{selected_program_name}'...")
            asm_result = subprocess.run([sys.executable, SIM_ASSEMBLER, selected_program_path])
            if asm_result.returncode != 0:
                input("\n[!] Assembler encountered an error. Press Enter to return to menu...")
                continue
            print("\n[Success] Generated 'src/program.txt' ready for your testbench!")
            input("\nPress Enter to return to the interface menu...")
            continue

        else:
            # --- NORMAL / HARDWARE MODE ---
            print(f"\n[Step 3 & 4] Assembling '{selected_program_name}' and uploading to {active_port}...")

            try:
                # Pipe Assembler output directly into uart_interface.py, passing the user-chosen port
                assembler_proc = subprocess.Popen(
                    [sys.executable, NORMAL_ASSEMBLER, selected_program_path],
                    stdout=subprocess.PIPE,
                    text=True
                )
                uart_proc = subprocess.run(
                    [sys.executable, UART_INTERFACE, active_port],
                    stdin=assembler_proc.stdout
                )

                assembler_proc.wait()
                if assembler_proc.returncode != 0 or uart_proc.returncode != 0:
                    input("\n[!] Build or upload failed. Press Enter to return to menu...")
                    continue
            except Exception as e:
                input(f"\n[!] Error during pipeline execution: {e}\nPress Enter to return to menu...")
                continue

        # Step 5: Open Serial/Debug Interface using the exact same device port
        print("\n[Step 5] Opening Serial Interface...")
        print("(Type 'q' inside the serial interface to return back to this interface menu to select a new program)")
        input("Press Enter to launch Serial Interface...")

        try:
            subprocess.run([sys.executable, SERIAL_INTERFACE, active_port])
        except Exception as e:
            print(f"[!] Error running serial interface: {e}")


if __name__ == "__main__":
    main()