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


unit AVXMoveOperationsSinglex64;

// #################################################
// #### SSE optimized move oprationes
// #################################################

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

procedure AVXMatrixCopyAligned(Dest : PSingle; const destLineWidth : NativeInt; src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure AVXMatrixCopyUnAligned(Dest : PSingle; const destLineWidth : NativeInt; src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure AVXRowSwapAligned(A, B : PSingle; width : NativeInt); assembler;
procedure AVXRowSwapUnAligned(A, B : PSingle; width : NativeInt); assembler;

procedure AVXInitMemAligned(A : PSingle; NumBytes : NativeInt; Value : single); assembler;


procedure AVXMatrixInitAligned( dest : PSingle; const destLineWidth : NativeInt; Width, Height : NativeInt; {$IFDEF UNIX}unixValue{$ELSE}Value{$ENDIF} : single); assembler;
procedure AVXMatrixInitUnAligned( dest : PSingle; const destLineWidth : NativeInt; Width, Height : NativeInt; {$IFDEF UNIX}unixValue{$ELSE}Value{$ENDIF} : single); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

// rcx = dest, rdx = destLineWidth;  r8 = width, r9 = height
procedure AVXMatrixInitAligned( dest : PSingle; const destLineWidth : NativeInt; Width, Height : NativeInt; {$IFDEF UNIX}unixValue{$ELSE}Value{$ENDIF} : single); assembler;
{$IFDEF UNIX}
var value : single;
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

   movss value, unixValue;
   {$ENDIF}

   lea rax, value;
   vbroadcastss ymm1, [rax]; 

   //iters := -width*sizeof(single);
   imul r8, -4;

   // helper registers for the src and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // move:
           vmovaps [rcx + rax - 128], ymm1; 
           vmovaps [rcx + rax - 96], ymm1; 
           vmovaps [rcx + rax - 64], ymm1; 
           vmovaps [rcx + rax - 32], ymm1; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
          add rax, 16;
          jg @loopEnd2;

          vmovaps [rcx + rax - 16], xmm1; 
       jmp @addforxloop2;

       @loopEnd2:
       sub rax, 16;

       jz @nextLine;

       // last element
       vmovss [rcx + rax], xmm1;

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   vzeroupper; 
end;

// rcx = dest, rdx = destLineWidth;  r8 = width, r9 = height
procedure AVXMatrixInitUnAligned( dest : PSingle; const destLineWidth : NativeInt; Width, Height : NativeInt; {$IFDEF UNIX}unixValue{$ELSE}Value{$ENDIF} : single); assembler;
{$IFDEF UNIX}
var value : single;
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

   movss value, unixValue;
   {$ENDIF}

   lea rax, value;
   vbroadcastss ymm1, [rax]; 

   //iters := -width*sizeof(single);
   imul r8, -4;

   // helper registers for the src and dest pointers
   sub rcx, r8;

   // for y := 0 to height - 1:
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r8;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // move:
           vmovups [rcx + rax - 128], ymm1; 
           vmovups [rcx + rax - 96], ymm1; 
           vmovups [rcx + rax - 64], ymm1; 
           vmovups [rcx + rax - 32], ymm1; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
          add rax, 16;
          jg @loopEnd2;

          vmovups [rcx + rax - 16], xmm1; 
       jmp @addforxloop2;

       @loopEnd2:
       sub rax, 16;

       jz @nextLine;

       // last element
       vmovss [rcx + rax], xmm1; 

       @nextLine:

       // next line:
       add rcx, rdx;

   // loop y end
   dec r9;
   jnz @@addforyloop;

   vzeroupper; 
end;

// uses non temporal moves so the cache is not poisned
// rcx = A, rdx = NumBytes;
procedure AVXInitMemAligned(A : PSingle; NumBytes : NativeInt; Value : single); assembler;
var tmp : Single;
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

   movss tmp, value;
   lea rax, tmp;
   vbroadcastss ymm1, [rax]; 

   imul rdx, -1;
   sub rcx, rdx;

   @@loopUnrolled:
      add rdx, 128;
      jg @@loopUnrolledEnd;

      vmovaps [rcx + rdx - 128], ymm1; 
      vmovaps [rcx + rdx - 96], ymm1; 
      vmovaps [rcx + rdx - 64], ymm1; 
      vmovaps [rcx + rdx - 32], ymm1; 
   jmp @@loopUnrolled;

   @@loopUnrolledEnd:

   sub rdx, 128;
   jz @@exitProc;

   add rdx, 32;
   jg @@beginloop3;

   @@loop2:
      vmovaps [rcx + rdx - 32], xmm1; 
      vmovaps [rcx + rdx - 16], xmm1; 
   add rdx, 32;
   jl @@loop2;

   @@beginloop3:
   sub rdx, 32;
   jz @@exitProc;

   @@loop3:
      vmovss [rcx + rdx], xmm1; 
      add rdx, 4;
   jnz @@loop3;

   @@exitProc:

   vzeroupper; 
end;

procedure AVXRowSwapAligned(A, B : PSingle; width : NativeInt); assembler;
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

   // note: RCX = a, RDX = b, R8 = width
   imul r8, -4;

   sub rcx, r8;
   sub rdx, r8;

   @unrolloop:
     add r8, 128;
     jg @unrolloopend;

     // prefetch data...
     // prefetchw [rcx + r10];
     // prefetchw [rdx + r10];

     vmovdqa ymm0, [rcx + r8 - 128]; 
     vmovdqa ymm1, [rdx + r8 - 128]; 

     vmovdqa [rcx + r8 - 128], ymm1; 
     vmovdqa [rdx + r8 - 128], ymm0; 

     vmovdqa ymm2, [rcx + r8 - 96]; 
     vmovdqa ymm3, [rdx + r8 - 96]; 

     vmovdqa [rcx + r8 - 96], ymm3; 
     vmovdqa [rdx + r8 - 96], ymm2; 

     vmovdqa ymm0, [rcx + r8 - 64]; 
     vmovdqa ymm1, [rdx + r8 - 64]; 

     vmovdqa [rcx + r8 - 64], ymm1; 
     vmovdqa [rdx + r8 - 64], ymm0; 

     vmovdqa ymm2, [rcx + r8 - 32]; 
     vmovdqa ymm3, [rdx + r8 - 32]; 

     vmovdqa [rcx + r8 - 32], ymm3; 
     vmovdqa [rdx + r8 - 32], ymm2; 
   jmp @unrolloop;
   @unrolloopend:

   sub r8, 128;
   jz @endfunc;

   @loop2:
     add r8, 16;
     jg @loop2End;

     vmovdqa xmm0, [rcx + r8 - 16]; 
     vmovdqa xmm1, [rdx + r8 - 16]; 

     vmovdqa [rcx + r8 - 16], xmm1; 
     vmovdqa [rdx + r8 - 16], xmm0; 
   jmp @loop2;

   @loop2End:
   sub r8, 16;

   jz @endfunc;

   vmovss xmm0, [rcx + r8]; 
   vmovss xmm1, [rdx + r8]; 

   vmovss [rcx + r8], xmm1; 
   vmovss [rdx + r8], xmm0; 

   @endfunc:

   vzeroupper; 
end;

procedure AVXRowSwapUnAligned(A, B : PSingle; width : NativeInt); assembler;
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

   // note: RCX = a, RDX = b, R8 = width
   imul r8, -4;

   sub rcx, r8;
   sub rdx, r8;

   @unrolloop:
     add r8, 128;
     jg @unrolloopend;

     // prefetch data...
     // prefetchw [rcx + r10];
     // prefetchw [rdx + r10];

     vmovdqu ymm0, [rcx + r8 - 128]; 
     vmovdqu ymm1, [rdx + r8 - 128]; 

     vmovdqu [rcx + r8 - 128], ymm1; 
     vmovdqu [rdx + r8 - 128], ymm0; 

     vmovdqu ymm2, [rcx + r8 - 96]; 
     vmovdqu ymm3, [rdx + r8 - 96]; 

     vmovdqu [rcx + r8 - 96], ymm3; 
     vmovdqu [rdx + r8 - 96], ymm2; 

     vmovdqu ymm0, [rcx + r8 - 64]; 
     vmovdqu ymm1, [rdx + r8 - 64]; 

     vmovdqu [rcx + r8 - 64], ymm1; 
     vmovdqu [rdx + r8 - 64], ymm0; 

     vmovdqu ymm2, [rcx + r8 - 32]; 
     vmovdqu ymm3, [rdx + r8 - 32]; 

     vmovdqu [rcx + r8 - 32], ymm3; 
     vmovdqu [rdx + r8 - 32], ymm2; 
   jmp @unrolloop;
   @unrolloopend:

   sub r8, 128;
   jz @endfunc;

   @loop2:
     add r8, 16;
     jg @loop2End;

     vmovdqu xmm0, [rcx + r8 - 16]; 
     vmovdqu xmm1, [rdx + r8 - 16]; 

     vmovdqu [rcx + r8 - 16], xmm1; 
     vmovdqu [rdx + r8 - 16], xmm0; 
   jmp @loop2;

   @loop2End:
   sub r8, 16;

   jz @endfunc;

   vmovss xmm0, [rcx + r8]; 
   vmovss xmm1, [rdx + r8]; 

   vmovss [rcx + r8], xmm1; 
   vmovss [rdx + r8], xmm0; 

   @endfunc:

   vzeroupper; 
end;

procedure AVXMatrixCopyAligned(Dest : PSingle; const destLineWidth : NativeInt; src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   //iters := -width*sizeof(single);
   mov r10, width;
   imul r10, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetchw [rcx + rax];

           // move:
           vmovdqa ymm0, [r8 + rax - 128]; 
           vmovdqa [rcx + rax - 128], ymm0; 

           vmovdqa ymm1, [r8 + rax - 96]; 
           vmovdqa [rcx + rax - 96], ymm1; 

           vmovdqa ymm2, [r8 + rax - 64]; 
           vmovdqa [rcx + rax - 64], ymm2; 

           vmovdqa ymm3, [r8 + rax - 32]; 
           vmovdqa [rcx + rax - 32], ymm3; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
          add rax, 16;
          jg @loopEnd2;

          vmovdqa xmm0, [r8 + rax - 16]; 
          vmovdqa [rcx + rax - 16], xmm0; 
       jmp @addforxloop2;

       @loopEnd2:
       sub rax, 16;

       jz @nextLine;

       // last element
       vmovss xmm0, [r8 + rax]; 
       vmovss [rcx + rax], xmm0; 

       @nextLine:

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   vzeroupper; 
end;

procedure AVXMatrixCopyUnAligned(Dest : PSingle; const destLineWidth : NativeInt; src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   //iters := -width*sizeof(single);
   mov r10, width;
   imul r10, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetchw [rcx + rax];

           // move:
           vmovdqu ymm0, [r8 + rax - 128]; 
           vmovdqu [rcx + rax - 128], ymm0; 

           vmovdqu ymm1, [r8 + rax - 96]; 
           vmovdqu [rcx + rax - 96], ymm1; 

           vmovdqu ymm2, [r8 + rax - 64]; 
           vmovdqu [rcx + rax - 64], ymm2; 

           vmovdqu ymm3, [r8 + rax - 32]; 
           vmovdqu [rcx + rax - 32], ymm3; 

       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
          add rax, 16;
          jg @loopEnd2;

          vmovdqu xmm0, [r8 + rax - 16]; 
          vmovdqu [rcx + rax - 16], xmm0; 
       jmp @addforxloop2;

       @loopEnd2:
       sub rax, 16;

       jz @nextLine;

       // last element
       vmovss xmm0, [r8 + rax]; 
       vmovss [rcx + rax], xmm0; 

       @nextLine:

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   vzeroupper; 
end;

{$ENDIF}

end.
