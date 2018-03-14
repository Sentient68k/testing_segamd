; Main assembly file that collects all others in proper order.
    include 'init.asm'
    include 'main.asm'
    include './data/palettes.asm'
    include './data/tileset03.asm'
    include './data/font.asm'
    include 'GLOBALS.asm'
    include './data/map03.asm'
__end   ; Address for end of ROM.