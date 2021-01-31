;
;==================================================================================================
; UTILITY FUNCTIONS
;==================================================================================================
;
;
CHR_BEL		.EQU	07H
CHR_CR		.EQU	0DH
CHR_LF		.EQU	0AH
CHR_BS		.EQU	08H
CHR_ESC		.EQU	1BH
;
;__________________________________________________________________________________________________
;
; UTILITY PROCS TO PRINT SINGLE CHARACTERS WITHOUT TRASHING ANY REGISTERS
;
PC_SPACE:
	PUSH	AF
	LD	A,' '
	JR	PC_PRTCHR

PC_PERIOD:
	PUSH	AF
	LD	A,'.'
	JR	PC_PRTCHR

PC_COLON:
	PUSH	AF
	LD	A,':'
	JR	PC_PRTCHR

PC_COMMA:
	PUSH	AF
	LD	A,','
	JR	PC_PRTCHR

PC_LBKT:
	PUSH	AF
	LD	A,'['
	JR	PC_PRTCHR

PC_RBKT:
	PUSH	AF
	LD	A,']'
	JR	PC_PRTCHR

PC_LT:
	PUSH	AF
	LD	A,'<'
	JR	PC_PRTCHR

PC_GT:
	PUSH	AF
	LD	A,'>'
	JR	PC_PRTCHR

PC_LPAREN:
	PUSH	AF
	LD	A,'('
	JR	PC_PRTCHR

PC_RPAREN:
	PUSH	AF
	LD	A,')'
	JR	PC_PRTCHR

PC_ASTERISK:
	PUSH	AF
	LD	A,'*'
	JR	PC_PRTCHR

PC_CR:
	PUSH	AF
	LD	A,CHR_CR
	JR	PC_PRTCHR

PC_LF:
	PUSH	AF
	LD	A,CHR_LF
	JR	PC_PRTCHR

PC_PRTCHR:
	CALL	COUT
	POP	AF
	RET

NEWLINE2:
	CALL	NEWLINE
NEWLINE:
	CALL	PC_CR
	CALL	PC_LF
	RET
;
; PRINT A CHARACTER REFERENCED BY POINTER AT TOP OF STACK
; USAGE:
;   CALL PRTCH
;   .DB  'X'
;
PRTCH:
	EX	(SP),HL
	PUSH	AF
	LD	A,(HL)
	CALL	COUT
	POP	AF
	INC	HL
	EX	(SP),HL
	RET
;
; PRINT A STRING AT ADDRESS SPECIFIED IN HL
; STRING MUST BE TERMINATED BY '$'
; USAGE:
;   LD	HL,MYSTR
;   CALL PRTSTR
;   ...
;   MYSTR: .DB  "HELLO$"
;
PRTSTR:
	LD	A,(HL)
	INC	HL
	CP	'$'
	RET	Z
	CALL	COUT
	JR	PRTSTR
;
; PRINT A STRING DIRECT: REFERENCED BY POINTER AT TOP OF STACK
; STRING MUST BE TERMINATED BY '$'
; USAGE:
;   CALL PRTSTRD
;   .DB  "HELLO$"
;   ...
;
PRTSTRD:
	EX	(SP),HL
	PUSH	AF
	CALL	PRTSTR
	POP	AF
	EX	(SP),HL
	RET
;
; PRINT A STRING INDIRECT: REFERENCED BY INDIRECT POINTER AT TOP OF STACK
; STRING MUST BE TERMINATED BY '$'
; USAGE:
;   CALL PRTSTRI(MYSTRING)
;   MYSTRING	.DB	"HELLO$"
;
PRTSTRI:
	EX	(SP),HL
	PUSH	AF
	LD	A,(HL)
	INC	HL
	PUSH	HL
	LD	H,(HL)
	LD	L,A
	CALL	PRTSTR
	POP	HL
	INC	HL
	POP	AF
	EX	(SP),HL
	RET
;
; PRINT THE HEX BYTE VALUE IN A
;
PRTHEXBYTE:
	PUSH	AF
	PUSH	DE
	CALL	HEXASCII
	LD	A,D
	CALL	COUT
	LD	A,E
	CALL	COUT
	POP	DE
	POP	AF
	RET
;
; PRINT THE HEX WORD VALUE IN BC
;
PRTHEXWORD:
	PUSH	AF
	LD	A,B
	CALL	PRTHEXBYTE
	LD	A,C
	CALL	PRTHEXBYTE
	POP	AF
	RET
;
; PRINT THE HEX WORD VALUE IN HL
;
PRTHEXWORDHL:
	PUSH	AF
	LD	A,H
	CALL	PRTHEXBYTE
	LD	A,L
	CALL	PRTHEXBYTE
	POP	AF
	RET
;
; PRINT THE HEX DWORD VALUE IN DE:HL
;
PRTHEX32:
	PUSH	BC
	PUSH	DE
	POP	BC
	CALL	PRTHEXWORD
	PUSH	HL
	POP	BC
	CALL	PRTHEXWORD
	POP	BC
	RET
;
; CONVERT BINARY VALUE IN A TO ASCII HEX CHARACTERS IN DE
;
HEXASCII:
	LD	D,A
	CALL	HEXCONV
	LD	E,A
	LD	A,D
	RLCA
	RLCA
	RLCA
	RLCA
	CALL	HEXCONV
	LD	D,A
	RET
;
; CONVERT LOW NIBBLE OF A TO ASCII HEX
;
HEXCONV:
	AND	0FH	     ;LOW NIBBLE ONLY
	ADD	A,90H
	DAA
	ADC	A,40H
	DAA
	RET
;
; PRINT A BYTE BUFFER IN HEX POINTED TO BY DE
; REGISTER A HAS SIZE OF BUFFER
;
PRTHEXBUF:
	OR	A
	RET	Z		; EMPTY BUFFER
;
	LD	B,A
PRTHEXBUF1:
	CALL	PC_SPACE
	LD	A,(DE)
	CALL	PRTHEXBYTE
	INC	DE
	DJNZ	PRTHEXBUF1
	RET
;
; PRINT A BLOCK OF MEMORY NICELY FORMATTED
;  DE=BUFFER ADDRESS
;
DUMP_BUFFER:
	CALL	NEWLINE

	PUSH	DE
	POP	HL
	INC	D
	INC	D

DB_BLKRD:
	PUSH	BC
	PUSH	HL
	POP	BC
	CALL	PRTHEXWORD		; PRINT START LOCATION
	POP	BC
	CALL	PC_SPACE		;
	LD	C,16			; SET FOR 16 LOCS
	PUSH	HL			; SAVE STARTING HL
DB_NXTONE:
	LD	A,(HL)			; GET BYTE
	CALL	PRTHEXBYTE		; PRINT IT
	CALL	PC_SPACE		;
DB_UPDH:
	INC	HL			; POINT NEXT
	DEC	C			; DEC. LOC COUNT
	JR	NZ,DB_NXTONE		; IF LINE NOT DONE
					; NOW PRINT 'DECODED' DATA TO RIGHT OF DUMP
DB_PCRLF:
	CALL	PC_SPACE		; SPACE IT
	LD	C,16			; SET FOR 16 CHARS
	POP	HL			; GET BACK START
DB_PCRLF0:
	LD	A,(HL)			; GET BYTE
	AND	060H			; SEE IF A 'DOT'
	LD	A,(HL)			; O.K. TO GET
	JR	NZ,DB_PDOT		;
DB_DOT:
	LD	A,2EH			; LOAD A DOT
DB_PDOT:
	CALL	COUT			; PRINT IT
	INC	HL			;
	LD	A,D			;
	CP	H			;
	JR	NZ,DB_UPDH1		;
	LD	A,E			;
	CP	L			;
	JP	Z,DB_END		;
DB_UPDH1:
; IF BLOCK NOT DUMPED, DO NEXT CHARACTER OR LINE
	DEC	C			; DEC. CHAR COUNT
	JR	NZ,DB_PCRLF0		; DO NEXT
DB_CONTD:
	CALL	NEWLINE			;
	JP	DB_BLKRD		;

DB_END:
	RET
;
; PRINT THE nTH STRING IN A LIST OF STRINGS WHERE EACH IS TERMINATED BY $
; C REGISTER CONTAINS THE INDEX TO THE STRING TO BE DISPLAYED.
; A REGISTER CONTAINS A MASK TO BE APPLIED TO THE INDEX
; THE INDEX IS NORMALIZED TO A RANGE 0..N USING THE MASK AND THEN THE nTH
; STRING IS PRINTED IN A LIST DEFINED BY DE
;
; C = ATTRIBUTE
; A = MASK
; DE = STRING LIST
;
PRTIDXMSK:
	PUSH	BC
PRTIDXMSK0:
	BIT	0,A
	JR	NZ,PRTIDXMSK1
	SRL	A
	SRL	C
	JR	PRTIDXMSK0
PRTIDXMSK1:
	LD	B,A
	LD	A,C
	AND	B
	POP	BC
;
; PRINT THE nTH STRING IN A LIST OF STRINGS WHERE EACH IS TERMINATED BY $
; A REGISTER DEFINES THE nTH STRING IN THE LIST TO PRINT AND DE POINTS
; TO THE START OF THE STRING LIST.
;
; SLOW BUT IMPROVES CODE SIZE, READABILITY AND ELIMINATES THE NEED HAVE
; LIST OF POINTERS OR A LIST OF CONDITIONAL CHECKS.
;
PRTIDXDEA:
	PUSH	BC
	LD	C,A			; INDEX COUNT
	OR	A
	LD	A,0
	LD	(PRTIDXCNT),A		; RESET CHARACTER COUNT
PRTIDXDEA1:
	JR	Z,PRTIDXDEA3
PRTIDXDEA2:
	LD	A,(DE)			; LOOP UNIT
	INC	DE			; WE REACH
	CP	'$'			; END OF STRING
	JR	NZ,PRTIDXDEA2
	DEC	C			; AT STRING END. SO GO
	JR	PRTIDXDEA1		; CHECK FOR INDEX MATCH
PRTIDXDEA3:
	POP	BC
;	CALL	WRITESTR		; FALL THROUGH TO WRITESTR
;	RET
;
PRTIDXCNT:
	.DB	0			; CHARACTER COUNT
;
; OUTPUT A '$' TERMINATED STRING AT DE
;
WRITESTR:
	PUSH	AF
WRITESTR1:
	LD	A,(DE)
	CP	'$'			; TEST FOR STRING TERMINATOR
	JP	Z,WRITESTR2
	CALL	COUT
	LD	A,(PRTIDXCNT)
	INC	A
	LD	(PRTIDXCNT),A
	INC	DE
	JP	WRITESTR1
WRITESTR2:
	POP	AF
	RET
;
;
;
TSTPT:
	PUSH	DE
	LD	DE,STR_TSTPT
	CALL	WRITESTR
	POP	DE
	JR	REGDMP			; DUMP REGISTERS AND RETURN
;
;
;
REGDMP:
	CALL	XREGDMP
	RET
;
XREGDMP:
	EX	(SP),HL			; RET ADR TO HL, SAVE HL ON TOS
	LD	(REGDMP_RET),HL		; SAVE RETURN ADDRESS
	POP	HL			; RESTORE HL AND BURN STACK ENTRY

	EX	(SP),HL			; PC TO HL, SAVE HL ON TOS
	LD	(REGDMP_PC),HL		; SAVE PC VALUE
	EX	(SP),HL			; BACK THE WAY IT WAS

	LD	(REGDMP_SP),SP		; SAVE STACK POINTER

	;LD	(RD_STKSAV),SP		; SAVE ORIGINAL STACK POINTER
	;LD	SP,RD_STACK		; SWITCH TO PRIVATE STACK

	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL

	PUSH	AF
	LD	A,'@'
	CALL	COUT
	POP	AF

	PUSH	BC
	LD	BC,(REGDMP_PC)
	CALL	PRTHEXWORD		; PC
	POP	BC
	CALL	PC_LBKT
	PUSH	BC
	PUSH	AF
	POP	BC
	CALL	PRTHEXWORD		; AF
	POP	BC
	CALL	PC_COLON
	CALL	PRTHEXWORD		; BC
	CALL	PC_COLON
	PUSH	DE
	POP	BC
	CALL	PRTHEXWORD		; DE
	CALL	PC_COLON
	PUSH	HL
	POP	BC
	CALL	PRTHEXWORD		; HL
	CALL	PC_COLON
	LD	BC,(REGDMP_SP)
	CALL	PRTHEXWORD		; SP

	CALL	PC_COLON
	PUSH	IX
	POP	BC
	CALL	PRTHEXWORD		; IX

	CALL	PC_COLON
	PUSH	IY
	POP	BC
	CALL	PRTHEXWORD		; IY

	CALL	PC_RBKT
	CALL	PC_SPACE

	POP	HL
	POP	DE
	POP	BC
	POP	AF

	;LD	SP,(RD_STKSAV)		; BACK TO ORIGINAL STACK FRAME

	JP	$FFFF			; RETURN, $FFFF IS DYNAMICALLY UPDATED
REGDMP_RET	.EQU	$-2		; RETURN ADDRESS GOES HERE
;
REGDMP_PC	.DW	0
REGDMP_SP	.DW	0
;
;RD_STKSAV	.DW	0
;		.FILL	$FF,16*2	; 16 LEVEL PRIVATE STACK
;RD_STACK	.EQU	$
;
;
;
;
;
STR_HALT	.TEXT	"\r\n\r\n*** System Halted ***$"
STR_TSTPT	.TEXT	"\r\n+++ TSTPT: $"
;STR_AF		.DB	" AF=$"
;STR_BC		.DB	" BC=$"
;STR_DE		.DB	" DE=$"
;STR_HL		.DB	" HL=$"
;STR_PC		.DB	" PC=$"
;STR_SP		.DB	" SP=$"
;
; INDIRECT JUMP TO ADDRESS IN HL
;
;   MOSTLY USEFUL TO PERFORM AN INDIRECT CALL LIKE:
;     LD	HL,xxxx
;     CALL	JPHL
;
JPHL:	JP	(HL)
;
; ADD HL,A
;
;   A REGISTER IS DESTROYED!
;
ADDHLA:
	ADD	A,L
	LD	L,A
	RET	NC
	INC	H
	RET
;
;****************************
;	A(BCD) => A(BIN)
;	[00H..99H] -> [0..99]
;****************************
;
BCD2BYTE:
	PUSH	BC
	LD	C,A
	AND	0F0H
	SRL	A
	LD	B,A
	SRL	A
	SRL	A
	ADD	A,B
	LD	B,A
	LD	A,C
	AND	0FH
	ADD	A,B
	POP	BC
	RET
;
;*****************************
;	 A(BIN) =>  A(BCD)
;	[0..99] => [00H..99H]
;*****************************
;
BYTE2BCD:
	PUSH	BC
	LD	B,10
	LD	C,-1
BYTE2BCD1:
	INC	C
	SUB	B
	JR	NC,BYTE2BCD1
	ADD	A,B
	LD	B,A
	LD	A,C
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	OR	B
	POP	BC
	RET

#IFDEF USEDELAY

;
; DELAY 16US (CPU SPEED COMPENSATED) INCUDING CALL/RET INVOCATION
; REGISTER A AND FLAGS DESTROYED
; NO COMPENSATION FOR Z180 MEMORY WAIT STATES
; THERE IS AN OVERHEAD OF 3TS PER INVOCATION
;   IMPACT OF OVERHEAD DIMINISHES AS CPU SPEED INCREASES
;
; CPU SCALER (CPUSCL) = (CPUHMZ - 2) FOR 16US + 3TS DELAY
;   NOTE: CPUSCL MUST BE >= 1!
;
; EXAMPLE: 8MHZ CPU (DELAY GOAL IS 16US)
;   LOOP = ((6 * 16) - 5) = 91TS
;   TOTAL COST = (91 + 40) = 131TS
;   ACTUAL DELAY = (131 / 8) = 16.375US
;
	; --- TOTAL COST = (LOOP COST + 40) TS -----------------+
DELAY:				; 17TS (FROM INVOKING CALL)	|
	LD	A,(CPUSCL)	; 13TS				|
;								|
DELAY1:				;				|
	; --- LOOP = ((CPUSCL * 16) - 5) TS ------------+	|
	DEC	A		; 4TS			|	|
  #IF (BIOS == BIOS_WBW)	;			|	|
    #IF (CPUFAM == CPU_Z180)	;			|	|
	OR	A		; +4TS FOR Z180		|	|
    #ENDIF			;			|	|
  #ENDIF			;			|	|
	JR	NZ,DELAY1	; 12TS (NZ) / 7TS (Z)	|	|
	; ----------------------------------------------+	|
;								|
	RET			; 10TS (RETURN)			|
	;-------------------------------------------------------+
;
; DELAY 16US * DE (CPU SPEED COMPENSATED)
; REGISTER DE, A, AND FLAGS DESTROYED
; NO COMPENSATION FOR Z180 MEMORY WAIT STATES
; THERE IS A 27TS OVERHEAD FOR CALL/RET PER INVOCATION
;   IMPACT OF OVERHEAD DIMINISHES AS DE AND/OR CPU SPEED INCREASES
;
; CPU SCALER (CPUSCL) = (CPUHMZ - 2) FOR 16US OUTER LOOP COST
;   NOTE: CPUSCL MUST BE > 0!
;
; EXAMPLE: 8MHZ CPU, DE=6250 (DELAY GOAL IS .1 SEC OR 100,000US)
;   INNER LOOP = ((16 * 6) - 5) = 91TS
;   OUTER LOOP = ((91 + 37) * 6250) = 800,000TS
;   ACTUAL DELAY = ((800,000 + 27) / 8) = 100,003US
;
	; --- TOTAL COST = (OUTER LOOP + 27) TS ------------------------+
VDELAY:				; 17TS (FROM INVOKING CALL)		|
;									|
	; --- OUTER LOOP = ((INNER LOOP + 37) * DE) TS ---------+	|
	LD	A,(CPUSCL)	; 13TS				|	|
;								|	|
VDELAY1:			;				|	|
	; --- INNER LOOP = ((CPUSCL * 16) - 5) TS ------+	|	|
  #IF (BIOS == BIOS_WBW)	;			|	|	|
    #IF (CPUFAM == CPU_Z180)	;			|	|	|
	OR	A		; +4TS FOR Z180		|	|	|
    #ENDIF			;			|	|	|
  #ENDIF			;			|	|	|
	DEC	A		; 4TS			|	|	|
	JR	NZ,VDELAY1	; 12TS (NZ) / 7TS (Z)	|	|	|
	; ----------------------------------------------+	|	|
;								|	|
	DEC	DE		; 6TS				|	|
  #IF (BIOS == BIOS_WBW)	;			|	|	|
    #IF (CPUFAM == CPU_Z180)	;				|	|
	OR	A		; +4TS FOR Z180			|	|
    #ENDIF			;				|	|
  #ENDIF			;				|	|
	LD	A,D		; 4TS				|	|
	OR	E		; 4TS				|	|
	JP	NZ,VDELAY	; 10TS				|	|
	;-------------------------------------------------------+	|
;									|
	RET			; 10TS (FINAL RETURN)			|
	;---------------------------------------------------------------+
;
; DELAY ABOUT 0.5 SECONDS
; 500000US / 16US = 31250
;
LDELAY:
	PUSH	AF
	PUSH	DE
	LD	DE,31250
	CALL	VDELAY
	POP	DE
	POP	AF
	RET
;
; INITIALIZE DELAY SCALER BASED ON OPERATING CPU SPEED
; HBIOS *MUST* BE INSTALLED AND AVAILABLE VIA RST 8!!!
; CPU SCALER := MAX(1, (PHIMHZ - 2))
;
DELAY_INIT:
  #IF (BIOS == BIOS_UNA)
	LD	C,$F8			; UNA BIOS GET PHI FUNCTION
	RST	08			; RETURNS SPEED IN HZ IN DE:HL
	LD	B,4			; DIVIDE MHZ IN DE:HL BY 100000H
DELAY_INIT0:
	SRL	D			; ... TO GET APPROX CPU SPEED IN
	RR	E			; ...MHZ.  THROW AWAY HL, AND
	DJNZ	DELAY_INIT0		; ...RIGHT SHIFT DE BY 4.
	INC	E			; FIX UP FOR VALUE TRUNCATION
	LD	A,E			; PUT IN A
  #ELSE
	LD	B,BF_SYSGET		; HBIOS FUNC=GET SYS INFO
	LD	C,BF_SYSGET_CPUINFO	; HBIOS SUBFUNC=GET CPU INFO
	RST	08			; CALL HBIOS, RST 08 NOT YET INSTALLED
	LD	A,L			; PUT SPEED IN MHZ IN ACCUM
  #ENDIF
	CP	3			; TEST FOR <= 2 (SPECIAL HANDLING)
	JR	C,DELAY_INIT1		; IF <= 2, SPECIAL PROCESSING
	SUB	2			; ADJUST AS REQUIRED BY DELAY FUNCTIONS
	JR	DELAY_INIT2		; AND CONTINUE
DELAY_INIT1:
	LD	A,1			; USE THE MIN VALUE OF 1
DELAY_INIT2:
	LD	(CPUSCL),A		; UPDATE CPU SCALER VALUE
	RET

  #IF (CPUMHZ < 3)
CPUSCL	.DB	1			; CPU SCALER MUST BE > 0
  #ELSE
CPUSCL	.DB	CPUMHZ - 2		; OTHERWISE 2 LESS THAN PHI MHZ
  #ENDIF
;
#ENDIF
;
; SHORT DELAY FUNCTIONS.  NO CLOCK SPEED COMPENSATION, SO THEY
; WILL RUN LONGER ON SLOWER SYSTEMS.  THE NUMBER INDICATES THE
; NUMBER OF CALL/RET INVOCATIONS.  A SINGLE CALL/RET IS
; 27 T-STATES ON A Z80, 25 T-STATES ON A Z180
;
;			; Z80	Z180
;			; ----	----
DLY64:	CALL	DLY32	; 1728	1600
DLY32:	CALL	DLY16	; 864	800
DLY16:	CALL	DLY8	; 432	400
DLY8:	CALL	DLY4	; 216	200
DLY4:	CALL	DLY2	; 108	100
DLY2:	CALL	DLY1	; 54	50
DLY1:	RET		; 27	25
;
; MULTIPLY 8-BIT VALUES
; IN:  MULTIPLY H BY E
; OUT: HL = RESULT, E = 0, B = 0
;
MULT8:
	LD D,0
	LD L,D
	LD B,8
MULT8_LOOP:
	ADD HL,HL
	JR NC,MULT8_NOADD
	ADD HL,DE
MULT8_NOADD:
	DJNZ MULT8_LOOP
	RET
;
; MULTIPLY A 16 BIT BY 8 BIT INTO 16 BIT
; IN: MULTIPLY DE BY A
; OUT: HL = RESULT, B=0, A, C, DE UNCHANGED
;
MULT8X16:
	LD	B,8
	LD	HL,0
MULT8X16_1:
	ADD	HL,HL
	RLCA
	JR	NC,MULT8X16_2
	ADD	HL,DE
MULT8X16_2:
	DJNZ	MULT8X16_1
	RET
;;
;; COMPUTE HL / DE
;; RESULT IN BC, REMAINDER IN HL, AND SET ZF DEPENDING ON REMAINDER
;; A, DE DESTROYED
;;
;DIV:
;	XOR	A
;	LD	BC,0
;DIV1:
;	SBC	HL,DE
;	JR	C,DIV2
;	INC	BC
;	JR	DIV1
;DIV2:
;	XOR	A
;	ADC	HL,DE		; USE ADC SO ZF IS SET
;	RET
;===============================================================
;
; COMPUTE HL / DE = BC W/ REMAINDER IN HL & ZF
;
DIV16:
	LD	A,H			; HL -> AC
	LD	C,L			; ...
	LD	HL,0			; INIT HL
	LD	B,16			; INIT LOOP COUNT
DIV16A:
	SCF
	RL	C
	RLA
	ADC	HL,HL
	SBC	HL,DE
	JR	NC,DIV16B
	ADD	HL,DE
	DEC	C
DIV16B:
	DJNZ	DIV16A			; LOOP AS NEEDED
	LD	B,A			; AC -> BC
	LD	A,H			; SET ZF
	OR	L			; ... BASED ON REMAINDER
	RET				; DONE
;
; INTEGER DIVIDE DE:HL BY C
; RESULT IN DE:HL, REMAINDER IN A
; CLOBBERS F, B
;
DIV32X8:
	XOR	A
	LD	B,32
DIV32X8A:
 	ADD	HL,HL
	RL	E
	RL	D
	RLA
	CP	C
	JR	C,DIV32X8B
	SUB	C
	INC	L
DIV32X8B:
 	DJNZ	DIV32X8A
	RET
;
; FILL MEMORY AT HL WITH VALUE A, LENGTH IN BC, ALL REGS USED
; LENGTH *MUST* BE GREATER THAN 1 FOR PROPER OPERATION!!!
;
FILL:
	LD	D,H		; SET DE TO HL
	LD	E,L		; SO DESTINATION EQUALS SOURCE
	LD	(HL),A		; FILL THE FIRST BYTE WITH DESIRED VALUE
	INC	DE		; INCREMENT DESTINATION
	DEC	BC		; DECREMENT THE COUNT
	LDIR			; DO THE REST
	RET			; RETURN
;
; SET A BIT IN BYTE ARRAY AT HL, INDEX IN A
;
BITSET:
	CALL	BITLOC		; LOCATE THE BIT
	OR	(HL)		; SET THE SPECIFIED BIT
	LD	(HL),A		; SAVE IT
	RET			; RETURN
;
; CLEAR A BIT IN BYTE ARRAY AT HL, INDEX IN A
;
BITCLR:
	CALL	BITLOC		; LOCATE THE BIT
	CPL			; INVERT ALL BITS
	AND	(HL)		; CLEAR SPECIFIED BIT
	LD	(HL),A		; SAVE IT
	RET			; RETURN
;
; GET VALUE OF A BIT IN BYTE ARRAY AT HL, INDEX IN A
;
BITTST:
	CALL	BITLOC		; LOCATE THE BIT
	AND	(HL)		; SET Z FLAG BASED ON BIT
	RET			; RETURN
;
; LOCATE A BIT IN BYTE ARRAY AT HL, INDEX IN A
; RETURN WITH HL POINTING TO BYTE AND A WITH MASK FOR SPECIFIC BIT
;
BITLOC:
	PUSH	AF		; SAVE BIT INDEX
	SRL	A		; DIVIDE BY 8 TO GET BYTE INDEX
	SRL	A		; "
	SRL	A		; "
	LD	C,A		; MOVE TO BC
	LD	B,0		; "
	ADD	HL,BC		; HL NOW POINTS TO BYTE CONTAINING BIT
	POP	AF		; RECOVER A (INDEX)
	AND	$07		; ISOLATE REMAINDER, Z SET IF ZERO
	LD	B,A		; SETUP SHIFT COUNTER
	LD	A,1		; SETUP A WITH MASK
	RET	Z		; DONE IF ZERO
BITLOC1:
	SLA	A		; SHIFT
	DJNZ	BITLOC1		; LOOP AS NEEDED
	RET			; DONE
;
; PRINT VALUE OF A IN DECIMAL WITH LEADING ZERO SUPPRESSION
;
PRTDECB:
	PUSH	HL
	PUSH	AF
	LD	L,A
	LD	H,0
	CALL	PRTDEC
	POP	AF
	POP	HL
	RET
;
; PRINT VALUE OF HL IN DECIMAL WITH LEADING ZERO SUPPRESSION
;
PRTDEC:
	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	E,'0'
	LD	BC,-10000
	CALL	PRTDEC1
	LD	BC,-1000
	CALL	PRTDEC1
	LD	BC,-100
	CALL	PRTDEC1
	LD	C,-10
	CALL	PRTDEC1
	LD	E,0
	LD	C,-1
	CALL	PRTDEC1
	POP	HL
	POP	DE
	POP	BC
	RET
PRTDEC1:
	LD	A,'0' - 1
PRTDEC2:
	INC	A
	ADD	HL,BC
	JR	C,PRTDEC2
	SBC	HL,BC
	CP	E
	JR	Z,PRTDEC3
	LD	E,0
	CALL	COUT
PRTDEC3:
	RET
;
; SHIFT HL:DE BY B BITS
;
SRL32:
	; ROTATE RIGHT 32 BITS, HIGH ORDER BITS BECOME ZERO
	SRL	D
	RR	E
	RR	H
	RR	L
	DJNZ	SRL32
	RET
;
SLA32:
	; ROTATE LEFT 32 BITS, LOW ORDER BITS BECOME ZERO
	SLA	L
	RL	H
	RL	E
	RL	D
	DJNZ	SLA32
	RET
;
; LOAD OR STORE DE:HL
;
LD32:
	; LD DE:HL,(HL)
	PUSH	AF
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	POP	AF
	EX	DE,HL
	RET
;
ST32:
	; LD (BC),DE:HL
	PUSH	AF
	LD	A,L
	LD	(BC),A
	INC	BC
	LD	A,H
	LD	(BC),A
	INC	BC
	LD	A,E
	LD	(BC),A
	INC	BC
	LD	A,D
	LD	(BC),A
	POP	AF
	RET
;
; INC/ADD/DEC/SUB 32 BIT VALUE IN DE:HL
; FOR ADD/SUB, OPERAND IS IN BC
;
INC32:
	LD	BC,1
ADD32:
	ADD	HL,BC
	RET	NC
	INC	DE
	RET
;
DEC32:
	LD	BC,1
SUB32:
	OR	A
	SBC	HL,BC
	RET	NC
	DEC	DE
	RET
;
; INC32 (HL)
; INCREMENT 32 BIT BINARY AT ADDRESS
;
INC32HL:
	INC	(HL)
	RET	NZ
	INC	HL
	INC	(HL)
	RET	NZ
	INC	HL
	INC	(HL)
	RET	NZ
	INC	HL
	INC	(HL)
	RET

