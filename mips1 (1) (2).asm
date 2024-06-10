.data
	infix: .space 100
	postfix: .space 800
	operator: .space 800
	endMsg: .asciiz "Click Yes to continue"
	bye: .asciiz "Thank you for using me"
	errorMsg: .asciiz "Input Error"
	invalidMsg: .asciiz "Invalid Result"
	startMsg: .asciiz "Enter infix expression\nNote: only allowed to use + - * / ^ ! () .  \n"
	prompt_postfix: .asciiz "\nPostfix expression: "
	prompt_result: .asciiz "Result: "
	prompt_infix: .asciiz "\nInfix expression: "
	converter: .word 1
	wordToConvert: .word 1
	zero: .float 0.0
	quit: .asciiz "quit"
	result: .float 0.0
	minimumFactorial: .float 1.0
	minimumExponential: .float 1.0
	filename: .asciiz "calc_log.txt"   # File name
	newline: .asciiz "\n"         # New line character
	valueM: .float 0.0

.text
setup: 
	l.s $f10, valueM   #luu gia tri M
start:
	li $v0,54
	la $a0,startMsg
	la $a1,infix
	la $a2,100
	syscall 
	
	#print Infix
	li $v0, 4
	la $a0, prompt_infix
	syscall
	li $v0, 4
	la $a0, infix
	syscall
	li $v0, 11
	li $a0, '\n'
	syscall
	la $a0, infix
	
	#########RESET########
	la $a0, infix
	la $s2, postfix    #Allocates an stack with 200 elements, đây là stack lưu trữ các giá trị tính toán được sau mỗi lần tính.
	la $s3, operator   #allocates an stack with 200 elements, đây la stack lưu trữ các phép toán (+,-,*,/,())
	l.s $f3, zero       #Toan hang 1 cua phep toan
	l.s $f4, zero 	   #Toan hang 2 cua phep toan
	li $t3, 0	   #Toan Tu
	jal resetNumber
	l.s $f3, zero       #Toan hang 1 cua phep toan
	l.s $f4, zero 	   #Toan hang 2 cua phep toan
	li $t3, 0	   #Toan Tu
	li $t5,-4 #postfix top offset
	li $t6,-4 #infix top offset
	li $s1, 0 #đây là số lượng dấu () ưu tiên, sẽ có $s1-1 số lượng () lồng nhau.
	li $s7,0 #Status
scanInf:
	lb $t4,0($a0)
	addi $a0,$a0,1
	beq $t4,' ',scanInf
	beq $t4, '\n', EOF
	j checkInvalidChar
	getNum:
		jal isNum   
		j checkNumber		
	getOpt: 
		beq $s7, 6, continue_getOpt
		beq $s7, 4, continue_getOpt
		jal sumDigit
		continue_getOpt:
		jal isOpt
		jal resetNumber
		j checkOperation
	getM:
		jal isMvalue
		mov.s $f0, $f10
		jal pushPostfix 
		j scanInf
	getDot:
		j foundDot
	getFrac:
		beq $s7, 4, continue_getFrac
		jal sumDigit
		continue_getFrac: 
		jal isFrac
		j checkOperation
	getExp:
		jal isExp
		jal sumDigit
		jal resetNumber
		j checkOperation
	getOBrak:
		addi $s1, $s1, 1
		jal isOBrak
		j checkOperation
	getCBrak:
		subi $s1, $s1, 1
		jal sumDigit
		jal resetNumber
		jal isCBrak
		j checkOperation

checkInvalidChar:
	beq $t4, '(', getOBrak
	beq $t4, ')', getCBrak
	beq $t4, 'M', getM
	beq $t4, '.', getDot
	beq $t4, '!', getFrac
	beq $t4, '^', getExp	
	bgt $t4, '9', wrongInput
	blt $t4, '(', wrongInput
	blt $t4,'0',getOpt
	bge $t4,'0',getNum
	
								
																								
printResult:
	li $v0, 4
	la $a0, prompt_result
	syscall
	li $v0, 2
	mov.s $f12, $f0
	syscall



ask: 			# Ask user to continue or not
 	li $v0, 50
 	la $a0, endMsg
 	syscall
 	beq $a0,0,start
 	beq $a0,2,ask	
end:
 	li $v0, 55
 	la $a0, bye
 	li $a1, 1
 	syscall
 	li $v0, 10
 	syscall
    	
EOF: 	
	bne $s7, 1, notNumber #the last digit is not a number
	jal sumDigit
	notNumber:
	j getAllOperator

invalidValue: # When detect the false caculate ( '0^x', 'x/0', '0!' , '-x!' : x is a number)
	li $v0, 55
 	la $a0, invalidMsg
 	li $a1, 2
 	syscall
	j ask	 	
wrongInput:	# When detect wrong input situation
	li $v0, 55
 	la $a0, errorMsg
 	li $a1, 2
 	syscall
	j ask	
	

isNum:
	beq $s7, 4, wrongInput # ')1' 
	beq $s7, 5, wrongInput # '!1'
	li $s7, 1
	jr $ra
isNothing:
	li $s7, 0
	jr $ra
isOpt:
	beq $s7, 2, wrongInput # '++'
	beq $s7, 3, wrongInput # '(+'
	beq $s7, 7, wrongInput # '^+'
	li $s7, 2
	jr $ra
isOBrak:
	beq $s7,5, wrongInput	# '!('
	beq $s7,1, wrongInput	# '1('
	beq $s7,4, wrongInput  	#')('
	li $s7,3
	jr $ra
isCBrak:
	beq $s7,5, wrongInput 	# '!)'
	beq $s7,7, wrongInput 	# '^)'
	beq $s7,2, wrongInput	# '+)'
	beq $s7,3, wrongInput 	# '()
	blt $s1,0, wrongInput 	# '(x))'
	li $s7,4 
	jr $ra
isFrac:
	beq $s7, 2, wrongInput # '+!"
	beq $s7, 3, wrongInput # '(!'
	beq $s7, 7, wrongInput # '^!'
	li $s7,5
	jr $ra
isMvalue:
	beq $s7, 1, wrongInput #'1M'
	beq $s7, 4, wrongInput #')M' 
	beq $s7, 5, wrongInput #'!M'
	li $s7,6
	jr $ra
isExp:
	beq $s7, 2, wrongInput # '+^'
	beq $s7,5, wrongInput # '!^'
	beq $s7,3, wrongInput # '(^'
	li $s7,7
	jr $ra
###########################MATH OPERATIONS##############################
pushOperator: #thêm phần tử vào stack Operator
	addi $t6,$t6,4			# Increment top of Operator offset
	add $t8,$t6,$s3			# Load address of top Operator  = the current address of operator  + 1
	sb $t4,($t8)			# Set the value of current point to the value of $t8
	j scanInf
popOperator: #xóa phần tử ở stack Operator
	subi $t6,$t6,4
	add $t8,$t6,$s3
	jr $ra

getTopOperator: #lấy giá trị đầu tiên của stack Operator
	add $t8, $t6, $s3
	lb $t3, ($t8)
	jr $ra
	
	
getAllOperator: #Duyệt và lấy từng operator để tính toán
	beq $t6, -4, endGetAll
	jal getTopOperator
	jal popOperator
	jal getCaculate
	j getAllOperator
	endGetAll:
		mov.s $f10, $f0
		bne $s1, 0, wrongInput # '(()', '())' 
		j printResult
		j ask
											
checkOperation: #check operation to set priority '()' > '!' > '^' > '*,/' > '+,-
	jal getTopOperator
	beq $t4,'+', add_sub_priority
	beq $t4,'-', add_sub_priority
	beq $t4,'*', mul_div_priority
	beq $t4,'/', mul_div_priority
	beq $t4,'^', exp_priority
	beq $t4,'!', frac_priority
	beq $t4,'(', obraket_priority
	beq $t4,')', cbraket_priority
	
add_sub_priority:
 	beq $t3,'(', pushOperator
	jal getCaculate
	jal popOperator
	j pushOperator
	
mul_div_priority:
 	beq $t3,'(', pushOperator
	beq, $t3, '+', pushOperator
	beq, $t3, '-', pushOperator
	jal getCaculate
	jal popOperator
	j pushOperator
	
exp_priority:
	beq $t3,'(', pushOperator
	beq, $t3, '+', pushOperator
	beq, $t3, '-', pushOperator
	beq, $t3, '*', pushOperator
	beq, $t3, '/', pushOperator
	jal getCaculate
	jal popOperator
	j pushOperator

frac_priority:
	li $a2, '!'
	la $t3, ($a2)
	jal getCaculate

		
obraket_priority:
	j pushOperator
		
cbraket_priority:
	j getAllOperator
	
getCaculate: #check operation to call the math operation
	beq $t3,'+', addition
	beq $t3,'-', subtraction
	beq $t3,'*', multiplication
	beq $t3,'/', division
	beq $t3,'^', exponent
	beq $t3,'!', factorization
	beq $t3,'(', parenthesesOpen
	beq $t3,')', parenthesesClose
	j pushOperator #không nhận được dữ liệu tức không có phần tử nào bên trong
	
addition: 
	#Get 2 operaters $f3: op1, $$f4: op2
	add $t8,$t5,$s2             	
	l.s $f4, ($t8)
	#pop
	subi $t5,$t5,4  
	               
	add $t8,$t5,$s2
	l.s $f3, ($t8)
	#pop
	subi $t5,$t5,4                 

	
	add.s $f0, $f3, $f4
	addi $t5,$t5,4                  #Increment top of Postfix offset
	add $t8,$t5,$s2	                #load address of top postfix = offset + base		
	s.s $f0,($t8)			# Store number of current point into Postfix's value
	jr $ra
	
	
subtraction:
	#Get 2 operaters $f3: op1, $$f4: op2
	add $t8,$t5,$s2             	
	l.s $f4, ($t8)
	#pop
	subi $t5,$t5,4    
	             
	add $t8,$t5,$s2
	l.s $f3, ($t8)
	#pop
	subi $t5,$t5,4                 

	
	sub.s $f0, $f3, $f4
	addi $t5,$t5,4                  #Increment top of Postfix offset
	add $t8,$t5,$s2	                #load address of top postfix = offset + base		
	s.s $f0,($t8)			# Store number of current point into Postfix's value
	jr $ra

multiplication:
	#Get 2 operaters $f3: op1, $$f4: op2
	add $t8,$t5,$s2             	
	l.s $f4, ($t8)
	#pop
	subi $t5,$t5,4                 
	add $t8,$t5,$s2
	l.s $f3, ($t8)
	#pop
	subi $t5,$t5,4                 

	
	mul.s $f0, $f3, $f4
	addi $t5,$t5,4                  #Increment top of Postfix offset
	add $t8,$t5,$s2	                #load address of top postfix = offset + base		
	s.s $f0,($t8)			# Store number of current point into Postfix's value
	jr $ra

division:
	#Get 2 operaters $f3: op1, $$f4: op2
	add $t8,$t5,$s2             	
	l.s $f4, ($t8)
	#pop
	subi $t5,$t5,4                 
	add $t8,$t5,$s2
	l.s $f3, ($t8)
	#pop
	subi $t5,$t5,4                 

	
	div.s $f0, $f3, $f4
	addi $t5,$t5,4                  #Increment top of Postfix offset
	add $t8,$t5,$s2	                #load address of top postfix = offset + base		
	s.s $f0,($t8)			# Store number of current point into Postfix's value
	jr $ra
	
factorization:
	#Get 2 operaters $f3: op1, $$f4: op2
	add $t8,$t5,$s2	               		
	l.s $f4, ($t8)		
	jal popPostfix
	l.s $f31, zero
	c.eq.s $f4, $f31
	bc1t invalidValue
	
	jal factorial
	jal pushPostfix 
	j scanInf
	
	factorial:
		l.s $f2, minimumFactorial
		c.le.s $f4, $f2
		bc1t endfactorial
		mov.s $f1, $f4
		factorial_loop:
	   	 	sub.s $f1, $f1, $f2
	    		mul.s $f4, $f4, $f1
	    		c.le.s $f1, $f2
	    		bc1t endfactorial
	    		j factorial_loop
		endfactorial:
	    		mov.s $f0, $f4 
	    		jr $ra

exponent:
	#Get 2 operaters $f3: op1, $$f4: op2
	add $t8,$t5,$s2             	
	l.s $f4, ($t8)
	#pop
	subi $t5,$t5,4                 
	add $t8,$t5,$s2
	l.s $f3, ($t8)
	#pop
	subi $t5,$t5,4     
	
	l.s $f31, zero
	c.eq.s $f3, $f31
	bc1t invalidValue
	
	c.eq.s $f4, $f31
	bc1t exponentialWithZero

	exponential:
		l.s $f2, minimumExponential
		mov.s $f5, $f3
		c.eq.s $f4, $f2
		bc1t endexponential
		exponential_loop:
			sub.s $f4, $f4, $f2
			mul.s $f5,$f5,$f3
			c.eq.s $f4,$f2
			bc1t endexponential
			j exponential_loop
		endexponential:
			mov.s $f0, $f5
			addi $t5,$t5,4                  #Increment top of Postfix offset
			add $t8,$t5,$s2	                #load address of top postfix = offset + base		
			s.s $f0,($t8)			# Store number of current point into Postfix's value
		 	jr $ra
		exponentialWithZero: 
			l.s $f5, minimumExponential
			mov.s $f0, $f5
			addi $t5,$t5,4                  #Increment top of Postfix offset
			add $t8,$t5,$s2	                #load address of top postfix = offset + base		
			s.s $f0,($t8)			# Store number of current point into Postfix's value
			jr $ra

parenthesesOpen:
	j scanInf
parenthesesClose:
	j getAllOperator	


#################################NUMBER##############################
pushPostfix: #thêm phần tử vào stack postfix
	addi $t5,$t5,4                  #Increment top of Postfix offset
	add $t8,$t5,$s2	                #load address of top postfix = offset + base		
	s.s $f0,($t8)			# Store number of current point into Postfix's value
	jr $ra
	
popPostfix:   #xóa phần tử ở stack Postfix
	subi $t5,$t5,4                 
	add $t8,$t5,$s2
	jr $ra
	
																																	
																																				
checkNumber:
	beq $t4,'0',storeDigit
	beq $t4,'1',storeDigit
	beq $t4,'2',storeDigit
	beq $t4,'3',storeDigit
	beq $t4,'4',storeDigit
	beq $t4,'5',storeDigit
	beq $t4,'6',storeDigit
	beq $t4,'7',storeDigit
	beq $t4,'8',storeDigit
	beq $t4,'9',storeDigit
	j scanInf	

foundDot:
	bne $s7, 1, wrongInput #if the previous charecter is not a number return false
	beq $t8, 1, wrongInput #if the number have 2 or more dots return false. For example: "2.2.2 + 2".
	addi $t8, $zero, 1	
	j scanInf
				
resetNumber: 
	li $t0, 0  	# Phần nguyên
	li $t1, 0	# Phần thập phân
	li $t2, 1	# 1 / 10^($t2-1)
	li $t8, 0	# 0: not found dot, 1: found dot.
	jr $ra

storeDigit:
	beq $t8, 0, storeIntergerDigit
	beq $t8, 1, storeDemicalDigit
			
storeIntergerDigit:
	sub $t4,$t4,'0'
	mul $t0,$t0,10
	add $t0,$t0,$t4	
	j scanInf

storeDemicalDigit:
	mul $t2,$t2,10
	sub $t4,$t4, '0'
	mul $t1, $t1, 10
	add $t1,$t1,$t4		
	j scanInf

sumDigit:
	mtc1 $t0, $f0     
    	mtc1 $t1, $f1     
    	mtc1 $t2, $f2	
    	cvt.s.w $f1, $f1
    	cvt.s.w $f0, $f0
    	cvt.s.w $f2,$f2
	
	div.s $f1, $f1, $f2
	add.s $f0, $f0, $f1  
	j pushPostfix
