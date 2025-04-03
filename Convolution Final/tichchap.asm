.data
	# Ðu?ng d?n cho file
	input_file: .asciiz "C:\\Convolution\\test_8.txt"        
	output_file: .asciiz "C:\\Convolution\\output.txt"

	# BI?n luu kích thu?c và d? li?u
	zero_f: .float 0.0	# Giá tr? 0.0 (float)
	one_f: .float 1.0	# Giá tr? 1.0 (float)
	ten_f: .float 10.0	# Giá t? 10.0 (float)
	ten_thousand: .float 10000.0
	decimal_f: .float 0.1	# Giá tr? 0.1 (float)
	space: .asciiz " "	# Kho?ng tr?ng
	newline: .asciiz "\n"	# Xu?ng dòng
	queue:          .space 1000    # Space for queue (adjust size as needed)
        queue_front:    .word 0        # Front index
        queue_rear:     .word 0        # Rear index
	float_buffer: .space 32	# B? d?m d? luu chu?i floating point  
	N: .word 0		# Size ma tr?n ?nh NxN - 3 <= N <= 7
	M: .word 0		# Size filter MxM - 2 <= M <= 4
	padding: .word 0 	# Giá tr? d?m - 0 <= p <= 4
	stride:  .word 0	# Giá tr? bu?c nh?y - 1 <= s <= 3
	N_padded:.word 0	# Giá tr? image sau khi padded
	output_size:.word  0 
	image:   .space 196	# B? nh? ?nh (if) l?n nh?t (7x7x)x4
	kernel: .word 0:64	# B? nh? filter (if) l?n nh?t (4x4)x4
	output: .word 0:784	# B? nh? ma tr?n d?u ra l?n nh?t (14x14)x4
	buffer: .space 1024	# B? nh? d?m luu n?i dung file
	image_padded: .word 0:900# Ma tr?n sau khi thêm padding
	float_string: .space 100  # Dung lu?ng cho chu?i k?t qu? float
	int_string:   .space 32         # C?p không gian cho chu?i s? nguyên, d? ch?a ph?n nguyên và d?u ch?m
        decimal_string: .space 32       # C?p không gian cho chu?i s? th?p phân (n?u c?n)
	image_msg: .ascii "IMAGE MATRIX"
	
	# Thông báo l?i
	open_error_msg: .asciiz "Error: Unable to open input file \n,"
	read_error_msg: .asciiz "Error: Unable to read input file \n,"
	write_error_msg: .asciiz "Error: Unable to write input file \n,"
	invalid_param_msg: .asciiz "Error: Invalid input file \n,"
.text 
.globl main			# Khai báo di?m vào chuong trình

main:
	# Ð?c Input
	jal read_input		
	
	# X? lí s? li?u
	jal process_data
	
	# Ki?m tra tham s?
	jal validate_parameter 
	
	# Th?c hi?n tích ch?p (convolutional)
	jal convolution
	
	
	#Ghi k?t qu? nh?n du?c vào file output
	jal write_output	
	
	# K?t thúc chuong trình
	jal exit_program
	
# ===========================================================================================================================================
# HÀM Ð?C D? LI?U INPUT
read_input:
	# M? file input
	li $v0, 13		# System call 13: M? file
	la $a0, input_file	# File input
	li $a1, 0		# Ch? d? d?c (0 -> read only)
	syscall
	move $s0, $v0		# Luu vào $s0
	
	# Ki?m tra l?i khi m? file
	bltz $v0, file_open_error	# N?u $v0 < 0 (r?ng), d?c file th?t b?i
	
	#Ð?c n?i dung file vào b? nh? d?m
	li $v0, 14		# System call 14: Ð?c file
	move $a0, $s0		# Ð?c file description
	la $a1, buffer 		# B? nh? d?m d? luu tr? d? li?u d?c t? file
	li $a2, 1024		# S? byte t?i da c?n d?c
	syscall
	
	# Ki?m tra l?i d?c file 
	bltz $v0, file_load_error	# N?u $v0 < 0, d?c file th?t b?i
	
	# Ðóng file sau khi d?c
	li $v0, 16		# System call 16: Ðóng file
	move $a0, $s0
	syscall
	
	jr $ra			# Return caller
	
file_open_error:
	li $v0, 4		# System call 4: In
	la $a0, open_error_msg	
	syscall
	j exit_program		# Thoát chuong trình
	
file_load_error:
	li $v0, 4		# System call 4: In
	la $a0, read_error_msg	
	syscall
	j exit_program		# Thoát chuong trình
# ===========================================================================================================================================
# HÀM X? LÍ S? LI?U
process_data:
	la $t0, buffer		# Ð?a ch? ban d?u c?a buffer
	li $t1, 0		# Ch? s? hi?n t?i trong buffer
	li $t2, 0		# Bi?n luu giá tr? t?m th?i
	li $t3, 4		# 4 Bi?n dòng d?u tiên (N, M, padding, stride)
	li $t4, 0		# Ð?m giá tr? dã d?c (count = 0)

parse_loop:
	lb $t5, 0($t0)		# L?y 1 byte t? buffer (i = 0)
	
	# Ki?m tra kí t? không h?p l?
	beqz $t5, skip_value		# N?u g?p ký t? null ('\0'). thoát
	beq $t5, 32, skip_value		# N?u g?p ' ', kí t? ti?p theo
	beq $t5, 10, skip_value		# N?u g?p '/n', kí t? ti?p theo
	
	# Chuy?n kí t? s? thành giá tr?
	sub $t5, $t5, 48	# Chuy?n kí t? ASCII -> s? (0 = ASCII 48)
	mul $t2, $t2, 10	# Nhân giá tr? tru?c dó v?i 10
	add $t2, $t2, $t5	# C?ng thêm ch? s? m?i
	addi $t0, $t0, 1	# i++
	j store_value
	
skip_value: 
	addi $t0, $t0, 1
	
	# N?u x? lí d? 4 giá tr? ? dòng d?u tiên
	beq $t4, $t3, para_parse_done		# count = 4 -> Ð? 4 giá tr?
	
	j parse_loop

store_value:
	# Luu giá tr? khi g?p kho?ng tr?ng
	beq $t4, 0, store_N		# count = 0 => luu vào N
	beq $t4, 1, store_M		# count = 1 => luu vào M
	beq $t4, 2, store_padding	# count = 2, luu vào padding
	beq $t4, 3, store_stride	# count = 3, luu vào stride

count_ram:
	addi $t4, $t4, 1	# count++
	move $t2, $zero		# Reset giá tr? t?m th?i
	addi $t0, $t0, 1	# Tang con tr? buffer
	j parse_loop
			
store_N:
	sw $t2, N		# Luu giá tr? vào N
	
	# Ki?m tra giá tr? v?a luu
	li $v0, 1
	lw $a0, N
	syscall
	
	#In kho?ng tr?ng
	li $v0, 4
	la $a0, space
	syscall
	
	j count_ram

store_M:
	sw $t2, M		# Luu giá tr? vào M
	# Ki?m tra giá tr? hay d?a ch? du?c luu
	li $v0, 1
	lw $a0, M
	syscall
	
	#In kho?ng tr?ng
	li $v0, 4
	la $a0, space
	syscall
	
	j count_ram
	
store_padding:
	sw $t2, padding		# Luu giá tr? padding
	
	# Ki?m tra giá tr? hay d?a ch? du?c luu
	li $v0, 1
	lw $a0, padding
	syscall
	
	#In kho?ng tr?ng
	li $v0, 4
	la $a0, space
	syscall
	
	j count_ram
	
store_stride:
	sw $t2, stride		# Luu giá tr? stide
	
	# Ki?m tra giá tr? hay d?a ch? du?c luu
	li $v0, 1
	lw $a0, stride
	syscall
	
	# #In kho?ng tr?ng
	li $v0, 4
	la $a0, newline
	syscall
	
	j count_ram
	
para_parse_done:
	j store_image_point		# Return caller	
	
store_image_point:

	# Kh?i t?o giá tr? floating point	
	la $a0, zero_f		
	lwc1 $f1, zero_f	# f1 = 0
	la $a0, ten_f
	lwc1 $f10, ten_f	# f10 = 0
	
	li $t1, 0		# C? duong (1: âm)
	li $t2, 0		# Index i = 0
	lw $t3, N		# Tham s? ?nh N
	mul $t4, $t3, $t3	# S? ph?n t? NxN

parse_image_loop:
	beq $t2, $t4, image_parse_done
	lb $t5, 0($t0)		# L?y kí t? hi?n t?i
	
	# Ki?m tra kí t? h?p l?, d?u âm, d?u th?p phâm
	beq $t5, 0, skip_image_value		# N?u g?p \'r'\, b? qua
	beq $t5, 10, skip_image_value		# N?u g?p \'n'\, b? qua
	beq $t5, 32, skip_image_value		# N?u g?p \' '\, b? qua
	
	beq $t5, 45, negative_image_value	# N?u g?p \-\, x? lí s? âm
	beq $t5, 46, image_parse_praction	# N?u g?p '.', x? lí ph?n th?p phân
	
	# X? lí s? nguyên
parse_image_integer:
	sub $t5, $t5, 48			# Chuy?n ASCII -> s?
	mtc1 $t5, $f0				# Chuy?n giá tr? thanh ghi t5  -> f0
	cvt.s.w $f0, $f0			# Chuy?n t? word -> float
	
	mul.s $f1, $f1, $f10
	add.s $f1, $f1, $f0			# $f1 = $f1x10 + ph?n nguyên
	
	addi $t0, $t0, 1			# Sang kí t? ti?p theo
	
	# Ki?m tra n?u dây là s? nguyên
	lb $t5, 0($t0)				# Kí t? sau khi convert
	beq $t5, 0, store_float.i_value 	# N?u g?p null, luu l?i
	beq $t5, 10, store_float.i_value	# N?u g?p \'r'\, luu l?i
	beq $t5, 13, store_float.i_value	# N?u g?p \'n'\, luu l?i
	beq $t5, 32, store_float.i_value	# N?u g?p  ' ', luu l?i
	
	j parse_image_loop
	
skip_image_value:
	addi $t0, $t0, 1
	j parse_image_loop

negative_image_value:
	li $t1, 1				# Ð?t d?u tr?
	addi $t0, $t0, 1
	j parse_image_loop
	
image_parse_praction:
	addi $t0, $t0, 1			# Sang kí t? sau '.'
	la $a0, decimal_f
	lwc1 $f2, decimal_f			# f2 = 0.1
	
image_fraction_loop:	
	lb $t5, 0($t0)				# L?y kí t? hi?n t?i

	# Ki?m tra kí t?
	beq $t5, 0, store_float.i_value 	# N?u g?p null, luu l?i
	beq $t5, 10, store_float.i_value	# N?u g?p \'r'\, luu l?i
	beq $t5, 13, store_float.i_value	# N?u g?p \'n'\, luu l?i
	beq $t5, 32, store_float.i_value	# N?u g?p  ' ', luu l?i
	
	# Tính toán
	sub $t5, $t5, 48			# Chuy?n ASCII -> s?
	mtc1 $t5, $f3				# Chuy?n giá tr? thanh ghi $t5 -> $f2
	cvt.s.w $f3, $f3			# Chuy?n giá tr? t? word -> float
	mul.s $f3, $f3, $f2			# f3 -> 0.f3
	add.s $f1, $f3, $f1			# f1 = f1 + 0.f3
	mul.s $f2, $f2, $f2			# f2 = f2 x 0.1  -> s? th?p phân ti?p theo
	
	addi $t0, $t0, 1			# Kí t? ti?p theo
	j image_fraction_loop

store_float.i_value:
	bnez $t1, make_image_negative
	j save_image_float
	
make_image_negative:
	neg.s $f1, $f1				# f1 = -f1
	li $t1, 0				# Ð?t l?i c? duong
	
save_image_float:
	la $a1, image				# Ð?a ch? co b?n c?a image
	mul $t6, $t2, 4				# t6 = Offset = Index * 4
	add $a1, $a1, $t6			# Ð?a ch? ph?n t? th? i trong image
	
	swc1 $f1, 0($a1)			# Luu giá tr? float vào m?ng
	addi $t2, $t2, 1			# i++ : Index k? ti?p
	
	# Reset giá tr? $f1
	la $a0, zero_f
	lwc1 $f1, 0($a0)			# Reset f1 = 0.0 d? ti?p t?c tính toán
	addi $t0, $t0, 1			# Kí t? ti?p theo
	
	j parse_image_loop
	
image_parse_done:
	j store_kernel_point
	
store_kernel_point:
	
	# Kh?i t?o giá tr? floating point	
	la $a0, zero_f		
	lwc1 $f1, zero_f	# f1 = 0
	la $a0, ten_f
	lwc1 $f10, ten_f	# f10 = 0
	
	li $t1, 0		# C? duong (1: âm)
	li $t2, 0		# Index i = 0
	lw $t3, M		# Giá tr? M
	
	mul $t4, $t3, $t3	# S? ph?n t? MxM

parse_kernel_loop:
	lb $t5, 0($t0)		# L?y kí t? hi?n t?i
	beq $t2, $t4, kernel_parse_done
	
	# Ki?m tra kí t? h?p l?, d?u âm, d?u th?p phâm
	beq $t5, 0, skip_kernel_value		# N?u g?p null, b? qua
	beq $t5, 10, skip_kernel_value		# N?u g?p \'n'\, b? qua
	beq $t5, 13, skip_kernel_value		# N?u g?p \'r'\, b? qua
	beq $t5, 32, skip_kernel_value		# N?u g?p \' '\, b? qua
	
	beq $t5, 45, negative_kernel_value	# N?u g?p \-\, x? lí s? âm
	beq $t5, 46, kernel_parse_praction	# N?u g?p '.', x? lí ph?n th?p phân

	# X? lí s? nguyên
parse_kernel_integer:
	sub $t5, $t5, 48			# Chuy?n ASCII -> s?
	mtc1 $t5, $f0				# Chuy?n giá tr? thanh ghi t5  -> f0
	cvt.s.w $f0, $f0			# Chuy?n t? word -> float
	
	mul.s $f1, $f1, $f10
	add.s $f1, $f1, $f0			# $f1 = $f1x10 + ph?n nguyên
	
	addi $t0, $t0, 1			# Sang kí t? ti?p theo
	
	# Ki?m tra n?u dây là s? nguyên
	lb $t5, 0($t0)				# Kí t? sau khi convert
	beq $t5, 0, store_float.k_value 	# N?u g?p null, luu l?i
	beq $t5, 10, store_float.k_value	# N?u g?p \'r'\, luu l?i
	beq $t5, 13, store_float.k_value	# N?u g?p \'n'\, luu l?i
	beq $t5, 32, store_float.k_value	# N?u g?p  ' ', luu l?i
	
	j parse_kernel_loop

skip_kernel_value:
	addi $t0, $t0, 1
	j parse_kernel_loop

negative_kernel_value:
	li $t1, 1				# Ð?t d?u tr?
	addi $t0, $t0, 1
	j parse_kernel_loop
	
kernel_parse_praction:
	addi $t0, $t0, 1			# Sang kí t? sau '.'
	la $a0, decimal_f
	lwc1 $f2, decimal_f			# f2 = 0.1

kernel_fraction_loop:	
	lb $t5, 0($t0)				# L?y kí t? hi?n t?i

	# Ki?m tra kí t?
	beq $t5, 0, store_float.k_value 	# N?u g?p null, luu l?i
	beq $t5, 10, store_float.k_value	# N?u g?p \'r'\, luu l?i
	beq $t5, 13, store_float.k_value	# N?u g?p \'n'\, luu l?i
	beq $t5, 32, store_float.k_value	# N?u g?p  ' ', luu l?i
	
	# Tính toán
	sub $t5, $t5, 48			# Chuy?n ASCII -> s?
	mtc1 $t5, $f3				# Chuy?n giá tr? thanh ghi $t5 -> $f2
	cvt.s.w $f3, $f3			# Chuy?n giá tr? t? word -> float
	mul.s $f3, $f3, $f2			# f3 -> 0.f3
	add.s $f1, $f3, $f1			# f1 = f1 + 0.f3
	mul.s $f2, $f2, $f2			# f2 = f2 x 0.1  -> s? th?p phân ti?p theo
	
	addi $t0, $t0, 1			# Kí t? ti?p theo
	j kernel_fraction_loop

store_float.k_value:
	bnez $t1, make_kernel_negative
	j save_kernel_float

make_kernel_negative:
	neg.s $f1, $f1				# f1 = -f1
	li $t1, 0				# Ð?t l?i c? duong

save_kernel_float:

	la $a1, kernel				# Ð?a ch? co b?n c?a kernel
	mul $t6, $t2, 4				# t6 = offset = index*4
	add $a1, $a1, $t6			# Ð?a ch? th? i trong image
	
	swc1 $f1, 0($a1)			# Luu giá tr? float vào m?ng
	addi $t2, $t2, 1			# i++: Index k? ti?p


	# Reset giá tr? $f1
	la $a0, zero_f
	lwc1 $f1, 0($a0)			# Reset f1 = 0.0 d? ti?p t?c tính toán
	addi $t0, $t0, 1			# Kí t? ti?p theo
	
	j parse_kernel_loop

kernel_parse_done:
	jr $ra
	
# ===========================================================================================================================================
# HÀM CHECK GIÁ TR? H?P L?
# Error handling routine that writes to both console and file
write_error_to_file:
    # Save registers
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)

    # First print to console
    li $v0, 4
    la $a0, invalid_param_msg
    syscall

    # Open output file
    li $v0, 13
    la $a0, output_file
    li $a1, 1          # Write mode
    li $a2, 0          # Mode (ignored)
    syscall
    move $s0, $v0      # Save file descriptor

    # Check if file opened successfully
    bltz $s0, write_error_exit

    # Write error message to file
    li $v0, 15
    move $a0, $s0
    la $a1, invalid_param_msg
    li $a2, 35         # Length of error message (adjust based on your message)
    syscall

    # Close file
    li $v0, 16
    move $a0, $s0
    syscall

write_error_exit:
    # Restore registers
    lw $ra, 4($sp)
    lw $s0, 0($sp)
    addi $sp, $sp, 8
    
    j exit_program     # Exit program after error

# Modified validate_parameter routine
validate_parameter:
    # Load parameter values
    lw $t0, N          # Image size
    lw $t1, M          # Kernel size
    lw $t2, padding    # Padding value
    lw $t3, stride     # Stride value
    
    # Calculate padded size
    mul $t2, $t2, 2        # padding * 2
    add $t4, $t0, $t2      # N_padded = N + padding*2
    sw $t4, N_padded
    
    # Check N -> [3;7]
    blt $t0, 3, invalid_parameter
    bgt $t0, 7, invalid_parameter
    
    # Check M -> [2;4]
    blt $t1, 2, invalid_parameter
    bgt $t1, 4, invalid_parameter
    
    lw $t2, padding        # Load original padding
    move $t5, $t2          # Store original padding in $t5
    mul $t2, $t2, 2        # padding * 2
    add $t4, $t0, $t2      # N_padded = N + padding * 2
    sw $t4, N_padded
    
    # Check padding -> [0;4]
    blt $t5, 0, invalid_parameter
    bgt $t5, 4, invalid_parameter
    
    # Check stride -> [1;3]
    blt $t3, 1, invalid_parameter
    bgt $t3, 3, invalid_parameter
    
    # Check N_padded >= M (kernel)
    blt $t4, $t1, invalid_parameter
    
    jr $ra          # Return if all validations pass

invalid_parameter:
    j write_error_to_file   # Jump to error handling routine
				
#==========================================================
# HÀM TÍNH TÍCH CH?P (CONVOLUTION)
convolution:
    # Luu d?a ch? tr? v?
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    # Tính toán kích thu?c ma tr?n dã padding và ma tr?n d?u ra
    jal calculate_padded_size

    # Thêm padding vào ma tr?n ?nh g?c
    jal pad_matrix

    # Th?c hi?n phép tích ch?p
    jal perform_convolution

    # Khôi ph?c d?a ch? tr? v? và k?t thúc
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# Hàm tính kích thu?c ma tr?n dã padding và ma tr?n d?u ra
calculate_padded_size:
    # Tính kích thu?c ma tr?n dã padding: N_padded = N + 2p
    lw   $t0, N
    lw   $t1, padding
    mul  $t2, $t1, 2         # 2 * padding
    add  $t2, $t0, $t2       # N + 2p
    sw   $t2, N_padded       # Luu kích thu?c ma tr?n dã padding

    # Tính kích thu?c ma tr?n d?u ra: output_size = ((N_padded - M) / stride) + 1
    lw   $t3, M
    sub  $t4, $t2, $t3       # N_padded - M
    lw   $t5, stride
    div  $t4, $t5            # (N_padded - M) / stride
    mflo $t4
    addi $t4, $t4, 1         # + 1
    sw   $t4, output_size    # Luu kích thu?c ma tr?n d?u ra
    jr   $ra

# Hàm thêm padding vào ma tr?n ?nh g?c
pad_matrix:
    # L?y các kích thu?c c?n thi?t
    lw   $t0, N              # Kích thu?c ma tr?n g?c
    lw   $t1, padding        # Kích thu?c padding
    lw   $t2, N_padded       # Kích thu?c ma tr?n dã padding

    # Xóa d? li?u ma tr?n dã padding (gán t?t c? b?ng 0)
    la   $t3, image_padded
    mul  $t4, $t2, $t2       # T?ng s? ph?n t? trong ma tr?n dã padding
    li   $t5, 0              # B? d?m
    l.s  $f0, zero_f         # Giá tr? 0.0 (float)
pad_clear_loop:
    beq  $t5, $t4, pad_copy_original
    s.s  $f0, ($t3)
    addi $t3, $t3, 4
    addi $t5, $t5, 1
    j    pad_clear_loop

pad_copy_original:
    # Sao chép ma tr?n ?nh g?c vào ma tr?n dã padding
    la   $t3, image          # Ma tr?n ngu?n (?nh g?c)
    la   $t4, image_padded   # Ma tr?n dích (sau padding)

    # Tính v? trí b?t d?u trong ma tr?n dã padding
    mul  $t5, $t1, $t2       # padding * N_padded
    mul  $t5, $t5, 4         # Chuy?n thành bytes
    add  $t4, $t4, $t5       # Chuy?n d?n dòng d?u tiên sau padding

    # Thêm offset padding c?t
    mul  $t5, $t1, 4         # padding * 4 bytes
    add  $t4, $t4, $t5       # Chuy?n d?n c?t d?u tiên sau padding

    li   $t5, 0              # B? d?m hàng
pad_copy_row_loop:
    beq  $t5, $t0, pad_done_out 
    li   $t6, 0              # B? d?m c?t
pad_copy_col_loop:
    beq  $t6, $t0, pad_next_row

    # Sao chép ph?n t?
    l.s  $f0, ($t3)
    s.s  $f0, ($t4)

    addi $t3, $t3, 4         # Ph?n t? ti?p theo c?a ma tr?n ngu?n
    addi $t4, $t4, 4         # Ph?n t? ti?p theo c?a ma tr?n dích
    addi $t6, $t6, 1         # Tang ch? s? c?t
    j    pad_copy_col_loop

pad_next_row:
    # Tính offset d? chuy?n d?n dòng ti?p theo
    sub  $t7, $t2, $t0       # N_padded - N
    mul  $t7, $t7, 4         # Chuy?n thành bytes
    add  $t4, $t4, $t7       # Thêm offset padding
    addi $t5, $t5, 1         # Tang ch? s? hàng
    j    pad_copy_row_loop

pad_done_out :
    jr   $ra

# Hàm th?c hi?n phép tích ch?p
perform_convolution:
    # Kh?i t?o các thanh ghi
    lw   $s0, N_padded       # Kích thu?c ma tr?n dã padding
    lw   $s1, M              # Kích thu?c kernel
    lw   $s2, stride         # Giá tr? stride
    lw   $s3, output_size    # Kích thu?c ma tr?n d?u ra

    la   $s4, image_padded   # Ð?a ch? ma tr?n dã padding
    la   $s5, kernel         # Ð?a ch? ma tr?n kernel
    la   $s6, output         # Ð?a ch? ma tr?n k?t qu?

    li   $t0, 0              # B? d?m hàng c?a ma tr?n d?u ra
conv_row_loop:
    beq  $t0, $s3, conv_done
    li   $t1, 0              # B? d?m c?t c?a ma tr?n d?u ra
conv_col_loop:
    beq  $t1, $s3, conv_next_row

    # Tính tích ch?p cho v? trí này
    l.s  $f0, zero_f         # T?ng = 0.0
    li   $t2, 0              # Ch? s? hàng kernel

conv_kernel_row:
    beq  $t2, $s1, conv_store_result
    li   $t3, 0              # Ch? s? c?t kernel

conv_kernel_col:
    beq  $t3, $s1, conv_next_kernel_row

    # Tính v? trí m?i:
    mul  $t4, $t0, $s2       # Hàng = output_row * stride
    add  $t4, $t4, $t2       # + kernel_row
    mul  $t4, $t4, $s0       # * N_padded

    mul  $t5, $t1, $s2       # C?t = output_col * stride
    add  $t5, $t5, $t3       # + kernel_col
    
    add  $t6, $t4, $t5       # offset = hàng + c?t
    mul  $t6, $t6, 4         # Chuy?n thành offset bytes
    add  $t6, $t6, $s4       # Ð?a ch? th?c trong ma tr?n dã padding

    # Ð?a ch? ph?n t? kernel
    mul  $t7, $t2, $s1       # kernel_row * kernel_width
    add  $t7, $t7, $t3       # kernel_row * kernel_width + kernel_col
    mul  $t7, $t7, 4
    add  $t7, $t7, $s5       # Ð?a ch? th?c trong kernel

    # L?y giá tr? và th?c hi?n nhân + c?ng
    l.s  $f1, ($t6)          # Giá tr? t? ma tr?n dã padding
    l.s  $f2, ($t7)          # Giá tr? t? kernel
    mul.s $f1, $f1, $f2      # Nhân hai giá tr?
    add.s $f0, $f0, $f1      # C?ng vào t?ng

    addi $t3, $t3, 1         # C?t kernel ti?p theo
    j    conv_kernel_col

conv_next_kernel_row:
    addi $t2, $t2, 1         # Hàng kernel ti?p theo
    j    conv_kernel_row

conv_store_result:
    # Luu k?t qu? vào ma tr?n d?u ra
    mul  $t4, $t0, $s3       # Hàng * width
    add  $t4, $t4, $t1       # Hàng * width + c?t
    mul  $t4, $t4, 4         # Chuy?n thành offset bytes
    add  $t4, $t4, $s6       # Ð?a ch? th?c trong ma tr?n k?t qu?
    s.s  $f0, ($t4)

    addi $t1, $t1, 1         # C?t ma tr?n d?u ra ti?p theo
    j    conv_col_loop

conv_next_row:
    addi $t0, $t0, 1         # Hàng ma tr?n d?u ra ti?p theo
    j    conv_row_loop

conv_done:
    jr   $ra

#===========================================
#HÀM GHI OUTPUT VÀO FILE 
write_output:
    # Save registers
    addi $sp, $sp, -28
    sw $ra, 24($sp)
    sw $s0, 20($sp)
    sw $s1, 16($sp)
    sw $s2, 12($sp)
    sw $s3, 8($sp)
    sw $s4, 4($sp)
    sw $s5, 0($sp)

    # Open file
    li $v0, 13
    la $a0, output_file
    li $a1, 1          # Write mode
    li $a2, 0          # Mode (ignored)
    syscall
    move $s0, $v0      # Save file descriptor

    # Check for errors
    bltz $s0, write_error

    # Get matrix size
    lw $s1, output_size
    li $s2, 0          # Row counter

outer_loop:
    beq $s2, $s1, write_done
    li $s3, 0          # Column counter

inner_loop:
    beq $s3, $s1, next_row_out

    # Calculate offset: row * size + col
    mul $t0, $s2, $s1  # row * size
    add $t0, $t0, $s3  # + column
    sll $t0, $t0, 2    # * 4 (float size)

    # Get float value
    la $t1, output
    add $t1, $t1, $t0
    l.s $f12, ($t1)

    # Prepare string buffer
    la $s4, float_string

    # Add 1 leading space for separation between columns
    li $t5, 32         # ASCII space
    sb $t5, ($s4)
    addi $s4, $s4, 1

    # Check if negative
    mtc1 $zero, $f0
    c.lt.s $f12, $f0
    bc1f positive_number
    li $t4, 45         # ASCII '-'
    sb $t4, ($s4)
    addi $s4, $s4, 1

positive_number:
    # Convert float to integer part
    abs.s $f12, $f12   # Work with absolute value
    trunc.w.s $f0, $f12
    mfc1 $s5, $f0      # Save integer part

    # Count digits in integer part
    move $t2, $s5
    li $t3, 0          # Digit counter
    li $t4, 10         # For division

    # Handle zero case
    bnez $t2, count_digits
    li $t3, 1
    j store_digits

count_digits:
    div $t2, $t4
    mflo $t2
    addi $t3, $t3, 1
    bnez $t2, count_digits

store_digits:
    move $t2, $s5      # Integer value
    li $t4, 10         # For division
    add $t7, $s4, $t3  # Calculate end position
    addi $t7, $t7, -1  # Adjust for 0-based index
    move $s4, $t7      # Move pointer to end

store_loop:
    div $t2, $t4
    mfhi $t5           # Remainder (current digit)
    mflo $t2           # Quotient for next iteration
    addi $t5, $t5, 48  # Convert to ASCII
    sb $t5, ($s4)      # Store digit
    addi $s4, $s4, -1  # Move backward
    bnez $t2, store_loop

    addi $s4, $t7, 1   # Move pointer after number

    # Add decimal point
    li $t5, 46         # ASCII '.'
    sb $t5, ($s4)
    addi $s4, $s4, 1

    # Process decimal part
    cvt.w.s $f0, $f12
    cvt.s.w $f0, $f0
    sub.s $f0, $f12, $f0  # Get decimal part
    abs.s $f0, $f0
    l.s $f2, ten_f        # Load 10.0
    li $t4, 4             # 4 decimal places

decimal_loop:
    mul.s $f0, $f0, $f2
    trunc.w.s $f3, $f0
    mfc1 $t5, $f3
    addi $t5, $t5, 48     # Convert to ASCII
    sb $t5, ($s4)
    addi $s4, $s4, 1
    cvt.s.w $f3, $f3
    sub.s $f0, $f0, $f3
    addi $t4, $t4, -1
    bnez $t4, decimal_loop

    # Add spaces to ensure fixed width (total width of 12 characters)
    li $t6, 12            # Total desired width
    la $t7, float_string  # Start of string
    sub $t8, $s4, $t7     # Current length
    sub $t6, $t6, $t8     # Required padding
    
pad_spaces:
    beqz $t6, write_number
    li $t5, 32            # ASCII space
    sb $t5, ($s4)
    addi $s4, $s4, 1
    addi $t6, $t6, -1
    j pad_spaces

write_number:
    # Write to file
    li $v0, 15
    move $a0, $s0         # File descriptor
    la $a1, float_string  # String buffer
    sub $a2, $s4, $a1     # Calculate length
    syscall

    addi $s3, $s3, 1      # Next column
    j inner_loop

next_row_out:
    # Add newline
    li $v0, 15
    move $a0, $s0
    la $a1, newline
    li $a2, 1
    syscall

    addi $s2, $s2, 1      # Next row
    j outer_loop

write_error:
    li $v0, 4
    la $a0, write_error_msg
    syscall
    j write_exit

write_done:
    # Close file
    li $v0, 16
    move $a0, $s0
    syscall

write_exit:
    # Restore registers
    lw $ra, 24($sp)
    lw $s0, 20($sp)
    lw $s1, 16($sp)
    lw $s2, 12($sp)
    lw $s3, 8($sp)
    lw $s4, 4($sp)
    lw $s5, 0($sp)
    addi $sp, $sp, 28
    jr $ra
# ===========================================================================================================================================								
# Hàm thoát chuong trình
exit_program:
	li $v0, 10			# System call 10: Exit program
	syscall