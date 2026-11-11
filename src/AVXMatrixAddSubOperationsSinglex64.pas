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


unit AVXMatrixAddSubOperationsSinglex64;

// ############################################################
// ##### Matrix addition/subtraction assembler optimized:
// ############################################################

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

procedure AVXMatrixAddAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure AVXMatrixAddUnAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

procedure AVXMatrixSubAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure AVXMatrixSubUnAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

procedure AVXMatrixSubT(A : PSingle; LineWidthA : NativeInt; B : PSingle; LineWidthB : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure AVXMatrixSubVecAlignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure AVXMatrixSubVecAlignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure AVXMatrixSubVecAlignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure AVXMatrixSubVecUnalignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure AVXMatrixSubVecUnalignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure AVXMatrixSubVecUnalignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure AVXMatrixAddVecAlignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure AVXMatrixAddVecAlignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure AVXMatrixAddVecAlignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure AVXMatrixAddVecUnalignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure AVXMatrixAddVecUnalignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure AVXMatrixAddVecUnalignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure AVXMatrixAddAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR12 : NativeInt;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
   // prolog - simulate stack
   mov iRBX, rbx;
   mov iR12, r12;

   //iters := -width*sizeof(single);
   mov r10, width;
   imul r10, -4;

   mov r11, LineWidth1;
   mov r12, LineWidth2;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub r9, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov rbx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetch [r9 + rax];

           // addition:
           vmovaps ymm0, [r8 + rax - 128]; 
           vaddps ymm0, ymm0, [r9 + rax - 128]; 

           vmovaps ymm1, [r8 + rax - 96]; 
           vaddps ymm1, ymm1, [r9 + rax - 96]; 

           vmovaps ymm2, [r8 + rax - 64]; 
           vaddps ymm2, ymm2, [r9 + rax - 64]; 

           vmovaps ymm3, [r8 + rax - 32]; 
           vaddps ymm3, ymm3, [r9 + rax - 32]; 

           vmovaps [rcx + rax - 128], ymm0; 
           vmovaps [rcx + rax - 96], ymm1; 
           vmovaps [rcx + rax - 64], ymm2; 
           vmovaps [rcx + rax - 32], ymm3; 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @@loopEnd2;

           vmovaps xmm0, [r8 + rax - 16]; 
           vaddps xmm0, xmm0, [r9 + rax - 16]; 

           vmovaps [rcx + rax - 16], xmm0; 
       jmp @addforxloop2;

       @@loopEnd2:

       sub rax, 16;
       jz @nextLine;

       vmovss xmm0, [r8 - 8]; 
       vmovss xmm1, [r9 - 8]; 
       vaddss xmm0, xmm0, xmm1; 
       vmovss [rcx - 8], xmm0; 

       @nextLine:

       // next line:
       add r8, r11;
       add r9, r12;
       add rcx, rdx;

   // loop y end
   dec rbx;
   jnz @@addforyloop;

   // epilog
   mov rbx, iRBX;
   mov r12, iR12;
   vzeroupper; 
end;

procedure AVXMatrixAddUnAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR12 : NativeInt;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
   // prolog - simulate stack
   mov iRBX, rbx;
   mov iR12, r12;

   //iters := -width*sizeof(single);
   mov r10, width;
   shl r10, 2;
   imul r10, -1;

   mov r11, LineWidth1;
   mov r12, LineWidth2;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub r9, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov rbx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetch [r9 + rax];

           // addition:
           vmovups ymm0, [r8 + rax - 128]; 
           vmovups ymm1, [r9 + rax - 128]; 
           vaddps ymm0, ymm0, ymm1; 
           vmovups [rcx + rax - 128], ymm0; 

           vmovups ymm0, [r8 + rax - 96]; 
           vmovups ymm1, [r9 + rax - 96]; 
           vaddps ymm0, ymm0, ymm1; 
           vmovups [rcx + rax - 96], ymm0; 

           vmovups ymm0, [r8 + rax - 64]; 
           vmovups ymm1, [r9 + rax - 64]; 
           vaddps ymm0, ymm0, ymm1; 
           vmovups [rcx + rax - 64], ymm0; 

           vmovups ymm0, [r8 + rax - 32]; 
           vmovups ymm1, [r9 + rax - 32]; 
           vaddps ymm0, ymm0, ymm1; 
           vmovups [rcx + rax - 32], ymm0; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @@loopEnd2;

           vmovups xmm0, [r8 + rax - 16]; 
           vmovups xmm1, [r9 + rax - 16]; 
           vaddps xmm0, xmm0, xmm1; 

           vmovups [rcx + rax - 16], xmm0; 
       jmp @addforxloop2;

       @@loopEnd2:

       sub rax, 16;
       jz @nextLine;

       vmovss xmm0, [r8 - 8]; 
       vmovss xmm1, [r9 - 8]; 
       vaddss xmm0, xmm0, xmm1; 
       vmovss [rcx - 8], xmm0; 

       @nextLine:

       // next line:
       add r8, r11;
       add r9, r12;
       add rcx, rdx;

   // loop y end
   dec rbx;
   jnz @@addforyloop;

   // epilog
   mov rbx, iRBX;
   mov r12, iR12;
   vzeroupper; 
end;

procedure AVXMatrixSubAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR12 : NativeInt;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
   // prolog - simulate stack
   mov iRBX, rbx;
   mov iR12, r12;

   //iters := -width*sizeof(single);
   mov r10, width;
   imul r10, -4;

   mov r11, LineWidth1;
   mov r12, LineWidth2;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub r9, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov rbx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetch [r9 + rax];

           // addition:
           vmovaps ymm0, [r8 + rax - 128]; 
           vsubps ymm0, ymm0, [r9 + rax - 128]; 

           vmovaps ymm1, [r8 + rax - 96]; 
           vsubps ymm1, ymm1, [r9 + rax - 96]; 

           vmovaps ymm2, [r8 + rax - 64]; 
           vsubps ymm2, ymm2, [r9 + rax - 64]; 

           vmovaps ymm3, [r8 + rax - 32]; 
           vsubps ymm3, ymm3, [r9 + rax - 32]; 

           vmovaps [rcx + rax - 128], ymm0; 
           vmovaps [rcx + rax - 96], ymm1; 
           vmovaps [rcx + rax - 64], ymm2; 
           vmovaps [rcx + rax - 32], ymm3; 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @@loopEnd2;

           vmovaps xmm0, [r8 + rax - 16]; 
           vsubps xmm0, xmm0, [r9 + rax - 16]; 

           vmovaps [rcx + rax - 16], xmm0; 
       jmp @addforxloop2;

       @@loopEnd2:

       sub rax, 16;
       jz @nextLine;

       vmovss xmm0, [r8 - 8]; 
       vmovss xmm1, [r9 - 8]; 
       vsubss xmm0, xmm0, xmm1; 
       vmovss [rcx - 8], xmm0; 

       @nextLine:

       // next line:
       add r8, r11;
       add r9, r12;
       add rcx, rdx;

   // loop y end
   dec rbx;
   jnz @@addforyloop;

   // epilog
   mov rbx, iRBX;
   mov r12, iR12;
   vzeroupper; 
end;

procedure AVXMatrixSubUnAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iR12 : NativeInt;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
   // prolog - simulate stack
   mov iRBX, rbx;
   mov iR12, r12;

   //iters := -width*sizeof(single);
   mov r10, width;
   imul r10, -4;

   mov r11, LineWidth1;
   mov r12, LineWidth2;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub r9, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov rbx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetch [r9 + rax];

           // addition:
           vmovups ymm0, [r8 + rax - 128]; 
           vmovups ymm1, [r9 + rax - 128]; 
           vsubps ymm0, ymm0, ymm1; 
           vmovups [rcx + rax - 128], ymm0; 

           vmovups ymm0, [r8 + rax - 96]; 
           vmovups ymm1, [r9 + rax - 96]; 
           vsubps ymm0, ymm0, ymm1; 
           vmovups [rcx + rax - 96], ymm0; 

           vmovups ymm0, [r8 + rax - 64]; 
           vmovups ymm1, [r9 + rax - 64]; 
           vsubps ymm0, ymm0, ymm1; 
           vmovups [rcx + rax - 64], ymm0; 

           vmovups ymm0, [r8 + rax - 32]; 
           vmovups ymm1, [r9 + rax - 32]; 
           vsubps ymm0, ymm0, ymm1; 
           vmovups [rcx + rax - 32], ymm0; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @@loopEnd2;

           vmovups xmm0, [r8 + rax - 16]; 
           vmovups xmm1, [r9 + rax - 16]; 
           vsubps xmm0, xmm0, xmm1; 

           vmovups [rcx + rax - 16], xmm0; 
       jmp @addforxloop2;

       @@loopEnd2:

       sub rax, 16;
       jz @nextLine;

       vmovss xmm0, [r8 - 8]; 
       vmovss xmm1, [r9 - 8]; 
       vsubss xmm0, xmm0, xmm1; 
       vmovss [rcx - 8], xmm0; 

       @nextLine:

       // next line:
       add r8, r11;
       add r9, r12;
       add rcx, rdx;

   // loop y end
   dec rbx;
   jnz @@addforyloop;

   // epilog
   mov rbx, iRBX;
   mov r12, iR12;
   vzeroupper; 
end;

procedure AVXMatrixSubT(A : PSingle; LineWidthA : NativeInt; B : PSingle; LineWidthB : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var iRBX : NativeInt;
    {$ifdef UNIX}
    width : NativeInt;
    height : NativeInt;
    {$ENDIF}
// rcx : A, rdx : LineWidthA, r8 : B, r9 : LineWidthB;
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
   // maintain stack
   mov iRBX, rbx;

   // rax: iter := -width*sizeof(single)
   mov rcx, A;
   mov rax, width;
   imul rax, -4;
   sub rcx, rax;

   // for y := 0 to height - 1
   @@foryloop:
      mov r10, r8;
      mov rbx, rax;
              // for x := 0 to width - 1
      @@forxloop:
         vmovss xmm0, [rcx + rbx]; 
         vmovss xmm1, [r10]; 
         vsubss xmm0, xmm0, xmm1; 
         vmovss [rcx + rbx], xmm0; 

         add r10, r9;
      add rbx, 4;
      jnz @@forxloop;

      add rcx, rdx;
      add r8, 4;
   dec height;
   jnz @@foryloop;

   // epilog
   mov rbx, iRBX;
   vzeroupper; 
end;

// ########################################################
// #### Matrix add, sub to vector operations
// ########################################################

procedure AVXMatrixSubVecAlignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
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
   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r10;

   @@foryloop:
      mov rax, r10;

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         vmovaps ymm0, [rcx + rax - 64]; 
         vsubps ymm0, ymm0, [r8 + rax - 64]; 
         vmovaps [rcx + rax - 64], ymm0; 

         vmovaps ymm2, [rcx + rax - 32]; 
         vsubps ymm2, ymm2, [r8 + rax - 32]; 
         vmovaps [rcx + rax - 32], ymm2; 

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         vmovss xmm0, [rcx + rax]; 
         vmovss xmm1, [r8 + rax]; 

         vsubss xmm0, xmm0, xmm1; 
         vmovss [rcx + rax], xmm0; 

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;

   vzeroupper; 
end;

procedure AVXMatrixSubVecAlignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var vecIter : NativeInt;
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
   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r11, width;

   imul r11, r9;
   imul r11, -1;
   mov vecIter, r11;

   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r11;

   @@foryloop:
      mov rax, r10;
      mov r11, vecIter;

      @@forxloop:
         vmovss xmm0, [rcx + rax]; 
         vmovss xmm1, [r8 + r11]; 

         vsubss xmm0, xmm0, xmm1; 
         vmovss [rcx + rax], xmm0; 

         add r11, r9;
         add rax, 4;
      jnz @@forxloop;

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;

   vzeroupper; 
end;

procedure AVXMatrixSubVecAlignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
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
   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;

   @@foryloop:
      mov rax, r10;

      vbroadcastss ymm1, [r8]; 

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         vmovaps ymm0, [rcx + rax - 64]; 
         vsubps ymm0, ymm0, ymm1; 
         vmovaps [rcx + rax - 64], ymm0; 

         vmovaps ymm2, [rcx + rax - 32]; 
         vsubps ymm2, ymm2, ymm1; 
         vmovaps [rcx + rax - 32], ymm2; 

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         vmovss xmm0, [rcx + rax]; 

         vsubss xmm0, xmm0, xmm1; 
         vmovss [rcx + rax], xmm0; 

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
      add r8, r9;
   dec Height;
   jnz @@foryloop;

   vzeroupper; 
end;

procedure AVXMatrixSubVecUnalignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r10;

   @@foryloop:
      mov rax, r10;

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         vmovups ymm0, [rcx + rax - 64]; 
         vmovups ymm1, [r8 + rax - 64]; 
         vsubps ymm0, ymm0, ymm1; 
         vmovups [rcx + rax - 64], ymm0; 

         vmovups ymm2, [rcx + rax - 32]; 
         vmovups ymm3, [r8 + rax - 32]; 
         vsubps ymm2, ymm2, ymm3; 
         vmovups [rcx + rax - 32], ymm2; 

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         vmovss xmm0, [rcx + rax]; 
         vmovss xmm1, [r8 + rax]; 

         vsubss xmm0, xmm0, xmm1; 
         vmovss [rcx + rax], xmm0; 

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;

   vzeroupper; 
end;

procedure AVXMatrixSubVecUnalignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var vecIter : NativeInt;
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
   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r11, width;

   imul r11, r9;
   imul r11, -1;
   mov vecIter, r11;

   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r11;

   @@foryloop:
      mov rax, r10;
      mov r11, vecIter;

      @@forxloop:
         vmovss xmm0, [rcx + rax]; 
         vmovss xmm1, [r8 + r11]; 

         vsubss xmm0, xmm0, xmm1; 
         vmovss [rcx + rax], xmm0; 

         add r11, r9;
         add rax, 4;
      jnz @@forxloop;

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;

   vzeroupper; 
end;

procedure AVXMatrixSubVecUnalignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;

   @@foryloop:
      mov rax, r10;

      vbroadcastss ymm1, [r8]; 

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         vmovups ymm0, [rcx + rax - 64]; 
         vsubps ymm0, ymm0, ymm1; 
         vmovups [rcx + rax - 64], ymm0; 

         vmovups ymm2, [rcx + rax - 32]; 
         vsubps ymm2, ymm2, ymm1; 
         vmovups [rcx + rax - 32], ymm2; 

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         vmovss xmm0, [rcx + rax]; 

         vsubss xmm0, xmm0, xmm1; 
         vmovss [rcx + rax], xmm0; 

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
      add r8, r9;
   dec Height;
   jnz @@foryloop;

   vzeroupper; 
end;


procedure AVXMatrixAddVecAlignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r10;

   @@foryloop:
      mov rax, r10;

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         vmovaps ymm0, [rcx + rax - 64]; 
         vaddps ymm0, ymm0, [r8 + rax - 64]; 
         vmovaps [rcx + rax - 64], ymm0; 

         vmovaps ymm2, [rcx + rax - 32]; 
         vaddps ymm2, ymm2, [r8 + rax - 32]; 
         vmovaps [rcx + rax - 32], ymm2; 
      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         vmovss xmm0, [rcx + rax]; 
         vmovss xmm1, [r8 + rax]; 

         vaddss xmm0, xmm0, xmm1; 
         vmovss [rcx + rax], xmm0; 

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;

   vzeroupper; 
end;

procedure AVXMatrixAddVecAlignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var vecIter : NativeInt;
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r11, width;

   imul r11, r9;
   imul r11, -1;
   mov vecIter, r11;

   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r11;

   @@foryloop:
      mov rax, r10;
      mov r11, vecIter;

      @@forxloop:
         vmovss xmm0, [rcx + rax]; 
         vmovss xmm1, [r8 + r11]; 

         vaddss xmm0, xmm0, xmm1; 
         vmovss [rcx + rax], xmm0; 

         add r11, r9;
         add rax, 4;
      jnz @@forxloop;

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;

   vzeroupper; 
end;

procedure AVXMatrixAddVecAlignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;

   @@foryloop:
      mov rax, r10;

      vbroadcastss ymm1, [r8]; 

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         vmovaps ymm0, [rcx + rax - 64]; 
         vaddps ymm0, ymm0, ymm1; 
         vmovaps [rcx + rax - 64], ymm0; 

         vmovaps ymm2, [rcx + rax - 32]; 
         vaddps ymm2, ymm2, ymm1; 
         vmovaps [rcx + rax - 32], ymm2; 

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         vmovss xmm0, [rcx + rax]; 

         vaddss xmm0, xmm0, xmm1; 
         vmovss [rcx + rax], xmm0; 

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
      add r8, r9;
   dec Height;
   jnz @@foryloop;

   vzeroupper; 
end;

procedure AVXMatrixAddVecUnalignedVecRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r10;

   @@foryloop:
      mov rax, r10;

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         vmovups ymm0, [rcx + rax - 64]; 
         vmovups ymm1, [r8 + rax - 64]; 
         vaddps ymm0, ymm0, ymm1; 
         vmovups [rcx + rax - 64], ymm0; 

         vmovups ymm2, [rcx + rax - 32]; 
         vmovups ymm3, [r8 + rax - 32]; 
         vaddps ymm2, ymm2, ymm3; 
         vmovups [rcx + rax - 32], ymm2; 

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         vmovss xmm0, [rcx + rax]; 
         vmovss xmm1, [r8 + rax]; 

         vaddss xmm0, xmm0, xmm1; 
         vmovss [rcx + rax], xmm0; 

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;

   vzeroupper; 
end;

procedure AVXMatrixAddVecUnalignedRow(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
var vecIter : NativeInt;
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r11, width;

   imul r11, r9;
   imul r11, -1;
   mov vecIter, r11;

   mov r10, width;
   imul r10, -4;

   sub rcx, r10;
   sub r8, r11;

   @@foryloop:
      mov rax, r10;
      mov r11, vecIter;

      @@forxloop:
         vmovss xmm0, [rcx + rax]; 
         vmovss xmm1, [r8 + r11]; 

         vaddss xmm0, xmm0, xmm1; 
         vmovss [rcx + rax], xmm0; 

         add r11, r9;
         add rax, 4;
      jnz @@forxloop;

      add rcx, rdx;
   dec Height;
   jnz @@foryloop;

   vzeroupper; 
end;

procedure AVXMatrixAddVecUnalignedCol(A : PSingle; LineWidthA : NativeInt; B : PSingle; incX : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
{$ifdef UNIX}
var width : NativeInt;
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

   // rcx = a, rdx = LineWidthA, r8 = B, r9 = incX
   mov r10, width;
   imul r10, -4;

   sub rcx, r10;

   @@foryloop:
      mov rax, r10;

      vbroadcastss ymm1, [r8]; 

      @@forxloopUnrolled:
         add rax, 64;
         jg @@EndLoop1;

         vmovups ymm0, [rcx + rax - 64]; 
         vaddps ymm0, ymm0, ymm1; 
         vmovups [rcx + rax - 64], ymm0; 

         vmovups ymm2, [rcx + rax - 32]; 
         vaddps ymm2, ymm2, ymm1; 
         vmovups [rcx + rax - 32], ymm2; 

      jmp @@forxloopUnrolled;

      @@EndLoop1:

      sub rax, 64;

      jz @NextLine;

      @@forxloop:
         vmovss xmm0, [rcx + rax]; 

         vaddss xmm0, xmm0, xmm1; 
         vmovss [rcx + rax], xmm0; 

         add rax, 4;
      jnz @@forxloop;

      @NextLine:

      add rcx, rdx;
      add r8, r9;
   dec Height;
   jnz @@foryloop;

   vzeroupper; 
end;


{$ENDIF}

end.
