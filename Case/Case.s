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

			ldr x11, [x1, #8]	// Gets the second argument passed to the program. First 8 bytes are the program name, second 8 bytes are the first argument
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
			adrp	X1, mesg_code@PAGE
			add	X1, X1, mesg_code@PAGEOFF
			
			// Calculate length of mesg (store it in x9)
			mov x9, #0
cloop:
			ldrb w13, [x1,x9]				// get the next byte in mesg
			cmp  w13, #255					// is it 255?
			b.eq  cend						
			add x9, x9, #1					// count++
			b cloop							
cend:
			mov	X0, #1	    				// 1 = StdOut
			mov	X2, X9	    				// length of our string
			mov	X16, #4	    				// 4 = write syscall 
			svc	#0x80 	    				// Call system call

endit:
			mov		W0, W12					// W0 stores exit code
    		mov     X16, #1     			// 1 = exit syscall
    		svc     #0x80           		// Call system call

.data
mesg_code:	// Message in data memory section
		.byte 0x1B
		.byte 'c'
		.byte 0
		.asciz	"Emulate switch/case in assembly code\n\n"
		.asciz	"Use: echo $? to see result of program\n"
		.byte	255
