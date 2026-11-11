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

unit ASMMatrixAbsOperationsSinglex64;

// #####################################################
// #### Abs opertaion applied to every element in a matrix
// #####################################################

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

uses MatrixConstSingle;

{$IFDEF CPUX64}

procedure ASMMatrixAbsAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
procedure ASMMatrixAbsUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;

procedure ASMMatrixAbsAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
procedure ASMMatrixAbsUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure ASMMatrixAbsAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
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

   // helper registers for the dest pointer
   sub rcx, r8;

   movups xmm0, [rip + cAbsMask];

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
           movaps xmm4, [rcx + rax - 128];
           andps xmm4, xmm0;
           movaps [rcx + rax - 128], xmm4;

           movaps xmm1, [rcx + rax - 112];
           andps xmm1, xmm0;
           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [rcx + rax - 96];
           andps xmm2, xmm0;
           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [rcx + rax - 80];
           andps xmm3, xmm0;
           movaps [rcx + rax - 80], xmm3;

           movaps xmm4, [rcx + rax - 64];
           andps xmm4, xmm0;
           movaps [rcx + rax - 64], xmm4;

           movaps xmm5, [rcx + rax - 48];
           andps xmm5, xmm0;
           movaps [rcx + rax - 48], xmm5;

           movaps xmm6, [rcx + rax - 32];
           andps xmm6, xmm0;
           movaps [rcx + rax - 32], xmm6;

           movaps xmm7, [rcx + rax - 16];
           andps xmm7, xmm0;
           movaps [rcx + rax - 16], xmm7;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm7, [rcx + rax];
           andps xmm7, xmm0;
           movaps [rcx + rax], xmm7;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;
end;

procedure ASMMatrixAbsUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
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

   // helper registers for the dest pointer
   sub rcx, r8;

   movups xmm0, [rip + cAbsMask];

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // Abs:
           movups xmm4, [rcx + rax - 128];
           andps xmm4, xmm0;
           movups [rcx + rax - 128], xmm4;

           movups xmm1, [rcx + rax - 112];
           andps xmm1, xmm0;
           movups [rcx + rax - 112], xmm1;

           movups xmm2, [rcx + rax - 96];
           andps xmm2, xmm0;
           movups [rcx + rax - 96], xmm2;

           movups xmm3, [rcx + rax - 80];
           andps xmm3, xmm0;
           movups [rcx + rax - 80], xmm3;

           movups xmm4, [rcx + rax - 64];
           andps xmm4, xmm0;
           movups [rcx + rax - 64], xmm4;

           movups xmm5, [rcx + rax - 48];
           andps xmm5, xmm0;
           movups [rcx + rax - 48], xmm5;

           movups xmm6, [rcx + rax - 32];
           andps xmm6, xmm0;
           movups [rcx + rax - 32], xmm6;

           movups xmm7, [rcx + rax - 16];
           andps xmm7, xmm0;
           movups [rcx + rax - 16], xmm7;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm1, [rcx + rax];
           andps xmm1, xmm0;
           movups [rcx + rax], xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;
end;

procedure ASMMatrixAbsAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
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
   dec r8;
   imul r8, -4;

   // helper registers for the dest pointer
   sub rcx, r8;

   movups xmm0, [rip + cAbsMask];

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
           movaps xmm4, [rcx + rax - 128];
           andps xmm4, xmm0;
           movaps [rcx + rax - 128], xmm4;

           movaps xmm1, [rcx + rax - 112];
           andps xmm1, xmm0;
           movaps [rcx + rax - 112], xmm1;

           movaps xmm2, [rcx + rax - 96];
           andps xmm2, xmm0;
           movaps [rcx + rax - 96], xmm2;

           movaps xmm3, [rcx + rax - 80];
           andps xmm3, xmm0;
           movaps [rcx + rax - 80], xmm3;

           movaps xmm4, [rcx + rax - 64];
           andps xmm4, xmm0;
           movaps [rcx + rax - 64], xmm4;

           movaps xmm5, [rcx + rax - 48];
           andps xmm5, xmm0;
           movaps [rcx + rax - 48], xmm5;

           movaps xmm6, [rcx + rax - 32];
           andps xmm6, xmm0;
           movaps [rcx + rax - 32], xmm6;

           movaps xmm7, [rcx + rax - 16];
           andps xmm7, xmm0;
           movaps [rcx + rax - 16], xmm7;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movaps xmm7, [rcx + rax];
           andps xmm7, xmm0;
           movaps [rcx + rax], xmm7;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last element
       movss xmm1, [rcx + rax];
       andps xmm1, xmm0;
       movss [rcx + rax], xmm1;

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;
end;

procedure ASMMatrixAbsUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt); assembler;
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
   //iters := -(width-1)*sizeof(single);
   dec r8;
   imul r8, -4;

   // helper registers for the dest pointer
   sub rcx, r8;

   movups xmm0, [rip + cAbsMask];

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // Abs:
           movups xmm4, [rcx + rax - 128];
           andps xmm4, xmm0;
           movups [rcx + rax - 128], xmm4;

           movups xmm1, [rcx + rax - 112];
           andps xmm1, xmm0;
           movups [rcx + rax - 112], xmm1;

           movups xmm2, [rcx + rax - 96];
           andps xmm2, xmm0;
           movups [rcx + rax - 96], xmm2;

           movups xmm3, [rcx + rax - 80];
           andps xmm3, xmm0;
           movups [rcx + rax - 80], xmm3;

           movups xmm4, [rcx + rax - 64];
           andps xmm4, xmm0;
           movups [rcx + rax - 64], xmm4;

           movups xmm5, [rcx + rax - 48];
           andps xmm5, xmm0;
           movups [rcx + rax - 48], xmm5;

           movups xmm6, [rcx + rax - 32];
           andps xmm6, xmm0;
           movups [rcx + rax - 32], xmm6;

           movups xmm7, [rcx + rax - 16];
           andps xmm7, xmm0;
           movups [rcx + rax - 16], xmm7;

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movups xmm1, [rcx + rax];
           andps xmm1, xmm0;
           movups [rcx + rax], xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last element
       movss xmm1, [rcx + rax];
       andps xmm1, xmm0;
       movss [rcx + rax], xmm1;

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;
end;

{$ENDIF}

end.
