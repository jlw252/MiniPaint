#Jenny Wang
#jlw252

# it is very important that you do not put any code or variables
# before this .include line. you can put comments, but nothing else.

#12 things


.include "display_2244_0203.asm"
.include "lab4_graphics.asm"

.eqv MODE_NOTHING 0
.eqv MODE_BRUSH   1
.eqv MODE_COLOR   2

.eqv PALETTE_X  32
.eqv PALETTE_Y  56
.eqv PALETTE_X2 96
.eqv PALETTE_Y2 72

.data
	drawmode: .word MODE_NOTHING
	last_x:   .word -1
	last_y:   .word -1
	color:    .word 0b111111 # 3,3,3 (white)
.text

.global main
main:
	#call display_init, load arguments 
	li a0, 15 #milliseconds per frame
	li a1, 1 #boolean to enable the framebuffer
	li a2, 0 #disable the tilemap
	jal display_init #call display_init
	
	jal load_graphics #call load_graphics

# ------------------------------------------------------------------
loop:
	#Call check_input
	jal check_input
	
	#call draw_cursor
	jal draw_cursor
	
	#call display_finish_frame
	jal display_finish_frame
	
	#go back to loop
	j loop

# -------------------------------------------------------------------
load_graphics:
	push ra
	
	#call diplay_load_sprite_gfx
	la a0, cursor_gfx
	li a1, CURSOR_TILE
	li a2, N_CURSOR_TILES
	jal display_load_sprite_gfx
	
	la a0, palette_sprite_gfx
	li a1, PALETTE_TILE
	li a2, N_PALETTE_TILES
	jal display_load_sprite_gfx
	
	pop ra
	jr ra
# -------------------------------------------------------------------
check_input:
	push ra
	lw t0, drawmode
	
	beq t0, MODE_NOTHING, _nothing
	beq t0, MODE_BRUSH, _brush
	beq t0, MODE_COLOR, _color
	
	_nothing:
		jal drawmode_nothing
		j _break
		
	_brush:
		jal drawmode_brush
		j _break
		
	_color:
		jal drawmode_color
		j _break
		
	_break:
	
	pop ra
	jr ra
# -------------------------------------------------------------------
drawmode_nothing:
	push ra
	
	#check if c is pressed
	display_is_key_pressed t0, KEY_C
	beq t0, 0, _c_not_pressed
	
	#Draw mode
	li t0, MODE_COLOR
	sw t0, drawmode
	
	#Show pallette sprites
	la t9, display_spr_table
	add t9, t9, 4
	
	li t8, 0 
	_outer_loop:
		bge t8, 2, _outer_break #t8 has row
		
		li t7, 0
		_inner_loop:
			bge t7, 8, _inner_break #t7 has col
			
			#x = col * 8 + PALETTE_X
			mul t0, t7, 8
			add t0, t0, PALETTE_X
			sb t0, 0(t9)
			
			#y = row * 8 + PALETTE_Y
			mul t0, t8, 8
			add t0, t0, PALETTE_Y
			sb t0, 1(t9)
			
			#tile = row * 8 + col + PALETTE_TILE
			mul t0, t8, 8
			add t0, t0, t7
			add t0, t0, PALETTE_TILE
			sb t0, 2(t9)
			
			li t0, 1 #change to 0 to hide
			sb t0, 3(t9)
			
			add t9, t9, 4
			add t7, t7, 1
			j _inner_loop
		_inner_break:
		
		add t8, t8, 1
		j _outer_loop
	_outer_break:

	_c_not_pressed:
	
	#check if Left mouse button pressed
	lw t0, display_mouse_pressed
	and t0, t0, MOUSE_LBUTTON
	beq t0, 0, _not_pressed
	
	#Check if user is holding alt, perform eyedropper
	li a0, KEY_ALT
	display_is_key_held a0, KEY_ALT
	beq a0, 0, _no_eyedrop
	
	#eyedrop
	lw a0, display_mouse_x
	lw a1, display_mouse_y
	jal display_get_pixel
	sw v0, color
	j _not_pressed
	
	
	_no_eyedrop:
	
	#Brush mode
	li t0, MODE_BRUSH
	sw t0, drawmode
	
	# draw a 1-pixel line using the current color
	#lw a0, display_mouse_x
	#lw a1, display_mouse_y
	#lw a2, display_mouse_x
	#sw a2, last_x
	#lw a3, display_mouse_y
    #sw a3, last_y
   	
   	display_is_key_held t0, KEY_SHIFT #shift held
	beq t0, 0, _else
		lw a0, last_x
		lw a1, last_y
		j _next
	_else:
		lw a0, display_mouse_x
		lw a1, display_mouse_y
		j _next
	
	_next:	
   	lw a2, display_mouse_x
   	lw a3, display_mouse_y
    lw v1, color   #Assuming color is stored at this location
    jal display_draw_line
		
	# set last_x and last_y to the current mouse coords
	lw t0, display_mouse_x
    lw t1, display_mouse_y
    sw t0, last_x
    sw t1, last_y

	_not_pressed:
	pop ra
	jr ra
	
# -------------------------------------------------------------------
drawmode_brush:
	push ra
	
	#Check if Left mouse button released or offscreen
	lw t0, display_mouse_released
	and t0, t0, MOUSE_LBUTTON
	beq t0, 1, _check_offscreen
	
	#Check offscreen coordinates
	lw t0, display_mouse_x
	blt t0, 0, _check_offscreen
	bgt t0, 127, _check_offscreen
	lw t0, display_mouse_y
	blt t0, 0, _check_offscreen
	bgt t0, 127, _check_offscreen
	j _else
    
    _check_offscreen:
    # Set drawmode to MODE_NOTHING
    li t0, MODE_NOTHING
    sw t0, drawmode
    j _end_drawmode_brush
    
    #else if
    _else:
    lw t0, display_mouse_x
    lw t1, last_x
    lw t2, display_mouse_y
    lw t3, last_y
    bne t0, t1, _draw_line
    bne t2, t3, _draw_line
    j _end_drawmode_brush
    
    _draw_line:
    #Draw a line from last x/y to the current mouse coordinates in current colors
    lw a0, last_x
    lw a1, last_y
    lw a2, display_mouse_x
    lw a3, display_mouse_y
    lw v1, color
    jal display_draw_line
    lw t0, display_mouse_x
    lw t2, display_mouse_y
    
    #Set last_x and last_y to current mouse coordinates
    sw t0, last_x
    sw t2, last_y
 
    _end_drawmode_brush:
    pop ra
    jr ra
	
# -------------------------------------------------------------------
drawmode_color:
	push ra
		
	# Check if the left mouse button is pressed
    lw t0, display_mouse_pressed
    and t0, t0, MOUSE_LBUTTON
    beqz t0, _not_pressed

    # Check if the mouse coordinates are within the palette
    jal check_palette_click

	_not_pressed:
	pop ra
	jr ra

# -------------------------------------------------------------------
check_palette_click:
	push ra
	
	lw t2, display_mouse_x
	lw t3, display_mouse_y

	# Check if the mouse coordinates are within the palette area
   	blt t2, PALETTE_X, _end_check_palette_click #greater than or = 
    bge t2, PALETTE_X2, _end_check_palette_click
    _not_in_palette:
	
	sub t2, t2, PALETTE_X
	sub t3, t3, PALETTE_Y
	
	#calculate the color based on palette postion
	div t3, t3, 4
	div t2, t2, 4
	
	mul t3, t3, 16
	add t4, t2, t3
	
	#set color based on calculation
	move t0, t4
	sw t0, color
	
	#Set drawmode to MODE_NOTHING
	li t0, MODE_NOTHING
	sw t0, drawmode
	
	#hide the palette sprites
	jal hide_palette
	
	_end_check_palette_click:
	pop ra
	jr ra

# -------------------------------------------------------------------
hide_palette:
    push ra

    la t9, display_spr_table
    add t9, t9, 4

    li t8, 0
    _outer_loop:
        bge t8, 2, _outer_break

        li t7, 0
        _inner_loop:
            bge t7, 8, _inner_break

            li t0, 0 # Change to 0 to hide
            sb t0, 3(t9)

            add t9, t9, 4
            add t7, t7, 1
            j _inner_loop

        _inner_break:
        add t8, t8, 1
        j _outer_loop

    _outer_break:
    pop ra
    jr ra

# -------------------------------------------------------------------
display_get_pixel:
	push ra
	
	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	lb v0, display_fb_ram(t0)
	
	pop ra
	jr ra
# -------------------------------------------------------------------
#eyedropper:
	
# -------------------------------------------------------------------
draw_cursor:
	push ra
	
	la t2, display_spr_table #temporary register
	
	#Calculate coordinates for drawing cursor
	lw t0, display_mouse_x
	lw t1, display_mouse_y
	
	#Calculate coordinate for drawing cursor
	add t0, t0, -3 #X
	add t1, t1, -3 #Y
	
	sb t0, 0(t2)
	
	sb t1, 1(t2)
	
	li t0, CURSOR_TILE
	sb t0, 2(t2)
	
	li t3, 0x41
	sb t3, 3(t2) #Storing
	
	pop ra
	jr ra
	
	
