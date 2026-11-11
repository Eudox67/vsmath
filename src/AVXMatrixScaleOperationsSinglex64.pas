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


unit AVXMatrixScaleOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

procedure AVXMatrixAddscaleAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;
procedure AVXMatrixAddscaleUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;

procedure AVXMatrixAddscaleAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;
procedure AVXMatrixAddscaleUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;

procedure AVXMatrixScaleAddAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;
procedure AVXMatrixScaleAddUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;

procedure AVXMatrixScaleAddAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;
procedure AVXMatrixScaleAddUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;

procedure AVXMatrixAddAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif} : single); assembler;
procedure AVXMatrixAddUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif} : single); assembler;

procedure AVXMatrixAddAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif} : single); assembler;
procedure AVXMatrixAddUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif} : single); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

procedure AVXMatrixAddscaleAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;
{$IFDEF UNIX}
var dOffset, Scale : single;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   movss xmm3, unixdOffset;
   movss dOffset, xmm3;
   movss xmm3, unixScale;
   movss scale, xmm3;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   // prolog - simulate stack

   //iters := -width*sizeof(single);
   imul r8, -4;

   lea rax, dOffset;
   vbroadcastss ymm3, [rax]; 
   lea rax, scale;
   vbroadcastss ymm1, [rax]; 


   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // add mul
           vmovaps ymm0, [rcx + rax - 128]; 
           vaddps ymm0, ymm0, ymm3; 
           vmulps ymm0, ymm0, ymm1; 
           vmovaps [rcx + rax - 128], ymm0; 

           vmovaps ymm2, [rcx + rax - 96]; 
           vaddps ymm2, ymm2, ymm3; 
           vmulps ymm2, ymm2, ymm1; 
           vmovaps [rcx + rax - 96], ymm2; 

           vmovaps ymm0, [rcx + rax - 64]; 
           vaddps ymm0, ymm0, ymm3; 
           vmulps ymm0, ymm0, ymm1; 
           vmovaps [rcx + rax - 64], ymm0; 

           vmovaps ymm2, [rcx + rax - 32]; 
           vaddps ymm2, ymm2, ymm3; 
           vmulps ymm2, ymm2, ymm1; 
           vmovaps [rcx + rax - 32], ymm2; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           vmovaps xmm0, [rcx + rax]; 
           vaddps xmm0, xmm0, xmm3; 
           vmulps xmm0, xmm0, xmm1; 

           vmovaps [rcx + rax], xmm0; 
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   vzeroupper; 
end;

procedure AVXMatrixAddscaleUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;
{$IFDEF UNIX}
var dOffset, scale : single;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   movss xmm3, unixdOffset;
   movss dOffset, xmm3;
   movss xmm3, unixscale;
   movss scale, xmm3;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   // prolog - simulate stack

   //iters := -width*sizeof(single);
   imul r8, -4;

   lea rax, dOffset;
   vbroadcastss ymm3, [rax]; 
   lea rax, scale;
   vbroadcastss ymm1, [rax]; 

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // add mul
           vmovups ymm0, [rcx + rax - 128]; 
           vaddps ymm0, ymm0, ymm3; 
           vmulps ymm0, ymm0, ymm1; 
           vmovups [rcx + rax - 128], ymm0; 

           vmovups ymm2, [rcx + rax - 96]; 
           vaddps ymm2, ymm2, ymm3; 
           vmulps ymm2, ymm2, ymm1; 
           vmovups [rcx + rax - 96], ymm2; 

           vmovups ymm0, [rcx + rax - 64]; 
           vaddps ymm0, ymm0, ymm3; 
           vmulps ymm0, ymm0, ymm1; 
           vmovups [rcx + rax - 64], ymm0; 

           vmovups ymm2, [rcx + rax - 32]; 
           vaddps ymm2, ymm2, ymm3; 
           vmulps ymm2, ymm2, ymm1; 
           vmovups [rcx + rax - 32], ymm2; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           vmovups xmm0, [rcx + rax]; 
           vaddps xmm0, xmm0, xmm3; 
           vmulps xmm0, xmm0, xmm1; 

           vmovups [rcx + rax], xmm0; 
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   vzeroupper; 
end;


procedure AVXMatrixAddscaleAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;
{$IFDEF UNIX}
var dOffset, scale : single;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   movss xmm3, unixdOffset;
   movss dOffset, xmm3;
   movss xmm3, unixscale;
   movss scale, xmm3;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   // prolog - simulate stack

   //iters := -(width - 1)*sizeof(single);
   dec r8;
   imul r8, -4;

   lea rax, dOffset;
   vbroadcastss ymm3, [rax]; 
   lea rax, scale;
   vbroadcastss ymm1, [rax]; 


   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // add mul
           vmovaps ymm0, [rcx + rax - 128]; 
           vaddps ymm0, ymm0, ymm3; 
           vmulps ymm0, ymm0, ymm1; 
           vmovaps [rcx + rax - 128], ymm0; 

           vmovaps ymm2, [rcx + rax - 96]; 
           vaddps ymm2, ymm2, ymm3; 
           vmulps ymm2, ymm2, ymm1; 
           vmovaps [rcx + rax - 96], ymm2; 

           vmovaps ymm0, [rcx + rax - 64]; 
           vaddps ymm0, ymm0, ymm3; 
           vmulps ymm0, ymm0, ymm1; 
           vmovaps [rcx + rax - 64], ymm0; 

           vmovaps ymm2, [rcx + rax - 32]; 
           vaddps ymm2, ymm2, ymm3; 
           vmulps ymm2, ymm2, ymm1; 
           vmovaps [rcx + rax - 32], ymm2; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           vmovaps xmm0, [rcx + rax]; 
           vaddps xmm0, xmm0, xmm3; 
           vmulps xmm0, xmm0, xmm1; 

           vmovaps [rcx + rax], xmm0; 
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       vmovss xmm0, [rcx]; 
       vaddss xmm0, xmm0, xmm3; 
       vmulss xmm0, xmm0, xmm1; 
       vmovss [rcx], xmm0; 

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   vzeroupper; 
end;

procedure AVXMatrixAddscaleUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;
{$IFDEF UNIX}
var dOffset, scale : single;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   movss xmm3, unixdOffset;
   movss dOffset, xmm3;
   movss xmm3, unixscale;
   movss scale, xmm3;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   // prolog - simulate stack

   //iters := -(width - 1)*sizeof(single);
   dec r8;
   imul r8, -4;

   lea rax, dOffset;
   vbroadcastss ymm3, [rax]; 
   lea rax, scale;
   vbroadcastss ymm1, [rax]; 

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // add mul
           vmovups ymm0, [rcx + rax - 128]; 
           vaddps ymm0, ymm0, ymm3; 
           vmulps ymm0, ymm0, ymm1; 
           vmovups [rcx + rax - 128], ymm0; 

           vmovups ymm2, [rcx + rax - 96]; 
           vaddps ymm2, ymm2, ymm3; 
           vmulps ymm2, ymm2, ymm1; 
           vmovups [rcx + rax - 96], ymm2; 

           vmovups ymm0, [rcx + rax - 64]; 
           vaddps ymm0, ymm0, ymm3; 
           vmulps ymm0, ymm0, ymm1; 
           vmovups [rcx + rax - 64], ymm0; 

           vmovups ymm2, [rcx + rax - 32]; 
           vaddps ymm2, ymm2, ymm3; 
           vmulps ymm2, ymm2, ymm1; 
           vmovups [rcx + rax - 32], ymm2; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           vmovups xmm0, [rcx + rax]; 
           vaddps xmm0, xmm0, xmm3; 
           vmulps xmm0, xmm0, xmm1; 

           vmovups [rcx + rax], xmm0; 
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       vmovss xmm0, [rcx]; 
       vaddss xmm0, xmm0, xmm3; 
       vmulss xmm0, xmm0, xmm1; 
       vmovss [rcx], xmm0; 

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   vzeroupper; 
end;


procedure AVXMatrixScaleAddAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;
{$IFDEF UNIX}
var dOffset, scale : single;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   movss xmm3, unixdOffset;
   movss dOffset, xmm3;
   movss xmm3, unixscale;
   movss scale, xmm3;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   // prolog - simulate stack

   //iters := -width*sizeof(single);
   imul r8, -4;

   lea rax, dOffset;
   vbroadcastss ymm3, [rax]; 
   lea rax, scale;
   vbroadcastss ymm1, [rax]; 

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // addition:
           vmovaps ymm0, [rcx + rax - 128]; 
           vmulps ymm0, ymm0, ymm1; 
           vaddps ymm0, ymm0, ymm3; 
           vmovaps [rcx + rax - 128], ymm0; 

           vmovaps ymm2, [rcx + rax - 96]; 
           vmulps ymm2, ymm2, ymm1; 
           vaddps ymm2, ymm2, ymm3; 
           vmovaps [rcx + rax - 96], ymm2; 

           vmovaps ymm0, [rcx + rax - 64]; 
           vmulps ymm0, ymm0, ymm1; 
           vaddps ymm0, ymm0, ymm3; 
           vmovaps [rcx + rax - 64], ymm0; 

           vmovaps ymm2, [rcx + rax - 32]; 
           vmulps ymm2, ymm2, ymm1; 
           vaddps ymm2, ymm2, ymm3; 
           vmovaps [rcx + rax - 32], ymm2; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           vmovaps xmm0, [rcx + rax]; 
           vmulps xmm0, xmm0, xmm1; 
           vaddps xmm0, xmm0, xmm3; 

           vmovaps [rcx + rax], xmm0; 
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   vzeroupper; 
end;

procedure AVXMatrixScaleAddUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;
{$IFDEF UNIX}
var dOffset, scale : single;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   movss xmm3, unixdOffset;
   movss dOffset, xmm3;
   movss xmm3, unixscale;
   movss scale, xmm3;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   // prolog - simulate stack

   //iters := -width*sizeof(single);
   imul r8, -4;

   lea rax, dOffset;
   vbroadcastss ymm3, [rax]; 
   lea rax, scale;
   vbroadcastss ymm1, [rax]; 

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // addition:
           vmovups ymm0, [rcx + rax - 128]; 
           vmulps ymm0, ymm0, ymm1; 
           vaddps ymm0, ymm0, ymm3; 
           vmovups [rcx + rax - 128], ymm0; 

           vmovups ymm2, [rcx + rax - 96]; 
           vmulps ymm2, ymm2, ymm1; 
           vaddps ymm2, ymm2, ymm3; 
           vmovups [rcx + rax - 96], ymm2; 

           vmovups ymm0, [rcx + rax - 64]; 
           vmulps ymm0, ymm0, ymm1; 
           vaddps ymm0, ymm0, ymm3; 
           vmovups [rcx + rax - 64], ymm0; 

           vmovups ymm2, [rcx + rax - 32]; 
           vmulps ymm2, ymm2, ymm1; 
           vaddps ymm2, ymm2, ymm3; 
           vmovups [rcx + rax - 32], ymm2; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           vmovups xmm0, [rcx + rax]; 
           vmulps xmm0, xmm0, xmm1; 
           vaddps xmm0, xmm0, xmm3; 

           vmovups [rcx + rax], xmm0; 
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   vzeroupper; 
end;

procedure AVXMatrixScaleAddAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;
{$IFDEF UNIX}
var dOffset, scale : single;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   movss xmm3, unixdOffset;
   movss dOffset, xmm3;
   movss xmm3, unixscale;
   movss scale, xmm3;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   // prolog - simulate stack

   //iters := -width*sizeof(single);
   dec r8;
   imul r8, -4;

   lea rax, dOffset;
   vbroadcastss ymm3, [rax]; 
   lea rax, scale;
   vbroadcastss ymm1, [rax]; 

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // addition:
           vmovaps ymm0, [rcx + rax - 128]; 
           vmulps ymm0, ymm0, ymm1; 
           vaddps ymm0, ymm0, ymm3; 
           vmovaps [rcx + rax - 128], ymm0; 

           vmovaps ymm2, [rcx + rax - 96]; 
           vmulps ymm2, ymm2, ymm1; 
           vaddps ymm2, ymm2, ymm3; 
           vmovaps [rcx + rax - 96], ymm2; 

           vmovaps ymm0, [rcx + rax - 64]; 
           vmulps ymm0, ymm0, ymm1; 
           vaddps ymm0, ymm0, ymm3; 
           vmovaps [rcx + rax - 64], ymm0; 

           vmovaps ymm2, [rcx + rax - 32]; 
           vmulps ymm2, ymm2, ymm1; 
           vaddps ymm2, ymm2, ymm3; 
           vmovaps [rcx + rax - 32], ymm2; 


       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           vmovaps xmm0, [rcx + rax]; 
           vmulps xmm0, xmm0, xmm1; 
           vaddps xmm0, xmm0, xmm3; 

           vmovaps [rcx + rax], xmm0; 
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       vmovss xmm0, [rcx]; 
       vmulss xmm0, xmm0, xmm1; 
       vaddss xmm0, xmm0, xmm3; 
       vmovss [rcx], xmm0; 

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   vzeroupper; 
end;

procedure AVXMatrixScaleAddUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif}, {$ifdef UNIX}unixScale{$ELSE}Scale{$endif} : single); assembler;
{$IFDEF UNIX}
var dOffset, scale : single;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   movss xmm3, unixdOffset;
   movss dOffset, xmm3;
   movss xmm3, unixscale;
   movss scale, xmm3;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   // prolog - simulate stack

   //iters := -width*sizeof(single);
   dec r8;
   imul r8, -4;

   lea rax, dOffset;
   vbroadcastss ymm3, [rax]; 
   lea rax, scale;
   vbroadcastss ymm1, [rax]; 

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // addition:
           vmovups ymm0, [rcx + rax - 128]; 
           vmulps ymm0, ymm0, ymm1; 
           vaddps ymm0, ymm0, ymm3; 
           vmovups [rcx + rax - 128], ymm0; 

           vmovups ymm2, [rcx + rax - 96]; 
           vmulps ymm2, ymm2, ymm1; 
           vaddps ymm2, ymm2, ymm3; 
           vmovups [rcx + rax - 96], ymm2; 

           vmovups ymm0, [rcx + rax - 64]; 
           vmulps ymm0, ymm0, ymm1; 
           vaddps ymm0, ymm0, ymm3; 
           vmovups [rcx + rax - 64], ymm0; 

           vmovups ymm2, [rcx + rax - 32]; 
           vmulps ymm2, ymm2, ymm1; 
           vaddps ymm2, ymm2, ymm3; 
           vmovups [rcx + rax - 32], ymm2; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           vmovups xmm0, [rcx + rax]; 
           vmulps xmm0, xmm0, xmm1; 
           vaddps xmm0, xmm0, xmm3; 

           vmovups [rcx + rax], xmm0; 
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       vmovss xmm0, [rcx]; 
       vmulss xmm0, xmm0, xmm1; 
       vaddss xmm0, xmm0, xmm3; 
       vmovss [rcx], xmm0; 

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   vzeroupper; 
end;


// ###########################################
// #### Offset a matrix
// ###########################################

procedure AVXMatrixAddAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif} : single); assembler;
{$IFDEF UNIX}
var dOffset : single;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   movss xmm3, unixdOffset;
   movss dOffset, xmm3;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   // prolog - simulate stack

   //iters := -width*sizeof(single);
   imul r8, -4;

   lea rax, dOffset;
   vbroadcastss ymm3, [rax]; 

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // add mul
           vmovaps ymm0, [rcx + rax - 128]; 
           vaddps ymm0, ymm0, ymm3; 
           vmovaps [rcx + rax - 128], ymm0; 

           vmovaps ymm2, [rcx + rax - 96]; 
           vaddps ymm2, ymm2, ymm3; 
           vmovaps [rcx + rax - 96], ymm2; 

           vmovaps ymm0, [rcx + rax - 64]; 
           vaddps ymm0, ymm0, ymm3; 
           vmovaps [rcx + rax - 64], ymm0; 

           vmovaps ymm2, [rcx + rax - 32]; 
           vaddps ymm2, ymm2, ymm3; 
           vmovaps [rcx + rax - 32], ymm2; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           vmovaps xmm0, [rcx + rax]; 
           vaddps xmm0, xmm0, xmm3; 

           vmovaps [rcx + rax], xmm0; 
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   vzeroupper; 
end;

procedure AVXMatrixAddUnAlignedEvenW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif} : single); assembler;
{$IFDEF UNIX}
var dOffset : single;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   movss xmm3, unixdOffset;
   movss dOffset, xmm3;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   // prolog - simulate stack

   //iters := -width*sizeof(single);
   imul r8, -4;

   lea rax, dOffset;
   vbroadcastss ymm3, [rax]; 

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // add mul
           vmovups ymm0, [rcx + rax - 128]; 
           vaddps ymm0, ymm0, ymm3; 
           vmovups [rcx + rax - 128], ymm0; 

           vmovups ymm2, [rcx + rax - 96]; 
           vaddps ymm2, ymm2, ymm3; 
           vmovups [rcx + rax - 96], ymm2; 

           vmovups ymm0, [rcx + rax - 64]; 
           vaddps ymm0, ymm0, ymm3; 
           vmovups [rcx + rax - 64], ymm0; 

           vmovups ymm2, [rcx + rax - 32]; 
           vaddps ymm2, ymm2, ymm3; 
           vmovups [rcx + rax - 32], ymm2; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           vmovups xmm0, [rcx + rax]; 
           vaddps xmm0, xmm0, xmm3; 

           vmovups [rcx + rax], xmm0; 
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   vzeroupper; 
end;


procedure AVXMatrixAddAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif} : single); assembler;
{$IFDEF UNIX}
var dOffset : single;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   movss xmm3, unixdOffset;
   movss dOffset, xmm3;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   // prolog - simulate stack

   //iters := -(width - 1)*sizeof(single);
   dec r8;
   imul r8, -4;

   lea rax, dOffset;
   vbroadcastss ymm3, [rax]; 

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // add mul
           vmovaps ymm0, [rcx + rax - 128]; 
           vaddps ymm0, ymm0, ymm3; 
           vmovaps [rcx + rax - 128], ymm0; 

           vmovaps ymm2, [rcx + rax - 96]; 
           vaddps ymm2, ymm2, ymm3; 
           vmovaps [rcx + rax - 96], ymm2; 

           vmovaps ymm0, [rcx + rax - 64]; 
           vaddps ymm0, ymm0, ymm3; 
           vmovaps [rcx + rax - 64], ymm0; 

           vmovaps ymm2, [rcx + rax - 32]; 
           vaddps ymm2, ymm2, ymm3; 
           vmovaps [rcx + rax - 32], ymm2; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           vmovaps xmm0, [rcx + rax]; 
           vaddps xmm0, xmm0, xmm3; 

           vmovaps [rcx + rax], xmm0; 
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       vmovss xmm0, [rcx]; 
       vaddss xmm0, xmm0, xmm3; 
       vmovss [rcx], xmm0; 

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   vzeroupper; 
end;

procedure AVXMatrixAddUnAlignedOddW(Dest : PSingle; const LineWidth, Width, Height : NativeInt; {$ifdef UNIX}unixdOffset{$ELSE}dOffset{$endif} : single); assembler;
{$IFDEF UNIX}
var dOffset : single;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   movss xmm3, unixdOffset;
   movss dOffset, xmm3;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note: RCX = dest, RDX = destLineWidth, R8 = width, R9 = height
   // prolog - simulate stack

   //iters := -(width - 1)*sizeof(single);
   dec r8;
   imul r8, -4;

   lea rax, dOffset;
   vbroadcastss ymm3, [rax]; 

   // helper registers for the mt1, mt2 and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetchw data...
           // prefetchw [rcx + rax];

           // add mul
           vmovups ymm0, [rcx + rax - 128]; 
           vaddps ymm0, ymm0, ymm3; 
           vmovups [rcx + rax - 128], ymm0; 

           vmovups ymm2, [rcx + rax - 96]; 
           vaddps ymm2, ymm2, ymm3; 
           vmovups [rcx + rax - 96], ymm2; 

           vmovups ymm0, [rcx + rax - 64]; 
           vaddps ymm0, ymm0, ymm3; 
           vmovups [rcx + rax - 64], ymm0; 

           vmovups ymm2, [rcx + rax - 32]; 
           vaddps ymm2, ymm2, ymm3; 
           vmovups [rcx + rax - 32], ymm2; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           vmovups xmm0, [rcx + rax]; 
           vaddps xmm0, xmm0, xmm3; 

           vmovups [rcx + rax], xmm0; 
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last column:
       vmovss xmm0, [rcx]; 
       vaddss xmm0, xmm0, xmm3; 
       vmovss [rcx], xmm0; 

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   // epilog
   vzeroupper; 
end;

{$ENDIF}

end.
