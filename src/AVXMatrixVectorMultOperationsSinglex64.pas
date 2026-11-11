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


unit AVXMatrixVectorMultOperationsSinglex64;

// #######################################################
// #### special routines for matrix vector multiplications.
// #######################################################

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

uses MatrixConstSingle;


// transposed matrix*vector product, y = beta*y + alpha*A^T*x: any width,
// height, matrix/vector stride and destination line width are handled.
procedure AVXMatrixVectMultT(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; LineWidthMT, LineWidthV : NativeInt; width, height : NativeInt; alpha, beta : single);
// row streaming body of AVXMatrixVectMultT for a contiguous dest
procedure AVXMatrixVectMultTRowStream(dest, mt1, v : PSingle; width, height, LineWidthMT, LineWidthV : NativeInt; alpha, beta : single); assembler;
procedure AVXMatrixVectMult(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF}, {$ifdef UNIX}unixbeta {$ELSE}beta{$ENDIF} : single); assembler;

// routines with special input layouts: LineWidthV needs to be sizeof(single)
procedure AVXMatrixVectMultAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF}, {$ifdef UNIX}unixbeta {$ELSE}beta{$ENDIF} : single); assembler;
procedure AVXMatrixVectMultUnAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF}, {$ifdef UNIX}unixbeta {$ELSE}beta{$ENDIF} : single); assembler;
// same layout, but 4 elements per block: cheaper than the 8 lane path for
// narrow matrices. Any width is handled by both.
procedure AVXMatrixVectMultOddUnAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; alpha, beta : single); assembler;

// destlinewidth needs to be sizeof(single)!
// no speed gain agains amsmatrixVectMultT
// alias of AVXMatrixVectMultT, kept for API compatibility
procedure AVXMatrixVecMultTDestVec(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; LineWidthMT, LineWidthV : NativeInt; width, height : NativeInt; alpha, beta : single);

function AVXMatrixVecDotMultUneven( x : PSingle; Y : PSingle; incX : NativeInt; incY : NativeInt;
 {$ifdef UNIX} unixN {$ELSE} N {$ENDIF} : NativeInt) : Single; assembler;
function AVXMatrixVecDotMultUnAligned( x : PSingle; y : PSingle; N : NativeInt ) : single; assembler;
function AVXMatrixVecDotMultAligned( x : PSingle; y : PSingle; N : NativeInt ) : single; assembler;


// rank1 update: A = A + alpha*X*Y' where x and y are vectors. It's assumed that y is sequential
procedure AVXRank1UpdateSeq(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt;
  {$ifdef UNIX}unixX{$ELSE}X{$endif}, {$ifdef UNIX}unixY{$ELSE}Y{$ENDIF} : PSingle; incX, incY : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF} : single); assembler;
procedure AVXRank1UpdateSeqAligned(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt;
  {$ifdef UNIX}unixX{$ELSE}X{$endif}, {$ifdef UNIX}unixY{$ELSE}Y{$ENDIF} : PSingle; incX, incY : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF} : single);  // forwards to AVXRank1UpdateSeq


procedure AVXRank1UpdateNonSeq(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt;
  {$ifdef UNIX}unixX{$ELSE}X{$endif}, {$ifdef UNIX}unixY{$ELSE}Y{$ENDIF} : PSingle; incX, incY : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF} : single); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure AVXMatrixVectMult(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF}, {$ifdef UNIX}unixbeta {$ELSE}beta{$ENDIF} : single); assembler;
// note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = v
var dXMM4, dXMM5, dXMM6, dXMM7 : Array[0..3] of single; iter : NativeInt;
    iRBX, iRSI, iRDI, iR12, iR13, iR14 : NativeInt;
    {$ifdef UNIX}
    LineWidthMT, LineWidthV : NativeInt;
    alpha : single;
    beta : single;
    {$endif}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   movss alpha, unixalpha;
   movss beta, unixbeta;
   mov LineWidthMT, r8;
   mov LineWidthV, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // prolog - simulate stack
   movups dXMM4, xmm4;
   movups dXMM5, xmm5;
   movups dXMM6, xmm6;
   movups dXMM7, xmm7;

   mov iRBX, rbx;
   mov iRSI, rsi;
   mov iRDI, rdi;
   mov iR12, r12;
   mov iR13, r13;
   mov iR14, r14;


   // for the final multiplication
   movss xmm6, alpha;
   movss xmm7, beta;

   // prepare for loop
   mov rsi, LineWidthMT;
   mov rdi, LineWidthV;
   mov r13, height;
   mov r14, width; mov rax, r14; dec rax; imul rax, -4; mov iter, rax;

   sub r13, 4;
   js @@foryloopend;

   // init for x := 0 to width - 1:
   @@foryloop:

       // init values:
       vxorps xmm0, xmm0, xmm0;
       vxorps xmm1, xmm1, xmm1;
       vxorps xmm2, xmm2, xmm2;
       vxorps xmm3, xmm3, xmm3; // res := 0;
       mov rax, r8;       // rax = first matrix element
       mov rbx, r9;       // rbx = first vector element

       mov r10, r14;      // r10 = width
       @@forxloop:
           vmovss xmm4, [rbx];

           vmovss xmm5, [rax];
           vmulss xmm5, xmm5, xmm4;
           vaddss xmm0, xmm0, xmm5;

           vmovss xmm5, [rax + rsi];
           vmulss xmm5, xmm5, xmm4;
           vaddss xmm1, xmm1, xmm5;

           vmovss xmm5, [rax + 2*rsi];
           vmulss xmm5, xmm5, xmm4;
           vaddss xmm2, xmm2, xmm5;

           add rax, rsi;
           vmovss xmm5, [rax + 2*rsi];
           vmulss xmm5, xmm5, xmm4;
           vaddss xmm3, xmm3, xmm5;
           sub rax, rsi;

           add rax, 4;
           add rbx, rdi;

       dec r10;
       jnz @@forxloop;

       // result building
       // calculate dest = beta*dest + alpha*xmm0
       vmulss xmm0, xmm0, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm0, xmm0, xmm5;
       vmovss [rcx], xmm0;
       add rcx, rdx;
       add r8, rsi;              // next mt1 element

       vmulss xmm1, xmm1, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm1, xmm1, xmm5;
       vmovss [rcx], xmm1;
       add rcx, rdx;
       add r8, rsi;              // next mt1 element

       vmulss xmm2, xmm2, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm2, xmm2, xmm5;
       vmovss [rcx], xmm2;
       add rcx, rdx;
       add r8, rsi;              // next mt1 element

       vmulss xmm3, xmm3, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm3, xmm3, xmm5;
       vmovss [rcx], xmm3;
       add rcx, rdx;             // next dest element
       add r8, rsi;              // next mt1 element

       // next rseult
   sub r13, 4;
   jns @@foryloop;

   // ###########################################
   // #### Remaining rows (max 4):
   @@foryloopend:
   add r13, 4;
   jz @@vecend;

   @@foryshortloop:
       // init values:
       vxorps xmm0, xmm0, xmm0;
       mov rax, r8;       // rax
       mov rbx, r9;       // rbx

       mov r10, r14;      // r10
       
       @@forxshortloop:
           vmovss xmm4, [rbx];
           vmovss xmm5, [rax];

           vmulss xmm5, xmm5, xmm4;
           vaddss xmm0, xmm0, xmm5;

           add rax, 4;
           add rbx, rdi; // Stride V
       dec r10;
       jnz @@forxshortloop;

       // result building
       vmulss xmm0, xmm0, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm0, xmm0, xmm5;
       vmovss [rcx], xmm0;

       add rcx, rdx;
       add r8, rsi;

   dec r13;
   jnz @@foryshortloop;

   @@vecend:

   // epilog pop "stack"
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;

   movups xmm4, dXMM4;
   movups xmm5, dXMM5;
   movups xmm6, dXMM6;
   movups xmm7, dXMM7;
end;
// routines with special input layouts: LineWidthV needs to be sizeof(single)
procedure AVXMatrixVectMultAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF}, {$ifdef UNIX}unixbeta {$ELSE}beta{$ENDIF} : single); assembler;
// note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = v
var iter : NativeInt; iRBX, iRSI, iRDI, iR12, iR13, iR14 : NativeInt;
    {$ifdef UNIX}
    LineWidthMT, LineWidthV : NativeInt;
    alpha, beta : single;
    {$endif}
asm
   {$IFDEF UNIX}
   mov LineWidthMT, r8;
   mov LineWidthV, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   movss alpha, unixalpha;
   movss beta, unixbeta;
   {$ENDIF}

   // prolog
   mov iRBX, rbx;
   mov iRSI, rsi;
   mov iRDI, rdi;
   mov iR12, r12;
   mov iR13, r13;
   mov iR14, r14;

   sub rsp, $30;
   vmovups [rsp + $00], xmm4;
   vmovups [rsp + $10], xmm5;
   vmovups [rsp + $20], xmm6;

   // for the final multiplication
   movss xmm6, alpha;
   movss xmm7, beta;

   // prepare for loop
   mov rsi, LineWidthMT;
   mov rdi, LineWidthV;
   mov r13, height;
   mov r14, width; mov rax, r14; dec rax; imul rax, -4; mov iter, rax;

   sub r14, 8;
   sub r13, 4;
   js @@foryloopend;

   // the unrolled loop takes 8 elements per iteration (one ymm per row)
   cmp r14, 0;
   jl @@foryloopend;

   // init for x := 0 to width - 1:
   @@foryloop:

       // init values:
       vxorps ymm0, ymm0, ymm0; 
       vxorps ymm1, ymm1, ymm1; 
       vxorps ymm2, ymm2, ymm2; 
       vxorps ymm3, ymm3, ymm3; // res := 0;
       mov rax, r8;       // rax = first matrix element
       mov rbx, r9;       // rbx = first vector element

       mov r10, r14;      // r10 = width
       @@forxloop:
           vmovaps ymm4, [rbx];

           vmulps ymm5, ymm4, [rax];
           vaddps ymm0, ymm0, ymm5;

           vmulps ymm5, ymm4, [rax + rsi];
           vaddps ymm1, ymm1, ymm5;

           vmulps ymm5, ymm4, [rax + 2*rsi];
           vaddps ymm2, ymm2, ymm5;

           add rax, rsi;
           vmulps ymm5, ymm4, [rax + 2*rsi];
           vaddps ymm3, ymm3, ymm5;
           sub rax, rsi;

           add rax, 32;
           add rbx, 32;

sub r10, 8;
       jge @@forxloop;

       vextractf128 xmm4, ymm0, 1;
       vhaddps xmm0, xmm0, xmm4; 
       vextractf128 xmm5, ymm1, 1;
       vhaddps xmm1, xmm1, xmm5; 
       vextractf128 xmm4, ymm2, 1;
       vhaddps xmm2, xmm2, xmm4; 
       vextractf128 xmm5, ymm3, 1;
       vhaddps xmm3, xmm3, xmm5; 

       // special treatment for the last value(s):
add r10, 8;
       jz @@resbuild;

       @@shortloopx:
          vmovss xmm4, [rbx];
          vmovss xmm5, [rax];

          vmulss xmm5, xmm5, xmm4;
          vaddss xmm0, xmm0, xmm5;

          vmovss xmm5, [rax + rsi];
          vmulss xmm5, xmm5, xmm4;
          vaddss xmm1, xmm1, xmm5;

          vmovss xmm5, [rax + 2*rsi];
          vmulss xmm5, xmm5, xmm4;
          vaddss xmm2, xmm2, xmm5;

          add rax, rsi;
          vmovss xmm5, [rax + 2*rsi];
          sub rax, rsi;

          vmulss xmm5, xmm5, xmm4;
          vaddss xmm3, xmm3, xmm5;

          add rax, 4;
          add rbx, 4;
       sub r10, 1;
       jnz @@shortloopx;


       @@resbuild:
       // result building
       
       vhaddps xmm0, xmm0, xmm0;
       vhaddps xmm0, xmm0, xmm0;
       vmulss xmm0, xmm0, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm0, xmm0, xmm5;
       vmovss [rcx], xmm0;
       add rcx, rdx;
       add r8, rsi;

       vhaddps xmm1, xmm1, xmm1;
       vhaddps xmm1, xmm1, xmm1;
       vmulss xmm1, xmm1, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm1, xmm1, xmm5;
       vmovss [rcx], xmm1;
       add rcx, rdx;
       add r8, rsi;

       vhaddps xmm2, xmm2, xmm2;
       vhaddps xmm2, xmm2, xmm2;
       vmulss xmm2, xmm2, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm2, xmm2, xmm5;
       vmovss [rcx], xmm2;
       add rcx, rdx;
       add r8, rsi;

       vhaddps xmm3, xmm3, xmm3;
       vhaddps xmm3, xmm3, xmm3;
       vmulss xmm3, xmm3, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm3, xmm3, xmm5;
       vmovss [rcx], xmm3;
       add rcx, rdx;
       add r8, rsi;

       // next rseult
   sub r13, 4;
   jge @@foryloop;

   // ###########################################
   // #### Remaining rows (max 4 or more if width is <4):
   @@foryloopend:
   add r13, 4;
   jz @@vecend;

   @@foryshortloop:
       // init values:
       vxorps xmm0, xmm0, xmm0;
       mov rax, r8;       // rax
       mov rbx, r9;       // rbx

mov r10, width;    // r10 = width (r14 keeps width - 8)
       
       @@forxshortloop:
           vmovss xmm4, [rbx];
           vmovss xmm5, [rax];

           vmulss xmm5, xmm5, xmm4;
           vaddss xmm0, xmm0, xmm5;

           add rax, 4;
           add rbx, 4; // Contiguous
       dec r10;
       jnz @@forxshortloop;

       // result building
       vmulss xmm0, xmm0, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm0, xmm0, xmm5;
       vmovss [rcx], xmm0;

       add rcx, rdx;
       add r8, rsi;

   dec r13;
   jnz @@foryshortloop;

   @@vecend:

   // epilog pop "stack"
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;

   vmovups xmm4, [rsp + $00];
   vmovups xmm5, [rsp + $10];
   vmovups xmm6, [rsp + $20];
   add rsp, $30;
   vzeroupper;
end;

procedure AVXMatrixVectMultUnAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF}, {$ifdef UNIX}unixbeta {$ELSE}beta{$ENDIF} : single); assembler;
// note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = v
var iter : NativeInt; iRBX, iRSI, iRDI, iR12, iR13, iR14 : NativeInt;
    {$ifdef UNIX}
    LineWidthMT, LineWidthV : NativeInt;
    alpha, beta : single;
    {$endif}
asm
   {$IFDEF UNIX}
   mov LineWidthMT, r8;
   mov LineWidthV, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   movss alpha, unixalpha;
   movss beta, unixbeta;
   {$ENDIF}

   // prolog - simulate stack
   mov iRBX, rbx;
   mov iRSI, rsi;
   mov iRDI, rdi;
   mov iR12, r12;
   mov iR13, r13;
   mov iR14, r14;

   sub rsp, $30;
   vmovups [rsp + $00], xmm4;
   vmovups [rsp + $10], xmm5;
   vmovups [rsp + $20], xmm6;

   // for the final multiplication
   movss xmm6, alpha;
   movss xmm7, beta;

   // prepare for loop
   mov rsi, LineWidthMT;
   mov rdi, LineWidthV;
   mov r13, height;
   mov r14, width; mov rax, r14; dec rax; imul rax, -4; mov iter, rax;

   sub r14, 8;
   sub r13, 4;
   js @@foryloopend;

   // the unrolled loop takes 8 elements per iteration (one ymm per row)
   cmp r14, 0;
   jl @@foryloopend;

   // init for x := 0 to width - 1:
   @@foryloop:

       // init values:
       vxorps ymm0, ymm0, ymm0; 
       vxorps ymm1, ymm1, ymm1; 
       vxorps ymm2, ymm2, ymm2; 
       vxorps ymm3, ymm3, ymm3; // res := 0;
       mov rax, r8;       // rax = first matrix element
       mov rbx, r9;       // rbx = first vector element

       mov r10, r14;      // r10 = width
       @@forxloop:
           vmovups ymm4, [rbx];

           vmovups ymm5, [rax];
           vmulps ymm5, ymm5, ymm4;
           vaddps ymm0, ymm0, ymm5;

           vmovups ymm5, [rax + rsi];
           vmulps ymm5, ymm5, ymm4;
           vaddps ymm1, ymm1, ymm5;

           vmovups ymm5, [rax + 2*rsi];
           vmulps ymm5, ymm5, ymm4;
           vaddps ymm2, ymm2, ymm5;

           add rax, rsi;
           vmovups ymm5, [rax + 2*rsi];
           vmulps ymm5, ymm5, ymm4;
           vaddps ymm3, ymm3, ymm5;
           sub rax, rsi;

           add rax, 32;
           add rbx, 32;

sub r10, 8;
       jge @@forxloop;

       vextractf128 xmm4, ymm0, 1;
       vhaddps xmm0, xmm0, xmm4; 
       vextractf128 xmm5, ymm1, 1;
       vhaddps xmm1, xmm1, xmm5; 
       vextractf128 xmm4, ymm2, 1;
       vhaddps xmm2, xmm2, xmm4; 
       vextractf128 xmm5, ymm3, 1;
       vhaddps xmm3, xmm3, xmm5; 

       // special treatment for the last value(s):
add r10, 8;
       jz @@resbuild;

       @@shortloopx:
          vmovss xmm4, [rbx];
          vmovss xmm5, [rax];

          vmulss xmm5, xmm5, xmm4;
          vaddss xmm0, xmm0, xmm5;

          vmovss xmm5, [rax + rsi];
          vmulss xmm5, xmm5, xmm4;
          vaddss xmm1, xmm1, xmm5;

          vmovss xmm5, [rax + 2*rsi];
          vmulss xmm5, xmm5, xmm4;
          vaddss xmm2, xmm2, xmm5;

          add rax, rsi;
          vmovss xmm5, [rax + 2*rsi];
          sub rax, rsi;

          vmulss xmm5, xmm5, xmm4;
          vaddss xmm3, xmm3, xmm5;

          add rax, 4;
          add rbx, 4;
       sub r10, 1;
       jnz @@shortloopx;

       @@resbuild:
       // result building
       
       vhaddps xmm0, xmm0, xmm0;
       vhaddps xmm0, xmm0, xmm0;
       vmulss xmm0, xmm0, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm0, xmm0, xmm5;
       vmovss [rcx], xmm0;
       add rcx, rdx;
       add r8, rsi;

       vhaddps xmm1, xmm1, xmm1;
       vhaddps xmm1, xmm1, xmm1;
       vmulss xmm1, xmm1, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm1, xmm1, xmm5;
       vmovss [rcx], xmm1;
       add rcx, rdx;
       add r8, rsi;

       vhaddps xmm2, xmm2, xmm2;
       vhaddps xmm2, xmm2, xmm2;
       vmulss xmm2, xmm2, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm2, xmm2, xmm5;
       vmovss [rcx], xmm2;
       add rcx, rdx;
       add r8, rsi;

       vhaddps xmm3, xmm3, xmm3;
       vhaddps xmm3, xmm3, xmm3;
       vmulss xmm3, xmm3, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm3, xmm3, xmm5;
       vmovss [rcx], xmm3;
       add rcx, rdx;
       add r8, rsi;

       // next rseult
   sub r13, 4;
   jge @@foryloop;

   // ###########################################
   // #### Remaining rows (max 4 or more if width is <4):
   @@foryloopend:
   add r13, 4;
   jz @@vecend;

   @@foryshortloop:
       // init values:
       vxorps xmm0, xmm0, xmm0;
       mov rax, r8;       // rax
       mov rbx, r9;       // rbx

mov r10, width;    // r10 = width (r14 keeps width - 8)
       
       @@forxshortloop:
           vmovss xmm4, [rbx];
           vmovss xmm5, [rax];

           vmulss xmm5, xmm5, xmm4;
           vaddss xmm0, xmm0, xmm5;

           add rax, 4;
           add rbx, 4; // Contiguous
       dec r10;
       jnz @@forxshortloop;

       // result building
       vmulss xmm0, xmm0, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm0, xmm0, xmm5;
       vmovss [rcx], xmm0;

       add rcx, rdx;
       add r8, rsi;

   dec r13;
   jnz @@foryshortloop;

   @@vecend:

   // epilog pop "stack"
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;

   vmovups xmm4, [rsp + $00];
   vmovups xmm5, [rsp + $10];
   vmovups xmm6, [rsp + $20];
   add rsp, $30;
   vzeroupper;
end;

procedure AVXMatrixVectMultOddUnAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; alpha, beta : single); assembler;
// note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = v
// any width, four rows at a time: full 4 element blocks plus a scalar tail, so
// no load leaves mt1[0..height-1][0..width-1] or v[0..width-1]
var dXMM4, dXMM5, dXMM6, dXMM7 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14 : NativeInt;
    {$ifdef UNIX}
    LineWidthMT, LineWidthV : NativeInt;
    {$endif}
asm
   {$IFDEF UNIX}
   mov LineWidthMT, r8;
   mov LineWidthV, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // prolog - simulate stack
   mov iRBX, rbx;
   mov iRSI, rsi;
   mov iRDI, rdi;
   mov iR12, r12;
   mov iR13, r13;
   mov iR14, r14;

   movups dXMM4, xmm4;
   movups dXMM5, xmm5;
   movups dXMM6, xmm6;
   movups dXMM7, xmm7;

   // for the final multiplication
   movss xmm6, alpha;
   movss xmm7, beta;

   // prepare for loop
   mov rsi, LineWidthMT;
   mov rdi, LineWidthV;
   mov r13, height;
   mov r14, width;
   lea r11, [rsi + rsi*2];       // offset of the fourth row

   sub r13, 4;
   js @@foryloopend;

   // four rows at a time
   @@foryloop:
       vxorps xmm0, xmm0, xmm0;
       vxorps xmm1, xmm1, xmm1;
       vxorps xmm2, xmm2, xmm2;
       vxorps xmm3, xmm3, xmm3; // res := 0;
       mov rax, r8;       // rax = first matrix element
       mov rbx, r9;       // rbx = first vector element

       mov r10, r14;
       shr r10, 2;        // full 4 element blocks
       jz @@shorttailx;

       @@forxloop:
           vmovups xmm4, [rbx];

           vmovups xmm5, [rax];
           vmulps xmm5, xmm5, xmm4;
           vaddps xmm0, xmm0, xmm5;

           vmovups xmm5, [rax + rsi];
           vmulps xmm5, xmm5, xmm4;
           vaddps xmm1, xmm1, xmm5;

           vmovups xmm5, [rax + rsi*2];
           vmulps xmm5, xmm5, xmm4;
           vaddps xmm2, xmm2, xmm5;

           vmovups xmm5, [rax + r11];
           vmulps xmm5, xmm5, xmm4;
           vaddps xmm3, xmm3, xmm5;

           add rax, 16;
           add rbx, 16;
       dec r10;
       jnz @@forxloop;

       @@shorttailx:
       // up to 3 remaining elements, one at a time
       mov r10, r14;
       and r10, 3;
       jz @@resbuild;

       @@shortloopx:
           vmovss xmm4, [rbx];

           vmovss xmm5, [rax];
           vmulss xmm5, xmm5, xmm4;
           vaddss xmm0, xmm0, xmm5;

           vmovss xmm5, [rax + rsi];
           vmulss xmm5, xmm5, xmm4;
           vaddss xmm1, xmm1, xmm5;

           vmovss xmm5, [rax + rsi*2];
           vmulss xmm5, xmm5, xmm4;
           vaddss xmm2, xmm2, xmm5;

           vmovss xmm5, [rax + r11];
           vmulss xmm5, xmm5, xmm4;
           vaddss xmm3, xmm3, xmm5;

           add rax, 4;
           add rbx, 4;
       dec r10;
       jnz @@shortloopx;

       @@resbuild:
       // calculate dest = beta*dest + alpha*sum
       vhaddps xmm0, xmm0, xmm0;
       vhaddps xmm0, xmm0, xmm0;
       vmulss xmm0, xmm0, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm0, xmm0, xmm5;
       vmovss [rcx], xmm0;
       add rcx, rdx;
       add r8, rsi;

       vhaddps xmm1, xmm1, xmm1;
       vhaddps xmm1, xmm1, xmm1;
       vmulss xmm1, xmm1, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm1, xmm1, xmm5;
       vmovss [rcx], xmm1;
       add rcx, rdx;
       add r8, rsi;

       vhaddps xmm2, xmm2, xmm2;
       vhaddps xmm2, xmm2, xmm2;
       vmulss xmm2, xmm2, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm2, xmm2, xmm5;
       vmovss [rcx], xmm2;
       add rcx, rdx;
       add r8, rsi;

       vhaddps xmm3, xmm3, xmm3;
       vhaddps xmm3, xmm3, xmm3;
       vmulss xmm3, xmm3, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm3, xmm3, xmm5;
       vmovss [rcx], xmm3;
       add rcx, rdx;
       add r8, rsi;

       // next result
   sub r13, 4;
   jns @@foryloop;

   // ###########################################
   // #### Remaining rows (max 3, or all of them if height < 4):
   @@foryloopend:
   add r13, 4;
   jz @@vecend;

   @@foryshortloop:
       vxorps xmm0, xmm0, xmm0;
       mov rax, r8;       // rax
       mov rbx, r9;       // rbx

       mov r10, r14;      // r10 = width
       test r10, r10;
       jz @@rowdone;

       @@forxshortloop:
           vmovss xmm4, [rbx];
           vmovss xmm5, [rax];

           vmulss xmm5, xmm5, xmm4;
           vaddss xmm0, xmm0, xmm5;

           add rax, 4;
           add rbx, 4; // contiguous
       dec r10;
       jnz @@forxshortloop;

       @@rowdone:
       // result building
       vmulss xmm0, xmm0, xmm6;
       vmovss xmm5, [rcx];
       vmulss xmm5, xmm5, xmm7;
       vaddss xmm0, xmm0, xmm5;
       vmovss [rcx], xmm0;

       add rcx, rdx;
       add r8, rsi;

   dec r13;
   jnz @@foryshortloop;

   @@vecend:

   // epilog pop "stack"
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;

   movups xmm4, dXMM4;
   movups xmm5, dXMM5;
   movups xmm6, dXMM6;
   movups xmm7, dXMM7;

   vzeroupper;
end;



// transposed matrix * vector multiplication:
//   dest[col] = beta*dest[col] + alpha * sum(row = 0 .. height-1,
//                                            mt1[row][col] * v[row])
//
// The AVX twin of ASMMatrixVectMultT: eight lanes, one linear pass over the
// matrix, dest used as the accumulator.
procedure AVXMatrixVectMultTStrided(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle;
  width, height, LineWidthMT, LineWidthV : NativeInt; alpha, beta : single);
var col, row : NativeInt;
    Sum : single;
    P : PSingle;
begin
  for col := 0 to width - 1 do
  begin
    Sum := 0;
    for row := 0 to height - 1 do
      Sum := Sum + PSingle(PByte(mt1) + row*LineWidthMT + col*SizeOf(Single))^
                  * PSingle(PByte(v) + row*LineWidthV)^;

    P := PSingle(PByte(dest) + col*destLineWidth);
    P^ := alpha * Sum + beta * P^;
  end;
end;

procedure AVXMatrixVectMultTRowStream(dest, mt1, v : PSingle; width, height, LineWidthMT, LineWidthV : NativeInt; alpha, beta : single); assembler;
// dest holds width contiguous elements. Only rbx and r12-r15 are callee saved, and
// all of them are restored; ymm0-ymm7 are volatile.
var iRBX, iR12, iR13, iR14, iR15 : NativeInt;
    tmp : single;
asm
   mov iRBX, rbx;
   mov iR12, r12;
   mov iR13, r13;
   mov iR14, r14;
   mov iR15, r15;

   // beta has to reach all eight lanes of a ymm register, and a 128-bit shufps
   // would leave the upper half cleared, so it goes through memory: vbroadcastss
   // fills every lane. alpha is only ever used as a scalar factor.
   movss xmm6, beta;
   vmovss [tmp], xmm6;
   vbroadcastss ymm6, [tmp];

   movss xmm7, alpha;

   // dest := beta * dest
   mov r12, dest;
   mov r13, width;
   shr r13, 3;
   jz @@scaletail;
   @@scaleloop:
       vmovups ymm0, [r12];
       vmulps ymm0, ymm0, ymm6;
       vmovups [r12], ymm0;
       add r12, 32;
   dec r13;
   jnz @@scaleloop;
   @@scaletail:
   mov r13, width;
   and r13, 7;
   jz @@rows;
   @@scaletailloop:
       vmovss xmm0, [r12];
       vmulss xmm0, xmm0, xmm6;
       vmovss [r12], xmm0;
       add r12, 4;
   dec r13;
   jnz @@scaletailloop;

   @@rows:
   mov r14, mt1;
   mov r15, v;
   mov r11, height;

   @@rowloop:
       // ymm5 := alpha * v[row], eight times
       vmovss xmm5, [r15];
       vmulss xmm5, xmm5, xmm7;
       vmovss [tmp], xmm5;
       vbroadcastss ymm5, [tmp];

       mov rax, r14;    // row cursor
       mov rbx, dest;   // dest restarts at its first element every row
       mov r13, width;
       shr r13, 5;      // whole thirty-two element blocks
       jz @@blocks8;

       @@loop32:
           vmulps ymm0, ymm5, [rax];
           vmovups ymm1, [rbx];
           vaddps ymm1, ymm1, ymm0;
           vmovups [rbx], ymm1;

           vmulps ymm0, ymm5, [rax + 32];
           vmovups ymm2, [rbx + 32];
           vaddps ymm2, ymm2, ymm0;
           vmovups [rbx + 32], ymm2;

           vmulps ymm0, ymm5, [rax + 64];
           vmovups ymm3, [rbx + 64];
           vaddps ymm3, ymm3, ymm0;
           vmovups [rbx + 64], ymm3;

           vmulps ymm0, ymm5, [rax + 96];
           vmovups ymm4, [rbx + 96];
           vaddps ymm4, ymm4, ymm0;
           vmovups [rbx + 96], ymm4;

           add rax, 128;
           add rbx, 128;
       dec r13;
       jnz @@loop32;

       @@blocks8:
       mov r13, width;
       shr r13, 3;
       and r13, 3;      // trailing whole eight element blocks
       jz @@tail;
       @@loop8:
           vmulps ymm0, ymm5, [rax];
           vmovups ymm1, [rbx];
           vaddps ymm1, ymm1, ymm0;
           vmovups [rbx], ymm1;
           add rax, 32;
           add rbx, 32;
       dec r13;
       jnz @@loop8;

       @@tail:
       mov r13, width;
       and r13, 7;      // zero to seven leftover elements
       jz @@nextrow;
       @@tailloop:
           vmovss xmm0, [rax];
           vmulss xmm0, xmm0, xmm5;
           vmovss xmm1, [rbx];
           vaddss xmm1, xmm1, xmm0;
           vmovss [rbx], xmm1;
           add rax, 4;
           add rbx, 4;
       dec r13;
       jnz @@tailloop;

       @@nextrow:
       add r14, LineWidthMT;
       add r15, LineWidthV;
   dec r11;
   jnz @@rowloop;

   vzeroupper;

   mov rbx, iRBX;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;
end;

procedure AVXMatrixVectMultT(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle;
  LineWidthMT, LineWidthV : NativeInt; width, height : NativeInt; alpha, beta : single);
begin
  if (width <= 0) or (height <= 0) then exit;

  if destLineWidth = SizeOf(Single) then
    AVXMatrixVectMultTRowStream(dest, mt1, v, width, height, LineWidthMT, LineWidthV, alpha, beta)
  else
    AVXMatrixVectMultTStrided(dest, destLineWidth, mt1, v, width, height, LineWidthMT, LineWidthV, alpha, beta);
end;


procedure AVXMatrixVecMultTDestVec(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle;
  LineWidthMT, LineWidthV : NativeInt; width, height : NativeInt; alpha, beta : single);
// alias of AVXMatrixVectMultT: the transposed product needs no separate body for a
// contiguous destination, so this old entry point simply forwards.
begin
  AVXMatrixVectMultT(dest, destLineWidth, mt1, v, LineWidthMT, LineWidthV, width, height, alpha, beta);
end;

procedure AVXRank1UpdateSeq(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt;
  {$ifdef UNIX}unixX{$ELSE}X{$endif}, {$ifdef UNIX}unixY{$ELSE}Y{$ENDIF} : PSingle; incX, incY : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF} : single); assembler;
// rcx = A, rdx = LineWidthA, r8 = width, r9 = height; X, Y, incX, incY and alpha
// are on the stack on linux
//
// Y is sequential: eight lanes of vmovups plus a scalar tail, any width. The row
// factor is broadcast once per row, which keeps the rounding identical to
// RefRank1.
var iRBX, iRDI, iR14 : NativeInt;
    pY : PSingle;
    tmp : single;
    {$ifdef UNIX}
    X, Y : PSingle;
    alpha : single;
    {$endif}
asm
   {$IFDEF UNIX}
   mov X, r8;
   mov Y, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   movss alpha, unixalpha;
   {$ENDIF}

   mov rax, r8;                 // width
   test rax, rax;
   jle @@done;

   mov rax, r9;                 // height
   test rax, rax;
   jle @@done;

   mov iRBX, rbx;
   mov iRDI, rdi;
   mov iR14, r14;

   mov rax, Y;                  // Y restarts at its first element every row
   mov pY, rax;
   mov rdi, X;                  // X advances by incX per row

   movss xmm3, alpha;
   vmovss [tmp], xmm3;
   vbroadcastss ymm3, [tmp];

   @@foryloop:
       // ymm0 := alpha * X[row]
       vmovss xmm0, [rdi];
       vmulss xmm0, xmm0, xmm3;
       vmovss [tmp], xmm0;
       vbroadcastss ymm0, [tmp];

       mov rax, rcx;            // the row of A
       mov rbx, pY;

       mov r14, r8;
       shr r14, 3;              // whole eight element blocks
       jz @@tail;

       @@vecloop:
           vmovups ymm1, [rax];
           vmovups ymm2, [rbx];
           vmulps ymm2, ymm2, ymm0;
           vaddps ymm1, ymm1, ymm2;
           vmovups [rax], ymm1;
           add rax, 32;
           add rbx, 32;
       dec r14;
       jnz @@vecloop;

       @@tail:
       mov r14, r8;
       and r14, 7;              // zero to seven leftover elements
       jz @@nextline;

       @@tailloop:
           vmovss xmm1, [rax];
           vmovss xmm2, [rbx];
           vmulss xmm2, xmm2, xmm0;
           vaddss xmm1, xmm1, xmm2;
           vmovss [rax], xmm1;
           add rax, 4;
           add rbx, 4;
       dec r14;
       jnz @@tailloop;

       @@nextline:
       add rdi, incX;
       add rcx, rdx;
   dec r9;
   jnz @@foryloop;

   vzeroupper;

   mov rbx, iRBX;
   mov rdi, iRDI;
   mov r14, iR14;

   @@done:
end;

procedure AVXRank1UpdateNonSeq(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt;
  {$ifdef UNIX}unixX{$ELSE}X{$endif}, {$ifdef UNIX}unixY{$ELSE}Y{$ENDIF} : PSingle; incX, incY : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF} : single);  assembler;
// rcx = A, rdx = LineWidthA, r8 = width, r9 = height
//
// Y is strided, so there is nothing to vectorise: one element at a time, with
// incY driving the Y walk and incX the X walk. The dispatcher only routes
// element sized increments here (see MatrixRank1Update).
var iRBX, iRDI, iRSI : NativeInt;
    pY : PSingle;
    {$ifdef UNIX}
    X, Y : PSingle;
    alpha : single;
    {$endif}
asm
   {$IFDEF UNIX}
   mov X, r8;
   mov Y, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   movss alpha, unixalpha;
   {$ENDIF}

   mov rax, r8;                 // width
   test rax, rax;
   jle @@done;

   mov rax, r9;                 // height
   test rax, rax;
   jle @@done;

   mov iRBX, rbx;
   mov iRDI, rdi;
   mov iRSI, rsi;

   mov rax, Y;
   mov pY, rax;
   mov rdi, X;
   mov rsi, incY;

   movss xmm3, alpha;

   @@foryloop:
       vmovss xmm0, [rdi];
       vmulss xmm0, xmm0, xmm3;     // tmp := alpha * X[row]

       mov rax, rcx;                // the row of A
       mov rbx, pY;                 // Y restarts every row
       mov r10, r8;                 // columns left

       @@colloop:
           vmovss xmm1, [rax];
           vmovss xmm2, [rbx];
           vmulss xmm2, xmm2, xmm0;
           vaddss xmm1, xmm1, xmm2;
           vmovss [rax], xmm1;
           add rax, 4;
           add rbx, rsi;
       dec r10;
       jnz @@colloop;

       add rdi, incX;
       add rcx, rdx;
   dec r9;
   jnz @@foryloop;

   vzeroupper;

   mov rbx, iRBX;
   mov rdi, iRDI;
   mov rsi, iRSI;

   @@done:
end;

procedure AVXRank1UpdateSeqAligned(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt;
  {$ifdef UNIX}unixX{$ELSE}X{$endif}, {$ifdef UNIX}unixY{$ELSE}Y{$ENDIF} : PSingle; incX, incY : NativeInt; unixalpha : single);
// The aligned twin would only differ in vmovaps versus vmovups, so it forwards.
begin
   AVXRank1UpdateSeq(A, LineWidthA, width, height, unixX, unixY, incX, incY, unixalpha);
end;


function AVXMatrixVecDotMultAligned( x : PSingle; y : PSingle; N : NativeInt ) : single;
// rcx = x, rdx = y, r8 = N
var dXMM4 : TXMMArr;
asm
   {$IFDEF UNIX}
   mov r8, rdx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   vmovups dXMM4, xmm4;

   // iters
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;
   sub rdx, r8;

   vxorps xmm0, xmm0, xmm0; 

   // unrolled loop
   @Loop1:
       add r8, 128;
       jg @loopEnd1;

       vmovaps ymm1, [rcx + r8 - 128];
       vmovaps ymm2, [rdx + r8 - 128];
       vmulps ymm1, ymm1, ymm2;
       vaddps ymm0, ymm0, ymm1;

       vmovaps ymm3, [rcx + r8 - 96];
       vmovaps ymm4, [rdx + r8 - 96];
       vmulps ymm3, ymm3, ymm4;
       vaddps ymm0, ymm0, ymm3;

       vmovaps ymm1, [rcx + r8 - 64];
       vmovaps ymm2, [rdx + r8 - 64];
       vmulps ymm1, ymm1, ymm2;
       vaddps ymm0, ymm0, ymm1;

       vmovaps ymm3, [rcx + r8 - 32];
       vmovaps ymm4, [rdx + r8 - 32];
       vmulps ymm3, ymm3, ymm4;
       vaddps ymm0, ymm0, ymm3;

   jmp @Loop1;

   @loopEnd1:

   vextractf128 xmm1, ymm0, 1;
   vaddps xmm0, xmm0, xmm1;

   sub r8, 128;
   jz @loopEnd2;

   // loop to get all fitting into an array of 2
   @loop2:
      add r8, 16;
      jg @loop2End;

      vmovaps xmm3, [rcx + r8 - 16];
      vmovaps xmm4, [rdx + r8 - 16];
      vmulps xmm3, xmm3, xmm4;
      vaddps xmm0, xmm0, xmm3;
   jmp @loop2;

   @loop2End:

   // handle last element
   sub r8, 16;
   jz @loopEnd2;

   vxorps xmm3, xmm3, xmm3;
   @tailLoop:
      vmovss xmm5, [rcx + r8];
      vmovss xmm4, [rdx + r8];
      vmulss xmm5, xmm5, xmm4;
      vaddss xmm3, xmm3, xmm5;

      add r8, 4;
      jnz @tailLoop;

   vaddss xmm0, xmm0, xmm3;

   @loopEnd2:

   vhaddps xmm0, xmm0, xmm0;
   vhaddps xmm0, xmm0, xmm0;
   vmovups xmm4, dXMM4;
   vzeroupper;
end;

function AVXMatrixVecDotMultUnAligned( x : PSingle; y : PSingle; N : NativeInt ) : single;
// rcx = x, rdx = y, r8 = N
var dXMM4 : TXMMArr;
asm
   {$IFDEF UNIX}
   mov r8, rdx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   vmovups dXMM4, xmm4;

   // iters
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;
   sub rdx, r8;

   vxorps xmm0, xmm0, xmm0; 

   // unrolled loop
   @Loop1:
       add r8, 128;
       jg @loopEnd1;

       vmovups ymm1, [rcx + r8 - 128];
       vmovups ymm2, [rdx + r8 - 128];
       vmulps ymm1, ymm1, ymm2;
       vaddps ymm0, ymm0, ymm1;

       vmovups ymm3, [rcx + r8 - 96];
       vmovups ymm4, [rdx + r8 - 96];
       vmulps ymm3, ymm3, ymm4;
       vaddps ymm0, ymm0, ymm3;

       vmovups ymm1, [rcx + r8 - 64];
       vmovups ymm2, [rdx + r8 - 64];
       vmulps ymm1, ymm1, ymm2;
       vaddps ymm0, ymm0, ymm1;

       vmovups ymm3, [rcx + r8 - 32];
       vmovups ymm4, [rdx + r8 - 32];
       vmulps ymm3, ymm3, ymm4;
       vaddps ymm0, ymm0, ymm3;

   jmp @Loop1;

   @loopEnd1:

   vextractf128 xmm1, ymm0, 1;
   vaddps xmm0, xmm0, xmm1;

   sub r8, 128;
   jz @loopEnd2;

   // loop to get all fitting into an array of 2
   @loop2:
      add r8, 16;
      jg @loop2End;

      vmovups xmm3, [rcx + r8 - 16];
      vmovups xmm4, [rdx + r8 - 16];
      vmulps xmm3, xmm3, xmm4;
      vaddps xmm0, xmm0, xmm3;
   jmp @loop2;

   @loop2End:

   // handle last element
   sub r8, 16;
   jz @loopEnd2;

   vxorps xmm3, xmm3, xmm3;
   @tailLoop:
      vmovss xmm5, [rcx + r8];
      vmovss xmm4, [rdx + r8];
      vmulss xmm5, xmm5, xmm4;
      vaddss xmm3, xmm3, xmm5;

      add r8, 4;
      jnz @tailLoop;

   vaddss xmm0, xmm0, xmm3;

   @loopEnd2:

   vhaddps xmm0, xmm0, xmm0;
   vhaddps xmm0, xmm0, xmm0;
   vmovups xmm4, dXMM4;
   vzeroupper;
end;

function AVXMatrixVecDotMultUneven( x : PSingle; Y : PSingle; incX : NativeInt; incY : NativeInt;
 {$ifdef UNIX} unixN {$ELSE} N {$ENDIF} : NativeInt) : Single;
// rcx = x, rdx = y, r8 = inx, r9 = incy
{$IFDEF UNIX}
var N : NativeInt;
{$ENDIF}
asm
   {$IFDEF UNIX}
   mov N, unixN;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov rax, N;
   vxorps xmm0, xmm0, xmm0; 

   test rax, rax;
   jz @loopEnd;
   @loop:
      vmovss xmm1, [rcx];
      vmovss xmm2, [rdx];
      vmulss xmm1, xmm1, xmm2;
      vaddss xmm0, xmm0, xmm1;

      // next element
      add rcx, r8;
      add rdx, r9;

      // counter
      dec rax;
      jnz @loop;
   @loopEnd:

   vzeroupper;
end;

{$ENDIF}

end.
