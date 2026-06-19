ADDI R1, R0, 10       ; R1 = 10
ADDI R2, R0, 20       ; R2 = 20
ADDI R3, R0, 0        ; R3 = 0, accumulator
ADDI R4, R0, 5        ; R4 = 5, loop counter
ADDI R5, R0, 1        ; R5 = 1, decrement value
ADD R3, R3, R1        ; R3 += R1
SUB R4, R4, R5        ; R4 -= 1
BNE R4, R0, -3        ; if R4 ≠ 0, go back 3 to ADD
ADDI R6, R0, 50       ; R6 = 50
BEQ R3, R6, 10        ; if R3 == 50, jump to SUCCESS
XOR R7, R1, R2        ; R7 = R1 ^ R2
OR R8, R1, R2         ; R8 = R1 | R2
AND R9, R1, R2        ; R9 = R1 & R2
NOT R10, R1           ; R10 = ~R1
SHL R11, R1           ; R11 = R1 << 1
SHR R12, R2           ; R12 = R2 >> 1
ADDI R13, R0, 3       ; R13 = base addr = 3
STORE R13, R3, 1      ; MEM[3+1] = R3
LOAD R14, R13, 1      ; R14 = MEM[3+1] → should be 50
JMP R0, 21			  ; Fail, jump to 21
HALT, 1               ; Success
HALT, 0               ; Fail
