
ORG 100h

.DATA  
    titulo db 'CALCULADORA$'
    titulo1 db 'Juan Prada -- 20221978002$'
    titulo2 db 'Cristian Romero -- 20221578100$'
    newline db 13, 10, '$'
    prompt      DB '>$'
    errorMsg    DB '-Ov-f', 0Dh, 0Ah, '$' ; Mensaje de error
    errorMsgD   DB 'Error Div-0',0Dh, 0Ah,'$';Mensaje de error division por 0
    inputBuffer DB 6                       ; Buffer de entrada
                DB ?                      
                DB 6 DUP(0)               
    numBuffer   DB 7 DUP('$')              ; Buffer para conversion
    crlf        DB 0Dh, 0Ah, '$'
    stackBuffer DW 10 DUP(0)               ; Pila de 10 elementos
    stackPtr    DW 0                     
        

.CODE
    MAIN PROC
        MOV AX, @DATA
        MOV DS, AX
        
    ; Limpiar pantalla
    mov ax, 0003h
    int 10h
    
    ; Configurar pantalla
    mov ah, 06h
    mov al, 0
    mov bh, 07h
    mov cx, 0000h
    mov dx, 184Fh
    int 10h
    
    ; Mostrar titulos
    mov ah, 02h
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 10h
    
    mov ah, 09h
    lea dx, titulo
    int 21h
    
    mov ah, 09h
    lea dx, newline
    int 21h
    
    mov ah, 09h
    lea dx, titulo1
    int 21h
    
    mov ah, 09h
    lea dx, newline
    int 21h
    
    mov ah, 09h
    lea dx, titulo2
    int 21h 
    
    mov ah, 09h
    lea dx, newline
    int 21h

    mainLoop:
        ; Mostrar prompt
        MOV AH, 09h
        LEA DX, prompt
        INT 21h

        ; Leer entrada
        MOV AH, 0Ah
        LEA DX, inputBuffer
        INT 21h

        ; Saltar linea
        MOV AH, 09h
        LEA DX, crlf
        INT 21h

        ; Verificar si es operador
        CMP [inputBuffer + 1], 1
        JNE esNumero

        MOV AL, [inputBuffer + 2]
        CMP AL, '+'
        JE esOperador
        CMP AL, '*'
        JE esOperador
        CMP AL, '-'
        JE esOperador
        CMP AL, '/'
        JE esOperador
        CMP AL, 'f'
        JE esOperador

    esNumero:
        CALL stringToNumber
        CALL pushStack
        JMP mainLoop

    esOperador:
        CALL popStack
        MOV CX, AX          ; Segundo operando
        CALL popStack       ; Primer operando en AX

        CMP [inputBuffer + 2], '+'
        JE suma
        CMP [inputBuffer + 2], '*'
        JE multiplicacion
        CMP [inputBuffer + 2], '-'
        JE resta
        CMP [inputBuffer + 2], '/'
        JE division
        CMP [inputBuffer + 2], 'f'
        JE potencia

    suma:
        ADD AX, CX
        JO error_overflow
        JMP procesarResultado

    multiplicacion:
        IMUL CX
        JO error_overflow
        JMP procesarResultado

    resta:
        SUB AX, CX
        JO error_overflow
        JMP procesarResultado

    division:
        CMP CX, 0
        JE error_div0
        CWD
        IDIV CX
        JMP procesarResultado

    potencia:
        MOV BX, AX      ; Base
        MOV AX, 1       ; Resultado inicial
        CMP CX, 0
        JE procesarResultado
    potencia_loop:
        IMUL BX
        JO error_overflow
        LOOP potencia_loop
        JMP procesarResultado

    error_overflow:
        MOV AH, 09h
        LEA DX, errorMsg
        INT 21h
        JMP mainLoop
        
    error_div0:
        MOV AH, 09h
        LEA DX, errorMsgD
        INT 21h
        JMP mainLoop

    procesarResultado:
        CALL pushStack
        CALL numberToString

        ; Mostrar resultado
        MOV AH, 09h
        LEA DX, numBuffer
        INT 21h
        LEA DX, crlf
        INT 21h
        INT 21h

        JMP mainLoop

    MAIN ENDP

    stringToNumber PROC
        PUSH BX
        MOV CL, [inputBuffer + 1]
        MOV CH, 0
        LEA SI, [inputBuffer + 2]
        XOR AX, AX
        XOR BX, BX
        MOV BL, [SI]
        CMP BL, '-'
        JNE convertir
        INC SI
        DEC CL

    convertir:
        MOV BL, [SI]
        SUB BL, '0'
        MOV DX, AX
        SHL AX, 1
        SHL DX, 3
        ADD AX, DX
        ADD AX, BX
        INC SI
        LOOP convertir

        CMP [inputBuffer + 2], '-'
        JNE fin_stringToNumber
        NEG AX
    fin_stringToNumber:
        POP BX
        RET
    stringToNumber ENDP

    numberToString PROC
        PUSH BX
        MOV BX, 10
        XOR CX, CX
        LEA DI, [numBuffer]

        TEST AX, AX
        JNS descomponer
        MOV BYTE PTR [DI], '-'
        INC DI
        NEG AX

    descomponer:
        XOR DX, DX
        DIV BX
        ADD DL, '0'
        PUSH DX
        INC CX
        TEST AX, AX
        JNZ descomponer

    construir:
        POP DX
        MOV [DI], DL
        INC DI
        LOOP construir

        MOV BYTE PTR [DI], '$'
        POP BX
        RET
    numberToString ENDP

    pushStack PROC
        MOV BX, stackPtr
        MOV [stackBuffer + BX], AX
        ADD stackPtr, 2
        RET
    pushStack ENDP

    popStack PROC
        SUB stackPtr, 2
        MOV BX, stackPtr
        MOV AX, [stackBuffer + BX]
        RET
    popStack ENDP

END MAIN