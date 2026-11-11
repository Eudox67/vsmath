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

unit AVXMatrixAbsOperationsSinglex64;

// #####################################################
// #### Abs opertaion applied to every element in a matrix
// #####################################################

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

uses MatrixConstSingle;

procedure AVXMatrixAbsAligned(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
procedure AVXMatrixAbsUnAligned(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure AVXMatrixAbsAligned(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   //iters := -width*sizeof(single);
   shl r8, 2;
   imul r8, -1;

   // helper registers for the dest pointer
   sub rcx, r8;

   lea rax, [rip + cAbsMask8];
   vmovups ymm0, [rax]; 

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           //prefetchw [rcx + rax];

           // Abs:
           vmovaps ymm1, [rcx + rax - 128]; 
           vAndps ymm1, ymm1, ymm0; 
           vmovaps [rcx + rax - 128], ymm1; 

           vmovaps ymm2, [rcx + rax - 96]; 
           vandps ymm2, ymm2, ymm0; 
           vmovaps [rcx + rax - 96], ymm2; 

           vmovaps ymm3, [rcx + rax - 64]; 
           vandps ymm3, ymm3, ymm0; 
           vmovaps [rcx + rax - 64], ymm3; 

           vmovaps ymm2, [rcx + rax - 32]; 
           vandps ymm2, ymm2, ymm0; 
           vmovaps [rcx + rax - 32], ymm2; 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @loopEnd2;

           vmovaps xmm1, [rcx + rax - 16]; 
           vandps xmm1, xmm1, xmm0; 
           vmovaps [rcx + rax - 16], xmm1; 
       jmp @addforxloop2;

       @loopEnd2:

       sub rax, 16;
       jz @nextLine;

       vmovss xmm1, [rcx + rax]; 
       vandps xmm1, xmm1, xmm0; 
       vmovss [rcx + rax], xmm1; 

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   vzeroupper; 
end;

procedure AVXMatrixAbsUnAligned(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   //iters := -width*sizeof(single);
   shl r8, 2;
   imul r8, -1;

   // helper registers for the dest pointer
   sub rcx, r8;

   lea rax, [rip + cAbsMask8];
   vmovups ymm0, [rax]; 

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           //prefetchw [rcx + rax];

           // Abs:
           vmovups ymm1, [rcx + rax - 128]; 
           vAndps ymm1, ymm1, ymm0; 
           vmovups [rcx + rax - 128], ymm1; 

           vmovups ymm2, [rcx + rax - 96]; 
           vandps ymm2, ymm2, ymm0; 
           vmovups [rcx + rax - 96], ymm2; 

           vmovups ymm3, [rcx + rax - 64]; 
           vandps ymm3, ymm3, ymm0; 
           vmovups [rcx + rax - 64], ymm3; 

           vmovups ymm2, [rcx + rax - 32]; 
           vandps ymm2, ymm2, ymm0; 
           vmovups [rcx + rax - 32], ymm2; 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @loopEnd2;

           vmovups xmm1, [rcx + rax - 16]; 
           vandps xmm1, xmm1, xmm0; 
           vmovups [rcx + rax - 16], xmm1; 
       jmp @addforxloop2;

       @loopEnd2:

       sub rax, 16;
       jz @nextLine;

       vmovss xmm1, [rcx + rax]; 
       vandps xmm1, xmm1, xmm0; 
       vmovss [rcx + rax], xmm1; 

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   vzeroupper; 
end;

{$ENDIF}

end.
