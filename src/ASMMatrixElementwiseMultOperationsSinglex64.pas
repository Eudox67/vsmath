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


unit ASMMatrixElementwiseMultOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

uses MatrixConstSingle;

procedure ASMMatrixElemMultAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixElemMultUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

procedure ASMMatrixElemMultAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixElemMultUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

procedure ASMMatrixElemDivAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixElemDivUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

procedure ASMMatrixElemDivAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixElemDivUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;


{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure ASMMatrixElemMultAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR11, iR12 : NativeInt;
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
   mov iR11, r11;
   mov iR12, r12;

   //iters := -width*sizeof(single);
   mov r10, width;
   shl r10, 2;
   imul r10, -1;

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

           // mult:
           movaps xmm0, [r8 + rax - 128];
           mulps xmm0, [r9 + rax - 128];

           movaps [rcx + rax - 128], xmm0;

           movaps xmm1, [r8 + rax - 112];
           mulps xmm1, [r9 + rax - 112];

           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [r8 + rax - 96];
           mulps xmm2, [r9 + rax - 96];

           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [r8 + rax - 80];
           mulps xmm3, [r9 + rax - 80];

           movaps [rcx + rax - 80], xmm3;

           movaps xmm0, [r8 + rax - 64];
           mulps xmm0, [r9 + rax - 64];

           movaps [rcx + rax - 64], xmm0;

           movaps xmm1, [r8 + rax - 48];
           mulps xmm1, [r9 + rax - 48];

           movaps [rcx + rax - 48], xmm1;

           movaps xmm2, [r8 + rax - 32];
           mulps xmm2, [r9 + rax - 32];

           movaps [rcx + rax - 32], xmm2;

           movaps xmm3, [r8 + rax - 16];
           mulps xmm3, [r9 + rax - 16];

           movaps [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm0, [r8 + rax];
           mulps xmm0, [r9 + rax];

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
   mov r11, iR11;
   mov r12, iR12;
end;

procedure ASMMatrixElemMultUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR11, iR12 : NativeInt;
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
   mov iR11, r11;
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

           // mult:
           movups xmm0, [r8 + rax - 128];
           movups xmm1, [r9 + rax - 128];
           mulps xmm0, xmm1;

           movups [rcx + rax - 128], xmm0;

           movups xmm0, [r8 + rax - 112];
           movups xmm1, [r9 + rax - 112];
           mulps xmm0, xmm1;

           movups [rcx + rax - 112], xmm0;

           movups xmm0, [r8 + rax - 96];
           movups xmm1, [r9 + rax - 96];
           mulps xmm0, xmm1;

           movups [rcx + rax - 96], xmm0;

           movups xmm0, [r8 + rax - 80];
           movups xmm1, [r9 + rax - 80];
           mulps xmm0, xmm1;

           movups [rcx + rax - 80], xmm0;

           movups xmm0, [r8 + rax - 64];
           movups xmm1, [r9 + rax - 64];
           mulps xmm0, xmm1;

           movups [rcx + rax - 64], xmm0;

           movups xmm0, [r8 + rax - 48];
           movups xmm1, [r9 + rax - 48];
           mulps xmm0, xmm1;

           movups [rcx + rax - 48], xmm0;

           movups xmm0, [r8 + rax - 32];
           movups xmm1, [r9 + rax - 32];
           mulps xmm0, xmm1;

           movups [rcx + rax - 32], xmm0;

           movups xmm0, [r8 + rax - 16];
           movups xmm1, [r9 + rax - 16];
           mulps xmm0, xmm1;

           movups [rcx + rax - 16], xmm0;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [r8 + rax];
           movups xmm1, [r9 + rax];
           mulps xmm0, xmm1;

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
   mov r11, iR11;
   mov r12, iR12;
end;

procedure ASMMatrixElemMultAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR11, iR12 : NativeInt;
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
   mov iR11, r11;
   mov iR12, r12;

   //iters := -(width - 1)*sizeof(single);
   mov r10, width;
   dec r10;
   shl r10, 2;
   imul r10, -1;

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

           // mult:
           movaps xmm0, [r8 + rax - 128];
           mulps xmm0, [r9 + rax - 128];

           movaps [rcx + rax - 128], xmm0;

           movaps xmm1, [r8 + rax - 112];
           mulps xmm1, [r9 + rax - 112];

           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [r8 + rax - 96];
           mulps xmm2, [r9 + rax - 96];

           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [r8 + rax - 80];
           mulps xmm3, [r9 + rax - 80];

           movaps [rcx + rax - 80], xmm3;

           movaps xmm0, [r8 + rax - 64];
           mulps xmm0, [r9 + rax - 64];

           movaps [rcx + rax - 64], xmm0;

           movaps xmm1, [r8 + rax - 48];
           mulps xmm1, [r9 + rax - 48];

           movaps [rcx + rax - 48], xmm1;

           movaps xmm2, [r8 + rax - 32];
           mulps xmm2, [r9 + rax - 32];

           movaps [rcx + rax - 32], xmm2;

           movaps xmm3, [r8 + rax - 16];
           mulps xmm3, [r9 + rax - 16];

           movaps [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm0, [r8 + rax];
           mulps xmm0, [r9 + rax];

           movaps [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm0, [r8];
       movss xmm1, [r9];
       mulss xmm0, xmm1;

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
   mov r11, iR11;
   mov r12, iR12;
end;

procedure ASMMatrixElemMultUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR11, iR12 : NativeInt;
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
   mov iR11, r11;
   mov iR12, r12;

   mov r11, LineWidth1;
   mov r12, LineWidth2;

   //iters := -(width - 1)*sizeof(single);
   mov r10, width;
   dec r10;
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

           // addition:
           movups xmm0, [r8 + rax - 128];
           movups xmm1, [r9 + rax - 128];
           mulps xmm0, xmm1;

           movups [rcx + rax - 128], xmm0;

           movups xmm0, [r8 + rax - 112];
           movups xmm1, [r9 + rax - 112];
           mulps xmm0, xmm1;

           movups [rcx + rax - 112], xmm0;

           movups xmm0, [r8 + rax - 96];
           movups xmm1, [r9 + rax - 96];
           mulps xmm0, xmm1;

           movups [rcx + rax - 96], xmm0;

           movups xmm0, [r8 + rax - 80];
           movups xmm1, [r9 + rax - 80];
           mulps xmm0, xmm1;

           movups [rcx + rax - 80], xmm0;

           movups xmm0, [r8 + rax - 64];
           movups xmm1, [r9 + rax - 64];
           mulps xmm0, xmm1;

           movups [rcx + rax - 64], xmm0;

           movups xmm0, [r8 + rax - 48];
           movups xmm1, [r9 + rax - 48];
           mulps xmm0, xmm1;

           movups [rcx + rax - 48], xmm0;

           movups xmm0, [r8 + rax - 32];
           movups xmm1, [r9 + rax - 32];
           mulps xmm0, xmm1;

           movups [rcx + rax - 32], xmm0;

           movups xmm0, [r8 + rax - 16];
           movups xmm1, [r9 + rax - 16];
           mulps xmm0, xmm1;

           movups [rcx + rax - 16], xmm0;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [r8 + rax];
           movups xmm1, [r9 + rax];
           mulps xmm0, xmm1;

           movups [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm0, [r8];
       movss xmm1, [r9];
       mulss xmm0, xmm1;

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
   mov r11, iR11;
   mov r12, iR12;
end;

// ##############################################################
// #### Elementwise divide of matrix 1 to matrix 2
// ##############################################################

procedure ASMMatrixElemDivAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR11, iR12 : NativeInt;
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
   mov iR11, r11;
   mov iR12, r12;

   //iters := -width*sizeof(single);
   mov r10, width;
   shl r10, 2;
   imul r10, -1;

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

           // Div:
           movaps xmm0, [r8 + rax - 128];
           divps xmm0, [r9 + rax - 128];

           movaps [rcx + rax - 128], xmm0;

           movaps xmm1, [r8 + rax - 112];
           divps xmm1, [r9 + rax - 112];

           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [r8 + rax - 96];
           divps xmm2, [r9 + rax - 96];

           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [r8 + rax - 80];
           divps xmm3, [r9 + rax - 80];

           movaps [rcx + rax - 80], xmm3;

           movaps xmm0, [r8 + rax - 64];
           divps xmm0, [r9 + rax - 64];

           movaps [rcx + rax - 64], xmm0;

           movaps xmm1, [r8 + rax - 48];
           divps xmm1, [r9 + rax - 48];

           movaps [rcx + rax - 48], xmm1;

           movaps xmm2, [r8 + rax - 32];
           divps xmm2, [r9 + rax - 32];

           movaps [rcx + rax - 32], xmm2;

           movaps xmm3, [r8 + rax - 16];
           divps xmm3, [r9 + rax - 16];

           movaps [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm0, [r8 + rax];
           divps xmm0, [r9 + rax];

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
   mov r11, iR11;
   mov r12, iR12;
end;

procedure ASMMatrixElemDivUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR11, iR12 : NativeInt;
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
   mov iR11, r11;
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

           // Div:
           movups xmm0, [r8 + rax - 128];
           movups xmm1, [r9 + rax - 128];
           divps xmm0, xmm1;

           movups [rcx + rax - 128], xmm0;

           movups xmm0, [r8 + rax - 112];
           movups xmm1, [r9 + rax - 112];
           divps xmm0, xmm1;

           movups [rcx + rax - 112], xmm0;

           movups xmm0, [r8 + rax - 96];
           movups xmm1, [r9 + rax - 96];
           divps xmm0, xmm1;

           movups [rcx + rax - 96], xmm0;

           movups xmm0, [r8 + rax - 80];
           movups xmm1, [r9 + rax - 80];
           divps xmm0, xmm1;

           movups [rcx + rax - 80], xmm0;

           movups xmm0, [r8 + rax - 64];
           movups xmm1, [r9 + rax - 64];
           divps xmm0, xmm1;

           movups [rcx + rax - 64], xmm0;

           movups xmm0, [r8 + rax - 48];
           movups xmm1, [r9 + rax - 48];
           divps xmm0, xmm1;

           movups [rcx + rax - 48], xmm0;

           movups xmm0, [r8 + rax - 32];
           movups xmm1, [r9 + rax - 32];
           divps xmm0, xmm1;

           movups [rcx + rax - 32], xmm0;

           movups xmm0, [r8 + rax - 16];
           movups xmm1, [r9 + rax - 16];
           divps xmm0, xmm1;

           movups [rcx + rax - 16], xmm0;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [r8 + rax];
           movups xmm1, [r9 + rax];
           divps xmm0, xmm1;

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
   mov r11, iR11;
   mov r12, iR12;
end;

procedure ASMMatrixElemDivAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR11, iR12 : NativeInt;
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
   mov iR11, r11;
   mov iR12, r12;

   //iters := -(width - 1)*sizeof(single);
   mov r10, width;
   dec r10;
   shl r10, 2;
   imul r10, -1;

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

           // Div:
           movaps xmm0, [r8 + rax - 128];
           divps xmm0, [r9 + rax - 128];

           movaps [rcx + rax - 128], xmm0;

           movaps xmm1, [r8 + rax - 112];
           divps xmm1, [r9 + rax - 112];

           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [r8 + rax - 96];
           divps xmm2, [r9 + rax - 96];

           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [r8 + rax - 80];
           divps xmm3, [r9 + rax - 80];

           movaps [rcx + rax - 80], xmm3;

           movaps xmm0, [r8 + rax - 64];
           divps xmm0, [r9 + rax - 64];

           movaps [rcx + rax - 64], xmm0;

           movaps xmm1, [r8 + rax - 48];
           divps xmm1, [r9 + rax - 48];

           movaps [rcx + rax - 48], xmm1;

           movaps xmm2, [r8 + rax - 32];
           divps xmm2, [r9 + rax - 32];

           movaps [rcx + rax - 32], xmm2;

           movaps xmm3, [r8 + rax - 16];
           divps xmm3, [r9 + rax - 16];

           movaps [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm0, [r8 + rax];
           divps xmm0, [r9 + rax];

           movaps [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm0, [r8];
       movss xmm1, [r9];
       divss xmm0, xmm1;

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
   mov r11, iR11;
   mov r12, iR12;
end;

procedure ASMMatrixElemDivUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR11, iR12 : NativeInt;
    dXMM4 : TXMMArr;
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
   mov iR11, r11;
   mov iR12, r12;
   movups dXMM4, xmm4;

   mov r11, LineWidth1;
   mov r12, LineWidth2;

   //iters := -(width - 1)*sizeof(single);
   mov r10, width;
   dec r10;
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

           // addition:
           movups xmm0, [r8 + rax - 128];
           movups xmm1, [r9 + rax - 128];
           divps xmm0, xmm1;

           movups [rcx + rax - 128], xmm0;

           movups xmm0, [r8 + rax - 112];
           movups xmm1, [r9 + rax - 112];
           divps xmm0, xmm1;

           movups [rcx + rax - 112], xmm0;

           movups xmm0, [r8 + rax - 96];
           movups xmm1, [r9 + rax - 96];
           divps xmm0, xmm1;

           movups [rcx + rax - 96], xmm0;

           movups xmm0, [r8 + rax - 80];
           movups xmm1, [r9 + rax - 80];
           divps xmm0, xmm1;

           movups [rcx + rax - 80], xmm0;

           movups xmm0, [r8 + rax - 64];
           movups xmm1, [r9 + rax - 64];
           divps xmm0, xmm1;

           movups [rcx + rax - 64], xmm0;

           movups xmm0, [r8 + rax - 48];
           movups xmm1, [r9 + rax - 48];
           divps xmm0, xmm1;

           movups [rcx + rax - 48], xmm0;

           movups xmm0, [r8 + rax - 32];
           movups xmm1, [r9 + rax - 32];
           divps xmm0, xmm1;

           movups [rcx + rax - 32], xmm0;

           movups xmm0, [r8 + rax - 16];
           movups xmm1, [r9 + rax - 16];
           divps xmm0, xmm1;

           movups [rcx + rax - 16], xmm0;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [r8 + rax];
           movups xmm1, [r9 + rax];
           divps xmm0, xmm1;

           movups [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm0, [r8];
       movss xmm1, [r9];
       divss xmm0, xmm1;

       movss [rcx], xmm0;

       // next line:
       add r8, r11;
       add r9, r12;
       add rcx, rdx;

   // loop y end
   dec rbx;
   jnz @@addforyloop;

   // epilog
   movups xmm4, dXMM4;
   mov rbx, iRBX;
   mov r11, iR11;
   mov r12, iR12;
end;

{$ENDIF}

end.
