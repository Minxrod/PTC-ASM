@ this prevents the shifting addresses from breaking stuff maybe
@ (it adds 0x400 zeros to the beginning of the grp)
.org 0x400 

.include "ptc_memory.s"

start:
 bl calcOffsetAddress
 @ r11 = offset
 
 @ RENDER command
 du_addr r0, cmdNull6
 asm_addr r1, renderString
 asm_addr r2, renderPTC
 bl replaceFunctionFormat
 
 @ RMTX commnd
 du_addr r0, cmdNull5
 asm_addr r1, rmtxString
 asm_addr r2, rmtxPTC
 bl replaceFunctionFormat
 
 @ RPOLY command
 du_addr r0, cmdNull4
 asm_addr r1, rpolyString
 asm_addr r2, rpolyPTC
 bl replaceFunctionFormat
 
 @ RCOLOR command
 du_addr r0, cmdNull3
 asm_addr r1, rcolorString
 asm_addr r2, rcolorPTC
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
 @ r0 points to table entry's function pointer already after copying 8 chars
 str r4, [r0]
 ldmia sp!,{r4, r5, r6, pc}

@ PTC format:
@ `RENDER setting`
@
@ Enables and controls the 3d rendering.
@ setting = 0: Disable 3D, restore console background/console
@ setting = 1: Enable 3D, set up for rendering, call ioSWAP_BUFFERS
@ 
@ Internal format:
@ in: r0 points to DirectDat
@ out: r0 is error code, or 0 if successful
renderPTC:
 stmdb sp!,{r4, r11, lr}
 sub sp, sp, #8
 mov r1, sp
 mov r2, #1 @ RENDER expects one argument
 bptc r4, parseCommandArgs
 @ exit early if parser error
 cmp r0, #0
 bne renderPTCEnd
 
 ldr r0, [sp, #0x4] @ first arg
 cmp r0, #0
 bne renderEnable
renderDisable:
 @ Disable rendering; restore console to normal state, etc.
 ldr r0, =ioBG0CNT
 ldr r1, =0xc008 @ restore as console
 strh r1, [r0]
 ldr r0, =ioBG1CNT
 ldr r1, =0xc413 @ restore as console background
 strh r1, [r0]
 
 @ turn off 3d hw, mode, etc.
 ldr r0, =ioDISPCNT
 ldr r1, [r0]
 bic r1, r1, #0x8 @ mask to disable 3D mode
 str r1, [r0]
 
 ldr r0, =ioPOWCNT1
 ldr r1, [r0]
 bic r1, r1, #0xc @ turn off 3d hardware
 str r1, [r0]
 
 b renderOK
renderEnable:
 @ TODO; Label these magic values please? Until then refer to GBATEK
 ldr r1, =0xc00b
 ldr r0, =ioBG0CNT
 ldr r2, [r0]
 @ If 3D has been set up already, we can skip to the buffer swap.
 cmp r2, r1
 beq renderOK
 
 ldr r0, =ioBG0CNT @ normally the console, now this is the 3d layer
 ldr r1, =0xc00b @ lower the priority so that console can render on top
 strh r1, [r0]
 ldr r0, =ioBG1CNT @ normally the console background
 ldr r1, =0xc008 @ replace this with console (points to console vram + chr)
 strh r1, [r0]
 
 @ turn on 3d hw, mode, etc.
 ldr r0, =ioDISPCNT
 ldr r1, [r0]
 orr r1, r1, #0x8 @ mask to enable 3D mode
 str r1, [r0]
 
 ldr r0, =ioPOWCNT1
 ldr r1, [r0]
 orr r1, r1, #0xc @ power 3d hardware
 str r1, [r0]
 
 @ set viewport
 ldr r0, =ioVIEWPORT
 ldr r1, =0xbfff0000
 str r1, [r0]
 
 @ swap buffer (required to init the 3d engine, and to update the screen)
renderOK:
 mov r0, #0
 ldr r1, =ioSWAP_BUFFERS
 str r0, [r1]
 
 bl copyConsoleBuffer
 mov r0, #0

renderPTCEnd:
 add sp, sp, #8
 ldmia sp!,{r4, r11, pc}

@ PTC format:
@ `RMTX type,form,x,y,z`
@
@ Sets various types of matrices.
@ -type: 0-3 (matrix mode)
@ -form: 0-proj 1-iden 2-scale 3-trans 4-rotate
@ -x,y,z: usage varies by format
@ 
@ Note on form: 
@  proj and iden set mtx;
@  scale, trans, and rotate multiply by current mtx
@ 
@ proj: x=cotangent(FOV in radians) y=(n+f)/(n-f) z=(2nf)/(n-f)
@  Used to create the following projection matrix, based on GBATEK's example
@   [	.75x	0	0	0	]
@   [	0		x	0	0	]
@   [	0		0	y	-1	]
@   [	0		0	z	0	]
@  Why is it like this? Because I didn't want to do any division in asm, so it
@  is outsourced to the interpreter. Requires symmmetry of lr, tb.
@ 
@ iden: (arguments ignored)
@  Sets the identity matrix. 
@ 
@ scale: x,y,z scale corresponding axis
@ 
@ trans: x,y,z translation by x,y,z
@
@ rotate: x=dir y=cos x=sin
@  dir controls what of 0=x,1=y,2=z to rotate around
@  Similar reason as proj: I didn't want to create the tables for sin, cos, etc.
.equ mtxFirstMode, 4
rmtxPTC:
 stmdb sp!,{r4, r5, r6, r7, r8, r11, lr}
 sub sp, sp, #40 @ 5 arguments always
 mov r1, sp
 mov r2, #5 @ RMTX expects five arguments
 bptc r4, parseCommandArgs
 @ exit early if parser error
 cmp r0, #0
 bne renderPTCEnd
 
 ldr r4, [sp, #0x4] @ type
 ldr r5, [sp, #0xc] @ form
 ldr r6, [sp, #0x14] @ x
 ldr r7, [sp, #0x1c] @ y
 ldr r8, [sp, #0x24] @ z
 
 @ check type for validity
 lsr r4, r4, #12 @ 20.12 -> int
 cmp r4, #3
 bhi rmtxOutOfRange
 
 @ check form for validity
 lsr r5, r5, #12 @ 20.12 -> int
 cmp r5, #4
 bhi rmtxOutOfRange
 
 @ set matrix mode
 bl calcOffsetAddress
 asm_addr r10, mtxModePrevious
 ldrb r0, [r10]
 cmp r0, #mtxFirstMode
 beq setMtxMode
 cmp r0, r4
 beq sameMtxMode
 @ this skip prevents weird bugs if you try to rotate twice for some reason
setMtxMode:
 asm_addr r0, mtxModePrevious
 strb r4, [r0]
 ldr r0, =ioMATRIX_MODE
 str r4, [r0]
sameMtxMode:
 
 @ jump to matrix generation section based on matrix form
 @ this is a stupid way of doing this but it's because the addresses are all wrong
 mov r0, #0  @ successful (no error) return value
 cmp r5, #0
 beq rmtxCreateProjMtx
 cmp r5, #1
 beq rmtxCreateIdentityMtx
 cmp r5, #2
 beq rmtxMultiplyByScaleMtx
 cmp r5, #3
 beq rmtxMultiplyByTranslationMtx
 cmp r5, #4
 beq rmtxMultiplyByRotationMtx
 
rmtxOutOfRange:
 mov r0, #errOUT_OF_RANGE
 
rmtxPTCEnd:
 add sp, sp, #40
 ldmia sp!,{r4, r5, r6, r7, r8, r11, pc}

rmtxCreateProjMtx:
 ldr r4, =ioMATRIX_LOAD_4x4
 asr r1, r6, #1 @x/2
 asr r3, r6, #2 @x/4
 add r1, r1, r3 @3x/4
 ldr r2, =0xfffff000 @-1 20.12
 
 str r1, [r4] @3x/4
 str r0, [r4]
 str r0, [r4]
 str r0, [r4]

 str r0, [r4]
 str r6, [r4] @x
 str r0, [r4]
 str r0, [r4]

 str r0, [r4]
 str r0, [r4]
 str r7, [r4] @y
 str r2, [r4] @-1
 
 str r0, [r4]
 str r0, [r4]
 str r8, [r4]
 str r0, [r4]
 b rmtxPTCEnd
 
@ this one is pretty simple
rmtxCreateIdentityMtx:
 ldr r4,=ioMATRIX_IDENTITY
 str r0, [r4]
 b rmtxPTCEnd
 
rmtxMultiplyByScaleMtx:
 ldr r4,=ioMATRIX_SCALE
rmtxShared3Value:
 str r6, [r4]
 str r7, [r4]
 str r8, [r4]
 b rmtxPTCEnd

rmtxMultiplyByTranslationMtx:
 ldr r4,=ioMATRIX_TRANS
 b rmtxShared3Value
 
rmtxMultiplyByRotationMtx:
 ldr r4,=ioMATRIX_MULTIPLY_3x3
 mov r1, #0x1000
 neg r2, r8 @ this is -sin now
 
 @ input at this point
 @ r0 - #  - 0
 @ r1 - fp - 1
 @ r2 - fp - -sin
 @ r4 - &p - io port to write
 @ r6 - fp - direction of rotation (fp)
 @ r7 - fp - cos (fp)
 @ r8 - fp - sin (fp)

 asr r6, r6, #12 @convert fp to in
 
 cmp r6, #0
 beq rmtxRotateX
 cmp r6, #1
 beq rmtxRotateY
 cmp r6, #2
 beq rmtxRotateZ
 
 mov r0, #errILLEGAL_FUNCTION_CALL
 b rmtxPTCEnd

rmtxRotateX:
 str r1, [r4] @1
 str r0, [r4] 
 str r0, [r4] 

 str r0, [r4] 
 str r7, [r4] @cos
 str r8, [r4] @sin

 str r0, [r4] 
 str r2, [r4] @-sin
 str r7, [r4] @cos
 b rmtxPTCEnd

rmtxRotateY:
 str r7, [r4] @cos
 str r0, [r4] 
 str r8, [r4] @sin

 str r0, [r4] 
 str r1, [r4] @1
 str r0, [r4] 

 str r2, [r4] @-sin
 str r0, [r4] 
 str r7, [r4] @cos
 b rmtxPTCEnd

rmtxRotateZ:
 str r7, [r4] @cos
 str r8, [r4] @sin
 str r0, [r4] 

 str r2, [r4] @-sin
 str r7, [r4] @cos
 str r0, [r4] 

 str r0, [r4] 
 str r0, [r4] 
 str r1, [r4] @1
 b rmtxPTCEnd

@ PTC format:
@ `RPOLY type,# vertices,varray_index`
@ 
@ type - special, tris, quads, tristrip, quadstrip [-1,0-3]
@ varray_index - numerical ID corresponding to array DIM order
@ this is used instead of a name because...
@  1) I don't know how the variable name parsing function works well enough
@     (only two functions, DIM and SORT/RSORT use array as arrays)
@  2) The lack of variable references/reassignment means one command could
@     only render one set of polygons, which is hard to work with
@  3) Faster/simpler (doesn't need to call various parsing functions)
@ The "variable index" is not perfect, it's harder to read, but it works. 
@
@ THe size of the 2nd dimension determines content
@   0 - (vx10) - packed VX10 data
@   1 - (vx10) - packed VX10 data
@   2 - (vx10, vc) - packed VX10 data + colors
rpolyPTC:
 stmdb sp!,{r4, r5, r6, r10, r11, lr}
 sub sp, sp, #0x10
 mov r10, r0
 mov r1, sp
 mov r2, #2
 bptc r4, parseCommandArgs
 cmp r0, #0 @ early exit if parser throws an error
 bne rpolyPTCEnd
 
 ldrb r0, [sp, #stackTypeArg1]
 ldr r1, [sp, #stackValueArg1]
 ldrb r2, [sp, #stackTypeArg2]
 ldr r3, [sp, #stackValueArg2]
 
 cmp r0, #varTypeNumber
 movne r0, #errTYPE_MISMATCH
 bne rpolyPTCEnd
 cmp r2, #varTypeNumber
 movne r0, #errTYPE_MISMATCH
 bne rpolyPTCEnd
 
 asr r6, r1, #12 @ poly type
 lsr r4, r3, #12 @ array id
 
 cmp r6, #-1
 beq rpolySpecialModel
 
 ldr r0, [r10, #ArrayTablePtrOfs]
 mov r1, r4
 bptc r11, getArrEntryPtr
 mov r5, r0 @ save
 
 @ check this is not string array
 ldrb r3, [r0, #arrEntryTypeOfs]
 cmp r3, #0
 movne r0, #errTYPE_MISMATCH
 bne rpolyPTCEnd
 
 @ get the pointer to the array 
 ldr r0, [r10, #ArrayTablePtrOfs]
 mov r1, r4
 bptc r11, getArrDataPtr
 mov r4, r0
 
 @ r4 - arr data ptr
 @ r5 - arr entry ptr [contains size1, size2]
 @ r6 - polygon type
 
 @ todo; Check array size against polygon type
 
 ldr r0, [r5, #arrEntryDimensionOfs]
 cmp r0, #1
 beq rpolyVX10
 
 ldr r0, [r5, #arrEntryDimension2SizeOfs]
 cmp r0, #1
 beq rpolyVX10
 
 mov r0, #errILLEGAL_FUNCTION_CALL
rpolyPTCEnd:
 add sp, sp, #0x10
 ldmia sp!,{r4, r5, r6, r10, r11, pc}

@ 0 - (vx10) - packed VX10 data
@ 1 - (vx10) - packed VX10 data
rpolyVX10:
 ldr r0, =ioVERTEX_BEGIN
 str r6, [r0]
 
 ldr r0, =ioVERTEX_10BIT
 ldr r1, [r5, #arrEntryDimension1SizeOfs]
rpolyVX10Loop:
 ldr r2, [r4]
 add r4, r4, #4
 str r2, [r0]
 
 subs r1, r1, #1
 bne rpolyVX10Loop
 
 ldr r0, =ioVERTEX_END
 str r0, [r0] @ dummy write
 
 mov r0, #0
 b rpolyPTCEnd

@ 2 - (vx10,c) - packed data, vertex color
rpolyVX10Col:
 ldr r0, =ioVERTEX_BEGIN
 str r6, [r0]
 ldr r6, =ioVERTEX_COLOR
 
 ldr r0, =ioVERTEX_10BIT
 ldr r1, [r5, #arrEntryDimension1SizeOfs]
rpolyVX10ColLoop:
 ldr r2, [r4] @ vertex coords
 add r4, r4, #4
 ldr r3, [r4] @ colors
 add r4, r4, #4
 
 str r3, [r6]
 str r2, [r0]
 
 subs r1, r1, #1
 bne rpolyVX10ColLoop
 
 ldr r0, =ioVERTEX_END
 str r0, [r0] @ dummy write
 
 mov r0, #0
 b rpolyPTCEnd

rpolySpecialModel:
 @ r4 - model ID
 bl calcOffsetAddress
 mov r0, r4
 @ probably a more efficient method but I don't want to figure out offsets rn
 cmp r0, #0
 asm_addr r1, cubeModel
 moveq r0, r1
 cmp r0, #1
 asm_addr r1, octahedronModel
 moveq r0, r1
 cmp r0, #2
 asm_addr r1, coneModel
 moveq r0, r1
 cmp r0, #3
 asm_addr r1, icosahedronModel
 moveq r0, r1
 cmp r0, #4
 asm_addr r1, cylinderModel
 moveq r0, r1
 cmp r0, #5
 ldr r1, =torusModel
 asm_addr r1, torusModel
 moveq r0, r1
 
 @ r0 is model ptr
 ldr r6, [r0] @ poly type
 ldr r1, [r0, #4] @ number of vertices
 add r4, r0, #8 @ points to model info
 
 ldr r0, =ioVERTEX_BEGIN
 str r6, [r0]
 
 ldr r0, =ioVERTEX_10BIT
 b rpolyVX10Loop

@ PTC format:
@  RCOLOR vertcolor
@ 
@ vertcolor should be 555 RGB, higher bits ignored. PTC integer.
@ 
rcolorPTC:
 stmdb sp!,{r4, r11, lr}
 sub sp, sp, #8
 mov r1, sp
 mov r2, #1 @ RENDER expects one argument
 bptc r4, parseCommandArgs
 @ exit early if parser error
 cmp r0, #0
 bne rcolorPTCEnd
 
 ldr r0, [sp, #0x4] @ first arg
 lsr r0, r0, #12 @ get integer bit
 ldr r1, =ioVERTEX_COLOR
 str r0, [r1] @ wow incredible
 
 mov r0, #0
rcolorPTCEnd:
 add sp, sp, #0x8
 ldmia sp!,{r4, r11, pc}

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

@ Copies from ConsoleTextBuffer to VRAM (in place of upper BGD layer)
@ This is a hack to make the console usable with 3D stuff
copyConsoleBuffer:
 stmdb sp!, {r11, lr}
 bl calcOffsetAddress
 du_addr r1, ConsoleTileBuffer
 ldr r2, =VRAM_Upper_ConsoleTile
 ldr r3, =ConsoleTextBufferSize
copyConsoleBufferLoop:
 ldrh r0, [r1]
 strh r0, [r2]
 
 add r1, r1, #2
 add r2, r2, #2
 subs r3, r3, #2
 bne copyConsoleBufferLoop
 ldmia sp!, {r11, pc}

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
 
renderString:
wide_str 'R','E','N','D','E','R'
.2byte 0,0

rmtxString:
wide_str 'R','M','T','X'
.2byte 0,0,0,0

rpolyString:
wide_str 'R','P','O','L','Y'
.2byte 0,0,0

rcolorString:
wide_str 'R','C','O','L','O','R'
.2byte 0,0

mtxModePrevious:
.4byte mtxFirstMode

cubeModel:
@ type
.4byte 1
@ number of verts
.4byte 24
@ vertex info
.4byte 0x3c010040, 0x3c0103c0, 0x40103c0, 0x4010040
.4byte 0x40f0040, 0x4010040, 0x40103c0, 0x40f03c0
.4byte 0x40f03c0, 0x40103c0, 0x3c0103c0, 0x3c0f03c0
.4byte 0x3c0f03c0, 0x3c0f0040, 0x40f0040, 0x40f03c0
.4byte 0x3c0f0040, 0x3c010040, 0x4010040, 0x40f0040
.4byte 0x3c0f03c0, 0x3c0103c0, 0x3c010040, 0x3c0f0040

octahedronModel:
@ Type of polygon
.4byte 0
@ Number of vertices
.4byte 24
.4byte 0xf0000, 0x4000000, 0x3c0
.4byte 0x4000000, 0x10000, 0x3c0
.4byte 0xf0000, 0x3c0, 0x3c000000
.4byte 0x10000, 0x3c000000, 0x3c0
.4byte 0xf0000, 0x40, 0x4000000
.4byte 0x10000, 0x4000000, 0x40
.4byte 0xf0000, 0x3c000000, 0x40
.4byte 0x10000, 0x40, 0x3c000000

coneModel:
@ Type of polygon
.4byte 0
@ Number of vertices
.4byte 36
.4byte 0xf0000, 0x3c0f0000, 0x3e0f0037
.4byte 0x3c0f0000, 0x10000, 0x3e0f0037
.4byte 0xf0000, 0x3e0f0037, 0x20f0037
.4byte 0x3e0f0037, 0x10000, 0x20f0037
.4byte 0xf0000, 0x20f0037, 0x40f0000
.4byte 0x20f0037, 0x10000, 0x40f0000
.4byte 0xf0000, 0x40f0000, 0x20f03c9
.4byte 0x40f0000, 0x10000, 0x20f03c9
.4byte 0xf0000, 0x20f03c9, 0x3e0f03c9
.4byte 0x20f03c9, 0x10000, 0x3e0f03c9
.4byte 0xf0000, 0x3e0f03c9, 0x3c0f0000
.4byte 0x3e0f03c9, 0x10000, 0x3c0f0000

icosahedronModel:
@ Type of polygon
.4byte 0
@ Number of vertices
.4byte 60
.4byte 0xf0000, 0x22f8c2e, 0x36f8fee
.4byte 0x22f8c2e, 0xf0000, 0x3def8c2e
.4byte 0xf0000, 0x36f8fee, 0xf8fc7
.4byte 0xf0000, 0xf8fc7, 0x3caf8fee
.4byte 0xf0000, 0x3caf8fee, 0x3def8c2e
.4byte 0x22f8c2e, 0x3def8c2e, 0x7439
.4byte 0x36f8fee, 0x22f8c2e, 0x3607412
.4byte 0xf8fc7, 0x36f8fee, 0x22077d2
.4byte 0x3caf8fee, 0xf8fc7, 0x3de077d2
.4byte 0x3def8c2e, 0x3caf8fee, 0x3ca07412
.4byte 0x22f8c2e, 0x7439, 0x3607412
.4byte 0x36f8fee, 0x3607412, 0x22077d2
.4byte 0xf8fc7, 0x22077d2, 0x3de077d2
.4byte 0x3caf8fee, 0x3de077d2, 0x3ca07412
.4byte 0x3def8c2e, 0x3ca07412, 0x7439
.4byte 0x3607412, 0x7439, 0x10000
.4byte 0x22077d2, 0x3607412, 0x10000
.4byte 0x3de077d2, 0x22077d2, 0x10000
.4byte 0x3ca07412, 0x3de077d2, 0x10000
.4byte 0x7439, 0x3ca07412, 0x10000

cylinderModel:
@ Type of polygon
.4byte 0
@ Number of vertices
.4byte 72
.4byte 0xf0000, 0x3c0f0000, 0x3e0f0037
.4byte 0x10000, 0x3e010037, 0x3c010000
.4byte 0x3c010000, 0x3e0f0037, 0x3c0f0000
.4byte 0xf0000, 0x3e0f0037, 0x20f0037
.4byte 0x10000, 0x2010037, 0x3e010037
.4byte 0x3e010037, 0x20f0037, 0x3e0f0037
.4byte 0xf0000, 0x20f0037, 0x40f0000
.4byte 0x10000, 0x4010000, 0x2010037
.4byte 0x2010037, 0x40f0000, 0x20f0037
.4byte 0xf0000, 0x40f0000, 0x20f03c9
.4byte 0x10000, 0x20103c9, 0x4010000
.4byte 0x4010000, 0x20f03c9, 0x40f0000
.4byte 0xf0000, 0x20f03c9, 0x3e0f03c9
.4byte 0x10000, 0x3e0103c9, 0x20103c9
.4byte 0x20103c9, 0x3e0f03c9, 0x20f03c9
.4byte 0xf0000, 0x3e0f03c9, 0x3c0f0000
.4byte 0x10000, 0x3c010000, 0x3e0103c9
.4byte 0x3e0103c9, 0x3c0f0000, 0x3e0f03c9
.4byte 0x3c010000, 0x3e010037, 0x3e0f0037
.4byte 0x3e010037, 0x2010037, 0x20f0037
.4byte 0x2010037, 0x4010000, 0x40f0000
.4byte 0x4010000, 0x20103c9, 0x20f03c9
.4byte 0x20103c9, 0x3e0103c9, 0x3e0f03c9
.4byte 0x3e0103c9, 0x3c010000, 0x3c0f0000

torusModel:
@ Type of polygon
.4byte 1
@ Number of vertices
.4byte 96
.4byte 0x50, 0x3bb00028, 0x3c904020, 0x4040
.4byte 0x4040, 0x3c904020, 0x3d600018, 0x30
.4byte 0x30, 0x3d600018, 0x3c9fc020, 0xfc040
.4byte 0xfc040, 0x3c9fc020, 0x3bb00028, 0x50
.4byte 0x3bb00028, 0x3bb003d8, 0x3c9043e0, 0x3c904020
.4byte 0x3c904020, 0x3c9043e0, 0x3d6003e8, 0x3d600018
.4byte 0x3d600018, 0x3d6003e8, 0x3c9fc3e0, 0x3c9fc020
.4byte 0x3c9fc020, 0x3c9fc3e0, 0x3bb003d8, 0x3bb00028
.4byte 0x3bb003d8, 0x3b0, 0x43c0, 0x3c9043e0
.4byte 0x3c9043e0, 0x43c0, 0x3d0, 0x3d6003e8
.4byte 0x3d6003e8, 0x3d0, 0xfc3c0, 0x3c9fc3e0
.4byte 0x3c9fc3e0, 0xfc3c0, 0x3b0, 0x3bb003d8
.4byte 0x3b0, 0x45003d8, 0x37043e0, 0x43c0
.4byte 0x43c0, 0x37043e0, 0x2a003e8, 0x3d0
.4byte 0x3d0, 0x2a003e8, 0x37fc3e0, 0xfc3c0
.4byte 0xfc3c0, 0x37fc3e0, 0x45003d8, 0x3b0
.4byte 0x45003d8, 0x4500028, 0x3704020, 0x37043e0
.4byte 0x37043e0, 0x3704020, 0x2a00018, 0x2a003e8
.4byte 0x2a003e8, 0x2a00018, 0x37fc020, 0x37fc3e0
.4byte 0x37fc3e0, 0x37fc020, 0x4500028, 0x45003d8
.4byte 0x4500028, 0x50, 0x4040, 0x3704020
.4byte 0x3704020, 0x4040, 0x30, 0x2a00018
.4byte 0x2a00018, 0x30, 0xfc040, 0x37fc020
.4byte 0x37fc020, 0xfc040, 0x50, 0x4500028

