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


unit AVXMatrixElementwiseMultOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

procedure AVXMatrixElemMultAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure AVXMatrixElemMultUnAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

procedure AVXMatrixElemDivAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure AVXMatrixElemDivUnAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure AVXMatrixElemMultAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
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

           // mult:
           vmovaps ymm0, [r8 + rax - 128]; 
           vmulps ymm0, ymm0, [r9 + rax - 128]; 

           vmovaps [rcx + rax - 128], ymm0; 

           vmovaps ymm1, [r8 + rax - 96]; 
           vmulps ymm1, ymm1, [r9 + rax - 96]; 

           vmovaps [rcx + rax - 96], ymm1; 

           vmovaps ymm2, [r8 + rax - 64]; 
           vmulps ymm2, ymm2, [r9 + rax - 64]; 

           vmovaps [rcx + rax - 64], ymm2; 

           vmovaps ymm3, [r8 + rax - 32]; 
           vmulps ymm3, ymm3, [r9 + rax - 32]; 

           vmovaps [rcx + rax - 32], ymm3; 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @@lastElem;

           vmovaps xmm0, [r8 + rax - 16]; 
           vmulps xmm0, xmm0, [r9 + rax - 16]; 

           vmovaps [rcx + rax - 16], xmm0; 
       jmp @addforxloop2;

       @@lastElem:
       sub rax, 16;

       jz @nextLine;

       vmovss xmm0, [r8 + rax]; 
       vmulss xmm0, xmm0, [r9 + rax]; 
       vmovss [rcx + rax], xmm0; 

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

procedure AVXMatrixElemMultUnAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
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

           // mult:
           vmovups ymm0, [r8 + rax - 128]; 
           vmovups ymm1, [r9 + rax - 128]; 
           vmulps ymm0, ymm0, ymm1; 

           vmovups [rcx + rax - 128], ymm0; 

           vmovups ymm2, [r8 + rax - 96]; 
           vmovups ymm3, [r9 + rax - 96]; 
           vmulps ymm2, ymm2, ymm3; 

           vmovups [rcx + rax - 96], ymm2; 

           vmovups ymm0, [r8 + rax - 64]; 
           vmovups ymm1, [r9 + rax - 64]; 
           vmulps ymm0, ymm0, ymm1; 

           vmovups [rcx + rax - 64], ymm0; 

           vmovups ymm2, [r8 + rax - 32]; 
           vmovups ymm3, [r9 + rax - 32]; 
           vmulps ymm2, ymm2, ymm3; 

           vmovups [rcx + rax - 32], ymm2; 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @@lastElem;

           vmovups xmm0, [r8 + rax - 16]; 
           vmovups xmm1, [r9 + rax - 16]; 
           vmulps xmm0, xmm0, xmm1; 

           vmovups [rcx + rax - 16], xmm0; 
       jmp @addforxloop2;

       @@lastElem:
       sub rax, 16;

       jz @nextLine;

       vmovss xmm0, [r8 + rax]; 
       vmulss xmm0, xmm0, [r9 + rax]; 
       vmovss [rcx + rax], xmm0; 

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

// ##############################################################
// #### Elementwise divide of matrix 1 to matrix 2
// ##############################################################

procedure AVXMatrixElemDivAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
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

           // mult:
           vmovaps ymm0, [r8 + rax - 128]; 
           vdivps ymm0, ymm0, [r9 + rax - 128]; 

           vmovaps [rcx + rax - 128], ymm0; 

           vmovaps ymm1, [r8 + rax - 96]; 
           vdivps ymm1, ymm1, [r9 + rax - 96]; 

           vmovaps [rcx + rax - 96], ymm1; 

           vmovaps ymm2, [r8 + rax - 64]; 
           vdivps ymm2, ymm2, [r9 + rax - 64]; 

           vmovaps [rcx + rax - 64], ymm2; 

           vmovaps ymm3, [r8 + rax - 32]; 
           vdivps ymm3, ymm3, [r9 + rax - 32]; 

           vmovaps [rcx + rax - 32], ymm3; 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @@lastElem;

           vmovaps xmm0, [r8 + rax - 16]; 
           vdivps xmm0, xmm0, [r9 + rax - 16]; 

           vmovaps [rcx + rax - 16], xmm0; 
       jmp @addforxloop2;

       @@lastElem:
       sub rax, 16;

       jz @nextLine;

       vmovss xmm0, [r8 + rax]; 
       vdivss xmm0, xmm0, [r9 + rax]; 
       vmovss [rcx + rax], xmm0; 

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

procedure AVXMatrixElemDivUnAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width{$endif} : NativeInt; {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
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

           // mult:
           vmovups ymm0, [r8 + rax - 128]; 
           vmovups ymm1, [r9 + rax - 128]; 
           vdivps ymm0, ymm0, ymm1; 

           vmovups [rcx + rax - 128], ymm0; 

           vmovups ymm2, [r8 + rax - 96]; 
           vmovups ymm3, [r9 + rax - 96]; 
           vdivps ymm2, ymm2, ymm3; 

           vmovups [rcx + rax - 96], ymm2; 

           vmovups ymm0, [r8 + rax - 64]; 
           vmovups ymm1, [r9 + rax - 64]; 
           vdivps ymm0, ymm0, ymm1; 

           vmovups [rcx + rax - 64], ymm0; 

           vmovups ymm2, [r8 + rax - 32]; 
           vmovups ymm3, [r9 + rax - 32]; 
           vdivps ymm2, ymm2, ymm3; 

           vmovups [rcx + rax - 32], ymm2; 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @@lastElem;

           vmovups xmm0, [r8 + rax - 16]; 
           vmovups xmm1, [r9 + rax - 16]; 
           vdivps xmm0, xmm0, xmm1; 

           vmovups [rcx + rax - 16], xmm0; 
       jmp @addforxloop2;

       @@lastElem:
       sub rax, 16;

       jz @nextLine;

       vmovss xmm0, [r8 + rax]; 
       vdivss xmm0, xmm0, [r9 + rax]; 
       vmovss [rcx + rax], xmm0; 

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

{$ENDIF}

end.
