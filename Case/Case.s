//
// Create assembly code to emulate a switch/case statement
//
// x: 64bits register
// w: 32bits register
//
// REGISTERS USED IN CODE
// w11 	- 	holds switch variable (1 thru 3 for this case statement)
// w12 	-	holds the exit value that can be queried at the OS level with: echo $?
//			NOTE:  w12 is transferred to w0 just before program exit so the
//				   user can query the value with $?
// w13 	-	work register used during calculation of mesg length
//
// X0	-	holds FD (file device) for output (stdout in this case)
// X1	-	holds address of mesg
// X2 	-	holds length of mesg 
//
// X16	-	used to hold Darwin/Kernel system call ID
// X9	-	holds calculated length of mesg

.global _start // Provide program starting address
.align 4

.text
_start:
			mov w12, #255 // Prepare for error case 
			cmp x0, #2	  // x0: quantity of arguments passed to program, cmp: compare
			bne endit	  // Neander: jnz (jump not zero)

			ldr x11, [x1, #8]	// Get a pointer to the second argument passed to the program. First 8 bytes are the program name, second 8 bytes are the first argument
			ldrb w11, [x11]	    // Load the Byte pointed to by that pointer into w11
			sub w11, w11, #'0'  // Subtract the ascii value for '0'

			cmp w11, #1         // Z = 1 if w11 == 1
			b.eq select1        // jz
			cmp w11, #2         
			b.eq select2
			cmp w11, #3         
			b.eq select3
			
			mov w12, #99
			b break							

select1:	mov w12, #1
			b break							
			
select2:	mov w12, #4
			b break							

select3:	mov w12, #9
			b break
		
break:
			// Code for microcrontroller:
			// LDR X2, =mesg_code        // Load the address of 'mesg_code' from the data section
			// LDR X1, [X2]              // Load the actual value from the data section into register X1

			// Move the message into data memory area before manipulating
			ADRP	X1, mesg_code@PAGE
			ADD	X1, X1, mesg_code@PAGEOFF
			
			// Calculate length of mesg (store it in x9)
			mov x9, #0						// x9 = 0
cloop:
			ldrb w13, [x1,x9]				// get the next byte in mesg
			cmp  w13, #255					// is it equal to 255 (0xFF)?
			b.eq  cend						// yes - jump to cend
			add x9, x9, #1					// no  - increase x9 count by 1
			b cloop							// do it again
cend:	
											// Setup the parameters to print string
											// and then call Darwin/kernel to do it.
			MOV	X0, #1	    				// 1 = StdOut
			MOV	X2, X9	    				// length of our string
			MOV	X16, #4	    				// Darwin write system call
			SVC	#0x80 	    				// Call Darwin/kernel to output the string

endit:
			mov		W0, W12					// move return code into W0 so it can be
											// queried at OS level
    		MOV     X16, #1     			// System call number 1 terminates this program
    		SVC     #0x80           		// Call Darwin/kernel to terminate the program

.data
mesg_code:	// Message in data memory section
		.byte 0x1B
		.byte 'c'
		.byte 0
		.asciz	"Emulate switch/case in assembly code\n\n"
		.asciz	"Use: echo $? to see result of program\n"
		.byte	255
