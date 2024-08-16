
#include "MemMap.h"
#include "StdTypes.h"
#include "DIO_Int.h"
#include "SEVEN_SEG_Int.h"
#include "MOTOR_Int.h"
#include "STEPPER_Int.h"
#include "LCD_Int.h"
#include "ECU_Int.h"
#include "KEYPAD_Int.h"
#include "EXI_Int.h"
#include "Timers_Services.h"
#include "Timers_Int.h"
#include "IR_Cfg.h"
#include "SERVO_Int.h"
#include "UART_Int.h"
#include "UART_Services.h"
#include "ADC_Int.h"
#include "Smart_Home_Uart.h"
#include "NVM_Int.h"
#include "NVM_Services.h"
#include "OS.h"
#include "SPI.h"

#define F_CPU 8000000UL
#include <util/delay.h>

volatile s8 floor1=5,floor2=5,flag=0,en=0,ex=0;


void Servo_Position(u8 degree);
void Floor1_Enter_Int_func(void)
{
	//ir1
	if(floor1 >= 0 && ex==0)
	{
		flag=1;
		Servo_Position(180);
		_delay_ms(2000);
		Servo_Position(0);
		floor1=floor1-1;
		en=1;
	}
	ex=0;
}

void Floor1_Exit_Int_func(void)
{
	//ir2
	if(floor1<5 && en==0)
	{
		Servo_Position(90);
		_delay_ms(2000);
		Servo_Position(0);
		floor1=floor1+1;
		ex=1;
	}
	en=0;
}

void Floor2_Enter_Int_func(void)
{
	// ir3
	if(floor2>=0 && flag==1 )
	{
		floor2=floor2-1;
		floor1=floor1+1;
		_delay_ms(2000);
	}
}

void Floor2_Exit_Int_func(void)
{
	// ir4
	if(floor2<5)
	{
		floor2=floor2+1;
		floor1=floor1-1;
		_delay_ms(2000);
	}
}

int main(void)
{
	DIO_Init();
	LCD_Init();
	EXI_Init();
	Timer1_Init(TIMER1_FASTPWM_OCRA_TOP_MODE,TIMER1_SCALER_8);
	Timer1_OCRA1Mode(OCRA_NON_INVERTING);
	Timer1_OCRB1Mode(OCRB_NON_INVERTING);
	OCR1A=19999;
	EXI_SetCallBack(EX_INT0,Floor1_Enter_Int_func);
	EXI_SetCallBack(EX_INT1,Floor1_Exit_Int_func);
	EXI_SetCallBack(EX_INT2,Floor2_Enter_Int_func);
	EXI_Enable(EX_INT0);
	EXI_Enable(EX_INT1);
	EXI_Enable(EX_INT2);
	LCD_WriteString("Car Garage Project");
	_delay_ms(200);
	LCD_Clear();
	LCD_WriteString("Mostafa AbdelNaby");
	_delay_ms(200);
	LCD_Clear();
	LCD_WriteString("Mohamed ElRokh");
	_delay_ms(200);
	LCD_Clear();
	LCD_WriteString("Mohamed Abdelhaq");
	_delay_ms(200);
	LCD_Clear();
	GLOBAL_ENABLE();
	Servo_Position(0);
	_delay_ms(1000);
	while(1)
	{
		LCD_SetCursor(1,1);
		LCD_WriteString("in Floor 1:");
		LCD_WriteNumber(floor1);
		LCD_SetCursor(2,1);
		LCD_WriteString("in Floor 2:");
		LCD_WriteNumber(floor2);
		if(!DIO_ReadPin(Floor2_Exit))
		{
			//ir4
			Floor2_Exit_Int_func();
		}
	}

}

void Servo_Position(u8 degree)
{
	OCR1B=999+((degree*(u32)1000)/180);
}


