;======================================================================
;	TM9918 AND V9958 VDU DRIVER
;
;	WRITTEN BY: DOUGLAS GOODALL
;	UPDATED BY: WAYNE WARTHEN -- 4/7/2013
;       UPDATED BY: DEAN NETHERTON -- 5/26/2021 - V9958 SUPPORT
;======================================================================
;
; TODO:
;   - IMPLEMENT SET CURSOR STYLE (VDASCS) FUNCTION?
;   - IMPLEMENT ALTERNATE DISPLAY MODES?
;   - IMPLEMENT DYNAMIC READ/WRITE OF CHARACTER BITMAP DATA?
;
;======================================================================
; TMS DRIVER - CONSTANTS
;======================================================================
;

TMSCTRL1:       .EQU   1               ; CONTROL BITS
TMSINTEN:       .EQU   5               ; INTERRUPT ENABLE BIT

#IF TMSTIMENABLE
	.ECHO	"TMS INTERRUPTS ENABLED\n"
#ENDIF

#IF ((TMSMODE == TMSMODE_MSX) | (TMSMODE == TMSMODE_MSX9958))
TMS_DATREG	.EQU	$98		; READ/WRITE DATA
TMS_CMDREG	.EQU	$99		; READ STATUS / WRITE REG SEL
TMS_PPIA	.EQU	0		; PPI PORT A
TMS_PPIB	.EQU	0		; PPI PORT B
TMS_PPIC	.EQU	0		; PPI PORT C
TMS_PPIX	.EQU	0		; PPI CONTROL PORT
#ENDIF

#IF (TMSMODE == TMSMODE_COLECO))
TMS_DATREG	.EQU	$BE		; READ/WRITE DATA
TMS_CMDREG	.EQU	$BF		; READ STATUS / WRITE REG SEL
TMS_PPIA	.EQU	0		; PPI PORT A
TMS_PPIB	.EQU	0		; PPI PORT B
TMS_PPIC	.EQU	0		; PPI PORT C
TMS_PPIX	.EQU	0		; PPI CONTROL PORT
#ENDIF

#IF (TMSMODE == TMSMODE_MSXKBD)
TMS_DATREG	.EQU	$98		; READ/WRITE DATA
TMS_CMDREG	.EQU	$99		; READ STATUS / WRITE REG SEL
TMS_KBDDATA	.EQU	$E0		; KBD CTLR DATA PORT
TMS_KBDST	.EQU	$E1		; KBD CTLR STATUS/CMD PORT
#ENDIF

#IF (TMSMODE == TMSMODE_N8)
TMS_DATREG	.EQU	$98		; READ/WRITE DATA
TMS_CMDREG	.EQU	$99		; READ STATUS / WRITE REG SEL
TMS_PPIA	.EQU	$84		; PPI PORT A
TMS_PPIB	.EQU	$85		; PPI PORT B
TMS_PPIC	.EQU	$86		; PPI PORT C
TMS_PPIX	.EQU	$87		; PPI CONTROL PORT
#ENDIF

#IF (TMSMODE == TMSMODE_SCG)
TMS_DATREG	.EQU	$98		; READ/WRITE DATA
TMS_CMDREG	.EQU	$99		; READ STATUS / WRITE REG SEL
TMS_ACR		.EQU	$9C		; AUX CONTROL REGISTER
TMS_PPIA	.EQU	0		; PPI PORT A
TMS_PPIB	.EQU	0		; PPI PORT B
TMS_PPIC	.EQU	0		; PPI PORT C
TMS_PPIX	.EQU	0		; PPI CONTROL PORT
#ENDIF
;
#IF (TMSMODE == TMSMODE_MBC)

TMS_DATREG	.EQU	$98		; READ/WRITE DATA
TMS_CMDREG	.EQU	$99		; READ STATUS / WRITE REG SEL
TMS_ACR		.EQU	$9C		; AUX CONTROL REGISTER
TMS_PPIA	.EQU	0		; PPI PORT A
TMS_PPIB	.EQU	0		; PPI PORT B
TMS_PPIC	.EQU	0		; PPI PORT C
TMS_PPIX	.EQU	0		; PPI CONTROL PORT
TMS_KBDDATA	.EQU	$E2		; KBD CTLR DATA PORT
TMS_KBDST	.EQU	$E3		; KBD CTLR STATUS/CMD PORT
#ENDIF

TMS_ROWS	.EQU	24

#IF ((TMSMODE == TMSMODE_MSX9958) | (TMSMODE == TMSMODE_MBC))
TMS_FNTVADDR	.EQU	$1000		; VRAM ADDRESS OF FONT DATA
TMS_COLS	.EQU	80
#ELSE
TMS_FNTVADDR	.EQU	$0800		; VRAM ADDRESS OF FONT DATA
TMS_COLS	.EQU	40
#ENDIF
;
#DEFINE USEFONT8X8
#DEFINE	TMS_FONT FONT8X8
;
TERMENABLE	.SET	TRUE		; INCLUDE TERMINAL PSEUDODEVICE DRIVER
;
; TMS_IODELAY IS USED TO ADD RECOVERY TIME TO TMS9918/V9958 ACCESSES
; IF YOU SEE SCREEN CORRUPTION, ADJUST THIS!!!
;
#IF (CPUFAM == CPU_Z180)
; BELOW WAS TUNED FOR Z180 AT 18MHZ
#DEFINE		TMS_IODELAY	EX (SP),HL \ EX (SP),HL	; 38 W/S
#ELSE
; BELOW WAS TUNED FOR SBC AT 8MHZ
#IF ((TMSMODE == TMSMODE_MSX9958) | (TMSMODE == TMSMODE_MBC))
#DEFINE		TMS_IODELAY	NOP \ NOP \ NOP \ NOP \ NOP \ NOP \ NOP ; V9958 NEEDS AT WORST CASE, APPROX 4us (28T) DELAY BETWEEN I/O (WHEN IN TEXT MODE)
#ELSE
#DEFINE		TMS_IODELAY	NOP \ NOP ; 8 W/S
#ENDIF
#ENDIF
;
;======================================================================
; TMS DRIVER - INITIALIZATION
;======================================================================
;
TMS_PREINIT:
	; DISABLE INTERRUPT GENERATION
	LD	A, (TMS_INITVDU_REG_1)
        RES	TMSINTEN, A             ; RESET INTERRUPT ENABLE BIT
	LD	(TMS_INITVDU_REG_1), A
        LD	C, TMSCTRL1
	JP	TMS_SET
;
TMS_INIT:
#IF (CPUFAM == CPU_Z180)
	CALL	TMS_Z180IO
#ENDIF
;
#IF ((TMSMODE == TMSMODE_SCG) | (TMSMODE == TMSMODE_MBC))
	LD	A,$FF
	OUT	(TMS_ACR),A		; INIT AUX CONTROL REG
#ENDIF
;
	CALL	NEWLINE			; FORMATTING
	PRTS("TMS: MODE=$")

#IF ((TMSMODE == TMSMODE_MBC))
	LD	A,$FE
	OUT	(TMS_ACR),A		; INIT AUX CONTROL REG
#ENDIF


	LD	IY,TMS_IDAT		; POINTER TO INSTANCE DATA
;
#IF (TMSMODE == TMSMODE_SCG)
	PRTS("SCG$")
#ENDIF
#IF (TMSMODE == TMSMODE_MBC)
	PRTS("MBC$")
#ENDIF
#IF (TMSMODE == TMSMODE_N8)
	PRTS("N8$")
#ENDIF
#IF (TMSMODE == TMSMODE_MSX)
	PRTS("MSX$")
#ENDIF
#IF (TMSMODE == TMSMODE_MSXKBD)
	PRTS("RCKBD$")
#ENDIF
#IF (TMSMODE == TMSMODE_MSX9958)
	PRTS("RC_V9958$")
#ENDIF
;
	PRTS(" IO=0x$")
	LD	A,TMS_DATREG
	CALL	PRTHEXBYTE
	CALL	TMS_PROBE		; CHECK FOR HW EXISTENCE
	JR	Z,TMS_INIT1		; CONTINUE IF PRESENT
;
	; HARDWARE NOT PRESENT
	PRTS(" NOT PRESENT$")
	OR	$FF			; SIGNAL FAILURE
	RET
;
TMS_INIT1:
	CALL 	TMS_CRTINIT		; SETUP THE TMS CHIP REGISTERS
	CALL	TMS_LOADFONT		; LOAD FONT DATA FROM ROM TO TMS STRORAGE
	CALL	TMS_VDARES1
#IF (TMSMODE == TMSMODE_N8)
	CALL	PPK_INIT		; INITIALIZE PPI KEYBOARD DRIVER
#ENDIF
#IF ((TMSMODE == TMSMODE_MSXKBD) | (TMSMODE == TMSMODE_MBC))
	CALL	KBD_INIT		; INITIALIZE 8242 KEYBOARD DRIVER
#ENDIF
#IF MKYENABLE
	CALL	MKY_INIT		; INITIALIZE MKY KEYBOARD DRIVER
#ENDIF

#IF (INTMODE == 1 & TMSTIMENABLE)
	; ADD IM1 INT CALL LIST ENTRY
	LD	HL, TMS_TSTINT		; GET INT VECTOR
	CALL	HB_ADDIM1		; ADD TO IM1 CALL LIST

	LD	A, (TMS_INITVDU_REG_1)
        SET	TMSINTEN, A             ; SET INTERRUPT ENABLE BIT
	LD	(TMS_INITVDU_REG_1), A
        LD	C, TMSCTRL1
	CALL	TMS_SET
#ENDIF
;
	; ADD OURSELVES TO VDA DISPATCH TABLE
	LD	BC,TMS_FNTBL		; BC := FUNCTION TABLE ADDRESS
	LD	DE,TMS_IDAT		; DE := TMS INSTANCE DATA PTR
	CALL	VDA_ADDENT		; ADD ENTRY, A := UNIT ASSIGNED
;
	; INITIALIZE EMULATION
	LD	C,A			; C := ASSIGNED VIDEO DEVICE NUM
	LD	DE,TMS_FNTBL		; DE := FUNCTION TABLE ADDRESS
	LD	HL,TMS_IDAT		; HL := TMS INSTANCE DATA PTR
	CALL	TERM_ATTACH		; DO IT
;
	XOR	A			; SIGNAL SUCCESS
	RET
;
;======================================================================
; TMS DRIVER - VIDEO DISPLAY ADAPTER (VDA) FUNCTIONS
;======================================================================
;
TMS_FNTBL:
	.DW	TMS_VDAINI
	.DW	TMS_VDAQRY
	.DW	TMS_VDARES
	.DW	TMS_VDADEV
	.DW	TMS_VDASCS
	.DW	TMS_VDASCP
	.DW	TMS_VDASAT
	.DW	TMS_VDASCO
	.DW	TMS_VDAWRC
	.DW	TMS_VDAFIL
	.DW	TMS_VDACPY
	.DW	TMS_VDASCR
#IF (TMSMODE == TMSMODE_N8)
	.DW	PPK_STAT
	.DW	PPK_FLUSH
	.DW	PPK_READ
#ELSE
  #IF  ((TMSMODE == TMSMODE_MSXKBD) | (TMSMODE == TMSMODE_MBC))
  	.DW	KBD_STAT
  	.DW	KBD_FLUSH
  	.DW	KBD_READ
  #ELSE
    #IF MKYENABLE
  	.DW	MKY_STAT
  	.DW	MKY_FLUSH
  	.DW	MKY_READ

    #ELSE
  	.DW	TMS_STAT
  	.DW	TMS_FLUSH
  	.DW	TMS_READ
    #ENDIF
  #ENDIF
#ENDIF
	.DW	TMS_VDARDC
#IF (($ - TMS_FNTBL) != (VDA_FNCNT * 2))
	.ECHO	"*** INVALID TMS FUNCTION TABLE ***\n"
	!!!!!
#ENDIF

TMS_VDAINI:
	; RESET VDA
	; CURRENTLY IGNORES VIDEO MODE AND BITMAP DATA
	CALL	TMS_VDARES		; RESET VDA
	XOR	A			; SIGNAL SUCCESS
	RET

TMS_VDAQRY:
	LD	C,$00		; MODE ZERO IS ALL WE KNOW
	LD	D,TMS_ROWS	; ROWS
	LD	E,TMS_COLS	; COLS
	LD	HL,0		; EXTRACTION OF CURRENT BITMAP DATA NOT SUPPORTED YET
	XOR	A		; SIGNAL SUCCESS
	RET

TMS_VDARES:
#IF (CPUFAM == CPU_Z180)
	CALL	TMS_Z180IO
#ENDIF
TMS_VDARES1:	; ENTRY POINT TO AVOID TMS_Z180IO RECURSION
	LD	DE,0			; ROW = 0, COL = 0
	CALL	TMS_XY			; SEND CURSOR TO TOP LEFT
	LD	A,' '			; BLANK THE SCREEN
	LD	DE,TMS_ROWS * TMS_COLS	; FILL ENTIRE BUFFER
	CALL	TMS_FILL		; DO IT
	LD	DE,0			; ROW = 0, COL = 0
	CALL	TMS_XY			; SEND CURSOR TO TOP LEFT
	XOR	A
	DEC	A
	LD	(TMS_CURSAV),A
	CALL	TMS_SETCUR		; SET CURSOR

	XOR	A			; SIGNAL SUCCESS
	RET

TMS_VDADEV:
	LD	D,VDADEV_TMS	; D := DEVICE TYPE
	LD	E,0		; E := PHYSICAL UNIT IS ALWAYS ZERO
	LD	H,TMSMODE	; H := MODE
	LD	L,TMS_DATREG	; L := BASE I/O ADDRESS
	XOR	A		; SIGNAL SUCCESS
	RET

TMS_VDASCS:
	SYSCHKERR(ERR_NOTIMPL)		; NOT IMPLEMENTED (YET)
	RET

TMS_VDASCP:
#IF (CPUFAM == CPU_Z180)
	CALL	TMS_Z180IO
#ENDIF
	CALL	TMS_CLRCUR
	CALL	TMS_XY		; SET CURSOR POSITION
	CALL	TMS_SETCUR
	XOR	A		; SIGNAL SUCCESS
	RET

TMS_VDASAT:
	XOR	A		; NOT POSSIBLE, JUST SIGNAL SUCCESS
	RET

TMS_VDASCO:
	XOR	A		; NOT POSSIBLE, JUST SIGNAL SUCCESS
	RET

TMS_VDAWRC:
#IF (CPUFAM == CPU_Z180)
	CALL	TMS_Z180IO
#ENDIF
	CALL	TMS_CLRCUR	; CURSOR OFF
	LD	A,E		; CHARACTER TO WRITE GOES IN A
	CALL	TMS_PUTCHAR	; PUT IT ON THE SCREEN
	CALL	TMS_SETCUR
	XOR	A		; SIGNAL SUCCESS
	RET

TMS_VDAFIL:
#IF (CPUFAM == CPU_Z180)
	CALL	TMS_Z180IO
#ENDIF
	CALL	TMS_CLRCUR
	LD	A,E		; FILL CHARACTER GOES IN A
	EX	DE,HL		; FILL LENGTH GOES IN DE
	CALL	TMS_FILL	; DO THE FILL
	CALL	TMS_SETCUR
	XOR	A		; SIGNAL SUCCESS
	RET

TMS_VDACPY:
#IF (CPUFAM == CPU_Z180)
	CALL	TMS_Z180IO
#ENDIF
	CALL	TMS_CLRCUR
	; LENGTH IN HL, SOURCE ROW/COL IN DE, DEST IS TMS_POS
	; BLKCPY USES: HL=SOURCE, DE=DEST, BC=COUNT
	PUSH	HL		; SAVE LENGTH
	CALL	TMS_XY2IDX	; ROW/COL IN DE -> SOURCE ADR IN HL
	POP	BC		; RECOVER LENGTH IN BC
	LD	DE,(TMS_POS)	; PUT DEST IN DE
	CALL	TMS_BLKCPY	; DO A BLOCK COPY
	CALL	TMS_SETCUR
	XOR	A
	RET

TMS_VDASCR:
#IF (CPUFAM == CPU_Z180)
	CALL	TMS_Z180IO
#ENDIF
	CALL	TMS_CLRCUR
TMS_VDASCR0:
	LD	A,E		; LOAD E INTO A
	OR	A		; SET FLAGS
	JR	Z,TMS_VDASCR2	; IF ZERO, WE ARE DONE
	PUSH	DE		; SAVE E
	JP	M,TMS_VDASCR1	; E IS NEGATIVE, REVERSE SCROLL
	CALL	TMS_SCROLL	; SCROLL FORWARD ONE LINE
	POP	DE		; RECOVER E
	DEC	E		; DECREMENT IT
	JR	TMS_VDASCR0	; LOOP
TMS_VDASCR1:
	CALL	TMS_RSCROLL	; SCROLL REVERSE ONE LINE
	POP	DE		; RECOVER E
	INC	E		; INCREMENT IT
	JR	TMS_VDASCR0	; LOOP
TMS_VDASCR2:
	CALL	TMS_SETCUR
	XOR	A
	RET

;----------------------------------------------------------------------
; READ VALUE AT CURRENT VDU BUFFER POSITION
; RETURN E = CHARACTER, B = COLOUR, C = ATTRIBUTES
;----------------------------------------------------------------------

TMS_VDARDC:
	OR	$FF		; UNSUPPORTED FUNCTION
	RET

; DUMMY FUNCTIONS BELOW BECAUSE SCG BOARD HAS NO
; KEYBOARD INTERFACE

TMS_STAT:
	XOR	A		; SIGNAL NOTHING READY
	JP	CIO_IDLE	; DO IDLE PROCESSING

TMS_FLUSH:
	XOR	A		; SIGNAL SUCCESS
	RET

TMS_READ:
	LD	E,26		; RETURN <SUB> (CTRL-Z)
	XOR	A		; SIGNAL SUCCESS
	RET
;
;======================================================================
; TMS DRIVER - PRIVATE DRIVER FUNCTIONS
;======================================================================
;
;----------------------------------------------------------------------
; SET TMS9918 REGISTER VALUE
;   TMS_SET WRITES VALUE IN A TO VDU REGISTER SPECIFIED IN C
;----------------------------------------------------------------------
;
TMS_SET:
	OUT	(TMS_CMDREG),A		; WRITE IT
	TMS_IODELAY
	LD	A,C			; GET THE DESIRED REGISTER
	OR	$80			; SET BIT 7
	OUT	(TMS_CMDREG),A		; SELECT THE DESIRED REGISTER
	TMS_IODELAY
	RET
;
;----------------------------------------------------------------------
; SET TMS9918 READ/WRITE ADDRESS
;   TMS_WR SETS TMS9918 TO BEGIN WRITING AT VDU ADDRESS SPECIFIED IN HL
;   TMS_RD SETS TMS9918 TO BEGIN READING AT VDU ADDRESS SPECIFIED IN HL
;----------------------------------------------------------------------
;
TMS_WR:
#IF ((TMSMODE == TMSMODE_MSX9958)  | (TMSMODE == TMSMODE_MBC))
        ; CLEAR R#14 FOR V9958
        XOR     A
        OUT     (TMS_CMDREG), A
	TMS_IODELAY
        LD      A, $80 | 14
        OUT     (TMS_CMDREG), A
	TMS_IODELAY
#ENDIF

	PUSH	HL
	SET	6,H			; SET WRITE BIT
	CALL	TMS_RD
	POP	HL
	RET
;
TMS_RD:
	LD	A,L
	OUT	(TMS_CMDREG),A
	TMS_IODELAY
	LD	A,H
	OUT	(TMS_CMDREG),A
	TMS_IODELAY
	RET
;
;----------------------------------------------------------------------
; PROBE FOR TMS HARDWARE
;----------------------------------------------------------------------
;
; ON RETURN, ZF SET INDICATES HARDWARE FOUND
;
TMS_PROBE:
	; SET WRITE ADDRESS TO $0
	LD	HL,0
	CALL	TMS_WR
	; WRITE TEST PATTERN TO FIRST TWO BYTES
	LD	A,$A5			; FIRST BYTE
	OUT	(TMS_DATREG),A		; OUTPUT
	;TMS_IODELAY			; DELAY
	CALL	DLY64			; DELAY
	CPL				; COMPLEMENT ACCUM
	OUT	(TMS_DATREG),A		; SECOND BYTE
	;TMS_IODELAY			; DELAY
	CALL	DLY64			; DELAY
	; SET READ ADDRESS TO $0
	LD	HL,0
	CALL	TMS_RD
	; READ TEST PATTERN
	LD	C,$A5			; VALUE TO EXPECT
	IN	A,(TMS_DATREG)		; READ FIRST BYTE
	;CALL	PRTHEXBYTE
	;TMS_IODELAY			; DELAY
	CALL	DLY64			; DELAY
	CP	C			; COMPARE
	RET	NZ			; RETURN ON MISCOMPARE
	IN	A,(TMS_DATREG)		; READ SECOND BYTE
	;CALL	PRTHEXBYTE
	;TMS_IODELAY			; DELAY
	CALL	DLY64			; DELAY
	CPL				; COMPLEMENT IT
	CP	C			; COMPARE
	RET				; RETURN WITH RESULT IN Z
;
;----------------------------------------------------------------------
; TMS9918 DISPLAY CONTROLLER CHIP INITIALIZATION
;----------------------------------------------------------------------
;
TMS_CRTINIT:
	; SET WRITE ADDRESS TO $0
	LD	HL,0
	CALL	TMS_WR
;
	; FILL ENTIRE RAM CONTENTS
	LD	DE,$4000
TMS_CRTINIT1:
	XOR	A
	OUT	(TMS_DATREG),A
	TMS_IODELAY			; DELAY
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,TMS_CRTINIT1
;
	; INITIALIZE VDU REGISTERS
    	LD 	C,0			; START WITH REGISTER 0
	LD	B,TMS_INITVDULEN	; NUMBER OF REGISTERS TO INIT
    	LD 	HL,TMS_INITVDU		; HL = POINTER TO THE DEFAULT VALUES
TMS_CRTINIT2:
	LD	A,(HL)			; GET VALUE
	CALL	TMS_SET			; WRITE IT
	INC	HL			; POINT TO NEXT VALUE
	INC	C			; POINT TO NEXT REGISTER
	DJNZ	TMS_CRTINIT2		; LOOP
;
	; ENABLE WAIT SIGNAL IF 9938/58
#IF ((TMSMODE == TMSMODE_MSX9958) | (TMSMODE == TMSMODE_MBC))
	LD	C,25			; REGISTER 25
	LD	A,%00000100		; ONLY WTE BIT SET
	CALL	TMS_SET			; DO IT
#ENDIF
    	RET
;
;----------------------------------------------------------------------
; LOAD FONT DATA
;----------------------------------------------------------------------
;
TMS_LOADFONT:
	; SET WRITE ADDRESS TO TMS_FNTVADDR
	LD	HL,TMS_FNTVADDR
	CALL	TMS_WR

#IF USELZSA2
	LD	(TMS_STACK),SP		; SAVE STACK
	LD	HL,(TMS_STACK)		; AND SHIFT IT
	LD	DE,$2000		; DOWN 4KB TO
	CCF				; CREATE A
	SBC	HL,DE			; DECOMPRESSION BUFFER
	LD	SP,HL			; HL POINTS TO BUFFER
	EX	DE,HL			; START OF STACK BUFFER
	PUSH	DE			; SAVE IT
	LD	HL,TMS_FONT		; START OF FONT DATA
	CALL	DLZSA2			; DECOMPRESS TO DE
	POP	HL			; RECALL STACK BUFFER POSITION
#ELSE
	LD	HL,TMS_FONT		; START OF FONT DATA
#ENDIF
;
	; FILL TMS_FNTVADDR BYTES FROM FONTDATA
	LD	DE,TMS_FNTVADDR
TMS_LOADFONT1:
	LD	A,(HL)
	OUT	(TMS_DATREG),A
	TMS_IODELAY			; DELAY
	INC	HL
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,TMS_LOADFONT1
;
#IF USELZSA2
	LD	HL,(TMS_STACK)		; ERASE DECOMPRESS BUFFER
	LD	SP,HL			; BY RESTORING THE STACK
	RET				; DONE
TMS_STACK	.DW	0
#ELSE
	RET
#ENDIF
;
;----------------------------------------------------------------------
; VIRTUAL CURSOR MANAGEMENT
;   TMS_SETCUR CONFIGURES AND DISPLAYS CURSOR AT CURRENT CURSOR LOCATION
;   TMS_CLRCUR REMOVES THE CURSOR
;
; VIRTUAL CURSOR IS GENERATED BY DYNAMICALLY CHANGING FONT GLYPH
; FOR CHAR 255 TO BE THE INVERSE OF THE GLYPH OF THE CHARACTER UNDER
; THE CURRENT CURSOR POSITION.  THE CHARACTER CODE IS THEN SWITCH TO
; THE VALUE 255 AND THE ORIGINAL VALUE IS SAVED.  WHEN THE DISPLAY
; NEEDS TO BE CHANGED THE PROCESS IS UNDONE.  IT IS ESSENTIAL THAT
; ALL DISPLAY CHANGES BE BRACKETED WITH CALLS TO TMS_CLRCUR PRIOR TO
; CHANGES AND TMS_SETCUR AFTER CHANGES.
;----------------------------------------------------------------------
;
TMS_SETCUR:
	PUSH	HL			; PRESERVE HL
	PUSH	DE			; PRESERVE DE
	LD	HL,(TMS_POS)		; GET CURSOR POSITION
	CALL	TMS_RD			; SETUP TO READ VDU BUF
	IN	A,(TMS_DATREG)		; GET REAL CHAR UNDER CURSOR
	TMS_IODELAY			; DELAY
	PUSH	AF			; SAVE THE CHARACTER
	CALL	TMS_WR			; SETUP TO WRITE TO THE SAME PLACE
	LD	A,$FF			; REPLACE REAL CHAR WITH 255
	OUT	(TMS_DATREG),A		; DO IT
	TMS_IODELAY			; DELAY
	POP	AF			; RECOVER THE REAL CHARACTER
	LD	B,A			; PUT IT IN B
	LD	A,(TMS_CURSAV)		; GET THE CURRENTLY SAVED CHAR
	CP	B			; COMPARE TO CURRENT
	JR	Z,TMS_SETCUR3		; IF EQUAL, BYPASS EXTRA WORK
	LD	A,B			; GET REAL CHAR BACK TO A
	LD	(TMS_CURSAV),A		; SAVE IT
	; GET THE GLYPH DATA FOR REAL CHARACTER
	LD	HL,0			; ZERO HL
	LD	L,A			; HL IS NOW RAW CHAR INDEX
	LD	B,3			; LEFT SHIFT BY 3 BITS
TMS_SETCUR0:	; MULT BY 8 FOR FONT INDEX
	SLA	L			; SHIFT LSB INTO CARRY
	RL	H			; SHFT MSB FROM CARRY
	DJNZ	TMS_SETCUR0		; LOOP 3 TIMES
	LD	DE,TMS_FNTVADDR			; OFFSET TO START OF FONT TABLE
	ADD	HL,DE			; ADD TO FONT INDEX
	CALL	TMS_RD			; SETUP TO READ GLYPH
	LD	B,8			; 8 BYTES
	LD	HL,TMS_BUF		; INTO BUFFER
TMS_SETCUR1:	; READ GLYPH LOOP
	IN	A,(TMS_DATREG)		; GET NEXT BYTE
	TMS_IODELAY			; IO DELAY
	LD	(HL),A			; SAVE VALUE IN BUF
	INC	HL			; BUMP BUF POINTER
	DJNZ	TMS_SETCUR1		; LOOP FOR 8 BYTES
;
	; NOW WRITE INVERTED GLYPH INTO FONT INDEX 255
	LD	HL,TMS_FNTVADDR + (255 * 8)	; LOC OF GLPYPH DATA FOR CHAR 255
	CALL	TMS_WR			; SETUP TO WRITE THE INVERTED GLYPH
	LD	B,8			; 8 BYTES PER GLYPH
	LD	HL,TMS_BUF		; POINT TO BUFFER
TMS_SETCUR2:	; WRITE INVERTED GLYPH LOOP
	LD	A,(HL)			; GET THE BYTE
	INC	HL			; BUMP THE BUF POINTER
	XOR	$FF			; INVERT THE VALUE
	OUT	(TMS_DATREG),A		; WRITE IT TO VDU
	TMS_IODELAY			; IO DELAY
	DJNZ	TMS_SETCUR2		; LOOP FOR ALL 8 BYTES OF GLYPH
;
TMS_SETCUR3:	; RESTORE REGISTERS AND RETURN
	POP	DE			; RECOVER DE
	POP	HL			; RECOVER HL
	RET				; RETURN
;
;
;
TMS_CLRCUR:	; REMOVE VIRTUAL CURSOR FROM SCREEN
	PUSH	HL			; SAVE HL
	LD	HL,(TMS_POS)		; POINT TO CURRENT CURSOR POS
	CALL	TMS_WR			; SET UP TO WRITE TO VDU
	LD	A,(TMS_CURSAV)		; GET THE REAL CHARACTER
	OUT	(TMS_DATREG),A		; WRITE IT
	TMS_IODELAY			; IO DELAY
	POP	HL			; RECOVER HL
	RET				; RETURN
;
;----------------------------------------------------------------------
; SET CURSOR POSITION TO ROW IN D AND COLUMN IN E
;----------------------------------------------------------------------
;
TMS_XY:
	CALL	TMS_XY2IDX		; CONVERT ROW/COL TO BUF IDX
	LD	(TMS_POS),HL		; SAVE THE RESULT (DISPLAY POSITION)
	RET
;
;----------------------------------------------------------------------
; CONVERT XY COORDINATES IN DE INTO LINEAR INDEX IN HL
; D=ROW, E=COL
;----------------------------------------------------------------------
;
TMS_XY2IDX:
	LD	A,E			; SAVE COLUMN NUMBER IN A
	LD	H,D			; SET H TO ROW NUMBER
	LD	E,TMS_COLS		; SET E TO ROW LENGTH
	CALL	MULT8			; MULTIPLY TO GET ROW OFFSET
	LD	E,A			; GET COLUMN BACK
	ADD	HL,DE			; ADD IT IN
	RET				; RETURN
;
;----------------------------------------------------------------------
; WRITE VALUE IN A TO CURRENT VDU BUFFER POSTION, ADVANCE CURSOR
;----------------------------------------------------------------------
;
TMS_PUTCHAR:
	PUSH	AF			; SAVE CHARACTER
	LD	HL,(TMS_POS)		; LOAD CURRENT POSITION INTO HL
	CALL	TMS_WR			; SET THE WRITE ADDRESS
	POP	AF			; RECOVER CHARACTER TO WRITE
	OUT	(TMS_DATREG),A		; WRITE THE CHARACTER
	TMS_IODELAY
	LD	HL,(TMS_POS)		; LOAD CURRENT POSITION INTO HL
	INC	HL
	LD	(TMS_POS),HL
	RET
;
;----------------------------------------------------------------------
; FILL AREA IN BUFFER WITH SPECIFIED CHARACTER AND CURRENT COLOR/ATTRIBUTE
; STARTING AT THE CURRENT FRAME BUFFER POSITION
;   A: FILL CHARACTER
;   DE: NUMBER OF CHARACTERS TO FILL
;----------------------------------------------------------------------
;
TMS_FILL:
	LD	C,A			; SAVE THE CHARACTER TO WRITE
	LD	HL,(TMS_POS)		; SET STARTING POSITION
	CALL	TMS_WR			; SET UP FOR WRITE
;
TMS_FILL1:
	LD	A,C			; RECOVER CHARACTER TO WRITE
	OUT	(TMS_DATREG),A
	TMS_IODELAY
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,TMS_FILL1
;
	RET
;
;----------------------------------------------------------------------
; SCROLL ENTIRE SCREEN FORWARD BY ONE LINE (CURSOR POSITION UNCHANGED)
;----------------------------------------------------------------------
;
TMS_SCROLL:
	LD	HL,0			; SOURCE ADDRESS OF CHARACER BUFFER
	LD	C,TMS_ROWS - 1		; SET UP LOOP COUNTER FOR ROWS - 1
;
TMS_SCROLL0:	; READ LINE THAT IS ONE PAST CURRENT DESTINATION
	PUSH	HL			; SAVE CURRENT DESTINATION
	LD	DE,TMS_COLS
	ADD	HL,DE			; POINT TO NEXT ROW SOURCE
	CALL	TMS_RD			; SET UP TO READ
	LD	DE,TMS_BUF
	LD	B,TMS_COLS
TMS_SCROLL1:
	IN	A,(TMS_DATREG)
	TMS_IODELAY
	LD	(DE),A
	INC	DE
	DJNZ	TMS_SCROLL1
	POP	HL			; RECOVER THE DESTINATION
;
	; WRITE THE BUFFERED LINE TO CURRENT DESTINATION
	CALL	TMS_WR			; SET UP TO WRITE
	LD	DE,TMS_BUF
	LD	B,TMS_COLS
TMS_SCROLL2:
	LD	A,(DE)
	OUT	(TMS_DATREG),A
	TMS_IODELAY
	INC	DE
	DJNZ	TMS_SCROLL2
;
	; BUMP TO NEXT LINE
	LD	DE,TMS_COLS
	ADD	HL,DE
	DEC	C			; DECREMENT ROW COUNTER
	JR	NZ,TMS_SCROLL0		; LOOP THRU ALL ROWS
;
	; FILL THE NEWLY EXPOSED BOTTOM LINE
	CALL	TMS_WR
	LD	A,' '
	LD	B,TMS_COLS
TMS_SCROLL3:
	OUT	(TMS_DATREG),A
	TMS_IODELAY
	DJNZ	TMS_SCROLL3
;
	RET
;
;----------------------------------------------------------------------
; REVERSE SCROLL ENTIRE SCREEN BY ONE LINE (CURSOR POSITION UNCHANGED)
;----------------------------------------------------------------------
;
TMS_RSCROLL:
	LD	HL,TMS_COLS * (TMS_ROWS - 1)
	LD	C,TMS_ROWS - 1
;
TMS_RSCROLL0:	; READ THE LINE THAT IS ONE PRIOR TO CURRENT DESTINATION
	PUSH	HL			; SAVE THE DESTINATION ADDRESS
	LD	DE,-TMS_COLS
	ADD	HL,DE			; SET SOURCE ADDRESS
	CALL	TMS_RD			; SET UP TO READ
	LD	DE,TMS_BUF		; POINT TO BUFFER
	LD	B,TMS_COLS		; LOOP FOR EACH COLUMN
TMS_RSCROLL1:
	IN	A,(TMS_DATREG)		; GET THE CHAR
	TMS_IODELAY			; RECOVER
	LD	(DE),A			; SAVE IN BUFFER
	INC	DE			; BUMP BUFFER POINTER
	DJNZ	TMS_RSCROLL1		; LOOP THRU ALL COLS
	POP	HL			; RECOVER THE DESTINATION ADDRESS
;
	; WRITE THE BUFFERED LINE TO CURRENT DESTINATION
	CALL	TMS_WR			; SET THE WRITE ADDRESS
	LD	DE,TMS_BUF		; POINT TO BUFFER
	LD	B,TMS_COLS		; INIT LOOP COUNTER
TMS_RSCROLL2:
	LD	A,(DE)			; LOAD THE CHAR
	OUT	(TMS_DATREG),A		; WRITE TO SCREEN
	TMS_IODELAY			; DELAY
	INC	DE			; BUMP BUF POINTER
	DJNZ	TMS_RSCROLL2		; LOOP THRU ALL COLS
;
	; BUMP TO THE PRIOR LINE
	LD	DE,-TMS_COLS		; LOAD COLS (NEGATIVE)
	ADD	HL,DE			; BACK UP THE ADDRESS
	DEC	C			; DECREMENT ROW COUNTER
	JR	NZ,TMS_RSCROLL0		; LOOP THRU ALL ROWS
;
	; FILL THE NEWLY EXPOSED BOTTOM LINE
	CALL	TMS_WR
	LD	A,' '
	LD	B,TMS_COLS
TMS_RSCROLL3:
	OUT	(TMS_DATREG),A
	TMS_IODELAY
	DJNZ	TMS_RSCROLL3
;
	RET
;
;----------------------------------------------------------------------
; BLOCK COPY BC BYTES FROM HL TO DE
;----------------------------------------------------------------------
;
TMS_BLKCPY:
	; SAVE DESTINATION AND LENGTH
	PUSH	BC		; LENGTH
	PUSH	DE		; DEST
;
	; READ FROM THE SOURCE LOCATION
TMS_BLKCPY1:
	CALL	TMS_RD		; SET UP TO READ FROM ADDRESS IN HL
	LD	DE,TMS_BUF	; POINT TO BUFFER
	LD	B,C
TMS_BLKCPY2:
	IN	A,(TMS_DATREG)	; GET THE NEXT BYTE
	TMS_IODELAY		; DELAY
	LD	(DE),A		; SAVE IN BUFFER
	INC	DE		; BUMP BUF PTR
	DJNZ	TMS_BLKCPY2	; LOOP AS NEEDED
;
	; WRITE TO THE DESTINATION LOCATION
	POP	HL		; RECOVER DESTINATION INTO HL
	CALL	TMS_WR		; SET UP TO WRITE
	LD	DE,TMS_BUF	; POINT TO BUFFER
	POP	BC		; GET LOOP COUNTER BACK
	LD	B,C
TMS_BLKCPY3:
	LD	A,(DE)		; GET THE CHAR FROM BUFFER
	OUT	(TMS_DATREG),A	; WRITE TO VDU
	TMS_IODELAY		; DELAY
	INC	DE		; BUMP BUF PTR
	DJNZ	TMS_BLKCPY3	; LOOP AS NEEDED
;
	RET
;
;----------------------------------------------------------------------
; Z180 LOW SPEED I/O CODE BRACKETING
;----------------------------------------------------------------------
;
#IF (CPUFAM == CPU_Z180)
;
TMS_Z180IO:
	; HOOK CALLERS RETURN TO RESTORE DCNTL
	EX	(SP),HL			; SAVE HL & HL := RET ADR
	LD	(TMS_Z180IOR),HL	; SET RET ADR
	LD	HL,TMS_Z180IOX		; HL := SPECIAL RETURN ADR
	EX	(SP),HL			; RESTORE HL, INS NEW RET ADR
	; SET Z180 MAX I/O WAIT STATES
	PUSH	AF			; SAVE AF
	IN0	A,(Z180_DCNTL)		; GET CURRENT Z180 DCNTL
	LD	(TMS_DCNTL),A		; SAVE IT
	OR	%00110000		; NEW DCNTL VALUE (MAX I/O W/S)
	OUT0	(Z180_DCNTL),A		; IMPLEMENT IT
	POP	AF			; RESTORE AF
	; BACK TO CALLER
TMS_Z180IOR	.EQU	$+1
	JP	$0000			; BACK TO CALLER
;
TMS_Z180IOX:
	; RESTORE ORIGINAL DCNTL
	PUSH	AF			; SAVE AF
	LD	A,(TMS_DCNTL)		; ORIG DCNTL
	OUT0	(Z180_DCNTL),A		; IMPLEMENT IT
	POP	AF			; RESTORE AF
	RET				; DONE
;
#ENDIF

#IF (INTMODE == 1 & TMSTIMENABLE)
TMS_TSTINT:
 	IN      A, (TMS_CMDREG)		; TEST FOR INT FLAG
	AND	$80
	JR	NZ, TMS_INTHNDL
	AND	$00			; RETURN Z - NOT HANDLED
	RET

TMS_INTHNDL:

;#IF MKYENABLE
;	CALL	MKY_INT
;#ENDIF

	CALL	HB_TIMINT	; RETURN NZ - HANDLED
	OR	$FF
	RET
#ENDIF
;
;==================================================================================================
;   TMS DRIVER - DATA
;==================================================================================================
;
TMS_POS		.DW 	0	; CURRENT DISPLAY POSITION
TMS_CURSAV	.DB	0	; SAVES ORIGINAL CHARACTER UNDER CURSOR
TMS_BUF		.FILL	256,0	; COPY BUFFER

;
;==================================================================================================
;   TMS DRIVER - INSTANCE DATA
;==================================================================================================
;

TMS_IDAT:
#IF ((TMSMODE == TMSMODE_MSX) | (TMSMODE == TMSMODE_MSX9958) | (TMSMODE == TMSMODE_N8) | (TMSMODE == TMSMODE_SCG))
	.DB	TMS_PPIA	; PPI PORT A
	.DB	TMS_PPIB        ; PPI PORT B
	.DB	TMS_PPIC        ; PPI PORT C
	.DB	TMS_PPIX        ; PPI CONTROL PORT
#ENDIF
#IF ((TMSMODE == TMSMODE_MSXKBD) | (TMSMODE == TMSMODE_MBC))
	.DB	TMS_KBDST	; 8242 CMD/STATUS PORT
	.DB	TMS_KBDDATA	; 8242 DATA PORT
	.DB	0		; FILLER
	.DB	0		; FILER
#ENDIF
;
	.DB	TMS_DATREG
	.DB	TMS_CMDREG
;
;==================================================================================================
;   TMS DRIVER - TMS9918 REGISTER INITIALIZATION
;==================================================================================================
;
; Control Registers (write CMDREG):
;
; Reg	Bit 7	Bit 6	Bit 5	Bit 4	Bit 3	Bit 2	Bit 1	Bit 0	Description
; 0	-	-	-	-	-	-	M2	EXTVID
; 1	4/16K	BL	GINT	M1	M3	-	SI	MAG
; 2	-	-	-	-	PN13	PN12	PN11	PN10
; 3	CT13	CT12	CT11	CT10	CT9	CT8	CT7	CT6
; 4	-	-	-	-	-	PG13	PG12	PG11
; 5	-	SA13	SA12	SA11	SA10	SA9	SA8	SA7
; 6	-	-	-	-	-	SG13	SG12	SG11
; 7	TC3	TC2	TC1	TC0	BD3	BD2	BD1	BD0
;
; Status (read CMDREG):
;
; 	Bit 7	Bit 6	Bit 5	Bit 4	Bit 3	Bit 2	Bit 1	Bit 0	Description
; 	INT	5S	C	FS4	FS3	FS2	FS1	FS0
;
; M1,M2,M3	Select screen mode
; EXTVID	Enables external video input.
; 4/16K		Selects 16kB RAM if set. No effect in MSX1 system.
; BL		Blank screen if reset; just backdrop. Sprite system inactive
; SI		16x16 sprites if set; 8x8 if reset
; MAG		Sprites enlarged if set (sprite pixels are 2x2)
; GINT		Generate interrupts if set
; PN*		Address for pattern name table
; CT*		Address for colour table (special meaning in M2)
; PG*		Address for pattern generator table (special meaning in M2)
; SA*		Address for sprite attribute table
; SG*		Address for sprite generator table
; TC*		Text colour (foreground)
; BD*		Back drop (background). Sets the colour of the border around
; 		the drawable area. If it is 0, it is black (like colour 1).
; FS*		Fifth sprite (first sprite that's not displayed). Only valid
; 		if 5S is set.
; C		Sprite collision detected
; 5S		Fifth sprite (not displayed) detected. Value in FS* is valid.
; INT		Set at each screen update, used for interrupts.
;
#IF ((TMSMODE == TMSMODE_MSX9958) | (TMSMODE == TMSMODE_MBC))
TMS_INITVDU:
	.DB	$04		; REG 0 - NO EXTERNAL VID, SET M4 = 1
TMS_INITVDU_REG_1:
	.DB	$50		; REG 1 - ENABLE SCREEN, SET MODE 1
	.DB	$03		; REG 2 - PATTERN NAME TABLE := 0
	.DB	$00		; REG 3 - NO COLOR TABLE
	.DB	$02		; REG 4 - SET PATTERN GENERATOR TABLE TO (TMS_FNTVADDR -> $1000)
	.DB	$00		; REG 5 - SPRITE ATTRIBUTE IRRELEVANT
	.DB	$00		; REG 6 - NO SPRITE GENERATOR TABLE
	.DB	$F0		; REG 7 - WHITE ON BLACK

	.DB	$88		; REG 8 - COLOUR BUS INPUT, DRAM 64K
	.DB	$00		; REG 9
	.DB	$00		; REG 10 - COLOUR TABLE A14-A16 (TMS_FNTVADDR - $1000)

#ELSE ; TMS REGISTER SET
TMS_INITVDU:
	.DB	$00		; REG 0 - NO EXTERNAL VID
TMS_INITVDU_REG_1:
	.DB	$50		; REG 1 - ENABLE SCREEN, SET MODE 1
	.DB	$00		; REG 2 - PATTERN NAME TABLE := 0
	.DB	$00		; REG 3 - NO COLOR TABLE
	.DB	$01		; REG 4 - SET PATTERN GENERATOR TABLE TO (TMS_FNTVADDR -> $0800)
	.DB	$00		; REG 5 - SPRITE ATTRIBUTE IRRELEVANT
	.DB	$00		; REG 6 - NO SPRITE GENERATOR TABLE
	.DB	$F0		; REG 7 - WHITE ON BLACK
#ENDIF
;
TMS_INITVDULEN	.EQU	$ - TMS_INITVDU
;
;
#IF (CPUFAM == CPU_Z180)
TMS_DCNTL	.DB	$00	; SAVE Z180 DCNTL AS NEEDED
#ENDIF
