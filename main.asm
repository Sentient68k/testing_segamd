; Main program for the ROM.
__main:
	move.w	#$8F02, vdp_control	; Autoincrement to 2 bytes on VDP
	
	; Move palettes to CRAM
	move.l	#vdp_write_palettes, vdp_control	; Setup VDP to write CRAM to address $0000
	lea	Palettes, a0	; Load address of palettes into a0
	move.l	#$1F, d0	; 128 bytes of data (4 palettes, 32 longs, -1 for counter)

	@ColorLoop:
	move.l (a0)+, vdp_data 	; Move data to VDP port, increment address pointer to move up in palette lines
	dbra d0, @ColorLoop

	jmp __main