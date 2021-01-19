.eqv	pHeader	0
.eqv	filesize 4
.eqv	pImg	8
.eqv	width	12
.eqv	height	16
.eqv	linesbytes 20

.eqv	bi_imgoffset  10
.eqv	bi_imgwidth   18
.eqv	bi_imgheight  22

.eqv	max_file_size 32830

	.data
filename:	.asciiz "blank.bmp"
resultfile:	.asciiz "result.bmp"
error_ini:	.asciiz "Error while reading bmp initial file\n"
error_res:	.asciiz "Error while reading bmp result file\n"
	.align	4
descriptor:	.word	0, 0, 0, 0, 0, 0, 0, 0, 0

filebuf:	.space max_file_size

	.text
main:
	la $a0, filename
	la $a1, descriptor
	la $t8, filebuf
	sw $t8, pHeader($a1)
	li $t8, max_file_size
	sw $t8, filesize($a1)
	jal read_bmp_file
	
	# check for errors
	
	la $a0, descriptor
	li $a1, 250 # x pixel coordinate
	li $a2, 250 # y pixel coordinate
	li $a3, 0 # Color of pixel
	li $s0, 120 # Radius of Circle
	
draw_circle:
	move $t0, $a1 	 # cX coordinate
	move $t1, $a2 	 # cY coordinate
	move $t3, $s0 	 # Radius
	move $t7, $zero  # small! "x"
	
	#add $t1, $t1, $t3	# setting starting point (cX, R)
	
	move $t2, $t3
	sll $t2, $t2, 2	# Radius * 4
	li $t4, 5	# define 5
	sub  $t4, $t4, $t2	# Define "d"
	
	
	sub $t5, $zero, 2   	# -2
	mul $t5, $t3, $t5	# -2 * radius	
	add $t5, $t5, 5		# -2 *radius + 5
	mul $t5, $t5, 4		# (-2 *radius + 5) * 4    defined dltA
					
	add $t6, $zero, 3  # define 3
	mul $t6, $t6, 4  # dltB
	jal loop

read_bmp_file:
	# $a0 - file name 
	# $a1 - file descriptor
	#	pHeader - contains pointer to file buffer
	#	filesize - maximum file size allowed
	move $t8, $a1
	li $a1, 0
	li $a2, 0
	li $v0, 13 # open file
	syscall
	
	bltz $v0, read_error	# check for errors: $v0 < 0
	
	move $a0, $v0
	lw $a1, pHeader($t8)
	lw $a2, filesize($t8)
	li $v0, 14
	syscall
	
	sw $v0, filesize($t8)  # actual size of bmp file

	li $v0, 16 # close file
	syscall

	lhu $t9, bi_imgoffset($a1)
	add $t9, $t9, $a1
	sw $t9, pImg($t8)
	
	lhu $t9, bi_imgwidth($a1)
	sw $t9, width($t8)
	
	lhu $t9, bi_imgheight($a1)
	sw $t9, height($t8)
	
	# number of words in a line: (width + 31) / 32
	# number of bytes in a line: ((width + 31) / 32) * 4
	lw $t9, width($t8)
	add $t9, $t9, 31
	sra $t9, $t9, 5 # t1 contains number of words
	sll $t9, $t9, 2
	sw $t9, linesbytes($t8)
	
	jr $ra


save_bmp_file:
	# $a0 - file name 
	# $a1 - file descriptor
	#	pHeader - contains pointer to file buffer
	#	filesize - maximum file size allowed
	move $t8, $a1
	li $a1, 1  # write
	li $a2, 0
	li $v0, 13 # open file
	syscall
	
	bltz $v0, save_error	# check for errors: $v0 < 0
	
	move $a0, $v0
	lw $a1, pHeader($t8)
	lw $a2, filesize($t8)
	li $v0, 15
	syscall
	
	li $v0, 16 # close file
	syscall
	jr $ra
	
	

	
set_color:
	bgt $a3, $zero, white
	beq $a3, $zero, black
	jr $ra
	
back:	

	la $a0, resultfile
	la $a1, descriptor
	jal save_bmp_file
	j end

black:
	xor $t9, $t9, $t2    	
	sb $t9, 0($t8)	
	jr $ra
white:
	or $t9, $t9, $t2    
	sb $t9, 0($t8)
	jr $ra



loop:
	bgt $t7, $t3, back	#while condition (x<=y)
	
	sub $a1, $t0, $t7	# cX -x
	sub $a2, $t1, $t3	# cY -y
	jal set_next_pixel	# SetPixel( cX-x, cY-y)
	
	sub $a1, $t0, $t7	# cX -x
	add $a2, $t1, $t3	# cY +y
	jal set_next_pixel	# SetPixel( cX-x, cY+y)
	
	add $a1, $t0, $t7	# cX +x
	sub $a2, $t1, $t3	# cY -y
	jal set_next_pixel	# SetPixel( cX-x, cY+y)
	
	add $a1, $t0, $t7	# cX +x
	add $a2, $t1, $t3	# cY +y
	jal set_next_pixel	# SetPixel( cX+x, cY+y)
	
	
	sub $a1, $t0, $t3	# cX -y
	sub $a2, $t1, $t7	# cY -x
	jal set_next_pixel	# SetPixel( cX-y, cY-x)
	
	sub $a1, $t0, $t3	# cX -y
	add $a2, $t1, $t7	# cY +x
	jal set_next_pixel	# SetPixel( cX-y, cY+x)
	
	add $a1, $t0, $t3	# cX +y
	sub $a2, $t1, $t7	# cY -x
	jal set_next_pixel	# SetPixel( cX-y, cY+x)
	
	add $a1, $t0, $t3	# cX +y
	add $a2, $t1, $t7	# cY +x
	jal set_next_pixel	# SetPixel( cX+y, cY+x)
	
		
	bgtz $t4, if  # if (d > 0)
	ble $t4, $zero, else	#else
	

	
	

save_error:			# No BMP result file found
	la $a0, error_res
	li $v0, 4
	syscall
	b end
	
read_error:			# No BMP initial file found
	la $a0, error_ini
	li $v0, 4
	syscall
	b end	
	
end:	li $v0, 10	# wyjscie z programu
	syscall

if:   # condition where d>0
	add $t4, $t4, $t5	# d+= dltA
	subi $t3, $t3, 1		# y--
	addi $t7, $t7, 1		# x++
	
	addi $t5, $t5, 16	#dltA += 4*4
	addi $t6, $t6, 8		#dltB += 2*4 
	
	b loop

else:	# condition where d<0
	add $t4, $t4, $t6	# d+= dltB
	addi $t7, $t7, 1		# x++
	
	addi $t5, $t5, 8	#dltA += 2*4
	addi $t6, $t6, 8		#dltB += 2*4 
		
	b loop
	
	
set_next_pixel:
	#jal read_bmp_file
	lw $t8, linesbytes($a0)
	mul $t8, $t8, $a2   # $t0 offset of the beginning of the row
	
	sra $t9, $a1, 3	    # pixel byte offset within the row
	add $t8, $t8, $t9   # pixel byte offset within the image
	lw $t9, pImg($a0)
	add $t8, $t8, $t9   # address of the pixel byte	
	lb $t9, 0($t8)
	and $a1, $a1, 0x7   # pixel offset within the byte
	li $t2, 0x80
	srlv $t2, $t2, $a1  # mask on the position of pixel
		
	bgt $a3, $zero, white # placing a proper coloured pixel
	beq $a3, $zero, black
	
	jr $ra
