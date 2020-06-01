	.model tiny
	.code
	.186
	org 100h


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
	mov		ch, 0  ; вводд параметров
	mov		cl, es:[0080h] ;количество символов командной строки
	mov		si, 81h
	lea		di, numberOfLaunches    
	mov		bx, 127 
	call	readParam	
	lea		di, buff
	mov		bx, 5
	call	readParam
	
	cmp		numberOfLaunches[0], 0 ; срвынение ввели параметры или нет
	eic		je, neParams
	cmp		buff[0], 0  ;проверяем на пустоту буфера
	eic		jne, tmParams                                                        
	                      
	lea		di, numberOfLaunches ; перевод из строки в инт
	call	atoi   
	mov		cx, ax
	lea		dx, programPath 
	 
launchLoop:	    
	call	startApp	   ; циклически запускаем            	               
	loop	launchLoop	                      
	                             
	mov		ah, 4Ch  ;выход
	int		21h


atoi proc			;DI to AX в ди строка и ах число
		push	bx
		push	dx
	
		mov		ax, 0  
	 
atoiLoop:
		cmp		byte ptr [di], 0    ;сравниваем текущий с 0
		je		exitAtoi ;если равен нулю то выходим
	 
		cmp		byte ptr [di], '0' ; сравниваем с символом нуля
		eic		jl, wrongNumber		; если меньше 0 то не цифра
		cmp		byte ptr [di], '9'  ;сравниваем с 9
		eic		jg, wrongNumber     ;если больше 
			      
		mov		bx, 10	; переводим из чара в инт 
		mul		bx
		mov		bl, [di] ;записываю текущую
		sub		bl, '0'  ; отнимаю 0
		add		ax, bx   ; добавляю
		
		cmp		ax, 255  ;сравниваю с максимумом
		eic		jg, wrongNumber 					      
			            
		inc		di	;++          
		jmp		atoiLoop
		
exitAtoi:							    
		cmp		ax, 1  ;сравниваем с 1 и если меньше то ексепшен
		eic		jl, wrongNumber
		cmp		ax, 255 ; сравниваем с максимумом
		eic		jg, wrongNumber
			        	
		pop		dx
		pop		bx			        	
		ret	        
endp	atoi


startApp proc								;Starts app with path in DX	      
		push	ax							
		push	bx							
		push	dx	            

		mov		esVal, es					;сохраням сегменты воизбежание их утери, для нормальной работы
		mov		dsVal, ds
		mov		ssVal, ss
		mov		spVal, sp
		
		mov		sp, memorySize				;перемещаем указатель стека
		                                    
		mov		ah, 4Ah						;изменене размера памяти
	
		mov		bx, memorySize shr 4 + 1	;узнаём количество наших сегментов + для того что бы влезло добавлям 1
		int		21h      					;Free memory after program end
		
		eic		jc, memModError    			;если флаг ошибки то выходим
		              		             		             
		mov		ax, cs						;в ах сегмент с данными				
		mov		word ptr EPB + 4, ax		;записываем сегмент в каждый параметр ЕРВ + ком строка
		mov		word ptr EPB + 8, ax		; FCB1
		mov		word ptr EPB + 0Ch, ax		;Fill EPB сегмент FCB2
		                                
		mov		ax, 4B00h     ;функция дня ззапуска программы
		lea		bx, EPB      ; передаём EPB
		int		21h							;Launch program	    
		
		mov		es, cs:esVal  ;востанавливаем сегменты так как в сом программе все сегменты одинаковые обращаемся к cs
		mov		ds, cs:dsVal
		mov		ss, cs:ssVal
		mov		sp, cs:spVal

		eic		jc, startError		                  				                 		                 		  		        				         	                	               	                           				                           	                           	
	           
		pop		dx	           
		pop		bx
		pop		ax	        	
	                
		ret	            
endp	startApp




	
readParam proc			;считывание
		push	ax	  
		push	bx     	          	
	           
		cmp		cx, 0	           
	 	jle		exitReadParam
	        	      	                  	                  
skipSpaces:       ;пропуск пробеллов
		push	di
		mov		di, si
		
		mov		al, ' '
		repz	scasb	   
		dec		di   
		inc		cx
		mov		si, di  
		
		pop		di
		        
findParamEnd:
		movsb       ;проверяем на конец
		dec		bx
		dec		cx
		cmp		bx, 0
		je		paramEnded
		cmp		byte ptr es:[di - 1], 0Dh
		je		paramEnded
		cmp		byte ptr es:[di - 1], ' '
		jne		findParamEnd
		
paramEnded:	   		
		dec		di    ; если параметр закончился то записываем 0
		mov		byte ptr es:[di], 0
		inc		di

exitReadParam:	  
		pop		bx   
		pop		ax	     		        	
		ret	            	
endp	readParam 

		programPath	db	"app.com", 0
                                 
		memModError	db "! Can't modify memory block$"
		startError	db "! Can't start app$"                                  
		wrongNumber	db "! Please, enter number between 1 and 255$"                               
		neParams	db "! Not enough params$"               
		tmParams	db "! Too many params$"
		                     
		numberOfLaunches	db	128 dup(0) 
		buff				db	5 dup(0)
		
		esVal			dw 0
		dsVal			dw 0
		ssVal			dw 0
		spVal			dw 0	                      	
		                      
		EPB			dw 0000 ; блок параметров запуска
					dw offset commandLine, 0 ;адрес командной строки, записывание сегмента с данными
					dw 005Ch, 0, 006Ch, 0  ;FCB1 заполняется с первого параметра ком строки FCB2 со второго
		commandLine	db 0, 0Dh   
                                                                      
		memorySize	EQU $ - start + 100h + 200h   ;тенущая позиция - начальная позиция  + сегмент PSP + стек                              
                               
end		start