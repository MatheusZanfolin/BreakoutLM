; #########################################################################
;
;             GENERIC.ASM is a roadmap around a standard 32 bit 
;              windows application skeleton written in MASM32.
;
; #########################################################################

;           Assembler specific instructions for 32 bit ASM code

      .386                   ; minimum processor needed for 32 bit
      .model flat, stdcall   ; FLAT memory model & STDCALL calling
      option casemap :none   ; set code to case sensitive



; #########################################################################

      ; ---------------------------------------------
      ; main include file with equates and structures
      ; ---------------------------------------------
      include \masm32\include\windows.inc

      ; -------------------------------------------------------------
      ; In MASM32, each include file created by the L2INC.EXE utility
      ; has a matching library file. If you need functions from a
      ; specific library, you use BOTH the include file and library
      ; file for that library.
      ; -------------------------------------------------------------

      include \masm32\include\gdi32.inc
      include \masm32\include\user32.inc
      include \masm32\include\kernel32.inc
      include timer.inc
      includelib \masm32\lib\gdi32.lib
      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
     ; includelib \masm32\lib\timer.lib

; #########################################################################

; ------------------------------------------------------------------------
; MACROS are a method of expanding text at assembly time. This allows the
; programmer a tidy and convenient way of using COMMON blocks of code with
; the capacity to use DIFFERENT parameters in each block.
; ------------------------------------------------------------------------

      ; 1. szText
      ; A macro to insert TEXT into the code section for convenient and 
      ; more intuitive coding of functions that use byte data as text.

      szText MACRO Name, Text:VARARG
        LOCAL lbl
          jmp lbl
            Name db Text,0
          lbl:
        ENDM

      ; 2. m2m
      ; There is no mnemonic to copy from one memory location to another,
      ; this macro saves repeated coding of this process and is easier to
      ; read in complex code.

      m2m MACRO M1, M2
        push M2
        pop  M1
      ENDM

      ; 3. return
      ; Every procedure MUST have a "ret" to return the instruction
      ; pointer EIP back to the next instruction after the call that
      ; branched to it. This macro puts a return value in eax and
      ; makes the "ret" instruction on one line. It is mainly used
      ; for clear coding in complex conditionals in large branching
      ; code such as the WndProc procedure.

      return MACRO arg
        mov eax, arg
        ret
      ENDM

; #########################################################################

; ----------------------------------------------------------------------
; Prototypes are used in conjunction with the MASM "invoke" syntax for
; checking the number and size of parameters passed to a procedure. This
; improves the reliability of code that is written where errors in
; parameters are caught and displayed at assembly time.
; ----------------------------------------------------------------------

        WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
        WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
        TopXY PROTO   :DWORD,:DWORD

; #########################################################################

; ------------------------------------------------------------------------
; Algumas constantes do programa
; ------------------------------------------------------------------------
    ; --------------------------------------------------------------------
    ; Constantes gerais
    ; --------------------------------------------------------------------

    ASCII_A equ 65 ; apertando A o jogador se move para a esquerda 
    ASCII_D equ 68 ; apertando D o jogador se move para a direita

    LARGURA_FORM equ 500
    ALTURA_FORM  equ 350
    ; --------------------------------------------------------------------
    ; Constantes dos gráficos
    ; --------------------------------------------------------------------

    ID_FUNDO   equ 1
    ID_PLAYER  equ 2
    ID_BOLINHA equ 3

    ID_AMARELO equ 4
    ID_VERDE   equ 5
    ID_AZUL    equ 6

    ; --------------------------------------------------------------------
    ; Constantes do jogador
    ; --------------------------------------------------------------------

    LARGURA_JOGADOR equ 50
    ALTURA_JOGADOR  equ 15

    X_INICIAL_JOGADOR equ 30
    Y_JOGADOR         equ 250

    VEL_JOGADOR       equ 5
    ; --------------------------------------------------------------------
    ; Constantes do cenário
    ; --------------------------------------------------------------------

    LARGURA_CENARIO equ 500
    ALTURA_CENARIO  equ 350

    LARGURA_BLOCO equ COLISAO_DIREITA / 10
    ALTURA_BLOCO  equ ALTURA_JOGADOR    

    Y_PRIMEIRO_BLOCO equ 25

    BLOCOS_POR_FILEIRA equ 10;COLISAO_DIREITA / LARGURA_BLOCO

    ; --------------------------------------------------------------------
    ; Constantes da bolinha
    ; --------------------------------------------------------------------

    LARGURA_BOLINHA equ 10
    ALTURA_BOLINHA  equ 10

    COLISAO_BAIXO   equ ALTURA_FORM  - 61
    COLISAO_DIREITA equ LARGURA_FORM - 20

    X_INICIAL_BOLINHA equ X_INICIAL_JOGADOR + (LARGURA_JOGADOR / 2) - (LARGURA_BOLINHA / 2)
    Y_INICIAL_BOLINHA equ Y_JOGADOR - ALTURA_BOLINHA - 5

    VEL_BOLINHA equ 4

; ------------------------------------------------------------------------
; This is the INITIALISED data section meaning that data declared here has
; an initial value. You can also use an UNINIALISED section if you need
; data of that type [ .data? ]. Note that they are different and occur in
; different sections.
; ------------------------------------------------------------------------

    .data?

    ; --------------------------------------------------------------------
    ; Handles para os gráficos do jogo
    ; --------------------------------------------------------------------

    hFundo   DD ?
    hPlayer  DD ?
    hBolinha DD ?

    hAmarelo DD ?
    hVerde   DD ?
    hAzul    DD ?

    .data
        szDisplayName db "Breakout de Bolso",0
        CommandLine   dd 0
        hWnd          dd 0
        hInstance     dd 0

    ; --------------------------------------------------------------------
    ; Variaveis da bolinha
    ; --------------------------------------------------------------------

    bolinhaIndoDireita DD 0
    bolinhaSubindo     DD 1

	; --------------------------------------------------------------------
    ; Variaveis do jogador
    ; --------------------------------------------------------------------

    apertouEsq db 0
    apertouDir db 0

    posicaoBolinha POINT<>
    posicaoJogador POINT<>        

    ; --------------------------------------------------------------------
    ; Variaveis dos blocos
    ; --------------------------------------------------------------------

    amarelos byte BLOCOS_POR_FILEIRA dup(1)
    verdes   byte BLOCOS_POR_FILEIRA dup(1)
    azuis    byte BLOCOS_POR_FILEIRA dup(1)

; #########################################################################

; ------------------------------------------------------------------------
; This is the start of the code section where executable code begins. This
; section ending with the ExitProcess() API function call is the only
; GLOBAL section of code and it provides access to the WinMain function
; with the necessary parameters, the instance handle and the command line
; address.
; ------------------------------------------------------------------------

    .code

; -----------------------------------------------------------------------
; The label "start:" is the address of the start of the code section and
; it has a matching "end start" at the end of the file. All procedures in
; this module must be written between these two.
; -----------------------------------------------------------------------

start:
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov hInstance, eax

    invoke GetCommandLine        ; provides the command line address
    mov CommandLine, eax

    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
    
    invoke ExitProcess,eax       ; cleanup & return to operating system

; #########################################################################

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

        ;====================
        ; Put LOCALs on stack
        ;====================

        LOCAL wc   :WNDCLASSEX
        LOCAL msg  :MSG

        LOCAL Wwd  :DWORD
        LOCAL Wht  :DWORD
        LOCAL Wtx  :DWORD
        LOCAL Wty  :DWORD

        szText szClassName,"Generic_Class"

        ;==================================================
        ; Fill WNDCLASSEX structure with required variables
        ;==================================================

        mov Wwd, LARGURA_FORM
        mov Wht, ALTURA_FORM
        mov wc.cbSize,         sizeof WNDCLASSEX
        mov wc.style,          CS_HREDRAW or CS_VREDRAW \
                               or CS_BYTEALIGNWINDOW
        mov wc.lpfnWndProc,    offset WndProc      ; address of WndProc
        mov wc.cbClsExtra,     NULL
        mov wc.cbWndExtra,     NULL
        m2m wc.hInstance,      hInst               ; instance handle
        mov wc.hbrBackground,  COLOR_BTNFACE+1     ; system color
        mov wc.lpszMenuName,   NULL
        mov wc.lpszClassName,  offset szClassName  ; window class name
          invoke LoadIcon,hInst,500    ; icon ID   ; resource icon
        mov wc.hIcon,          eax
          invoke LoadCursor,NULL,IDC_ARROW         ; system cursor
        mov wc.hCursor,        eax
        mov wc.hIconSm,        0

        invoke RegisterClassEx, ADDR wc     ; register the window class

        ;================================
        ; Centre window at following size
        ;================================        

        invoke GetSystemMetrics,SM_CXSCREEN ; get screen width in pixels
        invoke TopXY,Wwd,eax
        mov Wtx, eax

        invoke GetSystemMetrics,SM_CYSCREEN ; get screen height in pixels
        invoke TopXY,Wht,eax
        mov Wty, eax

        ; ==================================
        ; Create the main application window
        ; ==================================
        invoke CreateWindowEx,WS_EX_OVERLAPPEDWINDOW,
                              ADDR szClassName,
                              ADDR szDisplayName,
                              WS_OVERLAPPEDWINDOW,
                              Wtx,Wty,Wwd,Wht,
                              NULL,NULL,
                              hInst,NULL

        mov   hWnd,eax  ; copy return value into handle DWORD

        invoke LoadMenu,hInst,600                 ; load resource menu
        invoke SetMenu,hWnd,eax                   ; set it to main window

        invoke ShowWindow,hWnd,SW_SHOWNORMAL      ; display the window
        invoke UpdateWindow,hWnd                  ; update the display

      ;===================================
      ; Loop until PostQuitMessage is sent
      ;===================================

    StartLoop:
      invoke GetMessage,ADDR msg,NULL,0,0         ; get each message
      cmp eax, 0                                  ; exit if GetMessage()
      je ExitLoop                                 ; returns zero
      invoke TranslateMessage, ADDR msg           ; translate it
      invoke DispatchMessage,  ADDR msg           ; send it to message proc
      jmp StartLoop
    ExitLoop:

      return msg.wParam

WinMain endp

; #########################################################################

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

; -------------------------------------------------------------------------
; Variaveis de processamento dos gráficos
; -------------------------------------------------------------------------             

    LOCAL hDC    :DWORD
    LOCAL hMemDC :DWORD
    LOCAL Ps     :DWORD
    LOCAL rect   :RECT

    LOCAL qtosBlocos :byte
    LOCAL xBloco     :DWORD
    LOCAL yBloco     :DWORD

; -------------------------------------------------------------------------
; Variaveis de verificação de colisões
; -------------------------------------------------------------------------             

	LOCAL yBlocoAtual :DWORD
	LOCAL xBlocoAtual :DWORD

	LOCAL indice :DWORD

	LOCAL jogoAcabou :DWORD

; -------------------------------------------------------------------------
; Message are sent by the operating system to an application through the
; WndProc proc. Each message can have additional values associated with it
; in the two parameters, wParam & lParam. The range of additional data that
; can be passed to an application is determined by the message.
; -------------------------------------------------------------------------

    .if uMsg == WM_COMMAND
    ;----------------------------------------------------------------------
    ; The WM_COMMAND message is sent by menus, buttons and toolbar buttons.
    ; Processing the wParam parameter of it is the method of obtaining the
    ; control's ID number so that the code for each operation can be
    ; processed. NOTE that the ID number is in the LOWORD of the wParam
    ; passed with the WM_COMMAND message. There may be some instances where
    ; an application needs to seperate the high and low words of wParam.
    ; ---------------------------------------------------------------------
    
    ;======== menu commands ========

        .if wParam == 1000
            invoke SendMessage,hWin,WM_SYSCOMMAND,SC_CLOSE,NULL
        .elseif wParam == 1900
            szText TheMsg,"Assembler, Pure & Simple"
            invoke MessageBox,hWin,ADDR TheMsg,ADDR szDisplayName,MB_OK
        .endif

    ;====== end menu commands ======

    .elseif uMsg == WM_CREATE
    ; --------------------------------------------------------------------
    ; This message is sent to WndProc during the CreateWindowEx function
    ; call and is processed before it returns. This is used as a position
    ; to start other items such as controls. IMPORTANT, the handle for the
    ; CreateWindowEx call in the WinMain does not yet exist so the HANDLE
    ; passed to the WndProc [ hWin ] must be used here for any controls
    ; or child windows.
    ; --------------------------------------------------------------------

    ; --------------------------------------------------------------------
    ; Inicialização das variáveis de posicionamento dos objetos móveis
    ; --------------------------------------------------------------------

        mov posicaoJogador.x, X_INICIAL_JOGADOR
        mov posicaoJogador.y, Y_JOGADOR

        mov posicaoBolinha.x, X_INICIAL_BOLINHA
        mov posicaoBolinha.y, Y_INICIAL_BOLINHA

        invoke SetTimer, hWin, 222, 33, NULL ; Colocar timer para 42ms para 24 FPS

  	; --------------------------------------------------------------------
    ; Os quatro proximos eventos detectam a entrada do jogador
    ; --------------------------------------------------------------------

	.elseif uMsg == WM_LBUTTONDOWN
		mov apertouEsq, 1

    .elseif uMsg == WM_LBUTTONUP
    	mov apertouEsq, 0
    
    .elseif uMsg == WM_RBUTTONDOWN
    	mov apertouDir, 1

    .elseif uMsg == WM_RBUTTONUP    
    	mov apertouDir, 0

    .elseif uMsg == WM_PAINT
    ; --------------------------------------------------------------------
    ; Aqui se realizará o processamento dos gráficos do jogo
    ; --------------------------------------------------------------------

        ; ----------------------------------------------------------------
        ; Preparando os handles para as operações
        ; ----------------------------------------------------------------

        invoke BeginPaint, hWin, ADDR Ps
        mov hDC, eax

        invoke CreateCompatibleDC, hDC
        mov hMemDC, eax

        ; ----------------------------------------------------------------
        ; Desenhando "cenário"
        ; ----------------------------------------------------------------

        invoke SelectObject, hMemDC, hFundo

        invoke BitBlt, hDC, 0, 0, COLISAO_DIREITA, COLISAO_BAIXO, hMemDC, 0, 0, SRCCOPY

        ; ----------------------------------------------------------------
        ; Desenhando jogador no cenárioaddad
        ; ----------------------------------------------------------------

        invoke SelectObject, hMemDC, hPlayer

        invoke BitBlt, hDC, posicaoJogador.x, Y_JOGADOR, LARGURA_JOGADOR, ALTURA_JOGADOR, hMemDC, 0, 0, SRCCOPY

        ; ----------------------------------------------------------------
        ; Desenhando a bolinha
        ; ----------------------------------------------------------------

        invoke SelectObject, hMemDC, hBolinha

        invoke BitBlt, hDC, posicaoBolinha.x, posicaoBolinha.y, LARGURA_BOLINHA, ALTURA_BOLINHA, hMemDC, 0, 0, SRCCOPY        

        ; ----------------------------------------------------------------
        ; Desenhando os blocos da barreira
        ; ----------------------------------------------------------------

amarelo:
        mov qtosBlocos, 1
        mov xBloco    , 0
        mov yBloco    , Y_PRIMEIRO_BLOCO

        invoke SelectObject, hMemDC, hAmarelo

repete_am:
		lea ecx, offset amarelos
		
		mov edx, 0
		mov dl , qtosBlocos				
		dec dl		

		add ecx, edx ; ECX contem ponteiro para o bloco atual

		mov dl, byte ptr [ecx]

		.if dl == 1
        	invoke BitBlt, hDC, xBloco, yBloco, LARGURA_BLOCO, ALTURA_BLOCO, hMemDC, 0, 0, SRCCOPY
        .endif

avancar_am:

        cmp qtosBlocos, BLOCOS_POR_FILEIRA
        jge verde

        add xBloco, LARGURA_BLOCO
        inc qtosBlocos
        jmp repete_am

verde:
        mov qtosBlocos, 1
        mov xBloco    , 0
        add yBloco    , ALTURA_BLOCO

        invoke SelectObject, hMemDC, hVerde

repete_ve:
        lea ecx, offset verdes
		
		mov edx, 0
		mov dl , qtosBlocos				
		dec dl		

		add ecx, edx ; ECX contem ponteiro para o bloco atual

		mov dl, byte ptr [ecx]

		.if dl == 1
        	invoke BitBlt, hDC, xBloco, yBloco, LARGURA_BLOCO, ALTURA_BLOCO, hMemDC, 0, 0, SRCCOPY
        .endif

        cmp qtosBlocos, BLOCOS_POR_FILEIRA
        jge azul

        add xBloco, LARGURA_BLOCO
        inc qtosBlocos
        jmp repete_ve

azul:
        mov qtosBlocos, 1
        mov xBloco    , 0
        add yBloco    , ALTURA_BLOCO

        invoke SelectObject, hMemDC, hAzul

repete_az:
        lea ecx, offset azuis
		
		mov edx, 0
		mov dl , qtosBlocos				
		dec dl		

		add ecx, edx ; ECX contem ponteiro para o bloco atual

		mov dl, byte ptr [ecx]

		.if dl == 1
        	invoke BitBlt, hDC, xBloco, yBloco, LARGURA_BLOCO, ALTURA_BLOCO, hMemDC, 0, 0, SRCCOPY
        .endif

        cmp qtosBlocos, BLOCOS_POR_FILEIRA
        jge fim

        add xBloco, LARGURA_BLOCO
        inc qtosBlocos
        jmp repete_az

fim:
        invoke EndPaint, hWin, ADDR Ps ; Encerrando a "pintura" do formulário

    ; --------------------------------------------------------------------
    ; O método de timer controla todo o processamento do jogo, isto é
    ; a manipulação de cada uma das variáveis
    ; --------------------------------------------------------------------

    .elseif uMsg == WM_TIMER
    	; --------------------------------------------------------------------
	    ; Movimento do jogador
	    ; --------------------------------------------------------------------
    	.if apertouEsq == 1
    		.if apertouDir != 1
    			.if posicaoJogador.x > 0
    				sub posicaoJogador.x, VEL_JOGADOR
    			.endif
    		.endif
    	.endif

		.if apertouDir == 1
    		.if apertouEsq != 1
    			mov edx, posicaoJogador.x
    			add edx, LARGURA_JOGADOR

    			.if edx < COLISAO_DIREITA
    				add posicaoJogador.x, VEL_JOGADOR
    			.endif
    		.endif
    	.endif    	

    	; --------------------------------------------------------------------
	    ; Movimento vertical ba bolinha
	    ; --------------------------------------------------------------------
		.if bolinhaSubindo == 0
			mov edx, posicaoBolinha.y
			add edx, ALTURA_BOLINHA

        	.if edx >= COLISAO_BAIXO
        		invoke SendMessage, hWin, WM_SYSCOMMAND, SC_CLOSE, NULL        		
        	.elseif edx >= posicaoJogador.y
        		mov edx, posicaoBolinha.x
        		mov ecx, posicaoJogador.x
        		add ecx, LARGURA_JOGADOR

        		.if edx < ecx
        			add edx, LARGURA_BOLINHA
        			sub ecx, LARGURA_JOGADOR

        			.if edx > ecx
        				mov bolinhaSubindo, 1

        				sub posicaoBolinha.y, VEL_BOLINHA
        			.else
        				add posicaoBolinha.y, VEL_BOLINHA
        			.endif
        		.else
        			add posicaoBolinha.y, VEL_BOLINHA
        		.endif
        	.else
        		add posicaoBolinha.y, VEL_BOLINHA
        	.endif
        .elseif bolinhaSubindo == 1
        	mov edx, posicaoBolinha.y

        	.if edx <= 3
        		mov bolinhaSubindo, 0

        		add posicaoBolinha.y, VEL_BOLINHA
        	.else
        		sub posicaoBolinha.y, VEL_BOLINHA
        	.endif
        .endif

        ;================================================================
        ;======== Inicio da verificação da colisão bolinha-bloco ========
        ;================================================================

		mov yBlocoAtual, Y_PRIMEIRO_BLOCO
		
verifica_colisao:
		mov ecx, yBlocoAtual
		mov edx, posicaoBolinha.y

		add edx, ALTURA_BOLINHA

		.if edx > ecx
			sub edx, ALTURA_BOLINHA
			add ecx, ALTURA_BLOCO

			.if edx < ecx
				mov ecx, xBlocoAtual
				mov edx, posicaoBolinha.x				

				add edx, LARGURA_BOLINHA

				.if edx > ecx
					sub edx, LARGURA_BOLINHA
					add ecx, LARGURA_BLOCO

					.if edx < ecx
						mov edx, yBlocoAtual

						mov ecx, Y_PRIMEIRO_BLOCO

						.if edx == ecx
							mov eax, xBlocoAtual
							mov ebx, LARGURA_BLOCO

							mov edx, 0

							div ebx

							mov indice, eax

							mov eax, offset amarelos
							add eax, indice			

							mov bl, byte ptr [eax]

							.if bl == 0
								jmp avanca_bloco
							.endif				

							mov ebx, 0							

							mov byte ptr [eax], bl
						.else
							add ecx, ALTURA_BLOCO

							.if edx == ecx
								mov eax, xBlocoAtual
								mov ebx, LARGURA_BLOCO

								mov edx, 0

								div ebx

								mov indice, eax

								mov eax, offset verdes
								add eax, indice

								mov bl, byte ptr [eax]

								.if bl == 0
									jmp avanca_bloco
								.endif

								mov ebx, 0

								mov byte ptr [eax], bl
							.else
								add ecx, ALTURA_BLOCO

								.if edx == ecx
									mov eax, xBlocoAtual
									mov ebx, LARGURA_BLOCO

									mov edx, 0

									div ebx

									mov indice, eax

									mov eax, offset azuis
									add eax, indice

									mov bl, byte ptr [eax]

									.if bl == 0
										jmp avanca_bloco
									.endif

									mov ebx, 0									

									mov byte ptr [eax], bl
								.endif
							.endif													
						.endif

						mov edx, bolinhaSubindo

						.if edx == 1
							mov edx, 0
						.else
							mov edx, 1
						.endif

						mov bolinhaSubindo, edx

						jmp fim_colisao
					.endif
				.endif
			.endif
		.endif

avanca_bloco:
		add xBlocoAtual, LARGURA_BLOCO

		mov edx, xBlocoAtual

		.if edx >= COLISAO_DIREITA
			add yBlocoAtual, ALTURA_BLOCO

			mov edx, Y_PRIMEIRO_BLOCO
			add edx, ALTURA_BLOCO
			add edx, ALTURA_BLOCO
			add edx, ALTURA_BLOCO

			mov ecx, yBlocoAtual

			.if yBlocoAtual >= edx
				jmp fim_colisao
			.else
				mov xBlocoAtual, 0
			.endif
		.endif

		jmp verifica_colisao

fim_colisao:

		;=================================================================
        ;========== Fim da verificação da colisão bolinha-bloco ==========
        ;=================================================================


        ; --------------------------------------------------------------------
	    ; Movimento horizontal ba bolinha
	    ; --------------------------------------------------------------------
        .if bolinhaIndoDireita == 0        	
        	mov edx, posicaoBolinha.x

        	.if edx <= 2
        		mov bolinhaIndoDireita, 1

        		add posicaoBolinha.x, VEL_BOLINHA
        	.else
				sub posicaoBolinha.x, VEL_BOLINHA
			.endif
        .elseif bolinhaIndoDireita == 1
        	mov edx, posicaoBolinha.x
        	add edx, LARGURA_BOLINHA

        	.if edx >= COLISAO_DIREITA
        		mov bolinhaIndoDireita, 0

        		sub posicaoBolinha.x, VEL_BOLINHA
        	.else
        		add posicaoBolinha.x, VEL_BOLINHA
        	.endif
        .endif

        ; ----------------------------------------------------------------------
    ; Verificando se o jogador destruiu todos os blocos
    ; ----------------------------------------------------------------------
    mov jogoAcabou, 1
	mov indice, 0

inicioLoop:
    
	cmp indice, BLOCOS_POR_FILEIRA
	je parabens

	lea eax, offset amarelos
	add eax, indice
	lea ebx, offset verdes
	add ebx, indice
	lea ecx, offset azuis
	add ecx, indice
   	mov dl, byte ptr[eax]
	.if dl==1 
     	jmp continuandoJogo;
    .endif
    
    mov dh, byte ptr[ebx]
    .if dh==1 
    	jmp continuandoJogo;
    .endif
    
    mov cl, byte ptr[ecx]
    
    .if cl==1
    	jmp continuandoJogo;	
    .endif

	add indice, 1
	jmp inicioLoop

parabens:
	.if jogoAcabou ==1
    	invoke SendMessage,hWin,WM_SYSCOMMAND,SC_CLOSE,NULL
   .endif

continuandoJogo:
		
mov jogoAcabou, 0

        invoke LoadBitmap, hInstance, ID_FUNDO   ; Lê os gráficos para o "cenário"
        mov hFundo, eax                          ; Coloca um handle na memória

        invoke LoadBitmap, hInstance, ID_PLAYER  ; Lê os gráficos para o jogador         
        mov hPlayer, eax                         ; Coloca um handle na memória        

        invoke LoadBitmap, hInstance, ID_BOLINHA ; Lê os gráficos para a bolinha
        mov hBolinha, eax                        ; Coloca um handle na memória

        invoke LoadBitmap, hInstance, ID_AMARELO ; Lê os gráficos para o bloco amarelo
        mov hAmarelo, eax                        ; Coloca um handle na memória

        invoke LoadBitmap, hInstance, ID_VERDE   ; Lê os gráficos para o bloco verde
        mov hVerde, eax                          ; Coloca um handle na memória

        invoke LoadBitmap, hInstance, ID_AZUL    ; Lê os gráficos para o bloco azul
        mov hAzul, eax                           ; Coloca um handle na memória

        invoke InvalidateRect, hWnd, NULL, 0

    .elseif uMsg == WM_CHAR
      .if wParam == ASCII_A

      .elseif wParam ==  ASCII_D

	  .endif
	  
    .elseif uMsg == WM_CLOSE
    ; -------------------------------------------------------------------
    ; This is the place where various requirements are performed before
    ; the application exits to the operating system such as deleting
    ; resources and testing if files have been saved. You have the option
    ; of returning ZERO if you don't wish the application to close which
    ; exits the WndProc procedure without passing this message to the
    ; default window processing done by the operating system.
    ; -------------------------------------------------------------------
      invoke KillTimer, hWin, 222
      
    .elseif uMsg == WM_DESTROY
    ; ----------------------------------------------------------------
    ; This message MUST be processed to cleanly exit the application.
    ; Calling the PostQuitMessage() function makes the GetMessage()
    ; function in the WinMain() main loop return ZERO which exits the
    ; application correctly. If this message is not processed properly
    ; the window disappears but the code is left in memory.
    ; ----------------------------------------------------------------
        ; ------------------------------------------------------------
        ; Limpando os handles da memória
        ; ------------------------------------------------------------
        invoke DeleteObject, hPlayer 
        invoke DeleteObject, hFundo

        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam
    ; --------------------------------------------------------------------
    ; Default window processing is done by the operating system for any
    ; message that is not processed by the application in the WndProc
    ; procedure. If the application requires other than default processing
    ; it executes the code when the message is trapped and returns ZERO
    ; to exit the WndProc procedure before the default window processing
    ; occurs with the call to DefWindowProc().
    ; --------------------------------------------------------------------

    ret

WndProc endp

; ########################################################################

TopXY proc wDim:DWORD, sDim:DWORD

    ; ----------------------------------------------------
    ; This procedure calculates the top X & Y co-ordinates
    ; for the CreateWindowEx call in the WinMain procedure
    ; ----------------------------------------------------

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY endp

; ########################################################################

end start
