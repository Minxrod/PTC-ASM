@ important addresses, do not modify
.equ expectedEntry, 0x02676fdc
.equ colsetReturn, 0x020354c8

.equ ptcCharSize, 2
.equ ptcNumSize, 4

@ Stuff that isn't PTC specific but is still useful
.equ ioBase, 0x04000000
.equ ioDISPCNT, ioBase
.equ ioDISP3DCNT, ioBase + 0x60
.equ ioPOWCNT1, ioBase + 0x304

@ Background control
.equ ioBG0CNT, ioBase + 0x8
.equ ioBG1CNT, ioBase + 0xa
.equ ioBG2CNT, ioBase + 0xc
.equ ioBG3CNT, ioBase + 0xe

@ A subset of the 3d commands
.equ ioMATRIX_MODE, ioBase + 0x440
.equ ioMATRIX_IDENTITY, ioBase + 0x454
.equ ioMATRIX_LOAD_4x4, ioBase + 0x458
.equ ioMATRIX_MULTIPLY_3x3, ioBase + 0x468
.equ ioMATRIX_SCALE, ioBase + 0x46c
.equ ioMATRIX_TRANS, ioBase + 0x470

.equ ioVERTEX_COLOR, ioBase + 0x480
.equ ioVERTEX_16BIT, ioBase + 0x48c
.equ ioVERTEX_10BIT, ioBase + 0x490

.equ ioVERTEX_BEGIN, ioBase + 0x500
.equ ioVERTEX_END, ioBase + 0x504

.equ ioSWAP_BUFFERS, ioBase + 0x540
.equ ioVIEWPORT, ioBase + 0x580

@
@ Constants used by the interpreter
@

@ Error constants
.equ errSYNTAX_ERROR, 0x1
.equ errOUT_OF_RANGE, 0x2
.equ errOUT_OF_MEMORY, 0x3
.equ errILLEGAL_FUNCTION_CALL, 0x7
.equ errMISSING_OPERAND, 0xa
.equ errTYPE_MISMATCH, 0x12

@
@ Important/useful functions that live in TCM
@ See https://petitcomputer.fandom.com/wiki/User_blog:Minxrod/Some_function_notes
@

@ Input:
@ r0 - mainDU
@ r1 - Top of stack
@ r2 - # args
.equ parseCommandArgs, 0x01ffa160
.equ parseFunctionArgs, 0x01ffa23c
.equ parseFunctionVarargs, 0x01ffbb3c

@ parse*Args stack offsets
.equ stackTypeArg1, 0x0
.equ stackValueArg1, 0x4
.equ stackTypeArg2, 0x8
.equ stackValueArg2, 0xc
.equ stackTypeArg3, 0x10
.equ stackValueArg3, 0x14
.equ stackTypeArg4, 0x18
.equ stackValueArg4, 0x1c
.equ stackTypeArg5, 0x20
.equ stackValueArg5, 0x24

@ Input:
@ r0 - mainDU
.equ parseEvaluate, 0x01ff9a58
@ Input:
@ r0 - mainDU
.equ parseWhitespace, 0x1ff9d90

@ WARNING: not fully understood
@ Input:
@ r0 - mainDU
@ r1 - ptr to 8 bytes space [unknown 2-2-4]
@ r2 - ptr to 4 bytes space [unknown 4]
@ r3 - ptr to 8 bytes space [unknown 4-4]
.equ parseVarName, 0x1ff83e4
@ WARNING: not fully understood
@ Input:
@ r0 - varTblPtr
@ r1 - ptr to same 8 as r1 for parseVarName
@ r2 - 0?
@ r3 - Something that carries over from above? (ptr to 8 bytes?)
@ Output:
@ r0 - varEntryPtr
.equ getVarEntryPtr, 0x01ffbd5c
@ Input:
@ r0 - ArrTblPtr
@ r1 - array index
@ Output:
@ r0 - arrEntryPtr
.equ getArrEntryPtr, 0x0203dc6c
@ Input:
@ r0 - ArrTblPtr
@ r1 - array index
@ Output:
@ r0 - array data ptr
.equ getArrDataPtr, 0x0203dd8c

@
@ Variable table entries and values
@
.equ varEntryTypeOfs, 0x0
.equ varEntryValueOfs, 0x4 @ numbers only
.equ varEntryIndexOfs, 0x4 @ for non-number types


@ Variable types (simple)
.equ varTypeNumber, 0
.equ varTypeString, 1
.equ varTypeArray, 2
@ Variable types (complex)
.equ varSpecificTypeNumber, 0
.equ varSpecificTypeString, 1
.equ varSpecificTypeNumArray, 2
.equ varSpecificTypeStringArray, 3

@
@ Array table entries and values
@
.equ arrEntryTypeOfs, 0x0
.equ arrEntryDimensionOfs, 0x1
.equ arrEntryDimension1SizeOfs, 0x4
.equ arrEntryDimension2SizeOfs, 0x8
.equ arrEntryDataOffsetOfs, 0xc
.equ arrEntrySize, 0x10

@ Array types
.equ arrTypeNumber, 0
.equ arrTypeString, 1

@
@ Various data blocks contained within DUs
@ See https://petitcomputer.fandom.com/wiki/User_blog:Minxrod/More_memory_research
@
.equ DirectDat, 0x0217ff50
.equ MainDU, DirectDat

@ Offsets from DirectDat that contain useful pointers
.equ CurCharOfs, 0x8
.equ NextCharOfs, 0x210
.equ ArgumentStackPtrOfs, 0x214
.equ AlsoProgramDataPtrOfs, 0x21c @ ???
.equ ProgramDataPtrOfs, 0x220
.equ StringTablePtrOfs, 0x224
.equ VariableTablePtrOfs, 0x228
.equ ArrayTablePtrOfs, 0x22c
.equ ConsoleDataPtrOfs, 0x230

@ Instruction table entries

@ Command table entries

@ empty slots (no loss of function when filling)
.equ cmdNull1, 0x02186c98
.equ cmdNull2, 0x02187034
.equ cmdNull3, 0x02187114
.equ cmdNull4, 0x02187130
.equ cmdNull5, 0x0218737c
.equ cmdNull6, 0x0218745c

@ Function table entries
.equ funcTalkchk, 0x0218c1f0
.equ funcBtrig, 0x0218c2d0

@ Variable table entries

@ Console data blocks, contained within the console DU
.equ ConsoleTextBuffer, 0x0274804c
.equ ConsoleTextBufferSize, 32 * 24 * 2
.equ ConsoleTextColorBuffer, 0x0274931c
.equ ConsoleTextBGColorBuffer, 0x02794638

.equ ConsoleTileBuffer, 0x0274999c
.equ ConsoleTileBackBuffer, 0x0274b9f8

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

.macro bptc reg, ptc_expected_addr
	ldr \reg, =\ptc_expected_addr
	blx \reg
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
