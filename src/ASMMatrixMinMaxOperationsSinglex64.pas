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


unit ASMMatrixMinMaxOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

uses MatrixConstSingle;

{$IFDEF CPUX64}

function ASMMatrixMaxAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
function ASMMatrixMaxUnAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;

function ASMMatrixMaxAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
function ASMMatrixMaxUnAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;

function ASMMatrixMinAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
function ASMMatrixMinUnAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;

function ASMMatrixMinAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
function ASMMatrixMinUnAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;

// same as above but first taking the abs value
function ASMMatrixAbsMaxAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
function ASMMatrixAbsMaxUnAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;

function ASMMatrixAbsMaxAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
function ASMMatrixAbsMaxUnAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;

function ASMMatrixAbsMinAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
function ASMMatrixAbsMinUnAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;

function ASMMatrixAbsMinAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
function ASMMatrixAbsMinUnAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;

procedure ASMVecMinAligned( dest : PSingle; mt : PSingle; N : NativeInt ); assembler;
procedure ASMVecMinUnAligned( dest : PSingle; mt : PSingle; N : NativeInt ); assembler;

procedure ASMVecMaxAligned( dest : PSingle; mt : PSingle; N : NativeInt ); assembler;
procedure ASMVecMaxUnAligned( dest : PSingle; mt : PSingle; N : NativeInt ); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}


procedure ASMVecMinAligned( dest : PSingle; mt : PSingle; N : NativeInt ); assembler;
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov r8, rdx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   imul r8, -4;
   sub rcx, r8;
   sub rdx, r8;

   // unrolled loop
   @Loop1:
      add r8, 64;
      jg @LoopEnd1;

      movaps xmm0, [rcx + r8 - 64];
      movaps xmm1, [rdx + r8 - 64];

      minps xmm0, xmm1;
      movaps [rcx + r8 - 64], xmm0;

      movaps xmm2, [rcx + r8 - 48];
      movaps xmm3, [rdx + r8 - 48];

      minps xmm2, xmm3;
      movaps [rcx + r8 - 48], xmm2;

      movaps xmm0, [rcx + r8 - 32];
      movaps xmm1, [rdx + r8 - 32];

      minps xmm0, xmm1;
      movaps [rcx + r8 - 32], xmm0;

      movaps xmm2, [rcx + r8 - 16];
      movaps xmm3, [rdx + r8 - 16];

      minps xmm2, xmm3;
      movaps [rcx + r8 - 16], xmm2;
   jmp @Loop1;

   @LoopEnd1:
   sub r8, 64;
   jz @retProc;

   @Loop2:
      add r8, 16;
      jg @LoopEnd2;

      movaps xmm0, [rcx + r8 - 16];
      movaps xmm1, [rdx + r8 - 16];

      minps xmm0, xmm1;
      movaps [rcx + r8 - 16], xmm0;
   jmp @Loop2;

   @LoopEnd2:

   sub r8, 16;
   jz @retProc;

   // handle uneven last element...
   movss xmm0, [rcx - 8];
   movss xmm1, [rdx - 8];
   minss xmm0, xmm1;
   movss [rcx - 8], xmm0;

   @retProc:
end;

procedure ASMVecMinUnaligned( dest : PSingle; mt : PSingle; N : NativeInt );
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov r8, rdx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   imul r8, -4;
   sub rcx, r8;
   sub rdx, r8;

   // unrolled loop
   @Loop1:
      add r8, 64;
      jg @LoopEnd1;

      movups xmm0, [rcx + r8 - 64];
      movups xmm1, [rdx + r8 - 64];

      minps xmm0, xmm1;
      movups [rcx + r8 - 64], xmm0;

      movups xmm2, [rcx + r8 - 48];
      movups xmm3, [rdx + r8 - 48];

      minps xmm2, xmm3;
      movups [rcx + r8 - 48], xmm2;

      movups xmm0, [rcx + r8 - 32];
      movups xmm1, [rdx + r8 - 32];

      minps xmm0, xmm1;
      movups [rcx + r8 - 32], xmm0;

      movups xmm2, [rcx + r8 - 16];
      movups xmm3, [rdx + r8 - 16];

      minps xmm2, xmm3;
      movups [rcx + r8 - 16], xmm2;
   jmp @Loop1;
   @LoopEnd1:

   sub r8, 64;
   jz @retProc;

   @Loop2:
      add r8, 16;
      jg @LoopEnd2;

      movups xmm0, [rcx + r8 - 16];
      movups xmm1, [rdx + r8 - 16];

      minps xmm0, xmm1;
      movups [rcx + r8 - 16], xmm0;
   jmp @Loop2;

   @LoopEnd2:

   sub r8, 16;
   jz @retProc;

   // handle uneven element...
   movss xmm0, [rcx - 8];
   movss xmm1, [rdx - 8];
   minss xmm0, xmm1;
   movss [rcx - 8], xmm0;

   @retProc:
end;

procedure ASMVecMaxAligned( dest : PSingle; mt : PSingle; N : NativeInt ); assembler;
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov r8, rdx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   imul r8, -4;
   sub rcx, r8;
   sub rdx, r8;

   // unrolled loop
   @Loop1:
      add r8, 64;
      jg @LoopEnd1;

      movaps xmm0, [rcx + r8 - 64];
      movaps xmm1, [rdx + r8 - 64];

      maxps xmm0, xmm1;
      movaps [rcx + r8 - 64], xmm0;

      movaps xmm2, [rcx + r8 - 48];
      movaps xmm3, [rdx + r8 - 48];

      maxps xmm2, xmm3;
      movaps [rcx + r8 - 48], xmm2;

      movaps xmm0, [rcx + r8 - 32];
      movaps xmm1, [rdx + r8 - 32];

      maxps xmm0, xmm1;
      movaps [rcx + r8 - 32], xmm0;

      movaps xmm2, [rcx + r8 - 16];
      movaps xmm3, [rdx + r8 - 16];

      maxps xmm2, xmm3;
      movaps [rcx + r8 - 16], xmm2;
   jmp @Loop1;

   @LoopEnd1:
   sub r8, 64;
   jz @retProc;

   @Loop2:
      add r8, 16;
      jg @LoopEnd2;

      movaps xmm0, [rcx + r8 - 16];
      movaps xmm1, [rdx + r8 - 16];

      maxps xmm0, xmm1;
      movaps [rcx + r8 - 16], xmm0;
   jmp @Loop2;

   @LoopEnd2:

   sub r8, 16;
   jz @retProc;

   // handle uneven last element...
   movss xmm0, [rcx - 8];
   movss xmm1, [rdx - 8];
   maxss xmm0, xmm1;
   movss [rcx - 8], xmm0;

   @retProc:
end;

procedure ASMVecMaxUnaligned( dest : PSingle; mt : PSingle; N : NativeInt );
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov r8, rdx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   imul r8, -4;
   sub rcx, r8;
   sub rdx, r8;

   // unrolled loop
   @Loop1:
      add r8, 64;
      jg @LoopEnd1;

      movups xmm0, [rcx + r8 - 64];
      movups xmm1, [rdx + r8 - 64];

      maxps xmm0, xmm1;
      movups [rcx + r8 - 64], xmm0;

      movups xmm2, [rcx + r8 - 48];
      movups xmm3, [rdx + r8 - 48];

      maxps xmm2, xmm3;
      movups [rcx + r8 - 48], xmm2;

      movups xmm0, [rcx + r8 - 32];
      movups xmm1, [rdx + r8 - 32];

      maxps xmm0, xmm1;
      movups [rcx + r8 - 32], xmm0;

      movups xmm2, [rcx + r8 - 16];
      movups xmm3, [rdx + r8 - 16];

      maxps xmm2, xmm3;
      movups [rcx + r8 - 16], xmm2;
   jmp @Loop1;
   @LoopEnd1:

   sub r8, 64;
   jz @retProc;

   @Loop2:
      add r8, 16;
      jg @LoopEnd2;

      movups xmm0, [rcx + r8 - 16];
      movups xmm1, [rdx + r8 - 16];

      maxps xmm0, xmm1;
      movups [rcx + r8 - 16], xmm0;
   jmp @Loop2;

   @LoopEnd2:

   sub r8, 16;
   jz @retProc;

   // handle uneven element...
   movss xmm0, [rcx - 8];
   movss xmm1, [rdx - 8];
   maxss xmm0, xmm1;
   movss [rcx - 8], xmm0;

   @retProc:
end;


function ASMMatrixMaxAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   imul rdx, -4;

   sub rcx, rdx;

	  // init result
   movups xmm0, [rip + cNegMaxSingles];
   movaps xmm1, xmm0;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [rcx + rax];

           // max:
           maxps xmm0, [rcx + rax - 128];
           maxps xmm1, [rcx + rax - 112];
           maxps xmm0, [rcx + rax - 96];
           maxps xmm1, [rcx + rax - 80];
           maxps xmm0, [rcx + rax - 64];
           maxps xmm1, [rcx + rax - 48];
           maxps xmm0, [rcx + rax - 32];
           maxps xmm1, [rcx + rax - 16];
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           maxps xmm0, [rcx + rax];
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final max ->
   maxps xmm0, xmm1;
   movhlps xmm1, xmm0;
   maxps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   maxss xmm0, xmm1;

   // epilog - cleanup stack
end;

function ASMMatrixMaxUnAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack

   imul rdx, -4;

   sub rcx, rdx;

	  // init result
   movups xmm0, [rip + cNegMaxSingles];
   movaps xmm3, xmm0;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // max:
           movups xmm1, [rcx + rax - 128];
           maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 112];
           maxps xmm3, xmm2;
           movups xmm1, [rcx + rax - 96];
       				maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 80];
           maxps xmm3, xmm2;
           movups xmm1, [rcx + rax - 64];
           maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 48];
           maxps xmm3, xmm2;
           movups xmm1, [rcx + rax - 32];
           maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 16];
           maxps xmm3, xmm2;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm1, [rcx + rax];
           maxps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final max ->
   maxps xmm0, xmm3;
   movhlps xmm1, xmm0;
   maxps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   maxss xmm0, xmm1;

   // epilog - cleanup stack
end;


function ASMMatrixMaxAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   dec rdx;
   imul rdx, -4;

   sub rcx, rdx;

   // init result
   movups xmm0, [rip + cNegMaxSingles];
   movaps xmm1, xmm0;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [rcx + rax];

           // max:
           maxps xmm0, [rcx + rax - 128];
           maxps xmm1, [rcx + rax - 112];
           maxps xmm0, [rcx + rax - 96];
           maxps xmm1, [rcx + rax - 80];
           maxps xmm0, [rcx + rax - 64];
           maxps xmm1, [rcx + rax - 48];
           maxps xmm0, [rcx + rax - 32];
           maxps xmm1, [rcx + rax - 16];
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           maxps xmm0, [rcx + rax];
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm4, [rcx];
       maxss xmm0, xmm4;

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final max ->
   maxps xmm0, xmm1;
   movhlps xmm1, xmm0;
   maxps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   maxss xmm0, xmm1;

   // epilog - cleanup stack
end;

function ASMMatrixMaxUnAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   dec rdx;
   imul rdx, -4;

   sub rcx, rdx;

   // init result
   movups xmm0, [rip + cNegMaxSingles];
   movaps xmm3, xmm0;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // max
           movups xmm1, [rcx + rax - 128];
           maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 112];
           maxps xmm3, xmm2;
           movups xmm1, [rcx + rax - 96];
       				maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 80];
           maxps xmm3, xmm2;
           movups xmm1, [rcx + rax - 64];
           maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 48];
           maxps xmm3, xmm2;
           movups xmm1, [rcx + rax - 32];
           maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 16];
           maxps xmm3, xmm2;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm1, [rcx + rax];
           maxps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm1, [rcx];
       maxss xmm0, xmm1;

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final max ->
   maxps xmm0, xmm3;
   movhlps xmm1, xmm0;
   maxps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   maxss xmm0, xmm1;

   // epilog - cleanup stack
end;


function ASMMatrixMinAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   imul rdx, -4;

   sub rcx, rdx;

	  // init result
   movups xmm0, [rip + cMaxSingles];
   movaps xmm1, xmm0;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [rcx + rax];

           // min:
           minps xmm0, [rcx + rax - 128];
           minps xmm1, [rcx + rax - 112];
           minps xmm0, [rcx + rax - 96];
           minps xmm1, [rcx + rax - 80];
           minps xmm0, [rcx + rax - 64];
           minps xmm1, [rcx + rax - 48];
           minps xmm0, [rcx + rax - 32];
           minps xmm1, [rcx + rax - 16];
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           minps xmm0, [rcx + rax];
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final Min ->
   minps xmm0, xmm1;
   movhlps xmm1, xmm0;
   minps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   minss xmm0, xmm1;

   // epilog - cleanup stack
end;

function ASMMatrixMinUnAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   imul rdx, -4;

   sub rcx, rdx;

	  // init result
   movups xmm0, [rip + cMaxSingles];
   movaps xmm3, xmm0;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // min:
           movups xmm1, [rcx + rax - 128];
           minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 112];
           minps xmm3, xmm2;
           movups xmm1, [rcx + rax - 96];
       	   minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 80];
           minps xmm3, xmm2;
           movups xmm1, [rcx + rax - 64];
           minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 48];
           minps xmm3, xmm2;
           movups xmm1, [rcx + rax - 32];
           minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 16];
           minps xmm3, xmm2;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm1, [rcx + rax];
           minps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final Min ->
   minps xmm0, xmm3;
   movhlps xmm1, xmm0;
   minps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   minss xmm0, xmm1;

   // epilog - cleanup stack
end;


function ASMMatrixMinAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   dec rdx;
   imul rdx, -4;

   sub rcx, rdx;

   // init result
   movups xmm0, [rip + cMaxSingles];
   movaps xmm1, xmm0;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [rcx + rax];

           // min:
           minps xmm0, [rcx + rax - 128];
           minps xmm1, [rcx + rax - 112];
           minps xmm0, [rcx + rax - 96];
           minps xmm1, [rcx + rax - 80];
           minps xmm0, [rcx + rax - 64];
           minps xmm1, [rcx + rax - 48];
           minps xmm0, [rcx + rax - 32];
           minps xmm1, [rcx + rax - 16];
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           minps xmm0, [rcx + rax];
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm4, [rcx];
       minss xmm0, xmm4;

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final Min ->
   minps xmm0, xmm1;
   movhlps xmm1, xmm0;
   minps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   minss xmm0, xmm1;

   // epilog - cleanup stack
end;

function ASMMatrixMinUnAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   dec rdx;
   imul rdx, -4;

   sub rcx, rdx;

	  // init result
   movups xmm0, [rip + cMaxSingles];
   movaps xmm3, xmm0;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // Min
           movups xmm1, [rcx + rax - 128];
           minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 112];
           minps xmm3, xmm2;
           movups xmm1, [rcx + rax - 96];
       	   minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 80];
           minps xmm3, xmm2;
           movups xmm1, [rcx + rax - 64];
           minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 48];
           minps xmm3, xmm2;
           movups xmm1, [rcx + rax - 32];
           minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 16];
           minps xmm3, xmm2;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm1, [rcx + rax];
           minps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm1, [rcx];
       minss xmm0, xmm1;

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final Min ->
   minps xmm0, xmm3;
   movhlps xmm1, xmm0;
   minps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   minss xmm0, xmm1;

   // epilog - cleanup stack
end;

// ###########################################
// #### abs Min/Max operations
// ###########################################

function ASMMatrixAbsMaxAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   imul rdx, -4;

   sub rcx, rdx;

	  // init result
   movups xmm0, [rip + cNegMaxSingles];
   movaps xmm1, xmm0;
   movups xmm4, [rip + cAbsMask];

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [rcx + rax];

           // max:
           movaps xmm2, [rcx + rax - 128];
           andps xmm2, xmm4;
           maxps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 112];
           andps xmm3, xmm4;
           maxps xmm1, xmm3;
           movaps xmm2, [rcx + rax - 96];
           andps xmm2, xmm4;
           maxps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 80];
           andps xmm3, xmm4;
           maxps xmm1, xmm3;
           movaps xmm2, [rcx + rax - 64];
           andps xmm2, xmm4;
           maxps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 48];
           andps xmm3, xmm4;
           maxps xmm1, xmm3;
           movaps xmm2, [rcx + rax - 32];
           andps xmm2, xmm4;
           maxps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 16];
           andps xmm3, xmm4;
           maxps xmm1, xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm2, [rcx + rax];
           andps xmm2, xmm4;
           maxps xmm0, xmm2;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final max ->
   maxps xmm0, xmm1;
   movhlps xmm1, xmm0;
   maxps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   maxss xmm0, xmm1;

   // epilog - cleanup stack
end;


function ASMMatrixAbsMaxUnAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack

   imul rdx, -4;

   sub rcx, rdx;

	  // init result
   movups xmm0, [rip + cNegMaxSingles];
   movaps xmm3, xmm0;
   movups xmm4, [rip + cAbsMask];

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // max:
           movups xmm1, [rcx + rax - 128];
           andps xmm1, xmm4;
           maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 112];
           andps xmm2, xmm4;
           maxps xmm3, xmm2;
           movups xmm1, [rcx + rax - 96];
           andps xmm1, xmm4;
       				maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 80];
           andps xmm2, xmm4;
           maxps xmm3, xmm2;
           movups xmm1, [rcx + rax - 64];
           andps xmm1, xmm4;
           maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 48];
           andps xmm2, xmm4;
           maxps xmm3, xmm2;
           movups xmm1, [rcx + rax - 32];
           andps xmm1, xmm4;
           maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 16];
           andps xmm2, xmm4;
           maxps xmm3, xmm2;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm1, [rcx + rax];
           andps xmm1, xmm4;
           maxps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final max ->
   maxps xmm0, xmm3;
   movhlps xmm1, xmm0;
   maxps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   maxss xmm0, xmm1;

   // epilog - cleanup stack
end;


function ASMMatrixAbsMaxAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   dec rdx;
   imul rdx, -4;

   sub rcx, rdx;

   // init result
   movups xmm0, [rip + cNegMaxSingles];
   movaps xmm1, xmm0;
   movups xmm4, [rip + cAbsMask];

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [rcx + rax];

           // max:
           movaps xmm2, [rcx + rax - 128];
           andps xmm2, xmm4;
           maxps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 112];
           andps xmm3, xmm4;
           maxps xmm1, xmm3;
           movaps xmm2, [rcx + rax - 96];
           andps xmm2, xmm4;
           maxps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 80];
           andps xmm3, xmm4;
           maxps xmm1, xmm3;
           movaps xmm2, [rcx + rax - 64];
           andps xmm2, xmm4;
           maxps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 48];
           andps xmm3, xmm4;
           maxps xmm1, xmm3;
           movaps xmm2, [rcx + rax - 32];
           andps xmm2, xmm4;
           maxps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 16];
           andps xmm3, xmm4;
           maxps xmm1, xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm2, [rcx + rax];
           andps xmm2, xmm4;
           maxps xmm0, xmm2;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm3, [rcx];
       andps xmm3, xmm4;
       maxss xmm0, xmm3;

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final max ->
   maxps xmm0, xmm1;
   movhlps xmm1, xmm0;
   maxps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   maxss xmm0, xmm1;

   // epilog - cleanup stack
end;

function ASMMatrixAbsMaxUnAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   dec rdx;
   imul rdx, -4;

   sub rcx, rdx;

   // init result
   movups xmm0, [rip + cNegMaxSingles];
   movaps xmm3, xmm0;
   movups xmm4, [rip + cAbsMask];

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // max
           movups xmm1, [rcx + rax - 128];
           andps xmm1, xmm4;
           maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 112];
           andps xmm2, xmm4;
           maxps xmm3, xmm2;
           movups xmm1, [rcx + rax - 96];
           andps xmm1, xmm4;
       				maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 80];
           andps xmm2, xmm4;
           maxps xmm3, xmm2;
           movups xmm1, [rcx + rax - 64];
           andps xmm1, xmm4;
           maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 48];
           andps xmm2, xmm4;
           maxps xmm3, xmm2;
           movups xmm1, [rcx + rax - 32];
           andps xmm1, xmm4;
           maxps xmm0, xmm1;
           movups xmm2, [rcx + rax - 16];
           andps xmm2, xmm4;
           maxps xmm3, xmm2;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm1, [rcx + rax];
           andps xmm1, xmm4;
           maxps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm1, [rcx];
       andps xmm1, xmm4;
       maxss xmm0, xmm1;

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final max ->
   maxps xmm0, xmm3;
   movhlps xmm1, xmm0;
   maxps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   maxss xmm0, xmm1;

   // epilog - cleanup stack
end;


function ASMMatrixAbsMinAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   imul rdx, -4;

   sub rcx, rdx;

	  // init result
   movups xmm0, [rip + cMaxSingles];
   movaps xmm1, xmm0;
   movups xmm4, [rip + cAbsMask];

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [rcx + rax];

           // min:
           movaps xmm2, [rcx + rax - 128];
           andps xmm2, xmm4;
           minps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 112];
           andps xmm3, xmm4;
           minps xmm1, xmm3;
           movaps xmm2, [rcx + rax - 96];
           andps xmm2, xmm4;
           minps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 80];
           andps xmm3, xmm4;
           minps xmm1, xmm3;
           movaps xmm2, [rcx + rax - 64];
           andps xmm2, xmm4;
           minps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 48];
           andps xmm3, xmm4;
           minps xmm1, xmm3;
           movaps xmm2, [rcx + rax - 32];
           andps xmm2, xmm4;
           minps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 16];
           andps xmm3, xmm4;
           minps xmm1, xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm2, [rcx + rax];
           andps xmm2, xmm4;
           minps xmm0, xmm2;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final Min ->
   minps xmm0, xmm1;
   movhlps xmm1, xmm0;
   minps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   minss xmm0, xmm1;

   // epilog - cleanup stack
end;

function ASMMatrixAbsMinUnAlignedEvenW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   imul rdx, -4;

   sub rcx, rdx;

	  // init result
   movups xmm0, [rip + cMaxSingles];
   movaps xmm3, xmm0;
   movups xmm4, [rip + cAbsMask];

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // min:
           movups xmm1, [rcx + rax - 128];
           andps xmm1, xmm4;
           minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 112];
           andps xmm2, xmm4;
           minps xmm3, xmm2;
           movups xmm1, [rcx + rax - 96];
           andps xmm1, xmm4;
       				minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 80];
           andps xmm2, xmm4;
           minps xmm3, xmm2;
           movups xmm1, [rcx + rax - 64];
           andps xmm1, xmm4;
           minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 48];
           andps xmm2, xmm4;
           minps xmm3, xmm2;
           movups xmm1, [rcx + rax - 32];
           andps xmm1, xmm4;
           minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 16];
           andps xmm2, xmm4;
           minps xmm3, xmm2;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm1, [rcx + rax];
           andps xmm1, xmm4;
           minps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final Min ->
   minps xmm0, xmm3;
   movhlps xmm1, xmm0;
   minps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   minss xmm0, xmm1;

   // epilog - cleanup stack
end;


function ASMMatrixAbsMinAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   dec rdx;
   imul rdx, -4;

   sub rcx, rdx;

   // init result
   movups xmm0, [rip + cMaxSingles];
   movaps xmm1, xmm0;
   movups xmm4, [rip + cAbsMask];

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [rcx + rax];

           // min:
           movaps xmm2, [rcx + rax - 128];
           andps xmm2, xmm4;
           minps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 112];
           andps xmm3, xmm4;
           minps xmm1, xmm3;
           movaps xmm2, [rcx + rax - 96];
           andps xmm2, xmm4;
           minps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 80];
           andps xmm3, xmm4;
           minps xmm1, xmm3;
           movaps xmm2, [rcx + rax - 64];
           andps xmm2, xmm4;
           minps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 48];
           andps xmm3, xmm4;
           minps xmm1, xmm3;
           movaps xmm2, [rcx + rax - 32];
           andps xmm2, xmm4;
           minps xmm0, xmm2;
           movaps xmm3, [rcx + rax - 16];
           andps xmm3, xmm4;
           minps xmm1, xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm2, [rcx + rax - 32];
           andps xmm2, xmm4;
           minps xmm0, xmm2;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm2, [rcx];
       andps xmm2, xmm4;
       minss xmm0, xmm2;

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final Min ->
   minps xmm0, xmm1;
   movhlps xmm1, xmm0;
   minps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   minss xmm0, xmm1;

   // epilog - cleanup stack
end;

function ASMMatrixAbsMinUnAlignedOddW(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   dec rdx;
   imul rdx, -4;

   sub rcx, rdx;

	  // init result
   movups xmm0, [rip + cMaxSingles];
   movaps xmm3, xmm0;
   movups xmm4, [rip + cAbsMask];

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // Min
           movups xmm1, [rcx + rax - 128];
           andps xmm1, xmm4;
           minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 112];
           andps xmm2, xmm4;
           minps xmm3, xmm2;
           movups xmm1, [rcx + rax - 96];
           andps xmm1, xmm4;
       				minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 80];
           andps xmm2, xmm4;
           minps xmm3, xmm2;
           movups xmm1, [rcx + rax - 64];
           andps xmm1, xmm4;
           minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 48];
           andps xmm2, xmm4;
           minps xmm3, xmm2;
           movups xmm1, [rcx + rax - 32];
           andps xmm1, xmm4;
           minps xmm0, xmm1;
           movups xmm2, [rcx + rax - 16];
           andps xmm2, xmm4;
           minps xmm3, xmm2;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm1, [rcx + rax];
           andps xmm1, xmm4;
           minps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       movss xmm1, [rcx];
       andps xmm1, xmm4;
       minss xmm0, xmm1;

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final Min ->
   minps xmm0, xmm3;
   movhlps xmm1, xmm0;
   minps xmm0, xmm1;
   movaps xmm1, xmm0;
   shufps xmm1, xmm1, $55;
   minss xmm0, xmm1;

   // epilog - cleanup stack
end;

{$ENDIF}

end.
