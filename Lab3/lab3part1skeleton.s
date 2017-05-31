	AREA	lib, CODE, READWRITE	
	EXPORT lab3
	EXPORT pin_connect_block_setup_for_uart0
	EXPORT uart_init
	
U0LSR EQU 0x14			; UART0 Line Status Register

      ; You'll want to define more constants to make your code easier  
      ; to read and debug 
      ; Memory allocated for user-entered strings 
prompt = "Enter a number:  ",0          
input = "+0000",0
input2 = "Enter a number between -9999 and 9999",0
prompt2 = "Enter a second number:  ",0   
input3 = "The mean is: ",0
      ; Additional strings may be defined here 
   ALIGN 

lab3
	STMFD SP!,{lr}	; Store register lr on stack
    
	LDR r4, =input2
	BL OS
	MOV r0, #0x0A
	BL	OC
	MOV r0, #0x0d
	BL	OC
	LDR r4, =prompt
	BL OS
	LDR r4, =input
	BL RS			 ;Obtain user input
	BL S2N
	MOV r3, r2

	LDR r4, =prompt2
	BL OS

	LDR r4, =input
	BL RS
	BL S2N
	ADD r2, r2, r3
	MOV r1, #2
	MOV r0, r2
	BL div_and_mod 
	MOV r2,r0
	LDR r4, =input
	BL N2S
	
	LDR r4, =input3
	BL OS
	MOV r0, #0x0A
	BL	OC
	MOV r0, #0x0d
	BL	OC

	LDR r4, =input
	BL OS

	LDMFD sp!,{lr}
	BX lr	
	

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

	END
