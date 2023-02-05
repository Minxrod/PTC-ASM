.org 0x400 
@ this prevents the shifting addresses from breaking stuff maybe
@ (it adds 0x400 zeros to the beginning of the grp)
.include "ptc_memory.s"

@ notes:
@ Addresses in this code should be +0
@ DU addresses should use -expectedEntry+r11

start:
 bl calcOffsetAddress
 @ r11 = offset
 
 @ put code here
 du_addr r0, consoleTextBuffer
 asm_addr r1, helloWorld
 bl copyWideStr
 
 b end

end:
 ldr r0, =0x020354c8
 bx r0

@ copy r1 to r0 (null-terminated)
copyWideStr:
 ldrh r2,[r1]
 strh r2,[r0]
 add r0, #2
 add r1, #2
 cmp r2, #0
 bne copyWideStr
 bx lr

@ returns: r11 -> offset to use for every address
calcOffsetAddress:
 mov r11, pc
 ldr r0, =(calcOffsetAddress + 0x8)
 sub r11, r11, r0
 bx lr

@ input: r4 -> value to print
@ output: r4 hex to console start
r4ToConsole:
 stmdb sp!, {r4, r11, lr}
 bl calcOffsetAddress
 du_addr r0, consoleTextBuffer
@ TODO: read cursorx, cursory?
 mov r2, #8
r4ToConsoleLoop:
 and r1, r4, #0xf
 add r1, r1, #0x30 @ numbers start
 cmp r1, #39
 addgt r1, r1, #0x7
 strb r1, [r0, r2]
 @ to next character
 add r0, r0, #2
 lsr r4, r4, #4
 subs r2, #1
 bne r4ToConsoleLoop
 ldmia sp!, {r4, r11, lr}
 bx lr
 
helloWorld:
wide_str 'H','e','l','l','o',' ','W','o','r','l','d','!'
.2byte 0
