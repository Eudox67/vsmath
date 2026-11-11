// ###################################################################
// #### This file is part of the vsmath project - a 32-bit, single-
// #### precision (mode objfpc) fork of mrMath:
// ####   https://github.com/mikerabat/mrmath
// ####
// #### Derived from mrMath. Copyright (c) 2018, Michael R. All rights reserved.
// #### Licensed under the Apache License, Version 2.0 - see LICENSE.
// ####
// #### Modifications Copyright 2026 Eudox67.
// #### Ported from double/x64 to 32-bit single precision; converted
// #### to {$mode objfpc}. See NOTICE for details.
// ####
// #### vsmath is an independent fork and is not affiliated with,
// #### endorsed by, or supported by the mrMath project or its author.
// ###################################################################

unit AVXMatrixCumSumDiffOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

procedure AVXMatrixCumulativeSumRow(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure AVXMatrixCumulativeSumColumnUnaligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure AVXMatrixCumulativeSumColumnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure AVXMatrixDifferentiateRow(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure AVXMatrixDifferentiateColumnUnaligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure AVXMatrixDifferentiateColumnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

// ##################################################
// #### Cumulative sum
// ##################################################

procedure AVXMatrixCumulativeSumRow(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var iRSI : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
// rcx: dest, rdx: destlinewidth; r8: src; r9 : srclinewidth
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width, r8;
   mov height, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // prolog - maintain stack
   mov iRSI, rsi;

   // if (width <= 0) or (height <= 0) then exit;
   mov r10, width;
   cmp r10, 0;
   jle @@exitproc;
   mov rsi, height;
   cmp rsi, 0;
   jle @@exitproc;

   // iter := -width*sizeof(Single)
   imul r10, -4;

   // prepare counters
   sub rcx, r10;
   sub r8, r10;
   @@foryloop:
      mov rax, r10;

      vxorps xmm0, xmm0, xmm0; 
      @@forxloop:
         vmovss xmm1, [r8 + rax]; 
         vaddss xmm0, xmm0, xmm1; 
         vmovss [rcx + rax], xmm0; 
      add rax, 4;
      jnz @@forxloop;

      add rcx, rdx;
      add r8, r9;
   dec rsi;
   jnz @@foryloop;
   @@exitProc:

   // epilog - stack cleanup
   mov rsi, iRSI;
   vzeroupper; 
end;

procedure AVXMatrixCumulativeSumColumnUnaligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var iRDI, iRSI : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
// rcx: dest, rdx: destlinewidth; r8: src; r9 : srclinewidth
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width, r8;
   mov height, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // prolog - maintain stack
   mov iRDI, rdi;
   mov iRSI, rsi;

   // if (width <= 1) or (height <= 0) then exit;
   mov r11, height;
   cmp r11, 0;

   jle @@exitproc;
   mov r10, width;
   sub r10, 4;
   jl @@lastColumns;

   @@forxloop:
       mov rax, r11;
       vxorps ymm0, ymm0, ymm0; 
       xor rdi, rdi;
       xor rsi, rsi;

       // 4 values at once
       @@foryloop:
           vmovups ymm1, [r8 + rdi]; 
           vaddps ymm0, ymm0, ymm1; 
           vmovups [rcx + rsi], ymm0; 

           add rdi, r9;
           add rsi, rdx;
       dec rax;
       jnz @@foryloop;

       add r8, 32;
       add rcx, 32;
   sub r10, 4;
   jge @@forxloop;

   @@lastColumns:
   add r10, 4;
   jz @@exitProc;

   @@forxloopshort:
       mov rax, r11;
       vxorps xmm0, xmm0, xmm0; 
       xor rdi, rdi;
       xor rsi, rsi;

       // 4 values at once
       @@foryloopshort:
           vmovss xmm1, [r8 + rdi]; 
           vaddss xmm0, xmm0, xmm1; 
           vmovss [rcx + rsi], xmm0; 

           add rdi, r9;
           add rsi, rdx;
       dec rax;
       jnz @@foryloopshort;

       add r8, 4;
       add rcx, 4;
   sub r10, 1;
   jg @@forxloopshort;

   @@exitProc:

   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
   vzeroupper; 
end;

procedure AVXMatrixCumulativeSumColumnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var iRDI, iRSI : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
// rcx: dest, rdx: destlinewidth; r8: src; r9 : srclinewidth
asm
{$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width, r8;
   mov height, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // prolog - maintain stack
   mov iRDI, rdi;
   mov iRSI, rsi;

   // if (width <= 1) or (height <= 0) then exit;
   mov r11, height;
   cmp r11, 0;

   jle @@exitproc;
   mov r10, width;
   sub r10, 4;
   jl @@lastColumns;

   @@forxloop:
       mov rax, r11;
       vxorps ymm0, ymm0, ymm0; 
       xor rdi, rdi;
       xor rsi, rsi;

       // 4 values at once
       @@foryloop:
           vmovaps ymm1, [r8 + rdi]; 
           vaddps ymm0, ymm0, ymm1; 
           vmovaps [rcx + rsi], ymm0; 

           add rdi, r9;
           add rsi, rdx;
       dec rax;
       jnz @@foryloop;

       add r8, 32;
       add rcx, 32;
   sub r10, 4;
   jge @@forxloop;

   @@lastColumns:
   add r10, 4;
   jz @@exitProc;

   @@forxloopshort:
       mov rax, r11;
       vxorps xmm0, xmm0, xmm0; 
       xor rdi, rdi;
       xor rsi, rsi;

       // 4 values at once
       @@foryloopshort:
           vmovss xmm1, [r8 + rdi]; 
           vaddss xmm0, xmm0, xmm1; 
           vmovss [rcx + rsi], xmm0; 

           add rdi, r9;
           add rsi, rdx;
       dec rax;
       jnz @@foryloopshort;

       add r8, 4;
       add rcx, 4;
   sub r10, 1;
   jg @@forxloopshort;

   @@exitProc:
   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
   vzeroupper; 
end;

// ###############################################
// #### Differentiate
// ###############################################

procedure AVXMatrixDifferentiateRow(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
    {$ENDIF}
// rcx: dest, rdx: destlinewidth; r8: src; r9 : srclinewidth
asm
{$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width, r8;
   mov height, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
{$ENDIF}

   // prolog - maintain stack

   // if (width <= 1) or (height <= 0) then exit;
   mov r10, width;
   cmp r10, 1;
   jle @@exitproc;
   mov r11, height;
   cmp r11, 0;
   jle @@exitproc;
   // iter := -width*sizeof(Single)
   imul r10, -4;
   // prepare counters
   sub rcx, r10;
   sub r8, r10;
   add r10, 4;
   @@foryloop:
       mov rax, r10;
       vmovss xmm1, [r8 + rax - 8]; 
       @@forxloop:
           vmovss xmm0, [r8 + rax]; 
           vsubss xmm2, xmm0, xmm1; 
           vmovss [rcx + rax - 8], xmm2; 
           vmovaps xmm1, xmm0; 
       add rax, 4;
       jnz @@forxloop;

       add rcx, rdx;
       add r8, r9;
   dec r11;
   jnz @@foryloop;

   @@exitProc:

   // epilog - stack cleanup
   vzeroupper; 
end;

procedure AVXMatrixDifferentiateColumnUnaligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var iRDI, iRSI : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
// rcx: dest, rdx: destlinewidth; r8: src; r9 : srclinewidth
asm
{$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width, r8;
   mov height, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
{$ENDIF}
   // prolog - maintain stack
   mov iRDI, rdi;
   mov iRSI, rsi;

   // if (width <= 1) or (height <= 0) then exit;
   mov r11, height;
   cmp r11, 1;
   jle @@exitproc;

   mov r10, width;
   cmp r10, 1;
   jle @@exitproc;

   dec r11;
   sub r10, 4;
   jl @@forxloopend;

   @@forxloop:
       mov rax, r11;
       vxorps ymm0, ymm0, ymm0; 
       mov rdi, r9;
       xor rsi, rsi;

       vmovups ymm0, [r8]; 

       // 4 values at once
       @@foryloop:
           vmovups ymm1, [r8 + rdi]; 
           vsubps ymm2, ymm1, ymm0; 
           vmovups [rcx + rsi], ymm2; 

           vmovaps ymm0, ymm1; 

           add rdi, r9;
           add rsi, rdx;
       dec rax;
       jnz @@foryloop;

       add r8, 32;
       add rcx, 32;
   sub r10, 4;
   jge @@forxloop;

   @@forxloopend:
   add r10, 4;
   jz @@exitProc;

   // #####################################
   // #### last < 4 columns
   @@forxloopshort:
      mov rax, r11;
      vxorps xmm0, xmm0, xmm0; 
      mov rdi, r9;
      xor rsi, rsi;

      vmovss xmm0, [r8]; 

      // one column value:
      @@foryloopshort:
          vmovss xmm1, [r8 + rdi]; 
          vsubss xmm2, xmm1, xmm0; 
          vmovss [rcx + rsi], xmm2; 

          vmovss xmm0, xmm0, xmm1; 

          add rdi, r9;
          add rsi, rdx;
      dec rax;
      jnz @@foryloopshort;

      add r8, 4;
      add rcx, 4;

   dec r10;
   jnz @@forxloopshort;

   @@exitProc:

   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
end;

procedure AVXMatrixDifferentiateColumnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var iRDI, iRSI : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
// rcx: dest, rdx: destlinewidth; r8: src; r9 : srclinewidth
asm
{$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width, r8;
   mov height, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
{$ENDIF}
   // prolog - maintain stack
   mov iRDI, rdi;
   mov iRSI, rsi;

   // if (width <= 1) or (height <= 0) then exit;
   mov r11, height;
   cmp r11, 1;
   jle @@exitproc;

   mov r10, width;
   cmp r10, 1;
   jle @@exitproc;

   dec r11;
   sub r10, 4;
   jl @@forxloopend;

   @@forxloop:
       mov rax, r11;
       vxorps ymm0, ymm0, ymm0; 
       mov rdi, r9;
       xor rsi, rsi;

       vmovups ymm0, [r8]; 

       // 4 values at once
       @@foryloop:
           vmovaps ymm1, [r8 + rdi]; 
           vsubps ymm2, ymm1, ymm0; 
           vmovaps [rcx + rsi], ymm2; 

           vmovaps ymm0, ymm1; 

           add rdi, r9;
           add rsi, rdx;
       dec rax;
       jnz @@foryloop;

       add r8, 32;
       add rcx, 32;
   sub r10, 4;
   jge @@forxloop;

   @@forxloopend:
   add r10, 4;
   jz @@exitProc;

   // #####################################
   // #### last < 4 columns
   @@forxloopshort:
      mov rax, r11;
      vxorps xmm0, xmm0, xmm0; 
      mov rdi, r9;
      xor rsi, rsi;

      vmovss xmm0, [r8]; 

      // one column value:
      @@foryloopshort:
          vmovss xmm1, [r8 + rdi]; 
          vsubss xmm2, xmm1, xmm0; 
          vmovss [rcx + rsi], xmm2; 

          vmovss xmm0, xmm0, xmm1; 

          add rdi, r9;
          add rsi, rdx;
      dec rax;
      jnz @@foryloopshort;

      add r8, 4;
      add rcx, 4;

   dec r10;
   jnz @@forxloopshort;

   @@exitProc:

   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
end;


{$ENDIF}

end.
