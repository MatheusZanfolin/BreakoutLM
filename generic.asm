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

    LARGURA_BLOCO equ LARGURA_JOGADOR
    ALTURA_BLOCO  equ ALTURA_JOGADOR    

    Y_PRIMEIRO_BLOCO equ 25

    BLOCOS_POR_FILEIRA equ LARGURA_CENARIO / LARGURA_BLOCO

    ; --------------------------------------------------------------------
    ; Constantes da bolinha
    ; --------------------------------------------------------------------

    LARGURA_BOLINHA equ 10
    ALTURA_BOLINHA  equ 10

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

    posicaoBolinha POINT<>
    posicaoJogador POINT<>

    ; Handles para os gráficos do jogo

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
    bolinhaSubindo     DD 0

	; --------------------------------------------------------------------
    ; Variaveis do jogador
    ; --------------------------------------------------------------------

    apertouEsq db 0
    apertouDir db 0

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

        mov Wwd, 500
        mov Wht, 350

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

    LOCAL hDC    :DWORD
    LOCAL hMemDC :DWORD
    LOCAL Ps     :DWORD
    LOCAL rect   :RECT

    LOCAL qtosBlocos :DWORD
    LOCAL xBloco     :DWORD
    LOCAL yBloco     :DWORD

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

        mov posicaoJogador.x, X_INICIAL_JOGADOR
        mov posicaoJogador.y, Y_JOGADOR

        mov posicaoBolinha.x, X_INICIAL_BOLINHA
        mov posicaoBolinha.y, Y_INICIAL_BOLINHA

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

        invoke SetTimer, hWin, 222, 1000, NULL

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

        invoke BitBlt, hDC, 0, 0, LARGURA_CENARIO, ALTURA_CENARIO, hMemDC, 0, 0, SRCCOPY

        ; ----------------------------------------------------------------
        ; Desenhando jogador no cenárioaddad
        ; ----------------------------------------------------------------

        invoke SelectObject, hMemDC, hPlayer

        invoke BitBlt, hDC, posicaoJogador.x, Y_JOGADOR, LARGURA_JOGADOR, ALTURA_JOGADOR, hMemDC, 0, 0, SRCCOPY

        ; ----------------------------------------------------------------
        ; Desenhando a bolinha
        ; ----------------------------------------------------------------

        invoke SelectObject, hMemDC, hBolinha

        invoke BitBlt, hDC, X_INICIAL_BOLINHA, Y_INICIAL_BOLINHA, LARGURA_BOLINHA, ALTURA_BOLINHA, hMemDC, 0, 0, SRCCOPY

        ; ----------------------------------------------------------------
        ; Desenhando os blocos da barreira
        ; ----------------------------------------------------------------

amarelo:
        mov qtosBlocos, 1
        mov xBloco    , 0
        mov yBloco    , Y_PRIMEIRO_BLOCO

        invoke SelectObject, hMemDC, hAmarelo

repete_am:
        invoke BitBlt, hDC, xBloco, yBloco, LARGURA_BLOCO, ALTURA_BLOCO, hMemDC, 0, 0, SRCCOPY

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
        invoke BitBlt, hDC, xBloco, yBloco, LARGURA_BLOCO, ALTURA_BLOCO, hMemDC, 0, 0, SRCCOPY

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
        invoke BitBlt, hDC, xBloco, yBloco, LARGURA_BLOCO, ALTURA_BLOCO, hMemDC, 0, 0, SRCCOPY

        cmp qtosBlocos, BLOCOS_POR_FILEIRA
        jge fim

        add xBloco, LARGURA_BLOCO
        inc qtosBlocos
        jmp repete_az

fim:
        invoke EndPaint, hWin, ADDR Ps ; Encerrando a "pintura" do formulário

    .elseif uMsg == WM_TIMER
        .if bolinhaSubindo == 0

        .else

        .endif

        .if bolinhaIndoDireita == 0

        .else

        .endif

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
