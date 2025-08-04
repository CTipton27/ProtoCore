ADDI R1, R0, 10       ; (1000) R1 = 10
ADDI R2, R0, 20       ; (1000) R2 = 20
ADDI R3, R0, 0        ; (1000) R3 = 0, accumulator
ADDI R4, R0, 5        ; (1000) R4 = 5, loop counter
ADDI R5, R0, 1        ; (1000) R5 = 1, decrement value
ADD R3, R3, R1        ; (0000) R3 += R1
SUB R4, R4, R5        ; (0001) R4 -= 1
BNE R4, R0, -3        ; (1101) if R4 ≠ 0, go back 3 to ADD
ADDI R6, R0, 50       ; (1000) R6 = 50
BEQ R3, R6, 10         ; (1100) if R3 == 50, jump to SUCCESS
XOR R7, R1, R2        ; (0100) R7 = R1 ^ R2
OR R8, R1, R2         ; (0011) R8 = R1 | R2
AND R9, R1, R2        ; (0010) R9 = R1 & R2
NOT R10, R1           ; (0101) R10 = ~R1
SHL R11, R1           ; (0110) R11 = R1 << 1
SHR R12, R2           ; (0111) R12 = R2 >> 1
ADDI R13, R0, 3       ; (1000) R13 = base addr = 3
STORE R13, R3, 1      ; (1011) MEM[3+1] = R3
LOAD R14, R13, 1      ; (1010) R14 = MEM[3+1] → should be 50
JMP R0, 21			  ; JMP to fail condition
HALT, 1               ; (1111) stop execution, Success
HALT, 2               ; (1111) stop execution, Fail
