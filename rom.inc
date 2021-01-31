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


; ** Programmable Sound Generator **
; **********************************
PSG_W_DATA          EQU 002h
PSG_W_ADDRESS       EQU 003h
PSG_R_DATA          EQU 003h


; ** LCD 20x4 ***
; ***************
DISPLAY_REG         EQU 000h
DISPLAY_DATA        EQU 001h

CLEAR_DISPLAY       EQU 001h
RETURN_HOME         EQU 002h

ENTRY_MODE_SET      EQU 004h
ID_INCREMENT        EQU 002h
S_SHIFT             EQU 001h

DISPLAY_CONTROL     EQU 008h
D_DISPLAY_ON        EQU 004h
C_CURSOR_ON         EQU 002h
B_BLINKING_CURSOR   EQU 001h

FUNCTION_SET        EQU 020h
DL_8BITS            EQU 010h
N_2LINES            EQU 008h
F_5X10DOTS          EQU 004h

SET_DDRAM_ADDR      EQU 080h


; ** System calls **
; ******************
RESET                   EQU 0000h
PSG_INIT                EQU 0010h
DSP_INIT                EQU 0020h
DSP_WAIT                EQU 0023h
DSP_WRITE_REG           EQU 0026h
DSP_SCROLL_UP           EQU 0029h
DSP_PRINT_CHAR          EQU 002Ch
DSP_PRINT_STRING        EQU 002Fh
DSP_PRINT_HEX           EQU 0032h
DSP_PRINT_DEC           EQU 0035h
DSP_PRINT_DEC16         EQU 0038h
DSP_PRINT_BIN           EQU 003Bh
WAIT_FOR_KEY_PRESSED    EQU 0050h

; ** Others **
; ************
RAM_START_POINTER   EQU 08000h
