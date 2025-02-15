;########################################################################
;   ____            _                        _      
;  |  _ \          | |     /\               | |     
;  | |_) | __ _  __| |    /  \   _ __  _ __ | | ___ 
;  |  _ < / _` |/ _` |   / /\ \ | '_ \| '_ \| |/ _ \
;  | |_) | (_| | (_| |  / ____ \| |_) | |_) | |  __/
;  |____/ \__,_|\__,_| /_/    \_\ .__/| .__/|_|\___|
;                               | |   | |           
;                               |_|   |_|                
;########################################################################

;------------------------------------------------------------------------
;  ___         _         _        
; |_ _|_ _  __| |_  _ __| |___ ___
;  | || ' \/ _| | || / _` / -_|_-<
; |___|_||_\__|_|\_,_\__,_\___/__/
;                                 
;------------------------------------------------------------------------

				processor 6502
				include "vcs.h"
				include "macro.h"
				
;------------------------------------------------------------------------
;   ___             _            _      
;  / __|___ _ _  __| |_ __ _ _ _| |_ ___
; | (__/ _ \ ' \(_-<  _/ _` | ' \  _(_-<
;  \___\___/_||_/__/\__\__,_|_||_\__/__/
;                                         
;------------------------------------------------------------------------

SCREEN_H		equ #192					; Altura da tela em scanlines
PIXEL_H			equ #16						; Altura da tela em pixels

PF_COL			equ	#$0E					; Cor do playfield
BG_COL			equ #$00					; Cor do fundo

FPS				equ #60						; Quadros por segundo
SCREEN_RATE		equ #1						; Telas por segundo
AUD_RATE		equ #8						; Notas por segundo

AUD_CTL			equ #1						; Tipo de som
AUD_VOL			equ #3						; Volume do audio

;------------------------------------------------------------------------
; __   __        _      _    _        
; \ \ / /_ _ _ _(_)__ _| |__| |___ ___
;  \ V / _` | '_| / _` | '_ \ / -_|_-<
;   \_/\__,_|_| |_\__,_|_.__/_\___/__/
;
;------------------------------------------------------------------------

				seg.u vars
				org $80

temp			ds 1						; Variavel temporaria

audIndex		ds 1						; Indice do audio
audTimer		ds 1						; Temporizador para mudar de audio
audTableInd		ds 1						; Indice da tabela de audio

screenOffset	ds 1						; Offset da tela (pixels)
screenTimer		ds 1						; Temporizador para mudar de tela
screenTableInd	ds 1						; Indice da tabela de tela

				seg	main
				org $f000

;------------------------------------------------------------------------
;  ___             _   
; | _ \___ ___ ___| |_ 
; |   / -_|_-</ -_)  _|
; |_|_\___/__/\___|\__|
;                      
;------------------------------------------------------------------------

reset:			CLEAN_START					; Reseta o hardware

				; Cor do playfield e fundo
				lda #PF_COL					; (2)
				sta	COLUPF					; (3)
				lda #BG_COL					; (2)
				sta COLUBK					; (3)

				; Reseta variaveis
				lda #0						; (2)
				sta audIndex				; (3)
				sta audTableInd				; (3)
				sta screenOffset			; (3)
				sta screenTableInd			; (3)
				sta AUDV0					; (3)

				; Temporizador de tela e de audio
				lda #FPS/SCREEN_RATE		; (2)
				sta screenTimer				; (3)
				lda #FPS/#AUD_RATE			; (2)
				sta audTimer				; (3)

				; Audio
				lda #AUD_CTL				; (2)
				sta AUDC0					; (3)

;------------------------------------------------------------------------
;  _   _          _      _       
; | | | |_ __  __| |__ _| |_ ___ 
; | |_| | '_ \/ _` / _` |  _/ -_)
;  \___/| .__/\__,_\__,_|\__\___|
;       |_|                      
;------------------------------------------------------------------------

startFrame:
;......................... VERTICAL SYNC (3) ............................
				lda #0            			; (2)       
				sta VBLANK					; (3)
				lda #2                   	; (2)
				sta VSYNC                	; (3)
				sta WSYNC                	; (3)
				sta WSYNC					; (3)
				sta WSYNC					; (3)
				lda #0						; (2)
				sta VSYNC					; (3)

;......................... VERTICAL BLANK (37) ..........................
				ldx #0						; (2)
verticalBlank:	sta WSYNC					; (3)				
				inx							; (2)
				cpx #35    					; (2)
				bne verticalBlank			; (2/3)

				; Define frequencia de audio atual
				lda audIndex				; (3)
				and #%00000001				; (2)
				sta temp					; (3)
				lda audIndex				; (3)
				lsr							; (2)
				tay							; (2)

				lda AUD_DATA_0,y			; (4)
				ldx audTableInd				; (3)
				beq	foundTable				; (2/3)
				lda AUD_DATA_1,y			; (4)
				dex 						; (2)
				beq	foundTable				; (2/3)
				lda AUD_DATA_2,y			; (4)
				dex 						; (2)
				beq	foundTable				; (2/3)
				lda AUD_DATA_3,y			; (4)

foundTable:		sta WSYNC					; (3)
				ldx temp					; (3)
				bne oddAudInd				; (2/3)

				lsr							; (2)
				lsr							; (2)							
				lsr							; (2)
				lsr							; (2)

oddAudInd:		and #%00001111				; (2)
				tay							; (2)
				lda KEYS_DATA,y				; (4)
				beq muteAud					; (2/3)
				sta AUDF0					; (3)
				lda #3						; (2)

muteAud:		sta AUDV0					; (3)
		        sta WSYNC					; (3)

;......................... DRAWFIELD (192) ..............................

				ldx #0						; (2)
drawField0:		lda	dividePixelHeight,x		; (4)
				clc							; (2)
				adc screenOffset			; (3)
				tay							; (2)

				lda SCREEN_0_DATA_0,y		; (4)
				and #%00001111				; (2)
				sta WSYNC					; (3)
				sta PF1						; (3)

				lda SCREEN_1_DATA_0,y		; (4)
				and #%00001111				; (2)
				sta temp					; (2)
				lda SCREEN_0_DATA_0,y		; (4)
				and #%11110000				; (2)
				clc							; (2)
				adc temp					; (3)
				sta PF2						; (3)

				lda SCREEN_1_DATA_0,y		; (4)
				and #%11110000				; (2)
				sta PF0						; (3)

				lda SCREEN_2_DATA_0,y		; (4)
				sta PF1						; (3)

				SLEEP 14
				lda #0						; (2)
				sta PF2						; (3)
				sta PF1						; (3)
				sta PF0						; (3)

				sta WSYNC					; (3)

				inx							; (2)
				inx							; (2)
				cpx #SCREEN_H				; (2)
				bne drawField0				; (2/3)

				lda #%01000010				; (2)
				sta VBLANK					; (3)

;......................... OVERSCAN (30) ................................

				ldx #0						; (2)
overscan:       sta WSYNC					; (3)
				inx							; (2)
				cpx #27						; (2)
				bne overscan				; (2/3)

				sta WSYNC					; (3)

				; Audio
				dec audTimer				; (5)
				bne noAudIndex				; (2/3)
				inc audIndex				; (5)
				bne noAudTable	    		; (2/3)
				inc audTableInd				; (5)
noAudTable:		lda #FPS/#AUD_RATE			; (2)
				sta audTimer				; (3)
noAudIndex:
				sta WSYNC					; (3)

				; Tela
				dec screenTimer				; (5)
				bne noScreenOffset			; (2/3)
				lda screenOffset			; (3)
				clc							; (2)
				adc #PIXEL_H				; (3)
				sta screenOffset			; (3)
				bne noScreenTable			; (2/3)
				inc screenTableInd			; (5)
noScreenTable: 	lda #FPS/#SCREEN_RATE		; (2)
				sta screenTimer				; (3)
noScreenOffset:

				sta WSYNC					; (3)

				jmp startFrame				; (3) Fim do frame, avanca para o proximo

;------------------------------------------------------------------------
;   ___                     _   _             
;  / _ \ _ __  ___ _ _ __ _| |_(_)___ _ _  ___
; | (_) | '_ \/ -_) '_/ _` |  _| / _ \ ' \(_-<
;  \___/| .__/\___|_| \__,_|\__|_\___/_||_/__/
;       |_|                                   
;------------------------------------------------------------------------

dividePixelHeight									
.POS			SET 0								
				REPEAT #SCREEN_H + 1
				.byte .POS / (#SCREEN_H/#PIXEL_H)
.POS			SET .POS + 1
				REPEND	

;------------------------------------------------------------------------
;     _          _ _       ___       _        
;    /_\ _  _ __| (_)___  |   \ __ _| |_ __ _ 
;   / _ \ || / _` | / _ \ | |) / _` |  _/ _` |
;  /_/ \_\_,_\__,_|_\___/ |___/\__,_|\__\__,_|                                                               
;------------------------------------------------------------------------

				include "keys_data.h"
				include "audio_data.h"

;------------------------------------------------------------------------
;  ___                        ___       _        
; / __| __ _ _ ___ ___ _ _   |   \ __ _| |_ __ _ 
; \__ \/ _| '_/ -_) -_) ' \  | |) / _` |  _/ _` |
; |___/\__|_| \___\___|_||_| |___/\__,_|\__\__,_|
;------------------------------------------------------------------------

				include "screen_data.h"

;------------------------------------------------------------------------
;  ___         _ 
; | __|_ _  __| |
; | _|| ' \/ _` |
; |___|_||_\__,_|
;------------------------------------------------------------------------          

				org $fffa
	
interruptVectors:
				.word reset     			; nmi
				.word reset     			; reset
				.word reset     			; irq