.data
    	input_file: .asciiz "C:\\Users\\qaila\\Downloads\\BHMQAI001_Arch\\Images\\house_64_in_ascii_lf.ppm"
    	output_file: .asciiz "C:\\Users\\qaila\\Downloads\\BHMQAI001_Arch\\output.ppm"
    	buffer: .space 256     # Stores line from the file
	p2_header:  .asciiz "P2\n"  # P2 format header
	#buffer2: .space 500

.text
.globl main

main:
    # Opens input_file
    li $v0, 13           # Opens file
    la $a0, input_file
    li $a1, 0            
    syscall

    move $s0, $v0        # Stores in $s0

    # Opens output file
    li $v0, 13           # Opens file
    la $a0, output_file
    li $a1, 1            
    syscall

    move $s1, $v0        # Stores in $s1

    jal read_header

    # Writes P2 header (for greyscale)
    li $v0, 4
    la $a0, p2_header
    syscall

    jal convert_pixels

    li $v0, 16            # Closes files
    move $a0, $s0  
       
    syscall

    move $a0, $s1        
    syscall

    # Exit program
    li $v0, 10            
    syscall

# Reads header of input_file
read_header:
    # Initialises variables
    li $t4, 0            # Stores columns
    li $t5, 0            #  Stores rows
    li $t6, 0            # Stores max value

read_header_loop:
    # Reads line from input_file
    li $v0, 14           # Read
    move $a0, $s0        
    la $a1, buffer       # Stores read line into buffer
     li $a2, 256         # Max length ofline 
    syscall

    lb $t7, buffer      # Loads first letter of line
    beq $t7, 35, skip_comment  # 35 is the number for ascii '#'

    beq $t4, 0, read_dimensions	# Reads dimensions of line
    beq $t4, 1, read_max_value
    j header_exit

read_dimensions:
    li $t4, 1            
    j read_header_loop

read_max_value:
    j read_header_loop

 skip_comment:
    j read_header_loop

header_exit:
    jr $ra

# Converts RGB values to greyscale 
convert_to_greyscale:
    divu $t9, $t9, 3  # Divide by 3 to get average
    jr $ra

# Converts pixel values to greyscale
convert_pixels:
    li $t3, 0            # counter

pixel_loop:
    # Reads RGB values from input_file as specified
    li $v0, 14

    move $a0, $s0
    la $a1, buffer
    li $a2, 256
    syscall

    jal RGB_runthrough
    jal convert_to_greyscale

    # Convert greyscale pixel value to string
    move $a0, $t9        # Greyscale pixel value
    jal int_to_string

    # Writes greyscale pixel values to output_file
    li $v0, 4
    move $a0, $s1
    move $a1, $t7
    syscall

    # Writes ixels on separate lines
    li $v0, 11           # Print character
    li $a0, 10           # ASCII code for newline character
    syscall

    li $t7, 4096          # Total pixels = 64 x 64
    beq $t3, $t7, exit    # Exit if correct

    addi $t3, $t3, 1	# Increment pixel counter
    j pixel_loop

exit:
    jr $ra

# Runs through RGB values from each line in input_file
RGB_Runthrough:
    lb $t2, buffer
    lb $t3, buffer+3
    lb $t4, buffer+6

    # ascii to int conversion
    sub $t2, $t2, 48
    sub $t3, $t3, 48
    sub $t4, $t4, 48

    # Pixel values
    li $t5, 100  # Red
    li $t6, 10   # Green
    li $t7, 1    # Blue

	# Scaling
    mul $t2, $t2, $t5
    mul $t3, $t3, $t6
    mul $t4, $t4, $t7
    add $t9, $t2, $t3
    add $t9, $t9, $t4

    jr $ra

# Conversion of int to string
int_to_string:
    # Initialise variables
    li $t8, 10            
    move $t9, $a0         
    li $t0, 0 

int_to_string_loop:
    div $t9, $t8
    mfhi $t1         # Remainder stored in $t1

    addi $t1, $t1, 48	# Convert to ascii     
    sb $t1, ($a1)       # store in string

    addi $a1, $a1, 1

    beqz $t9, int_to_string_exit

    # Update for next loop
    move $t9, $t0

    j int_to_string_loop

int_to_string_exit:
    li $t2, 0
    sb $t2, ($a1)

    # Reverse string in place
    move $t3, $a1         
    addi $t3, $t3, -1      

int_to_string_reverse_loop:
    # Reverses order of characters in string for display
    lb $t1, ($a1)
    lb $t4, ($t3)
    sb $t4, ($a1)
    sb $t1, ($t3)

    addi $a1, $a1, 1
    addi $t3, $t3, -1

    beq $a1, $t3, int_to_string_reverse_exit	# Checks for middle of string
    j int_to_string_reverse_loop

int_to_string_reverse_exit:
    jr $ra



