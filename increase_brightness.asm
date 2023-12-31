.data
    # File locations
    input_file: .asciiz "C:\\Users\\qaila\\Downloads\\BHMQAI001_Arch\\Images\\house_64_in_ascii_lf.ppm"
    output_file: .asciiz "C:\\Users\\qaila\\Downloads\\BHMQAI001_Arch\\output.txt"
    buffer:  .space 256     # Stores line from the file

.text

.globl main

main:
    # Open input_file 
    li $v0, 13          # Opens file
    la $a0, input_file
    li $a1, 0            
    syscall

    move $s0, $v0       # Stores in $s0

    # Opens output_file 
    li $v0, 13          # Opens file
    la $a0, output_file
    li $a1, 1            
    syscall

    move $s1, $v0       # Stores in $s1

    jal read_header	# Jumps to function to read header 

    # Loads in colour variables
    li $t0, 0            # Red
    li $t1, 0            # Green
    li $t2, 0            # Blue

    # Loops through pixels
    li $t3, 0            # Pixel counter

pixel_loop:
    jal read_pixel	# Reads RGB values from input_file

    # Increases brightness for each colour value by 10
    addi $t4, $t4, 10    # Red
    addi $t5, $t5, 10    # Green
    addi $t6, $t6, 10    # Blue

    # Clamps values to 255
    li $t7, 255
    slt $t8, $t4, $t7    # Red
    movn $t4, $t7, $t8   

    slt $t8, $t5, $t7    # Green
    movn $t5, $t7, $t8   

    slt $t8, $t6, $t7    # Blue
    movn $t6, $t7, $t8   

    jal write_pixel	 # Write the updated RGB values to the output file

    # Update total colour values
    add $t0, $t0, $t4
    add $t1, $t1, $t5
    add $t2, $t2, $t6

    # Check if we've processed all pixels
    li $t7, 4096          # Total pixels = 64 x 64
    beq $t3, $t7, exit    # Exit if correct

    addi $t3, $t3, 1	  # Increment pixel counter
    j pixel_loop

exit:
    # Averages RGB values
    li $t7, 4096          # Total pixels = 64 x 64
    div $t0, $t7          # Average Red value
    mflo $t0

    div $t1, $t7          # Average Green value
    mflo $t1

    div $t2, $t7          # Average Blue value
    mflo $t2

    # Convert averages to type double
    mtc1 $t0, $f0   # Red
    mtc1 $t1, $f1   # Green
    mtc1 $t2, $f2   # Blue

    li $v0, 2     # Displays averages
     syscall

    li $v0, 16            # Closes files
    move $a0, $s0        

    syscall
    move $a0, $s1         
    syscall

    # Exit  program
    li $v0, 10            # Exit
    syscall

read_header:
    li $t4, 0            # Stores columns
    li $t5, 0            #  Stores Rows
    li $t6, 0            # Stores max

read_header_loop:
    li $v0, 14           # Read
     move $a0, $s0       
    la $a1, buffer       # Stores read line into buffer
    li $a2, 256          # Max line

    syscall

    lb $t7, buffer      # Loads first letter of line
    beq $t7, 35, skip_comment  

    beq $t4, 0, read_dimensions	# Reads dimensions of line
    beq $t4, 1, read_max_value
    j header_exit

read_dimensions:
    li $t4, 1            
    j read_header_loop

read_max_value:
    j read_header_loop

skip_comment:
    # SFunction to skip the comment line
    j read_header_loop

header_exit:
    jr $ra

read_pixel:
    # Reads RGB values from input_file
    li $v0, 14           # Reads string
    move $a0, $s0        
    la $a1, buffer       # Stores line
    li $a2, 256          # Max line length
    syscall

    # Runs through line for RGB values
    li $t4, 0            # Red value
    li $t5, 0            # Green value
    li $t6, 0            # Blue value
    li $t8, 0            

read_pixel_loop:
    lb $t7, buffer($t8)  # Loads character from buffer
    #beqz $t7, pixel_runthrough 

    sub $t7, $t7, 48     # Convert ascii character to int
 # Updates values
    beq $t8, 0, update_red	
    beq $t8, 1, update_green
    beq $t8, 2, update_blue
    j read_pixel_loop

update_red:
    mul $t4, $t4, 10     # Multiply by 10
    add $t4, $t4, $t7    # Update
    j read_pixel_loop

update_green:
    mul $t5, $t5, 10     # Multiply by 10
    add $t5, $t5, $t7    # Update

    j read_pixel_loop

update_blue:
    mul $t6, $t6, 10     # Multiply by 10
    add $t6, $t6, $t7    # Update
    j read_pixel_loop

#pixel_runthrough:
#   jr $ra

write_pixel:
    # Convert RGB values to string
    move $a0, $t4        # R value
    move $a1, $t5        # G value
    move $a2, $t6        # B value
    jal int_to_string

    # Writes RGB string to output_file
    move $a0, $s1        
    move $a1, $t7        # Stores RGB string

    li $v0, 4            
    syscall

    # Newline to separate pixels
    li $v0, 11           # Prints characters
    li $a0, 10           
    syscall

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

    beq $a1, $t3, int_to_string_reverse_exit	# Checks for  middle of string
    j int_to_string_reverse_loop

int_to_string_reverse_exit:
    jr $ra
