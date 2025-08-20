HALT, 6				; HALT 6 (fail)
HALT, 6				; HALT 6 (fail)
HALT, 6				; HALT 6 (fail)
HALT, 6				; HALT 6 (fail)
HALT, 6				; HALT 6 (fail)
ADDI R1, R0, 5		; R1 = 5, program should start here
ADDI R2, R0, 6		; R2 = 6
ADD R3, R1, R2		; R3 = R1+R2
ADDI R4, R0, 11		; R4 = 11
BEQ R3, R4, 1		; if R3=R4 PC+1
HALT, 1				; HALT 1 (fail)
HALT, 2				; HALT 2 (success)