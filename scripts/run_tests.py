import shutil
from pathlib import Path
import sys
import subprocess
import datetime
# from openpyxl import Workbook

run_time = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
log_name = input("Please enter a name for the log directory: ")

#Files associated with sim software. change as needed for your vivado installation
settings = Path("C:/Xilinx/Vivado/2024.2/settings64.bat")
settings = f'"{settings}"'

# Grabs all directories needed to run scripts and log files.
root = Path(__file__).resolve().parent.parent
script_dir = root / "scripts"
tb_dir = root / "testbenches"
src_dir = root / "src"
log_dir = root / "logs"

current_log_dir = log_dir / log_name
current_log_dir.mkdir(exist_ok=True)

log_file = current_log_dir / f"{log_name}_{run_time}.log"
excel_file =  current_log_dir / f"{log_name}_{run_time}.xlsx"

#Dict allows for multiple sources/tbs
testbenches = {
    "alu": {
        "tb": tb_dir / "ALU_TB.v",
        "src_files": [src_dir / "ALU.v"],
        "xelab_opts": ["work.ALU_TB", "-s", "alu_tb_snapshot"],
        "xsim_opts": ["alu_tb_snapshot"],
        "log_file": "ALUlog.txt"
    },
    "reg_file": {
        "tb": tb_dir / "REG_TB.v",
        "src_files": [src_dir / "reg_file.v"],
        "xelab_opts": ["work.REG_TB", "-s", "reg_tb_snapshot"],
        "xsim_opts": ["reg_tb_snapshot"],
        "log_file": "REGlog.txt"
    },
    "datapath": {
        "tb": tb_dir / "DATAPATH_TB.v",
        "src_files": [src_dir / "datapath.v", src_dir / "ALU.v", src_dir / "reg_file.v"],
        "xelab_opts": ["work.DATAPATH_TB", "-s", "datapath_tb_snapshot"],
        "xsim_opts": ["datapath_tb_snapshot"],
        "log_file": "DATAPATHlog.txt"
    }
}

choice = input("Which testbench do you want to run? (alu, reg_file, datapath)? ").strip().lower()

if choice not in testbenches:
    print("Invalid choice")
    sys.exit(1)

#Builds the command - Starts by finding all sources and testbenches needed for xvlog
tb = testbenches[choice]["tb"]
sources = testbenches[choice]["src_files"]
all_files = [tb] + sources
cmd_files = " ".join(str(f) for f in all_files)

#builds xvlog, xelab, and xsim commands
xvlog_cmd = f"xvlog {cmd_files}"
xelab_cmd = "xelab " + " ".join(testbenches[choice]["xelab_opts"])
xsim_cmd = "xsim " + " ".join(testbenches[choice]["xsim_opts"]) + " -runall" #Prevents clock from stalling xsim


#joins full command for pass into subprocess.
full_cmd = f"{settings} && {xvlog_cmd} && {xelab_cmd} && {xsim_cmd}"

# Run and log output
with open(log_file, 'a') as f:
    result = subprocess.run(full_cmd, shell=True, stdout=f, stderr=subprocess.STDOUT)

if result.returncode != 0:
    print(f"Simulation failed with return code {result.returncode}")
    sys.exit(result.returncode)
else:
    print("Simulation completed successfully.")

# finds log in script dir and moves it to log folder
vivado_default_log = script_dir / testbenches[choice]["log_file"]
if vivado_default_log.exists():
    # Destination path for log
    dest_log_path = current_log_dir / testbenches[choice]["log_file"]
    try:
        # Moves file to log folder
        shutil.move(str(vivado_default_log), str(dest_log_path))
        print(f"Moved log file to {dest_log_path}")
    except Exception as e:
        print(f"Failed to move log file: {e}")
else:
    print(f"Expected log file {vivado_default_log} not found.")

for item in script_dir.iterdir():
    if item.is_file():
        if item.suffix not in [".py", ".py~", ".asm"]:
            try:
                item.unlink()
            except Exception as e:
                print(f"Warning: Failed to delete file {item}: {e}")
    elif item.is_dir():
        if item.name not in [".idea", ".venv", "uart_programs"]:
            try:
                shutil.rmtree(item)
            except Exception as e:
                print(f"Warning: Failed to delete directory {item}: {e}")
# print("Cleanup complete.")
#
# # create Excel file and format data.
# workbook = Workbook()
#
# workbook.save(excel_file)