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


unit ASMMatrixMultTransposedOperationsSinglex64;

// ##############################################################
// #### Assembler optimized matrix multiplication assuming a transposed second
// #### matrix
// ##############################################################

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

procedure ASMMatrixMultAlignedEvenW1EvenH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixMultAlignedEvenW1EvenH2TransposedMod16(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixMultUnAlignedEvenW1EvenH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

procedure ASMMatrixMultAlignedEvenW1OddH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixMultUnAlignedEvenW1OddH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

procedure ASMMatrixMultAlignedOddW1EvenH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixMultUnAlignedOddW1EvenH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

procedure ASMMatrixMultAlignedOddW1OddH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixMultUnAlignedOddW1OddH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure ASMMatrixMultUnAlignedEvenW1OddH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : int64;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
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

   movups dXMM4, xmm4;

   // iters1 := height2 div 2;
   mov r15, height2;
   shr r15, 1;

   // iters2 := -width1*sizeof(single);
   mov r14, width1;
   shl r14, 2;
   imul r14, -1;

   // LineWidth2_2 := 2*LineWidth2;
   mov r13, LineWidth2;

   mov r12, r13;
   shl r12, 1;

   // prepare matrix pointers - remove constant offset here instead each time in the loop:
   sub r8, r14;
   sub r9, r14;
   mov r10, r9;
   add r10, r13;

   // for y := 0 to height1 - 1:
   mov r11, Height1;
   @@forylabel:
       mov rdi, r9;
       mov rsi, r10;
       mov r13, rcx;

       // for x := 0 to width2 - 1:
       mov rbx, r15;
       cmp rbx, 0;
       je @@fory2labelexit;

       @@fory2label:
           xorps xmm0, xmm0;   // dest^ := 0
           xorps xmm2, xmm2;   // dest + 1 := 0;
           // for idx := 0 to width1 div 2 do
           mov rax, r14;

           @@InnerLoop:
               movups xmm1, [r8 + rax];

               // load 2x2 block
               movups xmm3, [rdi + rax];
               movups xmm4, [rsi + rax];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               // end for idx := 0 to width1 div 2
           add rax, 16;
           jnz @@InnerLoop;

           haddps xmm0, xmm2;
           haddps xmm0, xmm0;

           // store back result
           movlps [r13], xmm0;

           // increment the pointers
           // inc(mt2), inc(dest);
           //add dword ptr [mt2], 8;
           add r13, 8;
           add rdi, r12;
           add rsi, r12;
       // end for x := 0 to width2 - 1
       dec rbx;
       jnz @@fory2label;

       @@fory2labelexit:

       // take care of the last line separatly
       xorps xmm0, xmm0;   // dest^ := 0
       // for idx := 0 to width1 div 2 do
       mov rax, r14;

       @@InnerLoop2:
           movups xmm3, [r8 + rax];
           movups xmm4, [rdi + rax];

           // multiply 2x2 and add
           mulps xmm3, xmm4;
           addps xmm0, xmm3;

           // end for idx := 0 to width1 div 2
       add rax, 16;
       jnz @@InnerLoop2;

       haddps xmm0, xmm0; haddps xmm0, xmm0;

       // store back result
       movss [r13], xmm0;

       // dec(mt2, Width2);
       // inc(PByte(mt1), LineWidth1);
       // inc(PByte(dest), destOffset);
       //mov ebx, bytesWidth2;
       //sub dword ptr [mt2], ebx;
       add r8, LineWidth1;
       add rcx, rdx;

   // end for y := 0 to height1 - 1
   dec r11;
   jnz @@forylabel;

   // epilog - cleanup stack
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;

   movups xmm4, dXMM4;
end;

procedure ASMMatrixMultAlignedEvenW1OddH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : int64;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
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

   movups dXMM4, xmm4;

   // iters1 := height2 div 2;
   mov r15, height2;
   shr r15, 1;

	  // iters2 := -width1*sizeof(single);
   mov r14, width1;
   shl r14, 2;
   imul r14, -1;

   // LineWidth2_2 := 2*LineWidth2;
   mov r13, LineWidth2;

   mov r12, r13;
   shl r12, 1;

			// prepare matrix pointers - remove constant offset here instead each time in the loop:
   sub r8, r14;
   sub r9, r14;
   mov r10, r9;
   add r10, r13;

   // for y := 0 to height1 - 1:
   mov r11, Height1;
   @@forylabel:
       mov rdi, r9;
       mov rsi, r10;
       mov r13, rcx;

       // for x := 0 to width2 - 1:
       mov rbx, r15;
       cmp rbx, 0;
       je @@fory2labelexit;

       @@fory2label:
           xorps xmm0, xmm0;   // dest^ := 0
           xorps xmm2, xmm2;   // dest + 1 := 0;
           // for idx := 0 to width1 div 2 do
           mov rax, r14;

           @@InnerLoop:
               movaps xmm1, [r8 + rax];

               // load 2x2 block
               movaps xmm3, [rdi + rax];
               movaps xmm4, [rsi + rax];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               // end for idx := 0 to width1 div 2
           add rax, 16;
           jnz @@InnerLoop;

           // last add and compact result
           haddps xmm0, xmm2;
           haddps xmm0, xmm0;

           // store back result
           movlps [r13], xmm0;

           // increment the pointers
           // inc(mt2), inc(dest);
           //add dword ptr [mt2], 8;
           add r13, 8;
           add rdi, r12;
           add rsi, r12;
       // end for x := 0 to width2 - 1
       dec rbx;
       jnz @@fory2label;

       @@fory2labelexit:

       // take care of the last line separatly
       xorps xmm0, xmm0;   // dest^ := 0
       // for idx := 0 to width1 div 2 do
       mov rax, r14;

       @@InnerLoop2:
           movaps xmm3, [r8 + rax];

           // multiply 2x2 and add
           mulps xmm3, [rdi + rax];;
           addps xmm0, xmm3;

           // end for idx := 0 to width1 div 2
       add rax, 16;
       jnz @@InnerLoop2;

       haddps xmm0, xmm0; haddps xmm0, xmm0;

       // store back result
       movss [r13], xmm0;

       // dec(mt2, Width2);
       // inc(PByte(mt1), LineWidth1);
       // inc(PByte(dest), destOffset);
       //mov ebx, bytesWidth2;
       //sub dword ptr [mt2], ebx;
       add r8, LineWidth1;
       add rcx, rdx;

   // end for y := 0 to height1 - 1
   dec r11;
   jnz @@forylabel;

   // epilog - cleanup stack
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;

   movups xmm4, dXMM4;
end;

procedure ASMMatrixMultAlignedEvenW1EvenH2TransposedMod16(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : int64;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}

asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
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

   movups dXMM4, xmm4;

   // iters1 := height2 div 2;
   mov r15, height2;
   shr r15, 1;

   // iters2 := -width1*sizeof(single);
   mov r14, width1;
   shl r14, 2;
   imul r14, -1;

   // LineWidth2_2 := 2*LineWidth2;
   mov r13, LineWidth2;

   mov r12, r13;
   shl r12, 1;

   // prepare matrix pointers - remove constant offset here instead each time in the loop:
   sub r8, r14;
   sub r9, r14;
   mov r10, r9;
   add r10, r13;

   // for y := 0 to height1 - 1:
   mov r11, Height1;
   @@forylabel:
       mov rdi, r9;
       mov rsi, r10;
       mov r13, rcx;

       // for x := 0 to width2 - 1:
       mov rbx, r15;
       @@fory2label:
           xorps xmm0, xmm0;   // dest^ := 0
           xorps xmm2, xmm2;   // dest + 1 := 0;
           // for idx := 0 to width1 div 2 do
           mov rax, r14;

           @@InnerLoop:
               // prefetch [ecx + edx + 128];
               // prefetch [edi + edx + 128];
               // prefetch [eax + edx + 128];

               movaps xmm1, [r8 + rax];

               // load 2x2 block
               movaps xmm3, [rdi + rax];
               movaps xmm4, [rsi + rax];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               movaps xmm1, [r8 + rax + 16];

               // load 2x2 block
               movaps xmm3, [rdi + rax + 16];
               movaps xmm4, [rsi + rax + 16];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               movaps xmm1, [r8 + rax + 32];

               // load 2x2 block
               movaps xmm3, [rdi + rax + 32];
               movaps xmm4, [rsi + rax + 32];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               movaps xmm1, [r8 + rax + 48];

               // load 2x2 block
               movaps xmm3, [rdi + rax + 48];
               movaps xmm4, [rsi + rax + 48];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               movaps xmm1, [r8 + rax + 64];

               // load 2x2 block
               movaps xmm3, [rdi + rax + 64];
               movaps xmm4, [rsi + rax + 64];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               movaps xmm1, [r8 + rax + 80];

               // load 2x2 block
               movaps xmm3, [rdi + rax + 80];
               movaps xmm4, [rsi + rax + 80];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               movaps xmm1, [r8 + rax + 96];

               // load 2x2 block
               movaps xmm3, [rdi + rax + 96];
               movaps xmm4, [rsi + rax + 96];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               movaps xmm1, [r8 + rax + 112];

               // load 2x2 block
               movaps xmm3, [rdi + rax + 112];
               movaps xmm4, [rsi + rax + 112];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               // end for idx := 0 to width1 div 2
           add rax, 128;
           jnz @@InnerLoop;

           haddps xmm0, xmm2;
           haddps xmm0, xmm0;

           // store back result
           movlps [r13], xmm0;

           // increment the pointers
           // inc(mt2), inc(dest);
           //add dword ptr [mt2], 8;
           add r13, 8;
           add rdi, r12;
           add rsi, r12;
       // end for x := 0 to width2 - 1
       dec rbx;
       jnz @@fory2label;

       // dec(mt2, Width2);
       // inc(PByte(mt1), LineWidth1);
       // inc(PByte(dest), destOffset);
       //mov ebx, bytesWidth2;
       //sub dword ptr [mt2], ebx;
       add r8, LineWidth1;
       add rcx, rdx;

   // end for y := 0 to height1 - 1
   dec r11;
   jnz @@forylabel;

   // epilog - cleanup stack
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;

   movups xmm4, dXMM4;
end;

// note mt2 is transposed this time -> width1 and width2 must be the same!
procedure ASMMatrixMultAlignedEvenW1EvenH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : int64;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}

asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
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

   movups dXMM4, xmm4;


   // iters1 := height2 div 2;
   mov r15, height2;
   shr r15, 1;

	  // iters2 := -width1*sizeof(single);
   mov r14, width1;
   shl r14, 2;
   imul r14, -1;

   // LineWidth2_2 := 2*LineWidth2;
   mov r13, LineWidth2;

   mov r12, r13;
   shl r12, 1;

			// prepare matrix pointers - remove constant offset here instead each time in the loop:
   sub r8, r14;
   sub r9, r14;
   mov r10, r9;
   add r10, r13;

   // for y := 0 to height1 - 1:
   mov r11, Height1;
   @@forylabel:
       mov rdi, r9;
       mov rsi, r10;
       mov r13, rcx;

       // for x := 0 to width2 - 1:
       mov rbx, r15;
       @@fory2label:
           xorps xmm0, xmm0;   // dest^ := 0
           xorps xmm2, xmm2;   // dest + 1 := 0;
           // for idx := 0 to width1 div 2 do
           mov rax, r14;

           @@InnerLoop:
               movaps xmm1, [r8 + rax];

               // load 2x2 block
               movaps xmm3, [rdi + rax];
               movaps xmm4, [rsi + rax];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               // end for idx := 0 to width1 div 2
           add rax, 16;
           jnz @@InnerLoop;

           // final add and compact result
           haddps xmm0, xmm2;
           haddps xmm0, xmm0;

           // store back result
           movlps [r13], xmm0;

           // increment the pointers
           // inc(mt2), inc(dest);
           //add dword ptr [mt2], 8;
           add r13, 8;
           add rdi, r12;
           add rsi, r12;
       // end for x := 0 to width2 - 1
       dec rbx;
       jnz @@fory2label;

       // dec(mt2, Width2);
       // inc(PByte(mt1), LineWidth1);
       // inc(PByte(dest), destOffset);
       //mov ebx, bytesWidth2;
       //sub dword ptr [mt2], ebx;
       add r8, LineWidth1;
       add rcx, rdx;

   // end for y := 0 to height1 - 1
   dec r11;
   jnz @@forylabel;

   // epilog - cleanup stack
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;

   movups xmm4, dXMM4;
end;

procedure ASMMatrixMultUnAlignedEvenW1EvenH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : int64;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
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

   movups dXMM4, xmm4;

   // iters1 := height2 div 2;
   mov r15, height2;
   shr r15, 1;

	  // iters2 := -width1*sizeof(single);
   mov r14, width1;
   shl r14, 2;
   imul r14, -1;

   // LineWidth2_2 := 2*LineWidth2;
   mov r13, LineWidth2;

   mov r12, r13;
   shl r12, 1;

			// prepare matrix pointers - remove constant offset here instead each time in the loop:
   sub r8, r14;
   sub r9, r14;
   mov r10, r9;
   add r10, r13;

   // for y := 0 to height1 - 1:
   mov r11, Height1;
   @@forylabel:
       mov rdi, r9;
       mov rsi, r10;
       mov r13, rcx;

       // for x := 0 to width2 - 1:
       mov rbx, r15;
       @@fory2label:
           xorps xmm0, xmm0;   // dest^ := 0
           xorps xmm2, xmm2;   // dest + 1 := 0;
           // for idx := 0 to width1 div 2 do
           mov rax, r14;

           @@InnerLoop:
               movups xmm1, [r8 + rax];

               // load 2x2 block
               movups xmm3, [rdi + rax];
               movups xmm4, [rsi + rax];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               // end for idx := 0 to width1 div 2
           add rax, 16;
           jnz @@InnerLoop;

           // final add and compact result
           haddps xmm0, xmm2;
           haddps xmm0, xmm0;

           // store back result
           movlps [r13], xmm0;

           // increment the pointers
           // inc(mt2), inc(dest);
           //add dword ptr [mt2], 8;
           add r13, 8;
           add rdi, r12;
           add rsi, r12;
       // end for x := 0 to width2 - 1
       dec rbx;
       jnz @@fory2label;

       // dec(mt2, Width2);
       // inc(PByte(mt1), LineWidth1);
       // inc(PByte(dest), destOffset);
       //mov ebx, bytesWidth2;
       //sub dword ptr [mt2], ebx;
       add r8, LineWidth1;
       add rcx, rdx;

   // end for y := 0 to height1 - 1
   dec r11;
   jnz @@forylabel;

   // epilog - cleanup stack
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;

   movups xmm4, dXMM4;
end;

procedure ASMMatrixMultUnAlignedOddW1EvenH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : int64;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
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

   movups dXMM4, xmm4;

   // iters1 := height2 div 2;
   mov r15, height2;
   shr r15, 1;

	  // iters2 := -width1*sizeof(single);
   mov r14, width1;
   dec r14;
   shl r14, 2;
   imul r14, -1;

   // LineWidth2_2 := 2*LineWidth2;
   mov r13, LineWidth2;

   mov r12, r13;
   shl r12, 1;

			// prepare matrix pointers - remove constant offset here instead each time in the loop:
   sub r8, r14;
   sub r9, r14;
   mov r10, r9;
   add r10, r13;

   // for y := 0 to height1 - 1:
   mov r11, Height1;
   @@forylabel:
       mov rdi, r9;
       mov rsi, r10;
       mov r13, rcx;

       // for x := 0 to width2 - 1:
       mov rbx, r15;
       @@fory2label:
           xorps xmm0, xmm0;   // dest^ := 0
           xorps xmm2, xmm2;   // dest + 1 := 0;
           // for idx := 0 to width1 div 2 do
           mov rax, r14;

           @@InnerLoop:
               movups xmm1, [r8 + rax];

               // load 2x2 block
               movups xmm3, [rdi + rax];
               movups xmm4, [rsi + rax];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               // end for idx := 0 to width1 div 2
           add rax, 16;
           jnz @@InnerLoop;

           // multiply and add the last element
           movss xmm1, [r8];

           movss xmm3, [rdi];
           movss xmm4, [rsi];

           mulss xmm3, xmm1;
           mulss xmm4, xmm1;

           // final add and compact
           addss xmm0, xmm3;
           addss xmm2, xmm4;
           haddps xmm0, xmm2;
           haddps xmm0, xmm0;

           // store back result
           movlps [r13], xmm0;

           // increment the pointers
           // inc(mt2), inc(dest);
           //add dword ptr [mt2], 8;
           add r13, 8;
           add rdi, r12;
           add rsi, r12;
       // end for x := 0 to width2 - 1
       dec rbx;
       jnz @@fory2label;

       // dec(mt2, Width2);
       // inc(PByte(mt1), LineWidth1);
       // inc(PByte(dest), destOffset);
       //mov ebx, bytesWidth2;
       //sub dword ptr [mt2], ebx;
       add r8, LineWidth1;
       add rcx, rdx;

   // end for y := 0 to height1 - 1
   dec r11;
   jnz @@forylabel;

   // epilog - cleanup stack
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;

   movups xmm4, dXMM4;
end;

procedure ASMMatrixMultAlignedOddW1EvenH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : int64;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
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

   movups dXMM4, xmm4;

   // iters1 := height2 div 2;
   mov r15, height2;
   shr r15, 1;

	  // iters2 := -width1*sizeof(single);
   mov r14, width1;
   dec r14;
   shl r14, 2;
   imul r14, -1;

   // LineWidth2_2 := 2*LineWidth2;
   mov r13, LineWidth2;

   mov r12, r13;
   shl r12, 1;

   // prepare matrix pointers - remove constant offset here instead each time in the loop:
   sub r8, r14;
   sub r9, r14;
   mov r10, r9;
   add r10, r13;

   // for y := 0 to height1 - 1:
   mov r11, Height1;
   @@forylabel:
       mov rdi, r9;
       mov rsi, r10;
       mov r13, rcx;

       // for x := 0 to width2 - 1:
       mov rbx, r15;
       @@fory2label:
           xorps xmm0, xmm0;   // dest^ := 0
           xorps xmm2, xmm2;   // dest + 1 := 0;
           // for idx := 0 to width1 div 2 do
           mov rax, r14;

           @@InnerLoop:
               movaps xmm1, [r8 + rax];

               // load 2x2 block
               movaps xmm3, [rdi + rax];
               movaps xmm4, [rsi + rax];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               // end for idx := 0 to width1 div 2
           add rax, 16;
           jnz @@InnerLoop;

           // multiply and add the last element
           movss xmm1, [r8];

           movss xmm3, [rdi];
           movss xmm4, [rsi];

           mulss xmm3, xmm1;
           mulss xmm4, xmm1;

           // final add and compact result
           addss xmm0, xmm3;
           addss xmm2, xmm4;
           haddps xmm0, xmm2;
           haddps xmm0, xmm0;

           // store back result
           movlps [r13], xmm0;

           // increment the pointers
           // inc(mt2), inc(dest);
           //add dword ptr [mt2], 8;
           add r13, 8;
           add rdi, r12;
           add rsi, r12;
       // end for x := 0 to width2 - 1
       dec rbx;
       jnz @@fory2label;

       // dec(mt2, Width2);
       // inc(PByte(mt1), LineWidth1);
       // inc(PByte(dest), destOffset);
       //mov ebx, bytesWidth2;
       //sub dword ptr [mt2], ebx;
       add r8, LineWidth1;
       add rcx, rdx;

   // end for y := 0 to height1 - 1
   dec r11;
   jnz @@forylabel;

   // epilog - cleanup stack
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;

   movups xmm4, dXMM4;
end;

procedure ASMMatrixMultAlignedOddW1OddH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : int64;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
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

   movups dXMM4, xmm4;

   // iters1 := height2 div 2;
   mov r15, height2;
   shr r15, 1;

	  // iters2 := -(width1 - 1)*sizeof(single);
   mov r14, width1;
   dec r14;
   shl r14, 2;
   imul r14, -1;

   // LineWidth2_2 := 2*LineWidth2;
   mov r13, LineWidth2;

   mov r12, r13;
   shl r12, 1;

   // prepare matrix pointers - remove constant offset here instead each time in the loop:
   sub r8, r14;
   sub r9, r14;
   mov r10, r9;
   add r10, r13;

   // for y := 0 to height1 - 1:
   mov r11, Height1;
   @@forylabel:
       mov rdi, r9;
       mov rsi, r10;
       mov r13, rcx;

       // for x := 0 to width2 - 1:
       mov rbx, r15;
       cmp rbx, 0;
       je @@fory2labelexit;

       @@fory2label:
           xorps xmm0, xmm0;   // dest^ := 0
           xorps xmm2, xmm2;   // dest + 1 := 0;
           // for idx := 0 to width1 div 2 do
           mov rax, r14;

           @@InnerLoop:
               movaps xmm1, [r8 + rax];

               // load 2x2 block
               movaps xmm3, [rdi + rax];
               movaps xmm4, [rsi + rax];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               // end for idx := 0 to width1 div 2
           add rax, 16;
           jnz @@InnerLoop;

           // multiply and add the last element
           movss xmm1, [r8];

           movss xmm3, [rdi];
           movss xmm4, [rsi];

           mulss xmm3, xmm1;
           mulss xmm4, xmm1;

           // final add and compact result
           addss xmm0, xmm3;
           addss xmm2, xmm4;
           haddps xmm0, xmm2;
           haddps xmm0, xmm0;

           // store back result
           movlps [r13], xmm0;

           // increment the pointers
           // inc(mt2), inc(dest);
           //add dword ptr [mt2], 8;
           add r13, 8;
           add rdi, r12;
           add rsi, r12;
       // end for x := 0 to width2 - 1
       dec rbx;
       jnz @@fory2label;

       @@fory2labelexit:

       // take care of the last line separatly
       xorps xmm0, xmm0;   // dest^ := 0
       // for idx := 0 to width1 div 2 do
       mov rax, r14;

       @@InnerLoop2:
           movaps xmm3, [r8 + rax];

           // multiply 2x2 and add
           mulps xmm3, [rdi + rax];;
           addps xmm0, xmm3;

           // end for idx := 0 to width1 div 2
       add rax, 16;
       jnz @@InnerLoop2;

       // multiply and add the last element
       movss xmm1, [r8];
       movss xmm3, [rdi];

       mulss xmm3, xmm1;
       haddps xmm0, xmm0; haddps xmm0, xmm0;
       addss xmm0, xmm3;

       // store back result
       movss [r13], xmm0;

       // dec(mt2, Width2);
       // inc(PByte(mt1), LineWidth1);
       // inc(PByte(dest), destOffset);
       //mov ebx, bytesWidth2;
       //sub dword ptr [mt2], ebx;
       add r8, LineWidth1;
       add rcx, rdx;

   // end for y := 0 to height1 - 1
   dec r11;
   jnz @@forylabel;

   // epilog - cleanup stack
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;

   movups xmm4, dXMM4;
end;

procedure ASMMatrixMultUnAlignedOddW1OddH2Transposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF} : NativeInt;  {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : int64;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
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

   movups dXMM4, xmm4;

   // iters1 := height2 div 2;
   mov r15, height2;
   shr r15, 1;

   // iters2 := -(width1 - 1)*sizeof(single);
   mov r14, width1;
   dec r14;
   shl r14, 2;
   imul r14, -1;

   // LineWidth2_2 := 2*LineWidth2;
   mov r13, LineWidth2;

   mov r12, r13;
   shl r12, 1;

			// prepare matrix pointers - remove constant offset here instead each time in the loop:
   sub r8, r14;
   sub r9, r14;
   mov r10, r9;
   add r10, r13;

   // for y := 0 to height1 - 1:
   mov r11, Height1;
   @@forylabel:
       mov rdi, r9;
       mov rsi, r10;
       mov r13, rcx;

       // for x := 0 to width2 - 1:
       mov rbx, r15;
       cmp rbx, 0;
       je @@fory2labelexit;

       @@fory2label:
           xorps xmm0, xmm0;   // dest^ := 0
           xorps xmm2, xmm2;   // dest + 1 := 0;
           // for idx := 0 to width1 div 2 do
           mov rax, r14;

           @@InnerLoop:
               movups xmm1, [r8 + rax];

               // load 2x2 block
               movups xmm3, [rdi + rax];
               movups xmm4, [rsi + rax];

               // multiply 2x2 and add
               mulps xmm3, xmm1;
               mulps xmm4, xmm1;

               addps xmm0, xmm3;
               addps xmm2, xmm4;

               // end for idx := 0 to width1 div 2
           add rax, 16;
           jnz @@InnerLoop;

           // multiply and add the last element
           movss xmm1, [r8];

           movss xmm3, [rdi];
           movss xmm4, [rsi];

           mulss xmm3, xmm1;
           mulss xmm4, xmm1;

           // compact and final add
           addss xmm0, xmm3;
           addss xmm2, xmm4;
           haddps xmm0, xmm2;
           haddps xmm0, xmm0;

           // store back result
           movlps [r13], xmm0;

           // increment the pointers
           // inc(mt2), inc(dest);
           //add dword ptr [mt2], 8;
           add r13, 8;
           add rdi, r12;
           add rsi, r12;
       // end for x := 0 to width2 - 1
       dec rbx;
       jnz @@fory2label;
       
       @@fory2labelexit:

       // take care of the last line separatly
       xorps xmm0, xmm0;   // dest^ := 0
       // for idx := 0 to width1 div 2 do
       mov rax, r14;

       @@InnerLoop2:
           movups xmm3, [r8 + rax];
           movups xmm4, [rdi + rax];

           // multiply 2x2 and add
           mulps xmm3, xmm4;
           addps xmm0, xmm3;

           // end for idx := 0 to width1 div 2
       add rax, 16;
       jnz @@InnerLoop2;

       // multiply and add the last element
       movss xmm1, [r8];
       movss xmm3, [rdi];

       mulss xmm3, xmm1;
       haddps xmm0, xmm0; haddps xmm0, xmm0;
       addss xmm0, xmm3;

       // store back result
       movss [r13], xmm0;

       // dec(mt2, Width2);
       // inc(PByte(mt1), LineWidth1);
       // inc(PByte(dest), destOffset);
       //mov ebx, bytesWidth2;
       //sub dword ptr [mt2], ebx;
       add r8, LineWidth1;
       add rcx, rdx;

   // end for y := 0 to height1 - 1
   dec r11;
   jnz @@forylabel;

   // epilog - cleanup stack
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;

   movups xmm4, dXMM4;
end;

{$ENDIF}

end.
