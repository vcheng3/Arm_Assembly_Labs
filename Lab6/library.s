	AREA	lib, CODE, READWRITE
	EXPORT RS
	EXPORT OS
	EXPORT OC
	EXPORT RC
	EXPORT uart_init
	EXPORT pin_connect_block_setup_for_uart0
	EXPORT pin_connect_block_setup_for_7_segment
	EXPORT display_digit
	EXPORT interrupt_init   
	EXPORT String_to_number
	EXPORT number_to_string2
	EXPORT number_to_string
	EXPORT div_and_mod
	EXPORT read_character
	EXPORT output_string

U0LSR EQU 0x14			; UART0 Line Status Register

prompt = "Enter a number:  ",0          
input = "+0000",0
input2 = "Enter a number between -9999 and 9999",0
prompt2 = "Enter a second number:  ",0   
input3 = "The mean is: ",0

	ALIGN

global_reg
		DCB 0x00	 		;negative global flag
		DCB 0x00			 ;Previous Value
		DCB 0x00			;Button Flag			  
	ALIGN

digits_SET	
		DCD 0x1F80  ; 0
 		DCD 0x0300  ; 1 
		DCD	0x2D80	; 2
		DCD	0x2780	; 3	
		DCD	0x3300	; 4
		DCD	0x3680	; 5
		DCD	0x3E80	; 6
		DCD	0x0380	; 7
		DCD	0x3F80	; 8
		DCD	0x3780	; 9 
		DCD	0x3B80	; A
		DCD	0x3E00	; B
		DCD	0x2C00	; C
		DCD	0x2F00	; D
		DCD	0x3C80	; E			
		DCD 0x3880  ; F	
		DCD 0x1000	
	ALIGN
			
color_SET	
		DCD 0x0 		;White
		DCD 0x240000  	;Red
		DCD 0x220000  	;Blue
		DCD 0x60000 	;Green
		DCD 0x40000 	;Yellow
		DCD 0x200000  	;Purple
		DCD 0x260000	;OFF
	ALIGN

binary_SET
		DCD 0xF0000		;0
		DCD 0x70000		;1
		DCD 0x40000		;2
		DCD 0x30000		;3
		DCD 0xD0000		;4
		DCD 0x50000	  	;5
		DCD 0x90000		;6
		DCD 0x10000		;7
		DCD 0xE0000		;8
		DCD 0x60000		;9
		DCD 0xA0000		;10
		DCD 0x20000		;11
		DCD 0xC0000		;12
		DCD 0x40000		;13
		DCD 0x80000	 	;14
		DCD 0x00000		;15
	ALIGN 

	ALIGN

read_string

RS		STMFD sp!,{r0,r4, lr}	  	
LOOP3   BL RC				;Read Character
		BL OC 				;Output character
		CMP r0, #0x0D
		BEQ END
		STRB r0, [r4], #1	;Store the byte from RC into the address at r0, then change r0 to the next memory address		  	
		B LOOP3	
END		MOV r0, #0x00
		STRB r0, [r4]		
		MOV r0, #0x0A
		BL	OC

		LDMFD sp!,{r0,r4,lr}
		BX lr				;Branch back to main

output_string

OS		STMFD sp!,{r0, lr}
LOOP4	LDRB r0,[r4], #1		;auto increment after loading
		CMP r0, #0x00			;compare to null terminated string in ascii
		BEQ STOP				;branch to stop if equal
		BL OC					;else branch to output_character
		B LOOP4
STOP	LDMFD sp!, {r0, lr}
		BX lr


read_character 
		
RC		STMFD sp!,{r6-r7,lr}
		LDR r6, =0xE000C000
LOOP8	LDRB r7, [r6, #U0LSR]
		AND r7, r7, #0x1
		CMP r7, #0
		BEQ LOOP8
		LDRB r0, [r6]
		LDMFD sp!,{r6-r7,lr}
		BX lr

		
output_character

OC		STMFD sp!,{r7-r8,lr}
		LDR r8, =0xE000C000
LOOP2	LDRB r7, [r8, #U0LSR]
		AND r7, r7, #0x20
		CMP r7, #0
		BEQ LOOP2
		STRB r0, [r8]
		LDMFD sp!, {r7-r8,lr}
		BX lr


String_to_number

S2N		STMFD sp!,{r3,r5-r6,r10,lr}
		
		MOV r2, #0
		MOV r6, #0			;Initialize Negative Flag
 		MOV r3, #0			;Initialize counter
		LDRB r5,[r4],#1		;grab the first character in string from memory
		CMP r5, #0x2D		;2D in hex is '-'
		BNE LOOP5			;Branch if the string isn't representing a negative number
		add r3, #-1			;Decrement counter 
		MOV r6, #1			;Set negative flag

							;DETERMINE total number of numbers in string
LOOP5	add r3, r3, #1		;Increment counter
		LDRB r5, [r4], #1	;grab next character from memory
		CMP r5, #0x00		;check if character is null
		BNE LOOP5			;Loop if not null

		LDR r4, =input		;Reset base address
		CMP r6, #0			;Check if number was negative
		BEQ POS				;Branch if number was positive
		ADD r4, r4, #1		;Increment String Base Address
POS		LDRB r5,[r4], #1	;Grab character in String
		add r5, r5, #-48	;Change the hex number into the number it represents
		CMP r3, #4			;Check if the String had 4 numbers
		BNE next			;If not then skip
		add r3, r3, #-1		;decrement counter
		MOV r10, #1000
		MUL r5, r10, r5		;Multiply the number by 1000
		ADD r2, r2, r5		;Store the product into a register
		B POS				;Branch back to POS

next	CMP r3, #3			;Check if the String had 3 numbers
		BNE next2			;If not then skip
		add r3, r3, #-1		;decrement counter
		MOV r10, #100
		MUL r5, r10, r5		;Multiply the number by 100
		ADD r2, r2, r5		;Store the product into a register
		B POS

next2	CMP r3, #2			;Check if the String had 2 numbers
		BNE next3			;If not then skip
		add r3, r3, #-1		;decrement counter
		MOV r10, #10
		MUL r5, r10, r5		;Multiply the number by 10
		ADD r2, r2, r5		;Store the product into a register
		B POS

next3	ADD r2, r2, r5		;Add the last number to the total
		CMP r6, #0			;Check if the number was negative
		BEQ DONE
		MVN r2,r2			;Change the number to negative
		ADD r2, r2, #1		
DONE	LDMFD sp!,{r3,r5-r6,r10,lr}
		BX lr



number_to_string

N2S		STMFD sp!,{r0-r1,r5,r8-r10,lr}
		MOV r5, #0
		MOV r9, #0
		CMP r2, #0				;Check if the number is negative
		BGE skip				;Skip if the number wasn't negative
		ADD r5, r5, #0x2D	
		STRB r5, [r4], #1		;Add a '-' character to the beginning of the string
		
		CMP r2, #0
		NEGLT r2, r2			
		

skip	MOV r0,r2				;Set the Dividend as the number
		MOV r1, #1000			;Set the Divisor as 1000				
		BL div_and_mod			;Divide the number by 1000
		CMP r0, #0				;Check if the Quotient is less than zero
		BLE next5				 ;Skip if Quotient is less than zero
		ADD r8, r0, #48			  ;Change the Quotient into its hex representation for ASCII
		STRB r8, [r4], #1		  ;Store that character into the memory
		MOV r10, #1000
		MUL r9, r0, r10
		SUB r2, r2, r9			  ;Subtract the number added to the string from the original number
		CMP r2, #0
		BNE next5
		ADD r2, #48
		STRB r2, [r4], #1
		STRB r2, [r4], #1
		STRB r2, [r4], #1
		B ZERO

next5	MOV r0,r2				;Set the Dividend as the number
		MOV r1, #100			;Set the Divisor as 100				
		BL div_and_mod			;Divide the number by 100
		CMP r0, #0				;Check if the Quotient is less than zero
		BLE next6				 ;Skip if Quotient is less than zero
		ADD r8, r0, #48			  ;Change the Quotient into its hex representation
		STRB r8, [r4], #1		  ;Store that character into the memory
		MOV r10, #100
		MUL r9, r0, r10
		SUB r2, r2, r9			  ;Subtract the number added to the string from the original number
		CMP r2, #0
		BNE next6
		ADD r2, #48
		STRB r2, [r4], #1
		STRB r2, [r4], #1
		B ZERO


next6	MOV r0,r2				;Set the Dividend as the number
		MOV r1, #10			;Set the Divisor as 10			
		BL div_and_mod			;Divide the number by 10
		CMP r0, #0				;Check if the Quotient is less than zero
		BLE next7				 ;Skip if Quotient is less than zero
		ADD r8, r0, #48			  ;Change the Quotient into its hex representation
		STRB r8, [r4], #1		   ;Store that character into the memory
		MOV r10, #10		  
		MUL r9, r0, r10
		SUB r2, r2, r9			  ;Subtract the number added to the string from the original number

next7	ADD r2, r2, #48
		STRB r2, [r4], #1		;Add final number charcter
ZERO	MOV r2, #0x00			
		STRB r2, [r4]			;Add null to end of the string
		LDMFD sp!,{r0-r1,r5,r8-r10,lr}

		BX lr
		
number_to_string2

		STMFD sp!,{r0,r1,r5,r8-r10,lr}	  ;number passed in through r2 		
 
			
		MOV r0,r2				;Set the Dividend as the number
		MOV r1, #100			;Set the Divisor as 100				
		BL div_and_mod			;Divide the number by 100
		CMP r0, #0				;Check if the Quotient is less than zero
		BLE NOT100				 ;Skip if Quotient is less than zero
		ADD r8, r0, #48			  ;Change the Quotient into its hex representation
		STRB r8, [r4], #1		  ;Store that character into the memory
		MOV r10, #100
		MUL r9, r0, r10
		SUB r2, r2, r9			  ;Subtract the number added to the string from the original number
		CMP r2, #0
		BNE NOT100
		ADD r2, #48
		STRB r2, [r4], #1
		STRB r2, [r4], #1
		B ZERO2

NOT100	ADD r4, r4, #1
		MOV r0,r2				;Set the Dividend as the number
		MOV r1, #10			;Set the Divisor as 10			
		BL div_and_mod			;Divide the number by 10
		CMP r0, #0				;Check if the Quotient is less than zero
		BLE NOT10				 ;Skip if Quotient is less than zero
		ADD r8, r0, #48			  ;Change the Quotient into its hex representation
		STRB r8, [r4]		   ;Store that character into the memory
		MOV r10, #10		  
		MUL r9, r0, r10
		SUB r2, r2, r9			  ;Subtract the number added to the string from the original number

NOT10	ADD r4, r4, #1
		ADD r2, r2, #48
		STRB r2, [r4] 		;Add final number charcter

ZERO2	
		LDMFD sp!,{r0,r1,r5,r8-r10,lr}

		BX lr		

div_and_mod
		STMFD r13!, {r2-r12, r14}
			
	; Your code for the signed division/mod routine goes here.  
	; The dividend is passed in r0 and the divisor in r1.
	; The quotient is returned in r0 and the remainder in r1. 
	

main		
			MOV r6, #0				;flag1 temp r6
			CMP r0, #0
			NEGLT r0, r0			;negate less than
			ADDLT r6,r6, #1			;negate add divisor 0 
			MOV r7, #0				;flag2 temp r7
			CMP r1, #0
			NEGLT r1, r1
			ADDLT r7,r7, #1			;negate then add divisor, 0
			MOV r3, #15				;Counter(r3)
			MOV r4, #0				;Quotient(r4) 
			MOV r1, r1, LSL #15 	;15-bit shift divisor
			MOV r5, r0				;remainder(r5) = dividend		
LOOP9		SUB r5, r5, r1 		   ;remainder -= divisor 
			CMP r5, #0				;compares r5 to 0
			BLT COUNT				;if less than branch to count
			MOV r4, r4, LSL  #1		;left shift quotient 1 bit
			ADD r4,r4, #1
CHECK		MOV r1, r1, LSR  #1 	;shift 1bit right
			CMP r3, #0				;compare counter to 0 
			BLE SWITCH				;less than branch
			SUB r3, r3, #1			;decrement by 1
			B LOOP9					;next iteration of loop
COUNT   	ADD r5, r5, r1  		;remainder += divisor
			MOV r4, r4, LSL #1		;shift 1bit left
			B CHECK					;jumps to check
SWITCH		CMP r6,#1
			NEGEQ r4,r4;			;both can't be negs
			CMP r7, #1
			NEGEQ r4,r4;
			MOV r0,r4				;get the quotient here and set it to r0
			MOV r1,r5				;get remainder and set it to r1

			LDMFD r13!, {r2-r12, r14}
			BX lr      ; Return to the C program 

uart_init
		STMFD 	sp!, {lr,r0-r7}
		LDR 	r0, =0xE000C00C
		MOV     r1, #131			
		STRB 	r1, [r0]				;store 131 into r0
		LDR 	r2,	=0xE000C000
		MOV		r3,	#120
		STRB	r3, [r2] 				;store 120 into r2
		LDR		r4,	=0xE000C004
		MOV		r5,	#0x00
		STRB	r5,	[r4] 				;store 0 into r4
		LDR		r6,	=0xE000C00C
		MOV		r7, #0x03
		STRB	r7,	[r6] 				;store 3 into r6
		
		LDMFD 	sp!, {lr,r0-r7}
		BX 		lr

pin_connect_block_setup_for_uart0
	STMFD sp!, {r0, r1, lr}
	LDR r0, =0xE002C000  ; PINSEL0
	LDR r1, [r0]
	ORR r1, r1, #5
	BIC r1, r1, #0xA
	STR r1, [r0]
	LDMFD sp!, {r0, r1, lr}
	BX lr

pin_connect_block_setup_for_7_segment
		
	   STMFD sp!, {r1-r2}		
	   LDR r0, =0x06FFC000		
	   LDR r1, =0xE002C000		;Load PINSEL0 address in r1
	   LDR r2, [r1]				;Load memory from PINSEL0 in r2
	   BIC r2, r2, r0			;Pins 7 - 13 are changed to 0's
	   STR r2, [r1]				;Store changes back into PINSEL0
	   
	   LDR r0, =0x3F80
	   LDR r1, = 0xE0028008		;Load IO0DIR address in r1
	   LDR r2, [r1]				;Load IO0DIR memory in r2
	   ORR r2, r2, r0 			;Pins 7 - 13 are changed to 1's
	   STR r2, [r1]				;Store changes back into IO0DIR
	   LDMFD sp!, {r1-r2}
	   BX LR
	   
pin_connect_block_setup_for_RGB_LEDs
		
	   STMFD sp!, {r1-r2}
	   LDR r0, =0xC3C
	   LDR r1, =0xE002C004		;Load PINSEL1 address in r1
	   LDR r2, [r1]				;Load memory from PINSEL1 in r2
	   BIC r2, r2, r0			;Pins 17,18,21 are changed to 0's
	   STR r2, [r1]				;Store changes back into PINSEL1
	   
	   LDR r0, =0x260000
	   LDR r1, = 0xE0028008		;Load IO0DIR address in r1
	   LDR r2, [r1]				;Load IO0DIR memory in r2
	   ORR r2, r2, r0 			;Pins 17,18,21 are changed to 1's
	   STR r2, [r1]				;Store changes back into IO0DIR
	   LDMFD sp!, {r1-r2}
	   BX LR

LED_Dir

	   STMFD sp!, {r0-r2,lr}
	   LDR r0, = 0xF0000
	   LDR r1, = 0xE0028018		;Load IO1DIR address in r1
	   LDR r2, [r1]				;Load IO1DIR memory in r2
	   ORR r2, r2, r0 			;Pins 16-19 are changed to 1's
	   STR r2, [r1]				;Store changes back into IO1DIR
	   LDMFD sp!, {r0-r2,lr}
	   BX LR


display_digit_seg	;r0 is the input/r0 = digit pattern

		STMFD sp!, {lr,r1-r2}			
		LDR r1, =0xE0028004	   	;Load IO0SET Address in r1
		LDR r2, [r1]			;Load IO0SET Memory in r2
		ORR r2, r2, r0			;Pins in pattern are changed to 1
		STR r2, [r1]			;Store changes back in IO0SET
		LDMFD sp!, {lr,r1-r2}
		BX lr
		
display_color	;r0 is the input

		STMFD sp!, {lr,r1-r2}			
		LDR r1, =0xE0028004	    ;Load IO0SET Address in r1
		LDR r2, [r1]			;Load IO0SET Memory in r2
		ORR r2, r2, r0			;Pins in pattern are changed to 1
		STR r2, [r1]			;Store changes back in IO0SET
		LDMFD sp!, {lr,r1-r2}
		BX lr
		
clear_color	;r0 is the input
		
		STMFD sp!, {lr,r1-r2}
		LDR r1, =0xE002800C		;Load IO0CLR Address in r1
		LDR r2, [r1]			;Load IO0CLR Memory in r2
		ORR r2, r2, r0			;Pins in pattern are changed to 1
		STR r2, [r1]			;Store changes back in IO0CLR
		LDMFD sp!, {lr,r1-r2}
		BX lr

clear_digit_seg	;r0 is the input
		
		STMFD sp!, {lr,r1-r2}
		LDR r1, =0xE002800C		;Load IO0CLR Address in r1
		LDR r2, [r1]			;Load IO0CLR Memory in r2
		ORR r2, r2, r0			;Pins in pattern are changed to 1
		STR r2, [r1]			;Store changes back in IO0CLR
		LDMFD sp!, {lr,r1-r2}
		BX lr

display_digit	;r0 is the input

		STMFD sp!, {lr,r1-r3}
		MOV r1, r0				;Store value in r0 in r1 
		LDR r3, =digits_SET	
		MOV r6, #8	
		LDR r0, [r3, r6, LSL #2];Load IOSET pattern for '8' in r0
		BL clear_digit_seg		;Clear all digit segments
		LDR r0, [r3, r1, LSL #2];Load IOSET pattern from list
		BL display_digit_seg	;Display digit 
		LDMFD sp!, {lr,r1-r3}
		BX lr
		
RGB_LEDs	;r0 is the input

		STMFD sp!, {lr,r1-r3}
		MOV r1, r0				;Store value in r0 in r1
		LDR r3, =color_SET
		LDR r0, =0x0260000				
		BL clear_color
				
		LDR r0, [r3, r1, LSL #2]		
		BL display_color			
		
		LDMFD sp!, {lr,r1-r3}
		BX lr

;push_button		;store value in r0
;		STMFD sp!, {r1,r2,r3}
;		LDR r0, = 0x00F00000	;pins 20-23
;		MOV r1, r0
;		LDR r1, =0xE002C000		;Load PINSEL0 address in r1
;		LDR r2, [r1]			;Load memory from PINSEL0 in r2
;	    BIC r2, r2, r0			;pin 20-23 changed to 0's
;	    STR r2, [r1]			;Store changes back into PINSEL0
		
;		LDR r3, =read_character	
;		LDR r3, [r0]
		
;		LDMFD sp!, {lr,r1-r3}
;		BX lr

LEDs	;r0 is the input

		STMFD sp!, {lr,r1-r6}
		LDR r4, =binary_SET
		LDR r1, =0xE002801C		;Load IO1CLR Address in r1
		LDR r2, [r1]			;Load IO1CLR Memory in r2
		LDR r6, [r4]			;Load pattern for '0' into r6
		ORR r2, r2, r6			;Pins in pattern are changed to 1
		STR r2, [r1]			;Store changes in to IO1CLR
					
		LDR r2, =0xE0028014		;Load IO1SET Address in r2
		LDR r0, [r4, r0, LSL #2];Load binary pattern into r0		
		LDR r3, [r2]			;Load IO1SET memory into r3
		ORR r3, r3, r0			;Pins in pattern are changed to 1
		STR r3, [r2]			;Store changes into IO1SET
		LDMFD sp!, {lr,r1-r6}
		BX lr

interrupt_init       
		STMFD SP!, {r0-r1, lr}   ; Save registers 
		
		; Push button setup		 
		LDR r0, =0xE002C000
		LDR r1, [r0]
		ORR r1, r1, #0x20000000
		BIC r1, r1, #0x10000000
		STR r1, [r0]  ; PINSEL0 bits 29:28 = 10

		; Classify sources as IRQ or FIQ
		LDR r0, =0xFFFFF00C
		LDR r1, [r0]
		ORR r1, r1, #0x8000 ; External Interrupt 1
		STR r1, [r0]

		; Enable Interrupts
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0x10] 
		ORR r1, r1, #0x8000 ; External Interrupt 1
		STR r1, [r0, #0x10]

		; Classify sources as IRQ or FIQ
		LDR r0, =0xFFFFF00C
		LDR r1, [r0]
		ORR r1, r1, #0x40 ; UART0 Interrupt 1
		STR r1, [r0]

		; Enable Interrupts
		LDR r0, =0xFFFFF010
		LDR r1, [r0] 
		ORR r1, r1, #0x40 ; UART0 Interrupt 1
		STR r1, [r0]
		
		; 
		LDR r0, =0xE000C004
		LDR r1, [r0] 
		ORR r1, r1, #0x1  
		STR r1, [r0]

		; Classify Timer0 Interrupt
		LDR r0, =0xFFFFF00C 
		LDR r1, [r0] 
		ORR r1, r1, #0x10 ; Timer0 Interrupt 1 
		STR r1, [r0] 
		
		; Enable Timer0 Interrupt
		LDR r0, =0xFFFFF010
		LDR r1, [r0] 
		ORR r1, r1, #0x10 ; Timer0 Interrupt 1   
		STR r1, [r0]

		; External Interrupt 1 setup for edge sensitive
		LDR r0, =0xE01FC148
		LDR r1, [r0]
		ORR r1, r1, #2  ; EINT1 = Edge Sensitive
		STR r1, [r0]

		; Enable FIQ's, Disable IRQ's
		MRS r0, CPSR
		BIC r0, r0, #0x40
		ORR r0, r0, #0x80
		MSR CPSR_c, r0



		LDMFD SP!, {r0-r1, lr} ; Restore registers
		BX lr             	   ; Return

increment_seven_segment

		STMFD sp!,{r3,r4,r7,lr}
		LDR r7, =global_reg
		LDRB r1, [r7, #1]

		ADD r2, r1, r2					;add first two numbers
		CMP r2, #0					    ;compare r1 to 0
		BLT LESSTHAN0					;branch if negative( number < 0 )					
		CMP	r2, #15						;else we can compare the number to 15
		BGT GREATERTHAN15				;jump to subroutine that subtract's 16( number > 15 )
		B return						;now we know that r1 is 1 <= r1 <= 15, so we can just store it
		
LESSTHAN0
		ADD r2, r2 , #0x10				;now we know it's negative. So we can just add 16.
		B return						;example is 5 - 15(F), going backwards answer is -10. So we add 16 to get 6

GREATERTHAN15
		SUB r2, r2, #0x10				;we subtract 16 if it exceeds 15
		B return						;branch to end

return  STRB r2, [r7, #1]

		LDMFD sp!, {r3,r4,r7,lr}
		BX lr

	END