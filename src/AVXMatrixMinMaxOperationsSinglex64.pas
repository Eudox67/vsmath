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


unit AVXMatrixMinMaxOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

uses MatrixConstSingle;

function AVXMatrixMaxAligned(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
function AVXMatrixMaxUnAligned(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;

function AVXMatrixMinAligned(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
function AVXMatrixMinUnAligned(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;

// in matrix max/min
procedure AVXMatrixMinValUnAligned( dest : PSingle; const LineWidth : NativeInt; width, height : NativeInt; {$IFDEF UNIX}unixMinVal : single {$ELSE} minVal : single {$ENDIF} ); assembler;
procedure AVXMatrixMaxValUnAligned( dest : PSingle; const LineWidth : NativeInt; width, height : NativeInt; {$IFDEF UNIX}unixMaxVal : single {$ELSE} maxVal : single {$ENDIF} ); assembler;

procedure AVXMatrixMinValAligned( dest : PSingle; const LineWidth : NativeInt; width, height : NativeInt; {$IFDEF UNIX}unixMinVal : single {$ELSE} minVal : single {$ENDIF} ); assembler;
procedure AVXMatrixMaxValAligned( dest : PSingle; const LineWidth : NativeInt; width, height : NativeInt; {$IFDEF UNIX}unixMaxVal : single {$ELSE} maxVal : single {$ENDIF} ); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

function AVXMatrixMaxAligned(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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
   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   sub rsp, $10;
   vmovups [rsp + $00], xmm4; 

   imul rdx, -4;

   sub rcx, rdx;

   // init result
   lea rax, [rip + cNegMaxSingle];
   vbroadcastss ymm0, [rax]; 
   vmovaps ymm3, ymm0; 
   vmovaps ymm4, ymm0; 

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       add rax, 128;
       jg @loopEnd;

       @addforxloop:
           // prefetch data...
           // prefetch [rcx + rax];

           // max:
           vmaxps ymm3, ymm3, [rcx + rax - 128]; 
           vmaxps ymm4, ymm4, [rcx + rax - 96]; 
           vmaxps ymm3, ymm3, [rcx + rax - 64]; 
           vmaxps ymm4, ymm4, [rcx + rax - 32]; 

       add rax, 128;
       jle @addforxloop;

       vextractf128 xmm2, ymm3, 1; 
       vmaxps xmm2, xmm2, xmm3; 
       vmaxps xmm0, xmm0, xmm2; 
       vextractf128 xmm2, ymm4, 1; 
       vmaxps xmm2, xmm2, xmm4; 
       vmaxps xmm0, xmm0, xmm2; 

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @addforxloop2end;

           vmaxps xmm0, xmm0, [rcx + rax - 16]; 
       jmp @addforxloop2;

       @addforxloop2end:

       sub rax, 16;
       jz @nextLine;

       vmovss xmm2, [rcx + rax]; 
       vmaxss xmm0, xmm0, xmm2; 

       @nextLine:

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final max -> fold all four lanes into lane 0
   vshufps xmm1, xmm0, xmm0, $4E;
   vmaxps xmm0, xmm0, xmm1;
   vshufps xmm1, xmm0, xmm0, $B1;
   vmaxps xmm0, xmm0, xmm1;

   // epilog - cleanup stack
   vmovups xmm4, [rsp + $00];
   add rsp, $10;
   vzeroupper;
end;

function AVXMatrixMaxUnAligned(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   sub rsp, $10;
   vmovups [rsp + $00], xmm4; 

   imul rdx, -4;

   sub rcx, rdx;

   // init result
   lea rax, [rip + cNegMaxSingle];
   vbroadcastss ymm0, [rax]; 
   vmovaps ymm3, ymm0; 
   vmovaps ymm4, ymm0; 

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;

       add rax, 128;
       jg @loopEnd;

       @addforxloop:
           // prefetch data...
           // prefetch [rcx + rax];

           // max:
           vmovups ymm2, [rcx + rax - 128]; 
           vmaxps ymm3, ymm3, ymm2; 
           vmovups ymm2, [rcx + rax - 96]; 
           vmaxps ymm4, ymm4, ymm2; 
           vmovups ymm2, [rcx + rax - 64]; 
           vmaxps ymm3, ymm3, ymm2; 
           vmovups ymm2, [rcx + rax - 32]; 
           vmaxps ymm4, ymm4, ymm2; 
       add rax, 128;
       jle @addforxloop;

       vextractf128 xmm2, ymm3, 1; 
       vmaxps xmm2, xmm2, xmm3; 
       vmaxps xmm0, xmm0, xmm2; 
       vextractf128 xmm2, ymm4, 1; 
       vmaxps xmm2, xmm2, xmm4; 
       vmaxps xmm0, xmm0, xmm2; 

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @addforxloop2end;

           vmovups xmm2, [rcx + rax - 16]; 
           vmaxps xmm0, xmm0, xmm2; 
       jmp @addforxloop2;

       @addforxloop2end:

       sub rax, 16;
       jz @nextLine;

       vmovss xmm2, [rcx + rax]; 
       vmaxss xmm0, xmm0, xmm2; 

       @nextLine:

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final max -> fold all four lanes into lane 0
   vshufps xmm1, xmm0, xmm0, $4E;
   vmaxps xmm0, xmm0, xmm1;
   vshufps xmm1, xmm0, xmm0, $B1;
   vmaxps xmm0, xmm0, xmm1;

   // epilog - cleanup stack
   vmovups xmm4, [rsp + $00]; 
   add rsp, $10;
   vzeroupper; 
end;

function AVXMatrixMinAligned(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   sub rsp, $10;
   vmovups [rsp + $00], xmm4; 

   imul rdx, -4;

   sub rcx, rdx;

   // init result
   lea rax, [rip + cMaxSingle];
   vbroadcastss ymm0, [rax]; 
   vmovaps ymm3, ymm0; 
   vmovaps ymm4, ymm0; 

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       add rax, 128;
       jg @loopEnd;

       @addforxloop:
           // prefetch data...
           // prefetch [rcx + rax];

           // max:
           vminps ymm3, ymm3, [rcx + rax - 128]; 
           vminps ymm4, ymm4, [rcx + rax - 96]; 
           vminps ymm3, ymm3, [rcx + rax - 64]; 
           vminps ymm4, ymm4, [rcx + rax - 32]; 
       add rax, 128;
       jle @addforxloop

       vextractf128 xmm2, ymm3, 1; 
       vminps xmm2, xmm2, xmm3; 
       vminps xmm0, xmm0, xmm2; 
       vextractf128 xmm2, ymm4, 1; 
       vminps xmm2, xmm2, xmm4; 
       vminps xmm0, xmm0, xmm2; 

       @loopEnd:
       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @addforxloop2end;

           vminps xmm0, xmm0, [rcx + rax - 16]; 
       jmp @addforxloop2;

       @addforxloop2end:

       sub rax, 16;
       jz @nextLine;

       vmovss xmm2, [rcx + rax]; 
       vminss xmm0, xmm0, xmm2; 

       @nextLine:

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final min -> fold all four lanes into lane 0
   vshufps xmm1, xmm0, xmm0, $4E;
   vminps xmm0, xmm0, xmm1;
   vshufps xmm1, xmm0, xmm0, $B1;
   vminps xmm0, xmm0, xmm1;

   // epilog - cleanup stack
   vmovups xmm4, [rsp + $00]; 
   add rsp, $10;
   vzeroupper; 
end;

function AVXMatrixMinUnAligned(mt : PSingle; width, height : NativeInt; const LineWidth : NativeInt) : single; assembler;
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

   // note: RCX = mt, RDX = width, R8 = height, R9 = LineWidth
   // prolog - simulate stack
   sub rsp, $10;
   vmovups [rsp + $00], xmm4; 

   imul rdx, -4;

   sub rcx, rdx;

   // init result
   lea rax, [rip + cMaxSingle];
   vbroadcastss ymm0, [rax]; 
   vmovaps ymm3, ymm0; 
   vmovaps ymm4, ymm0; 

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, rdx;
       add rax, 128;
       jg @loopEnd;

       @addforxloop:
           // prefetch data...
           // prefetch [rcx + rax];

           // max:
           vmovups ymm2, [rcx + rax - 128]; 
           vminps ymm3, ymm3, ymm2; 
           vmovups ymm2, [rcx + rax - 96]; 
           vminps ymm4, ymm4, ymm2; 
           vmovups ymm2, [rcx + rax - 64]; 
           vminps ymm3, ymm3, ymm2; 
           vmovups ymm2, [rcx + rax - 32]; 
           vminps ymm4, ymm4, ymm2; 
       add rax, 128;
       jle @addforxloop

       vextractf128 xmm2, ymm3, 1; 
       vminps xmm2, xmm2, xmm3; 
       vminps xmm0, xmm0, xmm2; 
       vextractf128 xmm2, ymm4, 1; 
       vminps xmm2, xmm2, xmm4; 
       vminps xmm0, xmm0, xmm2; 

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @addforxloop2end;

           vmovups xmm2, [rcx + rax - 16]; 
           vminps xmm0, xmm0, xmm2; 
       jmp @addforxloop2;

       @addforxloop2end:
       sub rax, 16;
       jz @nextLine;

       vmovss xmm2, [rcx + rax]; 
       vminss xmm0, xmm0, xmm2; 

       @nextLine:

       // next line:
       add rcx, r9;

   // loop y end
   dec r8;
   jnz @@addforyloop;

   // final min -> fold all four lanes into lane 0
   vshufps xmm1, xmm0, xmm0, $4E;
   vminps xmm0, xmm0, xmm1;
   vshufps xmm1, xmm0, xmm0, $B1;
   vminps xmm0, xmm0, xmm1;

   // epilog - cleanup stack
   vmovups xmm4, [rsp + $00]; 
   add rsp, $10;
   vzeroupper; 
end;

procedure AVXMatrixMinValUnAligned( dest : PSingle; const LineWidth : NativeInt; width, height : NativeInt;{$IFDEF UNIX}unixMinVal : single {$ELSE} minVal : single {$ENDIF}); assembler;
// rcx = dest; rdx = LineWidth, r8 = Width, r9 = height; xmm0 = unixMinVal
{$IFDEF UNIX}
var minVal : single;
{$ENDIF}
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
   movss minVal, xmm0;
   {$ENDIF}

   imul r8, -4;

   // helper registers for the dest pointer
   sub rcx, r8;

   lea rax, minVal;
   vbroadcastss ymm0, [rax]; 

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
           vminps ymm1, ymm1, ymm0; 
           vmovups [rcx + rax - 128], ymm1; 

           vmovups ymm2, [rcx + rax - 96]; 
           vminps ymm2, ymm2, ymm0; 
           vmovups [rcx + rax - 96], ymm2; 

           vmovups ymm3, [rcx + rax - 64]; 
           vminps ymm3, ymm3, ymm0; 
           vmovups [rcx + rax - 64], ymm3; 

           vmovups ymm4, [rcx + rax - 32]; 
           vminps ymm4, ymm4, ymm0; 
           vmovups [rcx + rax - 32], ymm4; 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @loopEnd2;

           vmovups xmm1, [rcx + rax - 16]; 
           vminps xmm1, xmm1, xmm0; 
           vmovups [rcx + rax - 16], xmm1; 
       jmp @addforxloop2;

       @loopEnd2:

       sub rax, 16;
       jz @nextLine;

       vmovss xmm1, [rcx + rax]; 
       vminss xmm1, xmm1, xmm0; 
       vmovss [rcx + rax], xmm1; 

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   vzeroupper; 
end;


procedure AVXMatrixMaxValUnAligned( dest : PSingle; const LineWidth : NativeInt; width, height : NativeInt; {$IFDEF UNIX}unixMaxVal : single {$ELSE} maxVal : single {$ENDIF} ); assembler;
// rcx = dest; rdx = LineWidth, r8 = Width, r9 = height, unix: xmm0 = unixmaxval
{$IFDEF UNIX}
var maxVal : single;
{$ENDIF}
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
   movss maxVal, xmm0;
   {$ENDIF}

   imul r8, -4;

   // helper registers for the dest pointer
   sub rcx, r8;

   lea rax, maxVal;
   vbroadcastss ymm0, [rax]; 

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
           vmaxps ymm1, ymm1, ymm0; 
           vmovups [rcx + rax - 128], ymm1; 

           vmovups ymm2, [rcx + rax - 96]; 
           vmaxps ymm2, ymm2, ymm0; 
           vmovups [rcx + rax - 96], ymm2; 

           vmovups ymm3, [rcx + rax - 64]; 
           vmaxps ymm3, ymm3, ymm0; 
           vmovups [rcx + rax - 64], ymm3; 

           vmovups ymm4, [rcx + rax - 32]; 
           vmaxps ymm4, ymm4, ymm0; 
           vmovups [rcx + rax - 32], ymm4; 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @loopEnd2;

           vmovups xmm1, [rcx + rax - 16]; 
           vmaxps xmm1, xmm1, xmm0; 
           vmovups [rcx + rax - 16], xmm1; 
       jmp @addforxloop2;

       @loopEnd2:

       sub rax, 16;
       jz @nextLine;

       vmovss xmm1, [rcx + rax]; 
       vmaxss xmm1, xmm1, xmm0; 
       vmovss [rcx + rax], xmm1; 

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   vzeroupper; 
end;


procedure AVXMatrixMinValAligned( dest : PSingle; const LineWidth : NativeInt; width, height : NativeInt; {$IFDEF UNIX}unixMinVal : single {$ELSE} minVal : single {$ENDIF} ); assembler;
// rcx = dest; rdx = LineWidth, r8 = Width, r9 = height
{$IFDEF UNIX}
var minVal : single;
{$ENDIF}
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
   movss minVal, xmm0;
   {$ENDIF}

   imul r8, -4;

   // helper registers for the dest pointer
   sub rcx, r8;

   lea rax, minVal;
   vbroadcastss ymm0, [rax]; 

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
           vminps ymm1, ymm0, [rcx + rax - 128]; 
           vmovaps [rcx + rax - 128], ymm1; 

           vminps ymm2, ymm0, [rcx + rax - 96]; 
           vmovaps [rcx + rax - 96], ymm2; 

           vminps ymm3, ymm0, [rcx + rax - 64]; 
           vmovaps [rcx + rax - 64], ymm3; 

           vminps ymm4, ymm0, [rcx + rax - 32]; 
           vmovaps [rcx + rax - 32], ymm4; 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @loopEnd2;

           vminps xmm1, xmm0, [rcx + rax - 16]; 
           vmovaps [rcx + rax - 16], xmm1; 
       jmp @addforxloop2;

       @loopEnd2:

       sub rax, 16;
       jz @nextLine;

       vmovss xmm1, [rcx + rax]; 
       vminss xmm1, xmm1, xmm0; 
       vmovss [rcx + rax], xmm1; 

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   vzeroupper; 
end;

procedure AVXMatrixMaxValAligned( dest : PSingle; const LineWidth : NativeInt; width, height : NativeInt; {$IFDEF UNIX}unixMaxVal : single {$ELSE} maxVal : single {$ENDIF} ); assembler;
// rcx = dest; rdx = LineWidth, r8 = Width, r9 = height
{$IFDEF UNIX}
var maxVal : single;
{$ENDIF}
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
   movss maxVal, xmm0;
   {$ENDIF}

   imul r8, -4;

   // helper registers for the dest pointer
   sub rcx, r8;

   lea rax, maxVal;
   vbroadcastss ymm0, [rax]; 

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
           vmaxps ymm1, ymm0, [rcx + rax - 128]; 
           vmovaps [rcx + rax - 128], ymm1; 

           vmaxps ymm2, ymm0, [rcx + rax - 96]; 
           vmovaps [rcx + rax - 96], ymm2; 

           vmaxps ymm3, ymm0, [rcx + rax - 64]; 
           vmovaps [rcx + rax - 64], ymm3; 

           vmaxps ymm4, ymm0, [rcx + rax - 32]; 
           vmovaps [rcx + rax - 32], ymm4; 
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           add rax, 16;
           jg @loopEnd2;

           vmaxps xmm1, xmm0, [rcx + rax - 16]; 
           vmovaps [rcx + rax - 16], xmm1; 
       jmp @addforxloop2;

       @loopEnd2:

       sub rax, 16;
       jz @nextLine;

       vmovss xmm1, [rcx + rax]; 
       vmaxss xmm1, xmm1, xmm0; 
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
