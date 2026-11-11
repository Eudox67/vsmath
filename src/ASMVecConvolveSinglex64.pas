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

unit ASMVecConvolveSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

// simple convolution: the input and output parameter are assumed to be vectors!
// dest[i] = sum(k = 0..bLen - 1) A[i + k - (bLen - 1)] * B[k]
// it's also assumed that memory before A is accessible for at least bLen - 1
// elements -> these elements are used for the convolution calculation
// there is no alignment or length restriction on B and bLen:
// every load is unaligned and bLen may be any value >= 0
procedure ASMVecConvolveRevB(dest : PSingle; A, B : PSingle; aLen, {$ifdef UNIX}unixbLen{$ELSE}bLen{$endif} : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure ASMVecConvolveRevB(dest : PSingle; A, B : PSingle; aLen, {$ifdef UNIX}unixbLen{$ELSE}bLen{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var bLen : NativeInt;
{$endif}
var iRDI : NativeInt;
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov bLen, r8;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // rcx = dest, rdx = A, r8 = B, r9 = aLen, r10 = bLen
   mov r10, bLen;
   mov iRDI, rdi;

   test r9, r9;
   jle @@done;               // nothing to do

   test r10, r10;
   jg @@forxloop;

   // a filter of length zero: every result is zero
   xor eax, eax;
   @@zeroloop:
      mov [rcx], eax;
      add rcx, 4;
      dec r9;
   jnz @@zeroloop;
   jmp @@done;

   @@forxloop:
      // rax = A + i - (bLen - 1)
      mov r11, r10;
      shl r11, 2;
      sub r11, 4;
      mov rax, rdx;
      sub rax, r11;

      xorps xmm0, xmm0;           // 4 lane accumulator
      xorps xmm5, xmm5;           // remainder accumulator
      xor r11, r11;               // byte offset into the row

      // full 4 element blocks - every load stays inside B[0..bLen-1]
      mov rdi, r10;
      shr rdi, 2;
      test rdi, rdi;
      jz @@tail;

      @@vecloop:
         movups xmm1, [rax + r11];
         movups xmm2, [r8 + r11];
         mulps xmm1, xmm2;
         addps xmm0, xmm1;
         add r11, 16;
         dec rdi;
      jnz @@vecloop;

      @@tail:
      // up to 3 remaining elements, one at a time
      mov rdi, r10;
      and rdi, 3;
      jz @@reduce;

      @@tailloop:
         movss xmm1, [rax + r11];
         mulss xmm1, [r8 + r11];
         addss xmm5, xmm1;
         add r11, 4;
         dec rdi;
      jnz @@tailloop;

      @@reduce:
      haddps xmm0, xmm0;
      haddps xmm0, xmm0;
      addss xmm0, xmm5;
      movss [rcx], xmm0;

      // next element
      add rcx, 4;
      add rdx, 4;
      dec r9;
   jnz @@forxloop;

   // ########################################
   // #### epilog

   @@done:
   mov rdi, iRDI;
end;

{$ENDIF}

end.
