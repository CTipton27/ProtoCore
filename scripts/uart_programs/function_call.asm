ADDI R1, 1		; R1=1
ADDI R2, 2		; R2=2
ADDI R15, R0, 4	; Set stack pointer to 4
JMP R0, 10		; Should jump to function
ADDI R5, 3		; R5=3
BEQ R3, R5, 1	; If R3=R5, PC + 1
HALT, 1			; Halt (Fail)
HALT, 6			; Halt (success)