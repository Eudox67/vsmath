// ###########################################################
// #### vsmath - vector single math
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the Apache License, Version 2.0 - see LICENSE.
// ###########################################################
// FPCUnit tests for the AVX kernels, against the same exactly representable data
// and Pascal reference as TestVsMath.pas. Every test ignores itself on a CPU
// without AVX.
//
// The over-read checks here use a poisoned pad (cPoison) behind the live data
// rather than a guard page, so a kernel that reads past its input or writes past
// its output fails the assertions.
unit TestVsMathAVX;

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

interface

uses
  fpcunit, testregistry;

{$IFDEF CPUX64}

type
  TvsmathAVXTests = class(TTestCase)
  private
    { True when the CPU can run the kernels; otherwise the test is ignored. }
    function AVXReady: Boolean;
  published
    procedure TestAbsAligned;
    procedure TestAddAligned;
    procedure TestAddUnAligned;
    procedure TestSubAligned;
    procedure TestElemMultAligned;
    procedure TestElemDivAligned;
    procedure TestSqrtAligned;
    procedure TestAddScaleAlignedEvenW;
    procedure TestScaleAddAlignedEvenW;
    procedure TestAddConstAlignedEvenW;
    procedure TestMatrixCopyAligned;
    procedure TestMatrixInitAligned;
    procedure TestSumColumnAligned;
    procedure TestMeanRowAligned;
    procedure TestVarRowAligned;
    procedure TestElementwiseNorm2Aligned;
    procedure TestMatrixMaxAligned;
    procedure TestMatrixMinAligned;
    procedure TestVecDotMultAligned;
    procedure TestMatrixMultAligned;
    procedure TestMatrixVectMultAligned;
    procedure TestMatrixVectMultUnAligned;
    procedure TestMatrixVectMultOddWidth;
    procedure TestCumulativeSumRow;
    procedure TestRotateAligned;
    procedure TestRotateOddN;
    procedure TestRotateStrided;
    procedure TestPlaneRotSeqLowerForward;
    procedure TestPlaneRotSeqLowerBackward;
    procedure TestPlaneRotSeqRowForward;
    procedure TestPlaneRotSeqRowBackward;
    procedure TestSSEPlaneRotSeq;
    procedure TestTransposeAligned;
    procedure TestTransposeUnaligned;
    procedure TestTransposeInplace;
    procedure TestSSETranspose;
    procedure TestMatrixMultTransposed;
    procedure TestVecConvolve;
    procedure TestSumRow;
    procedure TestNormalizeRow;
    procedure TestNormalizeColumn;
    procedure TestTriaForwarders;
    procedure TestFMAVectorMultForwarders;
  end;

{$ENDIF}

implementation

uses
  SysUtils, Math, cpu, MatrixConstSingle,
  AVXMatrixAbsOperationsSinglex64,
  AVXMatrixAddSubOperationsSinglex64,
  AVXMatrixScaleOperationsSinglex64,
  AVXMatrixElementwiseMultOperationsSinglex64,
  AVXMatrixSqrtOperationsSinglex64,
  AVXMatrixSumOperationsSinglex64,
  AVXMatrixMeanOperationsSinglex64,
  AVXMatrixNormOperationsSinglex64,
  AVXMatrixMinMaxOperationsSinglex64,
  AVXMatrixVectorMultOperationsSinglex64,
  AVXMatrixMultOperationsSinglex64,
  AVXMatrixMultTransposedOperationsSinglex64,
  AVXMatrixCumSumDiffOperationsSinglex64,
  AVXMatrixRotationsSinglex64,
  AVXMatrixTransposeOperationsSinglex64,
  ASMMatrixRotationsSinglex64,
  ASMMatrixTransposeOperationsSinglex64,
  ASMMatrixMultOperationsSinglex64,
  AVXVecConvolveSinglex64,
  ASMVecConvolveSinglex64,
  FMAVecConvolveSinglex64,
  FMAMatrixMultOperationsSinglex64,
  FMAMatrixVectorMultOperationsSinglex64,
  AVXMoveOperationsSinglex64;

{$IFDEF CPUX64}

const
  cEps = 1e-3;
  cW = 64;                        { default width, a multiple of 32 }
  cH = 8;                         { default height }
  cStride = cW * SizeOf(Single);  { 256 bytes -> every row stays aligned }
  { Padding sentinel: a kernel that reads or writes outside the live data
    changes the result by a huge amount instead of quietly seeing zeros. }
  cPoison: Single = 1.0e6;

{ Writes APoison over everything from AFirst to ALast (inclusive). }
procedure Poison(AData: PSingle; AFirst, ALast: NativeInt);
var
  i: NativeInt;
begin
  for i := AFirst to ALast do
    AData[i] := cPoison;
end;

{ Fails when any element between AFirst and ALast differs from the sentinel. }
function PadsIntact(AData: PSingle; AFirst, ALast: NativeInt): Boolean;
var
  i: NativeInt;
begin
  Result := True;
  for i := AFirst to ALast do
    if AData[i] <> cPoison then
      Result := False;
end;

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

{ 0, 1/16, 1/4, 9/16, 1, ... - every element has an exact Single square root. }
procedure FillSquares(ADest: PSingle; ACount: NativeInt);
var
  i: NativeInt;
  v: Single;
begin
  for i := 0 to ACount - 1 do
  begin
    v := Single(i mod 11) * 0.25;
    ADest[i] := v * v;
  end;
end;

{ 1/4, 1/2, 1, 2, 4 - exact power-of-two divisors, so division is exact. }
procedure FillPow2(ADest: PSingle; ACount: NativeInt);
const
  cVals: array[0..4] of Single = (0.25, 0.5, 1.0, 2.0, 4.0);
var
  i: NativeInt;
begin
  for i := 0 to ACount - 1 do
    ADest[i] := cVals[i mod 5];
end;

function Idx(AWidth, AX, AY: NativeInt): NativeInt; inline;
begin
  Result := AY * AWidth + AX;
end;

{ Every test starts with this: the AVX kernels are raw AVX code, so running
  them on a CPU without AVX would fault instead of failing an assertion.
  Ignore() only raises when ignores are enabled, hence the explicit Exit at
  every call site. }
function TvsmathAVXTests.AVXReady: Boolean;
begin
  Result := AVXSupport;
  if not Result then
    Ignore('CPU has no AVX support');
end;

procedure TvsmathAVXTests.TestAbsAligned;
var
  RawDest: Pointer;
  Dest: PSingle;
  x, y: NativeInt;
  v: Single;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cW * cH, RawDest);
  try
    FillDet(Dest, cW * cH);
    AVXMatrixAbsAligned(Dest, cStride, cW, cH);
    for y := 0 to cH - 1 do
      for x := 0 to cW - 1 do
      begin
        v := Single(Idx(cW, x, y) mod 23 - 11) * 0.25;
        AssertEquals('Abs x=' + IntToStr(x) + ' y=' + IntToStr(y),
          Abs(v), Dest[Idx(cW, x, y)], cEps);
      end;
  finally
    FreeMem(RawDest);
  end;
end;

procedure TvsmathAVXTests.TestAddAligned;
var
  RawDest, Raw1, Raw2: Pointer;
  Dest, M1, M2: PSingle;
  x, y: NativeInt;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cW * cH, RawDest);
  M1 := AllocSingles(cW * cH, Raw1);
  M2 := AllocSingles(cW * cH, Raw2);
  try
    FillDet(M1, cW * cH);
    FillDet(M2, cW * cH, 7);
    AVXMatrixAddAligned(Dest, cStride, M1, M2, cW, cH, cStride, cStride);
    for y := 0 to cH - 1 do
      for x := 0 to cW - 1 do
        AssertEquals('Add x=' + IntToStr(x) + ' y=' + IntToStr(y),
          M1[Idx(cW, x, y)] + M2[Idx(cW, x, y)], Dest[Idx(cW, x, y)], cEps);
  finally
    FreeMem(RawDest); FreeMem(Raw1); FreeMem(Raw2);
  end;
end;

procedure TvsmathAVXTests.TestAddUnAligned;
var
  RawDest, Raw1, Raw2: Pointer;
  Dest, M1, M2: PSingle;
  x, y: NativeInt;
begin
  if not AVXReady then
    Exit;
  { one element of padding makes every pointer 4-byte (not 64-byte) aligned }
  Dest := PSingle(PByte(AllocSingles(cW * cH + 1, RawDest)) + SizeOf(Single));
  M1 := PSingle(PByte(AllocSingles(cW * cH + 1, Raw1)) + SizeOf(Single));
  M2 := PSingle(PByte(AllocSingles(cW * cH + 1, Raw2)) + SizeOf(Single));
  try
    FillDet(M1, cW * cH);
    FillDet(M2, cW * cH, 3);
    AVXMatrixAddUnAligned(Dest, cStride, M1, M2, cW, cH, cStride, cStride);
    for y := 0 to cH - 1 do
      for x := 0 to cW - 1 do
        AssertEquals('AddUnAligned x=' + IntToStr(x) + ' y=' + IntToStr(y),
          M1[Idx(cW, x, y)] + M2[Idx(cW, x, y)], Dest[Idx(cW, x, y)], cEps);
  finally
    FreeMem(RawDest); FreeMem(Raw1); FreeMem(Raw2);
  end;
end;

procedure TvsmathAVXTests.TestSubAligned;
var
  RawDest, Raw1, Raw2: Pointer;
  Dest, M1, M2: PSingle;
  x, y: NativeInt;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cW * cH, RawDest);
  M1 := AllocSingles(cW * cH, Raw1);
  M2 := AllocSingles(cW * cH, Raw2);
  try
    FillDet(M1, cW * cH);
    FillDet(M2, cW * cH, 5);
    AVXMatrixSubAligned(Dest, cStride, M1, M2, cW, cH, cStride, cStride);
    for y := 0 to cH - 1 do
      for x := 0 to cW - 1 do
        AssertEquals('Sub x=' + IntToStr(x) + ' y=' + IntToStr(y),
          M1[Idx(cW, x, y)] - M2[Idx(cW, x, y)], Dest[Idx(cW, x, y)], cEps);
  finally
    FreeMem(RawDest); FreeMem(Raw1); FreeMem(Raw2);
  end;
end;
procedure TvsmathAVXTests.TestElemMultAligned;
var
  RawDest, Raw1, Raw2: Pointer;
  Dest, M1, M2: PSingle;
  x, y: NativeInt;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cW * cH, RawDest);
  M1 := AllocSingles(cW * cH, Raw1);
  M2 := AllocSingles(cW * cH, Raw2);
  try
    FillDet(M1, cW * cH);
    FillDet(M2, cW * cH, 2);
    AVXMatrixElemMultAligned(Dest, cStride, M1, M2, cW, cH, cStride, cStride);
    for y := 0 to cH - 1 do
      for x := 0 to cW - 1 do
        AssertEquals('ElemMult x=' + IntToStr(x) + ' y=' + IntToStr(y),
          M1[Idx(cW, x, y)] * M2[Idx(cW, x, y)], Dest[Idx(cW, x, y)], cEps);
  finally
    FreeMem(RawDest); FreeMem(Raw1); FreeMem(Raw2);
  end;
end;

procedure TvsmathAVXTests.TestElemDivAligned;
var
  RawDest, Raw1, Raw2: Pointer;
  Dest, M1, M2: PSingle;
  x, y: NativeInt;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cW * cH, RawDest);
  M1 := AllocSingles(cW * cH, Raw1);
  M2 := AllocSingles(cW * cH, Raw2);
  try
    FillDet(M1, cW * cH);
    FillPow2(M2, cW * cH);
    AVXMatrixElemDivAligned(Dest, cStride, M1, M2, cW, cH, cStride, cStride);
    for y := 0 to cH - 1 do
      for x := 0 to cW - 1 do
        AssertEquals('ElemDiv x=' + IntToStr(x) + ' y=' + IntToStr(y),
          M1[Idx(cW, x, y)] / M2[Idx(cW, x, y)], Dest[Idx(cW, x, y)], cEps);
  finally
    FreeMem(RawDest); FreeMem(Raw1); FreeMem(Raw2);
  end;
end;

procedure TvsmathAVXTests.TestSqrtAligned;
var
  RawDest: Pointer;
  Dest: PSingle;
  x, y: NativeInt;
  v: Single;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cW * cH, RawDest);
  try
    FillSquares(Dest, cW * cH);
    AVXMatrixSQRTAligned(Dest, cStride, cW, cH);
    for y := 0 to cH - 1 do
      for x := 0 to cW - 1 do
      begin
        v := Single(Idx(cW, x, y) mod 11) * 0.25;
        AssertEquals('SQRT x=' + IntToStr(x) + ' y=' + IntToStr(y),
          v, Dest[Idx(cW, x, y)], cEps);
      end;
  finally
    FreeMem(RawDest);
  end;
end;

procedure TvsmathAVXTests.TestAddScaleAlignedEvenW;
var
  RawDest, RawRef: Pointer;
  Dest, Ref: PSingle;
  i: NativeInt;
  dOffset, Scale: Single;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cW * cH, RawDest);
  Ref := AllocSingles(cW * cH, RawRef);
  try
    FillDet(Dest, cW * cH);
    FillDet(Ref, cW * cH);
    dOffset := 1.5;
    Scale := -2.0;
    { AddScale semantics: dest := (dest + dOffset) * Scale }
    AVXMatrixAddscaleAlignedEvenW(Dest, cStride, cW, cH, dOffset, Scale);
    for i := 0 to cW * cH - 1 do
      AssertEquals('AddScale i=' + IntToStr(i),
        (Ref[i] + dOffset) * Scale, Dest[i], cEps);
  finally
    FreeMem(RawDest); FreeMem(RawRef);
  end;
end;

procedure TvsmathAVXTests.TestScaleAddAlignedEvenW;
var
  RawDest, RawRef: Pointer;
  Dest, Ref: PSingle;
  i: NativeInt;
  dOffset, Scale: Single;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cW * cH, RawDest);
  Ref := AllocSingles(cW * cH, RawRef);
  try
    FillDet(Dest, cW * cH, 2);
    FillDet(Ref, cW * cH, 2);
    dOffset := 3.0;
    Scale := 0.5;
    { ScaleAdd semantics: dest := dest * Scale + dOffset }
    AVXMatrixScaleAddAlignedEvenW(Dest, cStride, cW, cH, dOffset, Scale);
    for i := 0 to cW * cH - 1 do
      AssertEquals('ScaleAdd i=' + IntToStr(i),
        Ref[i] * Scale + dOffset, Dest[i], cEps);
  finally
    FreeMem(RawDest); FreeMem(RawRef);
  end;
end;

procedure TvsmathAVXTests.TestAddConstAlignedEvenW;
var
  RawDest, RawRef: Pointer;
  Dest, Ref: PSingle;
  i: NativeInt;
  dOffset: Single;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cW * cH, RawDest);
  Ref := AllocSingles(cW * cH, RawRef);
  try
    FillDet(Dest, cW * cH, 4);
    FillDet(Ref, cW * cH, 4);
    dOffset := -0.75;
    AVXMatrixAddAlignedEvenW(Dest, cStride, cW, cH, dOffset);
    for i := 0 to cW * cH - 1 do
      AssertEquals('AddConst i=' + IntToStr(i), Ref[i] + dOffset, Dest[i], cEps);
  finally
    FreeMem(RawDest); FreeMem(RawRef);
  end;
end;

procedure TvsmathAVXTests.TestMatrixCopyAligned;
var
  RawDest, RawSrc: Pointer;
  Dest, Src: PSingle;
  i: NativeInt;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cW * cH, RawDest);
  Src := AllocSingles(cW * cH, RawSrc);
  try
    FillDet(Src, cW * cH, 6);
    AVXMatrixCopyAligned(Dest, cStride, Src, cStride, cW, cH);
    for i := 0 to cW * cH - 1 do
      AssertEquals('Copy i=' + IntToStr(i), Src[i], Dest[i], cEps);
  finally
    FreeMem(RawDest); FreeMem(RawSrc);
  end;
end;

procedure TvsmathAVXTests.TestMatrixInitAligned;
var
  RawDest: Pointer;
  Dest: PSingle;
  i: NativeInt;
  Value: Single;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cW * cH, RawDest);
  try
    FillDet(Dest, cW * cH);
    Value := -1.25;
    AVXMatrixInitAligned(Dest, cStride, cW, cH, Value);
    for i := 0 to cW * cH - 1 do
      AssertEquals('Init i=' + IntToStr(i), Value, Dest[i], cEps);
  finally
    FreeMem(RawDest);
  end;
end;

procedure TvsmathAVXTests.TestSumColumnAligned;
var
  RawDest, RawSrc: Pointer;
  Dest, Src: PSingle;
  x, y: NativeInt;
  Sum: Single;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cW, RawDest);
  Src := AllocSingles(cW * cH, RawSrc);
  try
    FillDet(Src, cW * cH);
    AVXMatrixSumColumnAligned(Dest, SizeOf(Single), Src, cStride, cW, cH);
    for x := 0 to cW - 1 do
    begin
      Sum := 0;
      for y := 0 to cH - 1 do
        Sum := Sum + Src[Idx(cW, x, y)];
      AssertEquals('SumColumn x=' + IntToStr(x), Sum, Dest[x], cEps);
    end;
  finally
    FreeMem(RawDest); FreeMem(RawSrc);
  end;
end;

procedure TvsmathAVXTests.TestMeanRowAligned;
var
  RawDest, RawSrc: Pointer;
  Dest, Src: PSingle;
  x, y: NativeInt;
  Sum: Single;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cH + 1, RawDest);
  Src := AllocSingles(cW * cH, RawSrc);
  try
    FillDet(Src, cW * cH);
    AVXMatrixMeanRowAligned(Dest, SizeOf(Single), Src, cStride, cW, cH);
    for y := 0 to cH - 1 do
    begin
      Sum := 0;
      for x := 0 to cW - 1 do
        Sum := Sum + Src[Idx(cW, x, y)];
      AssertEquals('MeanRow y=' + IntToStr(y), Sum / cW, Dest[y], cEps);
    end;
  finally
    FreeMem(RawDest); FreeMem(RawSrc);
  end;
end;

procedure TvsmathAVXTests.TestVarRowAligned;
var
  RawDest, RawSrc: Pointer;
  Dest, Src: PSingle;
  x, y: NativeInt;
  Sum, Mean, Acc, v: Single;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cH + 1, RawDest);
  Src := AllocSingles(cW * cH, RawSrc);
  try
    FillDet(Src, cW * cH, 3);
    AVXMatrixVarRowAligned(Dest, SizeOf(Single), Src, cStride, cW, cH, False);
    for y := 0 to cH - 1 do
    begin
      Sum := 0;
      for x := 0 to cW - 1 do
        Sum := Sum + Src[Idx(cW, x, y)];
      Mean := Sum / cW;
      Acc := 0;
      for x := 0 to cW - 1 do
      begin
        v := Src[Idx(cW, x, y)] - Mean;
        Acc := Acc + v * v;
      end;
      AssertEquals('VarRow biased y=' + IntToStr(y), Acc / cW, Dest[y], cEps);
    end;
    { the unbiased flag divides by width - 1, not by width }
    AVXMatrixVarRowAligned(Dest, SizeOf(Single), Src, cStride, cW, cH, True);
    for y := 0 to cH - 1 do
    begin
      Sum := 0;
      for x := 0 to cW - 1 do
        Sum := Sum + Src[Idx(cW, x, y)];
      Mean := Sum / cW;
      Acc := 0;
      for x := 0 to cW - 1 do
      begin
        v := Src[Idx(cW, x, y)] - Mean;
        Acc := Acc + v * v;
      end;
      AssertEquals('VarRow unbiased y=' + IntToStr(y), Acc / (cW - 1), Dest[y], cEps);
    end;
  finally
    FreeMem(RawDest); FreeMem(RawSrc);
  end;
end;

procedure TvsmathAVXTests.TestElementwiseNorm2Aligned;
var
  RawSrc: Pointer;
  Src: PSingle;
  i: NativeInt;
  Acc: Double;
begin
  if not AVXReady then
    Exit;
  Src := AllocSingles(cW * cH, RawSrc);
  try
    FillDet(Src, cW * cH);
    Acc := 0;
    for i := 0 to cW * cH - 1 do
      Acc := Acc + Src[i] * Src[i];
    { the kernel returns the sum of squares; MatrixElementwiseNorm2 takes the
      root when the caller asks for it }
    AssertEquals('ElemNorm2', Acc,
      AVXMatrixElementwiseNorm2Aligned(Src, cStride, cW, cH), cEps);
  finally
    FreeMem(RawSrc);
  end;
end;

procedure TvsmathAVXTests.TestMatrixMaxAligned;
var
  RawSrc: Pointer;
  Src: PSingle;
  i: NativeInt;
  Expected: Single;
begin
  if not AVXReady then
    Exit;
  Src := AllocSingles(cW * cH, RawSrc);
  try
    FillDet(Src, cW * cH);
    { all values negative: a reduction that starts from the wrong +0.0 sentinel
      instead of -FLT_MAX returns the sentinel and fails here }
    for i := 0 to cW * cH - 1 do
      Src[i] := -1.0 - Abs(Src[i]);
    Expected := Src[0];
    for i := 1 to cW * cH - 1 do
      if Src[i] > Expected then
        Expected := Src[i];
    AssertEquals('MatrixMaxAligned', Expected,
      AVXMatrixMaxAligned(Src, cW, cH, cStride), cEps);
  finally
    FreeMem(RawSrc);
  end;
end;

procedure TvsmathAVXTests.TestMatrixMinAligned;
var
  RawSrc: Pointer;
  Src: PSingle;
  i: NativeInt;
  Expected: Single;
begin
  if not AVXReady then
    Exit;
  Src := AllocSingles(cW * cH, RawSrc);
  try
    FillDet(Src, cW * cH, 5);
    { all values positive: a reduction that starts from +0.0 instead of +FLT_MAX
      returns 0.0 and fails here }
    for i := 0 to cW * cH - 1 do
      Src[i] := 1.0 + Abs(Src[i]);
    Expected := Src[0];
    for i := 1 to cW * cH - 1 do
      if Src[i] < Expected then
        Expected := Src[i];
    AssertEquals('MatrixMinAligned', Expected,
      AVXMatrixMinAligned(Src, cW, cH, cStride), cEps);
  finally
    FreeMem(RawSrc);
  end;
end;

procedure TvsmathAVXTests.TestVecDotMultAligned;
var
  RawX, RawY: Pointer;
  X, Y: PSingle;
  i, N: NativeInt;
  Expected: Single;
begin
  if not AVXReady then
    Exit;
  N := 256;
  X := AllocSingles(N, RawX);
  Y := AllocSingles(N, RawY);
  try
    FillDet(X, N);
    FillDet(Y, N, 9);
    Expected := 0;
    for i := 0 to N - 1 do
      Expected := Expected + X[i] * Y[i];
    AssertEquals('VecDotMultAligned', Expected,
      AVXMatrixVecDotMultAligned(X, Y, N), cEps);
  finally
    FreeMem(RawX); FreeMem(RawY);
  end;
end;

procedure TvsmathAVXTests.TestMatrixMultAligned;
var
  RawDest, Raw1, Raw2: Pointer;
  Dest, M1, M2: PSingle;
  x, y, k, W1, H1, W2, H2: NativeInt;
  Stride1, Stride2, StrideD: NativeInt;
  Sum: Single;
begin
  if not AVXReady then
    Exit;
  W1 := 32;
  H1 := 8;
  W2 := 32;
  H2 := 32;
  Stride1 := W1 * SizeOf(Single);
  Stride2 := W2 * SizeOf(Single);
  StrideD := W2 * SizeOf(Single);
  Dest := AllocSingles(H1 * W2, RawDest);
  M1 := AllocSingles(H1 * W1, Raw1);
  M2 := AllocSingles(H2 * W2, Raw2);
  try
    FillDet(M1, H1 * W1);
    FillDet(M2, H2 * W2, 4);
    AVXMatrixMultAligned(Dest, StrideD, M1, M2, W1, H1, W2, H2, Stride1, Stride2);
    for y := 0 to H1 - 1 do
      for x := 0 to W2 - 1 do
      begin
        Sum := 0;
        for k := 0 to W1 - 1 do
          Sum := Sum + M1[Idx(W1, k, y)] * M2[Idx(W2, x, k)];
        AssertEquals('Mult x=' + IntToStr(x) + ' y=' + IntToStr(y),
          Sum, Dest[Idx(W2, x, y)], cEps);
      end;
  finally
    FreeMem(RawDest); FreeMem(Raw1); FreeMem(Raw2);
  end;
end;

procedure TvsmathAVXTests.TestMatrixVectMultAligned;
var
  RawMt, RawV, RawDest: Pointer;
  Mt, V, Dest: PSingle;
  x, y, W, H: NativeInt;
  LwMt, LwV: NativeInt;
  Acc: Single;
begin
  if not AVXReady then
    Exit;
  W := 32;
  H := 8;
  LwMt := W * SizeOf(Single);
  LwV := W * SizeOf(Single);
  { no padding rows and no padding behind the vector: the kernel has to stop at
    the last row and at v[W-1]. The extra elements only exist to hold the
    poisoned sentinel that catches reads past the live data. }
  Mt := AllocSingles(H * W + 8, RawMt);
  V := AllocSingles(W + 8, RawV);
  Dest := AllocSingles(H + 2, RawDest);
  try
    FillDet(Mt, H * W);
    FillDet(V, W, 3);
    Poison(Mt, H * W, H * W + 7);
    Poison(V, W, W + 7);
    Poison(Dest, H, H + 1);
    { dest is a vector of H entries, hence a destLineWidth of one Single }
    AVXMatrixVectMultAlignedVAligned(Dest, SizeOf(Single), Mt, V, LwMt, LwV,
      W, H, 1.0, 0.0);
    for y := 0 to H - 1 do
    begin
      Acc := 0;
      for x := 0 to W - 1 do
        Acc := Acc + Mt[Idx(W, x, y)] * V[x];
      AssertEquals('VectMult y=' + IntToStr(y), Acc, Dest[y], cEps);
    end;
    AssertTrue('VectMult wrote past the last row', PadsIntact(Mt, H * W, H * W + 7));
    AssertTrue('VectMult wrote past the vector', PadsIntact(V, W, W + 7));
    AssertTrue('VectMult wrote past dest', PadsIntact(Dest, H, H + 1));
    { alpha/beta form: dest := alpha * (mt * v) + beta * dest }
    for y := 0 to H - 1 do
      Dest[y] := 1.0;
    AVXMatrixVectMultAlignedVAligned(Dest, SizeOf(Single), Mt, V, LwMt, LwV,
      W, H, 2.0, 3.0);
    for y := 0 to H - 1 do
    begin
      Acc := 0;
      for x := 0 to W - 1 do
        Acc := Acc + Mt[Idx(W, x, y)] * V[x];
      AssertEquals('VectMult alpha/beta y=' + IntToStr(y),
        2.0 * Acc + 3.0, Dest[y], cEps);
    end;
    AssertTrue('VectMult alpha/beta wrote past dest', PadsIntact(Dest, H, H + 1));
  finally
    FreeMem(RawMt); FreeMem(RawV); FreeMem(RawDest);
  end;
end;

{ Same as above for the unaligned matrix variant and for widths that are not a
  multiple of eight (the scalar tail of the kernels). }
procedure TvsmathAVXTests.TestMatrixVectMultUnAligned;
var
  RawMt, RawV, RawDest: Pointer;
  Mt, V, Dest: PSingle;
  x, y, W, H: NativeInt;
  Acc: Single;
begin
  if not AVXReady then
    Exit;
  W := 36;
  H := 5;
  Mt := AllocSingles(H * W + 8, RawMt);
  V := AllocSingles(W + 8, RawV);
  Dest := AllocSingles(H + 2, RawDest);
  try
    FillDet(Mt, H * W);
    FillDet(V, W, 3);
    Poison(Mt, H * W, H * W + 7);
    Poison(V, W, W + 7);
    Poison(Dest, H, H + 1);
    AVXMatrixVectMultUnAlignedVAligned(Dest, SizeOf(Single), Mt, V,
      W * SizeOf(Single), W * SizeOf(Single), W, H, 1.0, 0.0);
    for y := 0 to H - 1 do
    begin
      Acc := 0;
      for x := 0 to W - 1 do
        Acc := Acc + Mt[Idx(W, x, y)] * V[x];
      AssertEquals('VectMult unaligned y=' + IntToStr(y), Acc, Dest[y], cEps);
    end;
    AssertTrue('VectMult unaligned wrote past the last row',
      PadsIntact(Mt, H * W, H * W + 7));
    AssertTrue('VectMult unaligned wrote past the vector', PadsIntact(V, W, W + 7));
    AssertTrue('VectMult unaligned wrote past dest', PadsIntact(Dest, H, H + 1));
  finally
    FreeMem(RawMt); FreeMem(RawV); FreeMem(RawDest);
  end;
end;

{ Widths that are not a multiple of eight exercise the scalar tail of the
  eight lane path (the small width goes through the row by row fallback). }
procedure TvsmathAVXTests.TestMatrixVectMultOddWidth;
const
  cWidths: array[0..2] of NativeInt = (5, 13, 21);
var
  RawMt, RawV, RawDest: Pointer;
  Mt, V, Dest: PSingle;
  x, y, W, H: NativeInt;
  Acc: Single;
begin
  if not AVXReady then
    Exit;
  H := 6;
  for W in cWidths do
  begin
    Mt := AllocSingles(H * W + 8, RawMt);
    V := AllocSingles(W + 8, RawV);
    Dest := AllocSingles(H + 2, RawDest);
    try
      FillDet(Mt, H * W);
      FillDet(V, W, 3);
      Poison(Mt, H * W, H * W + 7);
      Poison(V, W, W + 7);
      Poison(Dest, H, H + 1);
      AVXMatrixVectMultUnAlignedVAligned(Dest, SizeOf(Single), Mt, V,
        W * SizeOf(Single), W * SizeOf(Single), W, H, 1.0, 0.0);
      for y := 0 to H - 1 do
      begin
        Acc := 0;
        for x := 0 to W - 1 do
          Acc := Acc + Mt[Idx(W, x, y)] * V[x];
        AssertEquals('VectMult W=' + IntToStr(W) + ' y=' + IntToStr(y),
          Acc, Dest[y], cEps);
      end;
      AssertTrue('VectMult W=' + IntToStr(W) + ' wrote past the last row',
        PadsIntact(Mt, H * W, H * W + 7));
      AssertTrue('VectMult W=' + IntToStr(W) + ' wrote past the vector',
        PadsIntact(V, W, W + 7));
      AssertTrue('VectMult W=' + IntToStr(W) + ' wrote past dest',
        PadsIntact(Dest, H, H + 1));
    finally
      FreeMem(RawMt); FreeMem(RawV); FreeMem(RawDest);
    end;
  end;
end;

procedure TvsmathAVXTests.TestCumulativeSumRow;
var
  RawDest, RawSrc: Pointer;
  Dest, Src: PSingle;
  x, y: NativeInt;
  Sum: Single;
begin
  if not AVXReady then
    Exit;
  Dest := AllocSingles(cW * cH, RawDest);
  Src := AllocSingles(cW * cH, RawSrc);
  try
    FillDet(Src, cW * cH);
    AVXMatrixCumulativeSumRow(Dest, cStride, Src, cStride, cW, cH);
    for y := 0 to cH - 1 do
    begin
      Sum := 0;
      for x := 0 to cW - 1 do
      begin
        Sum := Sum + Src[Idx(cW, x, y)];
        AssertEquals('CumSum x=' + IntToStr(x) + ' y=' + IntToStr(y),
          Sum, Dest[Idx(cW, x, y)], cEps);
      end;
    end;
  finally
    FreeMem(RawDest); FreeMem(RawSrc);
  end;
end;

// ---------------------------------------------------------------------------
// rotations
// ---------------------------------------------------------------------------
// AVXMatrixRotate turns X/Y into c*x + s*y and -s*x + c*y. c = 1/4 and s = 1/2
// keep both expressions exact in Single for the small integers used here, so a
// mismatch is a kernel bug and not rounding.
const
  cRotC = 0.25;
  cRotS = 0.5;

{ Fills X[i] = i and Y[i] = ACapacity - i, i.e. values that stay exact. }
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

procedure TvsmathAVXTests.TestRotateAligned;
const
  cN = 32; { eight full 16 byte blocks, no tail }
var
  RawX, RawY: Pointer;
  X, Y: PSingle;
  i: NativeInt;
begin
  if not AVXReady then
    Exit;
  X := AllocSingles(cN, RawX);
  Y := AllocSingles(cN, RawY);
  try
    FillRotate(X, Y, cN, cN);
    AVXMatrixRotate(cN, X, SizeOf(Single), Y, SizeOf(Single), cRotC, cRotS);
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

{ The tail loop handles N mod 4 elements, and nothing past X[N-1] / Y[N-1] may
  be touched: the sentinels after the live data catch an overrun. }
procedure TvsmathAVXTests.TestRotateOddN;
const
  cSizes: array[0..2] of NativeInt = (1, 3, 5);
  cCapacity = 8;
  cSentinel = -99;
var
  RawX, RawY: Pointer;
  X, Y: PSingle;
  i, n: NativeInt;
begin
  if not AVXReady then
    Exit;
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
      AVXMatrixRotate(n, X, SizeOf(Single), Y, SizeOf(Single), cRotC, cRotS);
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

{ LineWidthDY <> sizeof(single) selects the strided kernel: X stays contiguous
  while Y only touches every second element. }
procedure TvsmathAVXTests.TestRotateStrided;
const
  cN = 16;
var
  RawX, RawY: Pointer;
  X, Y: PSingle;
  i: NativeInt;
begin
  if not AVXReady then
    Exit;
  X := AllocSingles(cN, RawX);
  Y := AllocSingles(2 * cN, RawY);
  try
    FillRotate(X, Y, cN, cN);
    for i := 0 to cN - 1 do
    begin
      Y[2 * i] := Single(cN - i);
      Y[2 * i + 1] := -1;
    end;
    AVXMatrixRotate(cN, X, SizeOf(Single), Y, 2 * SizeOf(Single), cRotC, cRotS);
    for i := 0 to cN - 1 do
    begin
      AssertEquals('Strided X[' + IntToStr(i) + ']', RefRotX(i, cN), X[i], cEps);
      AssertEquals('Strided Y[' + IntToStr(2 * i) + ']', RefRotY(i, cN), Y[2 * i], cEps);
      AssertEquals('Strided Y[' + IntToStr(2 * i + 1) + '] untouched',
        Single(-1), Y[2 * i + 1], 0);
    end;
  finally
    FreeMem(RawX);
    FreeMem(RawY);
  end;
end;

// ---------------------------------------------------------------------------
// plane rotation sequences
// ---------------------------------------------------------------------------
// c = 1/2 and s = 1/4 keep every product exact for the multiples of 1/4 used
// as test data, so an exact comparison against the reference is possible.
const
  cSeqC = 0.5;
  cSeqS = 0.25;

{ Fills A with multiples of 1/4, every fourth c/s pair is the identity. }
procedure FillPlaneRot(W, H, APitch: NativeInt; A, C, S: PSingle);
var
  x, y: NativeInt;
begin
  for y := 0 to H - 1 do
    for x := 0 to W - 1 do
      A[y * APitch + x] := Single(((y * W + x) mod 9) - 4) * 0.25;
  for x := 0 to W + H do
  begin
    if x mod 4 = 0 then
    begin
      C[x] := 1;
      S[x] := 0;
    end
    else
    begin
      C[x] := cSeqC;
      S[x] := cSeqS;
    end;
  end;
end;

{ Reference for the L* variants: rotate the row pairs y / y + 1. }
procedure RefPlaneRotL(ABackward: Boolean; W, H, APitch: NativeInt; A, C, S: PSingle);
var
  x, y, i: NativeInt;
  t: Single;
begin
  for i := 0 to H - 2 do
  begin
    if ABackward then
      y := H - 2 - i
    else
      y := i;
    if (C[y] <> 1) or (S[y] <> 0) then
      for x := 0 to W - 1 do
      begin
        t := A[(y + 1) * APitch + x];
        A[(y + 1) * APitch + x] := C[y] * t - S[y] * A[y * APitch + x];
        A[y * APitch + x] := S[y] * t + C[y] * A[y * APitch + x];
      end;
  end;
end;

{ Reference for the R* variants: rotate the column pairs x / x + 1 per row. }
procedure RefPlaneRotR(ABackward: Boolean; W, H, APitch: NativeInt; A, C, S: PSingle);
var
  x, y, i: NativeInt;
  t: Single;
begin
  for y := 0 to H - 1 do
    for i := 0 to W - 2 do
    begin
      if ABackward then
        x := W - 2 - i
      else
        x := i;
      t := A[y * APitch + x + 1];
      A[y * APitch + x + 1] := C[x] * t - S[x] * A[y * APitch + x];
      A[y * APitch + x] := S[x] * t + C[x] * A[y * APitch + x];
    end;
end;

type
  TPlaneRotProc = procedure(width, height : NativeInt; A : PSingle;
    const LineWidthA : NativeInt; C, S : PConstSingleArr);

{ Runs AProc on a fresh copy of the test data and compares it with the
  reference. AW/APitch vary the width so the vector loop and its scalar tail
  are both exercised. }
procedure CheckPlaneRot(const AName: string; AProc: TPlaneRotProc;
  ABackward, ARows: Boolean; W, H, APitch: NativeInt);
var
  RawA, RawRef, RawC, RawS: Pointer;
  A, Ref, C, S: PSingle;
  x, y: NativeInt;
begin
  A := AllocSingles((APitch * H) + 8, RawA);
  Ref := AllocSingles((APitch * H) + 8, RawRef);
  C := AllocSingles(W + H + 8, RawC);
  S := AllocSingles(W + H + 8, RawS);
  try
    FillPlaneRot(W, H, APitch, A, C, S);
    FillPlaneRot(W, H, APitch, Ref, C, S);
    Poison(A, APitch * H, APitch * H + 7);
    if ARows then
      RefPlaneRotR(ABackward, W, H, APitch, Ref, C, S)
    else
      RefPlaneRotL(ABackward, W, H, APitch, Ref, C, S);
    AProc(W, H, A, APitch * SizeOf(Single), PConstSingleArr(C), PConstSingleArr(S));
    for y := 0 to H - 1 do
      for x := 0 to W - 1 do
        TAssert.AssertEquals(AName + ' W=' + IntToStr(W) + ' H=' + IntToStr(H) +
          ' [' + IntToStr(x) + ',' + IntToStr(y) + ']',
          Ref[y * APitch + x], A[y * APitch + x], 0);
    TAssert.AssertTrue(AName + ' wrote past the last row', PadsIntact(A, APitch * H, APitch * H + 7));
  finally
    FreeMem(RawA); FreeMem(RawRef); FreeMem(RawC); FreeMem(RawS);
  end;
end;

procedure TvsmathAVXTests.TestPlaneRotSeqLowerForward;
begin
  if not AVXReady then
    Exit;
  CheckPlaneRot('AVX LVF', @AVXApplyPlaneRotSeqLVF, False, False, 16, 5, 16);
  CheckPlaneRot('AVX LVF odd', @AVXApplyPlaneRotSeqLVF, False, False, 13, 4, 13);
  CheckPlaneRot('AVX LVF narrow', @AVXApplyPlaneRotSeqLVF, False, False, 5, 3, 5);
  CheckPlaneRot('AVX LVF single row', @AVXApplyPlaneRotSeqLVF, False, False, 11, 1, 11);
end;

procedure TvsmathAVXTests.TestPlaneRotSeqLowerBackward;
begin
  if not AVXReady then
    Exit;
  CheckPlaneRot('AVX LVB', @AVXApplyPlaneRotSeqLVB, True, False, 16, 5, 16);
  CheckPlaneRot('AVX LVB odd', @AVXApplyPlaneRotSeqLVB, True, False, 13, 4, 13);
  CheckPlaneRot('AVX LVB narrow', @AVXApplyPlaneRotSeqLVB, True, False, 5, 3, 5);
  CheckPlaneRot('AVX LVB padded', @AVXApplyPlaneRotSeqLVB, True, False, 9, 4, 12);
end;

procedure TvsmathAVXTests.TestPlaneRotSeqRowForward;
begin
  if not AVXReady then
    Exit;
  CheckPlaneRot('AVX RVF', @AVXApplyPlaneRotSeqRVF, False, True, 16, 5, 16);
  CheckPlaneRot('AVX RVF odd', @AVXApplyPlaneRotSeqRVF, False, True, 13, 4, 13);
  CheckPlaneRot('AVX RVF narrow', @AVXApplyPlaneRotSeqRVF, False, True, 3, 3, 3);
  CheckPlaneRot('AVX RVF one column', @AVXApplyPlaneRotSeqRVF, False, True, 1, 4, 1);
end;

procedure TvsmathAVXTests.TestPlaneRotSeqRowBackward;
begin
  if not AVXReady then
    Exit;
  CheckPlaneRot('AVX RVB', @AVXApplyPlaneRotSeqRVB, True, True, 16, 5, 16);
  CheckPlaneRot('AVX RVB odd', @AVXApplyPlaneRotSeqRVB, True, True, 13, 4, 13);
  CheckPlaneRot('AVX RVB narrow', @AVXApplyPlaneRotSeqRVB, True, True, 3, 3, 3);
  CheckPlaneRot('AVX RVB padded', @AVXApplyPlaneRotSeqRVB, True, True, 9, 4, 12);
end;

{ The SSE twins take the same c/s arrays and have to produce the same matrix. }
procedure TvsmathAVXTests.TestSSEPlaneRotSeq;
begin
  if not AVXReady then
    Exit;
  CheckPlaneRot('SSE LVF', @ASMApplyPlaneRotSeqLVF, False, False, 16, 5, 16);
  CheckPlaneRot('SSE LVF odd', @ASMApplyPlaneRotSeqLVF, False, False, 13, 4, 13);
  CheckPlaneRot('SSE LVB', @ASMApplyPlaneRotSeqLVB, True, False, 13, 4, 13);
  CheckPlaneRot('SSE RVF', @ASMApplyPlaneRotSeqRVF, False, True, 13, 4, 13);
  CheckPlaneRot('SSE RVB', @ASMApplyPlaneRotSeqRVB, True, True, 13, 4, 13);
  CheckPlaneRot('SSE RVB narrow', @ASMApplyPlaneRotSeqRVB, True, True, 3, 3, 3);
end;
// ---------------------------------------------------------------------------
// transposition
// ---------------------------------------------------------------------------
type
  TTransposeProc = procedure(dest : PSingle; const destLineWidth : NativeInt;
    mt : PSingle; const LineWidth : NativeInt; width, height : NativeInt);

{ Transposes a W x H block (both strides are configurable) and compares the
  result with the input; the pad behind dest catches writes past its end. }
procedure CheckTranspose(const AName: string; AProc: TTransposeProc;
  W, H, APitch, ADestPitch: NativeInt; AAligned: Boolean);
var
  RawMt, RawDest: Pointer;
  Mt, Dest: PSingle;
  x, y: NativeInt;
begin
  Mt := AllocSingles(APitch * H + 8, RawMt);
  Dest := AllocSingles(ADestPitch * W + 8, RawDest);
  try
    for y := 0 to H - 1 do
      for x := 0 to W - 1 do
        Mt[y * APitch + x] := Single(((y * W + x) mod 17) - 8) * 0.25;
    Poison(Dest, ADestPitch * W, ADestPitch * W + 7);
    AProc(Dest, ADestPitch * SizeOf(Single), Mt, APitch * SizeOf(Single), W, H);
    for x := 0 to W - 1 do
      for y := 0 to H - 1 do
        TAssert.AssertEquals(AName + ' W=' + IntToStr(W) + ' H=' + IntToStr(H) +
          ' [' + IntToStr(x) + ',' + IntToStr(y) + ']',
          Mt[y * APitch + x], Dest[x * ADestPitch + y], 0);
    TAssert.AssertTrue(AName + ' wrote past dest', PadsIntact(Dest, ADestPitch * W, ADestPitch * W + 7));
  finally
    FreeMem(RawMt); FreeMem(RawDest);
  end;
end;

procedure TvsmathAVXTests.TestTransposeAligned;
begin
  if not AVXReady then
    Exit;
  CheckTranspose('AVX transpose', @AVXMatrixTransposeAligned, 8, 8, 8, 8, True);
  CheckTranspose('AVX transpose', @AVXMatrixTransposeAligned, 16, 4, 16, 4, True);
  CheckTranspose('AVX transpose', @AVXMatrixTransposeAligned, 4, 16, 4, 16, True);
  CheckTranspose('AVX transpose', @AVXMatrixTransposeAligned, 24, 12, 24, 12, True);
end;

procedure TvsmathAVXTests.TestTransposeUnaligned;
begin
  if not AVXReady then
    Exit;
  CheckTranspose('AVX transpose unaligned', @AVXMatrixTransposeUnaligned, 1, 1, 1, 1, False);
  CheckTranspose('AVX transpose unaligned', @AVXMatrixTransposeUnaligned, 5, 3, 5, 3, False);
  CheckTranspose('AVX transpose unaligned', @AVXMatrixTransposeUnaligned, 11, 7, 11, 7, False);
  CheckTranspose('AVX transpose unaligned', @AVXMatrixTransposeUnaligned, 13, 4, 16, 6, False);
  CheckTranspose('AVX transpose unaligned', @AVXMatrixTransposeUnaligned, 7, 9, 11, 12, False);
end;

procedure TvsmathAVXTests.TestTransposeInplace;
const
  cSizes: array[0..4] of NativeInt = (1, 2, 5, 8, 11);
var
  Raw, RawRef: Pointer;
  Mt, Ref: PSingle;
  x, y, n: NativeInt;
begin
  if not AVXReady then
    Exit;
  for n in cSizes do
  begin
    Mt := AllocSingles(n * n + 8, Raw);
    Ref := AllocSingles(n * n, RawRef);
    try
      for y := 0 to n - 1 do
        for x := 0 to n - 1 do
        begin
          Mt[y * n + x] := Single((y * n + x) mod 23) * 0.25;
          Ref[y * n + x] := Mt[y * n + x];
        end;
      Poison(Mt, n * n, n * n + 7);
      AVXMatrixTransposeInplace(Mt, n * SizeOf(Single), n);
      for y := 0 to n - 1 do
        for x := 0 to n - 1 do
          AssertEquals('Inplace N=' + IntToStr(n) + ' [' + IntToStr(x) + ',' +
            IntToStr(y) + ']', Ref[x * n + y], Mt[y * n + x], 0);
      AssertTrue('Inplace N=' + IntToStr(n) + ' wrote past the matrix',
        PadsIntact(Mt, n * n, n * n + 7));
    finally
      FreeMem(Raw); FreeMem(RawRef);
    end;
  end;
end;

{ The SSE unit carries eight entry points (aligned/unaligned x even/odd width
  and height); all of them have to transpose correctly for any size. }
procedure TvsmathAVXTests.TestSSETranspose;
begin
  if not AVXReady then
    Exit;
  CheckTranspose('SSE transpose', @ASMMatrixTransposeAlignedEvenWEvenH, 8, 8, 8, 8, True);
  CheckTranspose('SSE transpose', @ASMMatrixTransposeUnAlignedEvenWEvenH, 5, 3, 5, 3, False);
  CheckTranspose('SSE transpose', @ASMMatrixTransposeUnAlignedEvenWOddH, 6, 5, 6, 5, False);
  CheckTranspose('SSE transpose', @ASMMatrixTransposeUnAlignedOddWEvenH, 7, 4, 7, 4, False);
  CheckTranspose('SSE transpose', @ASMMatrixTransposeUnAlignedOddWOddH, 9, 7, 9, 7, False);
  CheckTranspose('SSE transpose', @ASMMatrixTransposeAlignedEvenWOddH, 8, 5, 8, 8, True);
  CheckTranspose('SSE transpose', @ASMMatrixTransposeAlignedOddWEvenH, 7, 4, 8, 4, True);
  CheckTranspose('SSE transpose', @ASMMatrixTransposeAlignedOddWOddH, 7, 5, 8, 8, True);
  CheckTranspose('SSE transpose', @ASMMatrixTransposeUnAlignedOddWOddH, 11, 3, 13, 4, False);
end;

// ---------------------------------------------------------------------------
// multiplication with a transposed second operand
// ---------------------------------------------------------------------------
// dest[y][k] = sum(x) mt1[y][x] * mt2[k][x]
procedure TvsmathAVXTests.TestMatrixMultTransposed;
var
  RawDest, Raw1, Raw2: Pointer;
  Dest, M1, M2: PSingle;
  W1, H1, H2, y, k, x: NativeInt;
  Acc: Single;
begin
  if not AVXReady then
    Exit;
  W1 := 32;
  H1 := 4;
  H2 := 6;
  Dest := AllocSingles(H1 * H2 + 8, RawDest);
  M1 := AllocSingles(H1 * W1, Raw1);
  M2 := AllocSingles(H2 * W1, Raw2);
  try
    FillDet(M1, H1 * W1);
    FillDet(M2, H2 * W1, 5);
    Poison(Dest, H1 * H2, H1 * H2 + 7);
    AVXMatrixMultAlignedTransposed(Dest, H2 * SizeOf(Single), M1, M2,
      W1, H1, W1, H2, W1 * SizeOf(Single), W1 * SizeOf(Single));
    for y := 0 to H1 - 1 do
      for k := 0 to H2 - 1 do
      begin
        Acc := 0;
        for x := 0 to W1 - 1 do
          Acc := Acc + M1[y * W1 + x] * M2[k * W1 + x];
        AssertEquals('MultTransposed [' + IntToStr(y) + ',' + IntToStr(k) + ']',
          Acc, Dest[y * H2 + k], cEps);
      end;
    AssertTrue('MultTransposed wrote past dest', PadsIntact(Dest, H1 * H2, H1 * H2 + 7));

    { the Mod16 twins need width1 mod 32 = 0 and the height2 parity in their
      name; they write the same result }
    FillChar(Dest^, (H1 * H2 + 8) * SizeOf(Single), 0);
    AVXMatrixMultAlignedEvenW1EvenH2TransposedMod16(Dest, H2 * SizeOf(Single), M1, M2,
      W1, H1, W1, H2, W1 * SizeOf(Single), W1 * SizeOf(Single));
    for y := 0 to H1 - 1 do
      for k := 0 to H2 - 1 do
      begin
        Acc := 0;
        for x := 0 to W1 - 1 do
          Acc := Acc + M1[y * W1 + x] * M2[k * W1 + x];
        AssertEquals('MultTransposed even/even [' + IntToStr(y) + ',' +
          IntToStr(k) + ']', Acc, Dest[y * H2 + k], cEps);
      end;
  finally
    FreeMem(RawDest); FreeMem(Raw1); FreeMem(Raw2);
  end;
end;

// ---------------------------------------------------------------------------
// convolution
// ---------------------------------------------------------------------------
// The kernels get A shifted by (bLen - 1) and read (bLen - 1) elements in front
// of it, so over the raw buffer the reference is a plain correlation:
//   dest[i] = sum(k = 0..bLen - 1) A[i + k] * B[k]
procedure RefConvolve(ADest, A, B: PSingle; aLen, bLen: NativeInt);
var
  i, k: NativeInt;
  Acc: Single;
begin
  for i := 0 to aLen - 1 do
  begin
    Acc := 0;
    for k := 0 to bLen - 1 do
      Acc := Acc + A[i + k] * B[k];
    ADest[i] := Acc;
  end;
end;

type
  TConvolveProc = procedure(dest : PSingle; A, B : PSingle; aLen, bLen : NativeInt);

procedure TvsmathAVXTests.TestVecConvolve;
const
  { 0 = empty filter, 1 and 7 have no full eight lane block, 8/9/16 do }
  cBLens: array[0..6] of NativeInt = (0, 1, 3, 7, 8, 9, 16);
  cLead = 16;                     { readable elements in front of A }
var
  RawA, RawB, RawDest, RawRef: Pointer;
  A, B, Dest, Ref, AStart: PSingle;
  aLen, bLen, i: NativeInt;

  procedure Run(const AName: string; AProc: TConvolveProc);
  var
    j: NativeInt;
  begin
    for j := 0 to aLen - 1 do
      Dest[j] := 0;
    Poison(B, bLen, bLen + 7);
    Poison(Dest, aLen, aLen + 7);
    AProc(Dest, AStart, B, aLen, bLen);
    for j := 0 to aLen - 1 do
      AssertEquals(AName + ' aLen=' + IntToStr(aLen) + ' bLen=' + IntToStr(bLen) +
        ' [' + IntToStr(j) + ']', Ref[j], Dest[j], cEps);
    AssertTrue(AName + ' bLen=' + IntToStr(bLen) + ' wrote past B',
      PadsIntact(B, bLen, bLen + 7));
    AssertTrue(AName + ' bLen=' + IntToStr(bLen) + ' wrote past dest',
      PadsIntact(Dest, aLen, aLen + 7));
  end;

begin
  if not AVXReady then
    Exit;
  aLen := 12;
  A := AllocSingles(cLead + aLen + 8, RawA);
  B := AllocSingles(16 + 8, RawB);
  Dest := AllocSingles(aLen + 8, RawDest);
  Ref := AllocSingles(aLen, RawRef);
  try
    for i := 0 to cLead + aLen - 1 do
      A[i] := Single((i mod 13) - 6) * 0.25;
    for bLen in cBLens do
    begin
      { the kernels read up to (bLen - 1) elements in front of A, so A starts
        (bLen - 1) elements into the buffer - never before it }
      AStart := PSingle(PByte(A) + (bLen - 1) * SizeOf(Single));
      for i := 0 to bLen - 1 do
        B[i] := Single((i mod 7) - 3) * 0.5;
      RefConvolve(Ref, A, B, aLen, bLen);
      Run('AVX convolve', @AVXVecConvolveRevB);
      Run('SSE convolve', @ASMVecConvolveRevB);
      Run('FMA convolve', @FMAVecConvolveRevB);
    end;
  finally
    FreeMem(RawA); FreeMem(RawB); FreeMem(RawDest); FreeMem(RawRef);
  end;
end;

// ---------------------------------------------------------------------------
// row sums and normalization
// ---------------------------------------------------------------------------
procedure TvsmathAVXTests.TestSumRow;
var
  RawSrc, RawDest: Pointer;
  Src, Dest: PSingle;
  x, y: NativeInt;
  Acc: Single;
begin
  if not AVXReady then
    Exit;
  Src := AllocSingles(cW * cH + 8, RawSrc);
  Dest := AllocSingles(cH + 8, RawDest);
  try
    FillDet(Src, cW * cH);
    Poison(Src, cW * cH, cW * cH + 7);
    Poison(Dest, cH, cH + 7);
    { dest is a column vector: one Single per row }
    AVXMatrixSumRowAligned(Dest, SizeOf(Single), Src, cStride, cW, cH);
    for y := 0 to cH - 1 do
    begin
      Acc := 0;
      for x := 0 to cW - 1 do
        Acc := Acc + Src[Idx(cW, x, y)];
      AssertEquals('SumRow y=' + IntToStr(y), Acc, Dest[y], cEps);
    end;
    AssertTrue('SumRow wrote past dest', PadsIntact(Dest, cH, cH + 7));
    AssertTrue('SumRow wrote past the source', PadsIntact(Src, cW * cH, cW * cH + 7));

    { the unaligned twin and a width with a scalar tail }
    AVXMatrixSumRowUnAligned(Dest, SizeOf(Single), Src, cStride, 13, 4);
    for y := 0 to 3 do
    begin
      Acc := 0;
      for x := 0 to 12 do
        Acc := Acc + Src[Idx(cW, x, y)];
      AssertEquals('SumRow unaligned y=' + IntToStr(y), Acc, Dest[y], cEps);
    end;
  finally
    FreeMem(RawSrc); FreeMem(RawDest);
  end;
end;

{ Rows/columns of powers of two have exact norms, so the scaled result is exact
  as well and can be compared without a tolerance. }
procedure FillNormData(AData: PSingle; AW, AH, APitch: NativeInt);
var
  x, y: NativeInt;
begin
  for y := 0 to AH - 1 do
    for x := 0 to AW - 1 do
      AData[y * APitch + x] := Single(1 shl ((y * AW + x) mod 3)) * 0.25;
end;

function RefNorm(AData: PSingle; AW, AH, APitch, AX, AY: NativeInt;
  AColumns: Boolean): Single;
var
  i: NativeInt;
  Sum: Single;
begin
  Sum := 0;
  if AColumns then
  begin
    for i := 0 to AH - 1 do
      Sum := Sum + AData[i * APitch + AX] * AData[i * APitch + AX];
  end
  else
  begin
    for i := 0 to AW - 1 do
      Sum := Sum + AData[AY * APitch + i] * AData[AY * APitch + i];
  end;
  Result := AData[AY * APitch + AX] / Sqrt(Sum);
end;
procedure TvsmathAVXTests.TestNormalizeRow;
const
  cWidths: array[0..2] of NativeInt = (16, 13, 5);
var
  RawSrc, RawDest: Pointer;
  Src, Dest: PSingle;
  x, y, W: NativeInt;
begin
  if not AVXReady then
    Exit;
  for W in cWidths do
  begin
    Src := AllocSingles(cH * cW + 8, RawSrc);
    Dest := AllocSingles(cH * cW + 8, RawDest);
    try
      FillNormData(Src, W, cH, cW);
      Poison(Src, cH * cW, cH * cW + 7);
      Poison(Dest, cH * cW, cH * cW + 7);
      if W = 16 then
        AVXMatrixNormalizeRowAligned(Dest, cStride, Src, cStride, W, cH)
      else
        AVXMatrixNormalizeRowUnAligned(Dest, cStride, Src, cStride, W, cH);
      for y := 0 to cH - 1 do
        for x := 0 to W - 1 do
          AssertEquals('NormalizeRow W=' + IntToStr(W) + ' [' + IntToStr(x) + ',' +
            IntToStr(y) + ']', RefNorm(Src, W, cH, cW, x, y, False),
            Dest[Idx(cW, x, y)], 1e-5);
      AssertTrue('NormalizeRow W=' + IntToStr(W) + ' wrote past dest',
        PadsIntact(Dest, cH * cW, cH * cW + 7));
      AssertTrue('NormalizeRow W=' + IntToStr(W) + ' wrote past the source',
        PadsIntact(Src, cH * cW, cH * cW + 7));
    finally
      FreeMem(RawSrc); FreeMem(RawDest);
    end;
  end;
end;

procedure TvsmathAVXTests.TestNormalizeColumn;
const
  cWidths: array[0..2] of NativeInt = (16, 11, 3);
var
  RawSrc, RawDest: Pointer;
  Src, Dest: PSingle;
  x, y, W: NativeInt;
begin
  if not AVXReady then
    Exit;
  for W in cWidths do
  begin
    Src := AllocSingles(cH * cW + 8, RawSrc);
    Dest := AllocSingles(cH * cW + 8, RawDest);
    try
      FillNormData(Src, W, cH, cW);
      Poison(Src, cH * cW, cH * cW + 7);
      Poison(Dest, cH * cW, cH * cW + 7);
      if W = 16 then
        AVXMatrixNormalizeColumnAligned(Dest, cStride, Src, cStride, W, cH)
      else
        AVXMatrixNormalizeColumnUnAligned(Dest, cStride, Src, cStride, W, cH);
      for y := 0 to cH - 1 do
        for x := 0 to W - 1 do
          AssertEquals('NormalizeColumn W=' + IntToStr(W) + ' [' + IntToStr(x) +
            ',' + IntToStr(y) + ']', RefNorm(Src, W, cH, cW, x, y, True),
            Dest[Idx(cW, x, y)], 1e-5);
      AssertTrue('NormalizeColumn W=' + IntToStr(W) + ' wrote past dest',
        PadsIntact(Dest, cH * cW, cH * cW + 7));
      AssertTrue('NormalizeColumn W=' + IntToStr(W) + ' wrote past the source',
        PadsIntact(Src, cH * cW, cH * cW + 7));
    finally
      FreeMem(RawSrc); FreeMem(RawDest);
    end;
  end;
end;

{ The triangular multiply / rank update family and the FMA vector multiply
  entry points used to be `asm end;` stubs: the call returned without touching
  the destination, so a caller silently worked on stale data. They forward to
  the SSE / AVX kernels now, and that is what these two tests pin down:

    - the forwarder output equals its twin's output element for element, so the
      argument registers really are passed through on this ABI;
    - at least one element differs from the untouched input, which is exactly
      what the old stub failed to do.

  The buffers carry a two element pitch slack so a kernel that rounds a row up
  stays inside the allocation. }
function SameAndChanged(ARes, ATwin, AInput: PSingle; ACount: NativeInt): Boolean;
var
  i: NativeInt;
  Changed: Boolean;
begin
  Changed := False;
  Result := True;
  for i := 0 to ACount - 1 do
  begin
    if ARes[i] <> ATwin[i] then
      Result := False;
    if ARes[i] <> AInput[i] then
      Changed := True;
  end;
  if not Changed then
    Result := False;
end;

procedure TvsmathAVXTests.TestTriaForwarders;
const
  cN = 8;            { square, so every width/height argument is cN }
  cPitch = cN + 2;   { slack so a rounded up row stays in bounds }
var
  RawIn, RawM2, RawDest, RawSse, RawAvx, RawFma: Pointer;
  In_, M2, Dest, Sse, Avx, Fma: PSingle;
  LineWidth, Count: NativeInt;
  Raised: Boolean;
begin
  if not AVXReady then
    Exit;

  LineWidth := cPitch * SizeOf(Single);
  Count := cPitch * cN;
  In_ := AllocSingles(Count, RawIn);
  M2 := AllocSingles(Count, RawM2);
  Dest := AllocSingles(Count, RawDest);
  Sse := AllocSingles(Count, RawSse);
  Avx := AllocSingles(Count, RawAvx);
  Fma := AllocSingles(Count, RawFma);
  try
    FillNormData(In_, cN, cN, cPitch);
    FillNormData(M2, cN, cN, cPitch);
    { dest = mt1 * mt2', mt2 upper triangular }
    Poison(Dest, 0, Count - 1);
    Poison(Sse, 0, Count - 1);
    Poison(Avx, 0, Count - 1);
    ASMMtxMultTria2T1(Dest, LineWidth, In_, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    AVXMtxMultTria2T1(Sse, LineWidth, In_, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    FMAMtxMultTria2T1(Avx, LineWidth, In_, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    AssertTrue('AVXMtxMultTria2T1 delegates to the SSE kernel',
      SameAndChanged(Sse, Dest, In_, Count));
    AssertTrue('FMAMtxMultTria2T1 delegates to the SSE kernel',
      SameAndChanged(Avx, Dest, In_, Count));

    { mt1 = mt1 * mt2, mt2 upper triangular, result stored in mt1 }
    Move(In_^, Sse^, Count * SizeOf(Single));
    Move(In_^, Avx^, Count * SizeOf(Single));
    ASMMtxMultTria2Store1(Sse, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    AVXMtxMultTria2Store1(Avx, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    AssertTrue('AVXMtxMultTria2Store1 delegates to the SSE kernel',
      SameAndChanged(Avx, Sse, In_, Count));

    { mt1 = mt1 * mt2, mt2 upper triangular with a unit diagonal }
    Move(In_^, Sse^, Count * SizeOf(Single));
    Move(In_^, Avx^, Count * SizeOf(Single));
    ASMMtxMultTria2Store1Unit(Sse, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    AVXMtxMultTria2Store1Unit(Avx, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    AssertTrue('AVXMtxMultTria2Store1Unit delegates to the SSE kernel',
      SameAndChanged(Avx, Sse, In_, Count));

    { mt1 = mt1 * mt2', mt2 lower triangular with a unit diagonal }
    Move(In_^, Sse^, Count * SizeOf(Single));
    Move(In_^, Avx^, Count * SizeOf(Single));
    Move(In_^, Fma^, Count * SizeOf(Single));
    ASMMtxMultLowTria2T2Store1(Sse, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    AVXMtxMultLowTria2T2Store1(Avx, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    FMAMtxMultLowTria2T2Store1(Fma, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    AssertTrue('AVXMtxMultLowTria2T2Store1 delegates to the SSE kernel',
      SameAndChanged(Avx, Sse, In_, Count));
    AssertTrue('FMAMtxMultLowTria2T2Store1 delegates to the SSE kernel',
      SameAndChanged(Fma, Sse, In_, Count));

    { dest = mt1 * mt2', mt2 upper triangular with a unit diagonal: the SSE
      kernel's inner dot-product loop cannot terminate (it steps rax by 16 and
      stops on zero, but the x loop breaks the 16 byte alignment), so this whole
      family raises instead of returning stale data or walking off the buffer. }
    Raised := False;
    try
      ASMMtxMultTria2TUpperUnit(Dest, LineWidth, In_, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    except
      on E: ENotImplemented do
        Raised := True;
    end;
    AssertTrue('ASMMtxMultTria2TUpperUnit must fail loudly, not silently', Raised);

    Raised := False;
    try
      AVXMtxMultTria2TUpperUnit(Dest, LineWidth, In_, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    except
      on E: ENotImplemented do
        Raised := True;
    end;
    AssertTrue('AVXMtxMultTria2TUpperUnit must fail loudly, not silently', Raised);

    Raised := False;
    try
      FMAMtxMultTria2TUpperUnit(Dest, LineWidth, In_, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    except
      on E: ENotImplemented do
        Raised := True;
    end;
    AssertTrue('FMAMtxMultTria2TUpperUnit must fail loudly, not silently', Raised);

    { mt1 = mt1 * mt2' with the result stored over the second matrix: the SSE
      kernel faults (it walks past the matrix), so this family raises as well. }
    Raised := False;
    try
      ASMMtxMultTria2T1StoreT1(Sse, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    except
      on E: ENotImplemented do
        Raised := True;
    end;
    AssertTrue('ASMMtxMultTria2T1StoreT1 must fail loudly, not silently', Raised);

    Raised := False;
    try
      AVXMtxMultTria2T1StoreT1(Sse, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    except
      on E: ENotImplemented do
        Raised := True;
    end;
    AssertTrue('AVXMtxMultTria2T1StoreT1 must fail loudly, not silently', Raised);

    Raised := False;
    try
      FMAMtxMultTria2T1StoreT1(Sse, LineWidth, M2, LineWidth, cN, cN, cN, cN);
    except
      on E: ENotImplemented do
        Raised := True;
    end;
    AssertTrue('FMAMtxMultTria2T1StoreT1 must fail loudly, not silently', Raised);

    { C = C - A*B' - B*A' on the upper triangle }
    Move(In_^, Sse^, Count * SizeOf(Single));
    Move(In_^, Avx^, Count * SizeOf(Single));
    ASMSymRank2UpdateUpperUnaligned(Sse, LineWidth, M2, LineWidth, In_, LineWidth, cN, 2);
    AVXSymRank2UpdateUpperUnaligned(Avx, LineWidth, M2, LineWidth, In_, LineWidth, cN, 2);
    AssertTrue('AVXSymRank2UpdateUpperUnaligned delegates to the SSE kernel',
      SameAndChanged(Avx, Sse, In_, Count));
  finally
    FreeMem(RawIn); FreeMem(RawM2); FreeMem(RawDest);
    FreeMem(RawSse); FreeMem(RawAvx); FreeMem(RawFma);
  end;
end;

procedure TvsmathAVXTests.TestFMAVectorMultForwarders;
const
  cN = 8;
  cPitch = cN + 2;
var
  RawMt, RawV, RawX, RawY, RawTwin, RawFma: Pointer;
  Mt, V, X, Y, Twin, Fma: PSingle;
  LineWidth, Count, i: NativeInt;
  Wrote: Boolean;
begin
  if not AVXReady then
    Exit;

  LineWidth := cPitch * SizeOf(Single);
  Count := cPitch * cN;
  Mt := AllocSingles(Count, RawMt);
  V := AllocSingles(cPitch, RawV);
  X := AllocSingles(cPitch, RawX);
  Y := AllocSingles(cPitch, RawY);
  Twin := AllocSingles(Count, RawTwin);
  Fma := AllocSingles(Count, RawFma);
  try
    FillNormData(Mt, cN, cN, cPitch);
    FillNormData(V, 1, cN, 1);
    FillNormData(X, 1, cN, 1);
    FillNormData(Y, 1, cN, 1);

    { FMAMatrixVectMultT -> AVXMatrixVectMultT }
    Poison(Twin, 0, Count - 1);
    Poison(Fma, 0, Count - 1);
    AVXMatrixVectMultT(Twin, LineWidth, Mt, V, LineWidth, SizeOf(Single), cN, cN, 0.5, 0.25);
    FMAMatrixVectMultT(Fma, LineWidth, Mt, V, LineWidth, SizeOf(Single), cN, cN, 0.5, 0.25);
    Wrote := False;
    for i := 0 to Count - 1 do
    begin
      AssertEquals('FMAMatrixVectMultT lane ' + IntToStr(i), Twin[i], Fma[i], 0);
      if Fma[i] <> cPoison then
        Wrote := True;
    end;
    AssertTrue('FMAMatrixVectMultT wrote nothing', Wrote);

    { FMAMatrixVecMultTDestVec -> AVXMatrixVecMultTDestVec (dest is a vector) }
    Poison(Twin, 0, Count - 1);
    Poison(Fma, 0, Count - 1);
    AVXMatrixVecMultTDestVec(Twin, SizeOf(Single), Mt, V, LineWidth, SizeOf(Single), cN, cN, 0.5, 0.25);
    FMAMatrixVecMultTDestVec(Fma, SizeOf(Single), Mt, V, LineWidth, SizeOf(Single), cN, cN, 0.5, 0.25);
    Wrote := False;
    for i := 0 to Count - 1 do
    begin
      AssertEquals('FMAMatrixVecMultTDestVec lane ' + IntToStr(i), Twin[i], Fma[i], 0);
      if Fma[i] <> cPoison then
        Wrote := True;
    end;
    AssertTrue('FMAMatrixVecMultTDestVec wrote nothing', Wrote);

    { the two vect-mult delegates. The aligned twin needs a 32 byte pillared
      pitch (LineWidth = cN * SizeOf(Single)) and 32 byte aligned operands,
      which AllocSingles guarantees; the unaligned twin takes the padded pitch
      the rest of the test uses. }
    FillNormData(Mt, cN, cN, cPitch);
    Poison(Twin, 0, Count - 1);
    Poison(Fma, 0, Count - 1);
    AVXMatrixVectMultUnAlignedVAligned(Twin, SizeOf(Single), Mt, V, LineWidth,
      SizeOf(Single), cN, cN, 0.5, 0.25);
    FMAMatrixVectMultUnAlignedVAligned(Fma, SizeOf(Single), Mt, V, LineWidth,
      SizeOf(Single), cN, cN, 0.5, 0.25);
    Wrote := False;
    for i := 0 to Count - 1 do
    begin
      AssertEquals('FMAMatrixVectMultUnAlignedVAligned lane ' + IntToStr(i),
        Twin[i], Fma[i], 0);
      if Fma[i] <> cPoison then
        Wrote := True;
    end;
    AssertTrue('FMAMatrixVectMultUnAlignedVAligned wrote nothing', Wrote);

    FillNormData(Mt, cN, cN, cN);
    Poison(Twin, 0, Count - 1);
    Poison(Fma, 0, Count - 1);
    AVXMatrixVectMultAlignedVAligned(Twin, SizeOf(Single), Mt, V,
      cN * SizeOf(Single), SizeOf(Single), cN, cN, 0.5, 0.25);
    FMAMatrixVectMultAlignedVAligned(Fma, SizeOf(Single), Mt, V,
      cN * SizeOf(Single), SizeOf(Single), cN, cN, 0.5, 0.25);
    Wrote := False;
    for i := 0 to Count - 1 do
    begin
      AssertEquals('FMAMatrixVectMultAlignedVAligned lane ' + IntToStr(i),
        Twin[i], Fma[i], 0);
      if Fma[i] <> cPoison then
        Wrote := True;
    end;
    AssertTrue('FMAMatrixVectMultAlignedVAligned wrote nothing', Wrote);

    { the two rank-1 update forwarders }
    Move(Mt^, Twin^, Count * SizeOf(Single));
    Move(Mt^, Fma^, Count * SizeOf(Single));
    AVXRank1UpdateSeq(Twin, LineWidth, cN, cN, X, Y, SizeOf(Single), SizeOf(Single), 0.5);
    FMARank1UpdateSeq(Fma, LineWidth, cN, cN, X, Y, SizeOf(Single), SizeOf(Single), 0.5);
    AssertTrue('FMARank1UpdateSeq delegates to the AVX kernel',
      SameAndChanged(Fma, Twin, Mt, Count));

    Move(Mt^, Twin^, Count * SizeOf(Single));
    Move(Mt^, Fma^, Count * SizeOf(Single));
    AVXRank1UpdateSeqAligned(Twin, LineWidth, cN, cN, X, Y, SizeOf(Single), SizeOf(Single), 0.5);
    FMARank1UpdateSeqAligned(Fma, LineWidth, cN, cN, X, Y, SizeOf(Single), SizeOf(Single), 0.5);
    AssertTrue('FMARank1UpdateSeqAligned delegates to the AVX kernel',
      SameAndChanged(Fma, Twin, Mt, Count));
  finally
    FreeMem(RawMt); FreeMem(RawV); FreeMem(RawX); FreeMem(RawY);
    FreeMem(RawTwin); FreeMem(RawFma);
  end;
end;

{$ENDIF}

initialization
{$IFDEF CPUX64}
  RegisterTest(TvsmathAVXTests);
{$ENDIF}
end.

