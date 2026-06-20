; Wolfram's Rule 30

;x[1:0] Will act as an immutable frame, while x[255:254] acts as the MMIO Output

;start by  initializing board state
ADDI R1, R0, 1	
STORE R0, R1, 1		; x[1] = 0000 0001
STORE R0, R1, -1	; x[255] = 0000 0001
ADDI R1, R1, 127
STORE R0, R1, 0 	; x[0] = 1000 0000
STORE R0, R1, -2	; x[254] = 1000 0000

ADDI R15, 

ADDI R13, R0, 1		; Load High byte on 1


LOAD R1, R13, 0		; Load Byte into R1
BEQ R14,R0, 3
SHL R1, R1
ADDI R14, R14, -1
JMP R0, 10
BEQ R14,R0, 3
SHL R1, R1
ADDI R15, R15, -1
JMP R0, 14
