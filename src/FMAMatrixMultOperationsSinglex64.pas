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


unit FMAMatrixMultOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

uses MatrixConstSingle;

// full matrix operations
procedure FMAMatrixMultAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
procedure FMAMatrixMultUnAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;

// stubs for triangular
procedure FMAMtxMultTria2T1(dest : PSingle; LineWidthDest : NativeInt; mt1 : PSingle; LineWidth1 : NativeInt; {$ifdef UNIX}unixMT2{$ELSE}mt2{$endif} : PSingle; {$ifdef UNIX}unixLineWidth2{$ELSE}LineWidth2{$endif} : NativeInt; width1, height1, width2, height2 : NativeInt);
procedure FMAMtxMultTria2T1StoreT1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt);
procedure FMAMtxMultTria2TUpperUnit(dest : PSingle; LineWidthDest : NativeInt; mt1 : PSingle; LineWidth1 : NativeInt; {$ifdef UNIX}unixMT2{$ELSE}mt2{$endif} : PSingle; {$ifdef UNIX}unixLineWidth2{$ELSE}LineWidth2{$endif} : NativeInt; width1, height1, width2, height2 : NativeInt);
procedure FMAMtxMultLowTria2T2Store1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt);

{$ENDIF}

implementation

{$IFDEF CPUX64}

uses SysUtils, ASMMatrixMultOperationsSinglex64;

procedure FMAMatrixMultAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    iDestLineWidth : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov iRBX, rbx;
   mov iRSI, rsi;
   mov iRDI, rdi;
   mov iR12, r12;
   mov iR13, r13;
   mov iR14, r14;
   mov iR15, r15;
   mov iDestLineWidth, rdx;

   mov rdi, LineWidth1;
   mov r11, LineWidth2;
   mov rsi, height1;
   
   @@foryloop:
      mov r12, width2;
      mov rbx, r9; 
      mov r14, rcx; 

      @@forxloop:
         cmp r12, 8;
         jl @@lastX;

         vxorps ymm0, ymm0, ymm0;
         mov rax, r8; 
         mov r10, rbx; 
         mov rdx, width1;
         
         @@innerloop8:
            vbroadcastss ymm1, [rax];
            vfmadd231ps ymm0, ymm1, [r10];
            add rax, 4;
            add r10, r11;
         dec rdx;
         jnz @@innerloop8;
         
         vmovaps [r14], ymm0;
         add r14, 32;
         add rbx, 32;
         sub r12, 8;
      jnz @@forxloop;
      
      @@lastX:
      test r12, r12;
      jz @@nextRow;
      @@forxremainder:
         vxorps xmm0, xmm0, xmm0;
         mov rax, r8;
         mov r10, rbx;
         mov rdx, width1;
         @@innerloopscalar:
            vmovss xmm1, [rax];
            vmulss xmm1, xmm1, [r10];
            vaddss xmm0, xmm0, xmm1;
            add rax, 4;
            add r10, r11;
         dec rdx;
         jnz @@innerloopscalar;
         vmovss [r14], xmm0;
         add r14, 4;
         add rbx, 4;
      dec r12;
      jnz @@forxremainder;

      @@nextRow:
      add r8, rdi;
      add rcx, iDestLineWidth;
   dec rsi;
   jnz @@foryloop;

   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;
   vzeroupper;
end;

procedure FMAMatrixMultUnAligned(dest : PSingle; const destLineWidth : NativeInt; mt1, mt2 : PSingle; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); assembler;
var iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
    iDestLineWidth : NativeInt;
    {$ifdef UNIX}
    width1 : NativeInt;
    height1 : NativeInt;
    {$ENDIF}
asm
   {$IFDEF UNIX}
   mov width1, r8;
   mov height1, r9;
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov iRBX, rbx;
   mov iRSI, rsi;
   mov iRDI, rdi;
   mov iR12, r12;
   mov iR13, r13;
   mov iR14, r14;
   mov iR15, r15;
   mov iDestLineWidth, rdx;

   mov rdi, LineWidth1;
   mov r11, LineWidth2;
   mov rsi, height1;
   
   @@foryloop:
      mov r12, width2;
      mov rbx, r9; 
      mov r14, rcx; 

      @@forxloop:
         cmp r12, 8;
         jl @@lastX;

         vxorps ymm0, ymm0, ymm0;
         mov rax, r8; 
         mov r10, rbx; 
         mov rdx, width1;
         @@innerloop8:
            vbroadcastss ymm1, [rax];
            vmovups ymm2, [r10];
            vfmadd231ps ymm0, ymm1, ymm2;
            add rax, 4;
            add r10, r11;
         dec rdx;
         jnz @@innerloop8;
         vmovups [r14], ymm0;
         add r14, 32;
         add rbx, 32;
         sub r12, 8;
      jnz @@forxloop;
      
      @@lastX:
      test r12, r12;
      jz @@nextRow;
      @@forxremainder:
         vxorps xmm0, xmm0, xmm0;
         mov rax, r8;
         mov r10, rbx;
         mov rdx, width1;
         @@innerloopscalar:
            vmovss xmm1, [rax];
            vmulss xmm1, xmm1, [r10];
            vaddss xmm0, xmm0, xmm1;
            add rax, 4;
            add r10, r11;
         dec rdx;
         jnz @@innerloopscalar;
         vmovss [r14], xmm0;
         add r14, 4;
         add rbx, 4;
      dec r12;
      jnz @@forxremainder;

      @@nextRow:
      add r8, rdi;
      add rcx, iDestLineWidth;
   dec rsi;
   jnz @@foryloop;

   mov rbx, iRBX;
   mov rsi, iRSI;
   mov rdi, iRDI;
   mov r12, iR12;
   mov r13, iR13;
   mov r14, iR14;
   mov r15, iR15;
   vzeroupper;
end;

// The four triangular variants delegate to the SSE kernels, as a Pascal call: the
// callees read their later parameters from the stack, which an inline `asm call`
// would shift.
procedure FMAMtxMultTria2T1(dest : PSingle; LineWidthDest : NativeInt; mt1 : PSingle; LineWidth1 : NativeInt; {$ifdef UNIX}unixMT2{$ELSE}mt2{$endif} : PSingle; {$ifdef UNIX}unixLineWidth2{$ELSE}LineWidth2{$endif} : NativeInt; width1, height1, width2, height2 : NativeInt);
begin
   ASMMtxMultTria2T1(dest, LineWidthDest, mt1, LineWidth1, 
     {$ifdef UNIX}unixMT2{$ELSE}mt2{$endif}, 
     {$ifdef UNIX}unixLineWidth2{$ELSE}LineWidth2{$endif}, width1, height1, width2, height2);
end;
procedure FMAMtxMultTria2T1StoreT1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt);
begin
   // the SSE kernel this would delegate to faults, see above
   raise ENotImplemented.Create('FMAMtxMultTria2T1StoreT1 is not implemented');
end;
procedure FMAMtxMultTria2TUpperUnit(dest : PSingle; LineWidthDest : NativeInt; mt1 : PSingle; LineWidth1 : NativeInt; {$ifdef UNIX}unixMT2{$ELSE}mt2{$endif} : PSingle; {$ifdef UNIX}unixLineWidth2{$ELSE}LineWidth2{$endif} : NativeInt; width1, height1, width2, height2 : NativeInt);
begin
   // no SSE twin to delegate to: its inner dot-product loop cannot terminate
   raise ENotImplemented.Create('FMAMtxMultTria2TUpperUnit is not implemented');
end;
procedure FMAMtxMultLowTria2T2Store1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; {$ifdef UNIX}unixWidth1{$ELSE}width1{$ENDIF}, {$ifdef UNIX}unixHeight1{$ELSE}height1{$ENDIF}, width2, height2 : NativeInt);
begin
   ASMMtxMultLowTria2T2Store1(mt1, LineWidth1, mt2, LineWidth2, 
     {$ifdef UNIX}unixWidth1{$ELSE}width1{$endif}, 
     {$ifdef UNIX}unixHeight1{$ELSE}height1{$endif}, width2, height2);
end;

{$ENDIF}

end.
