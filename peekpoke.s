.org 0x400 
@ this prevents the shifting addresses from breaking stuff maybe
@ (it adds 0x400 zeros to the beginning of the grp)
.include "ptc_memory.s"

@ notes:
@ Addresses in this code should be +0
@ DU addresses should use -expectedEntry+r11
.equ cmdToReplace, 0x02186c98
.equ funcToReplace, 0x0218c1f0
@ cmd replaced is an empty slot (no loss of function)
@ func replaced is TALKCHK, which is useless in the version this exploit works for

start:
 bl calcOffsetAddress
 @ r11 = offset
 
 @ insert POKE code
 du_addr r0, cmdToReplace
 asm_addr r1, pokeString
 asm_addr r2, pokePTC
 bl replaceFunctionFormat
 
 @ insert PEEK code
 du_addr r0, funcToReplace
 asm_addr r1, peekString
 asm_addr r2, peekPTC
 bl replaceFunctionFormat
 
 b end

end:
 ldr r0, =colsetReturn
 bx r0

@ Input: 
@ r0 - Instruction table entry pointer
@ r1 - Pointer to function name string
@ r2 - Pointer to function to add
replaceFunctionFormat:
 stmdb sp!,{r4, r5, r6, lr}
 mov r4, r2 @ save actual function ptr
 mov r2, #8
 bl copyWideStrN
 @ r0 points to the table entry's function pointer slot already after copying 8 chars
 str r4, [r0]
 ldmia sp!,{r4, r5, r6, pc}

@ PTC format:
@ `POKE addr, value`
@ Writes the value contained in "value" to the given address.
@ 
@ Internal format:
@ in: r0 points to DirectDat
@ out: r0 is error code, or 0 if successful
pokePTC:
 stmdb sp!,{r4, lr}
 sub sp, sp, #16
 mov r1, sp
 mov r2, #2 @ POKE expects exactly 2 arguments
 ldr r4, =parseCommandArgs
 blx r4
 cmp r0, #0
 @ early exit if parser throws an error
 bne pokePTCEnd
 
 @ parser OK - extract values of arguments
 ldr r0, [sp, #0x4] @ addr
 ldr r1, [sp, #0xc] @ value
 str r1, [r0]
 
 mov r0, #0
pokePTCEnd:
 add sp, sp, #16
 ldmia sp!,{r4, pc}

@ PTC format:
@ `PEEK(addr)`
@ Reads the value contained at addr.
@ 
@ Internal format:
@ in: r0 points to DirectDat
@ out: r0 is error code, or 0 if successful
peekPTC:
 stmdb sp!,{r4, lr}
 
 sub sp, sp, #8
 mov r1, sp
 mov r2, #1 @ PEEK expects exactly 1 argument
 ldr r4, =parseFunctionArgs
 blx r4
 cmp r0, #0
 @ early exit if parser throws an error
 bne peekPTCEnd

 @ parser OK - extract values of arguments
 ldr r1, [sp, #-0] @ value
 ldr r0, [sp, #-8] @ addr
 str r1, [r0]
 
 mov r0, #0
peekPTCEnd:
 add sp, sp, #8
 ldmia sp!,{r4, pc} 

@ copy r1 to r0 (null-terminated)
@ destroys r2
copyWideStr:
 ldrh r2,[r1]
 strh r2,[r0]
 add r0, #2
 add r1, #2
 cmp r2, #0
 bne copyWideStr
 bx lr

@ copy r2 characters of r1 to r0 
@ destroys r3
@ r0 -> r0 + 2*r2
@ r1 -> r1 + 2*r2
copyWideStrN:
 ldrh r3,[r1]
 strh r3,[r0]
 add r0, #2
 add r1, #2
 subs r2, #1
 bne copyWideStrN
 bx lr

@ returns: r11 -> offset to use for every address
calcOffsetAddress:
 mov r11, pc
 ldr r0, =(calcOffsetAddress + 0x8)
 sub r11, r11, r0
 bx lr
 
pokeString:
wide_str 'P','O','K','E'
.2byte 0,0,0,0

peekString:
wide_str 'P','E','E','K'
.2byte 0,0,0,0

