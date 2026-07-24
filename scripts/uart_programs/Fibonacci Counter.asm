; --------------------------------------
; 16-bit Fibonacci sequence
; Output:
; x[254] = low byte
; x[255] = high byte
;
; R0 = constant zero
; --------------------------------------

; A = 0
ADDI R1, R0, 0
ADDI R2, R0, 0

; B = 1
ADDI R3, R0, 1
ADDI R4, R0, 0

LOOP:
; --------------------------------------
; Display current B
; --------------------------------------
STORE R0, R3, -2
STORE R0, R4, -1

; --------------------------------------
; Calculate B + A
;
; low byte:
; R5 = R1 + R3
; --------------------------------------
ADD R5, R1, R3


; --------------------------------------
; Calculate carry
;
; carry = ((A&B)|((A|B)&~sum)) >> 7
;
; Uses low bytes only
; --------------------------------------
AND R7, R1, R3        ; A & B
OR R8, R1, R3         ; A | B
NOT R9, R5            ; ~sum
AND R8, R8, R9        ; (A|B)&~sum
OR R7, R7, R8         ; combine

; move bit 7 down to bit 0
SHR R7, R7
SHR R7, R7
SHR R7, R7
SHR R7, R7
SHR R7, R7
SHR R7, R7
SHR R7, R7

; --------------------------------------
; high byte:
;
; high = A_high+B_high+carry
; --------------------------------------
ADD R6, R2, R4
ADD R6, R6, R7

; --------------------------------------
; Rotate:
;
; A = B
; B = new
; --------------------------------------
ADD R1, R3, R0
ADD R2, R4, R0

ADD R3, R5, R0
ADD R4, R6, R0

; --------------------------------------
; Repeat forever
; --------------------------------------
JMP R0, LOOP

HALT 0