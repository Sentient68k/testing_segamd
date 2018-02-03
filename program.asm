; Main assembly file that collects all others in proper order.
    include 'init.asm'
    include 'main.asm'
    include 'palettes.asm'
    include './data/test_tiles_01.asm'
    include 'GLOBALS.asm'
__end   ; Address for end of ROM.