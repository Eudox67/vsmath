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


unit AVXMatrixMeanOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

uses MatrixConstSingle;

procedure AVXMatrixMeanRowAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure AVXMatrixMeanRowUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure AVXMatrixMeanColumnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
procedure AVXMatrixMeanColumnUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;

procedure AVXMatrixVarRowAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure AVXMatrixVarRowUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;

procedure AVXMatrixVarColumnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure AVXMatrixVarColumnUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;


// combined methods
procedure AVXMatrixMeanVarRowAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure AVXMatrixMeanVarRowUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;

procedure AVXMatrixMeanVarColumnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
procedure AVXMatrixMeanVarColumnUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

// ###########################################
// #### Mean
// ###########################################
//
// One kernel per reduction direction with a scalar tail, so neither extent has to
// be a whole number of lanes. The *Aligned* twins only carried an alignment hint
// and forward.

procedure AVXMatrixMeanRowUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = Src, r9 = srcLineWidth
//
// dest[y] := sum(x) Src[y][x] / width. Eight elements per iteration, then a four
// element step, then a scalar tail; the lane reduction uses shuffles instead of
// a vhaddps cascade.
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
   vcvtsi2ss xmm5, xmm5, rax;

   @@foryloop:
       vxorps ymm0, ymm0, ymm0;  // lane accumulator
       vxorps xmm3, xmm3, xmm3;  // scalar tail accumulator
       xor r11, r11;             // byte offset into the row

       mov rax, iWidth;
       shr rax, 3;               // whole eight element blocks
       jz @@tail4;

       @@vecloop:
           vaddps ymm0, ymm0, [r8 + r11];
           add r11, 32;
       dec rax;
       jnz @@vecloop;

       @@tail4:
       vxorps xmm4, xmm4, xmm4;  // one leftover four element block; a 128 bit
       mov rax, iWidth;          // vaddps into ymm0 would clear its upper half
       and rax, 4;
       jz @@tail1;
       vmovups xmm4, [r8 + r11];
       add r11, 16;

       @@tail1:
       mov rax, iWidth;
       and rax, 3;               // zero to three leftover elements
       jz @@reduce;

       @@tailloop:
           vmovss xmm1, [r8 + r11];
           vaddss xmm3, xmm3, xmm1;
           add r11, 4;
       dec rax;
       jnz @@tailloop;

       @@reduce:
       // fold the eight lanes into lane 0, then add the scalar tail
       vextractf128 xmm2, ymm0, 1;
       vaddps xmm0, xmm0, xmm2;
       vaddps xmm0, xmm0, xmm4;
       vshufps xmm2, xmm0, xmm0, $4E;
       vaddps xmm0, xmm0, xmm2;
       vshufps xmm2, xmm0, xmm0, $B1;
       vaddps xmm0, xmm0, xmm2;
       vaddss xmm0, xmm0, xmm3;

       vdivss xmm0, xmm0, xmm5;  // mean := sum / width

       vmovss [rcx], xmm0;

       add rcx, rdx;
       add r8, r9;
   dec r10;
   jnz @@foryloop;

   @@done:
   vzeroupper;
end;
procedure AVXMatrixMeanRowAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
asm
   call AVXMatrixMeanRowUnAligned;
end;
procedure AVXMatrixMeanColumnUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = Src, r9 = srcLineWidth
//
// dest[x] := sum(y) Src[y][x] / height. Eight columns per iteration plus a scalar
// tail. A block result is stored with one 32 byte store when the destination is
// tight and lane by lane otherwise, which is what makes a padded destLineWidth
// work.
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

   // ymm5 := height in every lane, the mean divides every column sum by it
   mov rax, iHeight;
   vcvtsi2ss xmm5, xmm5, rax;
   vshufps xmm5, xmm5, xmm5, 0;
   vinsertf128 ymm5, ymm5, xmm5, 1;

   mov rax, iWidth;
   shr rax, 3;
   mov iBlocks, rax;
   xor rax, rax;
   mov iOff, rax;               // byte offset of the current column block
   mov rax, iBlocks;
   test rax, rax;
   jz @@tail;

   @@vecloop:
       vxorps ymm1, ymm1, ymm1;  // columns x .. x+7

       mov rax, r8;
       add rax, iOff;
       mov r10, iHeight;

       @@rowloop:
           vaddps ymm1, ymm1, [rax];
           add rax, r9;
       dec r10;
       jnz @@rowloop;

       vdivps ymm1, ymm1, ymm5;

       cmp rdx, 4;               // tight destination?
       jne @@scatter;

       vmovups [rcx], ymm1;
       add rcx, 32;
       jmp @@nextblock;

       @@scatter:
           vextractf128 xmm2, ymm1, 1;
           vmovss [rcx], xmm1;
           add rcx, rdx;
           vshufps xmm3, xmm1, xmm1, $39;
           vmovss [rcx], xmm3;
           add rcx, rdx;
           vshufps xmm3, xmm3, xmm3, $39;
           vmovss [rcx], xmm3;
           add rcx, rdx;
           vshufps xmm3, xmm3, xmm3, $39;
           vmovss [rcx], xmm3;
           add rcx, rdx;
           vmovss [rcx], xmm2;
           add rcx, rdx;
           vshufps xmm3, xmm2, xmm2, $39;
           vmovss [rcx], xmm3;
           add rcx, rdx;
           vshufps xmm3, xmm3, xmm3, $39;
           vmovss [rcx], xmm3;
           add rcx, rdx;
           vshufps xmm3, xmm3, xmm3, $39;
           vmovss [rcx], xmm3;
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
       vxorps xmm1, xmm1, xmm1;
       mov r10, r8;
       add r10, iOff;
       mov r11, iHeight;

       @@tailrowloop:
           vmovss xmm0, [r10];
           vaddss xmm1, xmm1, xmm0;
           add r10, r9;
       dec r11;
       jnz @@tailrowloop;

       vdivss xmm1, xmm1, xmm5;
       vmovss [rcx], xmm1;
       add rcx, rdx;
       add iOff, 4;
   dec rax;
   jnz @@tailcol;

   @@done:
   vzeroupper;
end;
procedure AVXMatrixMeanColumnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt); assembler;
asm
   call AVXMatrixMeanColumnUnAligned;
end;
// ###########################################
// #### Variance calculation
// ###########################################


procedure AVXMatrixVarRowAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
var tmp : single;
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
   sub rsp, $10;
   vmovups [rsp + $00], xmm4; 

   // iters := -width*sizeof(single)
   mov r10, width;
   shl r10, 2;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   mov rax, width;
   vcvtsi2ss xmm3, xmm3, rax;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       vxorps ymm0, ymm0, ymm0; 
       vxorps ymm1, ymm1, ymm1; 

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [r8 + rax];

           // addition:
           vaddps ymm0, ymm0, [r8 + rax - 128]; 
           vaddps ymm1, ymm1, [r8 + rax - 96]; 
           vaddps ymm0, ymm0, [r8 + rax - 64]; 
           vaddps ymm1, ymm1, [r8 + rax - 32]; 
       jmp @addforxloop

       @loopEnd:

       vaddps ymm0, ymm0, ymm1; 
       vextractf128 xmm2, ymm0, 1; 
       vhaddps xmm0, xmm0, xmm2; 

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           add rax, 16;
           jg @@addforxloop2end;

           vaddps xmm0, xmm0, [r8 + rax - 16]; 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub rax, 16;
       jz @buildRes;

       vaddss xmm0, xmm0, [r8 + rax]; 

       @buildRes:

       // build result
       vhaddps xmm0, xmm0, xmm0; 
       vhaddps xmm0, xmm0, xmm0; 
       vdivss xmm0, xmm0, xmm3; 

       // we have calculated the mean ->
       // repeat the loop to calculate the variance
       lea rax, tmp;
       vmovss [rax], xmm0; 
       vbroadcastss ymm4, [rax]; 
       vxorps xmm0, xmm0, xmm0; 

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
           vmovaps ymm1, [r8 + rax - 128]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

           vmovaps ymm1, [r8 + rax - 96]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

           vmovaps ymm1, [r8 + rax - 64]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

           vmovaps ymm1, [r8 + rax - 32]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

       jmp @addforxloop3

       @loopEnd2:

       sub rax, 128;

       vextractf128 xmm2, ymm0, 1; 
       vhaddps xmm0, xmm0, xmm2; 

       jz @buildRes2;

       @addforxloop4:
           add rax, 16;
           jg @addforxloop4end;

           vmovaps xmm1, [r8 + rax - 16]; 
           vsubps xmm1, xmm1, xmm4; 
           vmulps xmm1, xmm1, xmm1; 
           vaddps xmm0, xmm0, xmm1; 
       jmp @addforxloop4;

       @addforxloop4end:

       sub rax, 16;
       jz @buildRes2;

       // last column
       vmovss xmm1, [r8 + rax]; 
       vsubss xmm1, xmm1, xmm4; 
       vmulss xmm1, xmm1, xmm1; 
       vaddss xmm0, xmm0, xmm1; 


       @buildRes2:

       // build result
       vhaddps xmm0, xmm0, xmm0; 
       vhaddps xmm0, xmm0, xmm0; 

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       lea rax, [rip + cOne];
       vmovss xmm2, [rax]; 
       vsubss xmm4, xmm3, xmm2; 
       vmaxss xmm4, xmm4, xmm2; 

       vdivss xmm0, xmm0, xmm4; 

       jmp @@writeRes;

       @@dobiased:
       vdivss xmm0, xmm0, xmm3; 

       // write result
       @@writeRes:
       vmovss [rcx], xmm0; 

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog
   vmovups xmm4, [rsp + $00]; 
   add rsp, $10;
   vzeroupper; 
end;

procedure AVXMatrixVarRowUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
var tmp : single;
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
   sub rsp, $10;
   vmovups [rsp + $00], xmm4; 

   // iters := -width*sizeof(single)
   mov r10, width;
   shl r10, 2;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   mov rax, width;
   vcvtsi2ss xmm3, xmm3, rax;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       vxorps ymm0, ymm0, ymm0; 
       vxorps ymm1, ymm1, ymm1; 

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [r8 + rax];

           // addition:
           vmovups ymm2, [r8 + rax - 128]; 
           vaddps ymm0, ymm0, ymm2; 
           vmovups ymm2, [r8 + rax - 96]; 
           vaddps ymm1, ymm1, ymm2; 
           vmovups ymm2, [r8 + rax - 64]; 
           vaddps ymm0, ymm0, ymm2; 
           vmovups ymm2, [r8 + rax - 32]; 
           vaddps ymm1, ymm1, ymm2; 
       jmp @addforxloop

       @loopEnd:

       vaddps ymm0, ymm0, ymm1; 
       vextractf128 xmm2, ymm0, 1; 
       vhaddps xmm0, xmm0, xmm2; 

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           add rax, 16;
           jg @@addforxloop2end;

           vmovups xmm2, [r8 + rax - 16]; 
           vaddps xmm0, xmm0, xmm2; 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub rax, 16;
       jz @buildRes;

       vaddss xmm0, xmm0, [r8 + rax]; 

       @buildRes:

       // build result
       vhaddps xmm0, xmm0, xmm0; 
       vhaddps xmm0, xmm0, xmm0; 
       vdivss xmm0, xmm0, xmm3; 

       // we have calculated the mean ->
       // repeat the loop to calculate the variance
       lea rax, tmp;
       vmovss [rax], xmm0; 
       vbroadcastss ymm4, [rax]; 
       vxorps xmm0, xmm0, xmm0; 

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
           vmovups ymm1, [r8 + rax - 128]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

           vmovups ymm1, [r8 + rax - 96]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

           vmovups ymm1, [r8 + rax - 64]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

           vmovups ymm1, [r8 + rax - 32]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

       jmp @addforxloop3

       @loopEnd2:

       sub rax, 128;

       vextractf128 xmm2, ymm0, 1; 
       vhaddps xmm0, xmm0, xmm2; 

       jz @buildRes2;

       @addforxloop4:
           add rax, 16;
           jg @addforxloop4end;

           vmovups xmm1, [r8 + rax - 16]; 
           vsubps xmm1, xmm1, xmm4; 
           vmulps xmm1, xmm1, xmm1; 
           vaddps xmm0, xmm0, xmm1; 
       jmp @addforxloop4;

       @addforxloop4end:

       sub rax, 16;
       jz @buildRes2;

       // last column
       vmovss xmm1, [r8 + rax]; 
       vsubss xmm1, xmm1, xmm4; 
       vmulss xmm1, xmm1, xmm1; 
       vaddss xmm0, xmm0, xmm1; 


       @buildRes2:

       // build result
       vhaddps xmm0, xmm0, xmm0; 
       vhaddps xmm0, xmm0, xmm0; 

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       lea rax, [rip + cOne];
       vmovss xmm2, [rax]; 
       vsubss xmm4, xmm3, xmm2; 
       vmaxss xmm4, xmm4, xmm2; 

       vdivss xmm0, xmm0, xmm4; 

       jmp @@writeRes;

       @@dobiased:
       vdivss xmm0, xmm0, xmm3; 

       // write result
       @@writeRes:
       vmovss [rcx], xmm0; 

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog
   vmovups xmm4, [rsp + $00]; 
   add rsp, $10;
   vzeroupper; 
end;

procedure AVXMatrixVarColumnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
var tmp : single;
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

   // prolog
   sub rsp, $20;
   vmovups [rsp + $00], xmm4; 
   vmovups [rsp + $10], xmm5; 

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   mov rax, height;
   vcvtsi2ss xmm0, xmm0, rax; 
   
   //cvtsi2ss xmm0, height;
   
   lea rax, tmp;
   vmovss [rax], xmm0; 
   vbroadcastss ymm2, [rax]; // vbroadcastss ymm2, xmm0;  // is avx2

   lea rax, [rip + cOne];
   vbroadcastss ymm5, [rax]; 


   // for x := 0 to width - 1:
   mov r11, Width;
   sub r11, 4;
   jl @@addforxloop4end;

   // 4 columns at once
   @@addforxloop4:
       vxorps ymm1, ymm1, ymm1; 

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforyloop4:
           vaddps ymm1, ymm1, [r8 + rax]; 
       add rax, r9;
       jnz @addforyloop4;

       // build result
       vdivps ymm0, ymm1, ymm2; 

       // calculate final standard deviation
       // for y := 0 to height - 1;
       // prepare for reverse loop
       vxorps ymm4, ymm4, ymm4; 
       mov rax, r10;
       @addforyloop4_2:
           vmovaps ymm1, [r8 + rax]; 
           vsubps ymm1, ymm1, ymm0; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm4, ymm4, ymm1; 
       add rax, r9;
       jnz @addforyloop4_2;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased_4;

       lea rax, [rip + cOne];

       vbroadcastss ymm1, [rax]; 
       vsubps ymm3, ymm2, ymm1; 
       vmaxps ymm3, ymm3, ymm1; 

       vdivps ymm4, ymm4, ymm3; 

       jmp @@writeRes_4;

       @@dobiased_4:
       vdivps ymm4, ymm4, ymm2; 

       // write result
       @@writeRes_4:
       vmovaps [rcx], ymm4; 

       // next columns:
       add rcx, 32;
       add r8, 32;

   // loop x end
   sub r11, 4;
   jge @@addforxloop4;

   @@addforxloop4end:

   add r11, 4;
   jz @@endProc;

   sub r11, 2;
   jl @@lastcolumn;

   vxorps xmm1, xmm1, xmm1; 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop2:
       vaddps xmm1, xmm1, [r8 + rax]; 
   add rax, r9;
   jnz @addforyloop2;

   // build result
   vdivps xmm0, xmm1, xmm2; 

   // calculate final standard deviation
   // for y := 0 to height - 1;
   // prepare for reverse loop
   vxorps xmm4, xmm4, xmm4; 
   mov rax, r10;
   @addforyloop2_2:
      vmovaps xmm1, [r8 + rax]; 
      vsubps xmm1, xmm1, xmm0; 
      vmulps xmm1, xmm1, xmm1; 
      vaddps xmm4, xmm4, xmm1; 
   add rax, r9;
   jnz @addforyloop2_2;

   // check if we need to use the unbiased version
   cmp unbiased, 0;
   jz @@dobiased_2;

   vsubps xmm3, xmm2, xmm5; 
   vmaxps xmm3, xmm3, xmm5; 

   vdivps xmm4, xmm4, xmm3; 

   jmp @@writeRes2;

   @@dobiased_2:
   vdivps xmm4, xmm4, xmm2; 

   // write result
   @@writeRes2:
   vmovaps [rcx], xmm4; 

   // next columns:
   add rcx, 16;
   add r8, 16;

   dec r11;
   jnz @@endProc;

   @@lastcolumn:

   vxorps xmm1, xmm1, xmm1; 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop_1:
       vaddss xmm1, xmm1, [r8 + rax]; 
   add rax, r9;
   jnz @addforyloop_1;

   // build result
   vdivss xmm0, xmm1, xmm2; 

   // calculate final standard deviation
   // for y := 0 to height - 1;
   // prepare for reverse loop
   vxorps xmm4, xmm4, xmm4; 
   mov rax, r10;
   @addforyloop1_2:
      vmovss xmm1, [r8 + rax]; 
      vsubss xmm1, xmm1, xmm0; 
      vmulss xmm1, xmm1, xmm1; 
      vaddss xmm4, xmm4, xmm1; 
   add rax, r9;
   jnz @addforyloop1_2;

   // check if we need to use the unbiased version
   cmp unbiased, 0;
   jz @@dobiased_2;

   vmovss xmm3, xmm3, xmm2; 
   vsubss xmm3, xmm3, xmm5; 
   vmaxss xmm3, xmm3, xmm5; 

   vdivss xmm4, xmm4, xmm3; 

   jmp @@writeRes_1;

   @@dobiased_1:
   vdivss xmm4, xmm4, xmm2; 

   // write result
   @@writeRes_1:
   vmovss [rcx], xmm4; 


   @@endProc:

   // epilog
   vmovups xmm4, [rsp + $00]; 
   vmovups xmm5, [rsp + $10]; 
   add rsp, $20;
   vzeroupper; 
end;

procedure AVXMatrixVarColumnUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
var tmp : single;
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

   // prolog
   sub rsp, $20;
   vmovups [rsp + $00], xmm4; 
   vmovups [rsp + $10], xmm5; 

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   mov rax, height;
   vcvtsi2ss xmm0, xmm0, rax; 
   
   //cvtsi2ss xmm0, height;
   
   lea rax, tmp;
   vmovss [rax], xmm0; 
   vbroadcastss ymm2, [rax]; // vbroadcastss ymm2, xmm0; // avx2

   lea rax, [rip + cOne];
   vbroadcastss ymm5, [rax]; 

   // for x := 0 to width - 1:
   mov r11, Width;
   sub r11, 4;
   jl @@addforxloop4end;

   // 4 columns at once
   @@addforxloop4:
       vxorps ymm1, ymm1, ymm1; 

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforyloop4:
           vmovups ymm3, [r8 + rax]; 
           vaddps ymm1, ymm1, ymm3; 
       add rax, r9;
       jnz @addforyloop4;

       // build result
       vdivps ymm0, ymm1, ymm2; 

       // calculate final standard deviation
       // for y := 0 to height - 1;
       // prepare for reverse loop
       vxorps ymm4, ymm4, ymm4; 
       mov rax, r10;
       @addforyloop4_2:
           vmovups ymm1, [r8 + rax]; 
           vsubps ymm1, ymm1, ymm0; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm4, ymm4, ymm1; 
       add rax, r9;
       jnz @addforyloop4_2;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased_4;

       vsubps ymm3, ymm2, ymm5; 
       vmaxps ymm3, ymm3, ymm5; 

       vdivps ymm4, ymm4, ymm3; 

       jmp @@writeRes_4;

       @@dobiased_4:
       vdivps ymm4, ymm4, ymm2; 

       // write result
       @@writeRes_4:
       vmovups [rcx], ymm4; 

       // next columns:
       add rcx, 32;
       add r8, 32;

   // loop x end
   sub r11, 4;
   jge @@addforxloop4;

   @@addforxloop4end:

   add r11, 4;
   jz @@endProc;

   sub r11, 2;
   jl @@lastcolumn;

   vxorps xmm1, xmm1, xmm1; 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop2:
       vmovups xmm3, [r8 + rax]; 
       vaddps xmm1, xmm1, xmm3; 
   add rax, r9;
   jnz @addforyloop2;

   // build result
   vdivps xmm0, xmm1, xmm2; 

   // calculate final standard deviation
   // for y := 0 to height - 1;
   // prepare for reverse loop
   vxorps xmm4, xmm4, xmm4; 
   mov rax, r10;
   @addforyloop2_2:
      vmovups xmm1, [r8 + rax]; 
      vsubps xmm1, xmm1, xmm0; 
      vmulps xmm1, xmm1, xmm1; 
      vaddps xmm4, xmm4, xmm1; 
   add rax, r9;
   jnz @addforyloop2_2;

   // check if we need to use the unbiased version
   cmp unbiased, 0;
   jz @@dobiased_2;

   vsubps xmm3, xmm2, xmm5; 
   vmaxps xmm3, xmm3, xmm5; 

   vdivps xmm4, xmm4, xmm3; 

   jmp @@writeRes2;

   @@dobiased_2:
   vdivps xmm4, xmm4, xmm2; 

   // write result
   @@writeRes2:
   vmovups [rcx], xmm4; 

   // next columns:
   add rcx, 16;
   add r8, 16;

   dec r11;
   jnz @@endProc;

   @@lastcolumn:

   vxorps xmm1, xmm1, xmm1; 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop_1:
       vaddss xmm1, xmm1, [r8 + rax]; 
   add rax, r9;
   jnz @addforyloop_1;

   // build result
   vdivss xmm0, xmm1, xmm2; 

   // calculate final standard deviation
   // for y := 0 to height - 1;
   // prepare for reverse loop
   vxorps xmm4, xmm4, xmm4; 
   mov rax, r10;
   @addforyloop1_2:
      vmovss xmm1, [r8 + rax]; 
      vsubss xmm1, xmm1, xmm0; 
      vmulss xmm1, xmm1, xmm1; 
      vaddss xmm4, xmm4, xmm1; 
   add rax, r9;
   jnz @addforyloop1_2;

   // check if we need to use the unbiased version
   cmp unbiased, 0;
   jz @@dobiased_2;

   vsubss xmm3, xmm2, xmm5; 
   vmaxss xmm3, xmm3, xmm5; 

   vdivss xmm4, xmm4, xmm3; 

   jmp @@writeRes_1;

   @@dobiased_1:
   vdivss xmm4, xmm4, xmm2; 

   // write result
   @@writeRes_1:
   vmovss [rcx], xmm4; 

   @@endProc:

   vmovups xmm4, [rsp + $00]; 
   vmovups xmm5, [rsp + $10]; 
   add rsp, $20;
   vzeroupper; 
end;

// #####################################################
// #### Combined mean variance calculation
// #####################################################

procedure AVXMatrixMeanVarRowAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
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

   // prolog
   sub rsp, $10;
   vmovups [rsp + $00], xmm4; 

   // iters := -width*sizeof(single)
   mov r10, width;
   imul r10, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   mov rax, width;
   vcvtsi2ss xmm3, xmm3, rax;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       vxorps ymm0, ymm0, ymm0; 
       vxorps ymm1, ymm1, ymm1; 

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [r8 + rax];

           // addition:
           vaddps ymm0, ymm0, [r8 + rax - 128]; 
           vaddps ymm1, ymm1, [r8 + rax - 96]; 
           vaddps ymm0, ymm0, [r8 + rax - 64]; 
           vaddps ymm1, ymm1, [r8 + rax - 32]; 
       jmp @addforxloop

       @loopEnd:

       vaddps ymm0, ymm0, ymm1; 
       vextractf128 xmm2, ymm0, 1; 
       vhaddps xmm0, xmm0, xmm2; 

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           add rax, 16;
           jg @@addforxloop2end;

           vaddps xmm0, xmm0, [r8 + rax - 16]; 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub rax, 16;
       jz @buildRes;

       vaddss xmm0, xmm0, [r8 + rax]; 

       @buildRes:

       // build result
       vhaddps xmm0, xmm0, xmm0; 
       vhaddps xmm0, xmm0, xmm0; 
       vdivss xmm0, xmm0, xmm3; 
       vmovss [rcx], xmm0; 

       // we have calculated the mean ->
       // repeat the loop to calculate the variance
       vbroadcastss ymm4, [rcx]; // need avx2
       vxorps xmm0, xmm0, xmm0; 

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
           vmovaps ymm1, [r8 + rax - 128]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

           vmovaps ymm1, [r8 + rax - 96]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

           vmovaps ymm1, [r8 + rax - 64]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

           vmovaps ymm1, [r8 + rax - 32]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

       jmp @addforxloop3

       @loopEnd2:

       vextractf128 xmm2, ymm0, 1; 
       vhaddps xmm0, xmm0, xmm2; 

       sub rax, 128;
       jz @buildRes2;

       @addforxloop4:
           add rax, 16;
           jg @addforxloop4end;

           vmovaps xmm1, [r8 + rax - 16]; 
           vsubps xmm1, xmm1, xmm4; 
           vmulps xmm1, xmm1, xmm1; 
           vaddps xmm0, xmm0, xmm1; 
       jmp @addforxloop4;

       @addforxloop4end:

       sub rax, 16;
       jz @buildRes2;

       // last column
       vmovss xmm1, [r8 + rax]; 
       vsubss xmm1, xmm1, xmm4; 
       vmulss xmm1, xmm1, xmm1; 
       vaddss xmm0, xmm0, xmm1; 


       @buildRes2:

       // build result
       vhaddps xmm0, xmm0, xmm0; 
       vhaddps xmm0, xmm0, xmm0; 

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       lea rax, [rip + cOne];
       vmovss xmm2, [rax]; 
       vsubss xmm4, xmm3, xmm2; 
       vmaxss xmm4, xmm4, xmm2; 

       vdivss xmm0, xmm0, xmm4; 

       jmp @@writeRes;

       @@dobiased:
       vdivss xmm0, xmm0, xmm3; 

       // write result
       @@writeRes:
       vmovss [rcx + 8], xmm0; 

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog
   vmovups xmm4, [rsp + $00]; 
   add rsp, $10;
   vzeroupper; 
end;

procedure AVXMatrixMeanVarRowUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
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

   // prolog
   sub rsp, $10;
   vmovups [rsp + $00], xmm4; 

   // iters := -width*sizeof(single)
   mov r10, width;
   imul r10, -4;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   mov rax, width;
   vcvtsi2ss xmm3, xmm3, rax;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       vxorps ymm0, ymm0, ymm0; 
       vxorps ymm1, ymm1, ymm1; 

       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;
           // prefetch data...
           // prefetch [r8 + rax];

           // addition:
           vmovups ymm2, [r8 + rax - 128]; 
           vaddps ymm0, ymm0, ymm2; 
           vmovups ymm2, [r8 + rax - 96]; 
           vaddps ymm1, ymm1, ymm2; 
           vmovups ymm2, [r8 + rax - 64]; 
           vaddps ymm0, ymm0, ymm2; 
           vmovups ymm2, [r8 + rax - 32]; 
           vaddps ymm1, ymm1, ymm2; 
       jmp @addforxloop

       @loopEnd:

       vaddps ymm0, ymm0, ymm1; 
       vextractf128 xmm2, ymm0, 1; 
       vhaddps xmm0, xmm0, xmm2; 

       sub rax, 128;

       jz @buildRes;

       @addforxloop2:
           add rax, 16;
           jg @@addforxloop2end;

           vmovups xmm2, [r8 + rax - 16]; 
           vaddps xmm0, xmm0, xmm2; 
       jmp @addforxloop2;

       @@addforxloop2end:

       sub rax, 16;
       jz @buildRes;

       vaddss xmm0, xmm0, [r8 + rax]; 

       @buildRes:

       // build result
       vhaddps xmm0, xmm0, xmm0; 
       vhaddps xmm0, xmm0, xmm0; 
       vdivss xmm0, xmm0, xmm3; 
       vmovss [rcx], xmm0; 

       // we have calculated the mean ->
       // repeat the loop to calculate the variance

       vbroadcastss ymm4, [rcx]; // need avx2
       vxorps xmm0, xmm0, xmm0; 

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
           vmovups ymm1, [r8 + rax - 128]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

           vmovups ymm1, [r8 + rax - 96]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

           vmovups ymm1, [r8 + rax - 64]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

           vmovups ymm1, [r8 + rax - 32]; 
           vsubps ymm1, ymm1, ymm4; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm0, ymm0, ymm1; 

       jmp @addforxloop3

       @loopEnd2:

       sub rax, 128;

       vextractf128 xmm2, ymm0, 1; 
       vhaddps xmm0, xmm0, xmm2; 

       jz @buildRes2;

       @addforxloop4:
           add rax, 16;
           jg @addforxloop4end;

           vmovups xmm1, [r8 + rax - 16]; 
           vsubps xmm1, xmm1, xmm4; 
           vmulps xmm1, xmm1, xmm1; 
           vaddps xmm0, xmm0, xmm1; 
       jmp @addforxloop4;

       @addforxloop4end:

       sub rax, 16;
       jz @buildRes2;

       // last column
       vmovss xmm1, [r8 + rax]; 
       vsubss xmm1, xmm1, xmm4; 
       vmulss xmm1, xmm1, xmm1; 
       vaddss xmm0, xmm0, xmm1; 


       @buildRes2:

       // build result
       vhaddps xmm0, xmm0, xmm0; 
       vhaddps xmm0, xmm0, xmm0; 

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased;

       lea rax, [rip + cOne];
       vmovss xmm2, [rax]; 
       vsubss xmm4, xmm3, xmm2; 
       vmaxss xmm4, xmm4, xmm2; 

       vdivss xmm0, xmm0, xmm4; 

       jmp @@writeRes;

       @@dobiased:
       vdivss xmm0, xmm0, xmm3; 

       // write result
       @@writeRes:
       vmovss [rcx + 8], xmm0; 

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;

   // epilog
   vmovups xmm4, [rsp + $00]; 
   add rsp, $10;
   vzeroupper; 
end;

procedure AVXMatrixMeanVarColumnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
var tmp : single;
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

   // prolog
   sub rsp, $20;
   vmovups [rsp + $00], xmm4; 
   vmovups [rsp + $10], xmm5; 

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   mov rax, height;
   vcvtsi2ss xmm0, xmm0, rax; 
   
   //cvtsi2ss xmm0, height;
   
   lea rax, tmp;
   vmovss [rax], xmm0; 
   vbroadcastss ymm2, [rax]; // vbroadcastss ymm2, xmm0;  // avx2

   lea rax, [rip + cOne];
   vbroadcastss ymm5, [rax]; 


   // for x := 0 to width - 1:
   mov r11, Width;
   sub r11, 4;
   jl @@addforxloop4end;

   // 4 columns at once
   @@addforxloop4:
       vxorps ymm1, ymm1, ymm1; 

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforyloop4:
           vaddps ymm1, ymm1, [r8 + rax]; 
       add rax, r9;
       jnz @addforyloop4;

       // build result
       vdivps ymm0, ymm1, ymm2; 
       vmovaps [rcx], ymm0; 

       // calculate final standard deviation
       // for y := 0 to height - 1;
       // prepare for reverse loop
       vxorps ymm4, ymm4, ymm4; 
       mov rax, r10;
       @addforyloop4_2:
           vmovaps ymm1, [r8 + rax]; 
           vsubps ymm1, ymm1, ymm0; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm4, ymm4, ymm1; 
       add rax, r9;
       jnz @addforyloop4_2;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased_4;

       lea rax, [rip + cOne];

       vbroadcastss ymm1, [rax]; 
       vsubps ymm3, ymm2, ymm1; 
       vmaxps ymm3, ymm3, ymm1; 

       vdivps ymm4, ymm4, ymm3; 

       jmp @@writeRes_4;

       @@dobiased_4:
       vdivps ymm4, ymm4, ymm2; 

       // write result
       @@writeRes_4:
       vmovaps [rcx + rdx], ymm4; 

       // next columns:
       add rcx, 32;
       add r8, 32;

   // loop x end
   sub r11, 4;
   jge @@addforxloop4;

   @@addforxloop4end:

   add r11, 4;
   jz @@endProc;

   sub r11, 2;
   jl @@lastcolumn;

   vxorps xmm1, xmm1, xmm1; 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop2:
       vaddps xmm1, xmm1, [r8 + rax]; 
   add rax, r9;
   jnz @addforyloop2;

   // build result
   vdivps xmm0, xmm1, xmm2; 
   vmovaps [rcx], xmm0; 

   // calculate final standard deviation
   // for y := 0 to height - 1;
   // prepare for reverse loop
   vxorps xmm4, xmm4, xmm4; 
   mov rax, r10;
   @addforyloop2_2:
      vmovaps xmm1, [r8 + rax]; 
      vsubps xmm1, xmm1, xmm0; 
      vmulps xmm1, xmm1, xmm1; 
      vaddps xmm4, xmm4, xmm1; 
   add rax, r9;
   jnz @addforyloop2_2;

   // check if we need to use the unbiased version
   cmp unbiased, 0;
   jz @@dobiased_2;

   vsubps xmm3, xmm2, xmm5; 
   vmaxps xmm3, xmm3, xmm5; 

   vdivps xmm4, xmm4, xmm3; 

   jmp @@writeRes2;

   @@dobiased_2:
   vdivps xmm4, xmm4, xmm2; 

   // write result
   @@writeRes2:
   vmovaps [rcx + rdx], xmm4; 

   // next columns:
   add rcx, 16;
   add r8, 16;

   dec r11;
   jnz @@endProc;

   @@lastcolumn:

   vxorps xmm1, xmm1, xmm1; 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop_1:
       vaddss xmm1, xmm1, [r8 + rax]; 
   add rax, r9;
   jnz @addforyloop_1;

   // build result
   vdivss xmm0, xmm1, xmm2; 
   vmovss [rcx], xmm0; 

   // calculate final standard deviation
   // for y := 0 to height - 1;
   // prepare for reverse loop
   vxorps xmm4, xmm4, xmm4; 
   mov rax, r10;
   @addforyloop2_1:
      vmovss xmm1, [r8 + rax]; 
      vsubss xmm1, xmm1, xmm0; 
      vmulss xmm1, xmm1, xmm1; 
      vaddss xmm4, xmm4, xmm1; 
   add rax, r9;
   jnz @addforyloop2_1;

   // check if we need to use the unbiased version
   cmp unbiased, 0;
   jz @@dobiased_1;

   vmovss xmm3, xmm3, xmm2; 
   vsubss xmm3, xmm3, xmm5; 
   vmaxss xmm3, xmm3, xmm5; 

   vdivss xmm4, xmm4, xmm3; 

   jmp @@writeRes_1;

   @@dobiased_1:
   vdivss xmm4, xmm4, xmm2; 

   // write result
   @@writeRes_1:
   vmovss [rcx + rdx], xmm4; 

   @@endProc:

   // epilog
   vmovups xmm4, [rsp + $00]; 
   vmovups xmm5, [rsp + $10]; 
   add rsp, $20;
   vzeroupper; 
end;

procedure AVXMatrixMeanVarColumnUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; {$ifdef UNIX}unixWidth{$ELSE}width{$endif}, {$ifdef UNIX}unixHeight{$ELSE}height{$endif} : NativeInt; unbiased : boolean); assembler;
var tmp : single;
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

   // prolog
   sub rsp, $20;
   vmovups [rsp + $00], xmm4; 
   vmovups [rsp + $10], xmm5; 

   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   xor r10, r10;
   sub r10, height;
   imul r10, r9;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;

   mov rax, height;
   vcvtsi2ss xmm0, xmm0, rax; 
   
   //cvtsi2ss xmm0, height;
   
   lea rax, tmp;
   vmovss [rax], xmm0; 
   vbroadcastss ymm2, [rax]; //vbroadcastss ymm2, xmm0; // avx2

   lea rax, [rip + cOne];
   vbroadcastss ymm5, [rax]; 

   // for x := 0 to width - 1:
   mov r11, Width;
   sub r11, 4;
   jl @@addforxloop4end;

   // 4 columns at once
   @@addforxloop4:
       vxorps ymm1, ymm1, ymm1; 

       // for y := 0 to height - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforyloop4:
           vmovups ymm3, [r8 + rax]; 
           vaddps ymm1, ymm1, ymm3; 
       add rax, r9;
       jnz @addforyloop4;

       // build result
       vdivps ymm0, ymm1, ymm2; 
       vmovups [rcx], ymm0; 

       // calculate final standard deviation
       // for y := 0 to height - 1;
       // prepare for reverse loop
       vxorps ymm4, ymm4, ymm4; 
       mov rax, r10;
       @addforyloop4_2:
           vmovups ymm1, [r8 + rax]; 
           vsubps ymm1, ymm1, ymm0; 
           vmulps ymm1, ymm1, ymm1; 
           vaddps ymm4, ymm4, ymm1; 
       add rax, r9;
       jnz @addforyloop4_2;

       // check if we need to use the unbiased version
       cmp unbiased, 0;
       jz @@dobiased_4;

       vsubps ymm3, ymm2, ymm5; 
       vmaxps ymm3, ymm3, ymm5; 

       vdivps ymm4, ymm4, ymm3; 

       jmp @@writeRes_4;

       @@dobiased_4:
       vdivps ymm4, ymm4, ymm2; 

       // write result
       @@writeRes_4:
       vmovups [rcx + rdx], ymm4; 

       // next columns:
       add rcx, 32;
       add r8, 32;

   // loop x end
   sub r11, 4;
   jge @@addforxloop4;

   @@addforxloop4end:

   add r11, 4;
   jz @@endProc;

   sub r11, 2;
   jl @@lastcolumn;

   vxorps xmm1, xmm1, xmm1; 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop2:
       vmovups xmm3, [r8 + rax]; 
       vaddps xmm1, xmm1, xmm3; 
   add rax, r9;
   jnz @addforyloop2;

   // build result
   vdivps xmm0, xmm1, xmm2; 
   vmovups [rcx], xmm0; 

   // calculate final standard deviation
   // for y := 0 to height - 1;
   // prepare for reverse loop
   vxorps xmm4, xmm4, xmm4; 
   mov rax, r10;
   @addforyloop2_2:
      vmovups xmm1, [r8 + rax]; 
      vsubps xmm1, xmm1, xmm0; 
      vmulps xmm1, xmm1, xmm1; 
      vaddps xmm4, xmm4, xmm1; 
   add rax, r9;
   jnz @addforyloop2_2;

   // check if we need to use the unbiased version
   cmp unbiased, 0;
   jz @@dobiased_2;

   vsubps xmm3, xmm2, xmm5; 
   vmaxps xmm3, xmm3, xmm5; 

   vdivps xmm4, xmm4, xmm3; 

   jmp @@writeRes2;

   @@dobiased_2:
   vdivps xmm4, xmm4, xmm2; 

   // write result
   @@writeRes2:
   vmovups [rcx + rdx], xmm4; 

   // next columns:
   add rcx, 16;
   add r8, 16;

   dec r11;
   jnz @@endProc;

   @@lastcolumn:

   vxorps xmm1, xmm1, xmm1; 

   // for y := 0 to height - 1;
   // prepare for reverse loop
   mov rax, r10;
   @addforyloop_1:
       vaddss xmm1, xmm1, [r8 + rax]; 
   add rax, r9;
   jnz @addforyloop_1;

   // build result
   vdivss xmm0, xmm1, xmm2; 
   vmovss [rcx], xmm0; 

   // calculate final standard deviation
   // for y := 0 to height - 1;
   // prepare for reverse loop
   vxorps xmm4, xmm4, xmm4; 
   mov rax, r10;
   @addforyloop2_1:
      vmovss xmm1, [r8 + rax]; 
      vsubss xmm1, xmm1, xmm0; 
      vmulss xmm1, xmm1, xmm1; 
      vaddss xmm4, xmm4, xmm1; 
   add rax, r9;
   jnz @addforyloop2_1;

   // check if we need to use the unbiased version
   cmp unbiased, 0;
   jz @@dobiased_1;

   vsubss xmm3, xmm2, xmm5; 
   vmaxss xmm3, xmm3, xmm5; 

   vdivss xmm4, xmm4, xmm3; 

   jmp @@writeRes_1;

   @@dobiased_1:
   vdivss xmm4, xmm4, xmm2; 

   // write result
   @@writeRes_1:
   vmovss [rcx + rdx], xmm4; 

   @@endProc:

   vmovups xmm4, [rsp + $00]; 
   vmovups xmm5, [rsp + $10]; 
   add rsp, $20;
   vzeroupper; 
end;

{$ENDIF}

end.
