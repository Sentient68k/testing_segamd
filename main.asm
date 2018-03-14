	nop 0,8
; Main program for the ROM.
__main:
	
	;Load Plalettes
	lea	palette_test_segamd, a0	; Load address of palettes into a0
	jsr LoadPalette ; Jump to Palette Loading subroutine.

	;Load Font
	lea PixelFont, a0 ; Load font's first tile address to a0
	move.l #PixelFontVRAM, d0 ; Set first VRAM block number
	move.l #PixelFontSizeT, d1
	jsr LoadTiles

	;Load Tiles
	lea tiles_test_segamd, a0 ; Get tiles address ready for loading.
	move.l #0x0640, d0
	move.l #tiles_test_segamd_size_t, d1
	jsr LoadTiles

	;Load Tile Mapping
	lea map_test_segamd, a0 ; Get tiles address ready for loading.
	move.w #map_test_segamd_size_w, d0 ; d0 (b) - Size in words
	move.w #0x00, d1 ; d1 (b) - Y offset
	move.w #0x0032, d2 ; d2 (w) - First tile ID
	move.l #0x0, d3 ; d3 (b) - Palette ID
	jsr LoadMapPlaneA

	;Write String1 to Plane A
	lea TestString, a0 ; Put address of string in a0
	move.w #PixelFontTileID, d0 ; Put Block ID of font start in d0
	move.w #0x0000, d1 ; First letter position in tiles.
	move.l #0x0, d2 ; Pallete to use.
	jsr DrawTextPlaneA

	@Loop:
	nop
	jmp @Loop

	jmp __main

;======================Subroutines======================

LoadPalette:
	;
    ; a0 - Address of palettes to load.
    ;
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

LoadMapPlaneA:
 ; a0 (l) - Map address (ROM)
 ; d0 (b) - Size in words
 ; d1 (b) - Y offset
 ; d2 (w) - First tile ID
 ; d3 (b) - Palette ID
	mulu.w  #0x0040, d1            ; Multiply Y offset by line width (in words)
	swap    d1                     ; Shift to upper word
	add.l   #vdp_write_plane_a, d1 ; Add PlaneA write cmd + address
	move.l  d1, vdp_control        ; Move dest address to VDP control port
 
	rol.l   #0x08, d3              ; Shift palette ID to bits 14-15
	rol.l   #0x05, d3              ; Can only rol 8 bits at a time
 
	subq.b  #0x01, d0              ; Num words in d0, minus 1 for counter
 
	@Copy:
	move.w  (a0)+, d4              ; Move tile ID from map data to lower d4
	and.l   #%0011111111111111, d4 ; Mask out original palette ID.
	or.l    d3, d4                 ; Replace with our own
	add.w   d2, d4                 ; Add first tile offset to d4
	move.w  d4, vdp_data           ; Move to VRAM
	dbra    d0, @Copy              ; Loop
 
	rts

DrawTextPlaneA:
; a0 (l) - String Address
; d0 (w) - First tile ID of font
; d1 (bb) - XY coord (in tiles)
; d2 (b) - Palette
	clr.l 	d3		; Clear d3 ready to work with
	move.b 	d1, d3 	; Move Y pos (lower bytes of d1) to d3
	mulu.w 	#$0040, d3	; Multiply Y by line width (H40 mode, 64 lines horizontal) to get Y offset
	ror.l 	#$8, d1	; Shift X pos from upper to lower byte of d1
	add.b 	d1, d3	; Add X pos to offset
	mulu.w 	#$2, d3 ; Convert to words
	swap 	d3 		; Shift address to offset to upper word
	add.l 	#vdp_write_plane_a, d3 	; Add PlaneA write cmd + address
	move.l 	d3, vdp_control	; Send to VDP control port

	clr.l 	d3		; Clear d3 ready to work with again
	move.b 	d2, d3 	; Move palette ID (lower bytes of d2) to d3
	rol.l  	#$8, d3	; Shift palette ID bits 14 and 15 of d3
	rol.l 	#$5, d3	; Can only rol 8 bites in one instruction

	lea 	ASCIIMap, a1	; Load ASCIIMap address to a1

	@CharCopy:
	move.b 	(a0)+, d2 	; Move ASCII byte to lower byte of d2
	cmp.b 	#$0, d2		; Test if byte is zero (string terminator)
	beq.b 	@End 		; If zero, branch to End

	sub.b 	#ASCIIStart, d2	; Subtract first ASCII code to get table entry index
	move.b 	(a1, d2.w), d3 	; Move tile ID from table (index in lower word of d2) to lower byte of d3
	add.w 	d0, d3		; Offset title ID by first tile ID in front
	move.w 	d3, vdp_data 	; Move palette and pattern IDs to VDP data port
	jmp 	@CharCopy 		; Next character

	@End:
	rts