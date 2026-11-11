// ###################################################################
// #### This file is part of the vsmath project - a 32-bit, single-
// #### precision (mode objfpc) fork of mrMath:
// ####   https://github.com/mikerabat/mrmath
// ####
// #### Derived from mrMath. Copyright (c) 2017, Michael R. All rights reserved.
// #### Licensed under the Apache License, Version 2.0 - see LICENSE.
// ####
// #### Modifications Copyright 2026 Eudox67.
// #### Ported from double/x64 to 32-bit single precision; converted
// #### to {$mode objfpc}. See NOTICE for details.
// ####
// #### vsmath is an independent fork and is not affiliated with,
// #### endorsed by, or supported by the mrMath project or its author.
// ###################################################################


unit AVXMatrixTransposeOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

procedure AVXMatrixTransposeAligned(dest : PSingle; const destLineWidth : NativeInt; mt : PSingle; const LineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure AVXMatrixTransposeUnaligned(dest : PSingle; const destLineWidth : NativeInt; mt : PSingle; const LineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

// Inplace Trasnposition of an N x N matrix
procedure AVXMatrixTransposeInplace(mt : PSingle; const LineWidth : NativeInt; N : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

// Out of place transposition in 4x4 blocks. Columns and rows below a multiple of
// four are copied element by element, so any width/height works and nothing
// outside mt[0..height-1][0..width-1] / dest[0..width-1][0..height-1] is touched.
procedure AVXMatrixTransposeAligned(dest : PSingle; const destLineWidth : NativeInt;
  mt : PSingle; const LineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = mt, r9 = LineWidth
var iR12, iR13, iR14, iR15, iRSI, iRDI, iRBX : NativeInt;
    iRows, iDest : NativeInt;
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

   // save the callee saved registers we use
   mov iR12, r12;
   mov iR13, r13;
   mov iR14, r14;
   mov iR15, r15;
   mov iRSI, rsi;
   mov iRDI, rdi;
   mov iRBX, rbx;

   sub rsp, $40;
   vmovups [rsp + $00], xmm4;
   vmovups [rsp + $10], xmm5;
   vmovups [rsp + $20], xmm6;
   vmovups [rsp + $30], xmm7;

   mov iDest, rcx;
   mov rax, height;
   mov iRows, rax;

   lea r11, [rdx + rdx*2];        // 3 * destLineWidth
   mov rbx, rdx;
   shl rbx, 2;                    // 4 * destLineWidth

   xor rdi, rdi                   // y offset into dest
   // r8 already holds mt (the ABI prologue above put it there)

   cmp iRows, 4;
   jl @@foryloopend;

   @@foryloop4:
      // the four source rows
      mov r12, r8;
      lea r13, [r12 + r9];
      lea r14, [r13 + r9];
      lea r15, [r14 + r9];

      mov rcx, iDest
      add rcx, rdi
      mov r10, width;

      @@forxloop4:
         cmp r10, 4;
         jl @@forxscalar;

         vmovaps xmm0, [r12];
         vmovaps xmm1, [r13];
         vmovaps xmm2, [r14];
         vmovaps xmm3, [r15];

         vunpcklps xmm4, xmm0, xmm1;   // a0 b0 a1 b1
         vunpckhps xmm5, xmm0, xmm1;   // a2 b2 a3 b3
         vunpcklps xmm6, xmm2, xmm3;   // c0 d0 c1 d1
         vunpckhps xmm7, xmm2, xmm3;   // c2 d2 c3 d3

         vshufps xmm0, xmm4, xmm6, $44;  // a0 b0 c0 d0
         vshufps xmm1, xmm4, xmm6, $EE;  // a1 b1 c1 d1
         vshufps xmm2, xmm5, xmm7, $44;  // a2 b2 c2 d2
         vshufps xmm3, xmm5, xmm7, $EE;  // a3 b3 c3 d3

         vmovaps [rcx], xmm0;
         vmovaps [rcx + rdx], xmm1;
         vmovaps [rcx + rdx*2], xmm2;
         vmovaps [rcx + r11], xmm3;

         add r12, 16;
         add r13, 16;
         add r14, 16;
         add r15, 16;
         add rcx, rbx;
         sub r10, 4;
      jmp @@forxloop4;

      @@forxscalar:
      // the remaining (0..3) columns of this row group
      test r10, r10;
      jz @@nextline4;

      @@forxsloop:
         // one column of four rows: pack the four elements and store them as
         // one block (dest column x is dest[x*destLineWidth + y .. y + 3])
         vmovss xmm0, [r12];
         vmovss xmm1, [r13];
         vmovss xmm2, [r14];
         vmovss xmm3, [r15];
         vunpcklps xmm0, xmm0, xmm1;
         vunpcklps xmm2, xmm2, xmm3;
         vshufps xmm4, xmm0, xmm2, $44;
         vmovups [rcx], xmm4;

         add r12, 4;
         add r13, 4;
         add r14, 4;
         add r15, 4;
         add rcx, rdx;
         dec r10;
      jnz @@forxsloop;

      @@nextline4:
      add rdi, 16;
      mov rax, r9;
      shl rax, 2;
      add r8, rax;
      sub iRows, 4;
      cmp iRows, 4;
   jge @@foryloop4;

   @@foryloopend:
   cmp iRows, 0;
   jle @@endproc;

   // the remaining (0..3) rows, one at a time
   @@foryloop:
      mov r12, r8;
      mov rcx, iDest
      add rcx, rdi
      mov r10, width;
      test r10, r10;
      jz @@nextline;

      @@forxsloop2:
         vmovss xmm0, [r12];
         vmovss [rcx], xmm0;
         add r12, 4;
         add rcx, rdx;
         dec r10;
      jnz @@forxsloop2;

      @@nextline:
      add rdi, 4;
      add r8, r9;
      dec iRows;
   jnz @@foryloop;

   @@endproc:

   // epilog
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;

   vmovups xmm4, [rsp + $00];
   vmovups xmm5, [rsp + $10];
   vmovups xmm6, [rsp + $20];
   vmovups xmm7, [rsp + $30];
   add rsp, $40;
   vzeroupper;
end;


// Unaligned twin: same algorithm, all moves are vmovups
//
// Out of place transposition in 4x4 blocks, element by element below a multiple
// of four, so any width/height works and nothing outside the two matrices is
// touched.
procedure AVXMatrixTransposeUnaligned(dest : PSingle; const destLineWidth : NativeInt;
  mt : PSingle; const LineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = mt, r9 = LineWidth
var iR12, iR13, iR14, iR15, iRSI, iRDI, iRBX : NativeInt;
    iRows, iDest : NativeInt;
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

   // save the callee saved registers we use
   mov iR12, r12;
   mov iR13, r13;
   mov iR14, r14;
   mov iR15, r15;
   mov iRSI, rsi;
   mov iRDI, rdi;
   mov iRBX, rbx;

   sub rsp, $40;
   vmovups [rsp + $00], xmm4;
   vmovups [rsp + $10], xmm5;
   vmovups [rsp + $20], xmm6;
   vmovups [rsp + $30], xmm7;

   mov iDest, rcx;
   mov rax, height;
   mov iRows, rax;

   lea r11, [rdx + rdx*2];        // 3 * destLineWidth
   mov rbx, rdx;
   shl rbx, 2;                    // 4 * destLineWidth

   xor rdi, rdi                   // y offset into dest
   // r8 already holds mt (the ABI prologue above put it there)

   cmp iRows, 4;
   jl @@foryloopend;

   @@foryloop4:
      // the four source rows
      mov r12, r8;
      lea r13, [r12 + r9];
      lea r14, [r13 + r9];
      lea r15, [r14 + r9];

      mov rcx, iDest
      add rcx, rdi
      mov r10, width;

      @@forxloop4:
         cmp r10, 4;
         jl @@forxscalar;

         vmovups xmm0, [r12];
         vmovups xmm1, [r13];
         vmovups xmm2, [r14];
         vmovups xmm3, [r15];

         vunpcklps xmm4, xmm0, xmm1;   // a0 b0 a1 b1
         vunpckhps xmm5, xmm0, xmm1;   // a2 b2 a3 b3
         vunpcklps xmm6, xmm2, xmm3;   // c0 d0 c1 d1
         vunpckhps xmm7, xmm2, xmm3;   // c2 d2 c3 d3

         vshufps xmm0, xmm4, xmm6, $44;  // a0 b0 c0 d0
         vshufps xmm1, xmm4, xmm6, $EE;  // a1 b1 c1 d1
         vshufps xmm2, xmm5, xmm7, $44;  // a2 b2 c2 d2
         vshufps xmm3, xmm5, xmm7, $EE;  // a3 b3 c3 d3

         vmovups [rcx], xmm0;
         vmovups [rcx + rdx], xmm1;
         vmovups [rcx + rdx*2], xmm2;
         vmovups [rcx + r11], xmm3;

         add r12, 16;
         add r13, 16;
         add r14, 16;
         add r15, 16;
         add rcx, rbx;
         sub r10, 4;
      jmp @@forxloop4;

      @@forxscalar:
      // the remaining (0..3) columns of this row group
      test r10, r10;
      jz @@nextline4;

      @@forxsloop:
         // one column of four rows: pack the four elements and store them as
         // one block (dest column x is dest[x*destLineWidth + y .. y + 3])
         vmovss xmm0, [r12];
         vmovss xmm1, [r13];
         vmovss xmm2, [r14];
         vmovss xmm3, [r15];
         vunpcklps xmm0, xmm0, xmm1;
         vunpcklps xmm2, xmm2, xmm3;
         vshufps xmm4, xmm0, xmm2, $44;
         vmovups [rcx], xmm4;

         add r12, 4;
         add r13, 4;
         add r14, 4;
         add r15, 4;
         add rcx, rdx;
         dec r10;
      jnz @@forxsloop;

      @@nextline4:
      add rdi, 16;
      mov rax, r9;
      shl rax, 2;
      add r8, rax;
      sub iRows, 4;
      cmp iRows, 4;
   jge @@foryloop4;

   @@foryloopend:
   cmp iRows, 0;
   jle @@endproc;

   // the remaining (0..3) rows, one at a time
   @@foryloop:
      mov r12, r8;
      mov rcx, iDest
      add rcx, rdi
      mov r10, width;
      test r10, r10;
      jz @@nextline;

      @@forxsloop2:
         vmovss xmm0, [r12];
         vmovss [rcx], xmm0;
         add r12, 4;
         add rcx, rdx;
         dec r10;
      jnz @@forxsloop2;

      @@nextline:
      add rdi, 4;
      add r8, r9;
      dec iRows;
   jnz @@foryloop;

   @@endproc:

   // epilog
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;

   vmovups xmm4, [rsp + $00];
   vmovups xmm5, [rsp + $10];
   vmovups xmm6, [rsp + $20];
   vmovups xmm7, [rsp + $30];
   add rsp, $40;
   vzeroupper;
end;

// simple Inplace Trasnposition of an N x N matrix
procedure AVXMatrixTransposeInplace(mt : PSingle; const LineWidth : NativeInt; N : NativeInt); assembler;
// rcx: mt, rdx, LineWidth, r8: N
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
   // check if N < 2 -> do nothing an a 1x1 matrix
   cmp r8, 2;
   jl @@exitProc;

   // iter: -N*sizeof(Single)
   mov rax, r8;
   imul rax, -4;

   mov r9, rcx;  // pDest1: genptr(mt, 0, 1, linewidth)
   add r9, rdx;

   sub rcx, rax;  // mt + iter

   // for y := 0 to n - 2
   dec r8;
   @@foryloop:

      mov r10, rax; // iter aka x
      add r10, 4;
      mov r11, r9;
      // for x := y + 1 to n-1 do
      @@forxloop:
         vmovss xmm0, [rcx + r10]; 
         vmovss xmm1, [r11]; 

         vmovss [rcx + r10], xmm1; 
         vmovss [r11], xmm0; 

         add r11, rdx;
      add r10, 4;
      jnz @@forxloop;

      add rax, 4;  // iter + sizeof(single);
      //pDest := PConstSingleArr( GenPtr(dest, 0, y, destLineWidth) );
      add rcx, rdx;
      // GenPtr(dest, y, y + 1, destLineWidth);
      add r9, rdx;
      add r9, 4;
   dec r8;
   jnz @@foryloop;

   @@exitProc:

   vzeroupper; 
end;

{$ENDIF}

end.
