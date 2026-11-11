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


unit ASMMatrixMeanOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

uses MatrixConstSingle;

{$IFDEF CPUX64}

procedure ASMMatrixMeanRowAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixMeanRowUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixMeanRowAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixMeanRowUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure ASMMatrixMeanColumnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixMeanColumnUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixMeanColumnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure ASMMatrixMeanColumnUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure ASMMatrixVarRowAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure ASMMatrixVarRowUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure ASMMatrixVarRowAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure ASMMatrixVarRowUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;

procedure ASMMatrixVarColumnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure ASMMatrixVarColumnUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure ASMMatrixVarColumnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure ASMMatrixVarColumnUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;

// combined methods
procedure ASMMatrixMeanVarRowAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure ASMMatrixMeanVarRowUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure ASMMatrixMeanVarRowAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure ASMMatrixMeanVarRowUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;

procedure ASMMatrixMeanVarColumnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure ASMMatrixMeanVarColumnUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure ASMMatrixMeanVarColumnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure ASMMatrixMeanVarColumnUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;


{$ENDIF}

implementation

{$IFDEF CPUX64}


// ###########################################
// #### Mean
// ###########################################
//
// One kernel per reduction direction; the column kernel scatters its result with
// destLineWidth. Neither extent has to be a whole number of lanes. The
// *Aligned*/*OddW* twins only carried alignment/parity hints and forward.

procedure ASMMatrixMeanRowUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = Src, r9 = srcLineWidth
//
// dest[y] := sum(x) Src[y][x] / width. Eight elements per iteration, then a four
// element step, then a scalar tail, so every width is covered.
var iWidth, iHeight : NativeInt;
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

   mov rax, width;              // width/height live on the stack here, so they
   mov iWidth, rax;             // are staged through a register
   mov rax, height;
   mov iHeight, rax;

   mov r10, iHeight;
   test r10, r10;
   jle @@done;

   mov rax, iWidth;
   test rax, rax;
   jle @@done;

   // xmm5 := width, the mean divides every row sum by it
   cvtsi2ss xmm5, rax;

   @@foryloop:
       xorps xmm0, xmm0;         // lane accumulator
       xorps xmm4, xmm4;         // second lane accumulator
       xorps xmm3, xmm3;         // scalar tail accumulator
       xor r11, r11;             // byte offset into the row

       mov rax, iWidth;
       shr rax, 3;               // whole eight element blocks
       jz @@tail4;

       @@vecloop:
           movups xmm1, [r8 + r11];
           movups xmm2, [r8 + r11 + 16];
           addps xmm0, xmm1;
           addps xmm4, xmm2;
           add r11, 32;
       dec rax;
       jnz @@vecloop;

       @@tail4:
       mov rax, iWidth;
       and rax, 4;               // one leftover four element block
       jz @@tail1;
       movups xmm1, [r8 + r11];
       addps xmm0, xmm1;
       add r11, 16;

       @@tail1:
       mov rax, iWidth;
       and rax, 3;               // zero to three leftover elements
       jz @@reduce;

       @@tailloop:
           movss xmm1, [r8 + r11];
           addss xmm3, xmm1;
           add r11, 4;
       dec rax;
       jnz @@tailloop;

       @@reduce:
       // fold the eight lanes into lane 0, then add the scalar tail
       addps xmm0, xmm4;
       movaps xmm2, xmm0;
       shufps xmm2, xmm2, $4E;
       addps xmm0, xmm2;
       movaps xmm2, xmm0;
       shufps xmm2, xmm2, $B1;
       addps xmm0, xmm2;
       addss xmm0, xmm3;

       divss xmm0, xmm5;         // mean := sum / width

       movss [rcx], xmm0;

       add rcx, rdx;
       add r8, r9;
   dec r10;
   jnz @@foryloop;

   @@done:
end;
procedure ASMMatrixMeanRowAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
asm
   call ASMMatrixMeanRowUnAlignedEvenW;
end;
procedure ASMMatrixMeanRowAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
asm
   call ASMMatrixMeanRowUnAlignedEvenW;
end;
procedure ASMMatrixMeanRowUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
asm
   call ASMMatrixMeanRowUnAlignedEvenW;
end;
procedure ASMMatrixMeanColumnUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = Src, r9 = srcLineWidth
//
// dest[x] := sum(y) Src[y][x] / height. Eight columns per iteration, then a
// scalar tail, so every width is covered. A block result is written with one
// 32 byte store when the destination is tight and lane by lane otherwise, which
// is what makes a padded destLineWidth work.
var iWidth, iHeight, iBlocks, iOff : NativeInt;
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

   mov rax, width;              // width/height live on the stack here, so they
   mov iWidth, rax;             // are staged through a register
   mov rax, height;
   mov iHeight, rax;

   mov rax, iHeight;
   test rax, rax;
   jle @@done;

   mov rax, iWidth;
   test rax, rax;
   jle @@done;

   // xmm5 := height in every lane, the mean divides every column sum by it
   mov rax, iHeight;
   cvtsi2ss xmm5, rax;
   shufps xmm5, xmm5, 0;

   mov rax, iWidth;
   shr rax, 3;
   mov iBlocks, rax;
   xor rax, rax;
   mov iOff, rax;               // byte offset of the current column block
   mov rax, iBlocks;
   test rax, rax;
   jz @@tail;

   @@vecloop:
       xorps xmm1, xmm1;         // columns x .. x+3
       xorps xmm2, xmm2;         // columns x+4 .. x+7

       mov rax, r8;
       add rax, iOff;
       mov r10, iHeight;

       @@rowloop:
           movups xmm0, [rax];
           addps xmm1, xmm0;
           movups xmm3, [rax + 16];
           addps xmm2, xmm3;
           add rax, r9;
       dec r10;
       jnz @@rowloop;

       divps xmm1, xmm5;
       divps xmm2, xmm5;

       cmp rdx, 4;               // tight destination?
       jne @@scatter;

       movups [rcx], xmm1;
       movups [rcx + 16], xmm2;
       add rcx, 32;
       jmp @@nextblock;

       @@scatter:
           movss [rcx], xmm1;
           add rcx, rdx;
           shufps xmm1, xmm1, $39;
           movss [rcx], xmm1;
           add rcx, rdx;
           shufps xmm1, xmm1, $39;
           movss [rcx], xmm1;
           add rcx, rdx;
           shufps xmm1, xmm1, $39;
           movss [rcx], xmm1;
           add rcx, rdx;
           movss [rcx], xmm2;
           add rcx, rdx;
           shufps xmm2, xmm2, $39;
           movss [rcx], xmm2;
           add rcx, rdx;
           shufps xmm2, xmm2, $39;
           movss [rcx], xmm2;
           add rcx, rdx;
           shufps xmm2, xmm2, $39;
           movss [rcx], xmm2;
           add rcx, rdx;

       @@nextblock:
       add iOff, 32;
   dec iBlocks;
   jnz @@vecloop;

   @@tail:
   // the uncovered zero to seven columns are reduced one column at a time
   mov rax, iWidth;
   and rax, 7;
   jz @@done;

   @@tailcol:
       xorps xmm1, xmm1;
       mov r10, r8;
       add r10, iOff;
       mov r11, iHeight;

       @@tailrowloop:
           movss xmm0, [r10];
           addss xmm1, xmm0;
           add r10, r9;
       dec r11;
       jnz @@tailrowloop;

       divss xmm1, xmm5;
       movss [rcx], xmm1;
       add rcx, rdx;
       add iOff, 4;
   dec rax;
   jnz @@tailcol;

   @@done:
end;
procedure ASMMatrixMeanColumnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
asm
   call ASMMatrixMeanColumnUnAlignedEvenW;
end;
procedure ASMMatrixMeanColumnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
asm
   call ASMMatrixMeanColumnUnAlignedEvenW;
end;
procedure ASMMatrixMeanColumnUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
asm
   call ASMMatrixMeanColumnUnAlignedEvenW;
end;
// ###########################################
// #### Variance calculation
// ###########################################


procedure ASMMatrixVarRowAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
var dXMM5 : Array[0..3] of single;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth

   // prolog
   movups dXMM5, xmm5;

   // iters := -width*sizeof(single)
   mov r10, width;
   shl r10, 2;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, width;
   cvtsi2ss xmm5, rax;
   {$ELSE}
   cvtsi2ss xmm5, width;
   {$ENDIF}

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       xorps xmm0, xmm0;
       xorps xmm1, xmm1;
       xorps xmm2, xmm2;
       xorps xmm3, xmm3;

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [r8 + rax];

           // addition:
           addps xmm0, [r8 + rax - 128];
           addps xmm1, [r8 + rax - 112];
           addps xmm1, [r8 + rax - 96];
           addps xmm3, [r8 + rax - 80];
           addps xmm0, [r8 + rax - 64];
           addps xmm1, [r8 + rax - 48];
           addps xmm2, [r8 + rax - 32];
           addps xmm3, [r8 + rax - 16];
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           addps xmm0, [r8 + rax];
       add rax, 16;
       jnz @addforxloop2;

       @buildRes:

       addps xmm0, xmm1;
       addps xmm2, xmm3;
       addps xmm0, xmm2;

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;

       divss xmm0, xmm5;

       // we have calculated the mean -> 
       // repeat the loop to calculate the variance

       movss xmm4, xmm0; shufps xmm4, xmm4, 0;
       xorps xmm0, xmm0;
            
       // for x := 0 to w - 1;
       // prepare for reverse loop
       // variance = sum (x - mean)^2
       mov rax, r10;
       @addforxloop3:
           add rax, 128;
           jg @loopEnd2;
           // prefetch data...
           // prefetch [ecx + rax];

           // addition:
           movaps xmm1, [r8 + rax - 128];
           movaps xmm2, [r8 + rax - 112];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
           movaps xmm1, [r8 + rax - 96];
           movaps xmm2, [r8 + rax - 80];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
           movaps xmm1, [r8 + rax - 64];
           movaps xmm2, [r8 + rax - 48];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
           movaps xmm1, [r8 + rax - 32];
           movaps xmm2, [r8 + rax - 16];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
       jmp @addforxloop3

       @loopEnd2:

       sub rax, 128;

       jz @buildRes2;

       @addforxloop4:
           movaps xmm1, [r8 + rax];
           subps xmm1, xmm4;
           mulps xmm1, xmm1;
           addps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop4;

       @buildRes2:

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;
            
       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movss xmm4, xmm5;

       subss xmm4, [rip + cOnes];
       maxss xmm4, [rip + cOnes];

       divss xmm0, xmm4;

       jmp @@writeRes;

       @@dobiased:
       divss xmm0, xmm5;
            
       // write result
       @@writeRes:
       movss [rcx], xmm0;

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog
   movups xmm5, dXMM5;
end;

procedure ASMMatrixVarRowUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
var dXMM5 : Array[0..3] of single;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth

   // prolog
   movups dXMM5, xmm5;

   // iters := -width*sizeof(single)
   mov r10, width;
   shl r10, 2;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, width;
   cvtsi2ss xmm5, rax;
   {$ELSE}
   cvtsi2ss xmm5, width;
   {$ENDIF}

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       xorps xmm0, xmm0;

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [r8 + rax];

           // addition:
           movups xmm1, [r8 + rax - 128];
           addps xmm0, xmm1;

           movups xmm2, [r8 + rax - 112];
           addps xmm0, xmm2;

           movups xmm3, [r8 + rax - 96];
           addps xmm0, xmm3;

           movups xmm4, [r8 + rax - 80];
           addps xmm0, xmm4;

           movups xmm1, [r8 + rax - 64];
           addps xmm0, xmm1;

           movups xmm2, [r8 + rax - 48];
           addps xmm0, xmm2;

           movups xmm3, [r8 + rax - 32];
           addps xmm0, xmm3;

           movups xmm4, [r8 + rax - 16];
           addps xmm0, xmm4;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           movups xmm1, [r8 + rax];
           addps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @buildRes:

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;

       divss xmm0, xmm5;

       // we have calculated the mean -> 
       // repeat the loop to calculate the variance

       movss xmm4, xmm0; shufps xmm4, xmm4, 0;
       xorps xmm0, xmm0;
            
       // for x := 0 to w - 1;
       // prepare for reverse loop
       // variance = sum (x - mean)^2
       mov rax, r10;
       @addforxloop3:
           add rax, 128;
           jg @loopEnd2;
           // prefetch data...
           // prefetch [r8 + rax];

           // addition:
           movups xmm1, [r8 + rax - 128];
           movups xmm2, [r8 + rax - 112];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
           movups xmm1, [r8 + rax - 96];
           movups xmm2, [r8 + rax - 80];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
           movups xmm1, [r8 + rax - 64];
           movups xmm2, [r8 + rax - 48];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
           movups xmm1, [r8 + rax - 32];
           movups xmm2, [r8 + rax - 16];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
       jmp @addforxloop3

       @loopEnd2:

       sub rax, 128;

       jz @buildRes2;

       @addforxloop4:
           movups xmm1, [r8 + rax];
           subps xmm1, xmm4;
           mulps xmm1, xmm1;
           addps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop4;

       @buildRes2:

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;
            
       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movss xmm4, xmm5;
       subss xmm4, [rip + cOnes];
       maxss xmm4, [rip + cOnes];

       divss xmm0, xmm4;

       jmp @@writeRes;

       @@dobiased:
       divss xmm0, xmm5;
            
       // write result
       @@writeRes:
       movss [rcx], xmm0;

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog
   movups xmm5, dXMM5;
end;

procedure ASMMatrixVarRowAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
var dXMM5 : Array[0..3] of single;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth

   // prolog
   movups dXMM5, xmm5;

   // iters := -width*sizeof(single)
   mov r10, width;
   dec r10;
   shl r10, 2;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, width;
   cvtsi2ss xmm5, rax;
   {$ELSE}
   cvtsi2ss xmm5, width;
   {$ENDIF}

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       xorps xmm0, xmm0;
       xorps xmm1, xmm1;
       xorps xmm2, xmm2;
       xorps xmm3, xmm3;

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;
            // prefetch data...
           // prefetch [r8 + rax];

           // addition:
           addps xmm0, [r8 + rax - 128];
           addps xmm1, [r8 + rax - 112];
           addps xmm1, [r8 + rax - 96];
           addps xmm3, [r8 + rax - 80];
           addps xmm0, [r8 + rax - 64];
           addps xmm1, [r8 + rax - 48];
           addps xmm2, [r8 + rax - 32];
           addps xmm3, [r8 + rax - 16];
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           addps xmm0, [r8 + rax];
       add rax, 16;
       jnz @addforxloop2;

       @buildRes:

       addps xmm0, xmm1;
       addps xmm2, xmm3;
       addps xmm0, xmm2;

       // handle last element differently
       movss xmm2, [r8 + rax];
       addss xmm0, xmm2;

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;

       divss xmm0, xmm5;

       // we have calculated the mean -> 
       // repeat the loop to calculate the variance

       movss xmm4, xmm0; shufps xmm4, xmm4, 0;
       xorps xmm0, xmm0;
            
       // for x := 0 to w - 1;
       // prepare for reverse loop
       // variance = sum (x - mean)^2
       mov rax, r10;
       @addforxloop3:
           add rax, 128;
           jg @loopEnd2;
           // prefetch data...
           // prefetch [ecx + rax];

           // addition:
           movaps xmm1, [r8 + rax - 128];
           movaps xmm2, [r8 + rax - 112];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
           movaps xmm1, [r8 + rax - 96];
           movaps xmm2, [r8 + rax - 80];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
           movaps xmm1, [r8 + rax - 64];
           movaps xmm2, [r8 + rax - 48];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
           movaps xmm1, [r8 + rax - 32];
           movaps xmm2, [r8 + rax - 16];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
       jmp @addforxloop3

       @loopEnd2:

       sub rax, 128;

       jz @buildRes2;

       @addforxloop4:
           movaps xmm1, [r8 + rax];
           subps xmm1, xmm4;
           mulps xmm1, xmm1;
           addps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop4;

       @buildRes2:

       // handle last element differently
       movss xmm1, [r8 + rax];
       subss xmm1, xmm4;
       mulss xmm1, xmm1;
       addss xmm0, xmm1;

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;
            
       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movss xmm4, xmm5;
       subss xmm4, [rip + cOnes];
       maxss xmm4, [rip + cOnes];

       divss xmm0, xmm4;

       jmp @@writeRes;

       @@dobiased:
       divss xmm0, xmm5;
            
       // write result
       @@writeRes:
       movss [rcx], xmm0;

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog
   movups xmm5, dXMM5;
end;


procedure ASMMatrixVarRowUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
var dXMM5, dXMM4 : Array[0..3] of single;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth

   // prolog
   movups dXMM5, xmm5;
   movups dXMM4, xmm4;

   // iters := -width*sizeof(single)
   mov r10, width;
   dec r10;
   shl r10, 2;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, width;
   cvtsi2ss xmm5, rax;
   {$ELSE}
   cvtsi2ss xmm5, width;
   {$ENDIF}

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       xorps xmm0, xmm0;

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // addition:
           movups xmm1, [r8 + rax - 128];
           addps xmm0, xmm1;

           movups xmm2, [r8 + rax - 112];
           addps xmm0, xmm2;

           movups xmm3, [r8 + rax - 96];
           addps xmm0, xmm3;

           movups xmm4, [r8 + rax - 80];
           addps xmm0, xmm4;

           movups xmm1, [r8 + rax - 64];
           addps xmm0, xmm1;

           movups xmm2, [r8 + rax - 48];
           addps xmm0, xmm2;

           movups xmm3, [r8 + rax - 32];
           addps xmm0, xmm3;

           movups xmm4, [r8 + rax - 16];
           addps xmm0, xmm4;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           movups xmm1, [r8 + rax];
           addps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @buildRes:

       // handle last element differently
       movss xmm2, [r8 + rax];
       addss xmm0, xmm2;

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;

       divss xmm0, xmm5;

       // we have calculated the mean -> 
       // repeat the loop to calculate the variance

       movss xmm4, xmm0; shufps xmm4, xmm4, 0;
       xorps xmm0, xmm0;
            
       // for x := 0 to w - 1;
       // prepare for reverse loop
       // variance = sum (x - mean)^2
       mov rax, r10;
       @addforxloop3:
           add rax, 128;
           jg @loopEnd2;
           // prefetch data...
           // prefetch [ecx + rax];

           // addition:
           movups xmm1, [r8 + rax - 128];
           movups xmm2, [r8 + rax - 112];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
           movups xmm1, [r8 + rax - 96];
           movups xmm2, [r8 + rax - 80];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
           movups xmm1, [r8 + rax - 64];
           movups xmm2, [r8 + rax - 48];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
           movups xmm1, [r8 + rax - 32];
           movups xmm2, [r8 + rax - 16];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;
                
       jmp @addforxloop3

       @loopEnd2:

       sub rax, 128;

       jz @buildRes2;

       @addforxloop4:
           movups xmm1, [r8 + rax];
           subps xmm1, xmm4;
           mulps xmm1, xmm1;
           addps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop4;

       @buildRes2:

       // handle last element differently
       movss xmm1, [r8 + rax];
       subss xmm1, xmm4;
       mulss xmm1, xmm1;
       addss xmm0, xmm1;

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;
            
       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movss xmm4, xmm5;
       subss xmm4, [rip + cOnes];
       maxss xmm4, [rip + cOnes];

       divss xmm0, xmm4;

       jmp @@writeRes;

       @@dobiased:
       divss xmm0, xmm5;
            
       // write result
       @@writeRes:
       movss [rcx], xmm0;

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog
   movups xmm5, dXMM5;
   movups xmm4, dXMM4;
end;

procedure ASMMatrixVarColumnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
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
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   // according to microsoft the xmm5 does not need to be saved (volatile!)
   movups xmm5, [rip + cOnes];

   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, height;
   cvtsi2ss xmm0, rax;
   {$ELSE}
   cvtsi2ss xmm0, height;
   {$ENDIF}
   movss xmm2, xmm0; shufps xmm2, xmm2, 0;

   // for x := 0 to width - 1:
   mov r11, Width;
   sar r11, 1;
   @@addforxloop:
       xorps xmm0, xmm0;

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforyloop:
           addps xmm0, [r8 + rax];
       add rax, r9;
       jnz @addforyloop;

       // build mean
       divps xmm0, xmm2;

       // calculate final standard deviation
       // for y := 0 to height - 1;
       // prepare for reverse loop
       xorps xmm4, xmm4;
       mov rax, r10;
       @addforyloop2:
           movaps xmm1, [r8 + rax];
           subps xmm1, xmm0;
           mulps xmm1, xmm1;
           addps xmm4, xmm1;
       add rax, r9;
       jnz @addforyloop2;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movaps xmm3, xmm2;
       subps xmm3, xmm5;
       maxps xmm3, xmm5;

       divps xmm4, xmm3;

       jmp @@writeRes;

       @@dobiased:
       divps xmm4, xmm2;

       // write result
       @@writeRes:
       movaps [rcx], xmm4;

       // next columns:
       add rcx, 16;
       add r8, 16;

   // loop x end
   dec r11;
   jnz @@addforxloop;
end;

procedure ASMMatrixVarColumnUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
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
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   movups xmm5, [rip + cOnes];
   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, height;
   cvtsi2ss xmm0, rax;
   {$ELSE}
   cvtsi2ss xmm0, height;
   {$ENDIF}
   movss xmm2, xmm0; shufps xmm2, xmm2, 0;

   // for x := 0 to width - 1:
   mov r11, Width;
   sar r11, 1;
   @@addforxloop:
       xorps xmm0, xmm0;

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforyloop:
           movups xmm1, [r8 + rax];
           addps xmm0, xmm1;
       add rax, r9;
       jnz @addforyloop;

       // build mean
       divps xmm0, xmm2;

       // calculate final standard deviation
       // for y := 0 to height - 1;
       // prepare for reverse loop
       xorps xmm4, xmm4;
       mov rax, r10;
       @addforyloop2:
           movups xmm1, [r8 + rax];
           subps xmm1, xmm0;
           mulps xmm1, xmm1;
           addps xmm4, xmm1;
       add rax, r9;
       jnz @addforyloop2;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movaps xmm3, xmm2;
       subps xmm3, xmm5;
       maxps xmm3, xmm5;

       divps xmm4, xmm3;

       jmp @@writeRes;

       @@dobiased:
       divps xmm4, xmm2;

       // write result
       @@writeRes:
       movups [rcx], xmm4;

       // next columns:
       add rcx, 16;
       add r8, 16;

   // loop x end
   dec r11;
   jnz @@addforxloop;
end;

procedure ASMMatrixVarColumnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
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
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   movups xmm5, [rip + cOnes];
   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, height;
   cvtsi2ss xmm0, rax;
   {$ELSE}
   cvtsi2ss xmm0, height;
   {$ENDIF}
   movss xmm2, xmm0; shufps xmm2, xmm2, 0;

   // for x := 0 to width - 1:
   mov r11, Width;
   sar r11, 1;
   jz @lastColumn;
   @@addforxloop:
       xorps xmm0, xmm0;

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforyloop:
           addps xmm0, [r8 + rax];
       add rax, r9;
       jnz @addforyloop;

       // build result
       divps xmm0, xmm2;

       // calculate final standard deviation
       // for y := 0 to height - 1;
       // prepare for reverse loop
       xorps xmm4, xmm4;
       mov rax, r10;
       @addforyloop2:
           movaps xmm1, [r8 + rax];
           subps xmm1, xmm0;
           mulps xmm1, xmm1;
           addps xmm4, xmm1;
       add rax, r9;
       jnz @addforyloop2;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movaps xmm1, xmm2;
       subps xmm1, xmm5;
       maxps xmm1, xmm5;

       divps xmm4, xmm1;

       jmp @@writeRes;

       @@dobiased:
       divps xmm4, xmm2;

       // write result
       @@writeRes:
       movaps [rcx], xmm4;

       // next columns:
       add rcx, 16;
       add r8, 16;

   // loop x end
   dec r11;
   jnz @@addforxloop;

   @lastColumn:
   
   // handle last column
   xorps xmm0, xmm0;

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop3:
       movss xmm1, [r8 + rax];
       addss xmm0, xmm1;
   add rax, r9;
   jnz @addforyloop3;

   // build result
   divss xmm0, xmm2;

   // calculate final standard deviation
   // for y := 0 to height - 1;
   // prepare for reverse loop
   xorps xmm4, xmm4;
   mov rax, r10;
   @addforyloop4:
       movss xmm1, [r8 + rax];
       subss xmm1, xmm0;
       mulss xmm1, xmm1;
       addss xmm4, xmm1;
   add rax, r9;
   jnz @addforyloop4;

   // check if we need to use the unbiased version
   cmp unbiased, 0;
   jz @@dobiased2;

   movaps xmm1, xmm2;
   subss xmm1, [rip + cOnes];
   maxss xmm1, [rip + cOnes];

   divss xmm4, xmm1;

   jmp @@writeRes2;

   @@dobiased2:
   divss xmm4, xmm2;

   // write result
   @@writeRes2:
   movss [rcx], xmm4;
end;

procedure ASMMatrixVarColumnUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
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
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   movups xmm5, [rip + cOnes];
   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, height;
   cvtsi2ss xmm0, rax;
   {$ELSE}
   cvtsi2ss xmm0, height;
   {$ENDIF}
   movss xmm2, xmm0; shufps xmm2, xmm2, 0;

   // for x := 0 to width - 1:
   mov r11, Width;
   sar r11, 1;
   jz @lastColumn;
   @@addforxloop:
       xorps xmm0, xmm0;

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforyloop:
           movups xmm1, [r8 + rax];
           addps xmm0, xmm1;
       add rax, r9;
       jnz @addforyloop;

       // build result
       divps xmm0, xmm2;

       // calculate final standard deviation
       // for y := 0 to height - 1;
       // prepare for reverse loop
       xorps xmm4, xmm4;
       mov rax, r10;
       @addforyloop2:
           movups xmm1, [r8 + rax];
           subps xmm1, xmm0;
           mulps xmm1, xmm1;
           addps xmm4, xmm1;
       add rax, r9;
       jnz @addforyloop2;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movaps xmm1, xmm2;
       subps xmm1, xmm5;
       maxps xmm1, xmm5;

       divps xmm4, xmm1;

       jmp @@writeRes;

       @@dobiased:
       divps xmm4, xmm2;

       // write result
       @@writeRes:
       movups [rcx], xmm4;

       // next columns:
       add rcx, 16;
       add r8, 16;

   // loop x end
   dec r11;
   jnz @@addforxloop;

   @lastColumn:
   
   // handle last column
   xorps xmm0, xmm0;

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop3:
       movss xmm1, [r8 + rax];
       addss xmm0, xmm1;
   add rax, r9;
   jnz @addforyloop3;

   // build result
   divss xmm0, xmm2;

   // calculate final standard deviation
   // for y := 0 to height - 1;
   // prepare for reverse loop
   xorps xmm4, xmm4;
   mov rax, r10;
   @addforyloop4:
       movss xmm1, [r8 + rax];
       subss xmm1, xmm0;
       mulss xmm1, xmm1;
       addss xmm4, xmm1;
   add rax, r9;
   jnz @addforyloop4;

   // check if we need to use the unbiased version
   cmp unbiased, 0;
   jz @@dobiased2;

   movaps xmm1, xmm2;
   subss xmm1, [rip + cOnes];
   maxss xmm1, [rip + cOnes];

   divss xmm4, xmm1;

   jmp @@writeRes2;

   @@dobiased2:
   divss xmm4, xmm2;

   // write result
   @@writeRes2:
   movss [rcx], xmm4;
end;


// #####################################################
// #### Combined mean variance calculation
// #####################################################

procedure ASMMatrixMeanVarRowAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
var dXMM5 : Array[0..3] of single;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth

   // prolog
   movups dXMM5, xmm5;

   // iters := -width*sizeof(single)
   mov r10, width;
   shl r10, 2;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, width;
   cvtsi2ss xmm5, rax;
   {$ELSE}
   cvtsi2ss xmm5, width;
   {$ENDIF}

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       xorps xmm0, xmm0;
       xorps xmm1, xmm1;
       xorps xmm2, xmm2;
       xorps xmm3, xmm3;

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [r8 + rax];

           // addition:
           addps xmm0, [r8 + rax - 128];
           addps xmm1, [r8 + rax - 112];
           addps xmm1, [r8 + rax - 96];
           addps xmm3, [r8 + rax - 80];
           addps xmm0, [r8 + rax - 64];
           addps xmm1, [r8 + rax - 48];
           addps xmm2, [r8 + rax - 32];
           addps xmm3, [r8 + rax - 16];
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           addps xmm0, [r8 + rax];
       add rax, 16;
       jnz @addforxloop2;

       @buildRes:

       addps xmm0, xmm1;
       addps xmm2, xmm3;
       addps xmm0, xmm2;

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;

       divss xmm0, xmm5;
       movss [rcx], xmm0;

       // we have calculated the mean ->
       // repeat the loop to calculate the variance

       movss xmm4, xmm0; shufps xmm4, xmm4, 0;
       xorps xmm0, xmm0;

       // for x := 0 to w - 1;
       // prepare for reverse loop
       // variance = sum (x - mean)^2
       mov rax, r10;
       @addforxloop3:
           add rax, 128;
           jg @loopEnd2;
           // prefetch data...
           // prefetch [ecx + rax];

           // addition:
           movaps xmm1, [r8 + rax - 128];
           movaps xmm2, [r8 + rax - 112];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

           movaps xmm1, [r8 + rax - 96];
           movaps xmm2, [r8 + rax - 80];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

           movaps xmm1, [r8 + rax - 64];
           movaps xmm2, [r8 + rax - 48];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

           movaps xmm1, [r8 + rax - 32];
           movaps xmm2, [r8 + rax - 16];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

       jmp @addforxloop3

       @loopEnd2:

       sub rax, 128;

       jz @buildRes2;

       @addforxloop4:
           movaps xmm1, [r8 + rax];
           subps xmm1, xmm4;
           mulps xmm1, xmm1;
           addps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop4;

       @buildRes2:

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movss xmm4, xmm5;

       subss xmm4, [rip + cOnes];
       maxss xmm4, [rip + cOnes];

       divss xmm0, xmm4;

       jmp @@writeRes;

       @@dobiased:
       divss xmm0, xmm5;

       // write result
       @@writeRes:
       movss [rcx + 8], xmm0;

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog
   movups xmm5, dXMM5;
end;

procedure ASMMatrixMeanVarRowUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
var dXMM5 : Array[0..3] of single;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth

   // prolog
   movups dXMM5, xmm5;

   // iters := -width*sizeof(single)
   mov r10, width;
   shl r10, 2;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, width;
   cvtsi2ss xmm5, rax;
   {$ELSE}
   cvtsi2ss xmm5, width;
   {$ENDIF}

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       xorps xmm0, xmm0;

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [r8 + rax];

           // addition:
           movups xmm1, [r8 + rax - 128];
           addps xmm0, xmm1;

           movups xmm2, [r8 + rax - 112];
           addps xmm0, xmm2;

           movups xmm3, [r8 + rax - 96];
           addps xmm0, xmm3;

           movups xmm4, [r8 + rax - 80];
           addps xmm0, xmm4;

           movups xmm1, [r8 + rax - 64];
           addps xmm0, xmm1;

           movups xmm2, [r8 + rax - 48];
           addps xmm0, xmm2;

           movups xmm3, [r8 + rax - 32];
           addps xmm0, xmm3;

           movups xmm4, [r8 + rax - 16];
           addps xmm0, xmm4;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           movups xmm1, [r8 + rax];
           addps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @buildRes:

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;

       divss xmm0, xmm5;
       movss [rcx], xmm0;

       // we have calculated the mean ->
       // repeat the loop to calculate the variance

       movss xmm4, xmm0; shufps xmm4, xmm4, 0;
       xorps xmm0, xmm0;

       // for x := 0 to w - 1;
       // prepare for reverse loop
       // variance = sum (x - mean)^2
       mov rax, r10;
       @addforxloop3:
           add rax, 128;
           jg @loopEnd2;
           // prefetch data...
           // prefetch [r8 + rax];

           // addition:
           movups xmm1, [r8 + rax - 128];
           movups xmm2, [r8 + rax - 112];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

           movups xmm1, [r8 + rax - 96];
           movups xmm2, [r8 + rax - 80];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

           movups xmm1, [r8 + rax - 64];
           movups xmm2, [r8 + rax - 48];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

           movups xmm1, [r8 + rax - 32];
           movups xmm2, [r8 + rax - 16];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

       jmp @addforxloop3

       @loopEnd2:

       sub rax, 128;

       jz @buildRes2;

       @addforxloop4:
           movups xmm1, [r8 + rax];
           subps xmm1, xmm4;
           mulps xmm1, xmm1;
           addps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop4;

       @buildRes2:

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movss xmm4, xmm5;
       subss xmm4, [rip + cOnes];
       maxss xmm4, [rip + cOnes];

       divss xmm0, xmm4;

       jmp @@writeRes;

       @@dobiased:
       divss xmm0, xmm5;

       // write result
       @@writeRes:
       movss [rcx + 8], xmm0;

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog
   movups xmm5, dXMM5;
end;

procedure ASMMatrixMeanVarRowAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
var dXMM5 : Array[0..3] of single;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth

   // prolog
   movups dXMM5, xmm5;

   // iters := -width*sizeof(single)
   mov r10, width;
   dec r10;
   shl r10, 2;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, width;
   cvtsi2ss xmm5, rax;
   {$ELSE}
   cvtsi2ss xmm5, width;
   {$ENDIF}

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       xorps xmm0, xmm0;
       xorps xmm1, xmm1;
       xorps xmm2, xmm2;
       xorps xmm3, xmm3;

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;
            // prefetch data...
           // prefetch [r8 + rax];

           // addition:
           addps xmm0, [r8 + rax - 128];
           addps xmm1, [r8 + rax - 112];
           addps xmm1, [r8 + rax - 96];
           addps xmm3, [r8 + rax - 80];
           addps xmm0, [r8 + rax - 64];
           addps xmm1, [r8 + rax - 48];
           addps xmm2, [r8 + rax - 32];
           addps xmm3, [r8 + rax - 16];
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           addps xmm0, [r8 + rax];
       add rax, 16;
       jnz @addforxloop2;

       @buildRes:

       addps xmm0, xmm1;
       addps xmm2, xmm3;
       addps xmm0, xmm2;

       // handle last element differently
       movss xmm2, [r8 + rax];
       addss xmm0, xmm2;

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;

       divss xmm0, xmm5;
       movss [rcx], xmm0;

       // we have calculated the mean ->
       // repeat the loop to calculate the variance

       movss xmm4, xmm0; shufps xmm4, xmm4, 0;
       xorps xmm0, xmm0;

       // for x := 0 to w - 1;
       // prepare for reverse loop
       // variance = sum (x - mean)^2
       mov rax, r10;
       @addforxloop3:
           add rax, 128;
           jg @loopEnd2;
           // prefetch data...
           // prefetch [ecx + rax];

           // addition:
           movaps xmm1, [r8 + rax - 128];
           movaps xmm2, [r8 + rax - 112];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

           movaps xmm1, [r8 + rax - 96];
           movaps xmm2, [r8 + rax - 80];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

           movaps xmm1, [r8 + rax - 64];
           movaps xmm2, [r8 + rax - 48];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

           movaps xmm1, [r8 + rax - 32];
           movaps xmm2, [r8 + rax - 16];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

       jmp @addforxloop3

       @loopEnd2:

       sub rax, 128;

       jz @buildRes2;

       @addforxloop4:
           movaps xmm1, [r8 + rax];
           subps xmm1, xmm4;
           mulps xmm1, xmm1;
           addps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop4;

       @buildRes2:

       // handle last element differently
       movss xmm1, [r8 + rax];
       subss xmm1, xmm4;
       mulss xmm1, xmm1;
       addss xmm0, xmm1;

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movss xmm4, xmm5;
       subss xmm4, [rip + cOnes];
       maxss xmm4, [rip + cOnes];

       divss xmm0, xmm4;

       jmp @@writeRes;

       @@dobiased:
       divss xmm0, xmm5;

       // write result
       @@writeRes:
       movss [rcx + 8], xmm0;

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog
   movups xmm5, dXMM5;
end;


procedure ASMMatrixMeanVarRowUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
var dXMM5, dXMM4 : Array[0..3] of single;
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

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth

   // prolog
   movups dXMM5, xmm5;
   movups dXMM4, xmm4;

   // iters := -width*sizeof(single)
   mov r10, width;
   dec r10;
   shl r10, 2;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, width;
   cvtsi2ss xmm5, rax;
   {$ELSE}
   cvtsi2ss xmm5, width;
   {$ENDIF}

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       xorps xmm0, xmm0;

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // addition:
           movups xmm1, [r8 + rax - 128];
           addps xmm0, xmm1;

           movups xmm2, [r8 + rax - 112];
           addps xmm0, xmm2;

           movups xmm3, [r8 + rax - 96];
           addps xmm0, xmm3;

           movups xmm4, [r8 + rax - 80];
           addps xmm0, xmm4;

           movups xmm1, [r8 + rax - 64];
           addps xmm0, xmm1;

           movups xmm2, [r8 + rax - 48];
           addps xmm0, xmm2;

           movups xmm3, [r8 + rax - 32];
           addps xmm0, xmm3;

           movups xmm4, [r8 + rax - 16];
           addps xmm0, xmm4;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           movups xmm1, [r8 + rax];
           addps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop2;

       @buildRes:

       // handle last element differently
       movss xmm2, [r8 + rax];
       addss xmm0, xmm2;

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;

       divss xmm0, xmm5;
       movss [rcx], xmm0;

       // we have calculated the mean ->
       // repeat the loop to calculate the variance

       movss xmm4, xmm0; shufps xmm4, xmm4, 0;
       xorps xmm0, xmm0;

       // for x := 0 to w - 1;
       // prepare for reverse loop
       // variance = sum (x - mean)^2
       mov rax, r10;
       @addforxloop3:
           add rax, 128;
           jg @loopEnd2;
           // prefetch data...
           // prefetch [ecx + rax];

           // addition:
           movups xmm1, [r8 + rax - 128];
           movups xmm2, [r8 + rax - 112];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

           movups xmm1, [r8 + rax - 96];
           movups xmm2, [r8 + rax - 80];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

           movups xmm1, [r8 + rax - 64];
           movups xmm2, [r8 + rax - 48];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

           movups xmm1, [r8 + rax - 32];
           movups xmm2, [r8 + rax - 16];
           subps xmm1, xmm4;
           subps xmm2, xmm4;
           mulps xmm1, xmm1;
           mulps xmm2, xmm2;
           addps xmm0, xmm1;
           addps xmm0, xmm2;

       jmp @addforxloop3

       @loopEnd2:

       sub rax, 128;

       jz @buildRes2;

       @addforxloop4:
           movups xmm1, [r8 + rax];
           subps xmm1, xmm4;
           mulps xmm1, xmm1;
           addps xmm0, xmm1;
       add rax, 16;
       jnz @addforxloop4;

       @buildRes2:

       // handle last element differently
       movss xmm1, [r8 + rax];
       subss xmm1, xmm4;
       mulss xmm1, xmm1;
       addss xmm0, xmm1;

       // build result
       haddps xmm0, xmm0; haddps xmm0, xmm0;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movss xmm4, xmm5;
       subss xmm4, [rip + cOnes];
       maxss xmm4, [rip + cOnes];

       divss xmm0, xmm4;

       jmp @@writeRes;

       @@dobiased:
       divss xmm0, xmm5;

       // write result
       @@writeRes:
       movss [rcx + 8], xmm0;

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog
   movups xmm5, dXMM5;
   movups xmm4, dXMM4;
end;

procedure ASMMatrixMeanVarColumnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
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
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   // according to microsoft the xmm5 does not need to be saved (volatile!)
   movups xmm5, [rip + cOnes];

   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, height;
   cvtsi2ss xmm0, rax;
   {$ELSE}
   cvtsi2ss xmm0, height;
   {$ENDIF}
   movss xmm2, xmm0; shufps xmm2, xmm2, 0;

   // for x := 0 to width - 1:
   mov r11, Width;
   sar r11, 1;
   @@addforxloop:
       xorps xmm0, xmm0;

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforyloop:
           addps xmm0, [r8 + rax];
       add rax, r9;
       jnz @addforyloop;

       // build mean
       divps xmm0, xmm2;
       movaps [rcx], xmm0;

       // calculate final standard deviation
       // for y := 0 to height - 1;
       // prepare for reverse loop
       xorps xmm4, xmm4;
       mov rax, r10;
       @addforyloop2:
           movaps xmm1, [r8 + rax];
           subps xmm1, xmm0;
           mulps xmm1, xmm1;
           addps xmm4, xmm1;
       add rax, r9;
       jnz @addforyloop2;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movaps xmm3, xmm2;
       subps xmm3, xmm5;
       maxps xmm3, xmm5;

       divps xmm4, xmm3;

       jmp @@writeRes;

       @@dobiased:
       divps xmm4, xmm2;

       // write result
       @@writeRes:
       movaps [rcx + rdx], xmm4;

       // next columns:
       add rcx, 16;
       add r8, 16;

   // loop x end
   dec r11;
   jnz @@addforxloop;
end;

procedure ASMMatrixMeanVarColumnUnAlignedEvenW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
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
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   movups xmm5, [rip + cOnes];
   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, height;
   cvtsi2ss xmm0, rax;
   {$ELSE}
   cvtsi2ss xmm0, height;
   {$ENDIF}
   movss xmm2, xmm0; shufps xmm2, xmm2, 0;

   // for x := 0 to width - 1:
   mov r11, Width;
   sar r11, 1;
   @@addforxloop:
       xorps xmm0, xmm0;

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforyloop:
           movups xmm1, [r8 + rax];
           addps xmm0, xmm1;
       add rax, r9;
       jnz @addforyloop;

       // build mean
       divps xmm0, xmm2;
       movups [rcx], xmm0;

       // calculate final standard deviation
       // for y := 0 to height - 1;
       // prepare for reverse loop
       xorps xmm4, xmm4;
       mov rax, r10;
       @addforyloop2:
           movups xmm1, [r8 + rax];
           subps xmm1, xmm0;
           mulps xmm1, xmm1;
           addps xmm4, xmm1;
       add rax, r9;
       jnz @addforyloop2;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movaps xmm3, xmm2;
       subps xmm3, xmm5;
       maxps xmm3, xmm5;

       divps xmm4, xmm3;

       jmp @@writeRes;

       @@dobiased:
       divps xmm4, xmm2;

       // write result
       @@writeRes:
       movups [rcx + rdx], xmm4;

       // next columns:
       add rcx, 16;
       add r8, 16;

   // loop x end
   dec r11;
   jnz @@addforxloop;
end;

procedure ASMMatrixMeanVarColumnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
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
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   movups xmm5, [rip + cOnes];
   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, height;
   cvtsi2ss xmm0, rax;
   {$ELSE}
   cvtsi2ss xmm0, height;
   {$ENDIF}
   movss xmm2, xmm0; shufps xmm2, xmm2, 0;

   // for x := 0 to width - 1:
   mov r11, Width;
   sar r11, 1;
   jz @lastColumn;
   @@addforxloop:
       xorps xmm0, xmm0;

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforyloop:
           addps xmm0, [r8 + rax];
       add rax, r9;
       jnz @addforyloop;

       // build result
       divps xmm0, xmm2;
       movaps [rcx], xmm0;

       // calculate final standard deviation
       // for y := 0 to height - 1;
       // prepare for reverse loop
       xorps xmm4, xmm4;
       mov rax, r10;
       @addforyloop2:
           movaps xmm1, [r8 + rax];
           subps xmm1, xmm0;
           mulps xmm1, xmm1;
           addps xmm4, xmm1;
       add rax, r9;
       jnz @addforyloop2;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movaps xmm1, xmm2;
       subps xmm1, xmm5;
       maxps xmm1, xmm5;

       divps xmm4, xmm1;

       jmp @@writeRes;

       @@dobiased:
       divps xmm4, xmm2;

       // write result
       @@writeRes:
       movaps [rcx + rdx], xmm4;

       // next columns:
       add rcx, 16;
       add r8, 16;

   // loop x end
   dec r11;
   jnz @@addforxloop;

   @lastColumn:

   // handle last column
   xorps xmm0, xmm0;

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop3:
       movss xmm1, [r8 + rax];
       addss xmm0, xmm1;
   add rax, r9;
   jnz @addforyloop3;

   // build result
   divss xmm0, xmm2;
   movss [rcx], xmm0;

   // calculate final standard deviation
   // for y := 0 to height - 1;
   // prepare for reverse loop
   xorps xmm4, xmm4;
   mov rax, r10;
   @addforyloop4:
       movss xmm1, [r8 + rax];
       subss xmm1, xmm0;
       mulss xmm1, xmm1;
       addss xmm4, xmm1;
   add rax, r9;
   jnz @addforyloop4;

   // check if we need to use the unbiased version
   cmp unbiased, 0;
   jz @@dobiased2;

   movaps xmm1, xmm2;
   subss xmm1, [rip + cOnes];
   maxss xmm1, [rip + cOnes];

   divss xmm4, xmm1;

   jmp @@writeRes2;

   @@dobiased2:
   divss xmm4, xmm2;

   // write result
   @@writeRes2:
   movss [rcx + rdx], xmm4;
end;

procedure ASMMatrixMeanVarColumnUnAlignedOddW(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
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
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   movups xmm5, [rip + cOnes];
   // fpc seems to have a problem with this opcode
   {$IFDEF FPC}
   mov rax, height;
   cvtsi2ss xmm0, rax;
   {$ELSE}
   cvtsi2ss xmm0, height;
   {$ENDIF}
   movss xmm2, xmm0; shufps xmm2, xmm2, 0;

   // for x := 0 to width - 1:
   mov r11, Width;
   sar r11, 1;
   jz @lastColumn;
   @@addforxloop:
       xorps xmm0, xmm0;

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforyloop:
           movups xmm1, [r8 + rax];
           addps xmm0, xmm1;
       add rax, r9;
       jnz @addforyloop;

       // build result
       divps xmm0, xmm2;
       movups [rcx], xmm0;

       // calculate final standard deviation
       // for y := 0 to height - 1;
       // prepare for reverse loop
       xorps xmm4, xmm4;
       mov rax, r10;
       @addforyloop2:
           movups xmm1, [r8 + rax];
           subps xmm1, xmm0;
           mulps xmm1, xmm1;
           addps xmm4, xmm1;
       add rax, r9;
       jnz @addforyloop2;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       movaps xmm1, xmm2;
       subps xmm1, xmm5;
       maxps xmm1, xmm5;

       divps xmm4, xmm1;

       jmp @@writeRes;

       @@dobiased:
       divps xmm4, xmm2;

       // write result
       @@writeRes:
       movups [rcx + rdx], xmm4;

       // next columns:
       add rcx, 16;
       add r8, 16;

   // loop x end
   dec r11;
   jnz @@addforxloop;

   @lastColumn:

   // handle last column
   xorps xmm0, xmm0;

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop3:
       movss xmm1, [r8 + rax];
       addss xmm0, xmm1;
   add rax, r9;
   jnz @addforyloop3;

   // build result
   divss xmm0, xmm2;
   movss [rcx], xmm0;

   // calculate final standard deviation
   // for y := 0 to height - 1;
   // prepare for reverse loop
   xorps xmm4, xmm4;
   mov rax, r10;
   @addforyloop4:
       movss xmm1, [r8 + rax];
       subss xmm1, xmm0;
       mulss xmm1, xmm1;
       addss xmm4, xmm1;
   add rax, r9;
   jnz @addforyloop4;

   // check if we need to use the unbiased version
   cmp unbiased, 0;
   jz @@dobiased2;

   movaps xmm1, xmm2;
   subss xmm1, [rip + cOnes];
   maxss xmm1, [rip + cOnes];

   divss xmm4, xmm1;

   jmp @@writeRes2;

   @@dobiased2:
   divss xmm4, xmm2;

   // write result
   @@writeRes2:
   movss [rcx + rdx], xmm4;
end;


{$ENDIF}

end.
