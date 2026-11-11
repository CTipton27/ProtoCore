	ADDI R2, R0, u255       ; Reference bit value 0xFF

pre_fill:
    ADDI R1, R0, u255       ; Start counter at 255
mem_fill:
    STORE R1, R2, 0         ; RAM[R1] = 0xFF

    ; Check if we just hit 0 before decrementing
    BEQ R1, R0, send_frame  ; If R1 was already 0, we are done filling
    DEC R1                  ; Otherwise decrement
    RJMP mem_fill           ; Jump back to fill next byte

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

    RJMP pre_fill                ; Loop back to refill/re-render