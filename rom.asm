; myZ80, A computer based on Z80 microprocessor
; Copyright (C) 2020-2021 Cidorvan Leite

; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see [http://www.gnu.org/licenses/].

 INCLUDE "rom.inc"


 ORG 0000h
          JP main                 ; 0000h


 ORG 0010h
          JP PSGinit              ; 0010h


 ORG 0020h
          JP DSPinit              ; 0020h
          JP DSPwait              ; 0023h
          JP DSPwriteRegister     ; 0026h
          JP DSPscrollUp          ; 0029h
          JP DSPprintChar         ; 002Ch
          JP DSPprintString       ; 002Fh
          JP DSPprintHex          ; 0032h
          JP DSPprintDec          ; 0035h
          JP DSPprintDec16        ; 0038h
          JP DSPprintBin          ; 003Bh


 ORG 0050h
          JP waitForKeyPressed    ; 0050h


 ORG 0100h
main:
          DI
          LD   SP, 0                         ; Init stack pointer

          CALL PSGinit                       ; Initialize sound/IO
          CALL DSPinit                       ; Initialize display

          LD   HL, ready
          CALL DSPprintString                ; Display ready message
          LD   A, SET_DDRAM_ADDR | 64
          CALL DSPwriteRegister

          CALL loadBinary                    ; Load binary from UART

 IFNDEF DUMP_FIRST_BYTES
          LD   DE, RAM_START_POINTER
          SBC  HL, DE
          CALL DSPprintDec16
          LD   HL, loaded
          CALL DSPprintString                ; Display how many bytes were read

          LD   A, SET_DDRAM_ADDR | 20
          CALL DSPwriteRegister              ; Move to third line

          LD   HL, press
          CALL DSPprintString                ; Display press any key message

          CALL waitForKeyPressed             ; Wait any key to be pressed to continue

          LD   A, CLEAR_DISPLAY
          CALL DSPwriteRegister              ; Clear display
 ELSE
          CALL dumpFirstBytes                ; Show first bytes for DEBUG
 ENDIF

          JP   RAM_START_POINTER             ; Everything done, let's play!!!!


loadBinary:
          LD   A, 14
          OUT  (PSG_W_ADDRESS), A            ; Define PSG PORTA to read

          LD   HL, RAM_START_POINTER         ; Address to store all binary
.L0:      LD   B, 0

.L1:      IN   A, (PSG_R_DATA)     ; 11
          BIT  7, A                ; 8
          JP   Z, .L2              ; 10
          DJNZ .L1                 ; 13/8
          JP   .L4                 ; 10      ; Synchronizing with start bit

.L2:      NOP
          NOP
          LD   C, 8                ; 7
          LD   D, 0                ; 7       ; Synchronized, starting to read each bit

.L3:      SRL  D                   ; 8
          IN   A, (PSG_R_DATA)     ; 11
          AND  080h                ; 7
          OR   D                   ; 4
          LD   D, A                ; 4       ; Bit stored

          NOP
          DEC  C                   ; 4
          JP   NZ, .L3             ; 10      ; Delay to read next bit

          LD   (HL), D             ; 7
          INC  HL                  ; 6
          JP   .L0                 ; 10      ; Byte stored, let's read next one

.L4:      LD   A, H
          OR   L
          CP   080h
          JP   Z, .L0                        ; HL not changed, try again...

          RET


 IFDEF DUMP_FIRST_BYTES
dumpFirstBytes:
          LD   A, CLEAR_DISPLAY
          CALL DSPwriteRegister              ; Clear display

          LD   C, 4
          LD   HL, 08000h
.D0:      LD   B, 8
          LD   D, (HL)                       ; Start loop

.D1:      LD   A, D
          AND  1
          ADD  '0'
          CALL DSPprintChar
          SRL  D
          DJNZ .D1                           ; Print byte in binary (LSB first)

          LD   A, ' '
          CALL DSPprintChar                  ; Print space

          INC  HL
          DEC  C
          JR   NZ, .D0                       ; Repeat for first 4 bytes

          LD   A, SET_DDRAM_ADDR | 64
          CALL DSPwriteRegister              ; Move cursor to second line

          LD   A, 0
          LD   (08028h), A
          LD   HL, 08000h
          CALL DSPprintString                ; Print bytes received

.D2:      JR   .D2                           ; Halt
 ENDIF


; *******************
; ** PSG functions **
; *******************

; PSG_INIT (0010h)
; Entry ..... None
; Exit ...... None
; Modifies .. AF
; Inititialize PSG with PA input, PB output, noise and tone disable
; *******************************************************************
PSGinit:
          LD   A, 7                             ; Mixer - I/O
          OUT  (PSG_W_ADDRESS), A
          LD   A, 0BFh                          ; PA input, PB output, noise and tone disable
          OUT  (PSG_W_DATA), A
          LD   A, 15                            ; PORTB
          OUT  (PSG_W_ADDRESS), A
          LD   A, 0FFh                          ; Every pin HIGH
          OUT  (PSG_W_DATA), A

          RET


; ***********************
; ** Display functions **
; ***********************

; DSP_INIT (0020h)
; Entry ..... None
; Exit ...... None
; Modifies .. AF
; Initialize display with 8bits and two lines
; *********************************************
DSPinit:
          LD   A, FUNCTION_SET | DL_8BITS | N_2LINES
          CALL DSPwriteRegister
          LD   A, DISPLAY_CONTROL | D_DISPLAY_ON
          CALL DSPwriteRegister
          LD   A, CLEAR_DISPLAY
          CALL DSPwriteRegister

          RET


; DSP_WAIT (0023h)
; Entry ..... None
; Exit ...... None
; Modifies .. None
; Wait last command to finish
; *****************************
DSPwait:
          PUSH AF
.L0:      IN   A, (DISPLAY_REG)
          BIT  7, A
          JR   Z, .L1

          NOP
          NOP
          NOP
          NOP
          JR   .L0

.L1:      POP  AF
          RET


; DSP_WRITE_REG (0026h)
; Entry ..... A=Value
; Exit ...... None
; Modifies .. AF
; Write value to display internal register
; ******************************************
DSPwriteRegister:
          CALL DSPwait
          OUT  (DISPLAY_REG), A

          RET


; DSP_SCROLL_UP (0029h)
; Entry ..... None
; Exit ...... None
; Modifies .. AF B HL
; Scroll display one line up
; ****************************
DSPscrollUp:
          LD   HL, -20
          ADD  HL, SP
          LD   SP, HL                        ; allocate 20 bytes in stack

          LD   A, SET_DDRAM_ADDR | 64
          CALL .CL
          LD   A, SET_DDRAM_ADDR
          CALL .WL                           ; move second line to first one

          LD   A, SET_DDRAM_ADDR | 20
          CALL .CL
          LD   A, SET_DDRAM_ADDR | 64
          CALL .WL                           ; move third line to second one

          LD   A, SET_DDRAM_ADDR | 84
          CALL .CL
          LD   A, SET_DDRAM_ADDR | 20
          CALL .WL                           ; move forth line to third one

          LD   A, SET_DDRAM_ADDR | 84
          CALL DSPwriteRegister
          LD   A, ' '
          LD   B, 20
.S0:      CALL DSPprintChar
          DJNZ .S0                           ; clean last line with spaces

          LD   SP, HL
          RET

.CL:      CALL DSPwriteRegister
          LD   B, 20
          LD   HL, 2
          ADD  HL, SP
.CL0:     CALL DSPwait
          IN   A, (DISPLAY_DATA)
          LD   (HL), A                       ; copy full line to stack
          INC  HL
          DJNZ .CL0
          RET

.WL:      CALL DSPwriteRegister
          LD   B, 20
          LD   HL, 2
          ADD HL, SP
.WL0:     LD   A, (HL)                       ; copy full line from stack
          INC  HL
          CALL DSPprintChar
          DJNZ .WL0
          RET


; DSP_PRINT_CHAR (002Ch)
; Entry ..... A=ASCII code
; Exit ...... None
; Modifies .. AF
; Print one character in current cursor position
; ************************************************
DSPprintChar:
          CALL DSPwait
          OUT  (DISPLAY_DATA), A

          RET


; DSP_PRINT_STRING (002Fh)
; Entry ..... HL=String pointer
; Exit ...... None
; Modifies .. AF HL
; Print string in current cursor position
; *****************************************
DSPprintString:
          LD   A, (HL)
          OR   A
          RET  Z

          CALL DSPwait
          OUT  (DISPLAY_DATA), A
          INC  HL
          JR   DSPprintString


; DSP_PRINT_HEX (0032h)
; Entry ..... A=Value
; Exit ...... None
; Modifies .. AF
; Print an 8bits hexadecimal number in current cursor position
; **************************************************************
DSPprintHex:
          PUSH AF
          SRL  A
          SRL  A
          SRL  A
          SRL  A
          CALL .PH0
          POP  AF

.PH0:     AND  0Fh
          CP   10
          JR   C, .PH1
          ADD  'A' - '0' - 10
.PH1:     ADD  '0'
          CALL DSPprintChar

          RET


; DSP_PRINT_DEC (0035h)
; Entry ..... A=Value
; Exit ...... None
; Modifies .. AF BC
; Print an 8bit decimal in current cursor position
; **************************************************
DSPprintDec:
          LD   BC, 100
          CALL PD1
PD0:      LD   BC, 10
          CALL PD1

          ADD  '0'
          CALL DSPprintChar

          RET

PD1:      CP   C
          JR   C, .PD2
          INC  B
          SUB  C
          JR   PD1

.PD2:     PUSH AF
          LD   A, B
          ADD  '0'
          CALL DSPprintChar
          POP  AF

          RET


; DSP_PRINT_DEC16 (0038h)
; Entry ..... HL=Value
; Exit ...... None
; Modifies .. AF BC DE HL
; Print a 16bit decimal in current cursor position
; **************************************************
DSPprintDec16:
          LD   DE, 10000
          CALL .PD0
          LD   DE, 1000
          CALL .PD0
          LD   DE, 100
          CALL .PD0
          LD   A, L
          JR   PD0

.PD0:     LD   B, 0
.PD1:     LD   A, H
          CP   D
          JR   C, .PD3
          JR   NZ, .PD2
          LD   A, L
          CP   E
          JR   C, .PD3
.PD2:     INC  B
          SBC  HL, DE
          JR   .PD1

.PD3:     LD   A, B
          ADD  '0'
          CALL DSPprintChar

          RET


; DSP_PRINT_BIN (003Bh)
; Entry ..... A=Value
; Exit ...... None
; Modifies .. AF B
; Print a 8it binary in current cursor position
; ***********************************************
DSPprintBin:
          LD   B, 8

.PB0:     SLA  A
          PUSH AF
          LD   A, '0'
          JR   NC, .PB1
          INC  A
.PB1:     CALL DSPprintChar
          POP  AF
          DJNZ .PB0

          RET


; WAIT_FOR_KEY_PRESSED (0050h)
; Entry ..... None
; Exit ...... None
; Modifies .. AF B
; Wait a key be pressed and released removing bouncing
; ******************************************************
waitForKeyPressed:
          LD   A, 14
          OUT  (PSG_W_ADDRESS), A

.W0:      IN   A, (PSG_R_DATA)
          AND  01Eh
          CP   01Eh
          JR   Z, .W0

          LD   B, 0
.W1:      DJNZ .W1
.W11:     DJNZ .W11
.W12:     DJNZ .W12
.W13:     DJNZ .W13

.W2:      IN   A, (PSG_R_DATA)
          AND  01Eh
          CP   01Eh
          JR   NZ, .W2

          LD   B, 0
.W3:      DJNZ .W3
.W31:     DJNZ .W31
.W32:     DJNZ .W32
.W33:     DJNZ .W33

          RET


ready     DB "Ready!!!", 0
loaded    DB " bytes loaded", 0
press     DB "Press any key...", 0


 ORG 1FFFh
          NOP
