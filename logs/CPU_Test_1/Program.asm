ADDI R1,R0,3; R1 = 3
ADDI R2,R0,2; R2 = 2
ADD R3,R1,R2; R3 = R1 + R2 = 5
SHL R3,R3; R3 = R3 << 1 = 10
JMP R0,7; Skip next two instructions
XOR R4,R1,R2; skipped
OR R5,R1,R2; skipped
HALT; stop execution