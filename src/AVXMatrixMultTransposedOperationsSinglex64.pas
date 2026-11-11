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


unit AVXMatrixMultTransposedOperationsSinglex64;

// ##############################################################
// #### Assembler optimized matrix multiplication assuming a transposed second
// #### matrix
// ##############################################################

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

// Multiply with a transposed second operand:
//
//   dest[y][k] = sum(x = 0..width1 - 1) mt1[y][x] * mt2[k][x]
//
// dest has height1 rows of height2 elements (destLineWidth in bytes), mt1 is
// height1 x width1 and mt2 is height2 x width1. width2 is unused.
//
// Preconditions (the caller has to check them, the kernels assume them):
//   - the *Aligned* variants need 32 byte aligned mt1/mt2 rows,
//   - the Mod16 variants work on four 32 byte blocks per iteration, so width1
//     must be a multiple of 32,
//   - ...EvenH2... needs an even height2, ...OddH2... an odd height2 >= 3.
procedure AVXMatrixMultAlignedTransposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$endif}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$endif} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure AVXMatrixMultAlignedEvenW1EvenH2TransposedMod16(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$endif}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$endif} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure AVXMatrixMultAlignedEvenW1OddH2TransposedMod16(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$endif}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$endif} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure AVXMatrixMultUnAlignedTransposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$endif}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$endif} : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure AVXMatrixMultAlignedEvenW1EvenH2TransposedMod16(dest : PSingle; const destLineWidth : NativeInt;
    mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$endif}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$endif} : NativeInt; 
    width2 : NativeInt; height2 : NativeInt;
    const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : int64;
    {$IFDEF UNIX}
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

   sub rsp, $10;
   vmovups [rsp + $00], xmm4; 

   // iters1 := height2 div 2;
   mov r15, height2;
   shr r15, 1;

   // iters2 := -width1*sizeof(single);
   mov r14, width1;
   imul r14, -4;

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

       // for y2 := 0 to height2 - 1:
       mov rbx, r15;
       @@fory2label:
           vxorps ymm0, ymm0, ymm0; // dest^ := 0
           vxorps ymm2, ymm2, ymm2; // dest + 1 := 0;
           // for idx := 0 to width1 div 2 do
           mov rax, r14;

           // for x := 0 to width1 - 1
           @@InnerLoop:
               // prefetch [ecx + edx + 128];
               // prefetch [edi + edx + 128];
               // prefetch [eax + edx + 128];

               vmovaps ymm1, [r8 + rax]; 

               // multiply 2x2 and add
               vmulps ymm3, ymm1, [rdi + rax]; 
               vmulps ymm4, ymm1, [rsi + rax]; 

               vaddps ymm0, ymm0, ymm3; 
               vaddps ymm2, ymm2, ymm4; 

               vmovaps ymm1, [r8 + rax + 32]; 

               // multiply 2x2 and add
               vmulps ymm3, ymm1, [rdi + rax + 32]; 
               vmulps ymm4, ymm1, [rsi + rax + 32]; 

               vaddps ymm0, ymm0, ymm3; 
               vaddps ymm2, ymm2, ymm4; 

               vmovaps ymm1, [r8 + rax + 64]; 

               // load 2x2 block
               vmovaps ymm3, [rdi + rax + 64]; 
               vmovaps ymm4, [rsi + rax + 64]; 

               // multiply 2x2 and add
               vmulps ymm3, ymm3, ymm1; 
               vmulps ymm4, ymm4, ymm1; 

               vaddps ymm0, ymm0, ymm3; 
               vaddps ymm2, ymm2, ymm4; 

               vmovaps ymm1, [r8 + rax + 96]; 

               // multiply 2x2 and add
               vmulps ymm3, ymm1, [rdi + rax + 96]; 
               vmulps ymm4, ymm1, [rsi + rax + 96]; 

               vaddps ymm0, ymm0, ymm3; 
               vaddps ymm2, ymm2, ymm4; 

               // end for idx := 0 to width1 div 2
           add rax, 128;
           jnz @@InnerLoop;

           vextractf128 xmm1, ymm0, 1; 
           vextractf128 xmm3, ymm2, 1; 

           vhaddps xmm0, xmm0, xmm1; 
           vhaddps xmm2, xmm2, xmm3; 

           vhaddps xmm0, xmm0, xmm0;
           vhaddps xmm2, xmm2, xmm2;
           vhaddps xmm0, xmm0, xmm0;
           vhaddps xmm2, xmm2, xmm2;
           vunpcklps xmm0, xmm0, xmm2;

           // store back result
           vmovlps [r13], xmm0;

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

   vmovups xmm4, [rsp + $00]; 
   add rsp, $10;
   vzeroupper; 
end;

procedure AVXMatrixMultAlignedEvenW1OddH2TransposedMod16(dest : PSingle; const destLineWidth : NativeInt;
    mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$endif}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$endif}, 
    width2 : NativeInt; height2 : NativeInt;
    const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : int64;
    {$IFDEF UNIX}
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

   sub rsp, $10;
   vmovups [rsp + $00], xmm4; 

   // iters1 := height2 div 2;
   mov r15, height2;
   shr r15, 1;

   // iters2 := -width1*sizeof(single);
   mov r14, width1;
   imul r14, -4;

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

       // for y2 := 0 to height2 div 2 - 1:
       mov rbx, r15;
       @@fory2label:
           vxorps ymm0, ymm0, ymm0; // dest^ := 0
           vxorps ymm2, ymm2, ymm2; // dest + 1 := 0;
           // for idx := 0 to width1 div 2 do
           mov rax, r14;

           // for x := 0 to width1 - 1
           @@InnerLoop:
               // prefetch [ecx + edx + 128];
               // prefetch [edi + edx + 128];
               // prefetch [eax + edx + 128];

               vmovaps ymm1, [r8 + rax]; 

               // load 2x2 block
               vmovaps ymm3, [rdi + rax]; 
               vmovaps ymm4, [rsi + rax]; 

               // multiply 2x2 and add
               vmulps ymm3, ymm3, ymm1; 
               vmulps ymm4, ymm4, ymm1; 

               vaddps ymm0, ymm0, ymm3; 
               vaddps ymm2, ymm2, ymm4; 

               vmovaps ymm1, [r8 + rax + 32]; 

               // load 2x2 block
               vmovaps ymm3, [rdi + rax + 32]; 
               vmovaps ymm4, [rsi + rax + 32]; 

               // multiply 2x2 and add
               vmulps ymm3, ymm3, ymm1; 
               vmulps ymm4, ymm4, ymm1; 

               vaddps ymm0, ymm0, ymm3; 
               vaddps ymm2, ymm2, ymm4; 

               vmovaps ymm1, [r8 + rax + 64]; 

               // load 2x2 block
               vmovaps ymm3, [rdi + rax + 64]; 
               vmovaps ymm4, [rsi + rax + 64]; 

               // multiply 2x2 and add
               vmulps ymm3, ymm3, ymm1; 
               vmulps ymm4, ymm4, ymm1; 

               vaddps ymm0, ymm0, ymm3; 
               vaddps ymm2, ymm2, ymm4; 

               vmovaps ymm1, [r8 + rax + 96]; 

               // load 2x2 block
               vmovaps ymm3, [rdi + rax + 96]; 
               vmovaps ymm4, [rsi + rax + 96]; 

               // multiply 2x2 and add
               vmulps ymm3, ymm3, ymm1; 
               vmulps ymm4, ymm4, ymm1; 

               vaddps ymm0, ymm0, ymm3; 
               vaddps ymm2, ymm2, ymm4; 

               // end for idx := 0 to width1 div 2
           add rax, 128;
           jnz @@InnerLoop;

           vextractf128 xmm1, ymm0, 1; 
           vextractf128 xmm3, ymm2, 1; 

           vhaddps xmm0, xmm0, xmm1; 
           vhaddps xmm2, xmm2, xmm3; 

           vhaddps xmm0, xmm0, xmm0;
           vhaddps xmm2, xmm2, xmm2;
           vhaddps xmm0, xmm0, xmm0;
           vhaddps xmm2, xmm2, xmm2;
           vunpcklps xmm0, xmm0, xmm2;

           // store back result
           vmovlps [r13], xmm0;

           // increment the pointers
           // inc(mt2), inc(dest);
           //add dword ptr [mt2], 8;
           add r13, 8;
           add rdi, r12;
           add rsi, r12;
       // end for y := 0 to height2 div 2 - 1
       dec rbx;
       jnz @@fory2label;

       // last odd line:
       vxorps ymm0, ymm0, ymm0; // dest^ := 0
       // for idx := 0 to width1 div 2 do
       mov rax, r14;

       // for x := 0 to width1 - 1
       @@InnerLoop2:
          // prefetch [ecx + edx + 128];
          // prefetch [edi + edx + 128];
          // prefetch [eax + edx + 128];

          vmovaps ymm1, [r8 + rax]; 
          vmovaps ymm3, [rdi + rax]; 

          // multiply 2x2 and add
          vmulps ymm3, ymm3, ymm1; 
          vaddps ymm0, ymm0, ymm3; 

          vmovaps ymm1, [r8 + rax + 32]; 
          vmovaps ymm3, [rdi + rax + 32]; 
          vmulps ymm3, ymm3, ymm1; 
          vaddps ymm0, ymm0, ymm3; 

          vmovaps ymm1, [r8 + rax + 64]; 
          vmovaps ymm3, [rdi + rax + 64]; 
          vmulps ymm3, ymm3, ymm1; 
          vaddps ymm0, ymm0, ymm3; 

          vmovaps ymm1, [r8 + rax + 96]; 
          vmovaps ymm3, [rdi + rax + 96]; 
          vmulps ymm3, ymm3, ymm1; 
          vaddps ymm0, ymm0, ymm3; 

          // end for idx := 0 to width1 div 2
       add rax, 128;
       jnz @@InnerLoop2;

       vextractf128 xmm1, ymm0, 1; 
       vhaddps xmm0, xmm0, xmm1; 
       vhaddps xmm0, xmm0, xmm0;
       vhaddps xmm0, xmm0, xmm0;

       // store back result
       vmovss [r13], xmm0; 

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

   vmovups xmm4, [rsp + $00]; 
   add rsp, $10;
   vzeroupper; 
end;


// note mt2 is transposed this time -> width1 and width2 must be the same!
procedure AVXMatrixMultUnAlignedTransposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle;
   {$ifdef UNIX}unixWidth1{$ELSE}width1{$endif}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$endif} : NativeInt; width2 : NativeInt; height2 : NativeInt;
   const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : int64;
    {$IFDEF UNIX}
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

   sub rsp, $10;
   vmovups [rsp + $00], xmm4; 

   // height 2
   mov r15, height2;

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
       sub rbx, 2;
       jl @@fory2loopend;

       @@fory2label:
           vxorps ymm0, ymm0, ymm0; // dest^ := 0
           vxorps ymm2, ymm2, ymm2; // dest + 1 := 0;
           // for idx := 0 to width1 div 4 do
           mov rax, r14;
           add rax, 32;
           jg @InnerLoopEnd;

           @@InnerLoop:
               vmovups ymm1, [r8 + rax - 32]; 

               // load 2x2 block
               vmovups ymm3, [rdi + rax - 32]; 
               vmovups ymm4, [rsi + rax - 32]; 

               // multiply 2x2 and add
               vmulps ymm3, ymm3, ymm1; 
               vmulps ymm4, ymm4, ymm1; 

               vaddps ymm0, ymm0, ymm3; 
               vaddps ymm2, ymm2, ymm4; 

               // end for idx := 0 to width1 div 2
           add rax, 32;
           jle @@InnerLoop;

           vextractf128 xmm1, ymm0, 1; 
           vextractf128 xmm3, ymm2, 1; 

           vhaddps xmm0, xmm0, xmm1; 
           vhaddps xmm2, xmm2, xmm3; 

           @InnerLoopEnd:

           sub rax, 32;
           jz @@InnerLoopEnd2;

           // do the final few elements
           @@InnerLoop2:
               vmovss xmm1, [r8 + rax]; 

               // load 2x2 block
               vmovss xmm3, [rdi + rax]; 
               vmovss xmm4, [rsi + rax]; 

               // multiply 2x2 and add
               vmulss xmm3, xmm3, xmm1; 
               vmulss xmm4, xmm4, xmm1; 

               vaddss xmm0, xmm0, xmm3; 
               vaddss xmm2, xmm2, xmm4; 

           add rax, 4;
           jnz @@InnerLoop2;

           @@InnerLoopEnd2:

           // final add and compact result
           vhaddps xmm0, xmm0, xmm0;
           vhaddps xmm2, xmm2, xmm2;
           vhaddps xmm0, xmm0, xmm0;
           vhaddps xmm2, xmm2, xmm2;
           vunpcklps xmm0, xmm0, xmm2;

           // store back result
           vmovlps [r13], xmm0;

           // increment the pointers
           // inc(mt2), inc(dest);
           //add dword ptr [mt2], 8;
           add r13, 8;
           add rdi, r12;
           add rsi, r12;
       // end for x := 0 to width2 - 1
       sub rbx, 2;
       jge @@fory2label;

       @@fory2loopend:
       add rbx, 2;

       // test for odd h2
       jz @@NextLine;

       // we have an odd height2 -> special treatment for the last line
       vxorps ymm0, ymm0, ymm0; // dest^ := 0

       // for idx := 0 to width1 div 4 do
       mov rax, r14;
       add rax, 32;
       jg @LastLineInnerLoopEnd;

       @@LastLineInnerLoop:
            vmovups ymm1, [r8 + rax - 32]; 

            // load block
            vmovups ymm3, [rdi + rax - 32]; 

            // multiply and add
            vmulps ymm3, ymm3, ymm1; 

            vaddps ymm0, ymm0, ymm3; 

            // end for idx := 0 to width1 div 2
       add rax, 32;
       jle @@LastLineInnerLoop;

       vextractf128 xmm1, ymm0, 1; 
       vhaddps xmm0, xmm0, xmm1; 

       @LastLineInnerLoopEnd:
       sub rax, 32;
       jz @@LastLineInnerLoopEnd2;

       // do the final few elements
       @@LastLineInnerLoop2:
            vmovss xmm1, [r8 + rax]; 
            vmovss xmm3, [rdi + rax]; 

            // multiply and add
            vmulss xmm3, xmm3, xmm1; 
            vaddss xmm0, xmm0, xmm3; 
       // next element
       add rax, 4;
       jnz @@LastLineInnerLoop2;

       @@LastLineInnerLoopEnd2:

       // final add and compact result
       // final add and compact result (eight lanes need two collapses)
       vhaddps xmm0, xmm0, xmm0;
       vhaddps xmm0, xmm0, xmm0;
       // store back result
       vmovss [r13], xmm0; 

       // ################################################
       // #### next line of mt1
       @@NextLine:
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

   vmovups xmm4, [rsp + $00]; 
   add rsp, $10;
   vzeroupper; 
end;

// note mt2 is transposed this time -> width1 and width2 must be the same!
procedure AVXMatrixMultAlignedTransposed(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle;
  {$ifdef UNIX}unixWidth1{$ELSE}width1{$endif}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$endif} : NativeInt;
  width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : int64;
   {$IFDEF UNIX}
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

   sub rsp, $10;
   vmovups [rsp + $00], xmm4; 

   // height2 helper
   mov r15, height2;

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
       sub rbx, 2;
       jl @@fory2loopend;

       @@fory2label:
           vxorps ymm0, ymm0, ymm0; // dest^ := 0
           vxorps ymm2, ymm2, ymm2; // dest + 1 := 0;

           // for idx := 0 to width1 div 4 do
           mov rax, r14;
           add rax, 32;
           jg @InnerLoopEnd;

           @@InnerLoop:
               vmovaps ymm1, [r8 + rax - 32]; 

               // multiply 2x2 and add
               vmulps ymm3, ymm1, [rdi + rax - 32]; 
               vmulps ymm4, ymm1, [rsi + rax - 32]; 

               vaddps ymm0, ymm0, ymm3; 
               vaddps ymm2, ymm2, ymm4; 

               // end for idx := 0 to width1 div 2
           add rax, 32;
           jle @@InnerLoop;

           vextractf128 xmm1, ymm0, 1; 
           vextractf128 xmm3, ymm2, 1; 

           vhaddps xmm0, xmm0, xmm1; 
           vhaddps xmm2, xmm2, xmm3; 

           @InnerLoopEnd:

           sub rax, 32;
           jz @@InnerLoopEnd2;

           // do the final few elements
           @@InnerLoop2:
               vmovss xmm1, [r8 + rax]; 

               // load 2x2 block
               vmovss xmm3, [rdi + rax]; 
               vmovss xmm4, [rsi + rax]; 

               // multiply 2x2 and add
               vmulss xmm3, xmm3, xmm1; 
               vmulss xmm4, xmm4, xmm1; 

               vaddss xmm0, xmm0, xmm3; 
               vaddss xmm2, xmm2, xmm4; 

           add rax, 4;
           jnz @@InnerLoop2;

           @@InnerLoopEnd2:

           // final add and compact result: a ymm holds eight lanes, so after
           // vextractf128 + vhaddps there are still four partial sums per
           // accumulator - collapse them fully before packing the two results
           vhaddps xmm0, xmm0, xmm0;
           vhaddps xmm2, xmm2, xmm2;
           vhaddps xmm0, xmm0, xmm0;
           vhaddps xmm2, xmm2, xmm2;
           vunpcklps xmm0, xmm0, xmm2;

           // store back result: an xmm store would also write the two columns
           // that the next iteration produces, so only 8 bytes are written
           vmovlps [r13], xmm0;

           // increment the pointers
           // inc(mt2), inc(dest);
           //add dword ptr [mt2], 8;
           add r13, 8;
           add rdi, r12;
           add rsi, r12;
       // end for x := 0 to width2 - 1
       sub rbx, 2;
       jge @@fory2label;

       @@fory2loopend:
       add rbx, 2;

       // test for odd h2
       jz @@NextLine;

       // we have an odd height2 -> special treatment for the last line
       vxorps ymm0, ymm0, ymm0; // dest^ := 0

       // for idx := 0 to width1 div 4 do
       mov rax, r14;
       add rax, 32;
       jg @LastLineInnerLoopEnd;

       @@LastLineInnerLoop:
            vmovaps ymm1, [r8 + rax - 32]; 

            // multiply and add
            vmulps ymm3, ymm1, [rdi + rax - 32]; 

            vaddps ymm0, ymm0, ymm3; 

            // end for idx := 0 to width1 div 2
       add rax, 32;
       jle @@LastLineInnerLoop;

       vextractf128 xmm1, ymm0, 1; 
       vhaddps xmm0, xmm0, xmm1; 

       @LastLineInnerLoopEnd:
       sub rax, 32;
       jz @@LastLineInnerLoopEnd2;

       // do the final few elements
       @@LastLineInnerLoop2:
            vmovss xmm1, [r8 + rax]; 
            vmovss xmm3, [rdi + rax]; 

            // multiply and add
            vmulss xmm3, xmm3, xmm1; 
            vaddss xmm0, xmm0, xmm3; 
       // next element
       add rax, 4;
       jnz @@LastLineInnerLoop2;

       @@LastLineInnerLoopEnd2:

       // final add and compact result (two collapses: eight lanes -> one sum)
       vhaddps xmm0, xmm0, xmm0;
       vhaddps xmm0, xmm0, xmm0;

       // store back result
       vmovss [r13], xmm0; 

       // ################################################
       // #### next line of mt1
       @@NextLine:
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

   vmovups xmm4, [rsp + $00]; 
   add rsp, $10;
   vzeroupper; 
end;

{$ENDIF}

end.
