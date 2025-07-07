ADDI R1, R0, 10       ;R1 = 10
ADDI R2, R0, 20       ;R2 = 20
ADDI R3, R0, 0        ;R3 = 0, accumulator
ADDI R4, R0, 5        ;R4 = 5, loop counter
ADDI R5, R0, 1        ;R5 = 1, decrement value
ADD R3, R3, R1		  ;R3 = R3+R1
SUB R4, R4, R5		  ;R4 = R4-R5
BEQ R0, R4, 1		  ;if R4 = 0 P+1
JMP R0, 5			  ;Jump to line 5
STORE R0, R3, 0		  ;x(0) = R3
SHL R1				  ;R1 << 1
BNE R1, R2, 2		  ;if R1 ~= R2 PC + 2
XOR R6, R1, R2		  ;R6 = R1 ^ R2 (should be 0)
JMP R0, 26			  ;jump to line 26 
ADDI R1, R0, 0		  ;FAIL, R1 = 0
HALT				
LOAD R12, R0, 0		  ;R12 = x(0)
