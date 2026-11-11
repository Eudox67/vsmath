// ###################################################################
// #### This file is part of the vsmath project - a 32-bit, single-
// #### precision (mode objfpc) fork of mrMath:
// ####   https://github.com/mikerabat/mrmath
// ####
// #### Derived from mrMath. Copyright (c) 2024, Michael R. All rights reserved.
// #### Licensed under the Apache License, Version 2.0 - see LICENSE.
// ####
// #### Modifications Copyright 2026 Eudox67.
// #### Ported from double/x64 to 32-bit single precision; converted
// #### to {$mode objfpc}. See NOTICE for details.
// ####
// #### vsmath is an independent fork and is not affiliated with,
// #### endorsed by, or supported by the mrMath project or its author.
// ###################################################################

unit ASMVecDistSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

uses MatrixConstSingle;

{$IFDEF CPUX64}

procedure ASMMtxDistanceSqr(dist : PSingle; LineWidthDist : NativeInt; X, Y : PSingle; {$ifdef UNIX}unixxLen{$ELSE}xLen {$ENDIF}, {$ifdef UNIX}unixyLen{$ELSE}yLen{$ENDIF} : NativeInt); assembler;
procedure ASMMtxDistanceAbs(dist : PSingle; LineWidthDist : NativeInt; X, Y : PSingle; {$ifdef UNIX}unixxLen{$ELSE}xLen {$ENDIF}, {$ifdef UNIX}unixyLen{$ELSE}yLen{$ENDIF} : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure ASMMtxDistanceSqr(dist : PSingle; LineWidthDist : NativeInt; X, Y : PSingle; {$ifdef UNIX}unixxLen{$ELSE}
  xLen {$ENDIF}, {$ifdef UNIX}unixyLen{$ELSE}yLen{$ENDIF} : NativeInt); assembler;
{$ifdef UNIX}
var xLen, yLen : NativeInt;
{$ENDIF}
// rcx: dest, rdx: destlinewidth; r8: x; r9 : y
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov xLen, r8;
   mov yLen, r9;

   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov r11, xLen;
   mov rax, yLen;
   imul rax, -4;
   sub rcx, rax;

   sub r9, rax;

   @@foriloop:

      // load x[i] -> single
      movss xmm0, [r8]; shufps xmm0, xmm0, 0;
      mov r10, rax;
      add r10, 16;
      // todo unroll loop...
      jg @@lastelem;

      @@forjloop:
         // dist[i, j] = sqr( x[i] - y[j])
         movups xmm1, [r9 + r10 - 16];
         subps xmm1, xmm0;
         mulps xmm1, xmm1;

         movups [rcx + r10 - 16], xmm1;
      add r10, 16;
      jle @@forjloop;

      @@lastelem:
      sub r10, 4;
      jg @@linend;

      // last element
      movss xmm1, [r9 - 8];
      subss xmm1, xmm0;
      mulss xmm1, xmm1;
      movss [rcx - 8], xmm1;

      @@linend:

      add r8, 4;  // sizeof single
      add rcx, rdx; // next line
   dec r11;
   jnz @@foriloop;
end;

procedure ASMMtxDistanceAbs(dist : PSingle; LineWidthDist : NativeInt; X, Y : PSingle;
  {$ifdef UNIX}unixxLen{$ELSE}xLen {$ENDIF}, {$ifdef UNIX}unixyLen{$ELSE}yLen{$ENDIF} : NativeInt); assembler;

{$ifdef UNIX}
var xLen, yLen : NativeInt;
{$ENDIF}
// rcx: dest, rdx: destlinewidth; r8: x; r9 : y
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov xLen, r8;
   mov yLen, r9;

   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov r11, xLen;
   mov rax, yLen;
   imul rax, -4;
   sub rcx, rax;

   movups xmm2, [rip + cAbsMask];

   sub r9, rax;

   @@foriloop:

      // load x[i] -> single
      movss xmm0, [r8]; shufps xmm0, xmm0, 0;
      mov r10, rax;
      add r10, 16;
      // todo unroll loop...
      jg @@lastelem;

      @@forjloop:
         // dist[i, j] = sqr( x[i] - y[j])
         movups xmm1, [r9 + r10 - 16];
         subps xmm1, xmm0;
         andps xmm1, xmm2;

         movups [rcx + r10 - 16], xmm1;
      add r10, 16;
      jle @@forjloop;

      @@lastelem:
      sub r10, 4;
      jg @@linend;

      // last element
      movss xmm1, [r9 - 8];
      subss xmm1, xmm0;
      andps xmm1, xmm2;
      movss [rcx - 8], xmm1;

      @@linend:

      add r8, 4;  // sizeof single
      add rcx, rdx; // next line
   dec r11;
   jnz @@foriloop;
end;

{$ENDIF}


end.
