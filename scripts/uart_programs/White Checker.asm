start_frame:
    ADDI R2, R0, u170       ; R2 = 0xAA (10101010 - Pattern A)
    ADDI R1, R0, u255       ; R1 = 255 (Start at the top of the RAM buffer)
    ADDI R7, R0, u32        ; R7 = 32 rows total

row_loop:
    ADDI R6, R0, u8         ; R6 = 8 bytes per row (Inner loop counter)

byte_loop:
    STORE R1, R2, 0         ; RAM[R1] = R2
    DEC R1                  ; Decrement RAM address pointer
    DEC R6                  ; Decrement inner byte counter
    BNE R6, R0, byte_loop   ; Loop until all 8 bytes of this row are written

    NOT R2, R2              ; Invert pattern (0xAA <-> 0x55) for the NEXT row
    DEC R7                  ; Decrement row counter
    BNE R7, R0, row_loop    ; Loop until all 32 rows are written

send_frame:
    ; 1. Wait for graphics hardware to finish any active capture (Bit 7 drops to 0)
check_frame:
    LOAD R4, R0, MMIO_GPHC_ST     ; Pull current graphics status
    ANDI R4, R4, u128            ; Isolate bit 7 (status/busy bit)
    BNE R4, R0, check_frame      ; If bit 7 is still high, loop and wait

    ; 2. Configure VRAM pointer and trigger new frame capture
    ADDI R3, R0, FMT_64x32_1BPP
    STORE R0, R0, MMIO_VRAM_AD   ; Tell VRAM to start fetching from address 0 in RAM
    STORE R0, R3, MMIO_GPHC_ST   ; Trigger frame capture

    RJMP start_frame             ; Loop back to refill/re-render for the next frame