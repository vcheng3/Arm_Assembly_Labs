	AREA interrupts, CODE, READWRITE
	EXPORT lab6
	EXPORT FIQ_Handler
	IMPORT pin_connect_block_setup_for_7_segment
	IMPORT OS
	IMPORT RS
	IMPORT display_digit
	IMPORT RC
	IMPORT OC
	IMPORT interrupt_init
	IMPORT String_to_number
	IMPORT number_to_string
	IMPORT div_and_mod
	IMPORT number_to_string2
	IMPORT read_character
	IMPORT output_string

flag_reg
		DCB 0x3	 		;Direction Flag
		DCB 0x0			;counter			  
	ALIGN

movement_reg
		DCD 0x400000ab		;character location
	ALIGN
	
prompt = 0xC,"Walls Encountered: ",0
counter = "000",0xA,0xD,0
game = "|---------------------|",0xA,0xD,"|                     |",0xA,0xD,"|                     |",0xA,0xD,"|                     |",0xA,0xD,"|                     |",0xA,0xD,"|          *          |",0xA,0xD,"|                     |",0xA,0xD,"|                     |",0xA,0xD,"|                     |",0xA,0xD,"|                     |",0xA,0xD,"|                     |",0xA,0xD,"|                     |",0xA,0xD,"|---------------------|",0xA,0xD,0
prompt2 = 0xC,"Press <ENTER> to begin!",0xA,0xD,0
	ALIGN

lab6	 	
		STMFD sp!, {lr}

		BL timer0_enabler
		LDR r4, =prompt2
		BL output_string
NotCR	BL read_character 
		CMP r0, #0xd									;Check if character entered was ENTER (0xd) 
		BNE NotCR										;Branch if not equal 
		BL random_character
		BL change_location
		BL random_direction
		BL interrupt_init
AGAIN	ADD r0, r0, #0								   ;Infinite Loop
		B AGAIN

	
	LDMFD sp!,{lr}
	BX lr
	
timer0_enabler
		STMFD sp!, {r4,r5,lr}
		
		LDR r4, =0xE000401C		;MR1 Address
		LDR r5, =0x8C9FFF		;0.5 seconds
		STR r5, [r4]

		LDR r4, =0xE0004004		;T0TCR Address
		LDR r5, [r4]
		ORR r5, r5, #0x3		;Enable bit 0 and bit 1
		STR r5, [r4]			;Store changes back into T0TCR
		LDR r6, =0x2
		BIC r5, r5, r6			;Set bit 1 to 0
		STR r5, [r4]			;Store changes back into T0TCR
		
		LDR r4, =0xE0004014		;MCR1
		LDR r5, [r4]
		ORR r5, r5, #0x18		;Enable bit 3 and 4
		STR r5, [r4]			;Store changes back into MCR1		
		
		LDMFD sp!,{r4,r5,lr}
		BX lr


FIQ_Handler
        STMFD SP!, {r0-r12, lr}   ; Save registers 

EINT1            				; Check for EINT1 interrupt
        LDR r0, =0xE01FC140            ;Load the external interrupt flag register into r0
        LDR r1, [r0]                ;Load memory r0 into r1
        TST r1, #2                    ;checks to see if pin 2 is 1
        BEQ UART0                    ;equal, branch to the UART0

		BL random_character
		BL change_location

CLEAR   LDR r3, =0xE01FC140            ;Load the external interrupt flag register into r3
        LDR r1, [r3]                ;Load that into r1
        ORR r1, r1, #2                ;Clear Interrupt
        STR r1, [r0]                ;store that back into the external interrupt flag register
        LDR r6, =0xE000C000            ;load the push button address into r6    
        LDRB r0, [r6]                ;load the register byte memory to r0
		
		B FIQ_Exit

UART0   
        LDR r0, =0xE000C008          ;Load U0IIR (0xE000C008) into r0
        LDR r1, [r0]               ;Load memory from U0IIR into r1
        TST r1, #1                   ;Check if Bit 0 is 1
        BNE TIMER0                ;If Bit 0 != 1 then Branch to TIMER0

		LDR r3, =flag_reg         ;Load flag_reg into r3
        LDRB r4, [r3]         ;Load flag reg into r4
        
        LDR r6, =0xE000C000            ;Load Recieve Register Address into r6
        LDRB r0, [r6]                ;Load Byte from Recieve Register into r0

		CMP r0, #0x20                ;Check if the character entered is a 'w'(0x77)
        BEQ ST0P                        ;if key pressed was 'w', branch to label that handles upwards movement
        CMP r0, #0x77                ;Check if the character entered is a 'w'(0x77)
        BEQ UP                        ;if key pressed was 'w', branch to label that handles upwards movement
        CMP r0, #0x61                ;Check if the character entered is a 'a'(0x61)
        BEQ LEFT                    ;If key pressed was a 'a', branch to label that handles leftward movement
        CMP r0, #0x73                ;Check if the character entered is a 's'(0x73)
        BEQ DOWN                    ;if key pressed was a 's', branch to label that handles downward movement
        CMP r0, #0x64                ;Check if the character entered is a 'd'(0x64)
        BEQ RIGHT                    ;if key pressed was a 'd', branch to label that handles rightward movement
		B FIQ_Exit

ST0P	ADD r0, r0, #0
		B ST0P

UP                                    ;code to handle upwards movement
        MOV r4, #0x0                ;change flag_reg number to 0
		STRB r4, [r3] 
        B FIQ_Exit

LEFT                                ;code to handle leftward movement
        MOV r4, #0x1                ;change flag_reg number to 1
		STRB r4, [r3] 
        B FIQ_Exit

DOWN                                ;code to handle downward movement
        MOV r4, #0x2                ;change flag_reg number to 2
		STRB r4, [r3] 
        B FIQ_Exit

RIGHT                                ;code to handle rightward movement
        MOV r4, #0x3                ;change flag_Reg number to 3
		STRB r4, [r3] 
        B FIQ_Exit
		
TIMER0  LDR r0, =0xE0004000
		LDR r1, [r0]			   ;Load memory from T0IR into r1
		TST r1, #2				   ;Check if Bit 1 is 1
		BEQ FIQ_Exit				;If Bit 1 = 1 then Branch to FIQ_Exit
		
		LDR r3, =flag_reg
		LDR r4, =movement_reg		
		LDRB r3, [r3]				;check flag register
		CMP r3, #0x0
		BEQ UP2
		CMP r3, #0x1
		BEQ LEFT2
		CMP r3, #0x2
		BEQ DOWN2
		CMP r3, #0x3
		BEQ RIGHT2

		
RIGHT2	LDR r4, [r4]		  ;Load the memory in the movement_reg
		LDRB r5, [r4,#1]	  ;Load the byte to the right of the character
		CMP r5, #0x20		;Checks if the character to the right is a SPACE
		BNE DIR1			;change right to left
		LDRB r6, [r4]		;Load moving character byte 
		LDR r5, =0x20	  	;Loads SPACE (0x20) into r5
		STRB r5, [r4]		 ;Store SPACE byte into movement_reg
		STRB r6, [r4,#1]!	 ;Store moving character into memory address to the right  
		LDR r5, =movement_reg 	
		STR r4, [r5] 		;Change movement_reg to new character location
		B CLEAR2	

DIR1	LDR r4, =0xE000401C		;MR1 Address
		LDR r0, [r4]		 ;Load MR1 memory into r0
		LSR r0, r0, #1		;Divide r0 by 2
		STR r0, [r4]
		LDR r3, =flag_reg	;load flag register to r3
		LDR r4, =0x1		;load memory of r3 into r4
		STRB r4, [r3]		;store back into flag register
		BL ADDCOUNT			;branch to subroutine that adds 1
	   	B CLEAR2

UP2	  	LDR r4, [r4]		;Load the memory in the movement_reg
		LDRB r5, [r4,#-25]  ;Load the byte to the right of the character
		CMP r5, #0x20		;Checks if the character to the right is a SPACE
		BNE DIR2			;change up to down
		LDRB r6, [r4]		;Load moving character byte 
		LDR r5, =0x20	  	;Loads SPACE (0x20) into r5
		STRB r5, [r4]		 ;Store SPACE byte into movement_reg
		STRB r6, [r4,#-25]!	 ;Store moving character into memory address to the right  
		LDR r5, =movement_reg 	
		STR r4, [r5] 		;Change movement_reg to new character location
		B CLEAR2 


DIR2  	LDR r4, =0xE000401C		;MR1 Address
		LDR r0, [r4]		 ;Load MR1 memory into r0
		LSR r0, r0, #1		;Divide r0 by 2
		STR r0, [r4]
		LDR r3, =flag_reg	;load flag register to r3
		LDR r4, =0x2		;load memory of r3 into r4
		STRB r4, [r3]		;store back into flag register	
		BL ADDCOUNT			;branch to subroutine that adds 1
	   	B CLEAR2
				  
LEFT2   LDR r4, [r4]		  ;Load the memory in the movement_reg
		LDRB r5, [r4,#-1]	  ;Load the byte to the right of the character
		CMP r5, #0x20		;Checks if the character to the right is a SPACE
		BNE DIR3			;change left to right
		LDRB r6, [r4]		;Load moving character byte 
		LDR r5, =0x20	  	;Loads SPACE (0x20) into r5
		STRB r5, [r4]		 ;Store SPACE byte into movement_reg
		STRB r6, [r4,#-1]!	 ;Store moving character into memory address to the right  
		LDR r5, =movement_reg 	
		STR r4, [r5] 		;Change movement_reg to new character location
		B CLEAR2 

DIR3    LDR r4, =0xE000401C		;MR1 Address
		LDR r0, [r4]		 ;Load MR1 memory into r0
		LSR r0, r0, #1		;Divide r0 by 2
		STR r0, [r4]
		LDR r3, =flag_reg	;load flag register to r3
		LDR r4, =0x3		;load memory of r3 into r4
		STRB r4, [r3]		;store back into flag register
		BL ADDCOUNT			;branch to subroutine that adds 1
	   	B CLEAR2

DOWN2	LDR r4, [r4]		  ;Load the memory in the movement_reg
		LDRB r5, [r4,#25]	  ;Load the byte to the right of the character
		CMP r5, #0x20		;Checks if the character to the right is a SPACE
		BNE DIR4			;change down to up
		LDRB r6, [r4]		;Load moving character byte 
		LDR r5, =0x20	  	;Loads SPACE (0x20) into r5
		STRB r5, [r4]		 ;Store SPACE byte into movement_reg
		STRB r6, [r4,#25]!	 ;Store moving character into memory address to the right  
		LDR r5, =movement_reg 	
		STR r4, [r5] 		;Change movement_reg to new character location
		B CLEAR2 

DIR4    LDR r4, =0xE000401C		;MR1 Address
		LDR r0, [r4]		 ;Load MR1 memory into r0
		LSR r0, r0, #1		;Divide r0 by 2
		STR r0, [r4]
		LDR r3, =flag_reg	;load flag register to r3
		LDR r4, =0x0		;load memory of r3 into r4
		STRB r4, [r3]		;store back into flag register
		BL ADDCOUNT			;branch to subroutine that adds 1
	   	B CLEAR2


CLEAR2  LDR r4, =prompt
		BL OS
		LDR r4, =counter
		BL OS
		LDR r4, =game
		BL OS
		LDR r3, =0xE0004000            ;Load the T0IR register into r3
        LDR r1, [r3]                ;Load that into r1
        ORR r1, r1, #2                ;Clear Interrupt
        STR r1, [r3]                ;store that back into the T0IR register    
FIQ_Exit                                ;exit program
        LDMFD SP!, {r0-r12, lr}
        SUBS pc, lr, #4

change_location
		STMFD sp!, {r0-r7,lr}
		LDR r3, =0xE0004008			;Load T0TC register address into r3
		LDR r3, [r3]				;Load T0TC memory into r3
LOOP15	LSR r3, r3, #2				;Divide the cycle count from T0TC by 4 until it's below 300
		MOV r4, #300				;300 is about the size of the game board
		CMP r3, r4
		BGT LOOP15					;Loop if greater than 300
		LDR r5, =movement_reg
		LDR r5, [r5]				;Load character location from movement_reg into r5
		LDR r6, =0x20				;Load 0x20 (SPACE) into r6
		LDRB r7, [r5]				;Load byte from character location
		STRB r6, [r5]				;Store byte 0x20 (SPACE) in character location
		LDR r4, =game				;Load game into r4
		ADD r4, r4, r3			  	;Offset game by the number in r3
LOOP16	LDRB r3, [r4], #1			;Load byte from game and increment address
		CMP r3, r6					
		BNE LOOP16					;Check if byte from game is a SPACE (0x20) or not. Branch if not equal.
		SUB r4, r4, #1				;Subtract 1 from the address so its back to the address that had the SPACE character
		STRB r7,[r4]				;Store the random character in the new memory location in r4
		LDR r5, =movement_reg
		STR r4, [r5]				 ;Store new memory location in movement_reg
		LDMFD sp!, {r0-r7,lr}
		BX lr

random_direction
		STMFD sp!, {r0-r7,lr}
		LDR r4, =flag_reg		 	 ;Load flag_reg address into r4
		LDR r3, =0xE0004008			 ;Load T0TC register address into r3
		LDR r3, [r3]			  	 ;Load T0TC memory into r3
LOOP18	LSR r3, r3, #2				 ;Divide the cycle count from T0TC by 4 until it's less than or equal to 12
		CMP r3, #12
		BGE LOOP18
		CMP r3, #9					 ;Branch to END1 if Greater than 9
		BGT END5
		CMP r3, #6					 ;Branch to END2 if Greater than 6
		BGT END6
		CMP r3, #3					 ;Branch to END3 if Greater than 3
		BGT END7
		CMP r3, #0					 ;Branch to END1 if Greater or Equal to 0
		BGE END8					 

END5	MOV r3, #0x3				 ;If between 12 and 10 then the charcter will become '*'
		STRB r3, [r4]
		B Final2

END6	MOV r3, #0x2				 ;If between 9 and 7 then the charcter will become '@'
		STRB r3, [r4]
		B Final2

END7	MOV r3, #0x1				 ;If between 6 and 4 then the charcter will become '+'
		STRB r3, [r4]
		B Final2

END8	MOV r3, #0x0				 ;If  between 3 and 0 then the charcter will become 'X'
		STRB r3, [r4]
		B Final2

Final2  LDMFD sp!, {r0-r7,lr}
		BX lr

random_character
		STMFD sp!, {r0-r7,lr}
		LDR r4, =movement_reg		 ;Load movement_reg address into r4
		LDR r4, [r4]				 ;Load memory from movement_reg into r4
		LDR r3, =0xE0004008			 ;Load T0TC register address into r3
		LDR r3, [r3]			  	 ;Load T0TC memory into r3
LOOP17	LSR r3, r3, #2				 ;Divide the cycle count from T0TC by 4 until it's less than or equal to 12
		CMP r3, #12
		BGE LOOP17
		CMP r3, #9					 ;Branch to END1 if Greater than 9
		BGT END1
		CMP r3, #6					 ;Branch to END2 if Greater than 6
		BGT END2
		CMP r3, #3					 ;Branch to END3 if Greater than 3
		BGT END3
		CMP r3, #0					 ;Branch to END1 if Greater or Equal to 0
		BGE END4					 

END1	MOV r3, #0x2a				 ;If between 12 and 10 then the charcter will become '*'
		STRB r3, [r4]
		B Final

END2	MOV r3, #0x40				 ;If between 9 and 7 then the charcter will become '@'
		STRB r3, [r4]
		B Final

END3	MOV r3, #0x2b				 ;If between 6 and 4 then the charcter will become '+'
		STRB r3, [r4]
		B Final

END4	MOV r3, #0x58				 ;If  between 3 and 0 then the charcter will become 'X'
		STRB r3, [r4]
		B Final

Final  LDMFD sp!, {r0-r7,lr}
		BX lr


ADDCOUNT
		STMFD sp!, {r3,r4,lr}

		LDR r4, =counter 		;load the counter into register r3
		LDR r3, =flag_reg
		LDRB r2, [r3,#1]! 
		ADD r2, r2, #1			;add 1 to the counter
		STRB r2, [r3]			;store that change back into memory
		BL number_to_string2	;change that number back into a string
		
		LDMFD sp!,{r3,r4,lr}
		BX lr
			
	END