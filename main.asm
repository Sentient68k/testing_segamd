; Main program for the ROM.
__main:
	
	;Load Plalettes
	lea	palette_test_segamd, a0	; Load address of palettes into a0
	jsr LoadPalette ; Jump to Palette Loading subroutine.

	;Load Tiles
	lea tiles_test_segamd, a0 ; Get tiles address ready for loading.
	move.l #0x0100, d0
	move.l #tiles_test_segamd_size_t, d1
	jsr LoadTiles

	;Load Tile Mapping
	lea map_test_segamd, a0 ; Get tiles address ready for loading.
	move.w #map_test_segamd_size_w, d0 ; d0 (b) - Size in words
	move.w #0x00, d1 ; d1 (b) - Y offset
	move.w #0x0008, d2 ; d2 (w) - First tile ID
	move.l #0x0, d3 ; d3 (b) - Palette ID
	jsr LoadMapPlaneA

	@Loop:
	nop
	jmp @Loop

	jmp __main

;======================Subroutines======================

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
	and.l   #%0011111111111111, d4 ; Mask out original palette ID
	or.l    d3, d4                 ; Replace with our own
	add.w   d2, d4                 ; Add first tile offset to d4
	move.w  d4, vdp_data           ; Move to VRAM
	dbra    d0, @Copy              ; Loop
 
	rts