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


unit ASMMatrixSumOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

procedure ASMMatrixSumRowAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt);
procedure ASMMatrixSumRowUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt);
procedure ASMMatrixSumRowAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt);
procedure ASMMatrixSumRowUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt);

procedure ASMMatrixSumColumnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
procedure ASMMatrixSumColumnUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
procedure ASMMatrixSumColumnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
procedure ASMMatrixSumColumnUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure ASMMatrixSumColumnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = Src, r9 = srcLineWidth
//
// Column sum: accumulates four adjacent columns per pass plus a scalar tail, so
// neither width nor height has to be a whole number of lanes.
var iWidth, iHeight, iOff : NativeInt;
asm
   mov iWidth, width;
   mov iHeight, height;
   {$IFDEF UNIX}
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   cmp iWidth, 0;
   jle @@done;
   cmp iHeight, 0;
   jle @@done;

   xor eax, eax;
   mov iOff, rax;                // byte offset of the current column block
   mov rax, iWidth;
   shr rax, 2;                   // number of whole four column blocks
   jz @@tailcols;

   @@colblock:
       xorps xmm0, xmm0;         // four lane accumulator, one lane per column
       mov r10, r8;
       add r10, iOff;
       mov r11, iHeight;

       @@rowloop:
           movups xmm1, [r10];
           addps xmm0, xmm1;
           add r10, r9;
       dec r11;
       jnz @@rowloop;

       // The four lanes hold the four column sums in column order, so they are
       // stored as they are. A contiguous dest takes one store; a padded dest
       // needs one store per lane.
       cmp rdx, 4;
       jne @@scatter;

       movups [rcx], xmm0;
       add rcx, 16;              // the store covered four elements
       jmp @@nextblock;

       @@scatter:
       movss [rcx], xmm0;        // lane 0
       add rcx, rdx;
       shufps xmm0, xmm0, $39;   // rotate the lanes left by one
       movss [rcx], xmm0;
       add rcx, rdx;
       shufps xmm0, xmm0, $39;
       movss [rcx], xmm0;
       add rcx, rdx;
       shufps xmm0, xmm0, $39;
       movss [rcx], xmm0;
       add rcx, rdx;

       @@nextblock:
       add iOff, 16;
   dec rax;
   jnz @@colblock;

   @@tailcols:
   mov rax, iWidth;
   and rax, 3;
   jz @@done;

   @@tailloop:
       xorps xmm0, xmm0;
       mov r10, r8;
       add r10, iOff;
       mov r11, iHeight;

       @@tailrowloop:
           movss xmm1, [r10];
           addss xmm0, xmm1;
           add r10, r9;
       dec r11;
       jnz @@tailrowloop;

       movss [rcx], xmm0;
       add rcx, rdx;
       add iOff, 4;
   dec rax;
   jnz @@tailloop;

   @@done:
end;

procedure ASMMatrixSumColumnUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
asm
   call ASMMatrixSumColumnAlignedEvenW;
end;
procedure ASMMatrixSumColumnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
asm
   call ASMMatrixSumColumnAlignedEvenW;
end;
procedure ASMMatrixSumColumnUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
asm
   call ASMMatrixSumColumnAlignedEvenW;
end;

// Row sum: four elements per pass plus a scalar tail, so any width and height
// work. The accumulation order differs from a scalar left to right loop, so the
// result is bit identical only for exactly representable data.
procedure ASMMatrixSumRowUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = Src, r9 = srcLineWidth
var iWidth, iHeight : NativeInt;
asm
   mov iWidth, width;
   mov iHeight, height;
   {$IFDEF UNIX}
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov r10, iHeight;
   cmp r10, 0;
   jle @@done;

   @@foryloop:
       xorps xmm0, xmm0;         // four lane accumulator
       xorps xmm3, xmm3;         // tail accumulator, lane 0
       xor r11, r11;             // byte offset into the row

       mov rax, iWidth;
       shr rax, 2;               // number of whole four element blocks
       jz @@tail;

       @@vecloop:
           movups xmm1, [r8 + r11];
           addps xmm0, xmm1;
           add r11, 16;
       dec rax;
       jnz @@vecloop;

       @@tail:
       mov rax, iWidth;
       and rax, 3;               // zero to three leftover elements
       jz @@reduce;

       @@tailloop:
           movss xmm1, [r8 + r11];
           addss xmm3, xmm1;
           add r11, 4;
       dec rax;
       jnz @@tailloop;

       @@reduce:
       // fold the four lanes into lane 0, then add the tail
       movaps xmm2, xmm0;
       shufps xmm2, xmm2, $4E;
       addps xmm0, xmm2;
       movaps xmm2, xmm0;
       shufps xmm2, xmm2, $B1;
       addps xmm0, xmm2;
       addss xmm0, xmm3;

       movss [rcx], xmm0;

       add rcx, rdx;
       add r8, r9;
   dec r10;
   jnz @@foryloop;

   @@done:
end;

procedure ASMMatrixSumRowAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
asm
   call ASMMatrixSumRowUnAlignedEvenW;
end;
procedure ASMMatrixSumRowAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
asm
   call ASMMatrixSumRowUnAlignedEvenW;
end;
procedure ASMMatrixSumRowUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
asm
   call ASMMatrixSumRowUnAlignedEvenW;
end;

{$ENDIF}

end.
