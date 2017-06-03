	AREA interrupts, CODE, READWRITE
	EXPORT lab5
	EXPORT FIQ_Handler
	IMPORT pin_connect_block_setup_for_7_segment
	IMPORT OS
	IMPORT RS
	IMPORT display_digit
	IMPORT RC
	IMPORT OC
	

prompt = "Enter a hexadecimal number between -F and F.",0xA,0xD,0
prompt5 = "The sum of the number entered and the previous number displayed on the 7 segment display will be displayed.",0xA,0xD,0
prompt2 = "Press Z to reset the 7 segment display and previous value entered to 0",0xA,0xD,0
prompt3 = "Press Q to stop the program",0xA,0xD,0	
prompt4 = "Press the Interrupt Button to halt all keyboard inputs. Press the button again to continue normal operation",0xA,0xD,0
    ALIGN

global_reg
		DCB 0x00	 		;negative global flag
		DCB 0x00			 ;Previous Value
		DCB 0x00			;Button Flag			  
	ALIGN
lab5	 	
		STMFD sp!, {lr}

		LDR r4, =prompt
		BL OS
		LDR r4, =prompt5
		BL OS
		LDR r4, =prompt2
		BL OS
		LDR r4, =prompt3
		BL OS
		LDR r4, =prompt4
		BL OS
		BL pin_connect_block_setup_for_7_segment	  ;Branch Pin connect 7 segment
		BL interrupt_init							   ;Branch interrupt_init
AGAIN	ADD r0, r0, #0								   ;Infinite Loop
		B AGAIN

	
	LDMFD sp!,{lr}
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
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0xC]
		ORR r1, r1, #0x8000 ; External Interrupt 1
		STR r1, [r0, #0xC]

		; Enable Interrupts
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0x10] 
		ORR r1, r1, #0x8000 ; External Interrupt 1
		STR r1, [r0, #0x10]

		; Classify sources as IRQ or FIQ
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0xC]
		ORR r1, r1, #0x40 ; UART0 Interrupt 1
		STR r1, [r0, #0xC]

		; Enable Interrupts
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0x10] 
		ORR r1, r1, #0x40 ; UART0 Interrupt 
		STR r1, [r0, #0x10]

		; 
		LDR r0, =0xE000C004
		LDR r1, [r0] 
		ORR r1, r1, #0x1  
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



FIQ_Handler
        STMFD SP!, {r0-r12, lr}   ; Save registers 

EINT1            ; Check for EINT1 interrupt
        LDR r0, =0xE01FC140            ;Load the external interrupt flag register into r0
        LDR r1, [r0]                ;Load memory r0 into r1
        TST r1, #2                    ;checks to see if pin 2 is 1
        BEQ UART0                    ;equal, branch to the UART0
        LDR r3, =global_reg            ;load the global register from memory
        LDRB r4, [r3,#2]            ;load the 2nd global variable into r4
        CMP r4, #0x0                ;compare the flag to 0
        BNE not0                    ;if its not 0 than we branch to not0 Label
        ADD r4, #0x1                ;if it is a 0 then we add 1 to it
        STRB r4, [r3,#2]            ;store that back into the 2nd global variable
        B CLEAR                        ;branch to clear
not0    MOV r4, #0                    ;copy 0 into register 4
        STRB r4, [r3,#2]            ;store that back into the 2nd global variable 
        B CLEAR                        ;branch to clear

CLEAR    LDR r3, =0xE01FC140            ;Load the external interrupt flag register into r3
        LDR r1, [r3]                ;Load that into r1
        ORR r1, r1, #2                ;Clear Interrupt
        STR r1, [r0]                ;store that back into the external interrupt flag register
        LDR r6, =0xE000C000            ;load the push button address into r6    
        LDRB r0, [r6]                ;load the register byte memory to r0

        B FIQ_Exit                    ;branch to FIQ_exit, exit program
			
UART0		
			LDR r3, =global_reg		 ;Load global_reg into r3
			LDRB r4, [r3,#2]		 ;Load Button Flag into r4
			CMP r4, #0x1			  ;Check if Button Flag is 1
			BEQ FIQ_Exit			  ;If r4=1 then branch to FIQ_Exit

			LDR r0, =0xE000C008		  ;Load U0IIR (0xE000C008) into r0
			LDR r1, [r0]			   ;Load memory from U0IIR into r1
			TST r1, #1				   ;Check if Bit 0 is 1
			BNE FIQ_Exit				;If Bit 0 != 1 then Branch to FIQ_Exit
		
			
			LDR r6, =0xE000C000			;Load Recieve Register Address into r6
			LDRB r0, [r6]				;Load Byte from Recieve Register into r0
			BL OC						;Output Character
			CMP r0, #0x51				;Check if charcter entered (r0) is Q (0x51)
			BNE NEXTstep 				;Branch (NEXTstep) if not Q
REPEAT		ADD r0, r0, #0				
			B REPEAT					;Infinite Loop

NEXTstep	CMP r0, #0x5A				;Check if character entered (r0) is Z (0x5A)
			BNE NEXTstep2				;Branch if not Z
			MOV r0, #0					;Move 0 into r0
			BL display_digit			
			MOV r4, #0					 ;Move 0 into r4
			STRB r4, [r3, #1]			 ;Store 0 (r4) into Previous Value
			B FIQ_Exit					 ;Branch (NEXTstep2) to FIQ_Exit 


NEXTstep2	CMP r0, #0x2d				 ;Check if charcter entered(r0) is '-'(0x2d)
			BNE NOTNEG					  ;Branch(NOTNEG) if != '-'(0x2d)
			LDRB r4, [r3]				  ;Load Byte from Negative Global Flag
			ADD r4, r4, #0x1			   ;Increment Negative Global Flag
			STRB r4, [r3]				   ;Store changes back into Negative Global Flag Address
			B FIQ_Exit					   ;Branch to FIQ_Exit
NOTNEG		LDR r3, =global_reg				;Load Global Register(global_reg) inot r3
				
			CMP r0, #0x30					;Check if charcter entered was less than '0'(0x30)
			BLT FIQ_Exit					;Branch (FIQ_Exit) if less than 
			CMP r0, #0x39					;Check if character is '9'(0x39)
			BGT HEX							 ;Branch(HEX) if greater than
			SUB r2, r0, #0x30				 ;Subtract 0x30 from r0, store in r2
			B CONVERT_NEG					 ;Branch(CONVERT_NEG)

HEX            CMP r0, #0x41            ;Compare r0 to A
            BLT FIQ_Exit            ;if its less than A, we just branch to exit
            CMP r0, #0x46            ;Compare r0 to F
            BGT FIQ_Exit            ;if its greater than F, we just branch to exit
            SUB r2, r0, #55            ;if its an A, we subtract 55(decimal 65)

CONVERT_NEG    LDRB r4, [r3]            ;load the base address of the global register into register r4
            CMP r4, #0x0            ;Check if the number was negative
            BEQ END10                ;if it was 0, then we branch to END10
            MVN r2,r2                ;Change the number to negative
            ADD r2, r2, #1            ;Add one to the negative number

END10        BL increment_seven_segment    ;branch to the increment_seven_segment subroutine
            MOV r0, r2                    ;copy value of the number from r2 back to r0
            BL display_digit            ;branch to display_digit subroutine

            MOV r4, #0                    ;copy 0 into register r4
            STRB r4, [r3]                ;store r4(0) into the global register address in r3
    
FIQ_Exit                                ;exit program
        LDMFD SP!, {r0-r12, lr}
        SUBS pc, lr, #4


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