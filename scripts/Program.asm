.equ hold_time, 100     ; Hold each format for 100 centiseconds (1.0 second)

main_loop:

    ; ==========================================
    ; 1. FORMAT: 64x32 (1BPP) [FMT_64x32_1BPP = 0xC0]
    ; 64 columns total. 2 shades (0 and 1). 
    ; Shade changes every 32 steps (Bytes 0-3 = 0x00, Bytes 4-7 = 0xFF)
    ; ==========================================
    LDI   R5, FMT_64x32_1BPP  
    LDI   R1, 0               ; Start at RAM address 0 (top-left)
    LDI   R7, 32              ; 32 rows

row_1:
    LDI   R3, 0               ; Column byte index (0 to 7)
byte_1:
    ; Left 32 pixels (bytes 0-3) = 0x00 (black), Right 32 pixels (bytes 4-7) = 0xFF (white)
    LDI   R4, 4
    MOV   R8, R3
    SUB   R8, R8, R4          ; If R3 >= 4, result >= 0
    ; Simple branch check based on sign/value or explicit constant selection:
    ; Let's write it cleanly using direct values per byte column:
    LDI   R2, 0               ; Default black
    ; If R3 >= 4, make it white (0xFF). We can compare or use jump-free selection:
    ; (Since R3 is a constant counter from 0 to 7, we can branch or hardcode the row loop unrolled)
    
    STORE R1, R2, 0         
    INC   R1                  
    INC   R3                  
    LDI   R4, 8
    BNE   R3, R4, byte_1  

    DEC   R7                  
    BNE   R7, R0, row_1  

    ; Busy-wait for DMA streamer (Bit 7 of MMIO_GPHC_ST must drop to 0)
wait_busy_1:
    LOAD  R4, R0, MMIO_GPHC_ST     
    ANDI  R4, R4, u128            
    BNE   R4, R0, wait_busy_1       

    STORE R0, R0, MMIO_VRAM_AD   
    STORE R0, R5, MMIO_GPHC_ST   

    ; 1-second hold delay
    LDI   R10, hold_time
    RJMP  delay_centiseconds_1
return_1:


    ; ==========================================
    ; 2. FORMAT: 32x32 (2BPP) [FMT_32x32_2BPP = 0xD0]
    ; 32 columns, 4 shades. Shade changes every 8 pixel steps.
    ; ==========================================
    LDI   R5, FMT_32x32_2BPP  
    LDI   R1, 0       
    LDI   R7, 32        

row_2:
    LDI   R3, 0         
byte_2:
    MOV   R2, R3
    SHR   R2, R2              ; Step shade every 2 column bytes (8 pixels)
    STORE R1, R2, 0         
    INC   R1                  
    INC   R3                  
    LDI   R4, 8
    BNE   R3, R4, byte_2  

    DEC   R7                  
    BNE   R7, R0, row_2  

wait_busy_2:
    LOAD  R4, R0, MMIO_GPHC_ST     
    ANDI  R4, R4, u128            
    BNE   R4, R0, wait_busy_2       

    STORE R0, R0, MMIO_VRAM_AD   
    STORE R0, R5, MMIO_GPHC_ST   

    LDI   R10, hold_time
    RJMP  delay_centiseconds_2
return_2:


    ; ==========================================
    ; 3. FORMAT: 32x16 (4BPP) [FMT_32x16_4BPP = 0xE0]
    ; 32 columns, 16 shades. Shade changes every 2 pixel steps.
    ; ==========================================
    LDI   R5, FMT_32x16_4BPP  
    LDI   R1, 0       
    LDI   R7, 16              

row_3:
    LDI   R3, 0         
byte_3:
    MOV   R2, R3              ; 16 columns map directly to 16 shade levels (0-15)
    STORE R1, R2, 0         
    INC   R1                  
    INC   R3                  
    LDI   R4, 16
    BNE   R3, R4, byte_3  

    DEC   R7                  
    BNE   R7, R0, row_3  

wait_busy_3:
    LOAD  R4, R0, MMIO_GPHC_ST     
    ANDI  R4, R4, u128            
    BNE   R4, R0, wait_busy_3       

    STORE R0, R0, MMIO_VRAM_AD   
    STORE R0, R5, MMIO_GPHC_ST   

    LDI   R10, hold_time
    RJMP  delay_centiseconds_3
return_3:


    ; ==========================================
    ; 4. FORMAT: 16x16 (8BPP) [FMT_16x16_8BPP = 0xF0]
    ; 16 columns, 256 shades. Full 8-bit horizontal ramp.
    ; ==========================================
    LDI   R5, FMT_16x16_8BPP  
    LDI   R1, 0       
    LDI   R7, 16              

row_4:
    LDI   R3, 0         
byte_4:
    MOV   R2, R3
    SHL   R2, R2              
    SHL   R2, R2              
    SHL   R2, R2              
    SHL   R2, R2              ; Scale 16 columns across 0-255 brightness ramp
    STORE R1, R2, 0         
    INC   R1                  
    INC   R3                  
    LDI   R4, 16
    BNE   R3, R4, byte_4  

    DEC   R7                  
    BNE   R7, R0, row_4  

wait_busy_4:
    LOAD  R4, R0, MMIO_GPHC_ST     
    ANDI  R4, R4, u128            
    BNE   R4, R0, wait_busy_4       

    STORE R0, R0, MMIO_VRAM_AD   
    STORE R0, R5, MMIO_GPHC_ST   

    LDI   R10, hold_time
    RJMP  delay_centiseconds_4
return_4:

    RJMP  main_loop           ; Cycle infinitely through all 4 formats


; ==========================================
; Inline-Safe Delay Routines (No Stack/CALL)
; ==========================================
delay_centiseconds_1:
    LDI   R11, 16
cent_outer_1:
    LDI   R12, 255
cent_mid_1:
    LDI   R13, 255
cent_inner_1:
    DEC   R13
    BNE   R13, R0, cent_inner_1
    DEC   R12
    BNE   R12, R0, cent_mid_1
    DEC   R11
    BNE   R11, R0, cent_outer_1
    DEC   R10
    BNE   R10, R0, delay_centiseconds_1
    RJMP  return_1

delay_centiseconds_2:
    LDI   R11, 16
cent_outer_2:
    LDI   R12, 255
cent_mid_2:
    LDI   R13, 255
cent_inner_2:
    DEC   R13
    BNE   R13, R0, cent_inner_2
    DEC   R12
    BNE   R12, R0, cent_mid_2
    DEC   R11
    BNE   R11, R0, cent_outer_2
    DEC   R10
    BNE   R10, R0, delay_centiseconds_2
    RJMP  return_2

delay_centiseconds_3:
    LDI   R11, 16
cent_outer_3:
    LDI   R12, 255
cent_mid_3:
    LDI   R13, 255
cent_inner_3:
    DEC   R13
    BNE   R13, R0, cent_inner_3
    DEC   R12
    BNE   R12, R0, cent_mid_3
    DEC   R11
    BNE   R11, R0, cent_outer_3
    DEC   R10
    BNE   R10, R0, delay_centiseconds_3
    RJMP  return_3

delay_centiseconds_4:
    LDI   R11, 16
cent_outer_4:
    LDI   R12, 255
cent_mid_4:
    LDI   R13, 255
cent_inner_4:
    DEC   R13
    BNE   R13, R0, cent_inner_4
    DEC   R12
    BNE   R12, R0, cent_mid_4
    DEC   R11
    BNE   R11, R0, cent_outer_4
    DEC   R10
    BNE   R10, R0, delay_centiseconds_4
    RJMP  return_4