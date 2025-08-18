ADDI R2, R0, 0		; R2 = 0
LOAD R2, R0, 0		; R2 = mem[0]
BEQ R2, R0, 1		; if R2=0, PC+1
BEQ R1, R2, 1		; if R1=R2, PC+1
HALT, 4				; HALT 3 (fail)
HALT, 3				; HALT 4 (success)