    ; ******************************************************************
    ; Sega Megadrive ROM header
    ; ******************************************************************
StartOfRom:
Vectors:	
    dc.l	$FFFE00, EntryPoint, BusError, AddressError
	dc.l	IllegalInstr, ZeroDivide, ChkInstr, TrapvInstr
	dc.l	PrivilegeViol, Trace, Line1010Emu, Line1111Emu
	dc.l	ErrorExcept, ErrorExcept, ErrorExcept, ErrorExcept
	dc.l	ErrorExcept, ErrorExcept, ErrorExcept, ErrorExcept
	dc.l	ErrorExcept, ErrorExcept, ErrorExcept, ErrorExcept
	dc.l	ErrorExcept, ErrorTrap, ErrorTrap, ErrorTrap
	dc.l	HBlank,    ErrorTrap, VBlank, ErrorTrap
	dc.l	ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
	dc.l	ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
	dc.l	ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
	dc.l	ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
	dc.l	ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
	dc.l	ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
	dc.l	ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
	dc.l	ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
Console:	
    dc.b	'SEGA MEGA DRIVE '					; Hardware system ID
Date:
    dc.b	'(C)XXXX YEAR.MON'					; Release date
Title_Local:
    dc.b	'YOUR GAME TITLE WILL GO HERE... MEEEEEEEEEEEEEP!'	; Domestic name (Note: has to be 48 bytes long, pad it out with spaces if you do not have 48 characters in your title.
Title_Int:
    dc.b	'YOUR GAME TITLE WILL GO HERE... MEEEEEEEEEEEEEP!'	; International name (Note: has to be 48 bytes long)
Serial:
    dc.b	'GM 10101010-00'					; Serial/version number
Checksum:
    dc.w	0							; Checksum
	dc.b	'J               '					; I/O support (Has to be 16 bytes long, so pad it out with spaces.)
RomStartLoc:
    dc.l	StartOfRom						; ROM start
RomEndLoc:
    dc.l	__end-1						; ROM end
RamStartLoc:
    dc.l	$FF0000							; RAM start
RamEndLoc:
    dc.l	$FFFFFF							; RAM end
SRAMSupport:
    dc.l	$5241F820						; change to $5241F820 (NOT $5241E020) to create SRAM. 'RA' and $F8 also work.
	dc.l	$200000							; SRAM start
	dc.l	$200200							; SRAM end (Gives us $200  ($100 useable) bytes of SRAM)
Notes:
    dc.b	'                                                    '	; Anything can be put in this space, but it has to be 52 bytes.
Region:
    dc.b	'JUE             '					; Region (J=Japan, U=USA, E=Europe)

EntryPoint:           ; Entry point address set in ROM header
	move    #$2700,sr		; Disable interrupts.
	tst.l   ($A10008)		; Test port A control.
	bne.s   PortA_Ok		; If so, magically branch.
	tst.w   ($A1000C)		; Test port C control.
PortA_Ok:
	bne.w   PortC_Ok
	move.b  ($A10001),d0		; Get hardware version.
	andi.b  #$F,d0			; Compare.
	beq.s   SkipSecurity		; If the console has no TMSS, skip the security stuff.
	move.l  #'SEGA',($A14000)	; Make the TMSS happy.
SkipSecurity:
	moveq   #0,d0			; Clear d0.
	move.l  #$C0000000,($C00004)	; Set VDP to CRAM write.
	move.w  #$3F,d7			; Clear the entire CRAM.
VDP_ClrCRAM:
	move.w  d0,($C00000)		; Write 0 to the data port.
	dbf     d7,VDP_ClrCRAM		; Clear the CRAM.
	lea     ($FFFF0000),a0		; Load start of RAM into a0.
	move.w  #$3FFF,d0		; Clear $3FFF longwords.
	moveq   #0,d1			; Clear d1.
VDP_ClrVRAM:
	move.w  d0,($C00000)		; Write 0 to the data port.
	dbf     d7,VDP_ClrVRAM		; Clear the CRAM.
	lea     ($FFFF0000),a0		; Load start of RAM into a0.
	move.w  #$07FF,d0		; Clear $3FFF longwords.
	moveq   #0,d1			; Clear d1.
@clrRamLoop:
	move.l  d1,(a0)+		; Clear a long of RAM.
	dbf     d0,@clrRamLoop		; Continue clearing RAM if there's anything left.
PortC_Ok:
	bsr.w   Init_Z80		; Initialize the Z80.
	move    #$2300, sr		; Enable interrupts.
	bra.s   Main		; Branch to main program.
	nop

    ; ************************************
    ; Main
    ; ************************************
Main:
    move.l #VDPRegisters, a0 ; Load address of register table into a0
    move.l #0x18, d0         ; 24 registers to write
    move.l #0x00008000, d1   ; 'Set register 0' command (and clear the rest of d1 ready)
 
@Copy:
    move.b (a0)+, d1         ; Move register value to lower byte of d1
    move.w d1, vdp_control    ; Write command and value to VDP control port
    add.w #0x0100, d1        ; Increment register #
    dbra d0, @Copy

    jmp __main ; Begin external main

Init_Z80:
	move.w  #$100,($A11100)					; Send the Z80 a bus request.
	move.w  #$100,($A11200)					; Reset the Z80.
Init_Z80_WaitZ80Loop:
	btst	#0,($A11100)					; Has the Z80 reset?
	bne.s	Init_Z80_WaitZ80Loop				; If not, keep checking.
	lea     (Init_Z80_InitCode),a0				; Load the start address of the code to a0.
	lea     ($A00000),a1					; Load the address of start of Z80 RAM to a1.
	move.w  #Init_Z80_InitCode_End-Init_Z80_InitCode-1,d1	; Load the length of the Z80 code to d1.
Init_Z80_LoadProgramLoop:
	move.b  (a0)+,(a1)+					; Write a byte of Z80 data.
	dbf	d1,Init_Z80_LoadProgramLoop			; If we have bytes left to write, write them.
	move.w  #0,($A11200)					; Disable the Z80 reset.
	move.w  #0,($A11100)					; Give the Z80 the bus back.
	move.w  #$100,($A11200)					; Reset the Z80 again.
	rts							; Return to sub.

;----------------------------------------------
; Below is the code that the Z80 will execute.
;----------------------------------------------
Init_Z80_InitCode:
	dc.w    $AF01, $D91F, $1127, $0021, $2600, $F977 
	dc.w    $EDB0, $DDE1, $FDE1, $ED47, $ED4F, $D1E1
	dc.w    $F108, $D9C1, $D1E1, $F1F9, $F3ED, $5636
	dc.w    $E9E9
Init_Z80_InitCode_End:

HBlank:
    rte ; Return from Subroutine
VBlank:
    rte ; Return from Subroutine
ErrorExcept:
    lea ExErrorExcept, a0 ; Put address of string in a0
	move.w #PixelFontTileID, d0 ; Put Block ID of font start in d0
	move.w #0x0101, d1 ; First letter position in tiles.
	move.l #0x0, d2 ; Pallete to use.
	jsr DrawTextPlaneA
    stop #$2700 ; Halt CPU
ErrorTrap:
    lea ExErrorTrap, a0 ; Put address of string in a0
	move.w #PixelFontTileID, d0 ; Put Block ID of font start in d0
	move.w #0x0101, d1 ; First letter position in tiles.
	move.l #0x0, d2 ; Pallete to use.
	jsr DrawTextPlaneA
    stop #$2700 ; Halt CPU
BusError:
    lea ExBusError, a0 ; Put address of string in a0
	move.w #PixelFontTileID, d0 ; Put Block ID of font start in d0
	move.w #0x0101, d1 ; First letter position in tiles.
	move.l #0x0, d2 ; Pallete to use.
	jsr DrawTextPlaneA
    stop #$2700 ; Halt CPU
AddressError:
    lea ExAddressError, a0 ; Put address of string in a0
	move.w #PixelFontTileID, d0 ; Put Block ID of font start in d0
	move.w #0x0101, d1 ; First letter position in tiles.
	move.l #0x0, d2 ; Pallete to use.
	jsr DrawTextPlaneA
    stop #$2700 ; Halt CPU
IllegalInstr:
    lea ExIllegalInstr, a0 ; Put address of string in a0
	move.w #PixelFontTileID, d0 ; Put Block ID of font start in d0
	move.w #0x0101, d1 ; First letter position in tiles.
	move.l #0x0, d2 ; Pallete to use.
	jsr DrawTextPlaneA
    stop #$2700 ; Halt CPU
ZeroDivide:
    lea ExZeroDivide, a0 ; Put address of string in a0
	move.w #PixelFontTileID, d0 ; Put Block ID of font start in d0
	move.w #0x0101, d1 ; First letter position in tiles.
	move.l #0x0, d2 ; Pallete to use.
	jsr DrawTextPlaneA
    stop #$2700 ; Halt CPU
ChkInstr:
    lea ExChkInstr, a0 ; Put address of string in a0
	move.w #PixelFontTileID, d0 ; Put Block ID of font start in d0
	move.w #0x0101, d1 ; First letter position in tiles.
	move.l #0x0, d2 ; Pallete to use.
	jsr DrawTextPlaneA
    stop #$2700 ; Halt CPU
TrapvInstr:
    lea ExTrapvInstr, a0 ; Put address of string in a0
	move.w #PixelFontTileID, d0 ; Put Block ID of font start in d0
	move.w #0x0101, d1 ; First letter position in tiles.
	move.l #0x0, d2 ; Pallete to use.
	jsr DrawTextPlaneA
    stop #$2700 ; Halt CPU
PrivilegeViol:
    lea ExPrivilegeViol, a0 ; Put address of string in a0
	move.w #PixelFontTileID, d0 ; Put Block ID of font start in d0
	move.w #0x0101, d1 ; First letter position in tiles.
	move.l #0x0, d2 ; Pallete to use.
	jsr DrawTextPlaneA
    stop #$2700 ; Halt CPU
Trace:
    lea ExTrace, a0 ; Put address of string in a0
	move.w #PixelFontTileID, d0 ; Put Block ID of font start in d0
	move.w #0x0101, d1 ; First letter position in tiles.
	move.l #0x0, d2 ; Pallete to use.
	jsr DrawTextPlaneA
    stop #$2700 ; Halt CPU
Line1010Emu:
    lea ExLine1010Emu, a0 ; Put address of string in a0
	move.w #PixelFontTileID, d0 ; Put Block ID of font start in d0
	move.w #0x0101, d1 ; First letter position in tiles.
	move.l #0x0, d2 ; Pallete to use.
	jsr DrawTextPlaneA
    stop #$2700 ; Halt CPU
Line1111Emu:
    lea ExLine1111Emu, a0 ; Put address of string in a0
	move.w #PixelFontTileID, d0 ; Put Block ID of font start in d0
	move.w #0x0101, d1 ; First letter position in tiles.
	move.l #0x0, d2 ; Pallete to use.
	jsr DrawTextPlaneA
    stop #$2700 ; Halt CPU

    
Z80Data:
    dc.w $af01, $d91f
    dc.w $1127, $0021
    dc.w $2600, $f977
    dc.w $edb0, $dde1
    dc.w $fde1, $ed47
    dc.w $ed4f, $d1e1
    dc.w $f108, $d9c1
    dc.w $d1e1, $f1f9
    dc.w $f3ed, $5636
    dc.w $e9e9, $8104
    dc.w $8f01

PSGData:
    dc.w $9fbf, $dfff
    
VDPRegisters:
    dc.b $14 ; 0: Horiz. interrupt on, plus bit 2 (unknown, but docs say it needs to be on)
    dc.b $74 ; 1: Vert. interrupt on, display on, DMA on, V28 mode (40 cells vertically), + bit 2
    dc.b $30 ; 2: Pattern table for Scroll Plane A at $C000 (bits 3-5)
    dc.b $40 ; 3: Pattern table for Window Plane at $10000 (bits 1-5)
    dc.b $05 ; 4: Pattern table for Scroll Plane B at $A000 (bits 0-2)
    dc.b $70 ; 5: Sprite table at $E000 (bits 0-6)
    dc.b $00 ; 6: Unused
    dc.b $00 ; 7: Background colour - bits 0-3 = colour, bits 4-5 = palette
    dc.b $00 ; 8: Unused
    dc.b $00 ; 9: Unused
    dc.b $00 ; 10: Frequency of Horiz. interrupt in Rasters (number of lines travelled by the beam)
    dc.b $08 ; 11: External interrupts on, V/H scrolling on
    dc.b $81 ; 12: Shadows and highlights off, interlace off, H40 mode (64 cells horizontally)
    dc.b $34 ; 13: Horiz. scroll table at $D000 (bits 0-5)
    dc.b $00 ; 14: Unused
    dc.b $00 ; 15: Autoincrement off
    dc.b $01 ; 16: Vert. scroll 32, Horiz. scroll 64
    dc.b $00 ; 17: Window Plane X pos 0 left (pos in bits 0-4, left/right in bit 7)
    dc.b $00 ; 18: Window Plane Y pos 0 up (pos in bits 0-4, up/down in bit 7)
    dc.b $00 ; 19: DMA length lo byte
    dc.b $00 ; 20: DMA length hi byte
    dc.b $00 ; 21: DMA source address lo byte
    dc.b $00 ; 22: DMA source address mid byte
    dc.b $00 ; 23: DMA source address hi byte, memory-to-VRAM mode (bits 6-7)
	
	nop 0,8
ExHBlank:
	dc.b 	'HBlank'
ExVBlank:
	dc.b 	'VBlank'
ExErrorExcept:
	dc.b 	'ErrorExcept'
ExErrorTrap:
	dc.b 	'ErrorTrap'
ExBusError:
	dc.b 	'BusError'
ExAddressError:
	dc.b 	'AddressError'
ExIllegalInstr:
    dc.b 	'IllegalInstr'
ExZeroDivide:
    dc.b 	'ZeroDivide'
ExChkInstr:
    dc.b 	'ChkInstr'
ExTrapvInstr:
    dc.b 	'TrapvInstr'
ExPrivilegeViol:
    dc.b 	'PrivilegeViol'
ExTrace:
    dc.b 	'Trace'
ExLine1010Emu:
    dc.b 	'Line1010Emu'
ExLine1111Emu:
    dc.b 	'Line1111Emu'