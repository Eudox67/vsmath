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


unit ASMMatrixAddSubOperationsSinglex64;

// ############################################################
// ##### Matrix addition/subtraction assembler optimized:
// ############################################################

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

procedure ASMMatrixAddAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixAddUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixheight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

procedure ASMMatrixAddAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixAddUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

procedure ASMMatrixSubAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixSubUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

procedure ASMMatrixSubAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixSubUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

procedure ASMMatrixSubT(A : PSingle; LineWidthA : NativeInt; B : PSingle; LineWidthB : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure ASMMatrixSubVecAlignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixSubVecAlignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixSubVecAlignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure ASMMatrixSubVecUnalignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixSubVecUnalignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixSubVecUnalignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure ASMMatrixAddVecAlignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixAddVecAlignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixAddVecAlignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure ASMMatrixAddVecUnalignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixAddVecUnalignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixAddVecUnalignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure ASMVecAddAlignedSeq( X : PSingle; y : PSingle; N : NativeInt; alpha : single ); assembler;
procedure ASMVecAddUnAlignedSeq( X : PSingle; y : PSingle; N : NativeInt; alpha : single ); assembler;

procedure ASMVecAddNonSeq( X : PSingle; y : PSingle; N : NativeInt; incX, {$ifdef UNIX}unixIncY{$ELSE}incY {$ENDIF} : NativeInt; alpha : single ); assembler;


{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure ASMMatrixAddAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR12 : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX, r8, r9 -> mov to RCX, RDX, R8, R9, width and height
   mov width, r8;
   mov height, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
   // prolog - simulate stack
   mov iRBX, rbx;
   mov iR12, r12;

   //iters := -width*sizeof(single);
   mov r10, width;
   imul r10, -4;

   mov r11, LineWidth1;
   mov r12, LineWidth2;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub r9, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov rbx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetch [r9 + rax];

           // addition:
           movaps xmm0, [r8 + rax - 128];
           addps xmm0, [r9 + rax - 128];

           movaps [rcx + rax - 128], xmm0;

           movaps xmm1, [r8 + rax - 112];
           addps xmm1, [r9 + rax - 112];

           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [r8 + rax - 96];
           addps xmm2, [r9 + rax - 96];

           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [r8 + rax - 80];
           addps xmm3, [r9 + rax - 80];

           movaps [rcx + rax - 80], xmm3;

           movaps xmm0, [r8 + rax - 64];
           addps xmm0, [r9 + rax - 64];

           movaps [rcx + rax - 64], xmm0;

           movaps xmm1, [r8 + rax - 48];
           addps xmm1, [r9 + rax - 48];

           movaps [rcx + rax - 48], xmm1;

           movaps xmm2, [r8 + rax - 32];
           addps xmm2, [r9 + rax - 32];

           movaps [rcx + rax - 32], xmm2;

           movaps xmm3, [r8 + rax - 16];
           addps xmm3, [r9 + rax - 16];

           movaps [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm0, [r8 + rax];
           addps xmm0, [r9 + rax];

           movaps [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add r8, r11;
       add r9, r12;
       add rcx, rdx;

   // loop y end
   dec rbx;
   jnz @@addforyloop;

   // epilog
   mov rbx, iRBX;
   mov r12, iR12;
end;

procedure ASMMatrixAddUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR12 : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
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

   // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
   // prolog - simulate stack
   mov iRBX, rbx;
   mov iR12, r12;

   mov r11, LineWidth1;
   mov r12, LineWidth2;

   //iters := -width*sizeof(single);
   mov r10, width;
   shl r10, 2;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub r9, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov rbx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetch [r9 + rax];

           // addition:
           movups xmm0, [r8 + rax - 128];
           movups xmm1, [r9 + rax - 128];
           addps xmm0, xmm1;

           movups [rcx + rax - 128], xmm0;

           movups xmm0, [r8 + rax - 112];
           movups xmm1, [r9 + rax - 112];
           addps xmm0, xmm1;

           movups [rcx + rax - 112], xmm0;

           movups xmm0, [r8 + rax - 96];
           movups xmm1, [r9 + rax - 96];
           addps xmm0, xmm1;

           movups [rcx + rax - 96], xmm0;

           movups xmm0, [r8 + rax - 80];
           movups xmm1, [r9 + rax - 80];
           addps xmm0, xmm1;

           movups [rcx + rax - 80], xmm0;

           movups xmm0, [r8 + rax - 64];
           movups xmm1, [r9 + rax - 64];
           addps xmm0, xmm1;

           movups [rcx + rax - 64], xmm0;

           movups xmm0, [r8 + rax - 48];
           movups xmm1, [r9 + rax - 48];
           addps xmm0, xmm1;

           movups [rcx + rax - 48], xmm0;

           movups xmm0, [r8 + rax - 32];
           movups xmm1, [r9 + rax - 32];
           addps xmm0, xmm1;

           movups [rcx + rax - 32], xmm0;

           movups xmm0, [r8 + rax - 16];
           movups xmm1, [r9 + rax - 16];
           addps xmm0, xmm1;

           movups [rcx + rax - 16], xmm0;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [r8 + rax];
           movups xmm1, [r9 + rax];
           addps xmm0, xmm1;

           movups [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add r8, r11;
       add r9, r12;
       add rcx, rdx;

   // loop y end
   dec rbx;
   jnz @@addforyloop;

   // epilog
   mov rbx, iRBX;
   mov r12, iR12;
end;

procedure ASMMatrixAddAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR12 : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
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

   // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
   // prolog - simulate stack
   mov iRBX, rbx;
   mov iR12, r12;

   //iters := -(width - 1)*sizeof(single);
   mov r10, width;
   dec r10;
   imul r10, -4;

   mov r11, LineWidth1;
   mov r12, LineWidth2;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub r9, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov rbx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetch [r9 + rax];

           // addition:
           movaps xmm0, [r8 + rax - 128];
           addps xmm0, [r9 + rax - 128];

           movaps [rcx + rax - 128], xmm0;

           movaps xmm1, [r8 + rax - 112];
           addps xmm1, [r9 + rax - 112];

           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [r8 + rax - 96];
           addps xmm2, [r9 + rax - 96];

           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [r8 + rax - 80];
           addps xmm3, [r9 + rax - 80];

           movaps [rcx + rax - 80], xmm3;

           movaps xmm0, [r8 + rax - 64];
           addps xmm0, [r9 + rax - 64];

           movaps [rcx + rax - 64], xmm0;

           movaps xmm1, [r8 + rax - 48];
           addps xmm1, [r9 + rax - 48];

           movaps [rcx + rax - 48], xmm1;

           movaps xmm2, [r8 + rax - 32];
           addps xmm2, [r9 + rax - 32];

           movaps [rcx + rax - 32], xmm2;

           movaps xmm3, [r8 + rax - 16];
           addps xmm3, [r9 + rax - 16];

           movaps [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm0, [r8 + rax];
           addps xmm0, [r9 + rax];

           movaps [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm0, [r8];
       addss xmm0, [r9];

       movss [rcx], xmm0;

       // next line:
       add r8, r11;
       add r9, r12;
       add rcx, rdx;

   // loop y end
   dec rbx;
   jnz @@addforyloop;

   // epilog
   mov rbx, iRBX;
   mov r12, iR12;
end;

procedure ASMMatrixAddUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR12 : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
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

   // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
   // prolog - simulate stack
   mov iRBX, rbx;
   mov iR12, r12;

   mov r11, LineWidth1;
   mov r12, LineWidth2;

   //iters := -(width - 1)*sizeof(single);
   mov r10, width;
   dec r10;
   imul r10, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub r9, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov rbx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetch [r9 + rax];

           // addition:
           movups xmm0, [r8 + rax - 128];
           movups xmm1, [r9 + rax - 128];
           addps xmm0, xmm1;

           movups [rcx + rax - 128], xmm0;

           movups xmm0, [r8 + rax - 112];
           movups xmm1, [r9 + rax - 112];
           addps xmm0, xmm1;

           movups [rcx + rax - 112], xmm0;

           movups xmm0, [r8 + rax - 96];
           movups xmm1, [r9 + rax - 96];
           addps xmm0, xmm1;

           movups [rcx + rax - 96], xmm0;

           movups xmm0, [r8 + rax - 80];
           movups xmm1, [r9 + rax - 80];
           addps xmm0, xmm1;

           movups [rcx + rax - 80], xmm0;

           movups xmm0, [r8 + rax - 64];
           movups xmm1, [r9 + rax - 64];
           addps xmm0, xmm1;

           movups [rcx + rax - 64], xmm0;

           movups xmm0, [r8 + rax - 48];
           movups xmm1, [r9 + rax - 48];
           addps xmm0, xmm1;

           movups [rcx + rax - 48], xmm0;

           movups xmm0, [r8 + rax - 32];
           movups xmm1, [r9 + rax - 32];
           addps xmm0, xmm1;

           movups [rcx + rax - 32], xmm0;

           movups xmm0, [r8 + rax - 16];
           movups xmm1, [r9 + rax - 16];
           addps xmm0, xmm1;

           movups [rcx + rax - 16], xmm0;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [r8 + rax];
           movups xmm1, [r9 + rax];
           addps xmm0, xmm1;

           movups [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm0, [r8];
       addss xmm0, [r9];

       movss [rcx], xmm0;

       // next line:
       add r8, r11;
       add r9, r12;
       add rcx, rdx;

   // loop y end
   dec rbx;
   jnz @@addforyloop;

   // epilog
   mov rbx, iRBX;
   mov r12, iR12;
end;

procedure ASMMatrixSubAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR12 : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
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

   // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
   // prolog - simulate stack
   mov iRBX, rbx;
   mov iR12, r12;

   //iters := -width*sizeof(single);
   mov r10, width;
   imul r10, -4;

   mov r11, LineWidth1;
   mov r12, LineWidth2;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub r9, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov rbx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetch [r9 + rax];

           // addition:
           movaps xmm0, [r8 + rax - 128];
           subps xmm0, [r9 + rax - 128];

           movaps [rcx + rax - 128], xmm0;

           movaps xmm1, [r8 + rax - 112];
           subps xmm1, [r9 + rax - 112];

           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [r8 + rax - 96];
           subps xmm2, [r9 + rax - 96];

           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [r8 + rax - 80];
           subps xmm3, [r9 + rax - 80];

           movaps [rcx + rax - 80], xmm3;

           movaps xmm0, [r8 + rax - 64];
           subps xmm0, [r9 + rax - 64];

           movaps [rcx + rax - 64], xmm0;

           movaps xmm1, [r8 + rax - 48];
           subps xmm1, [r9 + rax - 48];

           movaps [rcx + rax - 48], xmm1;

           movaps xmm2, [r8 + rax - 32];
           subps xmm2, [r9 + rax - 32];

           movaps [rcx + rax - 32], xmm2;

           movaps xmm3, [r8 + rax - 16];
           subps xmm3, [r9 + rax - 16];

           movaps [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm0, [r8 + rax];
           subps xmm0, [r9 + rax];

           movaps [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add r8, r11;
       add r9, r12;
       add rcx, rdx;

   // loop y end
   dec rbx;
   jnz @@addforyloop;

   // epilog
   mov rbx, iRBX;
   mov r12, iR12;
end;

procedure ASMMatrixSubUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR12 : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
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

   // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
   // prolog - simulate stack
   mov iRBX, rbx;
   mov iR12, r12;

   mov r11, LineWidth1;
   mov r12, LineWidth2;

   //iters := -width*sizeof(single);
   mov r10, width;
   imul r10, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub r9, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov rbx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetch [r9 + rax];

           // addition:
           movups xmm0, [r8 + rax - 128];
           movups xmm1, [r9 + rax - 128];
           subps xmm0, xmm1;

           movups [rcx + rax - 128], xmm0;

           movups xmm0, [r8 + rax - 112];
           movups xmm1, [r9 + rax - 112];
           subps xmm0, xmm1;

           movups [rcx + rax - 112], xmm0;

           movups xmm0, [r8 + rax - 96];
           movups xmm1, [r9 + rax - 96];
           subps xmm0, xmm1;

           movups [rcx + rax - 96], xmm0;

           movups xmm0, [r8 + rax - 80];
           movups xmm1, [r9 + rax - 80];
           subps xmm0, xmm1;

           movups [rcx + rax - 80], xmm0;

           movups xmm0, [r8 + rax - 64];
           movups xmm1, [r9 + rax - 64];
           subps xmm0, xmm1;

           movups [rcx + rax - 64], xmm0;

           movups xmm0, [r8 + rax - 48];
           movups xmm1, [r9 + rax - 48];
           subps xmm0, xmm1;

           movups [rcx + rax - 48], xmm0;

           movups xmm0, [r8 + rax - 32];
           movups xmm1, [r9 + rax - 32];
           subps xmm0, xmm1;

           movups [rcx + rax - 32], xmm0;

           movups xmm0, [r8 + rax - 16];
           movups xmm1, [r9 + rax - 16];
           subps xmm0, xmm1;

           movups [rcx + rax - 16], xmm0;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [r8 + rax];
           movups xmm1, [r9 + rax];
           subps xmm0, xmm1;

           movups [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add r8, r11;
       add r9, r12;
       add rcx, rdx;

   // loop y end
   dec rbx;
   jnz @@addforyloop;

   // epilog
   mov rbx, iRBX;
   mov r12, iR12;
end;

procedure ASMMatrixSubAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR12 : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
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

   // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
   // prolog - simulate stack
   mov iRBX, rbx;
   mov iR12, r12;

   //iters := -(width - 1)*sizeof(single);
   mov r10, width;
   dec r10;
   imul r10, -4;

   mov r11, LineWidth1;
   mov r12, LineWidth2;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub r9, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov rbx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetch [r9 + rax];

           // addition:
           movaps xmm0, [r8 + rax - 128];
           subps xmm0, [r9 + rax - 128];

           movaps [rcx + rax - 128], xmm0;

           movaps xmm1, [r8 + rax - 112];
           subps xmm1, [r9 + rax - 112];

           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [r8 + rax - 96];
           subps xmm2, [r9 + rax - 96];

           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [r8 + rax - 80];
           subps xmm3, [r9 + rax - 80];

           movaps [rcx + rax - 80], xmm3;

           movaps xmm0, [r8 + rax - 64];
           subps xmm0, [r9 + rax - 64];

           movaps [rcx + rax - 64], xmm0;

           movaps xmm1, [r8 + rax - 48];
           subps xmm1, [r9 + rax - 48];

           movaps [rcx + rax - 48], xmm1;

           movaps xmm2, [r8 + rax - 32];
           subps xmm2, [r9 + rax - 32];

           movaps [rcx + rax - 32], xmm2;

           movaps xmm3, [r8 + rax - 16];
           subps xmm3, [r9 + rax - 16];

           movaps [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm0, [r8 + rax];
           subps xmm0, [r9 + rax];

           movaps [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm0, [r8];
       subss xmm0, [r9];

       movss [rcx], xmm0;

       // next line:
       add r8, r11;
       add r9, r12;
       add rcx, rdx;

   // loop y end
   dec rbx;
   jnz @@addforyloop;

   // epilog
   mov rbx, iRBX;
   mov r12, iR12;
end;

procedure ASMMatrixSubUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR12 : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
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

   // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
   // prolog - simulate stack
   mov iRBX, rbx;
   mov iR12, r12;

   mov r11, LineWidth1;
   mov r12, LineWidth2;

   //iters := -(width - 1)*sizeof(single);
   mov r10, width;
   dec r10;
   imul r10, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub r9, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov rbx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetch [r9 + rax];

           // addition:
           movups xmm0, [r8 + rax - 128];
           movups xmm1, [r9 + rax - 128];
           subps xmm0, xmm1;

           movups [rcx + rax - 128], xmm0;

           movups xmm0, [r8 + rax - 112];
           movups xmm1, [r9 + rax - 112];
           subps xmm0, xmm1;

           movups [rcx + rax - 112], xmm0;

           movups xmm0, [r8 + rax - 96];
           movups xmm1, [r9 + rax - 96];
           subps xmm0, xmm1;

           movups [rcx + rax - 96], xmm0;

           movups xmm0, [r8 + rax - 80];
           movups xmm1, [r9 + rax - 80];
           subps xmm0, xmm1;

           movups [rcx + rax - 80], xmm0;

           movups xmm0, [r8 + rax - 64];
           movups xmm1, [r9 + rax - 64];
           subps xmm0, xmm1;

           movups [rcx + rax - 64], xmm0;

           movups xmm0, [r8 + rax - 48];
           movups xmm1, [r9 + rax - 48];
           subps xmm0, xmm1;

           movups [rcx + rax - 48], xmm0;

           movups xmm0, [r8 + rax - 32];
           movups xmm1, [r9 + rax - 32];
           subps xmm0, xmm1;

           movups [rcx + rax - 32], xmm0;

           movups xmm0, [r8 + rax - 16];
           movups xmm1, [r9 + rax - 16];
           subps xmm0, xmm1;

           movups [rcx + rax - 16], xmm0;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [r8 + rax];
           movups xmm1, [r9 + rax];
           subps xmm0, xmm1;

           movups [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm0, [r8];
       subss xmm0, [r9];

       movss [rcx], xmm0;

       // next line:
       add r8, r11;
       add r9, r12;
       add rcx, rdx;

   // loop y end
   dec rbx;
   jnz @@addforyloop;

   // epilog
   mov rbx, iRBX;
   mov r12, iR12;
end;

procedure ASMMatrixSubT(A : PSingle; LineWidthA : NativeInt; B : PSingle; LineWidthB : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
{$ENDIF}
     // rcx : A, rdx : LineWidthA, r8 : B, r9 : LineWidthB;
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

        // rax: iter := -width*sizeof(single)
        mov rcx, A;
        mov rax, width;
        imul rax, -4;
        sub rcx, rax;

        // for y := 0 to height - 1
        @@foryloop:
           mov r10, r8;
           mov r11, rax;

           // for x := 0 to width - 1
           @@forxloop:
              movss xmm0, [rcx + r11];
              movss xmm1, [r10];

              subss xmm0, xmm1;
              movss [rcx + r11], xmm0;

              add r10, r9;
           add r11, 4;
           jnz @@forxloop;

           add rcx, rdx;
           add r8, 4;
        dec height;
        jnz @@foryloop;
     end;

// ########################################################
// #### Matrix add, sub to vector operations
// ########################################################

procedure ASMMatrixSubVecAlignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
{$ENDIF}
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
   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r10;

   @@foryloop:
      mov rax, r10;

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         movaps xmm0, [rcx + rax - 64];
         subps xmm0, [r8 + rax - 64];
         movaps [rcx + rax - 64], xmm0;

         movaps xmm1, [rcx + rax - 48];
         subps xmm1, [r8 + rax - 48];
         movaps [rcx + rax - 48], xmm1;

         movaps xmm2, [rcx + rax - 32];
         subps xmm2, [r8 + rax - 32];
         movaps [rcx + rax - 32], xmm2;

         movaps xmm3, [rcx + rax - 16];
         subps xmm3, [r8 + rax - 16];
         movaps [rcx + rax - 16], xmm3;

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         movss xmm0, [rcx + rax];
         movss xmm1, [r8 + rax];

         subss xmm0, xmm1;
         movss [rcx + rax], xmm0;

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;
end;

procedure ASMMatrixSubVecAlignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var vecIter : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
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
   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r11, width;

   imul r11, r9;
   imul r11, -1;
   mov vecIter, r11;

   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r11;

   @@foryloop:
      mov rax, r10;
      mov r11, vecIter;

      @@forxloop:
         movss xmm0, [rcx + rax];
         movss xmm1, [r8 + r11];

         subss xmm0, xmm1;
         movss [rcx + rax], xmm0;

         add r11, r9;
         add rax, 4;
      jnz @@forxloop;

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;
end;

procedure ASMMatrixSubVecAlignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
{$ENDIF}
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
   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;

   @@foryloop:
      mov rax, r10;

      movss xmm1, [r8]; shufps xmm1, xmm1, 0;

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         movaps xmm0, [rcx + rax - 64];
         subps xmm0, xmm1;
         movaps [rcx + rax - 64], xmm0;

         movaps xmm3, [rcx + rax - 48];
         subps xmm3, xmm1;
         movaps [rcx + rax - 48], xmm3;

         movaps xmm2, [rcx + rax - 32];
         subps xmm2, xmm1;
         movaps [rcx + rax - 32], xmm2;

         movaps xmm3, [rcx + rax - 16];
         subps xmm3, xmm1;
         movaps [rcx + rax - 16], xmm3;

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         movss xmm0, [rcx + rax];

         subss xmm0, xmm1;
         movss [rcx + rax], xmm0;

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
      add r8, r9;
   dec Height;
   jnz @@foryloop;
end;

procedure ASMMatrixSubVecUnalignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
{$ENDIF}
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r10;

   @@foryloop:
      mov rax, r10;

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         movups xmm0, [rcx + rax - 64];
         movups xmm1, [r8 + rax - 64];
         subps xmm0, xmm1;
         movups [rcx + rax - 64], xmm0;

         movups xmm1, [rcx + rax - 48];
         movups xmm2, [r8 + rax - 48];
         subps xmm1, xmm2;
         movups [rcx + rax - 48], xmm1;

         movups xmm2, [rcx + rax - 32];
         movups xmm3, [r8 + rax - 32];
         subps xmm2, xmm3;
         movups [rcx + rax - 32], xmm2;

         movups xmm3, [rcx + rax - 16];
         movups xmm0, [r8 + rax - 16];
         subps xmm3, xmm0;
         movups [rcx + rax - 16], xmm3;

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         movss xmm0, [rcx + rax];
         movss xmm1, [r8 + rax];

         subss xmm0, xmm1;
         movss [rcx + rax], xmm0;

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;
end;

procedure ASMMatrixSubVecUnalignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var vecIter : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
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
   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r11, width;

   imul r11, r9;
   imul r11, -1;
   mov vecIter, r11;

   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r11;

   @@foryloop:
      mov rax, r10;
      mov r11, vecIter;

      @@forxloop:
         movss xmm0, [rcx + rax];
         movss xmm1, [r8 + r11];

         subss xmm0, xmm1;
         movss [rcx + rax], xmm0;

         add r11, r9;
         add rax, 4;
      jnz @@forxloop;

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;
end;

procedure ASMMatrixSubVecUnalignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
{$ENDIF}
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;

   @@foryloop:
      mov rax, r10;

      movss xmm1, [r8]; shufps xmm1, xmm1, 0;

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         movups xmm0, [rcx + rax - 64];
         subps xmm0, xmm1;
         movups [rcx + rax - 64], xmm0;

         movups xmm3, [rcx + rax - 48];
         subps xmm3, xmm1;
         movups [rcx + rax - 48], xmm3;

         movups xmm2, [rcx + rax - 32];
         subps xmm2, xmm1;
         movups [rcx + rax - 32], xmm2;

         movups xmm3, [rcx + rax - 16];
         subps xmm3, xmm1;
         movups [rcx + rax - 16], xmm3;

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         movss xmm0, [rcx + rax];

         subss xmm0, xmm1;
         movss [rcx + rax], xmm0;

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
      add r8, r9;
   dec Height;
   jnz @@foryloop;
end;


procedure ASMMatrixAddVecAlignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
{$ENDIF}
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r10;

   @@foryloop:
      mov rax, r10;

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         movaps xmm0, [rcx + rax - 64];
         addps xmm0, [r8 + rax - 64];
         movaps [rcx + rax - 64], xmm0;

         movaps xmm1, [rcx + rax - 48];
         addps xmm1, [r8 + rax - 48];
         movaps [rcx + rax - 48], xmm1;

         movaps xmm2, [rcx + rax - 32];
         addps xmm2, [r8 + rax - 32];
         movaps [rcx + rax - 32], xmm2;

         movaps xmm3, [rcx + rax - 16];
         addps xmm3, [r8 + rax - 16];
         movaps [rcx + rax - 16], xmm3;

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         movss xmm0, [rcx + rax];
         movss xmm1, [r8 + rax];

         addss xmm0, xmm1;
         movss [rcx + rax], xmm0;

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;
end;

procedure ASMMatrixAddVecAlignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var vecIter : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r11, width;

   imul r11, r9;
   imul r11, -1;
   mov vecIter, r11;

   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r11;

   @@foryloop:
      mov rax, r10;
      mov r11, vecIter;

      @@forxloop:
         movss xmm0, [rcx + rax];
         movss xmm1, [r8 + r11];

         addss xmm0, xmm1;
         movss [rcx + rax], xmm0;

         add r11, r9;
         add rax, 4;
      jnz @@forxloop;

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;
end;

procedure ASMMatrixAddVecAlignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
{$ENDIF}
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;

   @@foryloop:
      mov rax, r10;

      movss xmm1, [r8]; shufps xmm1, xmm1, 0;

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         movaps xmm0, [rcx + rax - 64];
         addps xmm0, xmm1;
         movaps [rcx + rax - 64], xmm0;

         movaps xmm3, [rcx + rax - 48];
         addps xmm3, xmm1;
         movaps [rcx + rax - 48], xmm3;

         movaps xmm2, [rcx + rax - 32];
         addps xmm2, xmm1;
         movaps [rcx + rax - 32], xmm2;

         movaps xmm3, [rcx + rax - 16];
         addps xmm3, xmm1;
         movaps [rcx + rax - 16], xmm3;

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         movss xmm0, [rcx + rax];

         addss xmm0, xmm1;
         movss [rcx + rax], xmm0;

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
      add r8, r9;
   dec Height;
   jnz @@foryloop;
end;

procedure ASMMatrixAddVecUnalignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
{$ENDIF}
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r10;

   @@foryloop:
      mov rax, r10;

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         movups xmm0, [rcx + rax - 64];
         movups xmm1, [r8 + rax - 64];
         addps xmm0, xmm1;
         movups [rcx + rax - 64], xmm0;

         movups xmm1, [rcx + rax - 48];
         movups xmm2, [r8 + rax - 48];
         addps xmm1, xmm2;
         movups [rcx + rax - 48], xmm1;

         movups xmm2, [rcx + rax - 32];
         movups xmm3, [r8 + rax - 32];
         addps xmm2, xmm3;
         movups [rcx + rax - 32], xmm2;

         movups xmm3, [rcx + rax - 16];
         movups xmm0, [r8 + rax - 16];
         addps xmm3, xmm0;
         movups [rcx + rax - 16], xmm3;

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         movss xmm0, [rcx + rax];
         movss xmm1, [r8 + rax];

         addss xmm0, xmm1;
         movss [rcx + rax], xmm0;

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;
end;

procedure ASMMatrixAddVecUnalignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var vecIter : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r11, width;

   imul r11, r9;
   imul r11, -1;
   mov vecIter, r11;

   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r11;

   @@foryloop:
      mov rax, r10;
      mov r11, vecIter;

      @@forxloop:
         movss xmm0, [rcx + rax];
         movss xmm1, [r8 + r11];

         addss xmm0, xmm1;
         movss [rcx + rax], xmm0;

         add r11, r9;
         add rax, 4;
      jnz @@forxloop;

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;
end;

procedure ASMMatrixAddVecUnalignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
    height : NativeInt;
{$ENDIF}
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;

   @@foryloop:
      mov rax, r10;

      movss xmm1, [r8]; shufps xmm1, xmm1, 0;

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         movups xmm0, [rcx + rax - 64];
         addps xmm0, xmm1;
         movups [rcx + rax - 64], xmm0;

         movups xmm3, [rcx + rax - 48];
         addps xmm3, xmm1;
         movups [rcx + rax - 48], xmm3;

         movups xmm2, [rcx + rax - 32];
         addps xmm2, xmm1;
         movups [rcx + rax - 32], xmm2;

         movups xmm3, [rcx + rax - 16];
         addps xmm3, xmm1;
         movups [rcx + rax - 16], xmm3;

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         movss xmm0, [rcx + rax];

         addss xmm0, xmm1;
         movss [rcx + rax], xmm0;

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
      add r8, r9;
   dec Height;
   jnz @@foryloop;
end;

// perform y[i] = y[i] + alpha * x[i]
// unrolled 4 times
procedure ASMVecAddUnAlignedSeq( X : PSingle; y : PSingle; N : NativeInt; alpha : single );
// rcx = X (accumulated in place), rdx = y, r8 = N, xmm3 = alpha
//
// X[i] := X[i] + alpha*y[i]; every length is allowed, the leftover zero to three
// elements are added one scalar step each.
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
  {$ENDIF}

   movss xmm0, alpha; shufps xmm0, xmm0, 0;

   xor r9, r9;              // byte offset into both vectors

   mov rax, r8;
   shr rax, 2;              // whole four element blocks
   jz @@tail;

   @@forNLoop:
      movups xmm1, [rdx + r9];      // alpha*y
      mulps xmm1, xmm0;
      movups xmm2, [rcx + r9];      // X
      addps xmm2, xmm1;
      movups [rcx + r9], xmm2;
      add r9, 16;
   dec rax;
   jnz @@forNLoop;

   @@tail:
   mov rax, r8;
   and rax, 3;              // zero to three leftover elements
   jz @@done;

   @@tailLoop:
      movss xmm1, [rdx + r9];
      mulss xmm1, xmm0;
      movss xmm2, [rcx + r9];
      addss xmm2, xmm1;
      movss [rcx + r9], xmm2;
      add r9, 4;
   dec rax;
   jnz @@tailLoop;

   @@done:
end;

procedure ASMVecAddAlignedSeq( X : PSingle; y : PSingle; N : NativeInt; alpha : single );
// Same contract as ASMVecAddUnAlignedSeq: X[i] := X[i] + alpha*y[i]. The
// kernel loads and stores with movups, so there is no alignment gain left to
// exploit - forwarding keeps a single implementation to maintain.
asm
   call ASMVecAddUnAlignedSeq;
end;

procedure ASMVecAddNonSeq( X : PSingle; y : PSingle; N : NativeInt; incX, {$ifdef UNIX}unixIncY{$ELSE}incY {$ENDIF} : NativeInt; alpha : single );
// rcx = X, rdx = Y, r8 = N, incX = r9
{$IFDEF UNIX}
var incY : NativeInt;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov incY, unixIncY;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov rax, incY;

   {$IFNDEF UNIX}
   movss xmm0, alpha;
   {$ENDIF}

   @@loopN:
      movss xmm1, [rdx];        // alpha*y
      movss xmm2, [rcx];        // X
      mulss xmm1, xmm0;
      addss xmm2, xmm1;

      movss [rcx], xmm2;
      add rdx, rax;
      add rcx, r9;
   dec r8;
   jnz @@loopN;
end;

{$ENDIF}

end.
