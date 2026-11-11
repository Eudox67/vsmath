// ###########################################################
// #### vsmath - vector single math
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the Apache License, Version 2.0 - see LICENSE.
// ###########################################################
// FPCUnit tests for the x86_64 SIMD kernels.
//
// Every test compares a SIMD kernel against a plain Pascal reference over data
// that is exactly representable in Single (multiples of 1/4), so a pass means the
// kernel computes the same value rather than merely "close enough".
//
// On a target without the kernels the unit registers no tests.
unit TestVsMath;

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

interface

uses
  fpcunit, testregistry;

{$IFDEF CPUX64}

type
  TvsmathCoreTests = class(TTestCase)
  published
    procedure TestVecMinAligned;
    procedure TestVecMaxUnAligned;
    procedure TestMatrixMaxAlignedEvenW;
    procedure TestMatrixMinAlignedEvenW;
    procedure TestMatrixAbsMaxAlignedEvenW;
    procedure TestMatrixAbsMinAlignedEvenW;
    procedure TestMatrixAbsAlignedEvenW;
    procedure TestAddScaleAlignedEvenW;
    procedure TestAddScaleUnAlignedEvenW;
    procedure TestScaleAddAlignedEvenW;
    procedure TestElemAddAlignedEvenW;
    procedure TestMeanRowAlignedEvenW;
    procedure TestVarRowAlignedEvenW;
    procedure TestVecDotMultAligned;
    procedure TestConstSingleArr;
    procedure TestRotateAligned;
    procedure TestRotateOddN;
    procedure TestMatrixSumRowKernels;
    procedure TestMatrixNormalizeRowKernels;
    procedure TestMatrixNormalizeColumnKernels;
    procedure TestMtxVecMultEvenAlignedVAligned;
    procedure TestMtxVecMultTDestVecAlias;
    procedure TestRank1SeqAligned;
  end;

{$ENDIF}

implementation

uses
  SysUtils, Math, MatrixConstSingle,
  ASMMatrixAbsOperationsSinglex64,
  ASMMatrixMinMaxOperationsSinglex64,
  ASMMatrixScaleOperationsSinglex64,
  ASMMatrixMeanOperationsSinglex64,
  ASMMatrixVectorMultOperationsSinglex64,
  ASMMatrixRotationsSinglex64,
  ASMMatrixSumOperationsSinglex64,
  ASMMatrixNormOperationsSinglex64;

{$IFDEF CPUX64}

const
  cEps = 1e-3;

{ Allocate ACount singles, 64 byte aligned. ARaw must be released with FreeMem. }
function AllocSingles(ACount: NativeInt; out ARaw: Pointer): PSingle;
begin
  GetMem(ARaw, ACount * SizeOf(Single) + 64);
  Result := PSingle((NativeUInt(ARaw) + 63) and not NativeUInt(63));
  FillChar(Result^, ACount * SizeOf(Single), 0);
end;

{ Deterministic test data in [-2.75 .. 2.75]: all values are multiples of 1/4,
  so every partial sum stays exactly representable in Single. }
procedure FillDet(ADest: PSingle; ACount: NativeInt; AOffset: NativeInt = 0);
var
  i: NativeInt;
begin
  for i := 0 to ACount - 1 do
    ADest[i] := Single(((i + AOffset) mod 23) - 11) * 0.25;
end;

procedure RefVecMin(ADest, ASrc: PSingle; ACount: NativeInt);
var
  i: NativeInt;
begin
  for i := 0 to ACount - 1 do
    if ASrc[i] < ADest[i] then
      ADest[i] := ASrc[i];
end;

procedure RefVecMax(ADest, ASrc: PSingle; ACount: NativeInt);
var
  i: NativeInt;
begin
  for i := 0 to ACount - 1 do
    if ASrc[i] > ADest[i] then
      ADest[i] := ASrc[i];
end;

function RefMatrixExtremum(ASrc: PSingle; AWidth, AHeight, AStride: NativeInt;
  AAbs, AMax: Boolean): Single;
var
  x, y: NativeInt;
  v: Single;
begin
  Result := 0;
  for y := 0 to AHeight - 1 do
    for x := 0 to AWidth - 1 do
    begin
      v := PSingle(PByte(ASrc) + y * AStride + x * SizeOf(Single))^;
      if AAbs then
        v := Abs(v);
      if (x = 0) and (y = 0) then
        Result := v
      else if AMax then
      begin
        if v > Result then
          Result := v;
      end
      else if v < Result then
        Result := v;
    end;
end;
procedure RefMeanRow(ADest: PSingle; const ADestLineWidth: NativeInt;
  ASrc: PSingle; AWidth, AHeight, AStride: NativeInt);
var
  x, y: NativeInt;
  Sum: Single;
begin
  for y := 0 to AHeight - 1 do
  begin
    Sum := 0;
    for x := 0 to AWidth - 1 do
      Sum := Sum + PSingle(PByte(ASrc) + y * AStride + x * SizeOf(Single))^;
    PSingle(PByte(ADest) + y * ADestLineWidth)^ := Sum / AWidth;
  end;
end;

procedure RefVarRow(ADest: PSingle; const ADestLineWidth: NativeInt;
  ASrc: PSingle; AWidth, AHeight, AStride: NativeInt; AUnbiased: Boolean);
var
  x, y: NativeInt;
  Sum, Mean, Acc, v, Divisor: Single;
begin
  for y := 0 to AHeight - 1 do
  begin
    Sum := 0;
    for x := 0 to AWidth - 1 do
      Sum := Sum + PSingle(PByte(ASrc) + y * AStride + x * SizeOf(Single))^;
    Mean := Sum / AWidth;
    Acc := 0;
    for x := 0 to AWidth - 1 do
    begin
      v := PSingle(PByte(ASrc) + y * AStride + x * SizeOf(Single))^ - Mean;
      Acc := Acc + v * v;
    end;
    if AUnbiased then
      Divisor := AWidth - 1
    else
      Divisor := AWidth;
    PSingle(PByte(ADest) + y * ADestLineWidth)^ := Acc / Divisor;
  end;
end;

function RefDot(AX, AY: PSingle; ACount: NativeInt): Single;
var
  i: NativeInt;
begin
  Result := 0;
  for i := 0 to ACount - 1 do
    Result := Result + AX[i] * AY[i];
end;
procedure TvsmathCoreTests.TestVecMinAligned;
var
  RawSrc, RawDest, RawRef: Pointer;
  Src, Dest, Ref: PSingle;
  i: NativeInt;
begin
  Src := AllocSingles(64, RawSrc);
  Dest := AllocSingles(64, RawDest);
  Ref := AllocSingles(64, RawRef);
  try
    { ASMVecMinAligned reduces in place: Dest[i] := Min(Dest[i], Src[i]) }
    FillDet(Src, 64);
    FillDet(Dest, 64, 5);
    FillDet(Ref, 64, 5);
    RefVecMin(Ref, Src, 64);
    ASMVecMinAligned(Dest, Src, 64);
    for i := 0 to 63 do
      AssertEquals('ASMVecMinAligned lane ' + IntToStr(i), Ref[i], Dest[i], cEps);
  finally
    FreeMem(RawSrc); FreeMem(RawDest); FreeMem(RawRef);
  end;
end;

procedure TvsmathCoreTests.TestVecMaxUnAligned;
var
  RawSrc, RawDest, RawRef: Pointer;
  Src, Dest, Ref: PSingle;
  i: NativeInt;
begin
  { one element of padding makes both pointers unaligned }
  Src := PSingle(PByte(AllocSingles(65, RawSrc)) + SizeOf(Single));
  Dest := PSingle(PByte(AllocSingles(65, RawDest)) + SizeOf(Single));
  Ref := PSingle(PByte(AllocSingles(65, RawRef)) + SizeOf(Single));
  try
    { ASMVecMaxUnAligned reduces in place: Dest[i] := Max(Dest[i], Src[i]) }
    FillDet(Src, 64, 7);
    FillDet(Dest, 64, 3);
    FillDet(Ref, 64, 3);
    RefVecMax(Ref, Src, 64);
    ASMVecMaxUnAligned(Dest, Src, 64);
    for i := 0 to 63 do
      AssertEquals('ASMVecMaxUnAligned lane ' + IntToStr(i), Ref[i], Dest[i], cEps);
  finally
    FreeMem(RawSrc); FreeMem(RawDest); FreeMem(RawRef);
  end;
end;

procedure TvsmathCoreTests.TestMatrixMaxAlignedEvenW;
var
  RawSrc: Pointer;
  Src: PSingle;
  W, H, Stride: NativeInt;
  Expected, Actual: Single;
begin
  W := 64;
  H := 16;
  Stride := W * SizeOf(Single);
  Src := AllocSingles(W * H, RawSrc);
  try
    FillDet(Src, W * H);
    Expected := RefMatrixExtremum(Src, W, H, Stride, False, True);
    Actual := ASMMatrixMaxAlignedEvenW(Src, W, H, Stride);
    AssertEquals('ASMMatrixMaxAlignedEvenW', Expected, Actual, cEps);
  finally
    FreeMem(RawSrc);
  end;
end;

procedure TvsmathCoreTests.TestMatrixMinAlignedEvenW;
var
  RawSrc: Pointer;
  Src: PSingle;
  W, H, Stride: NativeInt;
  Expected, Actual: Single;
begin
  W := 64;
  H := 16;
  Stride := W * SizeOf(Single);
  Src := AllocSingles(W * H, RawSrc);
  try
    FillDet(Src, W * H, 5);
    Expected := RefMatrixExtremum(Src, W, H, Stride, False, False);
    Actual := ASMMatrixMinAlignedEvenW(Src, W, H, Stride);
    AssertEquals('ASMMatrixMinAlignedEvenW', Expected, Actual, cEps);
  finally
    FreeMem(RawSrc);
  end;
end;

{ Magnitudes 1.0 .. 6.5, all negative: a plain min/max would return the
  smallest / largest magnitude, so abs-min and abs-max are clearly distinct
  from their non-abs counterparts. }
procedure FillNegativeRamp(ADest: PSingle; ACount: NativeInt);
var
  i: NativeInt;
begin
  for i := 0 to ACount - 1 do
    ADest[i] := -(1.0 + Single(i mod 23) * 0.25);
end;

procedure TvsmathCoreTests.TestMatrixAbsMaxAlignedEvenW;
var
  RawSrc: Pointer;
  Src: PSingle;
  W, H, Stride: NativeInt;
  Expected, Actual: Single;
begin
  W := 64;
  H := 16;
  Stride := W * SizeOf(Single);
  Src := AllocSingles(W * H, RawSrc);
  try
    FillNegativeRamp(Src, W * H);
    Expected := 6.5;
    Actual := ASMMatrixAbsMaxAlignedEvenW(Src, W, H, Stride);
    AssertEquals('ASMMatrixAbsMaxAlignedEvenW', Expected, Abs(Actual), cEps);
  finally
    FreeMem(RawSrc);
  end;
end;

procedure TvsmathCoreTests.TestMatrixAbsMinAlignedEvenW;
var
  RawSrc: Pointer;
  Src: PSingle;
  W, H, Stride: NativeInt;
  Expected, Actual: Single;
begin
  W := 64;
  H := 16;
  Stride := W * SizeOf(Single);
  Src := AllocSingles(W * H, RawSrc);
  try
    FillNegativeRamp(Src, W * H);
    Expected := 1.0;
    Actual := ASMMatrixAbsMinAlignedEvenW(Src, W, H, Stride);
    AssertEquals('ASMMatrixAbsMinAlignedEvenW', Expected, Abs(Actual), cEps);
  finally
    FreeMem(RawSrc);
  end;
end;

{ ASMMatrixAbs* masks every lane with $7FFFFFFF. The mask used to be a pair of
  Int64 $7FFFFFFFFFFFFFFF, which only cleared the sign of every second single
  and zeroed the rest. }
procedure TvsmathCoreTests.TestMatrixAbsAlignedEvenW;
var
  RawDest: Pointer;
  Dest: PSingle;
  W, H, Stride, x, y: NativeInt;
begin
  W := 64;
  H := 8;
  Stride := W * SizeOf(Single);
  Dest := AllocSingles(W * H, RawDest);
  try
    for y := 0 to H - 1 do
      for x := 0 to W - 1 do
        Dest[y * W + x] := -Single(x + y) * 0.25;
    ASMMatrixAbsAlignedEvenW(Dest, Stride, W, H);
    for y := 0 to H - 1 do
      for x := 0 to W - 1 do
        AssertEquals('Abs x=' + IntToStr(x) + ' y=' + IntToStr(y),
          Single(x + y) * 0.25, Dest[y * W + x], 0);
  finally
    FreeMem(RawDest);
  end;
end;

procedure TvsmathCoreTests.TestAddScaleAlignedEvenW;
var
  RawDest: Pointer;
  Dest: PSingle;
  W, H, Stride, x: NativeInt;
  dOffset, Scale: Single;
begin
  W := 64;
  H := 8;
  Stride := W * SizeOf(Single);
  Dest := AllocSingles(W * H, RawDest);
  try
    FillDet(Dest, W * H);
    dOffset := 1.5;
    Scale := -2.0;
    { AddScale semantics: dest := (dest + dOffset) * Scale }
    ASMMatrixAddScaleAlignedEvenW(Dest, Stride, W, H, dOffset, Scale);
    for x := 0 to W - 1 do
      AssertEquals('AddScale col ' + IntToStr(x),
        (Single((x mod 23) - 11) * 0.25 + dOffset) * Scale, Dest[x], cEps);
  finally
    FreeMem(RawDest);
  end;
end;

procedure TvsmathCoreTests.TestAddScaleUnAlignedEvenW;
var
  RawDest: Pointer;
  Dest: PSingle;
  W, H, Stride, x: NativeInt;
  dOffset, Scale: Single;
begin
  W := 64;
  H := 4;
  Stride := W * SizeOf(Single);
  Dest := PSingle(PByte(AllocSingles(W * H + 1, RawDest)) + SizeOf(Single));
  try
    FillDet(Dest, W * H, 11);
    dOffset := -0.25;
    Scale := 4.0;
    ASMMatrixAddScaleUnAlignedEvenW(Dest, Stride, W, H, dOffset, Scale);
    for x := 0 to W - 1 do
      AssertEquals('AddScale unaligned col ' + IntToStr(x),
        (Single(((x + 11) mod 23) - 11) * 0.25 + dOffset) * Scale, Dest[x], cEps);
  finally
    FreeMem(RawDest);
  end;
end;

procedure TvsmathCoreTests.TestScaleAddAlignedEvenW;
var
  RawDest: Pointer;
  Dest: PSingle;
  W, H, Stride, x: NativeInt;
  dOffset, Scale: Single;
begin
  W := 64;
  H := 8;
  Stride := W * SizeOf(Single);
  Dest := AllocSingles(W * H, RawDest);
  try
    FillDet(Dest, W * H, 2);
    dOffset := 3.0;
    Scale := 0.5;
    { ScaleAdd semantics: dest := dest * Scale + dOffset }
    ASMMatrixScaleAddAlignedEvenW(Dest, Stride, W, H, dOffset, Scale);
    for x := 0 to W - 1 do
      AssertEquals('ScaleAdd col ' + IntToStr(x),
        Single(((x + 2) mod 23) - 11) * 0.25 * Scale + dOffset, Dest[x], cEps);
  finally
    FreeMem(RawDest);
  end;
end;

procedure TvsmathCoreTests.TestElemAddAlignedEvenW;
var
  RawDest: Pointer;
  Dest: PSingle;
  W, H, Stride, x: NativeInt;
  dOffset: Single;
begin
  W := 64;
  H := 8;
  Stride := W * SizeOf(Single);
  Dest := AllocSingles(W * H, RawDest);
  try
    FillDet(Dest, W * H, 1);
    dOffset := 0.75;
    ASMMatrixElemAddAlignedEvenW(Dest, Stride, W, H, dOffset);
    for x := 0 to W - 1 do
      AssertEquals('ElemAdd col ' + IntToStr(x),
        Single(((x + 1) mod 23) - 11) * 0.25 + dOffset, Dest[x], cEps);
  finally
    FreeMem(RawDest);
  end;
end;

procedure TvsmathCoreTests.TestMeanRowAlignedEvenW;
var
  RawSrc: Pointer;
  RawDest: Pointer;
  RawRef: Pointer;
  Src, Dest, Ref: PSingle;
  W, H, Stride, DestStride, y: NativeInt;
begin
  W := 64;
  H := 8;
  Stride := W * SizeOf(Single);
  DestStride := SizeOf(Single);
  Src := AllocSingles(W * H, RawSrc);
  Dest := AllocSingles(H, RawDest);
  Ref := AllocSingles(H, RawRef);
  try
    FillDet(Src, W * H);
    RefMeanRow(Ref, DestStride, Src, W, H, Stride);
    ASMMatrixMeanRowAlignedEvenW(Dest, DestStride, Src, Stride, W, H);
    for y := 0 to H - 1 do
      AssertEquals('MeanRow row ' + IntToStr(y), Ref[y], Dest[y], cEps);
  finally
    FreeMem(RawSrc); FreeMem(RawDest); FreeMem(RawRef);
  end;
end;

procedure TvsmathCoreTests.TestVarRowAlignedEvenW;
var
  RawSrc: Pointer;
  RawDest: Pointer;
  RawRef: Pointer;
  Src, Dest, Ref: PSingle;
  W, H, Stride, DestStride, y: NativeInt;
begin
  W := 64;
  H := 8;
  Stride := W * SizeOf(Single);
  DestStride := SizeOf(Single);
  Src := AllocSingles(W * H, RawSrc);
  Dest := AllocSingles(H, RawDest);
  Ref := AllocSingles(H, RawRef);
  try
    FillDet(Src, W * H, 4);
    RefVarRow(Ref, DestStride, Src, W, H, Stride, True);
    ASMMatrixVarRowAlignedEvenW(Dest, DestStride, Src, Stride, W, H, True);
    for y := 0 to H - 1 do
      AssertEquals('VarRow unbiased row ' + IntToStr(y), Ref[y], Dest[y], cEps);

    RefVarRow(Ref, DestStride, Src, W, H, Stride, False);
    ASMMatrixVarRowAlignedEvenW(Dest, DestStride, Src, Stride, W, H, False);
    for y := 0 to H - 1 do
      AssertEquals('VarRow biased row ' + IntToStr(y), Ref[y], Dest[y], cEps);
  finally
    FreeMem(RawSrc); FreeMem(RawDest); FreeMem(RawRef);
  end;
end;

procedure TvsmathCoreTests.TestVecDotMultAligned;
var
  RawX: Pointer;
  RawY: Pointer;
  X, Y: PSingle;
  N: NativeInt;
  Expected, Actual: Single;
begin
  N := 64;
  X := AllocSingles(N, RawX);
  Y := AllocSingles(N, RawY);
  try
    FillDet(X, N);
    FillDet(Y, N, 6);
    Expected := RefDot(X, Y, N);
    Actual := ASMMatrixVecDotMultAligned(X, Y, N);
    AssertEquals('ASMMatrixVecDotMultAligned', Expected, Actual, cEps);
  finally
    FreeMem(RawX); FreeMem(RawY);
  end;
end;

procedure TvsmathCoreTests.TestConstSingleArr;
var
  Buf: array[0..7] of Single;
  Arr: PConstSingleArr;
begin
  FillChar(Buf, SizeOf(Buf), 0);
  Arr := PConstSingleArr(@Buf[0]);
  Arr^[2] := 1.5;
  { if TConstSingleArr were declared over double, index 2 would land 16 bytes
    in - outside Buf - and the write above would corrupt the stack }
  AssertEquals('PConstSingleArr indexes 32 bit elements', 1.5, Buf[2], cEps);
  AssertEquals('TConstSingleArr element size', 4.0, SizeOf(Arr^[0]) * 1.0, cEps);

  { The kernel constants used to be `double` and `Int64` masks, straight from
    mrMath: a 32 bit load of `-1` then returned the low half of the bit pattern
    (0.0, not -1.0), and an Int64 abs mask cleared the sign bit of every second
    Single lane. Each of them is one 32 bit element per lane now, which is what
    the kernels' `movss`/`movups`/`vbroadcastss` loads assume. }
  AssertEquals('cOne is 4 bytes wide', 4.0, SizeOf(cOne) * 1.0, 0);
  AssertEquals('cOne holds 1.0', 1.0, PSingle(@cOne)^, 0);
  AssertEquals('cMinusOne holds -1.0', -1.0, PSingle(@cMinusOne)^, 0);
  AssertEquals('cOnes is 4 lanes of 4 bytes', 16.0, SizeOf(cOnes) * 1.0, 0);
  AssertEquals('cOnes lane 3', 1.0, cOnes[3], 0);
  AssertEquals('cDivBy2 lane 3', 0.5, cDivBy2[3], 0);
  AssertEquals('cAbsMask lane 3', Int64($7FFFFFFF), Int64(cAbsMask[3]));
  AssertEquals('cAbsMask8 lane 7', Int64($7FFFFFFF), Int64(cAbsMask8[7]));
  AssertEquals('cAbsMask8 covers 8 lanes', 32.0, SizeOf(cAbsMask8) * 1.0, 0);
  AssertEquals('cMulM1Bits lane 0', Int64($80000000), Int64(cMulM1Bits[0]));
  AssertEquals('cMulM1Bits lane 1', Int64(0), Int64(cMulM1Bits[1]));
  AssertEquals('cNegMaxSingle is FLT_MAX negated',
    Double(Single(-3.4028234e38)), Double(cNegMaxSingle), 0);
  AssertEquals('cMaxSingles lane 2', Double(Single(3.4028234e38)),
    Double(cMaxSingles[2]), 0);
  AssertEquals('cMinusOne is a Single', 4.0, SizeOf(cMinusOne) * 1.0, 0);
end;

// ---------------------------------------------------------------------------
// rotations
// ---------------------------------------------------------------------------
// ASMMatrixRotate turns X/Y into c*x + s*y and -s*x + c*y. c = 1/4 and s = 1/2
// keep both exact in Single for the small integers used here.
const
  cRotC = 0.25;
  cRotS = 0.5;

procedure FillRotate(AX, AY: PSingle; ACount, ACapacity: NativeInt);
var
  i: NativeInt;
begin
  for i := 0 to ACount - 1 do
  begin
    AX[i] := Single(i);
    AY[i] := Single(ACapacity - i);
  end;
end;

function RefRotX(AIndex, ACapacity: NativeInt): Single;
begin
  Result := cRotC * Single(AIndex) + cRotS * Single(ACapacity - AIndex);
end;

function RefRotY(AIndex, ACapacity: NativeInt): Single;
begin
  Result := -cRotS * Single(AIndex) + cRotC * Single(ACapacity - AIndex);
end;

procedure TvsmathCoreTests.TestRotateAligned;
const
  cN = 32; { eight full 16 byte blocks, no tail }
var
  RawX, RawY: Pointer;
  X, Y: PSingle;
  i: NativeInt;
begin
  X := AllocSingles(cN, RawX);
  Y := AllocSingles(cN, RawY);
  try
    FillRotate(X, Y, cN, cN);
    ASMMatrixRotate(cN, X, SizeOf(Single), Y, SizeOf(Single), cRotC, cRotS);
    for i := 0 to cN - 1 do
    begin
      AssertEquals('Rotate X[' + IntToStr(i) + ']', RefRotX(i, cN), X[i], cEps);
      AssertEquals('Rotate Y[' + IntToStr(i) + ']', RefRotY(i, cN), Y[i], cEps);
    end;
  finally
    FreeMem(RawX);
    FreeMem(RawY);
  end;
end;

{ N mod 4 elements are handled one at a time; the sentinels after the live data
  catch a kernel that walks past X[N-1] / Y[N-1]. }
procedure TvsmathCoreTests.TestRotateOddN;
const
  cSizes: array[0..2] of NativeInt = (1, 3, 5);
  cCapacity = 8;
  cSentinel = -99;
var
  RawX, RawY: Pointer;
  X, Y: PSingle;
  i, n: NativeInt;
begin
  for n in cSizes do
  begin
    X := AllocSingles(cCapacity, RawX);
    Y := AllocSingles(cCapacity, RawY);
    try
      FillRotate(X, Y, n, cCapacity);
      for i := n to cCapacity - 1 do
      begin
        X[i] := cSentinel;
        Y[i] := cSentinel;
      end;
      ASMMatrixRotate(n, X, SizeOf(Single), Y, SizeOf(Single), cRotC, cRotS);
      for i := 0 to n - 1 do
      begin
        AssertEquals('Rotate N=' + IntToStr(n) + ' X[' + IntToStr(i) + ']',
          RefRotX(i, cCapacity), X[i], cEps);
        AssertEquals('Rotate N=' + IntToStr(n) + ' Y[' + IntToStr(i) + ']',
          RefRotY(i, cCapacity), Y[i], cEps);
      end;
      for i := n to cCapacity - 1 do
      begin
        AssertEquals('Rotate N=' + IntToStr(n) + ' overran X[' + IntToStr(i) + ']',
          Single(cSentinel), X[i], 0);
        AssertEquals('Rotate N=' + IntToStr(n) + ' overran Y[' + IntToStr(i) + ']',
          Single(cSentinel), Y[i], 0);
      end;
    finally
      FreeMem(RawX);
      FreeMem(RawY);
    end;
  end;
end;

{ ---- kernels that used to be empty assembler stubs ---------------------- }
{ The four ASMMatrixSumRow* and the eight ASMMatrixNormalize* entry points had
  `asm end;` bodies, so a caller got its destination buffer back untouched and
  no error at all. Every test below zeroes the destination first (a zeroed
  buffer cannot pass, the test data is non-zero) and compares against a Pascal
  reference, so a silent no-op fails on the first element. }

function RefRowSum(ASrc: PSingle; AStrideSingles, AY, AWidth: NativeInt): Single;
var
  x: NativeInt;
begin
  Result := 0;
  for x := 0 to AWidth - 1 do
    Result := Result + ASrc[AY * AStrideSingles + x];
end;

{ dest = src / ||row|| (or / ||column||), element by element. }
function RefNormElement(ASrc: PSingle; AStrideSingles, AWidth, AHeight,
  AX, AY: NativeInt; AColumns: Boolean): Single;
var
  i: NativeInt;
  Sum, v: Single;
begin
  Sum := 0;
  if AColumns then
    for i := 0 to AHeight - 1 do
    begin
      v := ASrc[i * AStrideSingles + AX];
      Sum := Sum + v * v;
    end
  else
    for i := 0 to AWidth - 1 do
    begin
      v := ASrc[AY * AStrideSingles + i];
      Sum := Sum + v * v;
    end;
  Result := ASrc[AY * AStrideSingles + AX] / Sqrt(Sum);
end;

procedure TvsmathCoreTests.TestMatrixSumRowKernels;
const
  cWidths: array[0..1] of NativeInt = (8, 7);   { EvenW and OddW }
  cHeight = 4;
var
  RawSrc, RawDest: Pointer;
  Src, Dest: PSingle;
  W, y, Stride: NativeInt;
  v: Integer;
begin
  for W in cWidths do
  begin
    Stride := W * SizeOf(Single);
    Src := AllocSingles(W * cHeight, RawSrc);
    Dest := AllocSingles(cHeight, RawDest);
    try
      FillDet(Src, W * cHeight, 3);
      for v := 0 to 1 do
      begin
        { zeroed, so an untouched destination cannot pass by accident }
        FillChar(Dest^, cHeight * SizeOf(Single), 0);
        if (W and 3) = 0 then
        begin
          if v = 0 then
            ASMMatrixSumRowAlignedEvenW(Dest, SizeOf(Single), Src, Stride, W, cHeight)
          else
            ASMMatrixSumRowUnAlignedEvenW(Dest, SizeOf(Single), Src, Stride, W, cHeight);
        end
        else
        begin
          if v = 0 then
            ASMMatrixSumRowAlignedOddW(Dest, SizeOf(Single), Src, Stride, W, cHeight)
          else
            ASMMatrixSumRowUnAlignedOddW(Dest, SizeOf(Single), Src, Stride, W, cHeight);
        end;
        for y := 0 to cHeight - 1 do
          AssertEquals('SumRow W=' + IntToStr(W) + ' v=' + IntToStr(v) +
            ' y=' + IntToStr(y), RefRowSum(Src, W, y, W), Dest[y], cEps);
      end;
    finally
      FreeMem(RawSrc);
      FreeMem(RawDest);
    end;
  end;
end;

procedure TvsmathCoreTests.TestMatrixNormalizeRowKernels;
const
  cWidths: array[0..1] of NativeInt = (8, 7);   { EvenW and OddW }
  cHeight = 4;
var
  RawSrc, RawDest: Pointer;
  Src, Dest: PSingle;
  W, x, y, Stride: NativeInt;
  v: Integer;
begin
  for W in cWidths do
  begin
    Stride := W * SizeOf(Single);
    Src := AllocSingles(W * cHeight, RawSrc);
    Dest := AllocSingles(W * cHeight, RawDest);
    try
      FillDet(Src, W * cHeight, 7);
      for v := 0 to 1 do
      begin
        FillChar(Dest^, W * cHeight * SizeOf(Single), 0);
        if (W and 3) = 0 then
        begin
          if v = 0 then
            ASMMatrixNormalizeRowAlignedEvenW(Dest, Stride, Src, Stride, W, cHeight)
          else
            ASMMatrixNormalizeRowUnAlignedEvenW(Dest, Stride, Src, Stride, W, cHeight);
        end
        else
        begin
          if v = 0 then
            ASMMatrixNormalizeRowAlignedOddW(Dest, Stride, Src, Stride, W, cHeight)
          else
            ASMMatrixNormalizeRowUnAlignedOddW(Dest, Stride, Src, Stride, W, cHeight);
        end;
        for y := 0 to cHeight - 1 do
          for x := 0 to W - 1 do
            AssertEquals('NormalizeRow W=' + IntToStr(W) + ' v=' + IntToStr(v) +
              ' [' + IntToStr(x) + ',' + IntToStr(y) + ']',
              RefNormElement(Src, W, W, cHeight, x, y, False), Dest[y * W + x], cEps);
      end;
    finally
      FreeMem(RawSrc);
      FreeMem(RawDest);
    end;
  end;
end;

procedure TvsmathCoreTests.TestMatrixNormalizeColumnKernels;
const
  cWidths: array[0..1] of NativeInt = (8, 7);   { EvenW and OddW }
  cHeight = 4;
var
  RawSrc, RawDest: Pointer;
  Src, Dest: PSingle;
  W, x, y, Stride: NativeInt;
  v: Integer;
begin
  for W in cWidths do
  begin
    Stride := W * SizeOf(Single);
    Src := AllocSingles(W * cHeight, RawSrc);
    Dest := AllocSingles(W * cHeight, RawDest);
    try
      FillDet(Src, W * cHeight, 5);
      for v := 0 to 1 do
      begin
        FillChar(Dest^, W * cHeight * SizeOf(Single), 0);
        if (W and 3) = 0 then
        begin
          if v = 0 then
            ASMMatrixNormalizeColumnAlignedEvenW(Dest, Stride, Src, Stride, W, cHeight)
          else
            ASMMatrixNormalizeColumnUnAlignedEvenW(Dest, Stride, Src, Stride, W, cHeight);
        end
        else
        begin
          if v = 0 then
            ASMMatrixNormalizeColumnAlignedOddW(Dest, Stride, Src, Stride, W, cHeight)
          else
            ASMMatrixNormalizeColumnUnAlignedOddW(Dest, Stride, Src, Stride, W, cHeight);
        end;
        for y := 0 to cHeight - 1 do
          for x := 0 to W - 1 do
            AssertEquals('NormalizeColumn W=' + IntToStr(W) + ' v=' + IntToStr(v) +
              ' [' + IntToStr(x) + ',' + IntToStr(y) + ']',
              RefNormElement(Src, W, W, cHeight, x, y, True), Dest[y * W + x], cEps);
      end;
    finally
      FreeMem(RawSrc);
      FreeMem(RawDest);
    end;
  end;
end;

{ ASMMatrixVectMultEvenAlignedVAligned computes the row oriented product

    dest[row] := beta*dest[row] + alpha * sum(col, mt[row][col] * v[col])

  so dest holds `height` elements - the same contract as ASMMatrixVectMult, not
  the transposed one. Its preconditions are the ones the dispatch layer honours:
  mt is 16 byte aligned and its line width is a multiple of 16 bytes, v is 16
  byte aligned and contiguous (LineWidthV is ignored - the kernel steps a whole
  lane group at a time), and width is a multiple of 4. The dest line width is
  free, because the result is stored with a scalar move per row. }
procedure TvsmathCoreTests.TestMtxVecMultEvenAlignedVAligned;
const
  cWidths: array[0..2] of NativeInt = (4, 8, 16);
  cPads: array[0..1] of NativeInt = (0, 16);
var
  wi, pi, y, x: Integer;
  W, H, Pitch, LineWidthMt: NativeInt;
  RawMt, RawV, RawDest: Pointer;
  Mt, V, Dest: PSingle;
  Acc: Single;
  Expected: array of Single;
begin
  for wi := 0 to High(cWidths) do
    for pi := 0 to High(cPads) do
      for H := 1 to 4 do
      begin
        W := cWidths[wi];
        LineWidthMt := W * SizeOf(Single) + cPads[pi];
        Pitch := LineWidthMt div SizeOf(Single);
        Mt := AllocSingles(Pitch * H, RawMt);
        V := AllocSingles(W + 4, RawV);
        Dest := AllocSingles(H + 4, RawDest);
        try
          FillDet(Mt, Pitch * H);
          FillDet(V, W, 7);
          FillDet(Dest, H, 3);

          SetLength(Expected, H);
          for y := 0 to H - 1 do
          begin
            Acc := 0;
            for x := 0 to W - 1 do
              Acc := Acc + Mt[y * Pitch + x] * V[x];
            Expected[y] := 0.5 * Acc + 0.25 * Dest[y];
          end;

          ASMMatrixVectMultEvenAlignedVAligned(Dest, SizeOf(Single), Mt, V,
            LineWidthMt, SizeOf(Single), W, H, 0.5, 0.25);

          for y := 0 to H - 1 do
            AssertEquals('VectMultEvenAlignedVAligned W=' + IntToStr(W) +
              ' pad=' + IntToStr(cPads[pi]) + ' h=' + IntToStr(H) +
              ' [' + IntToStr(y) + ']', Expected[y], Dest[y]);
        finally
          FreeMem(RawMt); FreeMem(RawV); FreeMem(RawDest);
          Expected := nil;
        end;
      end;
end;

{ ASMMatrixVectMultTDestVec is the legacy name of ASMMatrixVectMultT:

    dest[col] := beta*dest[col] + alpha * sum(row, mt[row][col] * v[row])

  so dest holds `width` elements. The test compares the alias with the kernel it
  forwards to and with the reference, so an alias that drops, swaps or shifts an
  argument register cannot pass. }
procedure TvsmathCoreTests.TestMtxVecMultTDestVecAlias;
var
  W, H, LineWidthMt, LineWidthV, x, y: NativeInt;
  RawMt, RawV, RawAlias, RawTwin: Pointer;
  Mt, V, AliasRes, Twin: PSingle;
  Acc: Single;
  Expected: array of Single;
begin
  LineWidthV := SizeOf(Single);
  for H := 1 to 3 do
    for W := 1 to 9 do
    begin
      LineWidthMt := W * SizeOf(Single) + 8;   { padded rows, still a legal stride }
      Mt := AllocSingles((LineWidthMt div SizeOf(Single)) * H, RawMt);
      V := AllocSingles(H + 4, RawV);
      AliasRes := AllocSingles(W + 4, RawAlias);
      Twin := AllocSingles(W + 4, RawTwin);
      try
        FillDet(Mt, (LineWidthMt div SizeOf(Single)) * H);
        FillDet(V, H, 5);
        FillDet(AliasRes, W, 9);
        for x := 0 to W - 1 do
          Twin[x] := AliasRes[x];

        SetLength(Expected, W);
        for x := 0 to W - 1 do
        begin
          Acc := 0;
          for y := 0 to H - 1 do
            Acc := Acc + PSingle(PByte(Mt) + y * LineWidthMt + x * SizeOf(Single))^ * V[y];
          Expected[x] := 0.5 * Acc + 0.25 * AliasRes[x];
        end;

        ASMMatrixVectMultT(Twin, SizeOf(Single), Mt, V, LineWidthMt, LineWidthV,
          W, H, 0.5, 0.25);
        ASMMatrixVectMultTDestVec(AliasRes, SizeOf(Single), Mt, V, LineWidthMt,
          LineWidthV, W, H, 0.5, 0.25);

        for x := 0 to W - 1 do
          AssertEquals('VectMultTDestVec w=' + IntToStr(W) + ' h=' + IntToStr(H) +
            ' [' + IntToStr(x) + ']', Expected[x], AliasRes[x]);
        for x := 0 to W - 1 do
          AssertEquals('VectMultTDestVec vs VectMultT w=' + IntToStr(W) + ' h=' +
            IntToStr(H) + ' [' + IntToStr(x) + ']', Twin[x], AliasRes[x]);
      finally
        FreeMem(RawMt); FreeMem(RawV); FreeMem(RawAlias); FreeMem(RawTwin);
        Expected := nil;
      end;
    end;
end;

{ ASMRank1UpdateSeqAligned adds the rank one update

    A[row][col] := A[row][col] + alpha * X[row] * Y[col]

  loading the matrix rows and Y with aligned moves, so A and Y must be 16 byte
  aligned and the matrix line width a multiple of 16 bytes. The width itself is
  free: the tail is handled one element at a time. }
procedure TvsmathCoreTests.TestRank1SeqAligned;
var
  W, H, Pitch, LineWidthA, col, row: NativeInt;
  RawA, RawX, RawY: Pointer;
  A, X, Y: PSingle;
  Expected: array of Single;
begin
  for H := 1 to 4 do
    for W := 1 to 17 do
    begin
      LineWidthA := ((W * SizeOf(Single) + 15) div 16) * 16;
      Pitch := LineWidthA div SizeOf(Single);
      A := AllocSingles(Pitch * H, RawA);
      X := AllocSingles(H + 4, RawX);
      Y := AllocSingles(Pitch + 4, RawY);
      try
        FillDet(A, Pitch * H);
        FillDet(X, H, 11);
        FillDet(Y, Pitch, 13);

        SetLength(Expected, Pitch * H);
        for row := 0 to H - 1 do
          for col := 0 to W - 1 do
            Expected[row * Pitch + col] := A[row * Pitch + col] + 0.5 * X[row] * Y[col];

        ASMRank1UpdateSeqAligned(A, LineWidthA, W, H, X, Y,
          SizeOf(Single), SizeOf(Single), 0.5);

        for row := 0 to H - 1 do
          for col := 0 to W - 1 do
            AssertEquals('Rank1SeqAligned w=' + IntToStr(W) + ' h=' + IntToStr(H) +
              ' [' + IntToStr(col) + ',' + IntToStr(row) + ']',
              Expected[row * Pitch + col], A[row * Pitch + col]);
      finally
        FreeMem(RawA); FreeMem(RawX); FreeMem(RawY);
        Expected := nil;
      end;
    end;
end;

{$ENDIF}

initialization
{$IFDEF CPUX64}
  RegisterTest(TvsmathCoreTests);
{$ENDIF}
end.
