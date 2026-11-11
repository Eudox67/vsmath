// ###########################################################
// #### vsmath - vector single math
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the Apache License, Version 2.0 - see LICENSE.
// ###########################################################
unit AVXFFT;

interface

{$MODE OBJFPC}{$H+}
{$ASMMODE INTEL}

{$I VsMath_CPU.inc}

uses SysUtils, Math;

type
  TSingleDynArray = array of Single;

{$IFDEF CPUX64}

// Core execution entry point
// Data: Interleaved Complex [Re, Im, Re, Im...]
// BatchSize: Number of rows to process
// N: FFT Size (Complex pairs per row). Total floats per row = 2*N
procedure AVX_FFT_Execute(Data: PSingle; BatchSize, N: Integer; Inverse: Boolean);

// Helper: Vector * Scalar multiplication
procedure AVXVectorScale(Data: PSingle; Count: NativeInt; Factor: Single); assembler;

// Helper: Radix-2 Butterfly Kernel
procedure AVXButterflyPass(pA, pB: PSingle; pTwiddles: PSingle; Count: NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

// ----------------------------------------------------------------------
// Scale float array by constant factor using AVX
// ----------------------------------------------------------------------
procedure AVXVectorScale(Data: PSingle; Count: NativeInt; Factor: Single); assembler;
var
  iRBX: NativeInt;
asm
  // Load Factor into all elements of YMM0
  vbroadcastss ymm0, Factor

  mov rax, Data
  mov rcx, Count

  @@loop:
    cmp rcx, 32;
    jl @@scalar;

    // Unrolled 4x (128 floats per iter)
    vmovups ymm1, [rax];
    vmulps ymm1, ymm1, ymm0;
    vmovups [rax], ymm1;

    vmovups ymm2, [rax+32];
    vmulps ymm2, ymm2, ymm0;
    vmovups [rax+32], ymm2;

    vmovups ymm3, [rax+64];
    vmulps ymm3, ymm3, ymm0;
    vmovups [rax+64], ymm3;

    vmovups ymm4, [rax+96];
    vmulps ymm4, ymm4, ymm0;
    vmovups [rax+96], ymm4;

    add rax, 128;
    sub rcx, 32;
    jmp @@loop;

  @@scalar:
    test rcx, rcx;
    jz @@done;

    vmovss xmm1, [rax];
    vmulss xmm1, xmm1, xmm0;
    vmovss [rax], xmm1;
    add rax, 4;
    dec rcx;
    jmp @@scalar;

  @@done:
  vzeroupper;
end;

// ----------------------------------------------------------------------
// Core Butterfly Kernel (Radix-2)
// Processes 4 complex pairs (8 floats) per iteration.
// Operation: U = A, T = W*B; A = U+T, B = U-T
// ----------------------------------------------------------------------
procedure AVXButterflyPass(pA, pB: PSingle; pTwiddles: PSingle; Count: NativeInt); assembler;
var
  iRBX, iRSI, iRDI, iR12, iR13: NativeInt;
asm
  mov iRBX, rbx; mov iRSI, rsi; mov iRDI, rdi;
  mov iR12, r12; mov iR13, r13;

  // Move parameters to safe registers
  mov r10, pA;
  mov r11, pB;
  mov r12, pTwiddles;
  mov r13, Count;

  mov rsi, r13; // Number of butterflies

  @@loop:
    cmp rsi, 4;
    jl @@scalar;

    // 1. Load Data
    vmovups ymm0, [r10];        // U (4 complex numbers)
    vmovups ymm1, [r11];        // V (4 complex numbers)
    vmovups ymm2, [r12];        // W (Twiddle Factors)

    // 2. Complex Multiply: T = V * W
    vmovsldup ymm3, ymm1;
    vmulps ymm3, ymm3, ymm2;
    vmovshdup ymm4, ymm1;
    vshufps ymm5, ymm2, ymm2, $B1;
    vmulps ymm4, ymm4, ymm5;
    vaddsubps ymm5, ymm3, ymm4; // ymm5 = T

    // 3. Butterfly
    vaddps ymm6, ymm0, ymm5; // A' = U + T
    vsubps ymm7, ymm0, ymm5; // B' = U - T

    // 4. Store
    vmovups [r10], ymm6;
    vmovups [r11], ymm7;

    // Advance pointers (8 floats = 32 bytes)
    add r10, 32;
    add r11, 32;
    add r12, 32;
    sub rsi, 4;
    jmp @@loop

  @@scalar:
    test rsi, rsi;
    jz @@done;

    // vmovsd loads the whole complex pair (2 floats); vmovss would load the real
    // half alone and zero the imaginary half of U, V and W.
    vmovsd xmm0, [r10]; // Load 1 complex (2 floats)
    vmovsd xmm1, [r11];
    vmovsd xmm2, [r12];

    vmovshdup xmm4, xmm1;
    vmovsldup xmm3, xmm1;
    vshufps xmm5, xmm2, xmm2, $B1;
    vmulps xmm4, xmm4, xmm5;
    vmulps xmm3, xmm3, xmm2;
    vaddsubps xmm5, xmm3, xmm4; // T

    vaddps xmm6, xmm0, xmm5;
    vsubps xmm7, xmm0, xmm5;

    vmovlps [r10], xmm6;
    vmovlps [r11], xmm7;

    add r10, 8;
    add r11, 8;
    add r12, 8;
    dec rsi;
    jmp @@scalar;

  @@done:
  mov rbx, iRBX; mov rsi, iRSI; mov rdi, iRDI;
  mov r12, iR12; mov r13, iR13;
  vzeroupper;
end;

// ----------------------------------------------------------------------
// Pascal Helpers
// ----------------------------------------------------------------------

function ReverseBits(x, bits: Integer): Integer;
var k: Integer;
begin
  Result := 0;
  for k := 0 to bits - 1 do
  begin
    Result := (Result shl 1) or (x and 1);
    x := x shr 1;
  end;
end;

procedure ComputeTwiddles(Dst: PSingle; N: Integer; Inverse: Boolean);
var
  i: Integer;
  theta, invScale: Double;
begin
  if Inverse then invScale := 1.0 else invScale := -1.0;
  for i := 0 to (N div 2) - 1 do
  begin
    theta := invScale * 2.0 * Pi * i / N;
    Dst[i*2] := Cos(theta);
    Dst[i*2 + 1] := Sin(theta);
  end;
end;

// ----------------------------------------------------------------------
// FFT Driver
// ----------------------------------------------------------------------
procedure AVX_FFT_Execute(Data: PSingle; BatchSize, N: Integer; Inverse: Boolean);
var
  MainTwiddles, PackedTwiddles: TSingleDynArray;
  PermTable: array of Integer;
  i, j, b, k, LogN: Integer;
  BlockSize, Butterflies, Stride, Blocks: Integer;
  pDataRow, pTwidSrc, pTwidDst: PSingle;
  Dist: NativeInt;
  ScaleFactor, TempR, TempI: Single;
begin
  if N < 2 then Exit;

  // Radix-2 with a bit-reversal permutation: a size that is not a power of two
  // has no defined transform here, so it must fail instead of returning a
  // spectrum that is quietly wrong.
  if (N and (N - 1)) <> 0 then
    raise EArgumentException.CreateFmt(
      'AVX_FFT_Execute: FFT size %d is not a power of two', [N]);

  // 1. Initialization
  SetLength(MainTwiddles, N); // Size N floats (N/2 complex)
  ComputeTwiddles(@MainTwiddles[0], N, Inverse);

  LogN := Floor(Log2(N));
  SetLength(PermTable, N);
  for i := 0 to N - 1 do PermTable[i] := ReverseBits(i, LogN);

  // Allocate scratch buffer for AVX contiguous twiddles
  SetLength(PackedTwiddles, N);

  // 2. Process Batch
  pDataRow := Data;

  for b := 0 to BatchSize - 1 do
  begin
    // A. Bit Reversal Permutation
    for i := 0 to N - 1 do
    begin
      j := PermTable[i];
      if i < j then
      begin
        // Swap Complex[i] and Complex[j]
        TempR := pDataRow[i*2];
        TempI := pDataRow[i*2+1];
        pDataRow[i*2] := pDataRow[j*2];
        pDataRow[i*2+1] := pDataRow[j*2+1];
        pDataRow[j*2] := TempR;
        pDataRow[j*2+1] := TempI;
      end;
    end;

    // B. Butterfly Stages (Cooley-Tukey)
    BlockSize := 2;
    while BlockSize <= N do
    begin
      Butterflies := BlockSize div 2;
      Stride := N div BlockSize;
      Blocks := N div BlockSize;
      Dist := Butterflies; // Distance in Complex elements

      // Prepare Packed Twiddles for this stage (Linearize stride)
      // We need 'Butterflies' amount of twiddles.
      // Src Index: k * Stride * 2 (floats)
      pTwidDst := @PackedTwiddles[0];
      pTwidSrc := @MainTwiddles[0];

      for k := 0 to Butterflies - 1 do
      begin
        pTwidDst[0] := pTwidSrc[(k * Stride) * 2];
        pTwidDst[1] := pTwidSrc[(k * Stride) * 2 + 1];
        Inc(pTwidDst, 2);
      end;

      // Apply Kernel to all blocks
      for k := 0 to Blocks - 1 do
      begin
        AVXButterflyPass(
           pDataRow + (k * BlockSize * 2),             // Upper Wing
           pDataRow + (k * BlockSize * 2) + (Dist * 2), // Lower Wing
           @PackedTwiddles[0],                         // Linear Twiddles
           Butterflies
        );
      end;

      BlockSize := BlockSize * 2;
    end;

    // C. Inverse Scaling
    if Inverse then
    begin
      ScaleFactor := 1.0 / N;
      AVXVectorScale(pDataRow, N * 2, ScaleFactor);
    end;

    Inc(pDataRow, N * 2);
  end;
end;

{$ENDIF}

end.
