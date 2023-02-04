// .org 0x02676fe4
.global _start
 ldr r0, =testString
 bl printStr
//endless loop to observe results
asmEnd:
 b asmEnd

// Input: r0 points to string
printStr:
 ldr r3, =cursorOfs
// Input: r0 points to current char
// Prints to cursorOfs
printChar:
 ldr r1, [r3]
 add r1, #0x06000000      // offset to console
 ldrb r2, [r0]
 strb r2, [r1]
 ldr r1, [r3]
 add r1, r1, #2               // ++x
 str r1, [r3]
 add r0, #1 
// continue if not null 
 ldrb r2, [r0]
 cmp r2, #0
 bne printChar
 ldr r1, [r3]
 add r1, r1, #64              //++y kinda
 and r1, r1, #0x0fc0
 str r1, [r3]
 bx lr

cursorOfs: 
 .word 0
testString: 
 .asciz "Hello World" @ will naturally be null terminated
