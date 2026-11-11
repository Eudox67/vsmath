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


unit ASMMatrixNormOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

uses MatrixConstSingle;

{$IFDEF CPUX64}

function ASMMatrixElementwiseNorm2AlignedEvenW(dest : PSingle; const LineWidth : NativeInt; Width, height : NativeInt) : single; assembler;
function ASMMatrixElementwiseNorm2UnAlignedEvenW(dest : PSingle; const LineWidth : NativeInt; Width, height : NativeInt) : single; assembler;
function ASMMatrixElementwiseNorm2AlignedOddW(dest : PSingle; const LineWidth : NativeInt; Width, height : NativeInt) : single; assembler;
function ASMMatrixElementwiseNorm2UnAlignedOddW(dest : PSingle; const LineWidth : NativeInt; Width, height : NativeInt) : single; assembler;

procedure ASMMatrixNormalizeRowAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);
procedure ASMMatrixNormalizeRowUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);
procedure ASMMatrixNormalizeRowAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);
procedure ASMMatrixNormalizeRowUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);

procedure ASMMatrixNormalizeColumnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);
procedure ASMMatrixNormalizeColumnUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);
procedure ASMMatrixNormalizeColumnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);
procedure ASMMatrixNormalizeColumnUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);

{$ENDIF}

implementation

{$IFDEF CPUX64}


function ASMMatrixElementwiseNorm2AlignedEvenW(dest : PSingle; const LineWidth : NativeInt; Width, height : NativeInt) : single; assembler;
asm
   {$IFDEF UNIX}
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}
   // an empty matrix has a zero sum of squares; the row loop below
   // would not terminate for a non positive extent, and xmm0 has to
   // hold the zero that is returned
   xorps xmm0, xmm0;
   test r9, r9;
   jle @@finish;
   test r8, r8;
   jle @@finish;

   // note: RCX = dest, RDX = LineWidth, R8 = width, R9 = height
   @@foryloop:
      mov rax, rcx;
      mov r10, r8; // element count
      
      @@forxloop:
         cmp r10, 4;
         jl @@lastX;
         
         movaps xmm1, [rax];
         mulps xmm1, xmm1;
         addps xmm0, xmm1;
         add rax, 16;
         sub r10, 4;
      jnz @@forxloop;
      
      @@lastX:
      test r10, r10;
      jz @@nextRow;
      
      @@forxremainder:
         movss xmm1, [rax];
         mulss xmm1, xmm1;
         addss xmm0, xmm1;
         add rax, 4;
      dec r10;
      jnz @@forxremainder;
      
      @@nextRow:
      add rcx, rdx;
   dec r9;
   jnz @@foryloop;
   
   @@finish:
   haddps xmm0, xmm0;
   haddps xmm0, xmm0;
   // no square root here: the kernel returns the sum of squares so the caller
   // can fold the columns it did not cover and take the root once at the end
end;

function ASMMatrixElementwiseNorm2UnAlignedEvenW(dest : PSingle; const LineWidth : NativeInt; Width, height : NativeInt) : single; assembler;
asm
   {$IFDEF UNIX}
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}
   // an empty matrix has a zero sum of squares; the row loop below
   // would not terminate for a non positive extent, and xmm0 has to
   // hold the zero that is returned
   xorps xmm0, xmm0;
   test r9, r9;
   jle @@finish;
   test r8, r8;
   jle @@finish;

   @@foryloop:
      mov rax, rcx;
      mov r10, r8;
      @@forxloop:
         cmp r10, 4;
         jl @@lastX;
         movups xmm1, [rax];
         mulps xmm1, xmm1;
         addps xmm0, xmm1;
         add rax, 16;
         sub r10, 4;
      jnz @@forxloop;
      @@lastX:
      test r10, r10;
      jz @@nextRow;
      @@forxremainder:
         movss xmm1, [rax];
         mulss xmm1, xmm1;
         addss xmm0, xmm1;
         add rax, 4;
      dec r10;
      jnz @@forxremainder;
      @@nextRow:
      add rcx, rdx;
   dec r9;
   jnz @@foryloop;
   @@finish:
   haddps xmm0, xmm0;
   haddps xmm0, xmm0;
   // sum of squares only - see ASMMatrixElementwiseNorm2AlignedEvenW
end;

function ASMMatrixElementwiseNorm2AlignedOddW(dest : PSingle; const LineWidth : NativeInt; Width, height : NativeInt) : single; assembler;
asm
   call ASMMatrixElementwiseNorm2AlignedEvenW;
end;
function ASMMatrixElementwiseNorm2UnAlignedOddW(dest : PSingle; const LineWidth : NativeInt; Width, height : NativeInt) : single; assembler;
asm
   call ASMMatrixElementwiseNorm2UnAlignedEvenW;
end;

// Normalize: dest[i] = Src[i] / ||row|| (or / ||column||), one kernel per
// direction. Neither extent has to be a whole number of lanes and every access is
// a movups, so the *Aligned* twins cannot fault on unaligned rows.
//
// A zero norm writes zeros instead of the Inf/NaN of a raw division, like
// RefNormalize. The scale pass divides rather than multiplying by a reciprocal,
// which keeps the result bit identical to the reference.
procedure ASMMatrixNormalizeRowKernel(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = Src, r9 = srcLineWidth
var iWidth, iHeight : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux ABI: the 5th and 6th parameters arrive in r8/r9 and the first four
   // in rdi/rsi/rdx/rcx, so re-shuffle to the win64 layout used below.
   mov width, r8;
   mov height, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov rax, width;              // width/height live on the stack here, so they
   mov iWidth, rax;             // are staged through a register
   mov rax, height;
   mov iHeight, rax;

   mov r10, iHeight;
   test r10, r10;
   jle @@done;

   mov rax, iWidth;
   test rax, rax;
   jle @@done;

   @@foryloop:
       // ---- pass 1: sum of squares along the row
       xorps xmm0, xmm0;
       xor r11, r11;             // byte offset into the row

       mov rax, iWidth;
       shr rax, 2;               // whole four element blocks
       jz @@tail1;

       @@vecloop:
           movups xmm1, [r8 + r11];
           mulps xmm1, xmm1;
           addps xmm0, xmm1;
           add r11, 16;
       dec rax;
       jnz @@vecloop;

       @@tail1:
       mov rax, iWidth;
       and rax, 3;               // zero to three leftover elements
       jz @@reduce;

       @@tailloop:
           movss xmm1, [r8 + r11];
           mulss xmm1, xmm1;
           addss xmm0, xmm1;
           add r11, 4;
       dec rax;
       jnz @@tailloop;

       @@reduce:
       movaps xmm1, xmm0;        // fold the four lanes into every lane
       shufps xmm1, xmm1, $4E;
       addps xmm0, xmm1;
       movaps xmm1, xmm0;
       shufps xmm1, xmm1, $B1;
       addps xmm0, xmm1;
       sqrtss xmm0, xmm0;        // the norm, in lane 0
       shufps xmm0, xmm0, 0;     // broadcast it, the scale pass divides by it

       xorps xmm2, xmm2;
       ucomiss xmm0, xmm2;
       jp @@scale;               // NaN norm: the reference divides and yields NaN
       jne @@scale;
       jmp @@zerorow;

       // ---- pass 2: divide the row by its norm
       @@scale:
       xor r11, r11;
       mov rax, iWidth;
       shr rax, 2;
       jz @@scaleTail;

       @@scaleloop:
           movups xmm1, [r8 + r11];
           divps xmm1, xmm0;
           movups [rcx + r11], xmm1;
           add r11, 16;
       dec rax;
       jnz @@scaleloop;

       @@scaleTail:
       mov rax, iWidth;
       and rax, 3;
       jz @@nextrow;

       @@scaleTailLoop:
           movss xmm1, [r8 + r11];
           divss xmm1, xmm0;
           movss [rcx + r11], xmm1;
           add r11, 4;
       dec rax;
       jnz @@scaleTailLoop;
       jmp @@nextrow;

       // ---- zero norm: the row normalizes to zero
       @@zerorow:
       xorps xmm2, xmm2;
       xor r11, r11;
       mov rax, iWidth;
       shr rax, 2;
       jz @@zeroTail;

       @@zeroloop:
           movups [rcx + r11], xmm2;
           add r11, 16;
       dec rax;
       jnz @@zeroloop;

       @@zeroTail:
       mov rax, iWidth;
       and rax, 3;
       jz @@nextrow;

       @@zeroTailLoop:
           movss [rcx + r11], xmm2;
           add r11, 4;
       dec rax;
       jnz @@zeroTailLoop;

       @@nextrow:
       add rcx, rdx;
       add r8, r9;
   dec r10;
   jnz @@foryloop;

   @@done:
end;

// Column kernel: per column sum of squares, then the scale pass over the same
// rows. A zero norm gets a divisor of 1.0 and a masked result lane, so the block
// loop writes the zeros RefNormalize writes.
procedure ASMMatrixNormalizeColumnKernel(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = Src, r9 = srcLineWidth
var iWidth, iHeight, iRows : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
    iRSI : NativeInt;
asm
   mov iRSI, rsi;               // callee saved on win64, used as a row pointer
   {$IFDEF UNIX}
   // Linux ABI: the 5th and 6th parameters arrive in r8/r9 and the first four
   // in rdi/rsi/rdx/rcx, so re-shuffle to the win64 layout used below.
   mov width, r8;
   mov height, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov rax, width;              // width/height live on the stack here, so they
   mov iWidth, rax;             // are staged through a register
   mov rax, height;
   mov iHeight, rax;

   mov rax, iHeight;
   test rax, rax;
   jle @@done;

   mov rax, iWidth;
   test rax, rax;
   jle @@done;

   // xmm7 := 1.0 in every lane, the stand in divisor of a zero norm
   mov eax, $3F800000;
   movd xmm7, eax;
   shufps xmm7, xmm7, 0;

   mov r10, iWidth;             // columns still to do
   xor r11, r11;                // byte offset of the current block

   @@blockloop:
   cmp r10, 4;
   jl @@colscalar;

       // ---- pass 1: the four per column sums of squares
       xorps xmm0, xmm0;
       mov rax, iHeight;
       mov iRows, rax;
       mov rax, r8;
       add rax, r11;

       @@normloop:
           movups xmm1, [rax];
           mulps xmm1, xmm1;
           addps xmm0, xmm1;
           add rax, r9;
       dec iRows;
       jnz @@normloop;

       sqrtps xmm0, xmm0;       // the four norms

       // xmm3 := all ones where the norm is zero, xmm5 := the other lanes
       xorps xmm2, xmm2;
       movaps xmm3, xmm0;
       cmpps xmm3, xmm2, 0;
       movaps xmm5, xmm3;
       pcmpeqd xmm6, xmm6;
       pxor xmm5, xmm6;

       // xmm4 := the divisor actually used: 1.0 where the norm is zero
       movaps xmm4, xmm7;
       andps xmm4, xmm3;
       movaps xmm1, xmm3;
       andnps xmm1, xmm0;
       orps xmm4, xmm1;

       // ---- pass 2: divide every row of the block
       mov rax, iHeight;
       mov iRows, rax;
       mov rax, r8;
       add rax, r11;
       mov rsi, rcx;
       add rsi, r11;

       @@scaleloop:
           movups xmm1, [rax];
           divps xmm1, xmm4;
           andps xmm1, xmm5;    // a zero norm normalizes to zero
           movups [rsi], xmm1;
           add rax, r9;
           add rsi, rdx;
       dec iRows;
       jnz @@scaleloop;

       add r11, 16;
       sub r10, 4;
   jmp @@blockloop;

   // ---- leftover columns, one at a time
   @@colscalar:
   test r10, r10;
   jz @@done;

       @@colloop:
           xorps xmm0, xmm0;
           mov rax, iHeight;
           mov iRows, rax;
           mov rax, r8;
           add rax, r11;

           @@normloopS:
               movss xmm1, [rax];
               mulss xmm1, xmm1;
               addss xmm0, xmm1;
               add rax, r9;
           dec iRows;
           jnz @@normloopS;

           sqrtss xmm0, xmm0;
           xorps xmm2, xmm2;
           ucomiss xmm0, xmm2;
           jp @@scaleCol;       // NaN norm: divide, as the reference does
           jne @@scaleCol;

           mov rsi, rcx;        // zero norm: write zeros down the column
           add rsi, r11;
           mov rax, iHeight;
           mov iRows, rax;

           @@zeroloopS:
               movss [rsi], xmm2;
               add rsi, rdx;
           dec iRows;
           jnz @@zeroloopS;
           jmp @@nextcol;

           @@scaleCol:
           mov rax, iHeight;
           mov iRows, rax;
           mov rax, r8;
           add rax, r11;
           mov rsi, rcx;
           add rsi, r11;

           @@scaleloopS:
               movss xmm1, [rax];
               divss xmm1, xmm0;
               movss [rsi], xmm1;
               add rax, r9;
               add rsi, rdx;
           dec iRows;
           jnz @@scaleloopS;

           @@nextcol:
           add r11, 4;
           dec r10;
       jnz @@colloop;

   @@done:
   mov rsi, iRSI;
end;

// The eight exported names forward to the kernel above for their direction;
// EvenW/OddW and Aligned/UnAligned select nothing, because the kernels cover every
// width with movups.
procedure ASMMatrixNormalizeRowAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);
begin
   ASMMatrixNormalizeRowKernel(dest, destLineWidth, Src, srcLineWidth, unixWidth, unixHeight);
end;
procedure ASMMatrixNormalizeRowUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);
begin
   ASMMatrixNormalizeRowKernel(dest, destLineWidth, Src, srcLineWidth, unixWidth, unixHeight);
end;
procedure ASMMatrixNormalizeRowAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);
begin
   ASMMatrixNormalizeRowKernel(dest, destLineWidth, Src, srcLineWidth, unixWidth, unixHeight);
end;
procedure ASMMatrixNormalizeRowUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);
begin
   ASMMatrixNormalizeRowKernel(dest, destLineWidth, Src, srcLineWidth, unixWidth, unixHeight);
end;
procedure ASMMatrixNormalizeColumnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);
begin
   ASMMatrixNormalizeColumnKernel(dest, destLineWidth, Src, srcLineWidth, unixWidth, unixHeight);
end;
procedure ASMMatrixNormalizeColumnUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);
begin
   ASMMatrixNormalizeColumnKernel(dest, destLineWidth, Src, srcLineWidth, unixWidth, unixHeight);
end;
procedure ASMMatrixNormalizeColumnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);
begin
   ASMMatrixNormalizeColumnKernel(dest, destLineWidth, Src, srcLineWidth, unixWidth, unixHeight);
end;
procedure ASMMatrixNormalizeColumnUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt);
begin
   ASMMatrixNormalizeColumnKernel(dest, destLineWidth, Src, srcLineWidth, unixWidth, unixHeight);
end;

{$ENDIF}

end.
