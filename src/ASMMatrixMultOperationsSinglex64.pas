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


unit ASMMatrixMultOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

// full matrix operations -> there are no zero columns nor zero lines attached
procedure ASMMatrixMultAlignedEvenW1EvenW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixMultUnAlignedEvenW1EvenW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

// the width of the second matrix is uneven -> the last column of mt2 must be handled differently
procedure ASMMatrixMultAlignedEvenW1OddW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixMultUnAlignedEvenW1OddW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

// the width of mt1 is odd but the one of mt2 is even
procedure ASMMatrixMultAlignedOddW1EvenW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixMultUnAlignedOddW1EvenW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

// both matrices have an odd width
procedure ASMMatrixMultAlignedOddW1OddW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure ASMMatrixMultUnAlignedOddW1OddW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

// some special types of multiplications used e.g. in QR Decomposition
// dest = mt1'*mt2; where mt2 is a lower triangular matrix and the operation is transposition
// the function assumes a unit diagonal (does not touch the real middle elements)
// width and height values are assumed to be the "original" (non transposed) ones
procedure ASMMtxMultTria2T1(dest : PSingle; LineWidthDest : NativeInt; mt1 : PSingle; LineWidth1 : NativeInt; {$ifdef UNIX}unixMT2{$ELSE}mt2{$endif} : PSingle; {$ifdef UNIX}unixLineWidth2{$ELSE}LineWidth2{$endif} : NativeInt;
  width1, height1, width2, height2 : NativeInt); assembler;
// mt1 = mt1*mt2'; where mt2 is an upper triangular matrix
procedure ASMMtxMultTria2T1StoreT1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt);

// W = C1*V1*T -> V1 is an upper triangular matrix with assumed unit diagonal entries. Operation on V1 transposition
procedure ASMMtxMultTria2TUpperUnit(dest : PSingle; LineWidthDest : NativeInt; mt1 : PSingle; LineWidth1 : NativeInt;
  {$ifdef UNIX}unixMT2{$ELSE}mt2{$endif} : PSingle; {$ifdef UNIX}unixLineWidth2{$ELSE}LineWidth2{$endif} : NativeInt;
  width1, height1, width2, height2 : NativeInt);

// mt1 = mt1*mt2; where mt2 is an upper triangular matrix
procedure ASMMtxMultTria2Store1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt); assembler;

// calculates mt1 = mt1*mt2', mt2 = lower triangular matrix. diagonal elements are assumed to be 1!
procedure ASMMtxMultLowTria2T2Store1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt); assembler;

// mt1 = mt1*mt2; where mt2 is an upper triangular matrix - diagonal elements are unit
procedure ASMMtxMultTria2Store1Unit(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt); assembler;

// performs a rank2 update in the form
// C = C - A*B' - B*A'
// N...order of C (N x N matrix)
// k... number of columns of A and B
// the lower triangle of C is not referenced
procedure ASMSymRank2UpdateUpperUnaligned( C : PSingle; LineWidthC : NativeInt; A : PSingle; LineWidthA : NativeInt;
  {$IFDEF UNIX}unixB {$ELSE} B {$ENDIF}: PSingle;
  {$IFDEF UNIX}unixLineWidthB {$ELSE} LineWidthB {$ENDIF} : NativeInt;
  N : NativeInt; k : NativeInt ); assembler;

{$ENDIF}

implementation

uses SysUtils;

{$IFDEF CPUX64}

procedure ASMMatrixMultAlignedEvenW1EvenW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4, dXMM5, dXMM6 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

    // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
    // prolog - simulate stack
    mov iRBX, rbx;
    mov iRSI, rsi;
    mov iRDI, rdi;
    mov iR12, r12;
    mov iR13, r13;
    mov iR14, r14;
    mov iR15, r15;

    movups dXMM4, xmm4;
    movups dXMM5, xmm5;
    movups dXMM6, xmm6;


    //destOffset := destLineWidth - Width2*sizeof(single);
    mov rbx, Width2;
    shl rbx, 2;
    mov r15, rdx;
    sub r15, rbx;

    //bytesWidth2 := width2*sizeof(single);
    mov r11, rbx;

    //iters1 := width2 div 2;
    mov r14, width2;
    shr r14, 1;

    //iters2 := -width1*sizeof(single);
    mov rbx, width1;
    shl rbx, 2;
    imul rbx, -1;
    mov r13, rbx;

    //Linewidth2_2 := 2*LineWidth2;
    mov r12, LineWidth2;
    shl r12, 1;

    // initalize matrices
    sub r8, r13;    // r8 = mt1

    // for y := 0 to height1 - 1:
    mov rsi, Height1;

    mov rax, LineWidth2;
    @@forylabel:
        // for x := 0 to width2 - 1:
        mov rbx, r14;
        @@forxlabel:

            xorps xmm0, xmm0;   // dest^ := 0
            xorps xmm2, xmm2;   // (dest + 1)^ := 0;

            mov rdi, r9;       // valcounter2

            // for idx := 0 to width1 div 2 do
            mov rdx, r13;

            @@InnerLoop:
                // Load 2 elements of A [ A0 A1 ]
                movlps xmm1, [r8 + rdx];
                // Expand to [ A0 A0 A1 A1 ]
                unpcklps xmm1, xmm1;

                // Load B rows k, k+1
                movaps xmm3, [rdi];       // [ B00 B01 B02 B03 ]
                movaps xmm4, [rdi + rax]; // [ B10 B11 B12 B13 ]

                // Swizzle to [ B00 B01 B10 B11 ]
                movlhps xmm3, xmm4;

                // Advance rdi by 2 rows
                add rdi, r12;

                // Multiply and Add
                mulps xmm3, xmm1;
                addps xmm0, xmm3;

            add rdx, 8;
            jnz @@InnerLoop;

            // final reduction
            // xmm0 = [ C0a, C1a, C0b, C1b ]
            movhlps xmm2, xmm0; // [ C0b, C1b ]
            addps xmm0, xmm2;   // [ C0, C1 ]

            // store back result
            movlps [rcx], xmm0;

            // increment the pointers
            // inc(mt2), inc(dest);
            //add dword ptr [mt2], 8;
            add r9, 8;
            add rcx, 8;

        // end for x := 0 to width2 - 1
        dec rbx;
        jnz @@forxlabel;

        // dec(mt2, Width2);
        // inc(PByte(mt1), LineWidth1);
        // inc(PByte(dest), destOffset);
        //mov ebx, bytesWidth2;
        //sub dword ptr [mt2], ebx;
        sub r9, r11;
        add r8, LineWidth1;
        add rcx, r15;

    // end for y := 0 to height1 - 1
    //dec eax;
    dec rsi;
    jnz @@forylabel;


    // epilog
    mov rbx, iRBX;
    mov rsi, iRSI;
    mov rdi, iRDI;
    mov r12, iR12;
    mov r13, iR13;
    mov r14, iR14;
    mov r15, iR15;

    movups xmm4, dXMM4;
    movups xmm5, dXMM5;
    movups xmm6, dXMM6;
end;

procedure ASMMatrixMultUnAlignedEvenW1EvenW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4, dXMM5, dXMM6 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

    // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
    // prolog - simulate stack
    mov iRBX, rbx;
    mov iRSI, rsi;
    mov iRDI, rdi;
    mov iR12, r12;
    mov iR13, r13;
    mov iR14, r14;
    mov iR15, r15;

    movups dXMM4, xmm4;
    movups dXMM5, xmm5;
    movups dXMM6, xmm6;
    
    //destOffset := destLineWidth - Width2*sizeof(single);
    mov rbx, Width2;
    shl rbx, 2;
    mov r15, rdx;
    sub r15, rbx;

    //bytesWidth2 := width2*sizeof(single);
    mov r11, rbx;

    //iters1 := width2 div 2;
    mov r14, width2;
    shr r14, 1;

    //iters2 := -width1*sizeof(single);
    mov rbx, width1;
    imul rbx, -4;
    mov r13, rbx;

    //Linewidth2_2 := 2*LineWidth2;
    mov r12, LineWidth2;
    shl r12, 1;

    // initalize matrices
    sub r8, r13;    // r8 = mt1

    // for y := 0 to height1 - 1:
    mov rsi, Height1;

    mov rax, LineWidth2;
    @@forylabel:
        // for x := 0 to width2 - 1:
        mov rbx, r14;
        @@forxlabel:

            xorps xmm0, xmm0;   // dest^ := 0
            xorps xmm2, xmm2;   // (dest + 1)^ := 0;

            mov rdi, r9;       // valcounter2

            // for idx := 0 to width1 div 2 do
            mov rdx, r13;

            @@InnerLoop:
                // Load 2 elements of A [ A0 A1 ]
                movups xmm1, [r8 + rdx]; 
                // Expand to [ A0 A0 A1 A1 ]
                unpcklps xmm1, xmm1;

                // Load B rows k, k+1
                movups xmm3, [rdi];
                movups xmm4, [rdi + rax];

                // Swizzle to [ B00 B01 B10 B11 ]
                movlhps xmm3, xmm4;

                // Advance rdi by 2 rows
                add rdi, r12;

                // Multiply and Add
                mulps xmm3, xmm1;
                addps xmm0, xmm3;

            add rdx, 8;
            jnz @@InnerLoop;

            // final horizontal addition and compact
            movhlps xmm2, xmm0;
            addps xmm0, xmm2;

            // store back result
            movlps [rcx], xmm0;

            // increment the pointers
            // inc(mt2), inc(dest);
            //add dword ptr [mt2], 8;
            add r9, 8;
            add rcx, 8;

        // end for x := 0 to width2 - 1
        dec rbx;
        jnz @@forxlabel;

        // dec(mt2, Width2);
        // inc(PByte(mt1), LineWidth1);
        // inc(PByte(dest), destOffset);
        //mov ebx, bytesWidth2;
        //sub dword ptr [mt2], ebx;
        sub r9, r11;
        add r8, LineWidth1;
        add rcx, r15;

    // end for y := 0 to height1 - 1
    //dec eax;
    dec rsi;
    jnz @@forylabel;

    // epilog
    mov rbx, iRBX;
    mov rsi, iRSI;
    mov rdi, iRDI;
    mov r12, iR12;
    mov r13, iR13;
    mov r14, iR14;
    mov r15, iR15;

    movups xmm4, dXMM4;
    movups xmm5, dXMM5;
    movups xmm6, dXMM6;
end;

// the width of the second matrix is uneven -> the last column of mt2 must be handled differently
procedure ASMMatrixMultAlignedEvenW1OddW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4, dXMM5, dXMM6 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

    // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
    // prolog - simulate stack
    mov iRBX, rbx;
    mov iRSI, rsi;
    mov iRDI, rdi;
    mov iR12, r12;
    mov iR13, r13;
    mov iR14, r14;
    mov iR15, r15;

    movups dXMM4, xmm4;
    movups dXMM5, xmm5;
    movups dXMM6, xmm6;

    //destOffset := destLineWidth - (Width2 - 1)*sizeof(single);
    mov rbx, Width2;
    dec rbx;
    shl rbx, 2;
    mov r15, rdx;
    sub r15, rbx;

    //bytesWidth2 := (width2 - 1)*sizeof(single);
    mov r11, rbx;

    //iters1 := width2 div 2;
    mov r14, width2;
    shr r14, 1;

    //iters2 := -width1*sizeof(single);
    mov rbx, width1;
    shl rbx, 2;
    imul rbx, -1;
    mov r13, rbx;

    //Linewidth2_2 := 2*LineWidth2;
    mov r12, LineWidth2;
    shl r12, 1;

    // initalize matrices
    sub r8, r13;    // r8 = mt1

    // for y := 0 to height1 - 1:
    mov rsi, Height1;

    mov rax, LineWidth2;
    @@forylabel:
        // for x := 0 to width2 - 1:
        mov rbx, r14;
        @@forxlabel:

            xorps xmm0, xmm0;   // dest^ := 0
            xorps xmm2, xmm2;   // (dest + 1)^ := 0;

            mov rdi, r9;       // valcounter2

            // for idx := 0 to width1 div 2 do
            mov rdx, r13;

            @@InnerLoop:
                // Load 2 elements of A [ A0 A1 ]
                movlps xmm1, [r8 + rdx];
                // Expand to [ A0 A0 A1 A1 ]
                unpcklps xmm1, xmm1;

                // Load B rows k, k+1
                movaps xmm3, [rdi];
                movaps xmm4, [rdi + rax];

                // Swizzle to [ B00 B01 B10 B11 ]
                movlhps xmm3, xmm4;

                // Advance rdi by 2 rows
                add rdi, r12;

                // Multiply and Add
                mulps xmm3, xmm1;
                addps xmm0, xmm3;

            add rdx, 8;
            jnz @@InnerLoop;

            // final horizontal addition and compact
            movhlps xmm2, xmm0;
            addps xmm0, xmm2;

            // store back result
            movlps [rcx], xmm0;

            // increment the pointers
            // inc(mt2), inc(dest);
            //add dword ptr [mt2], 8;
            add r9, 8;
            add rcx, 8;

        // end for x := 0 to width2 - 1
        dec rbx;
        jnz @@forxlabel;

        // handle the last column of mt2
        xorps xmm0, xmm0;   // dest^ := 0
        mov rdi, r9;       // valcounter2

        mov rdx, r13;
        @@InnerLoop2:
            // load element from line
            movss xmm1, [r8 + rdx];

            // load, multiply and add
            mulss xmm1, [rdi];
            add rdi, rax;       // next row

            addss xmm0, xmm1;
        add rdx, 4;
        jnz @@InnerLoop2;

        movss [rcx], xmm0;

        // dec(mt2, Width2);
        // inc(PByte(mt1), LineWidth1);
        // inc(PByte(dest), destOffset);
        //mov ebx, bytesWidth2;
        //sub dword ptr [mt2], ebx;
        sub r9, r11;
        add r8, LineWidth1;
        add rcx, r15;

    // end for y := 0 to height1 - 1
    //dec eax;
    dec rsi;
    jnz @@forylabel;

    // epilog
    mov rbx, iRBX;
    mov rsi, iRSI;
    mov rdi, iRDI;
    mov r12, iR12;
    mov r13, iR13;
    mov r14, iR14;
    mov r15, iR15;

    movups xmm4, dXMM4;
    movups xmm5, dXMM5;
    movups xmm6, dXMM6;
end;

procedure ASMMatrixMultUnAlignedEvenW1OddW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4, dXMM5, dXMM6 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

    // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
    // prolog - simulate stack
    mov iRBX, rbx;
    mov iRSI, rsi;
    mov iRDI, rdi;
    mov iR12, r12;
    mov iR13, r13;
    mov iR14, r14;
    mov iR15, r15;

    movups dXMM4, xmm4;
    movups dXMM5, xmm5;
    movups dXMM6, xmm6;

    //destOffset := destLineWidth - (Width2 - 1)*sizeof(single);
    mov rbx, Width2;
    dec rbx;
    shl rbx, 2;
    mov r15, rdx;
    sub r15, rbx;

    //bytesWidth2 := (width2 - 1)*sizeof(single);
    mov r11, rbx;

    //iters1 := width2 div 2;
    mov r14, width2;
    shr r14, 1;

    //iters2 := -width1*sizeof(single);
    mov rbx, width1;
    shl rbx, 2;
    imul rbx, -1;
    mov r13, rbx;

    //Linewidth2_2 := 2*LineWidth2;
    mov r12, LineWidth2;
    shl r12, 1;

    // initalize matrices
    sub r8, r13;    // r8 = mt1

    // for y := 0 to height1 - 1:
    mov rsi, Height1;

    mov rax, LineWidth2;
    @@forylabel:
        // for x := 0 to width2 - 1:
        mov rbx, r14;
        @@forxlabel:

            xorps xmm0, xmm0;   // dest^ := 0
            xorps xmm2, xmm2;   // (dest + 1)^ := 0;

            mov rdi, r9;       // valcounter2

            // for idx := 0 to width1 div 2 do
            mov rdx, r13;

            @@InnerLoop:
                movups xmm1, [r8 + rdx];

                // load 2x2 block
                movups xmm3, [rdi];
                movaps xmm5, xmm3;

                movups xmm4, [rdi + rax];
                add rdi, r12;
                movaps xmm6, xmm4;

                // swap such that we can immediately multiply
                movhlps xmm4, xmm5;
                movlhps xmm3, xmm6;

                // it's a bit faster if we reuse a register - seems the cpu can
                // then parallelize the instructions better
                movaps xmm6, xmm1;

                // multiply 2x2 and add
                mulps xmm3, xmm1;
                mulps xmm4, xmm6;
                addps xmm0, xmm3;
                addps xmm2, xmm4;

                // end for idx := 0 to width1 div 2
            //dec edx;
            add rdx, 16;
            jnz @@InnerLoop;

            // final horizontal addition and compact
            haddps xmm0, xmm2;
            haddps xmm0, xmm0;

            // store back result
            movlps [rcx], xmm0;

            // increment the pointers
            // inc(mt2), inc(dest);
            //add dword ptr [mt2], 8;
            add r9, 8;
            add rcx, 8;

        // end for x := 0 to width2 - 1
        dec rbx;
        jnz @@forxlabel;

        // handle the last column of mt2
        xorps xmm0, xmm0;   // dest^ := 0
        mov rdi, r9;       // valcounter2

        mov rdx, r13;
        @@InnerLoop2:
            // load element from line
            movss xmm1, [r8 + rdx];

            // load, multiply and add
            mulss xmm1, [rdi];
            add rdi, rax;       // next row

            addss xmm0, xmm1;
        add rdx, 4;
        jnz @@InnerLoop2;

        movss [rcx], xmm0;

        // dec(mt2, Width2);
        // inc(PByte(mt1), LineWidth1);
        // inc(PByte(dest), destOffset);
        //mov ebx, bytesWidth2;
        //sub dword ptr [mt2], ebx;
        sub r9, r11;
        add r8, LineWidth1;
        add rcx, r15;

    // end for y := 0 to height1 - 1
    //dec eax;
    dec rsi;
    jnz @@forylabel;

    // epilog
    mov rbx, iRBX;
    mov rsi, iRSI;
    mov rdi, iRDI;
    mov r12, iR12;
    mov r13, iR13;
    mov r14, iR14;
    mov r15, iR15;

    movups xmm4, dXMM4;
    movups xmm5, dXMM5;
    movups xmm6, dXMM6;
end;

// the width of mt1 is odd but the one of mt2 is even
procedure ASMMatrixMultAlignedOddW1EvenW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4, dXMM5, dXMM6, dXMM7 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

    // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
    // prolog - simulate stack
    mov iRBX, rbx;
    mov iRSI, rsi;
    mov iRDI, rdi;
    mov iR12, r12;
    mov iR13, r13;
    mov iR14, r14;
    mov iR15, r15;

    movups dXMM4, xmm4;
    movups dXMM5, xmm5;
    movups dXMM6, xmm6;
    movups dXMM7, xmm7;

    //destOffset := destLineWidth - Width2*sizeof(single);
    mov rbx, Width2;
    shl rbx, 2;
    mov r15, rdx;
    sub r15, rbx;

    //bytesWidth2 := width2*sizeof(single);
    mov r11, rbx;

    //iters1 := width2 div 2;
    mov r14, width2;
    shr r14, 1;

    //iters2 := -(width1 - 1)*sizeof(single);
    mov rbx, width1;
    dec rbx;
    shl rbx, 2;
    imul rbx, -1;
    mov r13, rbx;

    //Linewidth2_2 := 2*LineWidth2;
    mov r12, LineWidth2;
    shl r12, 1;

    // initalize matrices
    sub r8, r13;    // r8 = mt1

    // for y := 0 to height1 - 1:
    mov rsi, Height1;

    mov rax, LineWidth2;
    @@forylabel:
        // for x := 0 to width2 - 1:
        mov rbx, r14;
        @@forxlabel:

            xorps xmm0, xmm0;   // dest^ := 0
            xorps xmm7, xmm7;   // (dest + 1)^ := 0;

            mov rdi, r9;       // valcounter2

            // for idx := 0 to width1 div 2 do
            mov rdx, r13;

            @@InnerLoop:
                // Load 2 elements of A
                movlps xmm1, [r8 + rdx];
                unpcklps xmm1, xmm1;

                // Load B rows
                movaps xmm3, [rdi];
                movaps xmm4, [rdi + rax];
                movlhps xmm3, xmm4;
                add rdi, r12;

                // Mul Add
                mulps xmm3, xmm1;
                addps xmm0, xmm3;

            add rdx, 8;
            jnz @@InnerLoop;

            // special treatment of the last column of mt1:
            movss xmm1, [r8]; shufps xmm1, xmm1, 0;

            movups xmm3, [rdi];
            mulps xmm1, xmm3;

            // final reduction
            movhlps xmm2, xmm0;
            addps xmm0, xmm2;

            // Add last term
            addps xmm0, xmm1;

            // store back result
            movlps [rcx], xmm0;

            // increment the pointers
            // inc(mt2), inc(dest);
            //add dword ptr [mt2], 8;
            add r9, 8;
            add rcx, 8;

        // end for x := 0 to width2 - 1
        dec rbx;
        jnz @@forxlabel;

        // dec(mt2, Width2);
        // inc(PByte(mt1), LineWidth1);
        // inc(PByte(dest), destOffset);
        //mov ebx, bytesWidth2;
        //sub dword ptr [mt2], ebx;
        sub r9, r11;
        add r8, LineWidth1;
        add rcx, r15;

    // end for y := 0 to height1 - 1
    //dec eax;
    dec rsi;
    jnz @@forylabel;

    // epilog
    mov rbx, iRBX;
    mov rsi, iRSI;
    mov rdi, iRDI;
    mov r12, iR12;
    mov r13, iR13;
    mov r14, iR14;
    mov r15, iR15;

    movups xmm4, dXMM4;
    movups xmm5, dXMM5;
    movups xmm6, dXMM6;
    movups xmm7, dXMM7;
end;

procedure ASMMatrixMultUnAlignedOddW1EvenW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4, dXMM5, dXMM6, dXMM7 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

    // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
    // prolog - simulate stack
    mov iRBX, rbx;
    mov iRSI, rsi;
    mov iRDI, rdi;
    mov iR12, r12;
    mov iR13, r13;
    mov iR14, r14;
    mov iR15, r15;

    movups dXMM4, xmm4;
    movups dXMM5, xmm5;
    movups dXMM6, xmm6;
    movups dXMM7, xmm7;

    //destOffset := destLineWidth - Width2*sizeof(single);
    mov rbx, Width2;
    shl rbx, 2;
    mov r15, rdx;
    sub r15, rbx;

    //bytesWidth2 := width2*sizeof(single);
    mov r11, rbx;

    //iters1 := width2 div 2;
    mov r14, width2;
    shr r14, 1;

    //iters2 := -(width1 - 1)*sizeof(single);
    mov rbx, width1;
    dec rbx;
    shl rbx, 2;
    imul rbx, -1;
    mov r13, rbx;

    //Linewidth2_2 := 2*LineWidth2;
    mov r12, LineWidth2;
    shl r12, 1;

    // initalize matrices
    sub r8, r13;    // r8 = mt1

    // for y := 0 to height1 - 1:
    mov rsi, Height1;

    mov rax, LineWidth2;
    @@forylabel:
        // for x := 0 to width2 - 1:
        mov rbx, r14;
        @@forxlabel:

            xorps xmm0, xmm0;   // dest^ := 0
            xorps xmm7, xmm7;   // (dest + 1)^ := 0;

            mov rdi, r9;       // valcounter2

            // for idx := 0 to width1 div 2 do
            mov rdx, r13;

            @@InnerLoop:
                // Load 2 elements of A
                movups xmm1, [r8 + rdx];
                unpcklps xmm1, xmm1;

                // Load B rows
                movups xmm3, [rdi];
                movups xmm4, [rdi + rax];
                movlhps xmm3, xmm4;
                add rdi, r12;

                // Mul Add
                mulps xmm3, xmm1;
                addps xmm0, xmm3;

            add rdx, 8;
            jnz @@InnerLoop;

            // special treatment of the last column of mt1:
            movss xmm1, [r8]; shufps xmm1, xmm1, 0;

            movups xmm3, [rdi];
            mulps xmm1, xmm3;

            // final reduction
            movhlps xmm2, xmm0;
            addps xmm0, xmm2;

            // Add last term
            addps xmm0, xmm1;

            // store back result
            movlps [rcx], xmm0;

            // increment the pointers
            // inc(mt2), inc(dest);
            //add dword ptr [mt2], 8;
            add r9, 8;
            add rcx, 8;

        // end for x := 0 to width2 - 1
        dec rbx;
        jnz @@forxlabel;

        // dec(mt2, Width2);
        // inc(PByte(mt1), LineWidth1);
        // inc(PByte(dest), destOffset);
        //mov ebx, bytesWidth2;
        //sub dword ptr [mt2], ebx;
        sub r9, r11;
        add r8, LineWidth1;
        add rcx, r15;

    // end for y := 0 to height1 - 1
    //dec eax;
    dec rsi;
    jnz @@forylabel;

    // epilog
    mov rbx, iRBX;
    mov rsi, iRSI;
    mov rdi, iRDI;
    mov r12, iR12;
    mov r13, iR13;
    mov r14, iR14;
    mov r15, iR15;

    movups xmm4, dXMM4;
    movups xmm5, dXMM5;
    movups xmm6, dXMM6;
    movups xmm7, dXMM7;
end;

// both matrices have an odd width
procedure ASMMatrixMultAlignedOddW1OddW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4, dXMM5, dXMM6, dXMM7 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

    // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
    // prolog - simulate stack
    mov iRBX, rbx;
    mov iRSI, rsi;
    mov iRDI, rdi;
    mov iR12, r12;
    mov iR13, r13;
    mov iR14, r14;
    mov iR15, r15;

    movups dXMM4, xmm4;
    movups dXMM5, xmm5;
    movups dXMM6, xmm6;
    movups dXMM7, xmm7;

    //destOffset := destLineWidth - (Width2 - 1)*sizeof(single);
    mov rbx, Width2;
    dec rbx;
    shl rbx, 2;
    mov r15, rdx;
    sub r15, rbx;

    //bytesWidth2 := (width2 - 1)*sizeof(single);
    mov r11, rbx;

    //iters1 := width2 div 2;
    mov r14, width2;
    shr r14, 1;

    //iters2 := -(width1 - 1)*sizeof(single);
    mov rbx, width1;
    dec rbx;
    shl rbx, 2;
    imul rbx, -1;
    mov r13, rbx;

    //Linewidth2_2 := 2*LineWidth2;
    mov r12, LineWidth2;
    shl r12, 1;

    // initalize matrices
    sub r8, r13;    // r8 = mt1

    // for y := 0 to height1 - 1:
    mov rsi, Height1;

    mov rax, LineWidth2;
    @@forylabel:
        // for x := 0 to width2 - 1:
        mov rbx, r14;
        @@forxlabel:

            xorps xmm0, xmm0;   // dest^ := 0
            xorps xmm7, xmm7;   // (dest + 1)^ := 0;

            mov rdi, r9;       // valcounter2

            // for idx := 0 to width1 div 2 do
            mov rdx, r13;

            @@InnerLoop:
                // Load 2 elements of A
                movlps xmm1, [r8 + rdx];
                unpcklps xmm1, xmm1;

                // Load B rows
                movaps xmm3, [rdi];
                movaps xmm4, [rdi + rax];
                movlhps xmm3, xmm4;
                add rdi, r12;

                // Mul Add
                mulps xmm3, xmm1;
                addps xmm0, xmm3;

            add rdx, 8;
            jnz @@InnerLoop;

            // special treatment of the last column of mt1:
            movss xmm1, [r8]; shufps xmm1, xmm1, 0;

            movaps xmm3, [rdi];
            mulps xmm1, xmm3;

            // final reduction
            movhlps xmm2, xmm0;
            addps xmm0, xmm2;

            // Add last term
            addps xmm0, xmm1;

            // store back result
            movlps [rcx], xmm0;

            // increment the pointers
            // inc(mt2), inc(dest);
            //add dword ptr [mt2], 8;
            add r9, 8;
            add rcx, 8;

        // end for x := 0 to width2 - 1
        dec rbx;
        jnz @@forxlabel;

        // handle the last column of mt2
        xorps xmm0, xmm0;   // dest^ := 0
        mov rdi, r9;       // valcounter2

        sub r13, 4;
        add r8, 4;
        mov rdx, r13;
        @@InnerLoop2:
            // load element from line
            movss xmm1, [r8 + rdx];

            // load, multiply and add
            mulss xmm1, [rdi];
            add rdi, rax;       // next row

            addss xmm0, xmm1;
        add rdx, 4;
        jnz @@InnerLoop2;
        add r13, 4;
        sub r8, 4;

        movss [rcx], xmm0;

        // dec(mt2, Width2);
        // inc(PByte(mt1), LineWidth1);
        // inc(PByte(dest), destOffset);
        //mov ebx, bytesWidth2;
        //sub dword ptr [mt2], ebx;
        sub r9, r11;
        add r8, LineWidth1;
        add rcx, r15;

    // end for y := 0 to height1 - 1
    //dec eax;
    dec rsi;
    jnz @@forylabel;

    // epilog
    mov rbx, iRBX;
    mov rsi, iRSI;
    mov rdi, iRDI;
    mov r12, iR12;
    mov r13, iR13;
    mov r14, iR14;
    mov r15, iR15;

    movups xmm4, dXMM4;
    movups xmm5, dXMM5;
    movups xmm6, dXMM6;
    movups xmm7, dXMM7;
end;

procedure ASMMatrixMultUnAlignedOddW1OddW2(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var dXMM4, dXMM5, dXMM6, dXMM7 : Array[0..3] of single;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

    // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = mt2
    // prolog - simulate stack
    mov iRBX, rbx;
    mov iRSI, rsi;
    mov iRDI, rdi;
    mov iR12, r12;
    mov iR13, r13;
    mov iR14, r14;
    mov iR15, r15;

    movups dXMM4, xmm4;
    movups dXMM5, xmm5;
    movups dXMM6, xmm6;
    movups dXMM7, xmm7;

    //destOffset := destLineWidth - (Width2 - 1)*sizeof(single);
    mov rbx, Width2;
    dec rbx;
    shl rbx, 2;
    mov r15, rdx;
    sub r15, rbx;

    //bytesWidth2 := (width2 - 1)*sizeof(single);
    mov r11, rbx;

    //iters1 := width2 div 2;
    mov r14, width2;
    shr r14, 1;

    //iters2 := -(width1 - 1)*sizeof(single);
    mov rbx, width1;
    dec rbx;
    imul rbx, -4;
    mov r13, rbx;

    //Linewidth2_2 := 2*LineWidth2;
    mov r12, LineWidth2;
    shl r12, 1;

    // initalize matrices
    sub r8, r13;    // r8 = mt1

    // for y := 0 to height1 - 1:
    mov rsi, Height1;

    mov rax, LineWidth2;
    @@forylabel:
        // for x := 0 to width2 - 1:
        mov rbx, r14;
        @@forxlabel:

            xorps xmm0, xmm0;   // dest^ := 0
            xorps xmm7, xmm7;   // (dest + 1)^ := 0;

            mov rdi, r9;       // valcounter2

            // for idx := 0 to width1 div 2 do
            mov rdx, r13;

            @@InnerLoop:
                // Load 2 elements of A
                movups xmm1, [r8 + rdx];
                unpcklps xmm1, xmm1;

                // Load B rows
                movups xmm3, [rdi];
                movups xmm4, [rdi + rax];
                movlhps xmm3, xmm4;
                add rdi, r12;

                // Mul Add
                mulps xmm3, xmm1;
                addps xmm0, xmm3;

            add rdx, 8;
            jnz @@InnerLoop;

            // special treatment of the last column of mt1:
            movss xmm1, [r8]; shufps xmm1, xmm1, 0;

            movups xmm3, [rdi];
            mulps xmm1, xmm3;

            // final reduction
            movhlps xmm2, xmm0;
            addps xmm0, xmm2;

            // Add last term
            addps xmm0, xmm1;

            // store back result
            movlps [rcx], xmm0;

            // increment the pointers
            // inc(mt2), inc(dest);
            //add dword ptr [mt2], 8;
            add r9, 8;
            add rcx, 8;

        // end for x := 0 to width2 - 1
        dec rbx;
        jnz @@forxlabel;

        // handle the last column of mt2
        xorps xmm0, xmm0;   // dest^ := 0
        mov rdi, r9;       // valcounter2

        sub r13, 4;
        add r8, 4;
        mov rdx, r13;
        @@InnerLoop2:
            // load element from line
            movss xmm1, [r8 + rdx];

            // load, multiply and add
            movss xmm2, [rdi];
            mulss xmm1, [rdi];
            add rdi, rax;       // next row

            addss xmm0, xmm1;
        add rdx, 4;
        jnz @@InnerLoop2;
        add r13, 4;
        sub r8, 4;

        movss [rcx], xmm0;

        // dec(mt2, Width2);
        // inc(PByte(mt1), LineWidth1);
        // inc(PByte(dest), destOffset);
        //mov ebx, bytesWidth2;
        //sub dword ptr [mt2], ebx;
        sub r9, r11;
        add r8, LineWidth1;
        add rcx, r15;

    // end for y := 0 to height1 - 1
    //dec eax;
    dec rsi;
    jnz @@forylabel;

    mov rbx, iRBX;
    mov rsi, iRSI;
    mov rdi, iRDI;
    mov r12, iR12;
    mov r13, iR13;
    mov r14, iR14;
    mov r15, iR15;

    movups xmm4, dXMM4;
    movups xmm5, dXMM5;
    movups xmm6, dXMM6;
    movups xmm7, dXMM7;
end;


// ###########################################
// #### Special multiplication routines (for now only used in QR Decomposition)
// ###########################################

// note the result is stored in mt1 again!
// mt1 = mt1*mt2; where mt2 is an upper triangular matrix
procedure ASMMtxMultTria2Store1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt); assembler;
var iRBX, iRDI, iRSI, iR12, iR13 : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
     // prolog init stack
     // rcx = mt1, rdx = LineWidth1, r8 = mt2, r9 = LineWidth2
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

        // prolog: stack
        mov iRBX, rbx;
        mov iRDI, rdi;
        mov iRSI, rsi;
        mov iR12, r12;
        mov iR13, r13;

        // r13 = height1
        mov r13, height1;

        // wm1: r11
        mov r11, width2;
        dec r11;

        // iter: r10
        mov r10, width1;
        shl r10, 2;
        imul r10, -1;
        // init

        // inc(mt2, width2 - 1);
        mov rax, r11;
        shl rax, 2; //sizeof(single)
        add r8, rax;


        // for x := 0 to width2 - 1 do
        mov r12, width2;
        @@forxloop:
           mov rdi, r13;  // height1

           mov rax, rcx;
           sub rax, r10;

           // for y := 0 to height1 - 1
           @@foryloop:
              // tmp := 0;
              xorps xmm0, xmm0;

              // r8, mt2
              mov rbx, r8;

              // for idx := 0 to width1 - x - 1
              mov rsi, r10;

              // check if we have enough iterations:
              test rsi, rsi;
              jz @@foridxloopend;

              @@foridxloop:
                 movss xmm1, [rbx];
                 movss xmm2, [rax + rsi]

                 add rbx, r9;  // + linewidth2

                 mulss xmm1, xmm2;
                 addss xmm0, xmm1;

              add rsi, 4;
              jnz @@foridxloop;

              @@foridxloopend:

              // PConstSingleArr(pmt1)^[width2 - 1 - x] := tmp;
              mov rbx, rax;
              add rbx, r10;
              mov rsi, r12; // r12 = width2
              dec rsi;
              movss [rbx + 8*rsi], xmm0;

              // inc(PByte(pmT1), LineWidth1);
              add rax, rdx;

           dec rdi;
           jnz @@foryloop;

           // reduce for idx loop
           add r10, 4;
           // dec(mt2);
           sub r8, 4;

        // dec width2
        dec r12;
        jnz @@forxloop;

        // cleanup stack
        mov rbx, iRBX;
        mov rdi, iRDI;
        mov rsi, iRSI;
        mov r12, iR12;
        mov r13, iR13;
     end;

// mt1 = mt1 * mt2', result stored over mt2, mt2 upper triangular.
// The inherited transposed dot product cannot terminate, so it raises.
procedure ASMMtxMultTria2T1StoreT1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt);
begin
   raise ENotImplemented.Create('ASMMtxMultTria2T1StoreT1 is not implemented');
end;


// dest = mt1 * mt2', mt2 upper triangular with an assumed unit diagonal.
// The inherited body walks off the buffer, so it raises until a blocked version
// exists.
procedure ASMMtxMultTria2TUpperUnit(dest : PSingle; LineWidthDest : NativeInt; mt1 : PSingle; LineWidth1 : NativeInt;
  {$ifdef UNIX}unixMT2{$ELSE}mt2{$endif} : PSingle; {$ifdef UNIX}unixLineWidth2{$ELSE}LineWidth2{$endif} : NativeInt;
  width1, height1, width2, height2 : NativeInt);
begin
   raise ENotImplemented.Create('ASMMtxMultTria2TUpperUnit is not implemented');
end;


// note the result is stored in mt2 again!
// dest = mt1'*mt2; where mt2 is a lower triangular matrix and the operation is transposition
// the function assumes a unit diagonal (does not touch the real middle elements)
// width and height values are assumed to be the "original" (non transposed) ones
procedure ASMMtxMultTria2T1(dest : PSingle; LineWidthDest : NativeInt; mt1 : PSingle; LineWidth1 : NativeInt;
  {$ifdef UNIX}unixMT2{$ELSE}mt2{$endif} : PSingle; {$ifdef UNIX}unixLineWidth2{$ELSE}LineWidth2{$endif} : NativeInt;
  width1, height1, width2, height2 : NativeInt); assembler;
var pMt2 : PSingle;
    iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    {$IFDEF UNIX}
    mt2 : PSingle;
    LineWidth2 : NativeInt;
    {$ENDIF}
     // note: RCX = dest, RDX = destLineWidth, R8 = mt1, R9 = LineWidth1
     // prolog - simulate stack
     asm
        {$IFDEF UNIX}
        // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
        // (note that the 5th and 6th parameter are are on the stack)
        // The parameters are passed in the following order:
        // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
        mov mt2, r8;
        mov LineWidth2, r9;
        mov r8, rdx;
        mov r9, rcx;
        mov rcx, rdi;
        mov rdx, rsi;
        {$ENDIF}

        mov iR12, r12;
        mov iR13, r13;
        mov iR14, r14;
        mov iR15, r15;
        mov iRSI, rsi;
        mov iRDI, rdi;
        mov iRBX, rbx;

        mov r15, LineWidth2;   // Linewidth2 is on the stack -> use it in local register

        // width2D2 := width2 div 2;
        mov r14, width2;
        shr r14, 1;

        // for x := 0 to width1 - 1 do
        mov rax, width1;

        @@forxloop:

          // pMT2 := mt2;
          // pDest := dest;

          mov rbx, mt2;
          mov pMT2, rbx;

          mov r13, rcx;   // r13 is pDest


          // for y := 0 to width2D2 - 1 do
          mov r12, r14;
          test r12, r12;
          jz @@foryloopend;

          xor r12, r12;
          @@foryloop:

               // valCounter1 := PConstSingleArr(mt1);
               // inc(PByte(valCounter1), 2*y*LineWidth1);
               mov rsi, r8;
               mov rbx, r12;
               add rbx, rbx;
               imul rbx, r9;
               add rsi, rbx;

               // valCounter2 := PConstSingleArr(pMT2);
               // inc(PByte(valCounter2), (2*y + 1)*LineWidth2);
               mov rdi, pMt2;
               mov rbx, r12;
               add rbx, rbx;
               imul rbx, r15;
               add rbx, r15;
               add rdi, rbx;

               // tmp[0] := valCounter1^[0];
               // inc(PByte(valCounter1), LineWidth1);
               movss xmm0, [rsi];
               add rsi, r9;

               // if height2 - 2*y - 1 > 0 then
               mov rbx, r12;
               add rbx, rbx;
               inc rbx;

               cmp rbx, height2;
               jnl @@PreInnerLoop;
                   // tmp[0] := tmp[0] + valCounter1^[0]*valCounter2^[0];
                   // tmp[1] := valCounter1^[0];
                   movss xmm1, [rsi];
                   movlhps xmm0, xmm1;

                   mulss xmm1, [rdi];
                   addss xmm0, xmm1;

                   //inc(PByte(valCounter1), LineWidth1);
                   //inc(PByte(valCounter2), LineWidth2);

                   add rsi, r9;
                   add rdi, r15;

               @@PreInnerLoop:

               // rest is a single column!

               // prepare loop
               mov rbx, height2;
               sub rbx, r12;
               sub rbx, r12;
               sub rbx, 2;

               test rbx, rbx;
               jle @@InnerLoopEnd;

               @@InnerLoop:
                  // tmp[0] := tmp[0] + valCounter1^[0]*valCounter2^[0];
                  // tmp[1] := tmp[1] + valCounter1^[0]*valCounter2^[1];
                  movss xmm1, [rsi]; shufps xmm1, xmm1, 0;
                  movups xmm2, [rdi];

                  mulps xmm2, xmm1;
                  addps xmm0, xmm2;

                  //inc(PByte(valCounter1), LineWidth1);
                  //inc(PByte(valCounter2), LineWidth2);

                  add rsi, r9;
                  add rdi, r15;

               dec rbx;
               jnz @@InnerLoop;

               @@InnerLoopEnd:


               // write back result

               // pDest^ := tmp[0];
               // PSingle(NativeUint(pDest) + sizeof(single))^ := tmp[1];

               movups [r13], xmm0;

               // inc(pDest, 2);
               // inc(pMT2, 2);
               add r13, 8;
               add pMT2, 8;

          // end foryloop
          inc r12;
          cmp r12, r14;
          jne @@foryloop;

          @@foryloopend:


          //if (width2 and $01) = 1 then
          mov r12, width2;
          and r12, 1;

          jz @@ifend1;

            // special handling of last column (just copy the value)

            // valCounter1 := PConstSingleArr(mt1);
            mov r12, r8;

            //inc(PByte(valCounter1), LineWidth1*(height1 - 1));
            mov rbx, height1;
            dec rbx;
            imul rbx, r9;

            // pDest^ := valCounter1^[0];
            movss xmm0, [r12 + rbx];
            movss [r13], xmm0;
          @@ifend1:


          //inc(mt1);
          //inc(PByte(dest), LineWidthDest);
          add r8, 4;
          add rcx, rdx;    // note: this can be done since dest is rcx

       // end for loop
       dec rax;
       jnz @@forxloop;

       // epilog
       mov r12, iR12;
       mov r13, iR13;
       mov r14, iR14;
       mov r15, iR15;
       mov rsi, iRSI;
       mov rdi, iRDI;
       mov rbx, iRBX;
end;

// calculates mt1 = mt1*mt2', mt2 = lower triangular matrix. diagonal elements are assumed to be 1!
procedure ASMMtxMultLowTria2T2Store1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt); assembler;
var iRBX, iRDI, iRSI : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
     // rcx: mt1, rdx: LineWidth1, r8 : mt2, r9 : LineWidth2
     asm
        {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

        // prolog - stack
        mov iRBX, rbx;
        mov iRDI, rdi;
        mov iRSI, rsi;

        // r11 : height1
        mov r11, height1;

        // r10 = iter := -(width2 - 1)*sizeof(single);
        mov r10, width2;
        dec r10;
        imul r10, -4;

        // start from bottom
        // r8: mt2
        // inc(PByte(mt2),(height2 - 1)*LineWidth2);
        mov rax, height2;
        dec rax;
        imul rax, r9;
        add r8, rax;
        sub r8, r10;

        // for x := 0 to width2 - 2
        mov rbx, width2;
        dec rbx;
        jz @@endproc;
        @@forxloop:
           mov rax, rcx;
           sub rax, r10;

           // for y := 0 to height1 - 1
           mov rsi, r11;
           @@foryloop:
              xorps xmm0, xmm0;

              // for idx := 0 to width2 - x - 2
              mov rdi, r10;
              test rdi, rdi;
              jz @@foridxloopend;

              // unrolled loop 2x2
              add rdi, 32;
              jg @@foridxloopStart;

              @@foridxlongloop:
                 movups xmm1, [rax + rdi - 32];
                 movups xmm2, [r8 + rdi - 32];
                 mulps xmm1, xmm2;
                 addps xmm0, xmm1;

                 movups xmm1, [rax + rdi - 16];
                 movups xmm2, [r8 + rdi - 16];
                 mulps xmm1, xmm2;
                 addps xmm0, xmm1;
              add rdi, 32;
              jl @@foridxlongloop;

              haddps xmm0, xmm0;
              haddps xmm0, xmm0;

              @@foridxloopStart:
              sub rdi, 32;

              jz @@foridxloopend;

              @@foridxloop:
                 movss xmm1, [rax + rdi];
                 movss xmm2, [r8 + rdi];
                 mulss xmm1, xmm2;
                 addss xmm0, xmm1;

              add rdi, 4;
              jnz @@foridxloop;

              @@foridxloopend:

              // last element is unit:
              movss xmm1, [rax];
              addss xmm0, xmm1;

              // write back
              // PConstSingleArr(pMt1)^[width2 - x - 1] := tmp + valCounter1^[width2 - x - 1];
              movss [rax], xmm0;

              add rax, rdx;

           dec rsi;
           jnz @@foryloop;

           // dec(PByte(mt2), LineWidth2);
           sub r8, r9;
           sub r8, 4;

           // adjust iterator to the next x value for the idxloop
           add r10, 4;

        dec rbx;
        jnz @@forxloop;

        @@endproc:

        // epilog: stack fixing
        mov rbx, iRBX;
        mov rdi, iRDI;
        mov rsi, iRSI;
     end;

procedure ASMMtxMultTria2Store1Unit(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt;
  {$ifdef UNIX}unixWidth{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt); assembler;
var iRBX, iRDI, iRSI, iR12 : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
// rcx : mt1, rdx : LineWidth1, r8 : mt2, r9: LineWidth2
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // prolog - stack
   mov iRBX, rbx;
   mov iRDI, rdi;
   mov iRSI, rsi;
   mov iR12, r12;
   // init

   // r12: height1
   mov r12, height1;

   // r10 : iter := -(width1-1)*sizeof(single);
   mov r10, width1;
   dec r10;
   imul r10, -4;

   // inc(mt2, width2 - 1);
   mov rax, width2;
   dec rax;
   imul rax, 4; //sizeof(single)
   add r8, rax;

   // r11: width2
   mov r11, width2;
   dec r11;

   // for x := 0 to width2 - 2 do
   @@forxloop:
      mov rdi, r12;

      mov rax, rcx;
      sub rax, r10;

      // for y := 0 to height1 - 1
      @@foryloop:
         // tmp := 0;
         xorps xmm0, xmm0;

         // r8, mt2
         mov rbx, r8;

         // for idx := 0 to width1 - x - 2
         mov rsi, r10;

         // check if we have enough r10ations:
         cmp rsi, 0;
         jge @@foridxloopend;

         @@foridxloop:
            movss xmm1, [rbx];
            movss xmm2, [rax + rsi]

            add rbx, r9;  // + linewidth2

            mulss xmm1, xmm2;
            addss xmm0, xmm1;

         add rsi, 4;
         jnz @@foridxloop;

         @@foridxloopend:

         // last element is unit
         addss xmm0, [rax];

         // PConstSingleArr(pmt1)^[width2 - 1 - x] := tmp;
         mov rbx, rax;
         add rbx, r10;
         mov rsi, r11;
         movss [rbx + 8*rsi], xmm0;

         // inc(PByte(pmT1), LineWidth1);
         add rax, rdx;

      dec rdi;
      jnz @@foryloop;

      // reduce for idx loop
      add r10, 4;
      // dec(mt2);
      sub r8, 4;

   dec r11;
   jnz @@forxloop;

   @@endproc:

   // cleanup stack
   mov rbx, iRBX;
   mov rdi, iRDI;
   mov rsi, iRSI;
   mov r12, iR12;
end;


procedure ASMSymRank2UpdateUpperUnaligned( C : PSingle; LineWidthC : NativeInt; A : PSingle; LineWidthA : NativeInt;
  {$IFDEF UNIX}unixB {$ELSE} B {$ENDIF}: PSingle;
  {$IFDEF UNIX}unixLineWidthB {$ELSE} LineWidthB {$ENDIF} : NativeInt; N : NativeInt; k : NativeInt );
// rcx = C, rdx = LineWidthC, r8 = A, r9 = LineWidthA
// unix has B and LineWidthB also in registers
var i, j : NativeInt;
    iRBX, iRDI, iRSI : NativeInt;
    {$IFDEF UNIX}
    B : PSingle; LineWidthB : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   // Linux uses a diffrent ABI -> copy over the registers so they meet with winABI
   // (note that the 5th and 6th parameter are are on the stack)
   // The parameters are passed in the following order:
   // RDI, RSI, RDX, RCX -> mov to RCX, RDX, R8, R9
   mov B, unixB;
   mov LineWidthB, unixLineWidthB;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   // save register
   mov iRBX, rbx;
   mov iRDI, rdi;
   mov iRSI, rsi;

   // rcx -> pointer to C
   // r8 -> ponter to pA1
   // rsi -> pointer to pB1
   mov rsi, B;

   mov rdi, k;
   imul rdi, -4;
   mov k, rdi;

   sub r8, rdi;
   sub rsi, rdi;

   mov rdi, N;
   shl rdi, 2;
   add rcx, rdi;


   // for j := 0 to N - 1 do
   //
   neg rdi;
   mov j, rdi;
   @@forNLoop:
       mov r10, j;
       mov i, r10;

       // ###########################################
       // #### Init A2 and B2
       // pA2
       mov rbx, r8;
       // pB2
       mov rdi, rsi;

       @@forjNLoop:
            xorps xmm0, xmm0;

            // ###########################################
            // #### Init loop
            mov r10, k;

            // accumulate
            @@forlLoop:
                add r10, 16;
                jg @@forlLoopEnd;

                movups xmm1, [r8 + r10 - 16];  // pA1;
                movups xmm2, [rdi + r10 - 16]; // pB2
                movups xmm3, [rsi + r10 - 16]; // pB1;
                movups xmm4, [rbx + r10 - 16]; // pA2;

                mulps xmm1, xmm2;
                addps xmm0, xmm1;
                mulps xmm3, xmm4;
                addps xmm0, xmm3;
            jmp @@forlLoop;

            @@forlLoopEnd:

            // is iterator actualy 16? (aka even k)
            cmp r10, 16;
            je @@NextN;

            // last element
            movss xmm1, [r8 - 8]; // pA1;
            movss xmm2, [rdi - 8]; // pB2
            movss xmm3, [rsi - 8]; // pB1;
            movss xmm4, [rbx - 8]; // pA2;

            mulss xmm1, xmm2;
            addss xmm0, xmm1;
            mulss xmm3, xmm4;
            addss xmm0, xmm3;

            @@NextN:

            // ###########################################
            // #### pC^[i] := pC^[i] - xmm0
            mov r10, i;
            haddps xmm0, xmm0;
            haddps xmm0, xmm0;
            movss xmm1, [rcx + r10];

            subss xmm1, xmm0;
            movss [rcx + r10], xmm1;

            add rbx, r9;          // increment pA2
            add rdi, LineWidthB;  // increment pB2

       add i, 4;
       jnz @@forjNLoop;

       // next line
       add rcx, rdx;
       add r8, r9;
       add rsi, LineWidthB;
   add j, 4;
   jnz @@forNLoop;

   // ###########################################
   // #### Finalize stack
   mov rbx, iRBX;
   mov rdi, iRDI;
   mov rsi, iRSI;
end;

{$ENDIF}

end.
