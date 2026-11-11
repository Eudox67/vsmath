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


unit ASMMatrixScaleOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

procedure ASMMatrixAddScaleAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;
procedure ASMMatrixAddScaleUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;

procedure ASMMatrixAddScaleAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;
procedure ASMMatrixAddScaleUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;

procedure ASMMatrixScaleAddAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;
procedure ASMMatrixScaleAddUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;

procedure ASMMatrixScaleAddAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;
procedure ASMMatrixScaleAddUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;

procedure ASMMatrixElemAddAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset : single); assembler;
procedure ASMMatrixElemAddUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset : single); assembler;

procedure ASMMatrixElemAddAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset : single); assembler;
procedure ASMMatrixElemAddUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset : single); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure ASMMatrixAddScaleAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;
var dXMM6, dXMM7 : Array[0..3] of single;
asm
   movups dXMM6, xmm6;
   movups dXMM7, xmm7;

   movss xmm6, dOffset; shufps xmm6, xmm6, 0;
   movss xmm7, Scale; shufps xmm7, xmm7, 0;
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

   //iters := -width*sizeof(single);
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // add mul
           movaps xmm0, [rcx + rax - 128];
           addps xmm0, xmm6;
           mulps xmm0, xmm7;
           movaps [rcx + rax - 128], xmm0;

           movaps xmm1, [rcx + rax - 112];
           addps xmm1, xmm6;
           mulps xmm1, xmm7;
           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [rcx + rax - 96];
           addps xmm2, xmm6;
           mulps xmm2, xmm7;
           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [rcx + rax - 80];
           addps xmm3, xmm6;
           mulps xmm3, xmm7;
           movaps [rcx + rax - 80], xmm3;

           movaps xmm0, [rcx + rax - 64];
           addps xmm0, xmm6;
           mulps xmm0, xmm7;
           movaps [rcx + rax - 64], xmm0;

           movaps xmm1, [rcx + rax - 48];
           addps xmm1, xmm6;
           mulps xmm1, xmm7;
           movaps [rcx + rax - 48], xmm1;

           movaps xmm2, [rcx + rax - 32];
           addps xmm2, xmm6;
           mulps xmm2, xmm7;
           movaps [rcx + rax - 32], xmm2;

           movaps xmm3, [rcx + rax - 16];
           addps xmm3, xmm6;
           mulps xmm3, xmm7;
           movaps [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm0, [rcx + rax];
           addps xmm0, xmm6;
           mulps xmm0, xmm7;

           movaps [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   movups xmm6, dXMM6;
   movups xmm7, dXMM7;
end;

procedure ASMMatrixAddScaleUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;
var dXMM6, dXMM7 : Array[0..3] of single;
asm
   movups dXMM6, xmm6;
   movups dXMM7, xmm7;
   movss xmm6, dOffset; shufps xmm6, xmm6, 0;
   movss xmm7, scale; shufps xmm7, xmm7, 0;
   
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

   //iters := -width*sizeof(single);
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // add mul:
           movups xmm0, [rcx + rax - 128];
           addps xmm0, xmm6;
           mulps xmm0, xmm7;
           movups [rcx + rax - 128], xmm0;

           movups xmm1, [rcx + rax - 112];
           addps xmm1, xmm6;
           mulps xmm1, xmm7;
           movups [rcx + rax - 112], xmm1;

           movups xmm2, [rcx + rax - 96];
           addps xmm2, xmm6;
           mulps xmm2, xmm7;
           movups [rcx + rax - 96], xmm2;

           movups xmm3, [rcx + rax - 80];
           addps xmm3, xmm6;
           mulps xmm3, xmm7;
           movups [rcx + rax - 80], xmm3;

           movups xmm0, [rcx + rax - 64];
           addps xmm0, xmm6;
           mulps xmm0, xmm7;
           movups [rcx + rax - 64], xmm0;

           movups xmm1, [rcx + rax - 48];
           addps xmm1, xmm6;
           mulps xmm1, xmm7;
           movups [rcx + rax - 48], xmm1;

           movups xmm2, [rcx + rax - 32];
           addps xmm2, xmm6;
           mulps xmm2, xmm7;
           movups [rcx + rax - 32], xmm2;

           movups xmm3, [rcx + rax - 16];
           addps xmm3, xmm6;
           mulps xmm3, xmm7;
           movups [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [rcx + rax];
           addps xmm0, xmm6;
           mulps xmm0, xmm7;

           movups [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   movups xmm6, dXMM6;
   movups xmm7, dXMM7;
end;


procedure ASMMatrixAddScaleAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;
var dXMM6, dXMM7 : Array[0..3] of single;
asm
   movups dXMM6, xmm6;
   movups dXMM7, xmm7;
   movss xmm6, dOffset; shufps xmm6, xmm6, 0;
   movss xmm7, scale; shufps xmm7, xmm7, 0;
   
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

   //iters := -(width - 1)*sizeof(single);
   dec r8;
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // add mul:
           movaps xmm0, [rcx + rax - 128];
           addps xmm0, xmm6;
           mulps xmm0, xmm7;
           movaps [rcx + rax - 128], xmm0;

           movaps xmm1, [rcx + rax - 112];
           addps xmm1, xmm6;
           mulps xmm1, xmm7;
           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [rcx + rax - 96];
           addps xmm2, xmm6;
           mulps xmm2, xmm7;
           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [rcx + rax - 80];
           addps xmm3, xmm6;
           mulps xmm3, xmm7;
           movaps [rcx + rax - 80], xmm3;

           movaps xmm0, [rcx + rax - 64];
           addps xmm0, xmm6;
           mulps xmm0, xmm7;
           movaps [rcx + rax - 64], xmm0;

           movaps xmm1, [rcx + rax - 48];
           addps xmm1, xmm6;
           mulps xmm1, xmm7;
           movaps [rcx + rax - 48], xmm1;

           movaps xmm2, [rcx + rax - 32];
           addps xmm2, xmm6;
           mulps xmm2, xmm7;
           movaps [rcx + rax - 32], xmm2;

           movaps xmm3, [rcx + rax - 16];
           addps xmm3, xmm6;
           mulps xmm3, xmm7;
           movaps [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm0, [rcx + rax];
           addps xmm0, xmm6;
           mulps xmm0, xmm7;

           movaps [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm0, [rcx];
       addss xmm0, xmm6;
       mulss xmm0, xmm7;
       movss [rcx], xmm0;

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   movups xmm6, dXMM6;
   movups xmm7, dXMM7;
end;

procedure ASMMatrixAddScaleUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;
var dXMM6, dXMM7 : Array[0..3] of single;
asm
   movups dXMM6, xmm6;
   movups dXMM7, xmm7;
   movss xmm6, dOffset; shufps xmm6, xmm6, 0;
   movss xmm7, scale; shufps xmm7, xmm7, 0;

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

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   // prolog - simulate stack


   //iters := -(width - 1)*sizeof(single);
   dec r8;
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // add mul:
           movups xmm0, [rcx + rax - 128];
           addps xmm0, xmm6;
           mulps xmm0, xmm7;
           movups [rcx + rax - 128], xmm0;

           movups xmm1, [rcx + rax - 112];
           addps xmm1, xmm6;
           mulps xmm1, xmm7;
           movups [rcx + rax - 112], xmm1;

           movups xmm2, [rcx + rax - 96];
           addps xmm2, xmm6;
           mulps xmm2, xmm7;
           movups [rcx + rax - 96], xmm2;

           movups xmm3, [rcx + rax - 80];
           addps xmm3, xmm6;
           mulps xmm3, xmm7;
           movups [rcx + rax - 80], xmm3;

           movups xmm0, [rcx + rax - 64];
           addps xmm0, xmm6;
           mulps xmm0, xmm7;
           movups [rcx + rax - 64], xmm0;

           movups xmm1, [rcx + rax - 48];
           addps xmm1, xmm6;
           mulps xmm1, xmm7;
           movups [rcx + rax - 48], xmm1;

           movups xmm2, [rcx + rax - 32];
           addps xmm2, xmm6;
           mulps xmm2, xmm7;
           movups [rcx + rax - 32], xmm2;

           movups xmm3, [rcx + rax - 16];
           addps xmm3, xmm6;
           mulps xmm3, xmm7;
           movups [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [rcx + rax];
           addps xmm0, xmm6;
           mulps xmm0, xmm7;

           movups [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm0, [rcx];
       addss xmm0, xmm6;
       mulss xmm0, xmm7;
       movss [rcx], xmm0;

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   movups xmm6, dXMM6;
   movups xmm7, dXMM7;
end;


procedure ASMMatrixScaleAddAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;
var dXMM6, dXMM7 : Array[0..3] of single;
asm
   movups dXMM6, xmm6;
   movups dXMM7, xmm7;
   movss xmm6, dOffset; shufps xmm6, xmm6, 0;
   movss xmm7, scale; shufps xmm7, xmm7, 0;
   
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

   //iters := -width*sizeof(single);
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // addition:
           movaps xmm0, [rcx + rax - 128];
           mulps xmm0, xmm7;
           addps xmm0, xmm6;
           movaps [rcx + rax - 128], xmm0;

           movaps xmm1, [rcx + rax - 112];
           mulps xmm1, xmm7;
           addps xmm1, xmm6;
           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [rcx + rax - 96];
           mulps xmm2, xmm7;
           addps xmm2, xmm6;
           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [rcx + rax - 80];
           mulps xmm3, xmm7;
           addps xmm3, xmm6;
           movaps [rcx + rax - 80], xmm3;

           movaps xmm0, [rcx + rax - 64];
           mulps xmm0, xmm7;
           addps xmm0, xmm6;
           movaps [rcx + rax - 64], xmm0;

           movaps xmm1, [rcx + rax - 48];
           mulps xmm1, xmm7;
           addps xmm1, xmm6;
           movaps [rcx + rax - 48], xmm1;

           movaps xmm2, [rcx + rax - 32];
           mulps xmm2, xmm7;
           addps xmm2, xmm6;
           movaps [rcx + rax - 32], xmm2;

           movaps xmm3, [rcx + rax - 16];
           mulps xmm3, xmm7;
           addps xmm3, xmm6;
           movaps [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm0, [rcx + rax];
           mulps xmm0, xmm7;
           addps xmm0, xmm6;

           movaps [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   movups xmm6, dXMM6;
   movups xmm7, dXMM7;
end;

procedure ASMMatrixScaleAddUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;
var dXMM6, dXMM7 : Array[0..3] of single;
asm
   movups dXMM6, xmm6;
   movups dXMM7, xmm7;
   movss xmm6, dOffset; shufps xmm6, xmm6, 0;
   movss xmm7, scale; shufps xmm7, xmm7, 0;
   
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

   //iters := -width*sizeof(single);
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // mul add:
           movups xmm0, [rcx + rax - 128];
           mulps xmm0, xmm7;
           addps xmm0, xmm6;
           movups [rcx + rax - 128], xmm0;

           movups xmm1, [rcx + rax - 112];
           mulps xmm1, xmm7;
           addps xmm1, xmm6;
           movups [rcx + rax - 112], xmm1;

           movups xmm2, [rcx + rax - 96];
           mulps xmm2, xmm7;
           addps xmm2, xmm6;
           movups [rcx + rax - 96], xmm2;

           movups xmm3, [rcx + rax - 80];
           mulps xmm3, xmm7;
           addps xmm3, xmm6;
           movups [rcx + rax - 80], xmm3;

           movups xmm0, [rcx + rax - 64];
           mulps xmm0, xmm7;
           addps xmm0, xmm6;
           movups [rcx + rax - 64], xmm0;

           movups xmm1, [rcx + rax - 48];
           mulps xmm1, xmm7;
           addps xmm1, xmm6;
           movups [rcx + rax - 48], xmm1;

           movups xmm2, [rcx + rax - 32];
           mulps xmm2, xmm7;
           addps xmm2, xmm6;
           movups [rcx + rax - 32], xmm2;

           movups xmm3, [rcx + rax - 16];
           mulps xmm3, xmm7;
           addps xmm3, xmm6;
           movups [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [rcx + rax];
           mulps xmm0, xmm7;
           addps xmm0, xmm6;

           movups [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   movups xmm6, dXMM6;
   movups xmm7, dXMM7;
end;


procedure ASMMatrixScaleAddAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;
var dXMM6, dXMM7 : Array[0..3] of single;
asm
   movups dXMM6, xmm6;
   movups dXMM7, xmm7;
   movss xmm6, dOffset; shufps xmm6, xmm6, 0;
   movss xmm7, scale; shufps xmm7, xmm7, 0;
   
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

   //iters := -width*sizeof(single);
   dec r8;
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // addition:
           movaps xmm0, [rcx + rax - 128];
           mulps xmm0, xmm7;
           addps xmm0, xmm6;
           movaps [rcx + rax - 128], xmm0;

           movaps xmm1, [rcx + rax - 112];
           mulps xmm1, xmm7;
           addps xmm1, xmm6;
           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [rcx + rax - 96];
           mulps xmm2, xmm7;
           addps xmm2, xmm6;
           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [rcx + rax - 80];
           mulps xmm3, xmm7;
           addps xmm3, xmm6;
           movaps [rcx + rax - 80], xmm3;

           movaps xmm0, [rcx + rax - 64];
           mulps xmm0, xmm7;
           addps xmm0, xmm6;
           movaps [rcx + rax - 64], xmm0;

           movaps xmm1, [rcx + rax - 48];
           mulps xmm1, xmm7;
           addps xmm1, xmm6;
           movaps [rcx + rax - 48], xmm1;

           movaps xmm2, [rcx + rax - 32];
           mulps xmm2, xmm7;
           addps xmm2, xmm6;
           movaps [rcx + rax - 32], xmm2;

           movaps xmm3, [rcx + rax - 16];
           mulps xmm3, xmm7;
           addps xmm3, xmm6;
           movaps [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm0, [rcx + rax];
           mulps xmm0, xmm7;
           addps xmm0, xmm6;

           movaps [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm0, [rcx];
       mulss xmm0, xmm7;
       addss xmm0, xmm6;
       movss [rcx], xmm0;

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   movups xmm6, dXMM6;
   movups xmm7, dXMM7;
end;

procedure ASMMatrixScaleAddUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset, Scale : single); assembler;
var dXMM6, dXMM7 : Array[0..3] of single;
asm
   movups dXMM6, xmm6;
   movups dXMM7, xmm7;
   movss xmm6, dOffset; shufps xmm6, xmm6, 0;
   movss xmm7, scale; shufps xmm7, xmm7, 0;
   
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

   //iters := -(width - 1)*sizeof(single);
   dec r8;
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // mul add:
           movups xmm0, [rcx + rax - 128];
           mulps xmm0, xmm7;
           addps xmm0, xmm6;
           movups [rcx + rax - 128], xmm0;

           movups xmm1, [rcx + rax - 112];
           mulps xmm1, xmm7;
           addps xmm1, xmm6;
           movups [rcx + rax - 112], xmm1;

           movups xmm2, [rcx + rax - 96];
           mulps xmm2, xmm7;
           addps xmm2, xmm6;
           movups [rcx + rax - 96], xmm2;

           movups xmm3, [rcx + rax - 80];
           mulps xmm3, xmm7;
           addps xmm3, xmm6;
           movups [rcx + rax - 80], xmm3;

           movups xmm0, [rcx + rax - 64];
           mulps xmm0, xmm7;
           addps xmm0, xmm6;
           movups [rcx + rax - 64], xmm0;

           movups xmm1, [rcx + rax - 48];
           mulps xmm1, xmm7;
           addps xmm1, xmm6;
           movups [rcx + rax - 48], xmm1;

           movups xmm2, [rcx + rax - 32];
           mulps xmm2, xmm7;
           addps xmm2, xmm6;
           movups [rcx + rax - 32], xmm2;

           movups xmm3, [rcx + rax - 16];
           mulps xmm3, xmm7;
           addps xmm3, xmm6;
           movups [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [rcx + rax];
           mulps xmm0, xmm7;
           addps xmm0, xmm6;

           movups [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm0, [rcx];
       mulss xmm0, xmm7;
       addss xmm0, xmm6;
       movss [rcx], xmm0;

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   movups xmm6, dXMM6;
   movups xmm7, dXMM7;
end;

// ###########################################
// #### Elementwise add
// ###########################################

procedure ASMMatrixElemAddAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset : single); assembler;
var dXMM6 : Array[0..3] of single;
asm
   movups dXMM6, xmm6;

   movss xmm6, dOffset; shufps xmm6, xmm6, 0;
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

   //iters := -width*sizeof(single);
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // add mul
           movaps xmm0, [rcx + rax - 128];
           addps xmm0, xmm6;
           movaps [rcx + rax - 128], xmm0;

           movaps xmm1, [rcx + rax - 112];
           addps xmm1, xmm6;
           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [rcx + rax - 96];
           addps xmm2, xmm6;
           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [rcx + rax - 80];
           addps xmm3, xmm6;
           movaps [rcx + rax - 80], xmm3;

           movaps xmm0, [rcx + rax - 64];
           addps xmm0, xmm6;
           movaps [rcx + rax - 64], xmm0;

           movaps xmm1, [rcx + rax - 48];
           addps xmm1, xmm6;
           movaps [rcx + rax - 48], xmm1;

           movaps xmm2, [rcx + rax - 32];
           addps xmm2, xmm6;
           movaps [rcx + rax - 32], xmm2;

           movaps xmm3, [rcx + rax - 16];
           addps xmm3, xmm6;
           movaps [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm0, [rcx + rax];
           addps xmm0, xmm6;

           movaps [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   movups xmm6, dXMM6;
end;

procedure ASMMatrixElemAddUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset : single); assembler;
var dXMM6 : Array[0..3] of single;
asm
   movups dXMM6, xmm6;
   movss xmm6, dOffset; shufps xmm6, xmm6, 0;

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

   //iters := -width*sizeof(single);
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // add mul:
           movups xmm0, [rcx + rax - 128];
           addps xmm0, xmm6;
           movups [rcx + rax - 128], xmm0;

           movups xmm1, [rcx + rax - 112];
           addps xmm1, xmm6;
           movups [rcx + rax - 112], xmm1;

           movups xmm2, [rcx + rax - 96];
           addps xmm2, xmm6;
           movups [rcx + rax - 96], xmm2;

           movups xmm3, [rcx + rax - 80];
           addps xmm3, xmm6;
           movups [rcx + rax - 80], xmm3;

           movups xmm0, [rcx + rax - 64];
           addps xmm0, xmm6;
           movups [rcx + rax - 64], xmm0;

           movups xmm1, [rcx + rax - 48];
           addps xmm1, xmm6;
           movups [rcx + rax - 48], xmm1;

           movups xmm2, [rcx + rax - 32];
           addps xmm2, xmm6;
           movups [rcx + rax - 32], xmm2;

           movups xmm3, [rcx + rax - 16];
           addps xmm3, xmm6;
           movups [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [rcx + rax];
           addps xmm0, xmm6;

           movups [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   movups xmm6, dXMM6;
end;


procedure ASMMatrixElemAddAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset : single); assembler;
var dXMM6 : Array[0..3] of single;
asm
   movups dXMM6, xmm6;
   movss xmm6, dOffset; shufps xmm6, xmm6, 0;

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

   //iters := -(width - 1)*sizeof(single);
   dec r8;
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // add mul:
           movaps xmm0, [rcx + rax - 128];
           addps xmm0, xmm6;
           movaps [rcx + rax - 128], xmm0;

           movaps xmm1, [rcx + rax - 112];
           addps xmm1, xmm6;
           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [rcx + rax - 96];
           addps xmm2, xmm6;
           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [rcx + rax - 80];
           addps xmm3, xmm6;
           movaps [rcx + rax - 80], xmm3;

           movaps xmm0, [rcx + rax - 64];
           addps xmm0, xmm6;
           movaps [rcx + rax - 64], xmm0;

           movaps xmm1, [rcx + rax - 48];
           addps xmm1, xmm6;
           movaps [rcx + rax - 48], xmm1;

           movaps xmm2, [rcx + rax - 32];
           addps xmm2, xmm6;
           movaps [rcx + rax - 32], xmm2;

           movaps xmm3, [rcx + rax - 16];
           addps xmm3, xmm6;
           movaps [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm0, [rcx + rax];
           addps xmm0, xmm6;

           movaps [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm0, [rcx];
       addss xmm0, xmm6;
       movss [rcx], xmm0;

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   movups xmm6, dXMM6;
end;

procedure ASMMatrixElemAddUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; dOffset : single); assembler;
var dXMM6 : Array[0..3] of single;
asm
   movups dXMM6, xmm6;
   movss xmm6, dOffset; shufps xmm6, xmm6, 0;

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

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   // prolog - simulate stack


   //iters := -(width - 1)*sizeof(single);
   dec r8;
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // add mul:
           movups xmm0, [rcx + rax - 128];
           addps xmm0, xmm6;
           movups [rcx + rax - 128], xmm0;

           movups xmm1, [rcx + rax - 112];
           addps xmm1, xmm6;
           movups [rcx + rax - 112], xmm1;

           movups xmm2, [rcx + rax - 96];
           addps xmm2, xmm6;
           movups [rcx + rax - 96], xmm2;

           movups xmm3, [rcx + rax - 80];
           addps xmm3, xmm6;
           movups [rcx + rax - 80], xmm3;

           movups xmm0, [rcx + rax - 64];
           addps xmm0, xmm6;
           movups [rcx + rax - 64], xmm0;

           movups xmm1, [rcx + rax - 48];
           addps xmm1, xmm6;
           movups [rcx + rax - 48], xmm1;

           movups xmm2, [rcx + rax - 32];
           addps xmm2, xmm6;
           movups [rcx + rax - 32], xmm2;

           movups xmm3, [rcx + rax - 16];
           addps xmm3, xmm6;
           movups [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [rcx + rax];
           addps xmm0, xmm6;

           movups [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm0, [rcx];
       addss xmm0, xmm6;
       movss [rcx], xmm0;

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   movups xmm6, dXMM6;
end;


{$ENDIF}

end.
