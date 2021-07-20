;==============================================================================	
;=================================[ AJUSTES ]========================================
;==============================================================================
  	ORG 0x00
;-----------------------[ AJUSTES PARA PROGRAMAR ]--------------------------
  	LIST 	P = PIC16F877A			; Identificación del uC en donde se ensamblará.
  	#INCLUDE 	P16F877.INC		; Se usarán las variables de Microchip
  	__CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _HS_OSC & _LVP_OFF & _DEBUG_OFF & _CPD_OFF
	RADIX			HEX						; La base numérica es Hexadecimal por omisión

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;=-=-=-=-=-=-=-=-=-=-=-==-=-=- ( MACROS ) =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	;MACROS PARA LA PANTALLA LCD

	#INCLUDE "SelBank.mac"			; MACRO para la mejor selección de BANCOS.
	#INCLUDE "Macros_LCD.mac"
	#INCLUDE "SaltaSiMacros.mac"
	#INCLUDE "EEPROM.mac"		
	IFNDEF LCD_4Bits_PORTB.h
		#INCLUDE "LCD_4Bits_PORTB.h"
	ENDIF
	
;==============================================================================	
;=========================[ CONFIGURACION DE PUERTOS ]========================================
;==============================================================================
; STATUS = IRP - RP1 - RP0 - T0  - PD  - Z  - DC  - C 

 			;Ajusta para acceder al BANCO 1
	bcf STATUS,RP1 ;El BIT 6 del Registro 3 se pone a "0"
	bsf STATUS,RP0 ;El BIT 5 del Registro 3 se pone a "1"
	
	; Se ajusta ADCON1 para: 			
  	movlw B'10000010' 								
		; Configuracion B7: "Justificado a la Derecha" 
		; Configuracion B6 a B4: No importa
		; Configuracion B3 a B0:
		; AN7, AN6 Y AN5 DIGITALES (PUERTO E)
		; AN4, AN3, AN2, AN1 Y AN0 ANALOGICOS (PUERTO A)  
	movwf ADCON1

		;CONFIGURACION DEL PUERTO A
	movlw B'00011111' ;TODOS LOS PINES DEL PORTA COMO ENTRADA
	movwf TRISA
	
		;CONFIGURACION DEL PUERTO C 
		;(Todo el puerto C se comporta como salida)
	movlw 0x00  ; W <- 0x00
	movwf TRISC  ; (Registro 0x87) <- W	
	
		;CONFIGURACION DEL PUERTO D
		;Se configura el puerto a utilizar por el teclado, en este caso 
		;el puerto D 
		;(Los bits mas significativos del PORTD se comportan como entrada)
	movlw B'11110000'  ; W <- 11110000
	movwf TRISD  ; (Registro 0x86) <- W		
	;	clrf 	INTCON				; Se deshabilitan las interrupciones.

		;CONFIGURACION DEL PUERTO E
	movlw B'00000000' ;TODOS LOS PINES DEL PORTE COMO SALIDA
	movwf TRISE

		;Ajusta para acceder al BANCO 0
	bcf STATUS,RP1 ;El BIT 6 del registro 3 se pone a "0"
	bcf STATUS,RP0 ;El BIT 5 del registro 3 de pone a "0"
			
	movlw	B'11000001' 	; Se ajusta: Oscilador a F R/C, Canal Analógico RA0,
	movwf ADCON0  			; Enciende Conversor A/D, conversión en progreso.

;==============================================================================	
;================================[ VARIABLES ]========================================
;==============================================================================
	CBLOCK	0x20
		cont_clave
		menu
		general_lcd
	;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		;VARIABLES PARA EL TECLADO
		Registro_tecla
	
	;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		;VARIABLES PARA LCD
		Var	 ; Variable para sacar información hacia la LCD.
		Point	; Apuntador para Tablas.
		Select	; Copia del bit asociado con RS en la LCD.
		OutCod	; Variable Temporal para el código de salida.
			
		LCD_Dato
		LCD_GuardaDato
		LCD_GuardaTRISB
		LCD_Auxiliar1
		LCD_Auxiliar2
	;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		;VARIABLES PARA SENSORES (Registros auxiliares)
	
		Temperatura1_H     ;Guarda el valor leido por el adc (parte alta)
		Temperatura1_L     ;Guarda el valor leido por el adc (parte baja)
		
		Temperatura2_H     ;Almacena el valor anterior para que no se pierda
		Temperatura2_L     ;Almacena el valor anterior para que no se pierda

	;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		;VARIABLES PARA OPERACIONES BÁSICAS (Registros auxiliares)
		Num1_a  ;Siendo A en al parte más baja
		Num1_b  
		Num1_c  ;Siendo B en la parte más alta

		Num2_a
		Num2_b
		Num2_c

		Acarreo ;Cuandon B0 de Acarreo es igual a 1 en una resta, significa
				;que el resultado de la resta es un número negativo

		Auxiliar1 ;PARA EL CASO DE LA DIVISION ES EL NUMERO / AUXILIAR		
		Auxiliar2 ;EN CASO DE DIVISION SE ALMACENA EL RESULTADO AQUI (C),
				  ;EN MULTIPLICACION AQUI SE LLEVAN LOS CORRIMIENTOS
		Auxiliar3 ;EN CASO DE DIVISION SE ALMACENA EL RESULTADO AQUI (B)
				  ;RESULTADO PARTE ALTA MULTIPLICACION
		Auxiliar4 ;EN CASO DE DIVISION SE ALMACENA EL RESULTADO AQUI (A)
				  ;RESULTADO PARTE BAJA MULTIPLICACION
		;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		;VARIABLES PARA CONVERTIR DE BINARIO A BCD
		
		BCD1 ;Unidades
		BCD2 ;Decenas
		BCD3 ;Centenas
		
		maxc
		maxd
		maxu
	
		minc
		mind
		minu
		;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		;VARIABLES AUXILIARES 
		aux_eeprom    ;auxiliar eeprom
		aux_eeprom1   
		aux_eeprom2
		aux_eeprom3
		aux_eeprom4

		c
		d
		u

	ENDC

;==============================================================================	
;===============================[ PROGRAMA ]========================================
;==============================================================================

;-=-=-=-=-=-=-=-=-=-= ( Parte obligatoria para iniciar LCD ) =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
  	LCD_Init      ; INICIA LCD 
  	call T1mS      ; Retardo de tiempo (1 mili segundo)
  
  	LCD_Off		; BORRA RESIDUOS DE LA LCD (la apaga)
  	call T1mS		; Retardo de tiempo (1 mili segundo)

  	LCD_Home
  	LCD_On
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-	
	
	;-------------- SE LEE EL LA DIRECCION 0 EN LA EEPROM ------------
		banco2
		movlw  .0 
		movwf	EEADR		;DIRECCION EEPROM=0
		call	EERD		;LEE EN EEPROM, RESULTADO EN W
		movwf aux_eeprom
		;------------------------------------------------------------------
		SaltaSiVarIgualConst aux_eeprom,'X',continua_prog 
			;---------------SE ESCRIBE '3' en la direccion 20 EEPROM-------------					
			banco2
			movlw '0'
			movwf	EEDATA		;DATO =3
			movlw .1
			movwf	EEADR		;DIRECCION EEPROM=1
			call EEWR
			;---------------SE ESCRIBE '5' en la direccion 21 EEPROM-------------					
			banco2
			movlw '3'
			movwf	EEDATA		;DATO =5
			movlw .2
			movwf	EEADR		;DIRECCION EEPROM=2
			call EEWR
			;---------------SE ESCRIBE '2' en la direccion 22 EEPROM-------------					
			banco2
			movlw '5'
			movwf	EEDATA		;DATO =2
			movlw .3
			movwf	EEADR		;DIRECCION EEPROM=3
			call EEWR
			;---------------SE ESCRIBE '5' en la direccion 23 EEPROM-------------					
			banco2
			movlw '0'
			movwf	EEDATA		;DATO =5
			movlw .4
			movwf	EEADR		;DIRECCION EEPROM=4
			call EEWR
			;---------------SE ESCRIBE '5' en la direccion 23 EEPROM-------------					
			banco2
			movlw '2'
			movwf	EEDATA		;DATO =5
			movlw .5
			movwf	EEADR		;DIRECCION EEPROM=4
			call EEWR
			;---------------SE ESCRIBE '5' en la direccion 23 EEPROM-------------					
			banco2
			movlw '5'
			movwf	EEDATA		;DATO =5
			movlw .6
			movwf	EEADR		;DIRECCION EEPROM=4
			call EEWR
		
continua_prog:
	clrf menu
	clrf PORTD	
	clrf c
	clrf d
	clrf u
Inicio:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;-=-=-=-=-=-=-=-=-=( CONVERSOR ANALOGICO-DIGITAL )-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Proceso_LM35:

	call T10uS
	call T10uS
	call T10uS

Continua_ADC:    
	bsf 	ADCON0,2 ; Inicio del proceso de conversión A/D.

Espera:
	btfsc	ADCON0,2 ; ¿Se terminó la conversión? 
		goto 	Espera				; No, espera...
	
	bsf 	STATUS,RP0		; Salto a BANCO "1"           
	movf 	ADRESL,W 			; Lectura de los bits menos significativos (8 bits)
 	bcf 	STATUS,RP0		; Salto a BANCO "0"	
	movwf 	Temperatura1_L
	movf 	ADRESH,W 			; Lectura de la parte más significativa (2 bits)	
	movwf 	Temperatura1_H
	
	;SE HACE CORRIMIENTO A LA DERECHA PARA CONVERTIR EL VOLTAGE A TEMPERATURA
	;EMULA UNA DIVISION ENTRE 2
	bcf STATUS,C
	rrf Temperatura1_L,F
	bcf STATUS,C
	rrf Temperatura1_H,F
	btfsc STATUS,C
		bsf Temperatura1_L,7
		
	call Convertir_a_BCD ;Convierte el numero binario a bcd
	movlw .48
	addwf BCD1,F
	addwf BCD2,F
	addwf BCD3,F
	
	call LEE_MAX_MIN
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;=-=-=-=-=-=-=-=-=-=-=-=-=-( IMPRESION DE LM35 )-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	SaltaSiVarIgualConst menu,0,emenu0
	SaltaSiVarIgualConst menu,1,emenu1
	SaltaSiVarIgualConst menu,2,emenu2
	goto finalmenus 
emenu0:
	call menu0 ;Imprime la temperatura
	goto finalmenus
emenu1:
	call menu1
	goto finalmenus
emenu2:
	call menu2

finalmenus:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;=-=-=-=-=-=-=-=-=-=-=-=-=-( LECTURA DEL TECLADO )-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;Busca en FILA 1
	movlw B'00000001'  ;W <- 0000 0001
	movwf PORTD  ;PORTD <- 0000 0001	
		
		btfsc PORTD,4
			goto Tecla0
		
		btfsc PORTD,5
			goto Tecla1

		btfsc PORTD,6
			goto Tecla2

		btfsc PORTD,7	
			goto Tecla3
		
	;Busca en FILA 2
	movlw B'00000010'  ;W <- 0000 0010
	movwf PORTD  ;PORTD <- 0000 0010

		btfsc PORTD,4
			goto Tecla4
		
		btfsc PORTD,5
			goto Tecla5

		btfsc PORTD,6
			goto Tecla6

		btfsc PORTD,7	
			goto Tecla7
		
	;Busca en FILA 3
	movlw B'00000100'  ;W <- 0000 0100
	movwf PORTD  ;PORTD <- 0000 0100

		btfsc PORTD,4
			goto Tecla8
		
		btfsc PORTD,5
			goto Tecla9

		btfsc PORTD,6
			goto Termina_teclado

		btfsc PORTD,7	
			goto Termina_teclado		
	
	;Busca en FILA 4
	movlw B'00001000'  ;W <- 0000 1000
	movwf PORTD  ;PORTD <- 0000 1000
	
		btfsc PORTD,4
			goto TeclaC
		
		btfsc PORTD,5
			goto TeclaD

		btfsc PORTD,6
			goto Termina_teclado

		btfsc PORTD,7	
			goto TeclaF

Termina_teclado:	
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;=-=-=-=-=-=-=-=-=-=-=-=-=-( INTERPRETACION DE TECLAS )-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	SaltaSiVarIgualConst Registro_tecla,0,NoTecla
		SaltaSiVarIgualConst menu,0,emenu0_2
		SaltaSiVarIgualConst menu,1,emenu1_2
		SaltaSiVarIgualConst menu,2,emenu2_2
		goto finalmenus_2 
;================== MENU 0===========================
emenu0_2:
	SaltaSiVarIgualConst Registro_tecla,'C',Bsmenu1
	SaltaSiVarIgualConst Registro_tecla,'D',Bsmenu2
	goto Bfinalsmenu
Bsmenu1:
	carga menu,.1
	goto Bfinalsmenu
Bsmenu2:
	carga menu,.2
Bfinalsmenu:
	goto finalmenus_2
;================== MENU 1===========================
;PARA INGRESAR EL MAXIMO
emenu1_2:
	SaltaSiVarIgualConst Registro_tecla,'#',m_princA
	SaltaSiVarIgualConst Registro_tecla,'C',m_maxA
	SaltaSiVarIgualConst Registro_tecla,'D',m_minA
	incf cont_clave,F
	SaltaSiVarIgualConst cont_clave,1,Adigito1
	SaltaSiVarIgualConst cont_clave,2,Adigito2
	goto Adigito3
Adigito1:
	llena c,Registro_tecla
	goto Afinaldigitos 
Adigito2:
	llena d,Registro_tecla
	goto Afinaldigitos 
Adigito3:
	llena u,Registro_tecla
	call menu1
	call T1S
	;---------------SE ESCRIBE '5' en la direccion 21 EEPROM-------------					
	banco2
	movlw 'X'
	movwf	EEDATA		;DATO =5
	movlw .0
	movwf	EEADR		;DIRECCION EEPROM=2
	call EEWR
	;---------------SE ESCRIBE '5' en la direccion 21 EEPROM-------------					
	movfw c
	banco2
	movwf	EEDATA		;DATO =5
	movlw .1
	movwf	EEADR		;DIRECCION EEPROM=2
	call EEWR
	;---------------SE ESCRIBE '5' en la direccion 21 EEPROM-------------					
	movfw d
	banco2
	movwf	EEDATA		;DATO =5
	movlw .2
	movwf	EEADR		;DIRECCION EEPROM=2
	call EEWR
	;---------------SE ESCRIBE '5' en la direccion 21 EEPROM-------------					
	movfw u
	banco2
	movwf	EEDATA		;DATO =5
	movlw .3
	movwf	EEADR		;DIRECCION EEPROM=2
	call EEWR
	;------------------------------------------------
m_princA:
	clrf cont_clave
	clrf menu
	clrf c
	clrf d
	clrf u
	goto Afinaldigitos 

m_maxA:
	clrf cont_clave
	carga menu,1
	clrf c
	clrf d
	clrf u
	goto Afinaldigitos 

m_minA:
	clrf cont_clave
	carga menu,2
	clrf c
	clrf d
	clrf u
	goto Afinaldigitos 	

Afinaldigitos:
	goto finalmenus_2
;================== MENU 2===========================
emenu2_2: 
;PARA INGRESAR EL MINIMO
	SaltaSiVarIgualConst Registro_tecla,'#',m_princB
	SaltaSiVarIgualConst Registro_tecla,'C',m_maxB
	SaltaSiVarIgualConst Registro_tecla,'D',m_minB
	incf cont_clave,F
	SaltaSiVarIgualConst cont_clave,1,Bdigito1
	SaltaSiVarIgualConst cont_clave,2,Bdigito2
	goto Bdigito3
Bdigito1:
	llena c,Registro_tecla
	goto Bfinaldigitos 
Bdigito2:
	llena d,Registro_tecla
	goto Bfinaldigitos 
Bdigito3:
	llena u,Registro_tecla
	call menu2
	call T1S
	;---------------SE ESCRIBE '5' en la direccion 21 EEPROM-------------					
	banco2
	movlw 'X'
	movwf	EEDATA		;DATO =5
	movlw .0
	movwf	EEADR		;DIRECCION EEPROM=2
	call EEWR
	;---------------SE ESCRIBE '5' en la direccion 21 EEPROM-------------					
	movfw c
	banco2
	movwf	EEDATA		;DATO =5
	movlw .4
	movwf	EEADR		;DIRECCION EEPROM=2
	call EEWR
	;---------------SE ESCRIBE '5' en la direccion 21 EEPROM-------------					
	movfw d
	banco2
	movwf	EEDATA		;DATO =5
	movlw .5
	movwf	EEADR		;DIRECCION EEPROM=2
	call EEWR
	;---------------SE ESCRIBE '5' en la direccion 21 EEPROM-------------					
	movfw u
	banco2
	movwf	EEDATA		;DATO =5
	movlw .6
	movwf	EEADR		;DIRECCION EEPROM=2
	call EEWR
	;------------------------------------------------
m_princB:
	clrf cont_clave
	clrf menu
	clrf c
	clrf d
	clrf u
	goto Bfinaldigitos 

m_maxB:
	clrf cont_clave
	carga menu,1
	clrf c
	clrf d
	clrf u
	goto Bfinaldigitos 

m_minB:
	clrf cont_clave
	carga menu,2
	clrf c
	clrf d
	clrf u
	goto Bfinaldigitos 	

Bfinaldigitos:
;================== FINAL DE LOS MENUS===========================
finalmenus_2:
	carga Registro_tecla,0
NoTecla:

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	;ETAPA DE CONTROL
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	call control
	
	goto Inicio

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;PARA EL CONTROL DE LA TEMPERATURA 
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
control:

	SaltaSiVarMayorIgualVar BCD3,maxc,dmayor
dmayor:
	SaltaSiVarMayorIgualVar BCD2,maxd,umayor
	goto identifica_menor	
umayor:	
	SaltaSiVarMayorIgualVar BCD1,maxu,superamaximo
	goto identifica_menor

superamaximo:
	bcf PORTC,0
	bsf PORTC,1
	goto fin_ident	


identifica_menor:
	SaltaSiVarMenorIgualVar1 BCD3,minc,dmenor
	goto fin_ident	
dmenor:
	SaltaSiVarMenorIgualVar2 BCD2,mind,umenor
	goto fin_ident	
umenor:	
	SaltaSiVarMenorIgualVar3 BCD1,minu,superaminimo
	goto fin_ident

superaminimo:
	bsf PORTC,0
	bcf PORTC,1

fin_ident:
	return

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ (Teclas) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
Tecla1: 
	call T100mS 
	call T100mS 
	movlw '1'
	movwf Registro_tecla
	goto Termina_teclado

Tecla2:   
	call T100mS 
	call T100mS 
	movlw '2'
	movwf Registro_tecla
	goto Termina_teclado

Tecla3:   
	call T100mS 
	call T100mS 
	movlw '3'
	movwf Registro_tecla
	goto Termina_teclado

Tecla4:   
	call T100mS 
	call T100mS 
	movlw '4'
	movwf Registro_tecla
	goto Termina_teclado

Tecla5:   
	call T100mS 
	call T100mS 
	movlw '5'
	movwf Registro_tecla
	goto Termina_teclado

Tecla6:   
	call T100mS 
	call T100mS 
	movlw '6'
	movwf Registro_tecla
	goto Termina_teclado
	
Tecla7:   
	call T100mS 
	call T100mS 
	movlw '7'
	movwf Registro_tecla
	goto Termina_teclado

Tecla8:   
	call T100mS 
	call T100mS 
	movlw '8'
	movwf Registro_tecla
	goto Termina_teclado

Tecla9:   
	call T100mS 
	call T100mS 
	movlw '9'
	movwf Registro_tecla
	goto Termina_teclado

TeclaC:   
	call T100mS 
	call T100mS 
	movlw 'C'
	movwf Registro_tecla
	goto Termina_teclado

Tecla0:   
	call T100mS 
	call T100mS 
	movlw '0'
	movwf Registro_tecla
	goto Termina_teclado

TeclaF:   
	call T100mS 
	call T100mS 
	movlw '#'
	movwf Registro_tecla
	goto Termina_teclado

TeclaD:   
	call T100mS 
	call T100mS 
	movlw 'D'
	movwf Registro_tecla
	goto Termina_teclado
	
;================================================================================
;==============================[ SUBRUTINAS ]======================================
;=================================================================================

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;IMPRESION DE TEMPERATURA 
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
menu0:	
	;SE IMPRIME EL NUMERO EN BCD EN LA LCD
	LCD_GoTo 0,0	;COLUMNA 0, FILA 1 

	;INGRESE 4 DIGTOS
	imprimelit 'T'  ;1
	imprimelit ':'  ;2
	imprimevar BCD3  ;3
	imprimevar BCD2  ;4
	imprimevar BCD1 ;5
	imprimelit ' '  ;6
	imprimelit 'M'  ;8
	imprimevar maxc  ;9
	imprimevar maxd  ;10
	imprimevar maxu ;11
	imprimelit ' ' ;12
	imprimelit 'm'  ;13
	imprimevar minc  ;14
	imprimevar mind  ;15
	imprimevar minu  ;16
	return

menu1:
	;SE IMPRIME EL NUMERO EN BCD EN LA LCD
	LCD_GoTo 0,0	;COLUMNA 0, FILA 1 
	;INGRESE 4 DIGTOS
	imprimelit 'M'  ;1
	imprimelit 'A'  ;2
	imprimelit 'X'  ;3
	imprimelit 'I'  ;4
	imprimelit 'M' ;5
	imprimelit 'O'  ;6
	imprimelit '('  ;8
	imprimelit '3'  ;9
	imprimelit 'd'  ;10
	imprimelit ')'  ;11
	imprimelit ':' ;12
	imprimelit ' '  ;13
	imprimevar c  ;14
	imprimevar d  ;15
	imprimevar u  ;16
	return

menu2:
	;SE IMPRIME EL NUMERO EN BCD EN LA LCD
	LCD_GoTo 0,0	;COLUMNA 0, FILA 1 
	;INGRESE 4 DIGTOS
	imprimelit 'M'  ;1
	imprimelit 'I'  ;2
	imprimelit 'N'  ;3
	imprimelit 'I'  ;4
	imprimelit 'M' ;5
	imprimelit 'O'  ;6
	imprimelit '('  ;8
	imprimelit '3'  ;9
	imprimelit 'd'  ;10
	imprimelit ')'  ;11
	imprimelit ':' ;12
	imprimelit ' '  ;13
	imprimevar c  ;14
	imprimevar d  ;15
	imprimevar u  ;16
	return

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;BINARIO A BCD PARA LA TEMPERATURA
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Convertir_a_BCD:
	movfw Temperatura1_L
	movwf Num1_a
	movfw Temperatura1_H
	movwf Num1_b
	clrf Num1_c	
	movlw .100
	movwf Num2_a
	clrf Num2_b
	clrf Num2_c
	call Division
	movfw Num2_a
	movwf BCD3
	
	movfw Num1_a
	movwf Temperatura1_L
	movfw Num1_b
	movwf Temperatura1_H
	clrf Num1_c	
	movlw .10
	movwf Num2_a
	clrf Num2_b
	clrf Num2_c
	call Division
	movfw Num2_a
	movwf BCD2
	
	movfw Num1_a
	movwf BCD1	
	return

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;LEER MAXIMOS Y MINIMOS EN LA EEPROM
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
LEE_MAX_MIN:
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .1 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf maxc
	;-------------- SE LEE EL LA DIRECCION 25 EN LA EEPROM ------------
	banco2
	movlw  .2 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf maxd
	;-------------- SE LEE EL LA DIRECCION 26 EN LA EEPROM ------------
	banco2
	movlw  .3 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf maxu
	;-------------- SE LEE EL LA DIRECCION 27 EN LA EEPROM ------------
	banco2
	movlw  .4 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf minc
	;-------------- SE LEE EL LA DIRECCION 27 EN LA EEPROM ------------
	banco2
	movlw  .5 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf mind
	;-------------- SE LEE EL LA DIRECCION 27 EN LA EEPROM ------------
	banco2
	movlw  .6 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf minu	
	return
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;ESCRITURA Y LECTURA EN MEMORIA DE EEPROM
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	EEWR:	
	banco3			;HABILITA EL BANCO 3
	BCF	EECON1,EEPGD	;APUNTA HACIA EEPROM DE DATOS		
	BSF	EECON1,WREN	;HABILITA ESCRITURA EN EEPROM
	MOVLW	H'55'		;PREPARA SECUENCIA DE SEGURIDAD
	MOVWF	EECON2		;ESCRIBE PRIMER DATO DE SECUENCIA
	MOVLW	H'AA'		;SEGUNDO DATO
	MOVWF	EECON2		;ESCRIBE SEGUNDO DATO DE SECUENCIA
	BSF	EECON1,WR	;INICIA CICLO DE ESCRITURA
EW:	
	BTFSC   EECON1,WR       ;MALLA PARA ESPERAR AL FINAL DEL CICLO
    GOTO    EW              ;SI WR=1, CICLO DE ESCRITURA AUN NO TERMINA
	BCF     EECON1, WREN    ;DESHABILITA ESCRITURA
	banco0
	RETURN

EERD: 	
	banco3
	BCF	EECON1,EEPGD		;APUNTA HACIA EEPROM DE DATOS		
	BSF	EECON1,RD		;HABILITA EL BIT 0 (RD) DEL REGISTRO EECON1		
	banco2
	MOVF	EEDATA,W		;TRANSFIERE EL DATO EN EEDATA A W,
	banco0
	RETURN 


;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;MACROS DE LCD Y RETARDOS DE TIEMPO
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	
	#INCLUDE "LCD_4Bits_PORTB.inc"	; Manejador de la LCD.
  	#INCLUDE "Tiempo.inc"						; Retardos y temporizados.

;=============================================================================
;====================( SUBRUTINAS OPERACIONES BÁSICAS )================================================
;================================================================================

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;SUMAR NUMEROS DE HASTA 24 BITS
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;SE DEBEN CARGAR PREVIAMENTE LOS NUMEROS A LOS REGISTROS Num1 y Num2
Suma:   ;Num1 + Num2 = Num2
	;Se suman las partes a
	
	movf Num1_a,W	;W = Num1_a
	addwf Num2_a,F  ;Num2_a= W + Num2_a  
	btfss STATUS,C
		goto No_incremento1
	
	movlw 0x01 ;SE INCREMENTA DE ESTA FORMA, SINO EL PIC CAUSA ERRORES
	addwf Num2_b,F ; POR ALGUNA RAZÓN DESCONOCIDA

No_incremento1:	
;----------------------------------------------	
	;Suma las partes b
	btfss STATUS,0
		goto No_incremento2		
	movlw 0x01 ;SE INCREMENTA DE ESTA FORMA, SINO EL PIC CAUSA ERRORES
	addwf Num2_c,F ; POR ALGUNA RAZÓN DESCONOCIDA

No_incremento2:
	btfsc STATUS,0
		incf Acarreo,F
	movf Num1_b,W
	addwf Num2_b,F	
	btfss STATUS,C
		goto No_incremento3
	movlw 0x01 ;SE INCREMENTA DE ESTA FORMA, SINO EL PIC CAUSA ERRORES
	addwf Num2_c,F ; POR ALGUNA RAZÓN DESCONOCIDA

No_incremento3:		
	btfsc STATUS,0
		incf Acarreo,F
;---------------------------------------------
	;Suma las partes c
	movf Num1_c,W
	addwf Num2_c,1		
	btfsc STATUS,0
		incf Acarreo,F
	return

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;RESTAR NUMEROS DE HASTA 24 BITS
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Resta: ;Num1 - Num2 = Num2  (SIENDO EL NUM2 EL MENOR)
	clrf Acarreo ;PARA EVITAR ERRORES SE REINICIAR EL REGISTRO DE ACARREO
	;Se saca el complemento a 2 del Numero 2 (el numero menor)
	;Se saca el complemento a 1
	comf Num2_a,F
	comf Num2_b,F
	comf Num2_c,F
	comf Acarreo,F

	movlw B'00000000'  ;PARA EVITAR ERRORES DEL PIC QUE CAUSAN EN ESTE
	addwf Num2_c,1	;PUNTO POR ALGUNA RAZÓN QUE DESCONOZCO!!!!?????

	;Se saca el complemento a 2 (se suma 1)
	incf Num2_a,1
	btfsc STATUS,0
		incf Num2_b,F

	btfsc STATUS,0
		incf Num2_c,F
	
	call Suma	
	return

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;DIVIDIR DOS NUMEROS,  NUM1 / NUM2  donde Num2=8 BIT MAX y Num1 = 24 BIT MAX
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Division: ;EL RESULTADO SE ALMACENA EN EL REGISTRO NUM2
	clrf Auxiliar4
	clrf Auxiliar3
	clrf Auxiliar2

	movfw Num2_a
	movwf Auxiliar1

Continua_division:
	clrf Num2_c
	clrf Num2_b
	movfw Auxiliar1
	movwf Num2_a

	call Resta 
	btfsc Acarreo,0 
		goto Termina_division
	
	movfw Num2_c
	movwf Num1_c
	movfw Num2_b
	movwf Num1_b
	movfw Num2_a
	movwf Num1_a

	incf Auxiliar4,F
	btfsc STATUS,C
		incf Auxiliar3,F
	btfsc STATUS,C
		incf Auxiliar2,F

	goto Continua_division

Termina_division:
	movfw Auxiliar4
	movwf Num2_a
	movfw Auxiliar3
	movwf Num2_b
	movfw Auxiliar2
	movwf Num2_c
	return

;---------------------------------------------------------
	END
