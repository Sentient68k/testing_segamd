; Main program for the ROM.
__main:
	lea	Palette01, a0	; Load address of palettes into a0
	jsr LoadPalette ; Jump to Palette Loading subroutine.

	lea test_tiles_01, a0 ; Get tiles address ready for loading.
	move.l #test_tiles_01VRAM, d0
	move.l #test_tiles_01SizeT, d1
	jsr LoadTiles

	jmp __main

LoadPalette:
    ; a0 - Address of palettes to load.
    move.w #$8F02, vdp_control ; Set VDP address autoincrement to 2 bytes

    ; Move selected pallet to CRAM
    move.l #vdp_write_palettes, vdp_control ; Setup VDP data port to load into CRAM
    move.l #$1F, d0 ; ; 128 bytes of data (4 palettes, 32 longs, -1 for counter)

    @ColorLoop:
    move.l (a0)+, vdp_data ; Move data to VDP Port, increment address
    dbra d0, @ColorLoop

    rts

LoadTiles:
; a0 - Tiles address (l)
; d0 - VRAM address	(w)
; d1 - Num chars (w)

	swap	d0	;Shift VRAM addr to upper word
	add.l 	#vdp_write_tiles, d0 	;VRAM write cmd + VRAM dest addr
	move.l 	d0, vdp_control		;Send address to VDP cmd port

	subq.b 	#$1, d1		; Num of chars -1
	@CharCopy:
	move.w 	#$07, d2 	; 8 longwords in tile
	@LongCopy:
	move.l 	(a0)+, vdp_data 	;Copy one line of tile to VDP data port
	dbra 	d2, @LongCopy
	dbra 	d1, @CharCopy

	rts

