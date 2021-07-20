;==============================================================================	
;=================================[ AJUSTES ]========================================
;==============================================================================
  	ORG 0x00
;-----------------------[ AJUSTES PARA PROGRAMAR ]--------------------------
  	LIST 	P = PIC16F877A			; Identificación del uC en donde se ensamblará.
  	#INCLUDE 	P16F877A.INC		; Se usarán las variables de Microchip
  	__CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _HS_OSC & _LVP_OFF & _DEBUG_OFF & _CPD_OFF
	RADIX			HEX						; La base numérica es Hexadecimal por omisión


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;=-=-=-=-=-=-=-=-=-=-=-==-=-=- ( MACROS ) =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	;MACROS PARA LA PANTALLA LCD

	#INCLUDE "SelBank.mac"			; MACRO para la mejor selección de BANCOS (LCD)
	#INCLUDE "Macros_LCD.mac"      ;MACRO para la impresion en la LCD
	#INCLUDE "SaltaSiMacros.mac" ;	;MACRO para funciones "if", igualar, impresion de caracteres, etc (varios)
	#INCLUDE "EEPROM.mac" ;MACRO para implementar las funciones de la memoria EEPROM, cambiar de banco
	;#INCLUDE "Macros_varias.mac" ;MACRO que contiene conjuntos de instrucciones necesarios para que el programa funcione
	#INCLUDE "Teclado.mac" ;MACRO que contiene conjuntos de instrucciones necesarios para que el programa funcione

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
	movlw B'11110000'  ; W <- 0x00
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
	;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		;VARIABLES DEL PROGRAMA		
		menu
		sala
		usuario
		almacenaje
		cont_clave
	
	;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		;VARIABLES DEL PROGRAMA		
		d1
		d2
		d3
		d4

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

		general_lcd
		;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		;VARIABLES AUXILIARES 
		aux_eeprom ;auxiliar eeprom
		aux_eeprom1
		aux_eeprom2
		aux_eeprom3
		aux_eeprom4
		aux_menu		
		llave		

	ENDC

goto Variables_iniciales

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;IMPRESION MENU 4
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Line7:	
	addwf	PCL,F							; Modifica el Contador del Programa [PC]
	DT " INGRESE USUARIO", 0x00

Line8:
	addwf	PCL,F							; Modifica el Contador del Programa [PC]
	DT "(1-3 o A) #=MENU", 0x00

menu4:
	clrf			Point					; Reinicio del Apuntador de la Tabla
	LCD_GoTo  0,0						; Pasa a la columna "0", Línea "1"
	bsf				Select,Pin_RS	; Selección del MODO de DATOS; RS <- "1" 

Mess7:
	movf			Point,W				; Carga el dato apuntado... 
	call			Line7					; Obtén el código ASCII apuntado en la tabla 
	bsf				Select,Pin_RS	; Select command mode 
	call			LCD_Char			; ... Envíalo a la LCD  
	incf			Point,F				; Apunta al próximo caracter 
	movf			Point,W				; y carga el apuntador 
	sublw			D'16'					; Verifica si ya se enviaron todos los caracteres 
	btfss			STATUS,Z			; ... concluye si ya se enviaron 16
		goto			Mess7					; Continuúa...
	LCD_GoTo  0,1						; Pasa a la columna "0", Línea "1"
	clrf			Point					; Reinicia el Apuntador de la Tabla.	

Mess8:
	movf			Point,W				; Carga el dato apuntado... 
	call			Line8				; Obtén el código ASCII apuntado en la tabla 
	bsf				Select,Pin_RS	; Select command mode 
	call			LCD_Char			; ... Envíalo a la LCD  
	incf			Point,F				; Apunta al próximo caracter 
	movf			Point,W				; y carga el apuntador 
	sublw			D'16'					; Verifica si ya se enviaron todos los caracteres 
	btfss			STATUS,Z			; ... concluye si ya se enviaron 16
		goto			Mess8					; Continuúa...
	
	return	


;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;IMPRESION MENU 3
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Line5:	
	addwf	PCL,F							; Modifica el Contador del Programa [PC]
	DT "INGRESE LA SALA ", 0x00

Line6:
	addwf	PCL,F							; Modifica el Contador del Programa [PC]
	DT "(1 a 4)   #=MENU", 0x00

menu3:
	clrf			Point					; Reinicio del Apuntador de la Tabla
	LCD_GoTo  0,0						; Pasa a la columna "0", Línea "1"
	bsf				Select,Pin_RS	; Selección del MODO de DATOS; RS <- "1" 

Mess5:
	movf			Point,W				; Carga el dato apuntado... 
	call			Line5					; Obtén el código ASCII apuntado en la tabla 
	bsf				Select,Pin_RS	; Select command mode 
	call			LCD_Char			; ... Envíalo a la LCD  
	incf			Point,F				; Apunta al próximo caracter 
	movf			Point,W				; y carga el apuntador 
	sublw			D'16'					; Verifica si ya se enviaron todos los caracteres 
	btfss			STATUS,Z			; ... concluye si ya se enviaron 16
		goto			Mess5					; Continuúa...
	LCD_GoTo  0,1						; Pasa a la columna "0", Línea "1"
	clrf			Point					; Reinicia el Apuntador de la Tabla.	

Mess6:
	movf			Point,W				; Carga el dato apuntado... 
	call			Line6				; Obtén el código ASCII apuntado en la tabla 
	bsf				Select,Pin_RS	; Select command mode 
	call			LCD_Char			; ... Envíalo a la LCD  
	incf			Point,F				; Apunta al próximo caracter 
	movf			Point,W				; y carga el apuntador 
	sublw			D'16'					; Verifica si ya se enviaron todos los caracteres 
	btfss			STATUS,Z			; ... concluye si ya se enviaron 16
		goto			Mess6					; Continuúa...
	
	return	


;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;IMPRESION MENU 1
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Line3:	
	addwf	PCL,F							; Modifica el Contador del Programa [PC]
	DT "USUARIO ACEPTADO", 0x00

Line4:
	addwf	PCL,F							; Modifica el Contador del Programa [PC]
	DT "USUARIO DENEGADO", 0x00

menu1:
	call LIMPIA_LCD
	clrf			Point					; Reinicio del Apuntador de la Tabla
	LCD_GoTo  0,0						; Pasa a la columna "0", Línea "1"
	bsf				Select,Pin_RS	; Selección del MODO de DATOS; RS <- "1" 
Mess3:
	movf			Point,W				; Carga el dato apuntado... 
	call			Line3					; Obtén el código ASCII apuntado en la tabla 
	bsf				Select,Pin_RS	; Select command mode 
	call			LCD_Char			; ... Envíalo a la LCD  
	incf			Point,F				; Apunta al próximo caracter 
	movf			Point,W				; y carga el apuntador 
	sublw			D'16'					; Verifica si ya se enviaron todos los caracteres 
	btfss			STATUS,Z			; ... concluye si ya se enviaron 16
		goto			Mess3					; Continuúa...
	return

menu2:
	call LIMPIA_LCD
	LCD_GoTo  0,0						; Pasa a la columna "0", Línea "1"
	clrf			Point					; Reinicia el Apuntador de la Tabla.	

Mess4:
	movf			Point,W				; Carga el dato apuntado... 
	call			Line4				; Obtén el código ASCII apuntado en la tabla 
	bsf				Select,Pin_RS	; Select command mode 
	call			LCD_Char			; ... Envíalo a la LCD  
	incf			Point,F				; Apunta al próximo caracter 
	movf			Point,W				; y carga el apuntador 
	sublw			D'16'					; Verifica si ya se enviaron todos los caracteres 
	btfss			STATUS,Z			; ... concluye si ya se enviaron 16
		goto			Mess4					; Continuúa...
	
	return	

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;IMPRESION MENU 0
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Line1:	
	addwf	PCL,F							; Modifica el Contador del Programa [PC]
	DT "2 = MENU USUARIO", 0x00

Line2:
	addwf	PCL,F							; Modifica el Contador del Programa [PC]
	DT "1=CLAVES 3=ACCES", 0x00

menu0:
	clrf			Point					; Reinicio del Apuntador de la Tabla
	LCD_GoTo  0,0						; Pasa a la columna "0", Línea "2"
	bsf				Select,Pin_RS	; Selección del MODO de DATOS; RS <- "1" 

Mess1:
	movf			Point,W				; Carga el dato apuntado... 
	call			Line1					; Obtén el código ASCII apuntado en la tabla 
	bsf				Select,Pin_RS	; Select command mode 
	call			LCD_Char			; ... Envíalo a la LCD  
	incf			Point,F				; Apunta al próximo caracter 
	movf			Point,W				; y carga el apuntador 
	sublw			D'16'					; Verifica si ya se enviaron todos los caracteres 
	btfss			STATUS,Z			; ... concluye si ya se enviaron 16
		goto			Mess1					; Continuúa...
	LCD_GoTo  0,1						; Pasa a la columna "0", Línea "1"
	clrf			Point					; Reinicia el Apuntador de la Tabla.	

Mess2:
	movf			Point,W				; Carga el dato apuntado... 
	call			Line2				; Obtén el código ASCII apuntado en la tabla 
	bsf				Select,Pin_RS	; Select command mode 
	call			LCD_Char			; ... Envíalo a la LCD  
	incf			Point,F				; Apunta al próximo caracter 
	movf			Point,W				; y carga el apuntador 
	sublw			D'16'					; Verifica si ya se enviaron todos los caracteres 
	btfss			STATUS,Z			; ... concluye si ya se enviaron 16
		goto			Mess2					; Continuúa...
	
	return	

;==============================================================================	
;====================[ VALORES INICIALES DE VARIABLES ]========================================
;==============================================================================
Variables_iniciales:
		;-------------- SE LEE EL LA DIRECCION 44 EN LA EEPROM ------------
		banco2
		movlw  .44 
		movwf	EEADR		;DIRECCION EEPROM=44
		call	EERD		;LEE EN EEPROM, RESULTADO EN W
		movwf aux_eeprom
		;------------------------------------------------------------------
		SaltaSiVarIgualConst aux_eeprom,'Z',continua_prog 
			;---------------SE ESCRIBE 'A' en la direccion 20 EEPROM-------------					
			banco2
			movlw 'A'
			movwf	EEDATA		;DATO =A
			movlw .20
			movwf	EEADR		;DIRECCION EEPROM=0
			call EEWR
			;---------------SE ESCRIBE 'A' en la direccion 21 EEPROM-------------					
			banco2
			movlw 'A'
			movwf	EEDATA		;DATO =A
			movlw .21
			movwf	EEADR		;DIRECCION EEPROM=0
			call EEWR
			;---------------SE ESCRIBE 'A' en la direccion 22 EEPROM-------------					
			banco2
			movlw 'A'
			movwf	EEDATA		;DATO =A
			movlw .22
			movwf	EEADR		;DIRECCION EEPROM=0
			call EEWR
			;---------------SE ESCRIBE 'A' en la direccion 23 EEPROM-------------					
			banco2
			movlw 'A'
			movwf	EEDATA		;DATO =A
			movlw .23
			movwf	EEADR		;DIRECCION EEPROM=0
			call EEWR
continua_prog: 
		clrf menu
		clrf usuario
		clrf sala
		clrf cont_clave
		clrf d1
		clrf d2
		clrf d3
		clrf d4		

;==============================================================================	
;===============================[ PROGRAMA  INICIO ]========================================
;==============================================================================

;-=-=-=-=-=-=-=-=-=-= ( Parte obligatoria para iniciar LCD ) =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
  	LCD_Init      ; INICIA LCD 
  	call T1mS      ; Retardo de tiempo (1 mili segundo)
  
  	LCD_Off		; BORRA RESIDUOS DE LA LCD (la apaga)
  	call T1mS		; Retardo de tiempo (1 mili segundo)

  	LCD_Home
  	LCD_On
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-		
	call menu0
Inicio:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;=-=-=-=-=-=-=-=-=-=-=-=-=-( LECTURA DEL TECLADO )-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	Multiplexea_tecla

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;=-=-=-=-=-=-=-=-=-=-=-=-=-( INTERPRETACION DE TECLAS )-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	SaltaSiVarIgualConst almacenaje,0,NoTecla
		SaltaSiVarIgualConst menu,.0,emenu0_2 ;MENU PRINCIPAL
		SaltaSiVarIgualConst menu,.1,emenu1_2 ;CAMBIAR CLAVES
		SaltaSiVarIgualConst menu,.2,emenu2_2 ;CAMBIAR ACCESOS
		SaltaSiVarIgualConst menu,.3,emenu3_2 ;INGRESAR USUARIO
		SaltaSiVarIgualConst menu,.4,emenu4_2 ;INGRESAR SALA
		SaltaSiVarIgualConst menu,.5,emenu5_2 ;INGRESAR CLAVE 
		SaltaSiVarIgualConst menu,.6,emenu6_2 ;ACCEDER A ALGUNA SALA
		goto finalmenus_2 
;================== MENU 0===========================
;MENU PRINCIPAL
emenu0_2:
	SaltaSiVarIgualConst almacenaje,'2',Asmenu2
	SaltaSiVarIgualConst almacenaje,'1',Asmenu1
	SaltaSiVarIgualConst almacenaje,'3',Asmenu3
	goto Afinalsmenu
Asmenu2:     ;SE PIDE QUE INGRESE UNA SALA
	call menu3  
	carga menu,.4
	goto Afinalsmenu
Asmenu1:   ;SE PIDE CONTRASEÑA DEL ADMINISTRADOR (cambiar claves)
	call menu5
	carga menu,.5
	carga aux_menu,'A'
	goto Afinalsmenu
Asmenu3:   ;SE PIDE CONTRASEÑA DEL ADMINISTRADOR (cambiar accesos)
	carga aux_menu,'B'
	call menu5
	carga menu,.5
Afinalsmenu:
	goto finalmenus_2
;================== MENU 1===========================
emenu1_2:
    movlw 0x01
	addwf cont_clave	
	SaltaSiVarIgualConst cont_clave,1,Bdigito1
	SaltaSiVarIgualConst cont_clave,2,Bdigito2
	SaltaSiVarIgualConst cont_clave,3,Bdigito3
	goto Bdigito4
Bdigito1:
	llena d1,almacenaje
	call menu5
	goto Bfinaldigitos 
Bdigito2:
	llena d2,almacenaje
	call menu5
	goto Bfinaldigitos 
Bdigito3:
	llena d3,almacenaje
	call menu5
	goto Bfinaldigitos 
Bdigito4:
	llena d4,almacenaje
	call menu5
	call T1S
	call ESCRIBE_CLAVES_EEPROM
	clrf cont_clave
	clrf d1
	clrf d2
	clrf d3
	clrf d4
	clrf menu
	clrf usuario
	clrf aux_menu
	call menu0

Bfinaldigitos:
	goto finalmenus_2
;================== MENU 2===========================
emenu2_2:
	SaltaSiVarIgualConst almacenaje,'1',Fsmenu1
	SaltaSiVarIgualConst almacenaje,'2',Fsmenu2
	SaltaSiVarIgualConst almacenaje,'3',Fsmenu3
	SaltaSiVarIgualConst almacenaje,'4',Fsmenu4
	SaltaSiVarIgualConst almacenaje,'#',Fsmenu#
	goto Ffinalsmenu
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Fsmenu1:
	SaltaSiVarIgualConst d1,'S',Asid1
	carga d1,'S'
	goto Afinalsinod1
Asid1:
	carga d1,'N'
Afinalsinod1:
	goto Ffinalsmenu
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Fsmenu2:
	SaltaSiVarIgualConst d2,'S',Asid2
	carga d2,'S'
	goto Afinalsinod2
Asid2:
	carga d2,'N'
Afinalsinod2:
	goto Ffinalsmenu
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Fsmenu3:
	SaltaSiVarIgualConst d3,'S',Asid3
	carga d3,'S'
	goto Afinalsinod3
Asid3:
	carga d3,'N'
Afinalsinod3:
	goto Ffinalsmenu
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Fsmenu4:
	SaltaSiVarIgualConst d4,'S',Asid4
	carga d4,'S'
	goto Afinalsinod4
Asid4:
	carga d4,'N'
Afinalsinod4:
	goto Ffinalsmenu	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Fsmenu#:
	clrf d1
	clrf d2
	clrf d3
	clrf d4
	clrf menu
	clrf usuario
	clrf aux_menu
	call menu0
	goto finalmenus_2
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Ffinalsmenu:
	call ESCRIBE_SALAS_EEPROM
	call menu6
	goto finalmenus_2	
;================== MENU 3===========================
emenu3_2:
	SaltaSiVarIgualConst almacenaje,'1',Dsmenu1
	SaltaSiVarIgualConst almacenaje,'2',Dsmenu2
	SaltaSiVarIgualConst almacenaje,'3',Dsmenu3
	SaltaSiVarIgualConst almacenaje,'A',DsmenuA
	SaltaSiVarIgualConst almacenaje,'#',Dsmenu#
	goto Dfinalsmenu
Dsmenu1:
Dsmenu2:
Dsmenu3:
	llena usuario,almacenaje
	SaltaSiVarIgualConst aux_menu,'X',cambia_clavesd
	SaltaSiVarIgualConst aux_menu,'Y',cambia_accesosd
	goto Dfinalsmenu
cambia_clavesd:
	call menu5
	llena usuario,almacenaje
	carga menu,1 ;CAMBIA CLAVES
	goto Dfinalsmenu
cambia_accesosd
	call menu6
	carga menu,2 ;CAMBIA ACCESOS
	llena usuario,almacenaje
	goto Dfinalsmenu

DsmenuA:
	SaltaSiVarIgualConst aux_menu,'Y',Dfinalsmenu ;NO SE PUEDEN CAMBIAR ACCESOS AL ADMINISTRADOR
	llena usuario,almacenaje
	SaltaSiVarDiferenteConst aux_menu,'X',otra_d
    movlw 'Z'
	banco2
	movwf	EEDATA		;DATO = d1
	movlw .44
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	
	carga menu,1 ;CAMBIA CLAVES
	call menu5
	goto Dfinalsmenu
otra_d:
	goto Dfinalsmenu
Dsmenu#:
	clrf menu
	clrf usuario
	clrf aux_menu
	call menu0
	goto Dfinalsmenu
Dfinalsmenu:
	goto finalmenus_2
;================== MENU 4===========================
emenu4_2:
	SaltaSiVarIgualConst almacenaje,'1',Csmenu1
	SaltaSiVarIgualConst almacenaje,'2',Csmenu2
	SaltaSiVarIgualConst almacenaje,'3',Csmenu3
	SaltaSiVarIgualConst almacenaje,'4',Csmenu4
	SaltaSiVarIgualConst almacenaje,'#',Csmenu#
	goto Cfinalsmenu
Csmenu1:
Csmenu2:
Csmenu3:
Csmenu4:
	carga menu,.6
	call menu5
	llena sala,almacenaje
	clrf d1
	clrf d2
	clrf d3
	clrf d4
	goto Cfinalsmenu
Csmenu#:
	call menu0
	clrf menu	
	clrf sala	
	clrf d1
	clrf d2
	clrf d3
	clrf d4
	goto Cfinalsmenu
Cfinalsmenu:
	goto finalmenus_2
;================== MENU 5===========================
emenu5_2:
	movlw 0x01
	addwf cont_clave
	
	SaltaSiVarIgualConst cont_clave,1,Adigito1
	SaltaSiVarIgualConst cont_clave,2,Adigito2
	SaltaSiVarIgualConst cont_clave,3,Adigito3
	goto Adigito4
Adigito1:
	llena d1,almacenaje
	call menu5
	goto Afinaldigitos 
Adigito2:
	llena d2,almacenaje
	call menu5
	goto Afinaldigitos 
Adigito3:
	llena d3,almacenaje
	call menu5
	goto Afinaldigitos 
Adigito4:
	llena d4,almacenaje
	call menu5
	call T100mS
	call T100mS
	call T100mS
	call VALIDA_ADMIN
	btfsc llave,0
		goto admin_acept
	;admin_rechazado
		call menu2
		call T1S
		clrf menu
		call menu0
		clrf aux_menu	
		goto final_admina
admin_acept:
	 	call menu1
		call T1S
		SaltaSiVarIgualConst aux_menu,'A',ad_cambiar_claves
		carga menu,3 ;Ingresa usuario (cambiar accesos)
		call menu4
		LCD_GoTo  5,1						; Pasa a la columna "0", Línea "1"
		imprimelit ' '	
		imprimelit ' '
		imprimelit ' '
		carga aux_menu,'Y'
		goto final_admina
ad_cambiar_claves:
		call menu4
		carga menu,3 ;ingresar usuario (cambiar claves)
		carga aux_menu,'X'
final_admina:
	clrf cont_clave
	clrf d1
	clrf d2
	clrf d3
	clrf d4
Afinaldigitos:
	goto finalmenus_2
;================== MENU 6===========================
emenu6_2:
	movlw 0x01
	addwf cont_clave	
	SaltaSiVarIgualConst cont_clave,1,Cdigito1
	SaltaSiVarIgualConst cont_clave,2,Cdigito2
	SaltaSiVarIgualConst cont_clave,3,Cdigito3
	goto Cdigito4
Cdigito1:
	llena d1,almacenaje
	call menu5
	goto Cfinaldigitos 
Cdigito2:
	llena d2,almacenaje
	call menu5
	goto Cfinaldigitos 
Cdigito3:
	llena d3,almacenaje
	call menu5
	goto Cfinaldigitos 
Cdigito4:
	llena d4,almacenaje
	call menu5
	call T100mS
	call T100mS
	call T100mS
	call VALIDA_ADMIN
	call VERIFICA_ACCESO
	clrf cont_clave
Cfinaldigitos:
	
;================== FINAL DE LOS MENUS===========================
finalmenus_2:
	carga almacenaje,0
NoTecla:

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	;DETECTA SENSOR BIT 7 PUERTO C COMO ENTREADA Y BIT 0 COMO SALIDA
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	Detecta_sensor
	goto Inicio

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ (Teclas) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	Graba_Tecla

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;LETREROS LCD 
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
menu5:
	LCD_GoTo  0,0	; Pasa a la columna "0", Línea "0"	
	;INGRESE 4 DIGTOS
	imprimelit 'I'  ;1
	imprimelit 'N'  ;2
	imprimelit 'G'  ;3
	imprimelit 'R'  ;4
	imprimelit 'E'  ;5
	imprimelit 'S'  ;6
	imprimelit 'E'  ;7
	imprimelit ' '  ;8
	imprimelit '4'  ;9
	imprimelit ' '  ;10
	imprimelit 'D'  ;11
	imprimelit 'I'  ;12
	imprimelit 'G'  ;13
	imprimelit 'T'  ;14
	imprimelit 'O'  ;15
	imprimelit 'S'  ;16
	LCD_GoTo  0,1; Pasa a la columna "0", Línea "1"
	;LETRERO RARO QUE NO PIENSO ESCRIBIR JEJE
	imprimelit ' '  ;1
	imprimelit ' '  ;2
	imprimelit ' '  ;3
	imprimelit ' '  ;4
	imprimelit ' '  ;5
	imprimevar d1  ;6
	imprimevar d2  ;7
	imprimevar d3  ;8
	imprimevar d4  ;9
	imprimelit ' '  ;10
	imprimelit ' '  ;11
	imprimelit ' '  ;12
	imprimelit ' '  ;13
	imprimelit ' '  ;14
	imprimelit ' '  ;15
	imprimelit ' '  ;16
	return

menu6:
	call LEE_SALAS_EEPROM
	LCD_GoTo  0,0	; Pasa a la columna "0", Línea "0"	
	;CONF(1-4) #M *AD
	imprimelit 'C'  ;1
	imprimelit 'O'  ;2
	imprimelit 'N'  ;3
	imprimelit 'F'  ;4
	imprimelit '('  ;5
	imprimelit '1'  ;6
	imprimelit '-'  ;7
	imprimelit '4'  ;8
	imprimelit ')'  ;9
	imprimelit ' '  ;10
	imprimelit 'M'  ;11
	imprimelit 'E'  ;12
	imprimelit 'N'  ;13
	imprimelit 'U'  ;14
	imprimelit '='  ;15
	imprimelit '#'  ;16
	LCD_GoTo  0,1; Pasa a la columna "0", Línea "1"
	;LETRERO RARO QUE NO PIENSO ESCRIBIR JEJE
	imprimelit 'U'  ;1
	imprimelit 's'  ;2
	imprimelit ':'  ;3
	imprimevar usuario  ;4
	imprimelit ' '  ;5
	imprimelit '1'  ;6
	imprimevar d1  ;7
	imprimelit ' '  ;8
	imprimelit '2'  ;9
	imprimevar d2  ;10
	imprimelit ' '  ;11
	imprimelit '3'  ;12
	imprimevar d3  ;13
	imprimelit ' '  ;14
	imprimelit '4'  ;15
	imprimevar d4  ;16
	return
	


;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;MACROS DE LCD Y RETARDOS DE TIEMPO
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	
	#INCLUDE "LCD_4Bits_PORTB.inc"	; Manejador de la LCD.
  	#INCLUDE "Tiempo.inc"						; Retardos y temporizados.

;=============================================================================
;====================( SUBRUTINAS EEPROM + otras)================================================
;================================================================================
;---------------------------------------------------------
LIMPIA_LCD:
	LCD_Clear
	return
;---------------------------------------------------------
ESCRIBE_CLAVES_EEPROM:
	SaltaSiVarIgualConst usuario,'1',clave_usuario1
	SaltaSiVarIgualConst usuario,'2',clave_usuario2
	SaltaSiVarIgualConst usuario,'3',clave_usuario3
	SaltaSiVarIgualConst usuario,'A',clave_usuarioA
	goto final_claveA
clave_usuario1:
	movfw d1
	banco2
	movwf	EEDATA		;DATO = d1
	movlw .0
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d2
	banco2
	movwf	EEDATA		;DATO = d2
	movlw .1
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d3
	banco2
	movwf	EEDATA		;DATO = d3
	movlw .2
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d4
	banco2
	movwf	EEDATA		;DATO = d4
	movlw .3
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	goto final_claveA   
clave_usuario2:
	movfw d1
	banco2
	movwf	EEDATA		;DATO = d1
	movlw .4
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d2
	banco2
	movwf	EEDATA		;DATO = d2
	movlw .5
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d3
	banco2
	movwf	EEDATA		;DATO = d3
	movlw .6
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d4
	banco2
	movwf	EEDATA		;DATO = d4
	movlw .7
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	goto final_claveA   
clave_usuario3:
	movfw d1
	banco2
	movwf	EEDATA		;DATO = d1
	movlw .8
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d2
	banco2
	movwf	EEDATA		;DATO = d2
	movlw .9
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d3
	banco2
	movwf	EEDATA		;DATO = d3
	movlw .10
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d4
	banco2
	movwf	EEDATA		;DATO = d4
	movlw .11
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	goto final_claveA   
clave_usuarioA:
	movfw d1
	banco2
	movwf	EEDATA		;DATO = d1
	movlw .20
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d2
	banco2
	movwf	EEDATA		;DATO = d2
	movlw .21
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d3
	banco2
	movwf	EEDATA		;DATO = d3
	movlw .22
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d4
	banco2
	movwf	EEDATA		;DATO = d4
	movlw .23
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
final_claveA:	 
	return
;---------------------------------------------------------
ESCRIBE_SALAS_EEPROM:
	SaltaSiVarIgualConst usuario,'1',Asala_usuario1
	SaltaSiVarIgualConst usuario,'2',Asala_usuario2
	SaltaSiVarIgualConst usuario,'3',Asala_usuario3
	goto final_salaA
Asala_usuario1:
	movfw d1
	banco2
	movwf	EEDATA		;DATO = d1
	movlw .24
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d2
	banco2
	movwf	EEDATA		;DATO = d2
	movlw .25
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d3
	banco2
	movwf	EEDATA		;DATO = d3
	movlw .26
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d4
	banco2
	movwf	EEDATA		;DATO = d4
	movlw .27
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	goto final_salaA   
Asala_usuario2:
	movfw d1
	banco2
	movwf	EEDATA		;DATO = d1
	movlw .28
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d2
	banco2
	movwf	EEDATA		;DATO = d2
	movlw .29
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d3
	banco2
	movwf	EEDATA		;DATO = d3
	movlw .30
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d4
	banco2
	movwf	EEDATA		;DATO = d4
	movlw .31
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	goto final_salaA   
Asala_usuario3:
	movfw d1
	banco2
	movwf	EEDATA		;DATO = d1
	movlw .32
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d2
	banco2
	movwf	EEDATA		;DATO = d2
	movlw .33
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d3
	banco2
	movwf	EEDATA		;DATO = d3
	movlw .34
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------
	movfw d4
	banco2
	movwf	EEDATA		;DATO = d4
	movlw .35
	movwf	EEADR		;DIRECCION EEPROM=0
	call EEWR
	;-----------------------	
final_salaA:	
	return	
;---------------------------------------------------------
LEE_SALAS_EEPROM:
	SaltaSiVarIgualConst usuario,'1',Bsala_usuario1
	SaltaSiVarIgualConst usuario,'2',Bsala_usuario2
	SaltaSiVarIgualConst usuario,'3',Bsala_usuario3
	goto final_salaB
Bsala_usuario1:
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .24 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf d1
	;-------------- SE LEE EL LA DIRECCION 25 EN LA EEPROM ------------
	banco2
	movlw  .25 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf d2
	;-------------- SE LEE EL LA DIRECCION 26 EN LA EEPROM ------------
	banco2
	movlw  .26 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf d3
	;-------------- SE LEE EL LA DIRECCION 27 EN LA EEPROM ------------
	banco2
	movlw  .27 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf d4
	goto final_salaB   
Bsala_usuario2:
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .28 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf d1
	;-------------- SE LEE EL LA DIRECCION 25 EN LA EEPROM ------------
	banco2
	movlw  .29 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf d2
	;-------------- SE LEE EL LA DIRECCION 26 EN LA EEPROM ------------
	banco2
	movlw  .30 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf d3
	;-------------- SE LEE EL LA DIRECCION 27 EN LA EEPROM ------------
	banco2
	movlw  .31 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf d4
	goto final_salaB   
Bsala_usuario3:
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .32 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf d1
	;-------------- SE LEE EL LA DIRECCION 25 EN LA EEPROM ------------
	banco2
	movlw  .33 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf d2
	;-------------- SE LEE EL LA DIRECCION 26 EN LA EEPROM ------------
	banco2
	movlw  .34 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf d3
	;-------------- SE LEE EL LA DIRECCION 27 EN LA EEPROM ------------
	banco2
	movlw  .35 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf d4
final_salaB:	
	return
;---------------------------------------------------------
VERIFICA_ACCESO: 
	call LEE_SALAS_EEPROM
	SaltaSiVarDiferenteConst sala,'1',vsala2
	SaltaSiVarDiferenteConst d1,'S',vsala2
	call menu1
	call T1S
	goto reinicia_var
vsala2:
	SaltaSiVarDiferenteConst sala,'2',vsala3
	SaltaSiVarDiferenteConst d2,'S',vsala3
	call menu1
	call T1S
	goto reinicia_var
vsala3:
	SaltaSiVarDiferenteConst sala,'3',vsala4
	SaltaSiVarDiferenteConst d3,'S',vsala4
	call menu1
	call T1S
	goto reinicia_var
vsala4:
	SaltaSiVarDiferenteConst sala,'4',vsalaadmin
	SaltaSiVarDiferenteConst d4,'S',vsalaadmin
	call menu1
	call T1S
	goto reinicia_var
vsalaadmin:
	SaltaSiVarDiferenteConst usuario,'A',vsalarechaza
	call menu1
	call T1S
	goto reinicia_var
vsalarechaza:
	call menu2
	call T1S	
reinicia_var:
	call menu0
	clrf menu
    clrf d1       
    clrf d2
    clrf d3
    clrf d4
    clrf usuario
    clrf sala	
	return
;---------------------------------------------------------
VALIDA_ADMIN:
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .0
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom1
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .1 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom2
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .2 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom3
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .3 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom4
	;------------------------------------------------------------
	SaltaSiVarDiferenteVar d1,aux_eeprom1,A_user2
	SaltaSiVarDiferenteVar d2,aux_eeprom2,A_user2
	SaltaSiVarDiferenteVar d3,aux_eeprom3,A_user2
	SaltaSiVarDiferenteVar d4,aux_eeprom4,A_user2
	carga usuario,'1'
	goto A_final_users
A_user2:
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .4 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom1
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .5 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom2
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .6 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom3
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .7 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom4
	;------------------------------------------------------------
	SaltaSiVarDiferenteVar d1,aux_eeprom1,A_user3
	SaltaSiVarDiferenteVar d2,aux_eeprom2,A_user3
	SaltaSiVarDiferenteVar d3,aux_eeprom3,A_user3
	SaltaSiVarDiferenteVar d4,aux_eeprom4,A_user3
	carga usuario,'2'
	goto A_final_users
A_user3:
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .8 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom1
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .9 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom2
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .10 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom3
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .11 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom4
	;------------------------------------------------------------
	SaltaSiVarDiferenteVar d1,aux_eeprom1,A_userA
	SaltaSiVarDiferenteVar d2,aux_eeprom2,A_userA
	SaltaSiVarDiferenteVar d3,aux_eeprom3,A_userA
	SaltaSiVarDiferenteVar d4,aux_eeprom4,A_userA
	carga usuario,'3'
	goto A_final_users
A_userA:
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .20 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom1
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .21 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom2
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .22 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom3
	;-------------- SE LEE EL LA DIRECCION 24 EN LA EEPROM ------------
	banco2
	movlw  .23 
	movwf	EEADR		;DIRECCION EEPROM=44
	call	EERD		;LEE EN EEPROM, RESULTADO EN W
	movwf aux_eeprom4
	;------------------------------------------------------------
	SaltaSiVarDiferenteVar d1,aux_eeprom1,A_Rechaza
	SaltaSiVarDiferenteVar d2,aux_eeprom2,A_Rechaza
	SaltaSiVarDiferenteVar d3,aux_eeprom3,A_Rechaza
	SaltaSiVarDiferenteVar d4,aux_eeprom4,A_Rechaza
	carga usuario,'A'
	carga llave,1
	goto A_final_users
A_Rechaza:
	clrf usuario
	clrf llave
A_final_users:
	clrf aux_eeprom1
	clrf aux_eeprom2
	clrf aux_eeprom3
	clrf aux_eeprom4
return

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
;==========================================================
	END
