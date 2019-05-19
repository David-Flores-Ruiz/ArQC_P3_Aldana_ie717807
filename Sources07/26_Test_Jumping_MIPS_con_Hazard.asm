.text
  addi $s0, $zero, 2
  addi $s1, $zero, 7
  addi $t0, $zero, 0
  addi $t1, $zero, 4
  addi $t0, $zero, 2
  
  nop
  nop
  beq $s0, $t1, TARGET		# Debería brincar
  
  addi $t3, $zero, 6
  addi $t4, $zero, 6
  addi $t5, $zero, 6
  
TARGET:
  addi $t3, $zero, 3
  addi $t4, $zero, 4
  addi $t5, $zero, 5
  
 FIN: addi $t6, $zero, 0xFF
