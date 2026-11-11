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


unit AVXMatrixSumOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

uses MatrixConstSingle;

procedure AVXMatrixSumRowAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
procedure AVXMatrixSumRowUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
procedure AVXMatrixSumColumnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
procedure AVXMatrixSumColumnUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure AVXMatrixSumColumnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = Src, r9 = srcLineWidth
//
// Column sum: eight adjacent columns accumulated per pass plus a scalar tail for
// the remaining zero to seven. Every load stays inside the matrix.
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
   shr rax, 3;                   // number of whole eight column blocks
   jz @@tailcols;

   @@colblock:
       vxorps ymm0, ymm0, ymm0;  // eight lane accumulator, one lane per column
       mov r10, r8;
       add r10, iOff;
       mov r11, iHeight;

       @@rowloop:
           vmovups ymm1, [r10];
           vaddps ymm0, ymm0, ymm1;
           add r10, r9;
       dec r11;
       jnz @@rowloop;

       // The eight lanes hold the eight column sums in column order. A
       // contiguous dest takes one store; a padded dest needs one store per
       // lane.
       cmp rdx, 4;
       jne @@scatter;

       vmovups [rcx], ymm0;
       add rcx, 32;              // the store covered eight elements
       jmp @@nextblock;

       @@scatter:
       vextractf128 xmm2, ymm0, 1;   // lanes 4..7, before xmm0 is rewritten
       vmovss [rcx], xmm0;           // lane 0
       add rcx, rdx;
       vshufps xmm0, xmm0, xmm0, $39;  // rotate the lanes left by one
       vmovss [rcx], xmm0;
       add rcx, rdx;
       vshufps xmm0, xmm0, xmm0, $39;
       vmovss [rcx], xmm0;
       add rcx, rdx;
       vshufps xmm0, xmm0, xmm0, $39;
       vmovss [rcx], xmm0;
       add rcx, rdx;

       vmovss [rcx], xmm2;           // lane 4
       add rcx, rdx;
       vshufps xmm2, xmm2, xmm2, $39;
       vmovss [rcx], xmm2;
       add rcx, rdx;
       vshufps xmm2, xmm2, xmm2, $39;
       vmovss [rcx], xmm2;
       add rcx, rdx;
       vshufps xmm2, xmm2, xmm2, $39;
       vmovss [rcx], xmm2;
       add rcx, rdx;

       @@nextblock:
       add iOff, 32;
   dec rax;
   jnz @@colblock;

   @@tailcols:
   mov rax, iWidth;
   and rax, 7;
   jz @@done;

   @@tailloop:
       vxorps xmm0, xmm0, xmm0;
       mov r10, r8;
       add r10, iOff;
       mov r11, iHeight;

       @@tailrowloop:
           vmovss xmm1, [r10];
           vaddss xmm0, xmm0, xmm1;
           add r10, r9;
       dec r11;
       jnz @@tailrowloop;

       vmovss [rcx], xmm0;
       add rcx, rdx;
       add iOff, 4;
   dec rax;
   jnz @@tailloop;

   @@done:
   vzeroupper;
end;

procedure AVXMatrixSumColumnUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
asm
   call AVXMatrixSumColumnAligned;
end;

// dest[y] := sum(x = 0..width - 1) Src[y][x] - dest is a column vector, so the
// results are destLineWidth bytes apart. The vector loop only reads full eight
// element blocks and the remainder is added one element at a time, so no element
// outside Src[0..height-1][0..width-1] is touched.
procedure AVXMatrixSumRowAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
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
   test r10, r10;
   jle @@done;

   @@foryloop:
       vxorps ymm0, ymm0, ymm0;      // eight lane accumulator
       vxorps xmm2, xmm2, xmm2;      // remainder accumulator
       xor r11, r11;

       mov rax, iWidth;
       shr rax, 3;
       jz @@tail;

       @@vecloop:
           vmovaps ymm1, [r8 + r11];
           vaddps ymm0, ymm0, ymm1;
           add r11, 32;
           dec rax;
       jnz @@vecloop;

       @@tail:
       mov rax, iWidth;
       and rax, 7;
       jz @@reduce;

       @@tailloop:
           vmovss xmm1, [r8 + r11];
           vaddss xmm2, xmm2, xmm1;
           add r11, 4;
           dec rax;
       jnz @@tailloop;

       @@reduce:
       vextractf128 xmm1, ymm0, 1;
       vaddps xmm0, xmm0, xmm1;
       vaddss xmm0, xmm0, xmm2;
       vhaddps xmm0, xmm0, xmm0;
       vhaddps xmm0, xmm0, xmm0;
       vmovss [rcx], xmm0;

       add rcx, rdx;
       add r8, r9;
       dec r10;
   jnz @@foryloop;

   vzeroupper;

   @@done:
end;

procedure AVXMatrixSumRowUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; width, height : NativeInt); assembler;
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
   test r10, r10;
   jle @@done;

   @@foryloop:
       vxorps ymm0, ymm0, ymm0;
       vxorps xmm2, xmm2, xmm2;
       xor r11, r11;

       mov rax, iWidth;
       shr rax, 3;
       jz @@tail;

       @@vecloop:
           vmovups ymm1, [r8 + r11];
           vaddps ymm0, ymm0, ymm1;
           add r11, 32;
           dec rax;
       jnz @@vecloop;

       @@tail:
       mov rax, iWidth;
       and rax, 7;
       jz @@reduce;

       @@tailloop:
           vmovss xmm1, [r8 + r11];
           vaddss xmm2, xmm2, xmm1;
           add r11, 4;
           dec rax;
       jnz @@tailloop;

       @@reduce:
       vextractf128 xmm1, ymm0, 1;
       vaddps xmm0, xmm0, xmm1;
       vaddss xmm0, xmm0, xmm2;
       vhaddps xmm0, xmm0, xmm0;
       vhaddps xmm0, xmm0, xmm0;
       vmovss [rcx], xmm0;

       add rcx, rdx;
       add r8, r9;
       dec r10;
   jnz @@foryloop;

   vzeroupper;

   @@done:
end;

{$ENDIF}

end.