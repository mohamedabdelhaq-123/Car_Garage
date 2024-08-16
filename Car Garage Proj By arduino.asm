
.include "m328pdef.inc"

	.org 0x0000
	jmp main  

	.org 0x0002
	jmp Enter_Int0

	.org 0x0004
	jmp Exit_Int1


.equ Lcd_Dddr = ddrb 
.equ Lcd_Dprt = portb // data port
.equ Lcd_Cddr = ddrd  
.equ Lcd_Cprt = portd // command port
.equ Lcd_RS = 0       // register select pin 0 in portd
.equ Lcd_EN = 1
.equ Int0_Enter_Pin = 2  // in portd
.equ Int1_Exit_Pin = 3   // in portd
.equ Green_Led = 4       // in portd
.equ Red_Led  = 5        // in portd
.equ Lcd_RW = 6 

/*** portd contain interrupt , leds, command bits****/



 Main: 
    /*stack initialization*/
	ldi r30,HIGH(RAMEND)   
	out sph,r30
	ldi r30,LOW(RAMEND)
	out spl,r30

	/*LCD initialization*/
	ldi r30,0xff 
	out Lcd_Dddr,r30    // data ddr is output
	sbi Lcd_Cddr,Lcd_EN // output en pin
	cbi Lcd_Cprt,Lcd_EN // en=0
	sbi Lcd_Cddr,Lcd_RS // output rs pin
	sbi Lcd_Cddr,Lcd_RW // output rw pin
	cbi Lcd_Cprt,Lcd_RW // rw=0 for write
	call delay2ms 

	ldi R16,0x33  // 4pin
	call Command_Wrt
	call delay2ms

	ldi R16,0x32  //  4pin
	call Command_Wrt
	call delay2ms
	
	ldi R16,0x28  // lcd 2 lines 4 bit 
	call Command_Wrt
	call delay2ms

	ldi r16,0x0f  //display on,cursor blinking
	call Command_Wrt

	ldi r16,0x01 //clear display screen
	call Command_Wrt
	call delay2ms

	ldi r16,0x06  // increament cursor
    call Command_Wrt


	/*Interrupt initialization*/
	ldi r30,0    // interrupt at low
	sts eicra,r30 // eicra is out of range of sfr so use sts

	ldi r30,(1<<INT0)|(1<<int1)  // enable the external int1 & int0
	out eimsk,r30                // eimsk in sfr so use out inst.

	cbi Lcd_Cddr,Int0_Enter_Pin
	cbi Lcd_Cddr,Int1_Exit_Pin  
	sbi Lcd_Cprt,Int0_Enter_Pin //input pull up resistor
	sbi Lcd_Cprt,Int1_Exit_Pin //input pull up resistor

	/*Pins initialization*/
	sbi Lcd_Cddr,Green_Led  // pin is output
	sbi Lcd_Cddr,Red_Led    // pin is output

	sei // enable global interrupt
	ldi r20,'0'  // counter units
	ldi r23,'0'  // counter tenths
	ldi r31,0    // flag register

HERE: //check loop & green led is on

	 cpi r23,'1'
	 breq xmax
	 sbi Lcd_Cprt,Green_Led
	 cbi Lcd_Cprt,Red_Led	
	 rjmp HERE
     xmax:
	 cpi r20,'1'
  	 brne HERE
	 ldi r31,1 // set the flag to prevent from counting up than 11
	 call MaxCars
	 rjmp HERE

/************************************/

Command_Wrt:
	MOV R29,R16
	SWAP R29                 ;swap the nibbles
	OUT Lcd_Dprt,R29         ;send the high nibble
	CBI Lcd_Cprt,Lcd_RS      ;RS = 0 for command
	CBI Lcd_Cprt,Lcd_RW      ;RW = 0 for write
	SBI Lcd_Cprt,Lcd_EN      ;EN = 1 
	CALL sdelay              ;make a wide EN pulse
	CBI Lcd_Cprt,Lcd_EN      ;EN=0
	CALL delay100us          

	MOV R29,R16
	OUT Lcd_Dprt,R29       ;send the low nibble
	SBI Lcd_Cprt,Lcd_EN    ;EN = 1 
	CALL sdelay            ;make a wide EN pulse
	CBI Lcd_Cprt,Lcd_EN    ;EN=0 
	CALL delay100us        ;wait 100 us
	RET

	Data_Wrt:
	MOV R29,R16
	SWAP R29                 ;swap the nibbles
	OUT Lcd_Dprt,R29         ;send the high nibble
	SBI Lcd_Cprt,Lcd_RS      ;RS = 1 for data
	CBI Lcd_Cprt,Lcd_RW      ;RW = 0 for write
	SBI Lcd_Cprt,Lcd_EN      ;EN = 1 
	CALL sdelay              ;make a wide EN pulse
	CBI Lcd_Cprt,Lcd_EN      ;EN=0
	CALL delay100us          

	MOV R29,R16
	OUT Lcd_Dprt,R29       ;send the low nibble
	SBI Lcd_Cprt,Lcd_EN    ;EN = 1 
	CALL sdelay            ;make a wide EN pulse
	CBI Lcd_Cprt,Lcd_EN    ;EN=0 
	CALL delay100us        ;wait 100 us
	RET



Enter_Int0:
	  ldi r16,0x01 //clear display screen
	  call Command_Wrt
	  call delay2ms

	  cpi r31,1 // if flag is set then skip the increament
	  breq xx

	 cpi r20,'9'   // the next inc must be 10
	 breq Digit_S
	 rjmp apply
	 Digit_S:
	 ldi r20,'/' // units
	 ldi r23,'1' // tenths
	 
apply:
	  mov r16,r23
	  call Data_Wrt //tenths

	  inc r20
	  mov r16,r20
	  call Data_Wrt //units

	  ldi r16,' '
	  call Data_Wrt
	  ldi r16,'C'
	  call Data_Wrt
	  ldi r16,'a'
	  call Data_Wrt
	  ldi r16,'r'
	  call Data_Wrt

	  call Big_Delay
xx:   reti


Exit_Int1:
	  ldi r16,0x01 //clear display screen
	  call Command_Wrt
	  call delay2ms

	  ldi r31,0 // clear flag after counting down from 11 then increament again

	 cpi r20,'0'   // the next inc must be 09
	 breq Digit_S2
	 rjmp apply2
	 Digit_S2:
	 ldi r20,':' // units
	 ldi r23,'0' // tenths
 
apply2:
	  mov r16,r23
	  call Data_Wrt // tenths

	  dec r20
	  mov r16,r20
	  call Data_Wrt // units

	  ldi r16,' '
	  call Data_Wrt
	  ldi r16,'C'
	  call Data_Wrt
	  ldi r16,'a'
	  call Data_Wrt
	  ldi r16,'r'
	  call Data_Wrt

	  call Big_Delay
	  reti


 MaxCars:
  	  ldi r16,0x01 //clear display screen
	  call Command_Wrt
	  call delay2ms

	  cbi portd,Green_Led
	  sbi portd,Red_Led

	  ldi r16,'A'
	  call Data_Wrt
	  ldi r16,'b'
	  call Data_Wrt
	  ldi r16,'d'
	  call Data_Wrt
	  ldi r16,'e'
	  call Data_Wrt
	  ldi r16,'l'
	  call Data_Wrt
	  ldi r16,'h'
	  call Data_Wrt
	  ldi r16,'a'
	  call Data_Wrt
	  ldi r16,'q'
	  call Data_Wrt // abdelhaq

	  ldi r16,0xC0
	  call Command_Wrt
	  call delay2ms  // new line

	  ldi r16,'A'
	  call Data_Wrt
	  ldi r16,'b'
	  call Data_Wrt
	  ldi r16,'d'
	  call Data_Wrt
	  ldi r16,'e'
	  call Data_Wrt
	  ldi r16,'l'
	  call Data_Wrt
	  ldi r16,'n'
	  call Data_Wrt
	  ldi r16,'a'
	  call Data_Wrt
	  ldi r16,'b'
	  call Data_Wrt
	  ldi r16,'y'
	  call Data_Wrt // abdelnaby

	  call BIg_Delay
	  ret

 /*** Delay functions ***/
  delay100us:
	  push r22
	  ldi r22,90
dd100:call sdelay
	  dec r22
	  brne dd100
	  pop r22
	  ret

  sdelay:
	  nop 
	  nop
	  ret

  delay2ms:
  	  push r22
	  ldi r22,40
  dd2:call delay100us
	  dec r22
	  brne dd2
	  pop r22
	  ret

Big_Delay:
	ldi r18,255
 l1:ldi r19,255
 l2:ldi r17,20
 l3:
    dec r17
	brne l3
	dec r19
	brne l2
	dec r18
	brne l1
 	ret