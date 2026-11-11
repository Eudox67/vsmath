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

// Vector/Matrix rotation routines mainly used for the SVD

unit AVXMatrixRotationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}


uses MatrixConstSingle;

procedure AVXApplyPlaneRotSeqRVB(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;
procedure AVXApplyPlaneRotSeqRVF(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;
procedure AVXApplyPlaneRotSeqLVF(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;
procedure AVXApplyPlaneRotSeqLVB(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;


procedure AVXMatrixRotate(N : NativeInt; X : PSingle; const LineWidthDX : NativeInt; Y : PSingle; LineWidthDY : NativeInt; const c, s : single);

{$ENDIF}

implementation

{$IFDEF CPUX64}

// rcx = width, rdx = height, r8 : A, r9 = LineWidthA
// ApplyPlaneRotSeq* rotate column pairs (L) or row pairs (R) of A with the per
// element factors c/s:
//   t := A[y + 1][x]; A[y + 1][x] := c*t - s*A[y][x]; A[y][x] := s*t + c*A[y][x]
// The L variants vectorise over x with a scalar tail, the R variants are scalar
// because the rotations within a row build on each other.
procedure AVXApplyPlaneRotSeqLVB(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;
// rcx = width, rdx = height, r8 = A, r9 = LineWidthA
var iRBX, iRSI, iRDI, iR12 : NativeInt;
    {$IFDEF UNIX}
    C, S : PConstSingleArr;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov C, r8;
   mov S, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // if (width < 1) or (height < 2) then exit;
   cmp rcx, 1;
   jl @@endproc;
   cmp rdx, 2;
   jl @@endproc;

   mov iRBX, rbx;
   mov iRSI, rsi;
   mov iRDI, rdi;
   mov iR12, r12;

   // y starts at height - 2 and walks down to 0
   mov rax, rdx;
   sub rax, 2;
   mov r11, rax;
   imul r11, r9;
   add r11, r8;               // r11 = A + (height - 2)*LineWidthA
   shl rax, 2;
   mov r12, C;
   add r12, rax;              // r12 = C + (height - 2)*sizeof(single)
   mov rbx, S;
   add rbx, rax;              // rbx = S + (height - 2)*sizeof(single)
   mov r10, rdx;
   dec r10;                   // height - 1 row pairs

   @@foryloop:
       vbroadcastss ymm6, [r12];   // c[y]
       vbroadcastss ymm7, [rbx];   // s[y]

       mov rsi, r11;               // row y
       lea rdi, [r11 + r9];        // row y + 1

       mov rax, rcx;
       shr rax, 3;                 // full 8 element blocks
       jz @@tailloop;

       @@vecloop:
           vmovups ymm0, [rsi];
           vmovups ymm1, [rdi];
           vmulps ymm2, ymm1, ymm6;    // c*t
           vmulps ymm3, ymm0, ymm7;    // s*a
           vsubps ymm2, ymm2, ymm3;
           vmulps ymm4, ymm1, ymm7;    // s*t
           vmulps ymm5, ymm0, ymm6;    // c*a
           vaddps ymm4, ymm4, ymm5;
           vmovups [rdi], ymm2;
           vmovups [rsi], ymm4;
           add rsi, 32;
           add rdi, 32;
           dec rax;
       jnz @@vecloop;

       @@tailloop:
       mov rax, rcx;
       and rax, 7;                 // up to 7 remaining elements
       jz @@nextline;

       @@tailloop2:
           vmovss xmm0, [rsi];
           vmovss xmm1, [rdi];
           vmulss xmm2, xmm1, xmm6;
           vmulss xmm3, xmm0, xmm7;
           vsubss xmm2, xmm2, xmm3;
           vmulss xmm4, xmm1, xmm7;
           vmulss xmm5, xmm0, xmm6;
           vaddss xmm4, xmm4, xmm5;
           vmovss [rdi], xmm2;
           vmovss [rsi], xmm4;
           add rsi, 4;
           add rdi, 4;
           dec rax;
       jnz @@tailloop2;

       @@nextline:
       sub r11, r9;
       sub r12, 4;
       sub rbx, 4;
       dec r10;
   jnz @@foryloop;

   vzeroupper;
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;

   @@endproc:
end;

// LVF: same rotation as LVB, walking the row pairs from the top down
procedure AVXApplyPlaneRotSeqLVF(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;
// rcx = width, rdx = height, r8 = A, r9 = LineWidthA
var iRBX, iRSI, iRDI, iR12 : NativeInt;
    {$IFDEF UNIX}
    C, S : PConstSingleArr;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   mov C, r8;
   mov S, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   cmp rcx, 1;
   jl @@endproc;
   cmp rdx, 2;
   jl @@endproc;

   mov iRBX, rbx;
   mov iRSI, rsi;
   mov iRDI, rdi;
   mov iR12, r12;

   mov r11, r8;               // r11 = A
   mov r12, C;                // r12 = C
   mov rbx, S;                // rbx = S
   mov r10, rdx;
   dec r10;                   // height - 1 row pairs

   @@foryloop:
       vbroadcastss ymm6, [r12];
       vbroadcastss ymm7, [rbx];

       mov rsi, r11;
       lea rdi, [r11 + r9];

       mov rax, rcx;
       shr rax, 3;
       jz @@tailloop;

       @@vecloop:
           vmovups ymm0, [rsi];
           vmovups ymm1, [rdi];
           vmulps ymm2, ymm1, ymm6;
           vmulps ymm3, ymm0, ymm7;
           vsubps ymm2, ymm2, ymm3;
           vmulps ymm4, ymm1, ymm7;
           vmulps ymm5, ymm0, ymm6;
           vaddps ymm4, ymm4, ymm5;
           vmovups [rdi], ymm2;
           vmovups [rsi], ymm4;
           add rsi, 32;
           add rdi, 32;
           dec rax;
       jnz @@vecloop;

       @@tailloop:
       mov rax, rcx;
       and rax, 7;
       jz @@nextline;

       @@tailloop2:
           vmovss xmm0, [rsi];
           vmovss xmm1, [rdi];
           vmulss xmm2, xmm1, xmm6;
           vmulss xmm3, xmm0, xmm7;
           vsubss xmm2, xmm2, xmm3;
           vmulss xmm4, xmm1, xmm7;
           vmulss xmm5, xmm0, xmm6;
           vaddss xmm4, xmm4, xmm5;
           vmovss [rdi], xmm2;
           vmovss [rsi], xmm4;
           add rsi, 4;
           add rdi, 4;
           dec rax;
       jnz @@tailloop2;

       @@nextline:
       add r11, r9;
       add r12, 4;
       add rbx, 4;
       dec r10;
   jnz @@foryloop;

   vzeroupper;
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;

   @@endproc:
end;


// RVB: rotate the column pairs x -> x + 1 of every row, walking x backwards
procedure AVXApplyPlaneRotSeqRVB(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;
// rcx = width, rdx = height, r8 = A, r9 = LineWidthA
var iRBX, iRSI, iR12, iR13 : NativeInt;
    {$IFDEF UNIX}
    C, S : PConstSingleArr;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   mov C, r8;
   mov S, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // need at least one pair and one row
   cmp rcx, 2;
   jl @@endproc;
   cmp rdx, 1;
   jl @@endproc;

   mov iRBX, rbx;
   mov iRSI, rsi;
   mov iR12, r12;
   mov iR13, r13;

   mov rax, rcx;
   sub rax, 2;
   shl rax, 2;
   mov r13, rax;              // (width - 2)*sizeof(single)

   mov r11, r8;               // row pointer
   mov r10, rdx;              // rows left

   @@foryloop:
       lea rsi, [r11 + r13];      // A[y][width - 2]
       mov r12, C;
       add r12, r13;              // c[width - 2]
       mov rbx, S;
       add rbx, r13;              // s[width - 2]
       mov rax, rcx;
       dec rax;                   // width - 1 pairs

       @@forxloop:
           vmovss xmm1, [rsi + 4];     // t := A[y][x + 1]
           vmovss xmm0, [rsi];         // A[y][x]
           vmovss xmm6, [r12];         // c[x]
           vmovss xmm7, [rbx];         // s[x]
           vmulss xmm2, xmm1, xmm6;    // c*t
           vmulss xmm3, xmm0, xmm7;    // s*a
           vsubss xmm2, xmm2, xmm3;
           vmulss xmm4, xmm1, xmm7;    // s*t
           vmulss xmm5, xmm0, xmm6;    // c*a
           vaddss xmm4, xmm4, xmm5;
           vmovss [rsi + 4], xmm2;
           vmovss [rsi], xmm4;
           sub rsi, 4;
           sub r12, 4;
           sub rbx, 4;
           dec rax;
       jnz @@forxloop;

       add r11, r9;
       dec r10;
   jnz @@foryloop;

   vzeroupper;
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov r12, iR12;
   mov r13, iR13;

   @@endproc:
end;

// RVF: same rotation as RVB, walking the column pairs from the left
procedure AVXApplyPlaneRotSeqRVF(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;
// rcx = width, rdx = height, r8 = A, r9 = LineWidthA
var iRBX, iRSI, iR12 : NativeInt;
    {$IFDEF UNIX}
    C, S : PConstSingleArr;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   mov C, r8;
   mov S, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   cmp rcx, 2;
   jl @@endproc;
   cmp rdx, 1;
   jl @@endproc;

   mov iRBX, rbx;
   mov iRSI, rsi;
   mov iR12, r12;

   mov r11, r8;               // row pointer
   mov r10, rdx;              // rows left

   @@foryloop:
       mov rsi, r11;              // A[y][0]
       mov r12, C;
       mov rbx, S;
       mov rax, rcx;
       dec rax;                   // width - 1 pairs

       @@forxloop:
           vmovss xmm1, [rsi + 4];     // t := A[y][x + 1]
           vmovss xmm0, [rsi];
           vmovss xmm6, [r12];
           vmovss xmm7, [rbx];
           vmulss xmm2, xmm1, xmm6;
           vmulss xmm3, xmm0, xmm7;
           vsubss xmm2, xmm2, xmm3;
           vmulss xmm4, xmm1, xmm7;
           vmulss xmm5, xmm0, xmm6;
           vaddss xmm4, xmm4, xmm5;
           vmovss [rsi + 4], xmm2;
           vmovss [rsi], xmm4;
           add rsi, 4;
           add r12, 4;
           add rbx, 4;
           dec rax;
       jnz @@forxloop;

       add r11, r9;
       dec r10;
   jnz @@foryloop;

   vzeroupper;
   mov rbx, iRBX;
   mov rsi, iRSI;
   mov r12, iR12;

   @@endproc:
end;


// its assumed that Linewidthdx and linewidthdy = sizeof(single)
// rcx = N, RDX = X, R8 = Y,
procedure AVXMatrixRotateAligned(N : NativeInt; X : PSingle;
  Y : PSingle; LineWidthDY : NativeInt; {$ifdef UNIX}unixC{$ELSE}c{$endif}, {$ifdef UNIX}unixS{$ELSE}s{$endif} : PSingle); assembler;
{$IFDEF UNIX}
var c : PSingle;
    s : PSingle;
{$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov c, r8;
   mov s, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // note c: xmm0

   // ###########################################
   // #### Stack push
   sub rsp, $30;
   vmovups [rsp + $00], xmm4; 
   vmovups [rsp + $10], xmm5; 
   vmovups [rsp + $20], xmm6; 

   // init
   mov rax, c;
   vbroadcastss xmm1, [rax]; 

   mov rax, s;
   vmovss xmm2, [rax]; 
   lea rax, [rip + cMinusOne];
   vmulss xmm2, xmm2, [rax]; 

   vshufps xmm0, xmm2, xmm2, 0; 
   mov rax, s;
   vbroadcastss xmm2, [rax]; 

   xor r10, r10;

   // 4 single elements per 16 byte block
   mov rax, rcx;
   shr rax, 2;
   test rax, rax;
   jz @@exitLoop;

   @@forNloop:
       // do a full load -> intermediate store in xmm5, and xmm6
       vmovups xmm5, [rdx + r10]; // x, x+1
       vmovups xmm6, [r8 + r10]; // y, y+1

       vmulps xmm3, xmm5, xmm0; // x, x+1 * -s
       vmulps xmm5, xmm5, xmm1; // x, x+1 * c
       vmulps xmm4, xmm6, xmm1; // y, y+1 * c
       vmulps xmm6, xmm6, xmm2; // y, y+1 * s

       vaddps xmm5, xmm5, xmm6; // c*x + s*y  , c*(x+1) + s*(y+1)
       vaddps xmm3, xmm3, xmm4; // -s*x + c*y, -s(x+1) + c*(y+1)

       // write back
       vmovups [rdx + r10], xmm5; 
       vmovups [r8 + r10], xmm3; 

       add r10, 16;

       dec rax;
   jnz @@forNloop;

   @@exitLoop:

   // process the remaining N and 3 elements one at a time
   mov rax, rcx;
   and rax, 3;
   jz @@endProc;

   @@tailLoop:
       vmovss xmm5, [rdx + r10]; 
       vmovss xmm6, [r8 + r10]; 

       //dtemp := c*pX^[i] + s*pY^[i];
       //pY^[i] := - s*pX^[i] + c*pY^[i];
       //px^[i] := dtemp;

       vmulss xmm3, xmm5, xmm0; // x * -s
       vmulss xmm4, xmm6, xmm1; // y * c
       vmulss xmm5, xmm5, xmm1; // x * c
       vmulss xmm6, xmm6, xmm2; // y * s

       vaddss xmm5, xmm5, xmm6; // c*x + s*y
       vaddss xmm3, xmm3, xmm4; // -s*x + c*y

       // write back
       vmovss [rdx + r10], xmm5; 
       vmovss [r8 + r10], xmm3; 

       add r10, 4;

       dec rax;
   jnz @@tailLoop;

   @@endProc:

   // ###########################################
   // #### epilog
   vmovups xmm4, [rsp + $00]; 
   vmovups xmm5, [rsp + $10]; 
   vmovups xmm6, [rsp + $20]; 
   add rsp, $30;
   vzeroupper; 
end;

// rcx = N, RDX = X, R8 = LineWidthDX, R9 = Y;
procedure AVXMatrixRotateUnaligned(N : NativeInt; X : PSingle; const LineWidthDX : NativeInt;
  Y : PSingle; {$ifdef UNIX}unixLineWidthDY{$ELSE}LineWidthDY{$endif} : NativeInt; {$ifdef UNIX}unixc{$ELSE}c{$endif}, s : Pdouble);  assembler;
{$ifdef UNIX}
var LineWidthDY : NativeInt;
    C : PSingle;
{$endif}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov LineWidthDY, r8;
   mov C, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // ###########################################
   // #### Stack push
   sub rsp, $30;
   vmovups [rsp + $00], xmm4; 
   vmovups [rsp + $10], xmm5; 
   vmovups [rsp + $20], xmm6; 

   mov rax, c;
   vbroadcastss xmm1, [rax]; 

   mov rax, s;
   vmovss xmm2, [rax]; 
   lea rax, [rip + cMinusOne];
   vmulss xmm2, xmm2, [rax]; 

   vshufps xmm0, xmm2, xmm2, 0; 

   mov rax, s;
   vbroadcastss xmm2, [rax]; 

   mov r10, LineWidthDY;

   // ###########################################
   // #### loop
   mov rax, rcx;
   shr rax, 1;
   test rax, rax;
   jz @@exitLoop;

   @@forNloop:
       // one element per lane: vmovss + vunpcklps, lanes 2 and 3 stay unused
       vmovss xmm5, [rdx]; // x
       vmovss xmm3, [rdx + r8]; // x+1
       vunpcklps xmm5, xmm5, xmm3; // x, x+1
       vmovss xmm6, [r9]; // y
       vmovss xmm3, [r9 + r10]; // y+1
       vunpcklps xmm6, xmm6, xmm3; // y, y+1

       vmulps xmm3, xmm5, xmm0; // x, x+1 * -s
       vmulps xmm5, xmm5, xmm1; // x, x+1 * c
       vmulps xmm4, xmm6, xmm1; // y, y+1 * c
       vmulps xmm6, xmm6, xmm2; // y, y+1 * s


       vaddps xmm5, xmm5, xmm6; // c*x + s*y  , c*(x+1) + s*(y+1)
       vaddps xmm3, xmm3, xmm4; // -s*x + c*y, -s(x+1) + c*(y+1)


       // write back (xmm5/xmm3 lane 1 -> lane 0, then a scalar store)
       vmovss [rdx], xmm5; 
       vshufps xmm5, xmm5, xmm5, $55;
       vmovss [rdx + r8], xmm5; 

       vmovss [r9], xmm3; 
       vshufps xmm3, xmm3, xmm3, $55;
       vmovss [r9 + r10], xmm3; 

       add rdx, r8;
       add rdx, r8;
       add r9, r10;
       add r9, r10;

   dec rax;
   jnz @@forNloop;

   @@exitLoop:

   // test for an odd N
   mov rax, rcx;
   and rax, 1;
   jz @@endProc;

   // handle last element
   vmovss xmm5, [rdx]; 
   vmovss xmm6, [r9]; 

   //dtemp := c*pX^[i] + s*pY^[i];
   //pY^[i] := - s*pX^[i] + c*pY^[i];
   //px^[i] := dtemp;
   //vmovss xmm3, xmm5;
   //vmovss xmm4, xmm6;

   vmulss xmm3, xmm5, xmm0; // x * -s
   vmulss xmm5, xmm5, xmm1; // x * c
   vmulss xmm4, xmm6, xmm1; // y * c
   vmulss xmm6, xmm6, xmm2; // y * s

   vaddss xmm5, xmm5, xmm6; // c*x + s*y
   vaddss xmm3, xmm3, xmm4; // -s*x + c*y

   // write back
   vmovss [rdx], xmm5; 
   vmovss [r9], xmm3; 

   @@endProc:

   // ###########################################
   // #### Epilog
   vmovups xmm4, [rsp + $00]; 
   vmovups xmm5, [rsp + $10]; 
   vmovups xmm6, [rsp + $20]; 
   add rsp, $30;
   vzeroupper; 
end;

procedure AVXMatrixRotate(N : NativeInt; X : PSingle; const LineWidthDX : NativeInt; Y : PSingle; LineWidthDY : NativeInt; const c, s : single);
begin
     if N <= 0 then
        exit;

     if (LineWidthDX = sizeof(single)) and (LineWidthDY = sizeof(single))
     then
         AVXMatrixRotateAligned(N, X, Y, LineWidthDY, @c, @s)
     else
         AVXMatrixRotateUnAligned(N, X, LineWidthDX, Y, LineWidthDY, @c, @s);
end;


{$ENDIF}

end.
