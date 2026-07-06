; Wolfram's Rule 30

;x[1:0] Will act as an immutable frame, while x[255:254] acts as the MMIO Output

;start by  initializing board state
ADDI R1, R0, 1	
STORE R0, R1, 1		; x[1] = 0000 0001
STORE R0, R1, -1	; x[255] = 0000 0001
STORE R0, R0, 0		; x[0] = 0000 0000
STORE R0, R0, -2	; x[254] = 0000 0000

main_loop:

r_cell carry:
LOAD R15, R0, 0
ANDI R15, R15, -128	;Isolate carry
ADDI R13, R0, 7
SHR R15, R15
ADDI R13, R13, -1
BNE R13, R0, -3	
;R15 now contains carry bit of r_cell from low byte

p_cell carry:
LOAD R14, R0, 1
ANDI R14, R14, 1	;Isolate carry
ADDI R13, R0, 7
SHL R14, R14
ADDI R13, R13, -1
BNE R13, R0, -3
;R14 now contains carry bit of p_cell from high byte		

ADDI R13, R0, 1		;Which byte is being manipulated?

load_pqr:
; Set P, Q, and R to be on the same "reference" point ( for each cell, Shift P and R to same pos as Q)
LOAD R1, R13, 0		
LOAD R2, R13, 0
LOAD R3, R13, 0

SHR R1, R1
SHL R3, R3

; If manipulating low byte, shift add P carry, otherwise add R carry
BEQ R13, R0, 2
ADD R3, R3, R15
JMP R0, byte_calc
ADD R1, R1, R14
JMP R0, byte_calc


byte_calc:
OR R2, R2, R3	; R2 = Q|R
XOR R2, R1, R2	; R2 = P^(Q|R)
;R2 now contains the updated frame of the byte.

frame_calc:
BEQ R13, R0, 3
ADD R6, R0, R2
ADDI R13, R0, 0
JMP R0, load_pqr
STORE R0, R2, -2
STORE R0, R6, -1
ADDI R13, R0, 1
JMP R0, load_frame

load_frame:
STORE R0, R6, 1
STORE R0, R2, 0
JMP R0, main_loop