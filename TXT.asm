;Text Editor By Josue Flores
;Up/Down Arrow Keys Not Supported. Scrolling and Word Wrap Coming soon!                                                                             ;Text Editor By Josue Flores
.model small									
.code   
 org 100h
 Start:
   	posX      db 1 dup(0)        ; dh = posY -> controls row
    posY      db 1 dup(0)        ; dl = posX -> controls column
    Lfind     dw 1 dup(0)        ; Once was db
    matrix    db 30000 dup(0)    ;(40*750)30000 chars + 1 end of file byte .
    ScrollAdjuster dw 1 dup(0)
    curr_line dw ?
    curr_char dw ?
    Index dw ?
    fsize dw ?
	fcont db 30000 dup(0)       
    inname db 100 dup (?)       ;argv[1] pop ax, pop bx, pop cx = argv[1]
    inh dw ? 

 File:  
    mov si, 82h                       ;Finds Filename within command line. If not found, the program will not open.
    mov di, offset inname
    CLD
  
   L1:
    LODSB
    cmp al, 13
    jz errorint
    cmp al, 10
    jbe L1
    
   L2:
    STOSB
    LODSB
    cmp al, ' '
    jg L2
    sub al,al
    STOSB
    
    mov ah, 3Dh                     ;Opens File
    mov dx, offset inname
    mov al, 2
    int 21h
    jc errorint
    mov inh, ax
     
    mov ah, 42h                    ;Seeks End of File
    mov al, 2
    mov bx, inh
	mov cx, 0
	mov dx, 0
    int 21h
    jc error
    mov fsize, ax                  ;Size of File
	
    cmp fsize, 30000               ;compares size of file to Buffer
    jge ReadError
    
    mov ah, 42h                    ;Rewinds file.
    mov al, 0
    mov cx, 0
    mov bx, inh
    int 21h
    jc error    
    jmp L3
    
   errorint:
    jmp error
                              
  L3:  
    mov ah, 3Fh                     ;Reads from file
    mov bx, inh
    mov dx, offset fcont
    mov cx, fsize
    int 21h
    jc error
    
    or ax, ax
    jz Copy
    
    mov cx, fsize                   ;Writes to file
    mov ah, 40h
    mov bx, inh                     ;Used to be outh.
    mov dx, offset fcont
    int 21h
    jc error
    jmp L3
  
  Copy:
    mov si, offset fcont
    mov di, offset matrix
    mov cx, fsize
    rep movsb    
 
  Closer: 
    mov ah, 3Eh
    mov bx, inh
    int 21h
    jc error
    jmp Program
    
  Error:
	mov ah,4ch
    int 21h     
  
  ReadError:
    mov ah, 0                       ;Enters Video Mode 80x25
    mov al, 03h
    int 10h
    
    mov al, 1
    mov bh, 0
    mov bl, 14
    mov cx, msg1end - offset msg1 ; calculate message size.
    mov dl, 0
    mov dh, 0
    push cs
    pop es
    mov bp, offset msg1
    mov ah, 13h
    int 10h
    jmp msg1end
   msg1 db "File couldn't be Read; Too large for Buffer. Press any key to exit. "
   msg1end:
      
    mov ah, 00                  ;Press a key to exit
    int 16h
    cmp al, 32
    jge RIP
    
    RIP:
    mov ax, 0003h                ;Clears Screen
    int 10h
    mov ah, 4ch
    int 21h 
                
Program:      
    mov ah, 0               ;Enters Video Mode 80x25
    mov al, 03h
    int 10h
    
    cmp fsize, 0
    je Initial
    jmp Contents
    
   Initial:
    mov al, 1                 ;Prints out matrix on video mode.
    mov bh, 0
    mov bl, 14
    mov cx, fsize             ;calculate message size.
    mov dl, 0
    mov dh, 0
    push cs
    pop es
    mov bp, offset matrix
    mov ah, 13h
    int 10h
    jmp Reset
   
   Contents:
    Call PrntBuffer
    
   Reset: 
    mov dh, 0
    mov dl, 0
    Call SetCursor
    
    mov posx,0
    mov posy, 0
   
    mov curr_line, offset matrix         ;offset matrix
    mov curr_char, 0
    mov index, 0

;Insert Mode (F1)                                    
Main:
    mov  ah, 0                      ;Insert is Default Mode
    int  16h  
        
    cmp al, 27        ; ESC
    je finint
    ;cmp ah, 48h      ; UP.
    ;je Upint
    cmp ah, 4Bh       ; LEFT.
    je Leftint
    cmp ah, 4DH       ; RIGHT.
    je Rightint
    ;cmp ah, 50h      ; DOWN.
    ;je Downint
    cmp ah, 0Eh
    je BackSpaceInt
    cmp ah, 1Ch
    je EnterInt
    cmp ah, 3Ch
    je OvertypeInt    
    cmp al, 32
    jge Insert
    jmp Main   
    
    finint:
    jmp fin
    Upint:
    jmp Up
    Downint:
    jmp Down
    Rightint:
    jmp Right
    Leftint:
    jmp Left
    BackSpaceInt:
    jmp BackSpace
    Enterint:
    jmp EnterKey
    Overtypeint:        ;Overtype
    jmp Main2
    
 Insert:                      ;Works Well for 80 * 25, DONE

  key_char:
    push ax                  ;Pushes char into ax
    inc fsize                ;increments fsize in preparation
    cmp fsize, 30000         ;fsize = 30000, Forced save and Quit
    je finint
    
    
    mov si, offset matrix    ;Reads Matrix from back and updates for fsize - 1
    add si, fsize  
    mov di, si
    dec si
    mov cx, fsize
    dec cx
    sub cx, index             ;Index = Curr_char + Curr_line for screen position
    STD                     
    Rep movsb
    CLD
    
  Update:
    mov si, offset matrix
    add si, index
    pop ax
    mov  bl, [si]
    mov [si + 1], bl
    ;inc si                   ;Sync up input position with cursor
    mov [si], al
    
    Call ClearScreen
    Call PrntBuffer           ;Prints Out Buffer
    
    ;Keep these together, Text Editor behavior.
 
 Right:
    mov  dl, posX
    mov  dh, posY    
    call SetCursor
    
    mov ah, 08
    int 10h
    cmp al, 0
    je RightScroll
    
    inc  curr_char       ; update current char.
    mov  dl, posX
    mov  dh, posY
    inc  dl              ; posX ++ 
    cmp dl, 80         ;You might have to take this out later for Scrolling and Word Wrap. Used to be curr_char
    je RScroll    
    mov  posX, dl
    call SetCursor
    inc index
    
    mov bx, index
    cmp bx, fsize
    jg EndOfFile
    jmp Main
      
   EndofFile:              ;When You Reach the End of the text, you can't scroll out.
    dec index
    dec dl
    Call SetCursor
    mov PosX, dl
    jmp Main
        
   RightScroll:                         ;RIGHT SCROLL FEATURE
    mov bx, index
    mov curr_line, bx
    mov curr_char, 0
    mov dl, 0
    mov posX, dl
    ;mov dh, posY
    inc dh
    mov posY, dh
    call SetCursor
    inc index            ;You can duplicate this for cmp dl, 80 but for just one inc index
    inc index
    jmp Main
    
   RScroll:
    mov bx, index
    mov curr_line, bx
    mov curr_char, 0
    mov dl, 0
    mov posX, dl
    mov dh, posY
    inc dh
    mov posY, dh
    call SetCursor
    inc index            ;You can duplicate this for cmp dl, 80 but for just one inc index
    jmp Main   
   
   Maininter:
    call Setcursor
    jmp Main
    
 Left:
    dec index               ;Checks if Char before in index was newline.
    mov si, offset matrix
    add si, index
    mov al, [si]
    cmp al, 10
    je LeftScroll
    
    inc index
    dec  curr_char       ; update current char.
    mov  dl, posX
    mov  dh, posY
    dec  dl              ; posX --
    cmp dl, -1           ;might have to fix this.
    je LScroll
    mov  posX, dl
    call SetCursor
    dec index
    jmp Main
     
  LeftScroll:                    ;LEFT SCROLL FEATURE    
    inc index
    cmp dh, 0
    jle maininter2
    mov bx, index
    cmp bx, 0                   ;Fix this later for Scrolling.
    jle maininter2
    
    dec dh
    mov dl, 0
    Call SetCursor   
   
   S3: 
    mov ah, 08
    int 10h
    cmp al, 0
    je Found
    inc dl
    Call SetCursor
    jmp S3
    
   Found:
    mov bl, dl
    CBW
    mov Lfind, bx     ;Was dl before    
    
    dec index
    dec index 
    mov posX, dl
    mov posY, dh
    mov bx, Lfind 
    mov curr_char, bx
    jmp main
  
  LScroll:                    ;LEFT SCROLL FEATURE    
    cmp dh, 0
    jle maininter2
    mov bx, index
    cmp bx, 0                   ;Fix this later for Scrolling.
    jle maininter2    
    
    dec dh
    mov dl, 79
    Call SetCursor   
    
    dec index 
    mov posX, dl
    mov posY, dh 
    mov curr_char, 79
    jmp main    

   maininter2:
    inc curr_char
    inc dl
    Call SetCursor
    jmp main
 
 
 Up:                                                ;Fix this
    sub  curr_line, 80   ; update current line.
    mov  dl, posX
    mov  dh, posY
    dec  dh              ; posY -- 
    mov  posY, dh
    call SetCursor         ; print cursor
    sub index, 80
    jmp main

 Down:                                              ;Fix this.
    add  curr_line, 80   ; update current line.
    mov  dl, posX
    mov  dh, posY
    inc  dh              ; posY ++
    mov  posY, dh
    call SetCursor       
    add index, 80
    jmp main
    
 EnterKey:
    
    add fsize, 2
    mov si, offset matrix    ;Reads Matrix from back and updates for fsize - 1
    add si, fsize  
    mov di, si
    sub si, 2
    mov cx, fsize
    sub cx, 1
    sub cx, index                ;Index dictates position on screen
    STD
    Rep movsb
    CLD    
   
    mov si, offset matrix              ;Cursor Position
    add si, index
    mov bl, 13
    mov [si], bl
    inc si
    mov bl, 10
    mov [si], bl
        
    Call clearScreen
    Call PrntBuffer
    
    inc index
    inc index
    mov posx, 0
    add posy, 1
    mov si, offset matrix
    add si, index
    mov curr_char, 0 
    add curr_line, 80
    mov dh, posy
    mov dl, posx
    Call SetCursor
    jmp main
 
 BackSpace:                 ;Fix when trying to delete from end.
    cmp fsize, 0
    jg PreBS
    jmp Main
    
    PreBS:
    Call SetCursor
    mov ah, 08
    int 10h
    cmp ah, 14
    je BS
    jmp Main
    
  BS: 
    mov ah, 08h
    int 10h
    cmp al, 0
    je DEnter
    
    mov si, offset matrix      
    add si, index
    mov di, si
    inc si
    mov cx, fsize
    ;inc cx          ;added
    sub cx, index
    Rep movsb
    jmp L4
    
  DEnter:
    mov si, offset matrix      
    add si, index
    mov di, si
    inc si
    mov cx, fsize
    sub cx, index
    Rep movsb
    
    dec fsize
    
    mov si, offset matrix      
    add si, index
    mov di, si
    inc si
    mov cx, fsize
    sub cx, index
    Rep movsb
    jmp L4    
          
  L4:  
    Call ClearScreen
    Call PrntBuffer
    dec fsize
    mov dh, Posy
    mov dl, PosX
    Call SetCursor
    jmp Left
    
 PrntBuffer:                 ;Prints Buffer
    mov dh, 0               ;Sets to beginning of the Video mode
    mov dl, 0
    Call SetCursor
    mov cx, fsize
    mov si, offset matrix   ; si = index
    ;add si, scrolladjuster  ;Scroller
   OB:   
    push cx
    mov al, [si]
    cmp al, 13
    je CR
    
    mov  ah, 9
    mov  bh, 0
    mov  bl, 14                            
    mov  cx, 1           ; how many times display char.
    int  10h    
    
    inc si
    inc dl
    Call SetCursor
    jmp R
     
   CR:
    mov  al, 0
    mov  ah, 9
    mov  bh, 0
    mov  bl, 14                            
    mov  cx, 1           ; how many times display char.
    int  10h
    
    pop cx
    
    inc si
    inc si
    dec cx    
    jmp RS
    
   R:
    pop cx
    cmp dl, 80             ;Remove this for Scrolling Mode
    je RS
    Loop OB
    Ret
   
    
   RS:
    mov dl, 0
    inc dh
    Call SetCursor
    Loop OB
    Ret

 SetCursor:                 ;Sets Cursor
    mov ah, 2h
    mov bh, 0
	int 10h    
	ret
     
 ClearScreen:
    mov ax, 0003h
    int 10h
    ret

 Fin:                           ;Writes matrix into file and closes it.
    mov ah, 3Dh                 ;Opens File To Write-Only Mode.
    mov dx, offset inname
    mov al, 1
    int 21h
    jc errorint2
    mov inh, ax
     
    mov ah,40h                  ;Writes to File to empty it.
    mov bx, inh
    mov cx, 0
    mov dx, offset matrix
    int 21h
    jc errorint2
    
    mov ah,40h                  ;Writes to File from matrix array for fsize bytes.
    mov bx, inh
    mov cx, fsize
    mov dx, offset matrix
    int 21h
    jc errorint2
    jmp Done
	
 Done:                          ;Closes File.
	mov bx, inh
	mov ah, 3Eh
	int 21h
	jc errorint2
	
	mov ax,0003h                ;Clears Screen and Exits.
    int 10h
	mov ah,4ch
    int 21h 
    
  errorint2:
    jmp error


;Overtype Mode (F2)
Main2:     
    mov  ah, 0                      ;Insert is Default Mode
    int  16h  
        
    cmp al, 27        ; ESC
    je finint2
    ;cmp ah, 48h       ; UP.
    ;je Upint2
    cmp ah, 4Bh       ; LEFT.
    je Leftint2
    cmp ah, 4DH       ; RIGHT.
    je Rightint2
    ;cmp ah, 50h       ; DOWN.
    ;je Downint2
    cmp ah, 0Eh
    je BackSpaceInt2
    cmp ah, 1Ch
    je EnterInt2    
    cmp ah, 3Bh
    je InsertInt    
    cmp al, 32
    jge OverType
    jmp Main2   
    
    finint2:
    jmp fin2
    Upint2:
    jmp Up2
    Downint2:
    jmp Down2
    Rightint2:
    jmp Right2
    Leftint2:
    jmp Left2
    BackSpaceInt2:
    jmp BackSpace2
    EnterInt2:
    jmp EnterKey2
    Insertint:              ;Insert Mode
    jmp Main
    
 Overtype:                    ;Works Well for 80 * 25, DONE

  key_char2:
    push ax                  ;Pushes char into ax
    xor cx, cx               ;clears cx
    mov cx, index
    cmp cx, fsize
    jl Update2           ; Less or Equal?
    inc fsize                 ;increments fsize in preparation
    cmp fsize, 30000         ;fsize = 30000, Forced save and Quit
    je finint2
    
    

;UPDATE CHAR IN MATRIX.    
   Update2: 
    pop ax
    mov si, offset matrix
    add si, index
    mov bl, [si]
    cmp bl, 13
    je NoUpdate
    mov [ si ], al      ; the char is in the matrix.   
    xor cx, cx       
    jmp Continue
    
   NoUpdate:
    inc fsize                ;Fix this?
    mov si, offset matrix    ;Reads Matrix from back and updates for fsize - 1
    add si, fsize  
    mov di, si
    dec si
    mov cx, fsize
    ;dec cx                   ;Commented this to account for 10 ascii char associated with enter key.
    sub cx, index             ;Index = Curr_char + Curr_line for screen position
    STD                     
    Rep movsb
    CLD
    
    mov si, offset matrix
    add si, index
    mov [ si ], al      ; the char is in the matrix.   
    xor cx, cx
    
    Call ClearScreen
    Call PrntBuffer    
    jmp Right2

   Continue:
    Call PrntBuffer
        
    ;Keep these together, Text Editor behavior.

 Right2:
    mov  dl, posX
    mov  dh, posY    
    call SetCursor2
    
    mov ah, 08
    int 10h
    cmp al, 0
    je RightScroll2
    
    inc  curr_char       ; update current char.
    mov  dl, posX
    mov  dh, posY
    inc  dl              ; posX ++ 
    cmp dl, 80         ;You might have to take this out later for Scrolling and Word Wrap. Used to be curr_char
    je RScroll2    
    mov  posX, dl
    call SetCursor2
    inc index
    mov bx, index
    cmp bx, fsize
    jg EndofFile2
    jmp main2
    
    EndofFile2:
    dec index
    dec dl
    Call SetCursor
    mov PosX, dl   
    jmp main2
    
       
  RightScroll2:                         ;RIGHT SCROLL FEATURE
    mov bx, index
    mov curr_line, bx
    mov curr_char, 0
    mov dl, 0
    mov posX, dl
    inc dh
    mov posY, dh
    call SetCursor2
    inc index
    inc index
    jmp main2
    
  RScroll2:
    mov bx, index
    mov curr_line, bx
    mov curr_char, 0
    mov dl, 0
    mov posX, dl
    mov dh, posY
    inc dh
    mov posY, dh
    call SetCursor
    inc index            ;You can duplicate this for cmp dl, 80 but for just one inc index
    jmp main2     
      
   maininter3:
    call Setcursor2
    jmp main2
    

 Left2:
    dec index
    mov si, offset matrix
    add si, index
    mov al, [si]
    cmp al, 10
    je LeftScroll2
        
    inc index
    dec  curr_char       ; update current char.
    mov  dl, posX
    mov  dh, posY
    dec  dl              ; posX --
    cmp dl, -1
    je LScroll2
    mov  posX, dl
    call SetCursor2
    dec index
    jmp main2
   
  LeftScroll2:                    ;LEFT SCROLL FEATURE    
    inc index
    cmp dh, 0
    jle maininter4
    mov bx, index
    cmp bx, 0                   ;Fix this later for Scrolling.
    jle maininter4
    
    dec dh
    mov dl, 0
    Call SetCursor2   
   
   S4: 
    mov ah, 08
    int 10h
    cmp al, 0
    je Found2
    inc dl
    Call SetCursor2
    jmp S4
    
   Found2:
    mov bl, dl
    CBW
    mov Lfind, bx     ;Was dl before    
    
    dec index
    dec index 
    mov posX, dl
    mov posY, dh
    mov bx, Lfind 
    mov curr_char, bx
    jmp main2
  
  LScroll2:                    ;LEFT SCROLL FEATURE    
    cmp dh, 0
    jle maininter4
    mov bx, index
    cmp bx, 0                   ;Fix this later for Scrolling.
    jle maininter4    
    
    dec dh
    mov dl, 79
    Call SetCursor2   
    
    dec index 
    mov posX, dl
    mov posY, dh 
    mov curr_char, 79
    jmp main2
    
   maininter4:
    inc curr_char
    inc dl
    Call SetCursor
    jmp main2

 Up2: 
    dec dl
    dec index
    cmp dl, -1
    
    Call SetCursor2
    mov ah, 08
    int 10h
    
    dec dh                    ;Index Position line above.
    mov dl, 0
    Call SetCursor2   
   
   S5: 
    mov ah, 08
    int 10h
    cmp al, 0
    je Found3
    inc dl
    Call SetCursor2
    jmp S5
    
   Found3:
    mov bl, dl
    CBW
    mov Lfind, bx     ;Was dl before    
    
    dec index
    dec index 
    mov posX, dl
    mov posY, dh
    mov bx, Lfind 
    mov curr_char, bx
    jmp main2    

 Down2:   
    add  curr_line, 80   ; update current line.
    mov  dl, posX
    mov  dh, posY
    inc  dh              ; posY ++
    mov  posY, dh
    call SetCursor        
    jmp main2
 
 EnterKey2: 
    add fsize, 2
    mov si, offset matrix    ;Reads Matrix from back and updates for fsize - 1
    add si, fsize  
    mov di, si
    sub si, 2
    mov cx, fsize
    sub cx, 1
    sub cx, index                ;Index dictates position on screen
    STD
    Rep movsb
    CLD    
   
    mov si, offset matrix               ;Cursor Position
    add si, index
    mov bl, 13
    mov [si], bl
    inc si
    mov bl, 10
    mov [si], bl
        
    Call clearScreen
    Call PrntBuffer
    
    inc index
    inc index
    mov posx, 0
    add posy, 1
    mov si, offset matrix
    add si, index
    mov curr_char, 0 
    add curr_line, 80
    mov dh, posy
    mov dl, posx
    Call SetCursor2
    jmp main2
 
 BackSpace2:
    cmp fsize, 0
    jg PreBS2
    jmp Main2
    
   PreBS2:
    Call SetCursor
    mov ah, 08
    int 10h
    cmp ah, 14
    je BS2
    jmp Main2    
    
   BS2: 
    mov ah, 08h
    int 10h
    cmp al, 0
    je DEnter2
    
    mov si, offset matrix      
    add si, index
    mov di, si
    inc si
    mov cx, fsize
    sub cx, index
    Rep movsb
    jmp L5
    
   DEnter2:
    mov si, offset matrix      
    add si, index
    mov di, si
    inc si
    mov cx, fsize
    sub cx, index
    Rep movsb
    
    dec fsize
    
    mov si, offset matrix      
    add si, index
    mov di, si
    inc si
    mov cx, fsize
    sub cx, index
    Rep movsb
    jmp L5    
    
   L5:
    Call ClearScreen
    Call PrntBuffer
    dec fsize
    mov dh, PosY
    mov dl, PosX
    Call SetCursor
    jmp Left2        
    
 SetCursor2:                 ; print cursor
    mov ah, 2h
    mov bh, 0
	int 10h    
	ret

 Fin2:                            ;Writes matrix into file and closes it.
    mov ah, 3Dh                 ;Opens File To Write-Only Mode.
    mov dx, offset inname
    mov al, 1
    int 21h
    jc errorint3
    mov inh, ax
     
    mov ah,40h                  ;Writes to File to Empty it.
    mov bx, inh
    mov cx, 0
    mov dx, offset matrix
    int 21h
    jc errorint3
    
    
    mov ah,40h                  ;Writes to File from matrix array for fsize bytes.
    mov bx,inh
    mov cx, fsize
    mov dx, offset matrix
    int 21h
    jc errorint3
    jmp Done
	
  Done2:                          ;Closes File.
	mov bx, inh
	mov ah, 3Eh
	int 21h
	jc errorint3
	
	mov ax,0003h                    ;Clears Screen and Exits.
    int 10h
	mov ah,4ch
    int 21h 
    
   errorint3:
    jmp error
        
end Start
     
  ;Actual Scrolling for First line only  
   RScroll3:
    inc ScrollAdjuster
    Call ClearScreen
    Call PrntBuffer
    mov bx, index
    cmp bx, fsize
    jg EndOfFile    
    inc index
    mov dh, PosY
    mov dl, 79
    Call SetCursor    
    jmp Main
    
   LScroll3:
    ;cmp dh, 0
    ;jle mainint2
    mov bx, index
    cmp bx, 0                   ;Fix this later for Scrolling.
    jle mainint2    
    ;mov bx, scrollAdjuster
    ;cmp bx, 0
    ;jne Con
    ;jmp main
   Con:
    dec ScrollAdjuster
    ;mov bx, index
    ;sub ScrollAdjuster, bx
    Call ClearScreen
    Call PrntBuffer
    dec index
    mov dh, posY
    mov dl, 0
    Call SetCursor
    jmp Main
      