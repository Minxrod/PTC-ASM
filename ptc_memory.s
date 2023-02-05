@ various useful addresses
.equ expectedEntry, 0x02676fdc

.equ ptcCharSize, 2
.equ ptcNumSize, 4

.equ consoleTextBuffer, 0x02748048
.equ consoleTextBufferSize, 32 * 24 * 2
.equ consoleTextColorBuffer, 0x0274931c
.equ consoleTextBGColorBuffer, 0x02794638

.equ consoleTileBuffer, 0x0274999c
.equ consoleTileBackBuffer, 0x0274b9f8

@ use this to simplify getting addresses
@ requires r11 already set!
.macro du_addr reg, du_expected_addr
	ldr \reg, =\du_expected_addr-expectedEntry+0x4 @idk why the +4 is so important but it is
	add \reg, \reg, r11
.endm

.macro asm_addr reg, asm_expected_addr
	ldr \reg, =\asm_expected_addr
	add \reg, \reg, r11
.endm

@ recursive macro idea from here
@ https://community.arm.com/arm-community-blogs/b/architectures-and-processors-blog/posts/useful-assembler-directives-and-macros-for-the-gnu-assembler
@ this converts a list of characters to a string, because PTC likes to use wide strings everywhere
@ doesn't work for some characters probably, but
.macro wide_str c:req tx:vararg
	.hword \c - 0x20 + 0xff00
	.ifnb \tx
	wide_str \tx
	.endif
.endm
