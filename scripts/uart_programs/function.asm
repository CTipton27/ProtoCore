ADDI R1, R0, 10 ; R1=10
ADDI R2, R0, 20 ; R2=20
ADDI R15, R0, 4 ; Return Pointer
JMP R0, 10		; Jump to function
ADDI R4, R0, 200; R4 = 200
BEQ R3, R4, 1	; if R3=R4=200, PC+1
HALT, 1			; Fail
HALT, 2			; Success
HALT, 9			; Fail
HALT, 9			; Fail
ADD R3, R1, R2  ; R3=R1+R2 =? 200 	Function start
JMP R15, 0		; Jump to R15 =? 4  Function end