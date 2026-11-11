// ###################################################################
// #### This file is part of the vsmath project - a 32-bit, single-
// #### precision (mode objfpc) fork of mrMath:
// ####   https://github.com/mikerabat/mrmath
// ####
// #### Derived from mrMath. Copyright (c) 2011, Michael R. All rights reserved.
// #### Licensed under the Apache License, Version 2.0 - see LICENSE.
// ####
// #### Modifications Copyright 2026 Eudox67.
// #### Ported from double/x64 to 32-bit single precision; converted
// #### to {$mode objfpc}. See NOTICE for details.
// ####
// #### vsmath is an independent fork and is not affiliated with,
// #### endorsed by, or supported by the mrMath project or its author.
// ###################################################################

unit ASMMatrixCumSumDiffOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

procedure ASMMatrixCumulativeSumRow(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure ASMMatrixCumulativeSumColumnEvenWUnaligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixCumulativeSumColumnOddWUnaligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixCumulativeSumColumnEvenWAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixCumulativeSumColumnOddWAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure ASMMatrixDifferentiateRow(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure ASMMatrixDifferentiateColumnEvenWUnaligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixDifferentiateColumnOddWUnaligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixDifferentiateColumnEvenWAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixDifferentiateColumnOddWAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

// ##################################################
// #### Cumulative sum
// ##################################################

procedure ASMMatrixCumulativeSumRow(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var iRBX, iRDI, iRSI : NativeInt;
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
   mov iRBX, rbx;
   mov iRDI, rdi;
   mov iRSI, rsi;

   // if (width <= 0) or (height <= 0) then exit;
   mov rbx, width;
   cmp rbx, 0;
   jle @@exitproc;
   mov rsi, height;
   cmp rsi, 0;
   jle @@exitproc;

   // iter := -width*sizeof(Single)
   imul rbx, -4;

   // prepare counters
   sub rcx, rbx;
   sub r8, rbx;

   @@foryloop:
      mov rax, rbx;
      xorps xmm0, xmm0;

      @@forxloop:
         movss xmm1, [r8 + rax];
         addss xmm0, xmm1;
         movss [rcx + rax], xmm0;
      add rax, 4;
      jnz @@forxloop;

      add rcx, rdx;
      add r8, r9;
   dec rsi;
   jnz @@foryloop;

   @@exitProc:

   // epilog - stack cleanup
   mov rbx, iRBX;
   mov rdi, iRDI;
   mov rsi, iRSI;
end;


procedure ASMMatrixCumulativeSumColumnEvenWUnaligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
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
        cmp r10, 1;
        jle @@exitproc;

        sar r10, 1;  // width div 2

        @@forxloop:
           mov rax, r11;
           xorps xmm0, xmm0;
           xor rdi, rdi;
           xor rsi, rsi;

           // two values at once
           @@foryloop:
              movups xmm1, [r8 + rdi];
              addps xmm0, xmm1;
              movups [rcx + rsi], xmm0;

              add rdi, r9;
              add rsi, rdx;
           dec rax;
           jnz @@foryloop;

           add r8, 16;
           add rcx, 16;
        dec r10;
        jnz @@forxloop;

        @@exitProc:
        // epilog - stack cleanup
        mov rdi, iRDI;
        mov rsi, iRSI;
     end;

procedure ASMMatrixCumulativeSumColumnOddWUnaligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
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
   cmp r10, 1;
   jle @@exitproc;

   sar r10, 1;  // width div 2

   test r10, r10;
   jz @@lastColumn;

   @@forxloop:
      mov rax, r11;
      xorps xmm0, xmm0;
      xor rdi, rdi;
      xor rsi, rsi;

      // two values at once
      @@foryloop:
         movups xmm1, [r8 + rdi];
         addps xmm0, xmm1;
         movups [rcx + rsi], xmm0;

         add rdi, r9;
         add rsi, rdx;
      dec rax;
      jnz @@foryloop;

      add r8, 16;
      add rcx, 16;
   dec r10;
   jnz @@forxloop;

   @@lastColumn:

   mov rax, r11;
   xorps xmm0, xmm0;

   // last column
   @@forycolumnloop:
      movss xmm1, [r8];
      addss xmm0, xmm1;
      movss [rcx], xmm0;

      add r8, r9;
      add rcx, rdx;
   dec rax;
   jnz @@forycolumnloop;

   @@exitProc:
   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
end;


procedure ASMMatrixCumulativeSumColumnEvenWAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
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
   cmp r10, 1;
   jle @@exitproc;

   sar r10, 1;  // width div 2

   @@forxloop:
      mov rax, r11;
      xorps xmm0, xmm0;
      xor rdi, rdi;
      xor rsi, rsi;

      // two values at once
      @@foryloop:
         movaps xmm1, [r8 + rdi];
         addps xmm0, xmm1;
         movaps [rcx + rsi], xmm0;

         add rdi, r9;
         add rsi, rdx;
      dec rax;
      jnz @@foryloop;

      add r8, 16;
      add rcx, 16;
   dec r10;
   jnz @@forxloop;

   @@exitProc:
   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
end;

procedure ASMMatrixCumulativeSumColumnOddWAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
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
   cmp r10, 1;
   jle @@exitproc;

   sar r10, 1;  // width div 2

   test r10, r10;
   jz @@lastColumn;

   @@forxloop:
      mov rax, r11;
      xorps xmm0, xmm0;
      xor rdi, rdi;
      xor rsi, rsi;

      // two values at once
      @@foryloop:
         movaps xmm1, [r8 + rdi];
         addps xmm0, xmm1;
         movaps [rcx + rsi], xmm0;

         add rdi, r9;
         add rsi, rdx;
      dec rax;
      jnz @@foryloop;

      add r8, 16;
      add rcx, 16;
   dec r10;
   jnz @@forxloop;

   @@lastColumn:

   mov rax, r11;
   xorps xmm0, xmm0;

   // last column
   @@forycolumnloop:
      movss xmm1, [r8];
      addss xmm0, xmm1;
      movss [rcx], xmm0;

      add r8, r9;
      add rcx, rdx;
   dec rax;
   jnz @@forycolumnloop;

   @@exitProc:
   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
end;

// ###############################################
// #### Differentiate
// ###############################################

procedure ASMMatrixDifferentiateRow(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var iRBX, iRDI, iRSI : NativeInt;
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
   mov iRBX, rbx;
   mov iRDI, rdi;
   mov iRSI, rsi;

   // if (width <= 1) or (height <= 0) then exit;
   mov rbx, width;
   cmp rbx, 1;
   jle @@exitproc;
   mov rsi, height;
   cmp rsi, 0;
   jle @@exitproc;

   // iter := -width*sizeof(Single)
   imul rbx, -4;

   // prepare counters
   sub rcx, rbx;
   sub r8, rbx;
   add rbx, 4;

   @@foryloop:
      mov rax, rbx;
      movss xmm1, [r8 + rax - 8];

      @@forxloop:
         movss xmm0, [r8 + rax];
         movss xmm2, xmm0;

         subss xmm1, xmm0;
         movss [rcx + rax - 8], xmm0;
         movss xmm1, xmm2;
      add rax, 4;
      jnz @@forxloop;

      add rcx, rdx;
      add r8, r9;
   dec rsi;
   jnz @@foryloop;

   @@exitProc:

   // epilog - stack cleanup
   mov rbx, iRBX;
   mov rdi, iRDI;
   mov rsi, iRSI;
end;

procedure ASMMatrixDifferentiateColumnEvenWUnaligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
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

   // if (width <= 0) or (height <= 1) then exit;
   mov r11, height;
   cmp r11, 1;
   jle @@exitproc;
   mov r10, width;
   cmp r10, 0;
   jle @@exitproc;

   dec r11;
   sar r10, 1;  // width div 2

   @@forxloop:
      mov rax, r11;
      xorps xmm0, xmm0;
      mov rdi, r9;
      xor rsi, rsi;

      movups xmm0, [r8];

      // two values at once
      @@foryloop:
         movups xmm1, [r8 + rdi];
         movaps xmm2, xmm1;
         subps xmm1, xmm0;
         movups [rcx + rsi], xmm1;

         movaps xmm0, xmm2;

         add rdi, r9;
         add rsi, rdx;
      dec rax;
      jnz @@foryloop;

      add r8, 16;
      add rcx, 16;
   dec r10;
   jnz @@forxloop;

   @@exitProc:
   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
end;

procedure ASMMatrixDifferentiateColumnOddWUnaligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
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

   // if (width <= 0) or (height <= 1) then exit;
   mov r11, height;
   cmp r11, 1;
   jle @@exitproc;
   mov r10, width;
   cmp r10, 0;
   jle @@exitproc;

   dec r11;     // height - 1

   sar r10, 1;  // width div 2

   test r10, r10;
   jz @@lastColumn;

   @@forxloop:
      mov rax, r11;
      xorps xmm0, xmm0;
      mov rdi, r9;
      xor rsi, rsi;

      movups xmm0, [r8];
      // two values at once
      @@foryloop:
         movups xmm1, [r8 + rdi];
         movaps xmm2, xmm1;
         subps xmm1, xmm0;
         movups [rcx + rsi], xmm1;

         movaps xmm0, xmm2;
         add rdi, r9;
         add rsi, rdx;
      dec rax;
      jnz @@foryloop;

      add r8, 16;
      add rcx, 16;
   dec r10;
   jnz @@forxloop;

   @@lastColumn:

   mov rax, r11;

   movss xmm0, [r8];
   add r8, r9;

   // last column
   @@forycolumnloop:
      movss xmm1, [r8];
      movss xmm2, xmm1;
      subss xmm1, xmm0;
      movss [rcx], xmm1;
      movss xmm0, xmm2;

      add r8, r9;
      add rcx, rdx;
   dec rax;
   jnz @@forycolumnloop;

   @@exitProc:
   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
end;

procedure ASMMatrixDifferentiateColumnEvenWAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
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

   // if (width <= 0) or (height <= 1) then exit;
   mov r11, height;
   cmp r11, 1;
   jle @@exitproc;
   mov r10, width;
   cmp r10, 0;
   jle @@exitproc;

   dec r11;     // height - 1
   sar r10, 1;  // width div 2

   @@forxloop:
      mov rax, r11;
      xorps xmm0, xmm0;
      mov rdi, r9;
      xor rsi, rsi;

      movaps xmm0, [r8];

      // two values at once
      @@foryloop:
         movaps xmm1, [r8 + rdi];
         movaps xmm2, xmm1;
         subps xmm1, xmm0;
         movaps [rcx + rsi], xmm1;

         movaps xmm0, xmm2;

         add rdi, r9;
         add rsi, rdx;
      dec rax;
      jnz @@foryloop;

      add r8, 16;
      add rcx, 16;
   dec r10;
   jnz @@forxloop;

   @@exitProc:
   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
end;


procedure ASMMatrixDifferentiateColumnOddWAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
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

   // if (width <= 0) or (height <= 1) then exit;
   mov r11, height;
   cmp r11, 1;
   jle @@exitproc;
   mov r10, width;
   cmp r10, 0;
   jle @@exitproc;

   dec r11;     // height - 1
   sar r10, 1;  // width div 2

   test r10, r10;
   jz @@lastColumn;

   @@forxloop:
      mov rax, r11;
      xorps xmm0, xmm0;
      mov rdi, r9;
      xor rsi, rsi;

      movaps xmm0, [r8];
      // two values at once
      @@foryloop:
         movaps xmm1, [r8 + rdi];
         movaps xmm2, xmm1;
         subps xmm1, xmm0;
         movaps [rcx + rsi], xmm1;

         movaps xmm0, xmm2;
         add rdi, r9;
         add rsi, rdx;
      dec rax;
      jnz @@foryloop;

      add r8, 16;
      add rcx, 16;
   dec r10;
   jnz @@forxloop;

   @@lastColumn:

   mov rax, r11;

   movss xmm0, [r8];
   add r8, r9;

   // last column
   @@forycolumnloop:
      movss xmm1, [r8];
      movss xmm2, xmm1;
      subss xmm1, xmm0;
      movss [rcx], xmm1;
      movss xmm0, xmm2;

      add r8, r9;
      add rcx, rdx;
   dec rax;
   jnz @@forycolumnloop;

   @@exitProc:
   // epilog - stack cleanup
   mov rdi, iRDI;
   mov rsi, iRSI;
end;

{$ENDIF}

end.
