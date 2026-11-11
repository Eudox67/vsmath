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


unit AVXMatrixSqrtOperationsSinglex64;

// #####################################################
// #### SQRT opertaion applied to every element in a matrix
// #####################################################

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

procedure AVXMatrixSQRTAligned(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
procedure AVXMatrixSQRTUnAligned(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure AVXMatrixSQRTAligned(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
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
   imul r8, -4;

   // helper registers dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetchw [rcx + rax];

           // elementwise sqrt
           vsqrtps ymm0, [rcx + rax - 128]; 
           vmovaps [rcx + rax - 128], ymm0; 

           vsqrtps ymm1, [rcx + rax - 96]; 
           vmovaps [rcx + rax - 96], ymm1; 

           vsqrtps ymm0, [rcx + rax - 64]; 
           vmovaps [rcx + rax - 64], ymm0; 

           vsqrtps ymm1, [rcx + rax - 32]; 
           vmovaps [rcx + rax - 32], ymm1; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @addforxloop2end;

           vsqrtps xmm0, [rcx + rax - 16]; 
           vmovaps [rcx + rax - 16], xmm0; 
       jmp @addforxloop2;

       @addforxloop2end:

       sub rax, 16;

       jz @nextLine;

       vmovss xmm0, [rcx + rax]; 
       vsqrtss xmm0, xmm0, xmm0; 
       vmovss [rcx + rax], xmm0; 

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;
   vzeroupper; 
end;

procedure AVXMatrixSQRTUnAligned(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
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
   imul r8, -4;

   // helper registers dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetchw [rcx + rax];

           // elementwise sqrt
           vmovups ymm2, [rcx + rax - 128]; 
           vsqrtps ymm0, ymm2; 
           vmovups [rcx + rax - 128], ymm0; 

           vmovups ymm3, [rcx + rax - 96]; 
           vsqrtps ymm1, ymm3; 
           vmovups [rcx + rax - 96], ymm1; 

           vmovups ymm2, [rcx + rax - 64]; 
           vsqrtps ymm0, ymm2; 
           vmovups [rcx + rax - 64], ymm0; 

           vmovups ymm3, [rcx + rax - 32]; 
           vsqrtps ymm1, ymm3; 
           vmovups [rcx + rax - 32], ymm1; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @addforxloop2end;

           vmovups xmm1, [rcx + rax - 16]; 
           vsqrtps xmm0, xmm1; 
           vmovups [rcx + rax - 16], xmm0; 
       jmp @addforxloop2;

       @addforxloop2end:

       sub rax, 16;

       jz @nextLine;

       vmovss xmm0, [rcx + rax]; 
       vsqrtss xmm0, xmm0, xmm0; 
       vmovss [rcx + rax], xmm0; 

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
