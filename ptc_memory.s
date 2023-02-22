@ important addresses, do not modify
.equ expectedEntry, 0x02676fdc
.equ colsetReturn, 0x020354c8

.equ ptcCharSize, 2
.equ ptcNumSize, 4

@
@ Important/useful functions that live in TCM
@ See https://petitcomputer.fandom.com/wiki/User_blog:Minxrod/Some_function_notes
@

@ Input:
@ r0 - DirectDat
@ r1 - Top of stack
@ r2 - # args
.equ parseCommandArgs, 0x01ffa160
.equ parseFunctionArgs, 0x01ffa23c
.equ parseFunctionVarargs, 0x01ffbb3c

@
@ Various data blocks contained within DUs
@ See https://petitcomputer.fandom.com/wiki/User_blog:Minxrod/More_memory_research
@
.equ DirectDat, 0x0217ff50

.equ ArgumentStackPtr, DirectDat + 0x214

.equ consoleTextBuffer, 0x02748048
.equ consoleTextBufferSize, 32 * 24 * 2
.equ consoleTextColorBuffer, 0x0274931c
.equ consoleTextBGColorBuffer, 0x02794638

.equ consoleTileBuffer, 0x0274999c
.equ consoleTileBackBuffer, 0x0274b9f8

@
@ Useful VRAM locations
@ See https://petitcomputer.fandom.com/wiki/User_blog:Minxrod/More_memory_research
@
.equ VRAM_Base, 0x06000000
@ Upper screen BG layers + characters
.equ VRAM_BG_Upper_Base, VRAM_Base
.equ VRAM_Upper_ConsoleTile, VRAM_Base + 0x0
.equ VRAM_Upper_ConsoleBackTile, VRAM_Base + 0x2000
.equ VRAM_Upper_BG0Tile, VRAM_Base + 0x4000
.equ VRAM_Upper_BG1Tile, VRAM_Base + 0x6000
.equ ChrBGF0U, VRAM_Base + 0x8000
.equ ChrBGF1U, VRAM_Base + 0xa000
.equ ChrBGF2U, VRAM_Base + 0xc000 @ normally unused
.equ ChrBGF3U, VRAM_Base + 0xe000 @ normally unused
.equ ChrBGD0U, VRAM_Base + 0x10000
.equ ChrBGD1U, VRAM_Base + 0x12000
.equ ChrBGD2U, VRAM_Base + 0x14000 @ normally inaccessible
.equ ChrBGD3U, VRAM_Base + 0x16000 @ normally inaccessible
.equ ChrBGU0U, VRAM_Base + 0x18000
.equ ChrBGU1U, VRAM_Base + 0x1a000
.equ ChrBGU2U, VRAM_Base + 0x1c000
.equ ChrBGU3U, VRAM_Base + 0x1e000
@ Lower screen BG layers + characters
.equ VRAM_BG_Lower_Base, VRAM_Base + 0x200000
.equ VRAM_Lower_ConsoleTile, VRAM_BG_Lower_Base + 0x0
.equ VRAM_Lower_ConsoleBackTile, VRAM_BG_Lower_Base + 0x2000
.equ VRAM_Lower_BG0Tile, VRAM_BG_Lower_Base + 0x4000
.equ VRAM_Lower_BG1Tile, VRAM_BG_Lower_Base + 0x6000
.equ ChrBGF0L, VRAM_BG_Lower_Base + 0x8000
.equ ChrBGF1L, VRAM_BG_Lower_Base + 0xa000
.equ ChrBGF2L, VRAM_BG_Lower_Base + 0xc000 @ normally unused
.equ ChrBGF3L, VRAM_BG_Lower_Base + 0xe000 @ normally unused
.equ ChrBGD0L, VRAM_BG_Lower_Base + 0x10000
.equ ChrBGD1L, VRAM_BG_Lower_Base + 0x12000
.equ ChrBGD2L, VRAM_BG_Lower_Base + 0x14000 @ normally inaccessible
.equ ChrBGD3L, VRAM_BG_Lower_Base + 0x16000 @ normally inaccessible
.equ ChrBGU0L, VRAM_BG_Lower_Base + 0x18000
.equ ChrBGU1L, VRAM_BG_Lower_Base + 0x1a000
.equ ChrBGU2L, VRAM_BG_Lower_Base + 0x1c000
.equ ChrBGU3L, VRAM_BG_Lower_Base + 0x1e000
@ Upper screen OBJ characters
.equ VRAM_OBJ_Upper_Base, VRAM_Base + 0x400000
.equ ChrSPU0, VRAM_OBJ_Upper_Base + 0x0
.equ ChrSPU1, VRAM_OBJ_Upper_Base + 0x2000
.equ ChrSPU2, VRAM_OBJ_Upper_Base + 0x4000
.equ ChrSPU3, VRAM_OBJ_Upper_Base + 0x6000
.equ ChrSPU4, VRAM_OBJ_Upper_Base + 0x8000
.equ ChrSPU5, VRAM_OBJ_Upper_Base + 0xa000
.equ ChrSPU6, VRAM_OBJ_Upper_Base + 0xc000
.equ ChrSPU7, VRAM_OBJ_Upper_Base + 0xe000
.equ ChrSPS0U, VRAM_OBJ_Upper_Base + 0x10000
.equ ChrSPS1U, VRAM_OBJ_Upper_Base + 0x12000
@ Lower screen OBJ characters
.equ VRAM_OBJ_Lower_Base, VRAM_Base + 0x600000
.equ ChrSPD0, VRAM_OBJ_Lower_Base + 0x0
.equ ChrSPD1, VRAM_OBJ_Lower_Base + 0x2000
.equ ChrSPD2, VRAM_OBJ_Lower_Base + 0x4000
.equ ChrSPD3, VRAM_OBJ_Lower_Base + 0x6000
.equ ChrSPK0, VRAM_OBJ_Lower_Base + 0x8000
.equ ChrSPK1, VRAM_OBJ_Lower_Base + 0xa000
.equ ChrSPK2, VRAM_OBJ_Lower_Base + 0xc000
.equ ChrSPK3, VRAM_OBJ_Lower_Base + 0xe000
.equ ChrSPS0L, VRAM_OBJ_Lower_Base + 0x10000
.equ ChrSPS1L, VRAM_OBJ_Lower_Base + 0x12000


@ use this to simplify getting addresses
@ requires r11 already set!
.macro du_addr reg, du_expected_addr
	ldr \reg, =\du_expected_addr-expectedEntry @idk why the +4 is so important but it is
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
