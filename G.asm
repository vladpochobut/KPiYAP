    .model  tiny
    .code
    
    org     100h
              
      
    print   macro   str ;
        push    ax
        push    dx
    
        mov     ah, 09h
        lea     dx, str
        int     21h
        
        pop     dx
        pop     ax
endm      
              
eic     macro   cond, str                   ;Exit if condition is met 
        LOCAL   exitMacro, writeError
                        
        cond    writeError                      
        jmp     exitMacro
                                        
writeError:   
        mov     ah, 09h
        lea     dx, str
        int     21h
                
        mov     ah, 4Ch
        int     21h       
                
exitMacro:
endm              
          
          
          
start:          
        mov     ch, 0 
        mov     cl, es:[0080h] ;
        mov     si, 81h ;
        lea     di, file
        mov     bx, 125 ;
        call    readParam               ; Read params   
        mov     bx, 5 ;
        lea     di, buffer
        call    readParam
        
        cmp     file[0], 0 ;
        eic     je, neParams            ; Check params 
        cmp     buffer[0], 0 
        eic     jne, tmParams ;                                 
        
        mov     ah, 3Dh
        mov     al, 0 ;
        lea     dx, file       
        int     21h
        eic     jc, fileError           ; Try to open file            
        mov     bx, ax
        
        call    calcNotEmptyLines       ; Calc number of not empty lines
        mov     ax, neLines    
        print   notELines
        call    printNumber             ; Print number of not empty lines                                                           
            
closeFile:          
        mov     ah, 3Eh
        int     21h 
        eic     jc, closeError          ; Close file                           
                      
exitProgram:                                          
        mov     ah, 4Ch
        int     21h                     ; Exit              

printNumber proc    
        push    bp
        push    ax
        push    bx
        push    dx
                  
        mov     bp, sp                
                  
getCharLoop:    
        mov     dx, 0 ;
        mov     bx, 10
        div     bx    ;
        
     ;  push    ax
        add     dl, '0'
       ;pop     ax      
       push    dx ;
        
        cmp     ax, 0
        jne     getCharLoop
        
printCharLoop:      
        pop     dx   ;
        mov     ah, 2h
        int     21h
        cmp     bp, sp
        jne     printCharLoop               
            
        pop     dx
        pop     bx
        pop     ax
        pop     bp                          
        ret                
endp    printNumber             


calcNotEmptyLines proc    
        push    ax
        push    bx
        push    cx
        push    dx
    
readFileLoop:       
        mov     cx, 1024 ;
        lea     dx, buffer 
        mov     ah, 3Fh
        int     21h
        eic     jc, readError
        cmp     ax, 0
        je      exitCalcNotEmptyLines       
                         
        mov     cx, ax
        lea     si, buffer
processCharLoop: 
        lodsb
        cmp     al, 0Ah  ; 
        je      foundNewline    
        cmp     al, 0Dh  ; 
        je      nextChar
                           
        mov     lineEmpty, 0    ;                     
        jmp     nextChar
                  
foundNewline:             
        call    lineEnded
        
        nextChar:s
        loop    processCharLoop                                                              
        jmp     readFileLoop                                            
                      
exitCalcNotEmptyLines:
        call    lineEnded    ;                                
        pop     dx
        pop     cx
        pop     bx
        pop     ax             
        ret                      
endp    calcNotEmptyLines
              


lineEnded proc    
        cmp     lineEmpty, 1  ;
        je      lineIsEmpty
        inc     neLines                             
                        
lineIsEmpty:
        mov     lineEmpty, 1                
                 
        ret              
endp    lineEnded
              
              
        
readParam proc  ;     
        push    ax    
        push    bx                  
     
        jcxz    exitReadParam
                                                              
skipSpaces:  
        push    es  ;
        push    di
        mov     ax, ds
        mov     es, ax
        mov     di, si
        
        mov     al, ' '
        repz    scasb      
        dec     di   
        inc     cx
        mov     si, di  
        
        pop     di
        pop     es
                
findParamEnd:
        movsb   ;
        dec     bx  ;
        dec     cx
        cmp     bx, 0 ;
        je      paramEnded
        cmp     byte ptr es:[di - 1], 0Dh ;
        je      paramEnded
        cmp     byte ptr es:[di - 1], ' ' ;
        jne     findParamEnd
        
paramEnded:         
        dec     di    ;
        mov     byte ptr es:[di], 0
        inc     di

exitReadParam:    
        pop     bx   
        pop     ax                          
        ret                 
endp    readParam   
                                                   
        file        db 125 dup(0)
        buffer      db 1024 dup(0)  
        neLines     dw 0     
        lineEmpty   db 1            

        notELines   db "Not empty lines: $"                                
                                   
        neParams    db "! Not enough params$"        
        tmParams    db "! Too many params$"
        fileError   db "! Can't open file$"     
        readError   db "! Read error$"      
        closeError  db "! Close error$"                                                 
end     start
        