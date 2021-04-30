
ADDR	.= $FE		; 2 bytes, an address

	*= $8000

RES_vec
    	CLD             ; clear decimal mode
    	LDX #$FF
    	TXS             ; set the stack pointer

	JMP loop

inc_addr:
	; we increment ADDR
	INC ADDR	; ADDR LO++
	BNE put_newline	; show_addr
	INC ADDR+1	; ADDR HI++
	JMP put_newline
	
put_newline:
	; output a CR+LF
	LDA #$0a ; CR
	JSR putc
	LDA #$0d ; LF
	JSR putc
	; fallback to loop

loop:	

; show address
	LDA ADDR+1
	JSR print_byte
	LDA ADDR
	JSR print_byte

; show value at addr
	LDA #':'
	JSR putc

	LDY #0
	LDA (ADDR),y
	TAX		; we use X to save the VALUE
	JSR print_byte	; print byte at ADDR

	LDA #' '
	JSR putc

	CPX #$20
	BMI non_printable	; not printable (too low)
	CPX #$7E
	BPL non_printable	; not printable (too low)

	TXA
	JSR putc
	JMP prompt
	
non_printable:
	; print a blank char
	LDA #' '
	JSR putc

prompt:	
	LDA #' '
	JSR putc
	LDA #'?'
	JSR putc
	LDA #' '
	JSR putc

	JSR getline
	
	CMP #$0d ; LF
	BEQ cmd_return
	; here user hit ESC
	
cmd_esc:
	; here we do whatever to handle an ESC
	LDA #'E'
	JSR putc
	lda #'S'
	JSR putc
	lda #'C'
	JSR putc
	; fall through to  put_newline


cmd_return:
	; here we do whatever to handle a RETURN
	
	; decision tree depending on the length
	; (length is still stored in X at this pointtp)

	CPX #0	; user has just hit return again?
	BEQ inc_addr

	LDA CMD	 ; first char

	CMP #'X'		; starts with X
	BEQ exec_cmd

	CMP #'''		; starts with quote
	BEQ it_is_a_char

	CPX #2			; 2 chars --> a value
	BEQ it_is_a_value

	CPX #4			; 4 chars --> an addr
	BEQ it_is_an_addr

	; ELSE
	JMP error


exec_cmd:
	JMP (ADDR)
	; we don't know were wi'll end up...

it_is_a_char:
	LDX #1		; we load the 2nd byte of CMD
	LDA CMD,x	; into A
	
	STA (ADDR),y	; and store at ADDR

	JMP inc_addr
		
it_is_a_value:
	LDX #0
	JSR scan_ascii_byte

	STA (ADDR),y

	JMP inc_addr

it_is_an_addr:
	LDX #0
	JSR scan_ascii_addr
	JMP put_newline
	
error:
	LDA #'E'
	JSR putc
	lda #'R'
	JSR putc
	lda #'R'
	JSR putc

	JMP put_newline ; and loop

print_byte:
	PHA	; save A for 2nd nibble
	LSR	; here we shift right
	LSR	; to get HI nibble
	LSR
	LSR
	JSR nibble_value_to_asc
	JSR putc

	PLA
	AND #$0F ; LO nibble
	JSR nibble_value_to_asc
	JSR putc
	RTS

getc:	
	LDA IO_AREA+4
	BEQ getc
	RTS

putc:
	STA IO_AREA+1
	RTS

getline:
	LDX #0
next:	
	JSR getc

	CMP #$0D	; LF (enter)?
	BEQ eol

	CMP #$1B 	; ESC	
	BEQ eol

	CMP #$08 	; Backspace	
	BEQ backspace

;	CMP #'9'+1
;	BMI skip_uppercase
;	AND #$DF 	; make upper case
;skip_uppercase:
	STA CMD,x	; save in buffer
	
	CPX #$0F	; x=15 -> end line
	BEQ eol
	
	INX
	JSR putc	; echo char
	JMP next	; wait for next

backspace:
	CPX #0
	BEQ next
	DEX
	JSR putc	; echo char
	JMP next

eol:
	STX LEN
	RTS

nibble_asc_to_value:
; converts a char representing a hex-digit (nibble)
; into the corresponding hex value
	CMP #$41
	BMI less
	SBC #$37
less:
	AND #$0F
	RTS

nibble_value_to_asc:
	CMP #$0A
	BCC skip
	ADC #$66
skip:
	EOR #$30
	RTS

scan_ascii_addr:
	LDA CMD,X	; load char into A
	JSR nibble_asc_to_value
	ASL
	ASL
	ASL
	ASL
	STA ADDR+1

	INX
	LDA CMD,X	; load char into A
	JSR nibble_asc_to_value
	
	ORA ADDR+1
	STA ADDR+1

	INX
	LDA CMD,X	; load char into A
	JSR nibble_asc_to_value
	ASL
	ASL
	ASL
	ASL
	STA ADDR
	
	INX
	LDA CMD,X	; load char into A
	JSR nibble_asc_to_value
	ORA ADDR
	STA ADDR
	
	RTS

scan_ascii_byte:
	LDA CMD,X	; load char into A
	JSR nibble_asc_to_value
	ASL
	ASL
	ASL
	ASL
	STA BYTE

	INX
	LDA CMD,X	; load char into A
	JSR nibble_asc_to_value
	ORA BYTE
	STA BYTE
	RTS

msg	.BYTE "Monitor v0", 0


IRQ_vec
	; Save registers
	STA SAVE_A
	STX SAVE_X
	STY SAVE_Y
	TSX		; get SP into X
	INX		; add 3 to get real 
	INX		; SP before IRQ
	INX
	STX SAVE_S
	PLA 		; P is on stack
	STA SAVE_P
	PLA
	STA SAVE_PC
	PLA
	STA SAVE_PC+1
	PHA		; put P back on stack
	LDA SAVE_PC
	PHA
	LDA SAVE_P
	PHA
	; is it a BRK?
	LDA #$10	; position of B bit
	BIT SAVE_P	; is B bit set, indicating BRK and not IRQ?
	BNE BRKhandler

	; for now, force jmp to BRKhandler
	JMP BRKhandler
	
	PHA
	LDA #'I'
	JSR putc
	LDA #'R'
	JSR putc
	LDA #'Q'
	JSR putc
	PLA

	LDX SAVE_S
	TXS
	LDY SAVE_Y
	LDX SAVE_X
	LDA SAVE_A
	RTI

BRKhandler:
	LDA #' '
	JSR putc
	LDA #'A'
	JSR putc
	LDA SAVE_A
	JSR print_byte

	LDA #' '
	JSR putc
	LDA #'X'
	JSR putc
	LDA SAVE_X
	JSR print_byte

	LDA #' '
	JSR putc
	LDA #'Y'
	JSR putc
	LDA SAVE_Y
	JSR print_byte

	LDA #' '
	JSR putc
	LDA #'P'
	JSR putc
	LDA SAVE_P
	JSR print_byte

	LDA #' '
	JSR putc
	LDA #'S'
	JSR putc
	LDA SAVE_S
	JSR print_byte

	LDA #' '
	JSR putc
	LDA #'P'
	JSR putc
	LDA #'C'
	JSR putc
	LDA SAVE_PC+1
	JSR print_byte
	LDA SAVE_PC
	JSR print_byte

	LDX SAVE_S
	TXS
	LDY SAVE_Y
	LDX SAVE_X
	LDA SAVE_A

	JMP loop
	;RTI
	
NMI_vec
	RTI


	*= $0200

BYTE	.DS 1
LEN 	.DS 1	; Length of CMD
CMD	.DS 16	; CMD string
SAVE_A  .DS 1
SAVE_X  .DS 1
SAVE_Y  .DS 1
SAVE_S  .DS 1
SAVE_P  .DS 1
SAVE_PC .DS 2

; system vectors

    *=  $FFFA

    .word   NMI_vec     ; NMI vector
    .word   RES_vec     ; RESET vector
    .word   IRQ_vec     ; IRQ vector