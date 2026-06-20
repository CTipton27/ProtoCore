; 16 bit counter
ADDI R14, R0, 0		; R14 = 0
ADDI R15, R0, 0		; R15 = 0
ADDI R14, R14, 1	; R14++
BNE R14, R0, 1		; skip incrementing R15 if no overflow
ADDI R15, R15, 1	; R15++
STORE R0, R14, -2	; x[254] = R14
STORE R0, R15, -1	; x[255] = R15
JMP R0, 2			; Loop back