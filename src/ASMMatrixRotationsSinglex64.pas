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

unit ASMMatrixRotationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}


uses MatrixConstSingle;

procedure ASMApplyPlaneRotSeqRVB(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;
procedure ASMApplyPlaneRotSeqRVF(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;
procedure ASMApplyPlaneRotSeqLVF(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;
procedure ASMApplyPlaneRotSeqLVB(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;


procedure ASMMatrixRotate(N : NativeInt; X : PSingle; const LineWidthDX : NativeInt; Y : PSingle; LineWidthDY : NativeInt; const c, s : single);

{$ENDIF}

implementation

{$IFDEF CPUX64}


// rcx = width, rdx = height, r8 : A, r9 = LineWidthA
procedure ASMApplyPlaneRotSeqLVB(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;
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
       movss xmm6, [r12];
       shufps xmm6, xmm6, 0;   // c[y]
       movss xmm7, [rbx];
       shufps xmm7, xmm7, 0;   // s[y]

       mov rsi, r11;               // row y
       lea rdi, [r11 + r9];        // row y + 1

       mov rax, rcx;
       shr rax, 2;                 // full 8 element blocks
       jz @@tailloop;

       @@vecloop:
           movups xmm0, [rsi];
           movups xmm1, [rdi];
           movaps xmm2, xmm1;
           mulps xmm2, xmm6;
           movaps xmm3, xmm0;
           mulps xmm3, xmm7;
           subps xmm2, xmm3;
           movaps xmm4, xmm1;
           mulps xmm4, xmm7;
           movaps xmm5, xmm0;
           mulps xmm5, xmm6;
           addps xmm4, xmm5;
           movups [rdi], xmm2;
           movups [rsi], xmm4;
           add rsi, 16;
           add rdi, 16;
           dec rax;
       jnz @@vecloop;

       @@tailloop:
       mov rax, rcx;
       and rax, 3;                 // up to 7 remaining elements
       jz @@nextline;

       @@tailloop2:
           movss xmm0, [rsi];
           movss xmm1, [rdi];
           movaps xmm2, xmm1;
           mulss xmm2, xmm6;
           movaps xmm3, xmm0;
           mulss xmm3, xmm7;
           subss xmm2, xmm3;
           movaps xmm4, xmm1;
           mulss xmm4, xmm7;
           movaps xmm5, xmm0;
           mulss xmm5, xmm6;
           addss xmm4, xmm5;
           movss [rdi], xmm2;
           movss [rsi], xmm4;
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

   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;

   @@endproc:
end;

procedure ASMApplyPlaneRotSeqLVF(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;
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
       movss xmm6, [r12];
       shufps xmm6, xmm6, 0;
       movss xmm7, [rbx];
       shufps xmm7, xmm7, 0;

       mov rsi, r11;
       lea rdi, [r11 + r9];

       mov rax, rcx;
       shr rax, 2;
       jz @@tailloop;

       @@vecloop:
           movups xmm0, [rsi];
           movups xmm1, [rdi];
           movaps xmm2, xmm1;
           mulps xmm2, xmm6;
           movaps xmm3, xmm0;
           mulps xmm3, xmm7;
           subps xmm2, xmm3;
           movaps xmm4, xmm1;
           mulps xmm4, xmm7;
           movaps xmm5, xmm0;
           mulps xmm5, xmm6;
           addps xmm4, xmm5;
           movups [rdi], xmm2;
           movups [rsi], xmm4;
           add rsi, 16;
           add rdi, 16;
           dec rax;
       jnz @@vecloop;

       @@tailloop:
       mov rax, rcx;
       and rax, 3;
       jz @@nextline;

       @@tailloop2:
           movss xmm0, [rsi];
           movss xmm1, [rdi];
           movaps xmm2, xmm1;
           mulss xmm2, xmm6;
           movaps xmm3, xmm0;
           mulss xmm3, xmm7;
           subss xmm2, xmm3;
           movaps xmm4, xmm1;
           mulss xmm4, xmm7;
           movaps xmm5, xmm0;
           mulss xmm5, xmm6;
           addss xmm4, xmm5;
           movss [rdi], xmm2;
           movss [rsi], xmm4;
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

   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;

   @@endproc:
end;

procedure ASMApplyPlaneRotSeqRVB(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;
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
           movss xmm1, [rsi + 4];     // t := A[y][x + 1]
           movss xmm0, [rsi];         // A[y][x]
           movss xmm6, [r12];         // c[x]
           movss xmm7, [rbx];         // s[x]
           movaps xmm2, xmm1;
           mulss xmm2, xmm6;
           movaps xmm3, xmm0;
           mulss xmm3, xmm7;
           subss xmm2, xmm3;
           movaps xmm4, xmm1;
           mulss xmm4, xmm7;
           movaps xmm5, xmm0;
           mulss xmm5, xmm6;
           addss xmm4, xmm5;
           movss [rsi + 4], xmm2;
           movss [rsi], xmm4;
           sub rsi, 4;
           sub r12, 4;
           sub rbx, 4;
           dec rax;
       jnz @@forxloop;

       add r11, r9;
       dec r10;
   jnz @@foryloop;

   mov rbx, iRBX;
   mov rsi, iRSI;
   mov r12, iR12;
   mov r13, iR13;

   @@endproc:
end;

procedure ASMApplyPlaneRotSeqRVF(width, height : NativeInt; A : PSingle; const LineWidthA : NativeInt; {$ifdef UNIX}unixC{$ELSE}C{$endif}, {$ifdef UNIX}unixS{$ELSE}S{$endif} : PConstSingleArr); assembler;
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
           movss xmm1, [rsi + 4];     // t := A[y][x + 1]
           movss xmm0, [rsi];
           movss xmm6, [r12];
           movss xmm7, [rbx];
           movaps xmm2, xmm1;
           mulss xmm2, xmm6;
           movaps xmm3, xmm0;
           mulss xmm3, xmm7;
           subss xmm2, xmm3;
           movaps xmm4, xmm1;
           mulss xmm4, xmm7;
           movaps xmm5, xmm0;
           mulss xmm5, xmm6;
           addss xmm4, xmm5;
           movss [rsi + 4], xmm2;
           movss [rsi], xmm4;
           add rsi, 4;
           add r12, 4;
           add rbx, 4;
           dec rax;
       jnz @@forxloop;

       add r11, r9;
       dec r10;
   jnz @@foryloop;

   mov rbx, iRBX;
   mov rsi, iRSI;
   mov r12, iR12;

   @@endproc:
end;

procedure ASMMatrixRotateAligned(N : NativeInt; X : PSingle;
  Y : PSingle; c, {$ifdef UNIX}unixS{$ELSE}s{$endif} : PSingle); assembler;
var dXMM4, dXMM5, dXMM6 : Array[0..3] of single;
    {$ifdef UNIX}
    s : PSingle;
    {$endif}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov s, r8;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // ###########################################
   // #### Stack push
   movups dXMM4, xmm4;
   movups dXMM5, xmm5;
   movups dXMM6, xmm6;

   // init
   mov rax, s;
   movss xmm2, [rax];
   mulss xmm2, [rip + cMinusOne];

   movss xmm0, xmm2; shufps xmm0, xmm0, 0;
   movss xmm1, [r9]; shufps xmm1, xmm1, 0;

   mov rax, s;
   movss xmm2, [rax]; shufps xmm2, xmm2, 0;

   xor r10, r10;

   // 4 single elements per 16 byte block
   mov rax, rcx;
   shr rax, 2;
   test rax, rax;
   jz @@exitLoop;

      @@forNloop:
         // do a full load -> intermediate store in xmm5, and xmm6
         movups xmm5, [rdx + r10];      // x, x+1
         movups xmm6, [r8 + r10];      // y, y+1

         movaps xmm3, xmm5;
         movaps xmm4, xmm6;

         mulps xmm3, xmm0;  // x, x+1 * -s
         mulps xmm5, xmm1;  // x, x+1 * c
         mulps xmm6, xmm2;  // y, y+1 * s
         mulps xmm4, xmm1;  // y, y+1 * c

         addps xmm5, xmm6;  // c*x + s*y  , c*(x+1) + s*(y+1)
         addps xmm3, xmm4;  // -s*x + c*y, -s(x+1) + c*(y+1)

         // write back
         movups [rdx + r10], xmm5;
         movups [r8 + r10], xmm3;

         add r10, 16;

      dec rax;
      jnz @@forNloop;

   @@exitLoop:

   // process the remaining N and 3 elements one at a time
   mov rax, rcx;
   and rax, 3;
   jz @@endProc;

   @@tailLoop:
      movss xmm5, [rdx + r10];
      movss xmm6, [r8 + r10];

      //dtemp := c*pX^[i] + s*pY^[i];
      //pY^[i] := - s*pX^[i] + c*pY^[i];
      //px^[i] := dtemp;
      movss xmm3, xmm5;
      movss xmm4, xmm6;

      mulss xmm3, xmm0;  // x * -s
      mulss xmm5, xmm1;  // x * c
      mulss xmm6, xmm2;  // y * s
      mulss xmm4, xmm1;  // y * c

      addss xmm5, xmm6;  // c*x + s*y
      addss xmm3, xmm4;  // -s*x + c*y

      // write back
      movss [rdx + r10], xmm5;
      movss [r8 + r10], xmm3;

      add r10, 4;

      dec rax;
   jnz @@tailLoop;

   @@endProc:

   // ###########################################
   // #### epilog
   movups xmm4, dXMM4;
   movups xmm5, dXMM5;
   movups xmm6, dXMM6;
end;

// rcx = N, RDX = X, R8 = LineWidthDX, R9 = Y; 
procedure ASMMatrixRotateUnaligned(N : NativeInt; X : PSingle; const LineWidthDX : NativeInt;
  Y : PSingle; {$ifdef UNIX}unixLineWidthDY{$ELSE}LineWidthDY{$endif} : NativeInt; {$ifdef UNIX}unixc{$ELSE}c{$endif}, s : Pdouble); assembler;
var dXMM4, dXMM5, dXMM6 : Array[0..3] of single;
    {$ifdef UNIX}
    LineWidthDY : NativeInt;
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
   movups dXMM4, xmm4;
   movups dXMM5, xmm5;
   movups dXMM6, xmm6;

   mov rax, s;
   movss xmm2, [rax];
   mulss xmm2, [rip + cMinusOne];

   movss xmm0, xmm2; shufps xmm0, xmm0, 0;
   mov rax, C;
   movss xmm1, [rax]; shufps xmm1, xmm1, 0;

   mov rax, s;
   movss xmm2, [rax]; shufps xmm2, xmm2, 0;

   mov r10, LineWidthDY;

   // ###########################################
   // #### loop
   mov rax, rcx;
   shr rax, 1;
   test rax, rax;
   jz @@exitLoop;

      @@forNloop:
         // do a full load -> intermediate store in xmm5, and xmm6
         movss xmm5, [rdx];
         movss xmm0, [rdx + r8];
         unpcklps xmm5, xmm0;
         movss xmm6, [r9];
         movss xmm0, [r9 + r10];
         unpcklps xmm6, xmm0;

         // ###########################################
         // #### apply rotation
         movaps xmm3, xmm5;
         movaps xmm4, xmm6;

         mulps xmm3, xmm1; // c1*x1
         mulps xmm4, xmm2; // s1*y1
         addps xmm3, xmm4; // c1*x1 + s1*y1

         mulps xmm5, xmm2; // s1*x1
         mulps xmm6, xmm1; // c1*y1
         subps xmm6, xmm5; // c1*y1 - s1*x1

         // ###########################################
         // #### write back result
         movss [rdx], xmm3;
         movhlps xmm3, xmm3;
         movss [rdx + r8], xmm3;

         movss [r9], xmm6;
         movhlps xmm6, xmm6;
         movss [r9 + r10], xmm6;

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
   movss xmm5, [rdx];
   movss xmm6, [r9];

   //dtemp := c*pX^[i] + s*pY^[i];
   //pY^[i] := - s*pX^[i] + c*pY^[i];
   //px^[i] := dtemp;
   movss xmm3, xmm5;
   movss xmm4, xmm6;

   mulss xmm3, xmm0;  // x * -s
   mulss xmm5, xmm1;  // x * c
   mulss xmm6, xmm2;  // y * s
   mulss xmm4, xmm1;  // y * c

   addss xmm5, xmm6;  // c*x + s*y
   addss xmm3, xmm4;  // -s*x + c*y

   // write back
   movss [rdx], xmm5;
   movss [r9], xmm3;

   @@endProc:

   // ###########################################
   // #### Epilog
   movups xmm4, dXMM4;
   movups xmm5, dXMM5;
   movups xmm6, dXMM6;
end;

procedure ASMMatrixRotate(N : NativeInt; X : PSingle; const LineWidthDX : NativeInt; Y : PSingle; LineWidthDY : NativeInt; const c, s : single);
begin
     if N <= 0 then
        exit;
        
     if (LineWidthDX = sizeof(single)) and (LineWidthDY = sizeof(single))
     then
         ASMMatrixRotateAligned(N, X, Y, @c, @s)
     else
         ASMMatrixRotateUnAligned(N, X, LineWidthDX, Y, LineWidthDY, @c, @s)
end;


{$ENDIF}

end.
