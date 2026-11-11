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


unit ASMMatrixSqrtOperationsSinglex64;

// #####################################################
// #### SQRT opertaion applied to every element in a matrix
// #####################################################

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

procedure ASMMatrixSQRTAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
procedure ASMMatrixSQRTUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;

procedure ASMMatrixSQRTAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
procedure ASMMatrixSQRTUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure ASMMatrixSQRTAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
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
   mov r10, r8;
   shl r10, 2;
   imul r10, -1;

   // helper registers dest pointers
   sub rcx, r10;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetchw [rcx + rax];

           // elementwise sqrt
           sqrtps xmm0, [rcx + rax - 128];
           movaps [rcx + rax - 128], xmm0;

           sqrtps xmm1, [rcx + rax - 112];
           movaps [rcx + rax - 112], xmm1;

           sqrtps xmm2, [rcx + rax - 96];
           movaps [rcx + rax - 96], xmm2;

           sqrtps xmm3, [rcx + rax - 80];
           movaps [rcx + rax - 80], xmm3;

           sqrtps xmm0, [rcx + rax - 64];
           movaps [rcx + rax - 64], xmm0;

           sqrtps xmm1, [rcx + rax - 48];
           movaps [rcx + rax - 48], xmm1;

           sqrtps xmm2, [rcx + rax - 32];
           movaps [rcx + rax - 32], xmm2;

           sqrtps xmm3, [rcx + rax - 16];
           movaps [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           sqrtps xmm0, [rcx + rax];
           movaps [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

end;

procedure ASMMatrixSQRTUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
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
   mov r10, r8;
   shl r10, 2;
   imul r10, -1;

   // helper registers dest pointers
   sub rcx, r10;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // elementwise sqrt
           movups xmm0, [rcx + rax - 128];
           sqrtps xmm0, xmm0;
           movups [rcx + rax - 128], xmm0;

           movups xmm1, [rcx + rax - 112];
           sqrtps xmm1, xmm1;
           movups [rcx + rax - 112], xmm1;

           movups xmm2, [rcx + rax - 96];
           sqrtps xmm2, xmm2;
           movups [rcx + rax - 96], xmm2;

           movups xmm3, [rcx + rax - 80];
           sqrtps xmm3, xmm3;
           movups [rcx + rax - 80], xmm3;

           movups xmm0, [rcx + rax - 64];
           sqrtps xmm0, xmm0;
           movups [rcx + rax - 64], xmm0;

           movups xmm1, [rcx + rax - 48];
           sqrtps xmm1, xmm1;
           movups [rcx + rax - 48], xmm1;

           movups xmm2, [rcx + rax - 32];
           sqrtps xmm2, xmm2;
           movups [rcx + rax - 32], xmm2;

           movups xmm3, [rcx + rax - 16];
           sqrtps xmm3, xmm3;
           movups [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [rcx + rax];
           sqrtps xmm0, xmm0;
           movups [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

end;

procedure ASMMatrixSQRTAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
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
   //iters := -(width - 1)*sizeof(single);
   mov r10, r8;
   dec r10;
   shl r10, 2;
   imul r10, -1;

   // helper registers dest pointers
   sub rcx, r10;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetchw [rcx + rax];

           // elementwise sqrt
           sqrtps xmm0, [rcx + rax - 128];
           movaps [rcx + rax - 128], xmm0;

           sqrtps xmm1, [rcx + rax - 112];
           movaps [rcx + rax - 112], xmm1;

           sqrtps xmm2, [rcx + rax - 96];
           movaps [rcx + rax - 96], xmm2;

           sqrtps xmm3, [rcx + rax - 80];
           movaps [rcx + rax - 80], xmm3;

           sqrtps xmm0, [rcx + rax - 64];
           movaps [rcx + rax - 64], xmm0;

           sqrtps xmm1, [rcx + rax - 48];
           movaps [rcx + rax - 48], xmm1;

           sqrtps xmm2, [rcx + rax - 32];
           movaps [rcx + rax - 32], xmm2;

           sqrtps xmm3, [rcx + rax - 16];
           movaps [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           sqrtps xmm0, [rcx + rax];
           movaps [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last element
       movss xmm0, [rcx + rax];
       sqrtss xmm0, xmm0;
       movss [rcx + rax], xmm0;

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

end;

procedure ASMMatrixSQRTUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
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
   mov r10, r8;
   shl r10, 2;
   imul r10, -1;

   // helper registers dest pointers
   sub rcx, r10;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // elementwise sqrt
           movups xmm0, [rcx + rax - 128];
           sqrtps xmm0, xmm0;
           movups [rcx + rax - 128], xmm0;

           movups xmm1, [rcx + rax - 112];
           sqrtps xmm1, xmm1;
           movups [rcx + rax - 112], xmm1;

           movups xmm2, [rcx + rax - 96];
           sqrtps xmm2, xmm2;
           movups [rcx + rax - 96], xmm2;

           movups xmm3, [rcx + rax - 80];
           sqrtps xmm3, xmm3;
           movups [rcx + rax - 80], xmm3;

           movups xmm0, [rcx + rax - 64];
           sqrtps xmm0, xmm0;
           movups [rcx + rax - 64], xmm0;

           movups xmm1, [rcx + rax - 48];
           sqrtps xmm1, xmm1;
           movups [rcx + rax - 48], xmm1;

           movups xmm2, [rcx + rax - 32];
           sqrtps xmm2, xmm2;
           movups [rcx + rax - 32], xmm2;

           movups xmm3, [rcx + rax - 16];
           sqrtps xmm3, xmm3;
           movups [rcx + rax - 16], xmm3;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm0, [rcx + rax];
           sqrtps xmm0, xmm0;
           movups [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last element
       movss xmm0, [rcx + rax];
       sqrtss xmm0, xmm0;
       movss [rcx + rax], xmm0;

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;
end;

{$ENDIF}

end.
