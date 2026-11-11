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


unit ASMMatrixVectorMultOperationsSinglex64;

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
procedure ASMMatrixVectMultT(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; LineWidthMT, LineWidthV : NativeInt; width, height : NativeInt; alpha, beta : single);
// row streaming body of ASMMatrixVectMultT for a contiguous dest
procedure ASMMatrixVectMultTRowStream(dest, mt1, v : PSingle; width, height, LineWidthMT, LineWidthV : NativeInt; alpha, beta : single); assembler;
procedure ASMMatrixVectMult(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; alpha, beta : single); assembler;

// routines with special input layouts: LineWidthV needs to be sizeof(single)
procedure ASMMatrixVectMultEvenAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; alpha, beta : single); assembler;
procedure ASMMatrixVectMultEvenUnAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle;{$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; alpha, beta : single); assembler;
procedure ASMMatrixVectMultOddUnAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; alpha, beta : single); assembler;

function ASMMatrixVecDotMultUneven( x : PSingle; Y : PSingle; incX : NativeInt; incY : NativeInt;
 {$ifdef UNIX} unixN {$ELSE} N {$ENDIF} : NativeInt) : Single; assembler;
function ASMMatrixVecDotMultUnAligned( x : PSingle; y : PSingle; N : NativeInt ) : single; assembler;
function ASMMatrixVecDotMultAligned( x : PSingle; y : PSingle; N : NativeInt ) : single; assembler;


// destlinewidth needs to be sizeof(single)!
// no speed gain agains amsmatrixVectMultT
// alias of ASMMatrixVectMultT, kept for API compatibility
procedure ASMMatrixVectMultTDestVec(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; LineWidthMT, LineWidthV : NativeInt; width, height : NativeInt; alpha, beta : single);

// rank1 update: A = A + alpha*X*Y' where x and y are vectors. It's assumed that y is sequential
procedure ASMRank1UpdateSeq(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt;
  {$ifdef UNIX}unixX{$ELSE}X{$endif}, {$ifdef UNIX}unixY{$ELSE}Y{$ENDIF} : PSingle; incX, incY : NativeInt; alpha : single);  assembler;
procedure ASMRank1UpdateSeqAligned(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt;
  {$ifdef UNIX}unixX{$ELSE}X{$endif}, {$ifdef UNIX}unixY{$ELSE}Y{$ENDIF} : PSingle; incX, incY : NativeInt; alpha : single);  assembler;


procedure ASMRank1UpdateNonSeq(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt;
  {$ifdef UNIX}unixX{$ELSE}X{$endif}, {$ifdef UNIX}unixY{$ELSE}Y{$ENDIF} : PSingle; incX, incY : NativeInt; alpha : single);  assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure ASMMatrixVectMult(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; alpha, beta : single); assembler;
// note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = v
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
   mov r14, width;

   sub r13, 4;
   js @@foryloopend;

   // init for x := 0 to width - 1:
   @@foryloop:

       // init values:
       xorps xmm0, xmm0;
       xorps xmm1, xmm1;
       xorps xmm2, xmm2;
       xorps xmm3, xmm3;  // res := 0;
       mov rax, r8;       // rax = first matrix element
       mov rbx, r9;       // rbx = first vector element

       mov r10, r14;      // r10 = width
       @@forxloop:
           movss xmm4, [rbx];

           movss xmm5, [rax];
           mulss xmm5, xmm4;
           addss xmm0, xmm5;

           movss xmm5, [rax + rsi];
           mulss xmm5, xmm4;
           addss xmm1, xmm5;

           movss xmm5, [rax + 2*rsi];
           mulss xmm5, xmm4;
           addss xmm2, xmm5;

           add rax, rsi;
           movss xmm5, [rax + 2*rsi];
           mulss xmm5, xmm4;
           addss xmm3, xmm5;
           sub rax, rsi;

           add rax, 4;
           add rbx, rdi;

       dec r10;
       jnz @@forxloop;

       // result building
       // calculate dest = beta*dest + alpha*xmm0
       mulss xmm0, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm0, xmm5;
       movss [rcx], xmm0;
       add rcx, rdx;
       add r8, rsi;              // next mt1 element

       mulss xmm1, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm1, xmm5;
       movss [rcx], xmm1;
       add rcx, rdx;
       add r8, rsi;              // next mt1 element

       mulss xmm2, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm2, xmm5;
       movss [rcx], xmm2;
       add rcx, rdx;
       add r8, rsi;              // next mt1 element

       mulss xmm3, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm3, xmm5;
       movss [rcx], xmm3;
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
       xorps xmm0, xmm0; 
       mov rax, r8;       // rax = first matrix element
       mov rbx, r9;       // rbx = first vector element

       mov r10, r14;      // r10 = width
       @@forxshortloop:
           movss xmm4, [rbx];

           movss xmm5, [rax];
           mulss xmm5, xmm4;
           addss xmm0, xmm5;

           add rax, 4;
           add rbx, rdi;
       dec r10;
       jnz @@forxshortloop;

       // build result

       // calculate dest = beta*dest + alpha*xmm0
       mulss xmm0, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm0, xmm5;
       movss [rcx], xmm0;
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
procedure ASMMatrixVectMultEvenAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; alpha, beta : single); assembler;
// note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = v
var dXMM4, dXMM5, dXMM6 : Array[0..3] of single;
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

   // prolog
   push rbx;
   push rsi;
   push rdi;
   push r12;
   push r13;
   push r14;

   movups dXMM4, xmm4;
   movups dXMM5, xmm5;
   movups dXMM6, xmm6;

   // for the final multiplication
   movss xmm6, alpha;
   movss xmm7, beta;

   // prepare for loop
   mov rsi, LineWidthMT;
   mov rdi, LineWidthV;
   mov r13, height;
   mov r14, width;

   sub r13, 4;
   js @@foryloopend;

   // init for x := 0 to width - 1:
   @@foryloop:

       // init values:
       xorps xmm0, xmm0;
       xorps xmm1, xmm1;
       xorps xmm2, xmm2;
       xorps xmm3, xmm3;  // res := 0;
       mov rax, r8;       // rax = first matrix element
       mov rbx, r9;       // rbx = first vector element

       mov r10, r14;      // r10 = width
       @@forxloop:
           movaps xmm4, [rbx];

           movaps xmm5, [rax];
           mulps xmm5, xmm4;
           addps xmm0, xmm5;

           movaps xmm5, [rax + rsi];
           mulps xmm5, xmm4;
           addps xmm1, xmm5;

           movaps xmm5, [rax + 2*rsi];
           mulps xmm5, xmm4;
           addps xmm2, xmm5;

           add rax, rsi;
           movaps xmm5, [rax + 2*rsi];
           mulps xmm5, xmm4;
           addps xmm3, xmm5;
           sub rax, rsi;

           add rax, 16;
           add rbx, 16;

       sub r10, 4;
       jnz @@forxloop;

       // result building
       haddps xmm0, xmm0; haddps xmm0, xmm0;
       mulss xmm0, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm0, xmm5;
       movss [rcx], xmm0;
       add rcx, rdx;
       add r8, rsi;

       haddps xmm1, xmm1; haddps xmm1, xmm1;
       mulss xmm1, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm1, xmm5;
       movss [rcx], xmm1;
       add rcx, rdx;
       add r8, rsi;

       haddps xmm2, xmm2; haddps xmm2, xmm2;
       mulss xmm2, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm2, xmm5;
       movss [rcx], xmm2;
       add rcx, rdx;
       add r8, rsi;

       haddps xmm3, xmm3; haddps xmm3, xmm3;
       mulss xmm3, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm3, xmm5;
       movss [rcx], xmm3;
       add rcx, rdx;
       add r8, rsi;

       // next rseult
   sub r13, 4;
   jns @@foryloop;

   @@foryloopend:

   add r13, 4;
   jz @@vecend;

   @@foryshortloop:
       // init values:
       xorps xmm0, xmm0;
       mov rax, r8;       // rax = first matrix element
       mov rbx, r9;       // rbx = first vector element

       mov r10, r14;      // r10 = width
       @@forxshortloop:
           movaps xmm4, [rbx];
           movaps xmm5, [rax];
           mulps xmm5, xmm4;
           addps xmm0, xmm5;

           add rax, 16;
           add rbx, 16;
       sub r10, 4;
       jnz @@forxshortloop;

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;
       mulss xmm0, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm0, xmm5;
       movss [rcx], xmm0;

       add rcx, rdx;
       add r8, rsi;

   dec r13;
   jnz @@foryshortloop;

   @@vecend:

   movups xmm4, dXMM4;
   movups xmm5, dXMM5;
   movups xmm6, dXMM6;

   pop r14;
   pop r13;
   pop r12;
   pop rdi;
   pop rsi;
   pop rbx;
end;

procedure ASMMatrixVectMultEvenUnAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; alpha, beta : single); assembler;
// note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = v
var dXMM4, dXMM5, dXMM6 : Array[0..3] of single;
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

   // prolog
   push rbx;
   push rsi;
   push rdi;
   push r12;
   push r13;
   push r14;

   movups dXMM4, xmm4;
   movups dXMM5, xmm5;
   movups dXMM6, xmm6;

   // for the final multiplication
   movss xmm6, alpha;
   movss xmm7, beta;

   // prepare for loop
   mov rsi, LineWidthMT;
   mov rdi, LineWidthV;
   mov r13, height;
   mov r14, width;

   sub r13, 4;
   js @@foryloopend;

   // init for x := 0 to width - 1:
   @@foryloop:

       // init values:
       xorps xmm0, xmm0;
       xorps xmm1, xmm1;
       xorps xmm2, xmm2;
       xorps xmm3, xmm3;  // res := 0;
       mov rax, r8;       // rax = first matrix element
       mov rbx, r9;       // rbx = first vector element

       mov r10, r14;      // r10 = width
       @@forxloop:
           movups xmm4, [rbx];

           movups xmm5, [rax];
           mulps xmm5, xmm4;
           addps xmm0, xmm5;

           movups xmm5, [rax + rsi];
           mulps xmm5, xmm4;
           addps xmm1, xmm5;

           movups xmm5, [rax + 2*rsi];
           mulps xmm5, xmm4;
           addps xmm2, xmm5;

           add rax, rsi;
           movups xmm5, [rax + 2*rsi];
           mulps xmm5, xmm4;
           addps xmm3, xmm5;
           sub rax, rsi;

           add rax, 16;
           add rbx, 16;

       sub r10, 4;
       jnz @@forxloop;

       // result building
       haddps xmm0, xmm0; haddps xmm0, xmm0;
       mulss xmm0, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm0, xmm5;
       movss [rcx], xmm0;
       add rcx, rdx;
       add r8, rsi;

       haddps xmm1, xmm1; haddps xmm1, xmm1;
       mulss xmm1, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm1, xmm5;
       movss [rcx], xmm1;
       add rcx, rdx;
       add r8, rsi;

       haddps xmm2, xmm2; haddps xmm2, xmm2;
       mulss xmm2, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm2, xmm5;
       movss [rcx], xmm2;
       add rcx, rdx;
       add r8, rsi;

       haddps xmm3, xmm3; haddps xmm3, xmm3;
       mulss xmm3, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm3, xmm5;
       movss [rcx], xmm3;
       add rcx, rdx;
       add r8, rsi;

       // next rseult
   sub r13, 4;
   jns @@foryloop;

   @@foryloopend:

   add r13, 4;
   jz @@vecend;

   @@foryshortloop:
       // init values:
       xorps xmm0, xmm0;
       mov rax, r8;       // rax = first matrix element
       mov rbx, r9;       // rbx = first vector element

       mov r10, r14;      // r10 = width
       @@forxshortloop:
           movups xmm4, [rbx];
           movups xmm5, [rax];
           mulps xmm5, xmm4;
           addps xmm0, xmm5;

           add rax, 16;
           add rbx, 16;
       sub r10, 4;
       jnz @@forxshortloop;

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;
       mulss xmm0, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm0, xmm5;
       movss [rcx], xmm0;

       add rcx, rdx;
       add r8, rsi;

   dec r13;
   jnz @@foryshortloop;

   @@vecend:

   movups xmm4, dXMM4;
   movups xmm5, dXMM5;
   movups xmm6, dXMM6;

   pop r14;
   pop r13;
   pop r12;
   pop rdi;
   pop rsi;
   pop rbx;
end;

procedure ASMMatrixVectMultOddUnAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; alpha, beta : single); assembler;
// note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = v
// precondition: (width - 1) is a multiple of 4, i.e. width and 3 = 1; the
// block loop consumes width - 1 elements four at a time and the scalar tail
// adds the last one.
var dXMM4, dXMM5, dXMM6 : Array[0..3] of single;
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

   // prolog
   push rbx;
   push rsi;
   push rdi;
   push r12;
   push r13;
   push r14;

   movups dXMM4, xmm4;
   movups dXMM5, xmm5;
   movups dXMM6, xmm6;

   // for the final multiplication
   movss xmm6, alpha;
   movss xmm7, beta;

   // prepare for loop
   mov rsi, LineWidthMT;
   mov rdi, LineWidthV;
   mov r13, height;
   mov r14, width;

   sub r13, 4;
   js @@foryloopend;

   // init for x := 0 to width - 1:
   @@foryloop:

       // init values:
       xorps xmm0, xmm0;
       xorps xmm1, xmm1;
       xorps xmm2, xmm2;
       xorps xmm3, xmm3;  // res := 0;
       mov rax, r8;       // rax = first matrix element
       mov rbx, r9;       // rbx = first vector element

       mov r10, r14;      // r10 = width
       dec r10;           // the vector loop below handles width - 1
       // A four lane block needs four elements. width = 1 is a legal input for
       // this kernel (width and 3 = 1) but has no block, so the do-while body
       // below must not run at all: it would read three elements that are not
       // there. With width < 5 the tail is the whole row.
       cmp r10, 4;
       jl @@lastonly;
       @@forxloop:
           movups xmm4, [rbx];

           movups xmm5, [rax];
           mulps xmm5, xmm4;
           addps xmm0, xmm5;

           movups xmm5, [rax + rsi];
           mulps xmm5, xmm4;
           addps xmm1, xmm5;

           movups xmm5, [rax + 2*rsi];
           mulps xmm5, xmm4;
           addps xmm2, xmm5;

           add rax, rsi;
           movups xmm5, [rax + 2*rsi];
           mulps xmm5, xmm4;
           addps xmm3, xmm5;
           sub rax, rsi;

           add rax, 16;
           add rbx, 16;

       // jg, not jge: r10 is width - 1 here, so the loop must stop as soon as
       // the remaining element count drops to zero - with jge it ran one block
       // more than exists, reading four elements past the row and the vector.
       sub r10, 4;
       jg @@forxloop;

       @@lastonly:
       // last element handling
       movss xmm4, [rbx];
       
       movss xmm5, [rax];
       mulss xmm5, xmm4;
       addss xmm0, xmm5;

       movss xmm5, [rax + rsi];
       mulss xmm5, xmm4;
       addss xmm1, xmm5;

       movss xmm5, [rax + 2*rsi];
       mulss xmm5, xmm4;
       addss xmm2, xmm5;

       add rax, rsi;
       movss xmm5, [rax + 2*rsi];
       mulss xmm5, xmm4;
       addss xmm3, xmm5;
       sub rax, rsi;

       // result building
       haddps xmm0, xmm0; haddps xmm0, xmm0;
       mulss xmm0, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm0, xmm5;
       movss [rcx], xmm0;
       add rcx, rdx;
       add r8, rsi;

       haddps xmm1, xmm1; haddps xmm1, xmm1;
       mulss xmm1, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm1, xmm5;
       movss [rcx], xmm1;
       add rcx, rdx;
       add r8, rsi;

       haddps xmm2, xmm2; haddps xmm2, xmm2;
       mulss xmm2, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm2, xmm5;
       movss [rcx], xmm2;
       add rcx, rdx;
       add r8, rsi;

       haddps xmm3, xmm3; haddps xmm3, xmm3;
       mulss xmm3, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm3, xmm5;
       movss [rcx], xmm3;
       add rcx, rdx;
       add r8, rsi;

       // next rseult
   sub r13, 4;
   jns @@foryloop;

   @@foryloopend:

   add r13, 4;
   jz @@vecend;

   @@foryshortloop:
       // init values:
       xorps xmm0, xmm0;
       mov rax, r8;       // rax = first matrix element
       mov rbx, r9;       // rbx = first vector element

       // counted scalar tail; lane 0 of xmm0 is what the haddps below folds
       mov r10, r14;      // r10 = width
       @@forxshortloop:
           movss xmm4, [rbx];
           movss xmm5, [rax];
           mulss xmm5, xmm4;
           addss xmm0, xmm5;

           add rax, 4;
           add rbx, 4;
       dec r10;
       jnz @@forxshortloop;

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;
       mulss xmm0, xmm6;
       movss xmm5, [rcx];
       mulss xmm5, xmm7;
       addss xmm0, xmm5;
       movss [rcx], xmm0;

       add rcx, rdx;
       add r8, rsi;

   dec r13;
   jnz @@foryshortloop;

   @@vecend:

   movups xmm4, dXMM4;
   movups xmm5, dXMM5;
   movups xmm6, dXMM6;

   pop r14;
   pop r13;
   pop r12;
   pop rdi;
   pop rsi;
   pop rbx;
end;

// transposed matrix * vector multiplication:
//   dest[col] = beta*dest[col] + alpha * sum(row = 0 .. height-1,
//                                            mt1[row][col] * v[row])
//
// mt1 is height rows of width elements, v holds height elements and dest holds
// width elements, so this is y = beta*y + alpha*A^T*x.
//
// dest is scaled by beta once and then used as the accumulator, so the matrix is
// read once, row after row. A destination that is not contiguous is computed one
// column at a time.
procedure MtxVecMultTStrided(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle;
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

procedure ASMMatrixVectMultTRowStream(dest, mt1, v : PSingle; width, height, LineWidthMT, LineWidthV : NativeInt; alpha, beta : single); assembler;
// dest holds width contiguous elements. Parameters are referenced by name only:
// FPC maps each one to the register or stack slot the calling convention picked,
// so the body needs no ABI specific prologue. It works in rax, rbx, r10, r11 and
// r12-r15 and restores every callee saved register it uses.
var iRBX, iR12, iR13, iR14, iR15 : NativeInt;
asm
   mov iRBX, rbx;
   mov iR12, r12;
   mov iR13, r13;
   mov iR14, r14;
   mov iR15, r15;

   // broadcast alpha and beta for the whole call
   movss xmm6, beta;
   unpcklps xmm6, xmm6;
   unpcklps xmm6, xmm6;

   movss xmm7, alpha;
   unpcklps xmm7, xmm7;
   unpcklps xmm7, xmm7;

   // dest := beta * dest
   mov r12, dest;
   mov r13, width;
   shr r13, 2;
   jz @@scaletail;
   @@scaleloop:
       movups xmm0, [r12];
       mulps xmm0, xmm6;
       movups [r12], xmm0;
       add r12, 16;
   dec r13;
   jnz @@scaleloop;
   @@scaletail:
   mov r13, width;
   and r13, 3;
   jz @@rows;
   @@scaletailloop:
       movss xmm0, [r12];
       mulss xmm0, xmm6;
       movss [r12], xmm0;
       add r12, 4;
   dec r13;
   jnz @@scaletailloop;

   @@rows:
   mov r14, mt1;        // current row of the matrix
   mov r15, v;          // current element of v
   mov r11, height;     // rows left

   @@rowloop:
       // xmm5 := alpha * v[row], four times
       movss xmm5, [r15];
       mulss xmm5, xmm7;
       unpcklps xmm5, xmm5;
       unpcklps xmm5, xmm5;

       mov rax, r14;    // row cursor
       mov rbx, dest;   // dest restarts at its first element every row
       mov r13, width;
       shr r13, 4;      // whole sixteen element blocks
       jz @@blocks4;

       @@loop16:
           movups xmm0, [rax];
           movups xmm1, [rbx];
           mulps xmm0, xmm5;
           addps xmm1, xmm0;
           movups [rbx], xmm1;

           movups xmm0, [rax + 16];
           movups xmm2, [rbx + 16];
           mulps xmm0, xmm5;
           addps xmm2, xmm0;
           movups [rbx + 16], xmm2;

           movups xmm0, [rax + 32];
           movups xmm3, [rbx + 32];
           mulps xmm0, xmm5;
           addps xmm3, xmm0;
           movups [rbx + 32], xmm3;

           movups xmm0, [rax + 48];
           movups xmm4, [rbx + 48];
           mulps xmm0, xmm5;
           addps xmm4, xmm0;
           movups [rbx + 48], xmm4;

           add rax, 64;
           add rbx, 64;
       dec r13;
       jnz @@loop16;

       @@blocks4:
       mov r13, width;
       shr r13, 2;
       and r13, 3;      // trailing whole four element blocks
       jz @@tail;
       @@loop4:
           movups xmm0, [rax];
           movups xmm1, [rbx];
           mulps xmm0, xmm5;
           addps xmm1, xmm0;
           movups [rbx], xmm1;
           add rax, 16;
           add rbx, 16;
       dec r13;
       jnz @@loop4;

       @@tail:
       mov r13, width;
       and r13, 3;      // zero to three leftover elements
       jz @@nextrow;
       @@tailloop:
           movss xmm0, [rax];
           mulss xmm0, xmm5;
           movss xmm1, [rbx];
           addss xmm1, xmm0;
           movss [rbx], xmm1;
           add rax, 4;
           add rbx, 4;
       dec r13;
       jnz @@tailloop;

       @@nextrow:
       add r14, LineWidthMT;
       add r15, LineWidthV;
   dec r11;
   jnz @@rowloop;

   mov rbx, iRBX;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;
end;

procedure ASMMatrixVectMultT(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle;
  LineWidthMT, LineWidthV : NativeInt; width, height : NativeInt; alpha, beta : single);
begin
  if (width <= 0) or (height <= 0) then exit;

  if destLineWidth = SizeOf(Single) then
    ASMMatrixVectMultTRowStream(dest, mt1, v, width, height, LineWidthMT, LineWidthV, alpha, beta)
  else
    MtxVecMultTStrided(dest, destLineWidth, mt1, v, width, height, LineWidthMT, LineWidthV, alpha, beta);
end;


// simple routine... not used any more
// note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = v
procedure ASMMatrixVectMultT1(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; LineWidthMT, LineWidthV : NativeInt; width, height : NativeInt; alpha, beta : single); assembler;
var dXMM6 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14 : NativeInt;
asm
{$IFDEF UNIX}
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

   movups dXMM6, xmm6;

   // for the final multiplication
   movss xmm6, alpha;

   // prepare for loop
   mov rsi, LineWidthMT;
   mov rdi, LineWidthV;
   mov r13, height;
   mov r14, width;

   // init for x := 0 to width - 1:
   @@forxloop:

       // init values:
       xorps xmm3, xmm3;  // res := 0;
       mov rax, r8;       // rax = first matrix element
       mov rbx, r9;       // rbx = first vector element

       mov r10, r13;
       @@foryloop:
           movss xmm1, [rax];
           movss xmm2, [rbx];

           mulss xmm1, xmm2;
           addss xmm3, xmm1;

           add rax, rsi;
           add rbx, rdi;

       dec r10;
       jnz @@foryloop;

       // result building
       // write back result (final addition and compactation)

       // calculate dest = beta*dest + alpha*xmm0
       mulss xmm3, xmm6;
       movss xmm1, [rcx];
       mulss xmm1, beta;

       addss xmm3, xmm1;

       movss [rcx], xmm3;

       // next results:
       add rcx, rdx;   // next dest element
       add r8, 4;                // next mt1 element
   dec r14;
   jnz @@forxloop;

   // epilog pop "stack"
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;

   movups xmm6, dXMM6;
end;


procedure ASMMatrixVectMultTDestVec(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle;
  LineWidthMT, LineWidthV : NativeInt; width, height : NativeInt; alpha, beta : single);
// alias of ASMMatrixVectMultT: the transposed product needs no separate body for a
// contiguous destination, so this old entry point simply forwards.
begin
  ASMMatrixVectMultT(dest, destLineWidth, mt1, v, LineWidthMT, LineWidthV, width, height, alpha, beta);
end;

procedure ASMRank1UpdateSeq(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt;
  {$ifdef UNIX}unixX{$ELSE}X{$endif}, {$ifdef UNIX}unixY{$ELSE}Y{$ENDIF} : PSingle; incX, incY : NativeInt; alpha : single); assembler;
var iRBX, iRSI, iRDI, iR12, iR13, iR14 : NativeInt;
    {$ifdef UNIX}
    X, Y : PSingle;
    {$endif}
asm
   {$IFDEF UNIX}
   mov X, r8;
   mov Y, r9;
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

   mov r12, r8;
   sar r12, 2;   // width div 4

   // performs A = A + alpha*X*Y' in row major form

   mov rdi, X;
   mov r13, Y;

   // for the temp calculation
   movss xmm3, alpha; unpcklps xmm3, xmm3; unpcklps xmm3, xmm3;

   // prepare for loop
   mov rsi, incx;
   // init for y := 0 to height - 1:
   @@foryloop:

      // init values:
      movss xmm0, [rdi]; unpcklps xmm0, xmm0; unpcklps xmm0, xmm0;  // res := 0;
      mulps xmm0, xmm3;     // tmp := alpha*pX^
      mov rax, rcx;         // eax = first destination element A
      mov rbx, r13;           // ebx = first y vector element

      // for j := 0 to width - 1 do
      mov r14, r12;
      test r14, r14;
      jz @@lastElem;

      @@forxloop:
         movups xmm1, [rax];
         movups xmm2, [rbx];

         // pA^[j] := pA^[j] + tmp*pY1^[j];
         mulps xmm2, xmm0;
         addps xmm1, xmm2;

         movups [rax], xmm1;

         add rax, 16;
         add rbx, 16;

      dec r14;
      jnz @@forxloop;

      @@lastElem:
      mov r14, r8;
      and r14, 3;
      jz @@nextline;

      // handle remaining elements scalar
      @@tailLoop:
          movss xmm1, [rax];
          movss xmm2, [rbx];
          mulss xmm2, xmm0;
          addss xmm1, xmm2;
          movss [rax], xmm1;
          
          add rax, 4;
          add rbx, 4;
      dec r14;
      jnz @@tailLoop;

      @@nextline:

      // next results:
      add rdi, rsi;
      add rcx, rdx;
   dec r9;          // r9 = height
   jnz @@foryloop;

   // epilog
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
end;

procedure ASMRank1UpdateNonSeq(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt;
  {$ifdef UNIX}unixX{$ELSE}X{$endif}, {$ifdef UNIX}unixY{$ELSE}Y{$ENDIF} : PSingle; incX, incY : NativeInt; alpha : single);  assembler;
var iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    {$ifdef UNIX}
    X, Y : PSingle;
    {$endif}
asm
   {$IFDEF UNIX}
   mov X, r8;
   mov Y, r9;
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
   mov iR15, r15;

   mov r15, incY;
   mov r12, r8;
   sar r12, 1;   // width div 2

   // performs A = A + alpha*X*Y' in row major form

   mov rdi, X;
   mov r13, Y;

   // for the temp calculation
   movss xmm3, alpha; unpcklps xmm3, xmm3; unpcklps xmm3, xmm3;

   // prepare for loop
   mov rsi, incx;
   // init for y := 0 to height - 1:
   @@foryloop:

      // init values:
      movss xmm0, [rdi]; unpcklps xmm0, xmm0; unpcklps xmm0, xmm0;  // res := 0;
      mulps xmm0, xmm3;     // tmp := alpha*pX^
      mov rax, rcx;         // eax = first destination element A
      mov rbx, r13;           // ebx = first y vector element

      // for j := 0 to width - 1 do
      mov r14, r12;
      test r14, r14;
      jz @@lastElem;

      @@forxloop:
         movlps xmm1, [rax];
         
         // load non-seq Y
         // we need 2 elements. incY is stride.
         movss xmm2, [rbx];
         movss xmm4, [rbx + r15];
         unpcklps xmm2, xmm4; // [Y0, Y1, ?, ?]
         
         // pA^[j] := pA^[j] + tmp*pY1^[j];
         mulps xmm2, xmm0;
         addps xmm1, xmm2;

         movlps [rax], xmm1;

         add rax, 8;
         lea rbx, [rbx + 2*r15]; // advance Y by 2 strides

      dec r14;
      jnz @@forxloop;

      @@lastElem:
      mov r14, r8;
      and r14, 1;
      jz @@nextline;

      @@tailLoop:
          movss xmm1, [rax];
          movss xmm2, [rbx];
          mulss xmm2, xmm0;
          addss xmm1, xmm2;
          movss [rax], xmm1;
          
          add rax, 4;
          add rbx, r15; // increment Y by stride
      dec r14;
      jnz @@tailLoop;

      @@nextline:

      // next results:
      add rdi, rsi;
      add rcx, rdx;
   dec r9;          // r9 = height
   jnz @@foryloop;

   // epilog
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;
end;

procedure ASMRank1UpdateSeqAligned(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt;
  {$ifdef UNIX}unixX{$ELSE}X{$endif}, {$ifdef UNIX}unixY{$ELSE}Y{$ENDIF} : PSingle; incX, incY : NativeInt; alpha : single); assembler;
// note: RCX = A, RDX = LineWidthA, R8 = width, R9 = height
var iRBX, iRSI, iRDI, iR12, iR13, iR14 : NativeInt;
    {$ifdef UNIX}
    X, Y : PSingle;
    {$endif}
asm
   {$IFDEF UNIX}
   mov X, r8;
   mov Y, r9;
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

   mov r12, r8;
   sar r12, 2;   // width div 4

   // performs A = A + alpha*X*Y' in row major form

   mov rdi, X;
   mov r13, Y;

   // for the temp calculation
   movss xmm3, alpha; unpcklps xmm3, xmm3; unpcklps xmm3, xmm3;

   // prepare for loop
   mov rsi, incx;
   // init for y := 0 to height - 1:
   @@foryloop:

      // init values:
      movss xmm0, [rdi]; unpcklps xmm0, xmm0; unpcklps xmm0, xmm0;  // res := 0;
      mulps xmm0, xmm3;     // tmp := alpha*pX^
      mov rax, rcx;         // eax = first destination element A
      mov rbx, r13;           // ebx = first y vector element

      // for j := 0 to width - 1 do
      mov r14, r12;
      test r14, r14;
      jz @@lastElem;

      @@forxloop:
          movaps xmm1, [rax];
          movaps xmm2, [rbx];

          // pA^[j] := pA^[j] + tmp*pY1^[j];
          mulps xmm2, xmm0;
          addps xmm1, xmm2;

          movups [rax], xmm1;

          add rax, 16;
          add rbx, 16;

      dec r14;
      jnz @@forxloop;

      @@lastElem:
      mov r14, r8;
      and r14, 3;
      jz @@nextline;

      @@tailLoop:
          movss xmm1, [rax];
          movss xmm2, [rbx];
          mulss xmm2, xmm0;
          addss xmm1, xmm2;
          movss [rax], xmm1;
          
          add rax, 4;
          add rbx, 4;
      dec r14;
      jnz @@tailLoop;

      @@nextline:

      // next results:
      add rdi, rsi;
      add rcx, rdx;
   dec r9;          // r9 = height
   jnz @@foryloop;

   // epilog
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
end;


function ASMMatrixVecDotMultAligned( x : PSingle; y : PSingle; N : NativeInt ) : single;
// rcx = x, rdx = y, r8 = N
var dXMM4 : TXMMArr;
asm
   {$IFDEF UNIX}
   mov r8, rdx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   movups dXMM4, xmm4;

   // iters
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;
   sub rdx, r8;

   xorps xmm0, xmm0;

   // unrolled loop
   @Loop1:
       add r8, 128;
       jg @loopEnd1;

       movaps xmm1, [rcx + r8 - 128];
       movaps xmm2, [rdx + r8 - 128];
       mulps xmm1, xmm2;
       addps xmm0, xmm1;

       movaps xmm3, [rcx + r8 - 112];
       movaps xmm4, [rdx + r8 - 112];
       mulps xmm3, xmm4;
       addps xmm0, xmm3;

       movaps xmm1, [rcx + r8 - 96];
       movaps xmm2, [rdx + r8 - 96];
       mulps xmm1, xmm2;
       addps xmm0, xmm1;

       movaps xmm3, [rcx + r8 - 80];
       movaps xmm4, [rdx + r8 - 80];
       mulps xmm3, xmm4;
       addps xmm0, xmm3;

       movaps xmm1, [rcx + r8 - 64];
       movaps xmm2, [rdx + r8 - 64];
       mulps xmm1, xmm2;
       addps xmm0, xmm1;

       movaps xmm3, [rcx + r8 - 48];
       movaps xmm4, [rdx + r8 - 48];
       mulps xmm3, xmm4;
       addps xmm0, xmm3;

       movaps xmm1, [rcx + r8 - 32];
       movaps xmm2, [rdx + r8 - 32];
       mulps xmm1, xmm2;
       addps xmm0, xmm1;

       movaps xmm3, [rcx + r8 - 16];
       movaps xmm4, [rdx + r8 - 16];
       mulps xmm3, xmm4;
       addps xmm0, xmm3;
   jmp @Loop1;

   @loopEnd1:

   sub r8, 128;
   jz @loopEnd2;

   // loop to get all fitting into an array of 2
   @loop2:
      add r8, 16;
      jg @loop2End;

      movaps xmm3, [rcx + r8 - 16];
      movaps xmm4, [rdx + r8 - 16];
      mulps xmm3, xmm4;
      addps xmm0, xmm3;
   jmp @loop2;

   @loop2End:

   // handle last element
   sub r8, 16;
   jz @loopEnd2;

   xorps xmm3, xmm3;
   @tailLoop:
      movss xmm1, [rcx + r8];
      movss xmm2, [rdx + r8];
      mulss xmm1, xmm2;
      addss xmm3, xmm1;
      
      add r8, 4;
      jnz @tailLoop;
   
   addss xmm0, xmm3;

   @loopEnd2:

   // build result
   haddps xmm0, xmm0;
   haddps xmm0, xmm0;
   movups xmm4, dXMM4;
end;

function ASMMatrixVecDotMultUnAligned( x : PSingle; y : PSingle; N : NativeInt ) : single;
// rcx = x, rdx = y, r8 = N
var dXMM4 : TXMMArr;
asm
   {$IFDEF UNIX}
   mov r8, rdx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   movups dXMM4, xmm4;

   // iters
   imul r8, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;
   sub rdx, r8;

   xorps xmm0, xmm0;

   // unrolled loop
   @Loop1:
       add r8, 128;
       jg @loopEnd1;

       movups xmm1, [rcx + r8 - 128];
       movups xmm2, [rdx + r8 - 128];
       mulps xmm1, xmm2;
       addps xmm0, xmm1;

       movups xmm3, [rcx + r8 - 112];
       movups xmm4, [rdx + r8 - 112];
       mulps xmm3, xmm4;
       addps xmm0, xmm3;

       movups xmm1, [rcx + r8 - 96];
       movups xmm2, [rdx + r8 - 96];
       mulps xmm1, xmm2;
       addps xmm0, xmm1;

       movups xmm3, [rcx + r8 - 80];
       movups xmm4, [rdx + r8 - 80];
       mulps xmm3, xmm4;
       addps xmm0, xmm3;

       movups xmm1, [rcx + r8 - 64];
       movups xmm2, [rdx + r8 - 64];
       mulps xmm1, xmm2;
       addps xmm0, xmm1;

       movups xmm3, [rcx + r8 - 48];
       movups xmm4, [rdx + r8 - 48];
       mulps xmm3, xmm4;
       addps xmm0, xmm3;

       movups xmm1, [rcx + r8 - 32];
       movups xmm2, [rdx + r8 - 32];
       mulps xmm1, xmm2;
       addps xmm0, xmm1;

       movups xmm3, [rcx + r8 - 16];
       movups xmm4, [rdx + r8 - 16];
       mulps xmm3, xmm4;
       addps xmm0, xmm3;
   jmp @Loop1;

   @loopEnd1:

   sub r8, 128;
   jz @loopEnd2;

   // loop to get all fitting into an array of 2
   @loop2:
      add r8, 16;
      jg @loop2End;

      movups xmm3, [rcx + r8 - 16];
      movups xmm4, [rdx + r8 - 16];
      mulps xmm3, xmm4;
      addps xmm0, xmm3;
   jmp @loop2;

   @loop2End:

   // handle last element
   sub r8, 16;
   jz @loopEnd2;

   xorps xmm3, xmm3;
   @tailLoop:
      movss xmm1, [rcx + r8];
      movss xmm2, [rdx + r8];
      mulss xmm1, xmm2;
      addss xmm3, xmm1;
      
      add r8, 4;
      jnz @tailLoop;
   
   addss xmm0, xmm3;

   @loopEnd2:

   // build result
   haddps xmm0, xmm0;
   haddps xmm0, xmm0;
   movups xmm4, dXMM4;
end;

function ASMMatrixVecDotMultUneven( x : PSingle; Y : PSingle; incX : NativeInt; incY : NativeInt;
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
   xorps xmm0, xmm0;

   test rax, rax;
   jz @loopEnd;
   @loop:
      movss xmm1, [rcx];
      movss xmm2, [rdx];
      mulss xmm1, xmm2;
      addss xmm0, xmm1;

      // next element
      add rcx, r8;
      add rdx, r9;

      // counter
      dec rax;
      jnz @loop;
   @loopEnd:
end;

{$ENDIF}

end.
