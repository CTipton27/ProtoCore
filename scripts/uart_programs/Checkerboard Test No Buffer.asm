.equ hold_time, 100     ; Hold each format for 100 centiseconds (1.0 seconds total)

test_all_formats:

    ; ==========================================
    ; 1. FORMAT: 64x32 (1BPP) — 8 bytes/row, 32 rows
    ; ==========================================
    LDI   R5, FMT_64x32_1BPP  ; R5 = 0xC0
    LDI   R2, 170             ; R2 = 0xAA (10101010)
    LDI   R1, 255             ; R1 = Top of RAM (255)
    LDI   R7, 32              ; R7 = 32 rows total

fill_row_1:
    LDI   R6, 8               ; R6 = 8 bytes per row
fill_byte_1:
    STORE R1, R2, 0         ; RAM[R1] = R2
    DEC   R1
    DEC   R6
    BNE   R6, R0, fill_byte_1

    NOT   R2, R2              ; Invert pattern for next row
    DEC   R7
    BNE   R7, R0, fill_row_1

    ; 1. Wait for graphics hardware to be idle (Bit 7 must drop to 0)
wait_busy_1:
    LOAD  R4, R0, MMIO_GPHC_ST
    ANDI  R4, R4, u128
    BNE   R4, R0, wait_busy_1

    ; 2. Trigger frame capture
    STORE R0, R0, MMIO_VRAM_AD
    STORE R0, R5, MMIO_GPHC_ST

    ; 3. Hold on screen for 1 second
    LDI   R10, hold_time
    RJMP  delay_centiseconds_1
return_1:


    ; ==========================================
    ; 2. FORMAT: 32x32 (2BPP) — 8 bytes/row, 32 rows
    ; ==========================================
    LDI   R5, FMT_32x32_2BPP  ; R5 = 0xD0
    LDI   R2, 204             ; R2 = 0xCC (11001100)
    LDI   R1, 255
    LDI   R7, 32

fill_row_2:
    LDI   R6, 8
fill_byte_2:
    STORE R1, R2, 0
    DEC   R1
    DEC   R6
    BNE   R6, R0, fill_byte_2

    NOT   R2, R2
    DEC   R7
    BNE   R7, R0, fill_row_2

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
    ; 3. FORMAT: 32x16 (4BPP) — 16 bytes/row, 16 rows
    ; ==========================================
    LDI   R5, FMT_32x16_4BPP  ; R5 = 0xE0
    LDI   R2, 240             ; R2 = 0xF0 (11110000)
    LDI   R1, 255
    LDI   R7, 16              ; R7 = 16 rows total

fill_row_3:
    LDI   R6, 16              ; R6 = 16 bytes per row
fill_byte_3:
    STORE R1, R2, 0
    DEC   R1
    DEC   R6
    BNE   R6, R0, fill_byte_3

    NOT   R2, R2
    DEC   R7
    BNE   R7, R0, fill_row_3

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
    ; 4. FORMAT: 16x16 (8BPP) — 16 bytes/row, 16 rows (Alternating Bytes)
    ; ==========================================
    LDI   R5, FMT_16x16_8BPP  ; R5 = 0xF0
    LDI   R2, 255             ; R2 starts at 0xFF (White pixel)
    LDI   R1, 255
    LDI   R7, 16              ; R7 = 16 rows total

fill_row_4:
    LDI   R6, 16              ; R6 = 16 bytes per row
fill_byte_4:
    STORE R1, R2, 0
    DEC   R1
    NOT   R2, R2              ; Alternate byte between 0xFF and 0x00 horizontally
    DEC   R6
    BNE   R6, R0, fill_byte_4

    NOT   R2, R2              ; Invert starting pattern for the next row
    DEC   R7
    BNE   R7, R0, fill_row_4

wait_busy_4:
    LOAD  R4, R0, MMIO_GPHC_ST
    ANDI  R4, R4, u128
    BNE   R4, R0, wait_busy_4

    STORE R0, R0, MMIO_VRAM_AD
    STORE R0, R5, MMIO_GPHC_ST

    LDI   R10, hold_time
    RJMP  delay_centiseconds_4
return_4:

    RJMP  test_all_formats    ; Loop the entire format sequence infinitely


; ==========================================
; Unrolled Delay Subroutines (100 MHz tuned)
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