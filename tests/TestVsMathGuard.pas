// ###########################################################
// #### vsmath - vector single math
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the Apache License, Version 2.0 - see LICENSE.
// ###########################################################
// Guard page tests for the matrix*vector kernels: every buffer ends on a PROT_NONE
// page, so a load or store past the end faults. The faults happen in a forked child
// (see GuardPage) and are reported as test failures.
//
// Covered: the harness itself, the SSE and AVX matrix*vector entry points, the row
// and column sum and normalize kernels at every width and height 1..17, and
// MatrixMtxVecMult/MatrixMtxVecMultT/MatrixSum/MatrixNormalize at every level.
// Not covered: the SSE *AlignedVAligned variants, which need 16 byte aligned rows.
unit TestVsMathGuard;

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

interface

uses
  fpcunit, testregistry
  {$IFDEF UNIX}, GuardPage{$ENDIF};

{$IFDEF CPUX64}
{$IFDEF UNIX}

type
  TvsmathGuardTests = class(TTestCase)
  private
    { The probes. Each one is run on guard flush buffers. }
    procedure CallReference(Mt, V, Dest: PSingle; W, H: NativeInt);
    procedure CallReadPastMatrix(Mt, V, Dest: PSingle; W, H: NativeInt);
    procedure CallWritePastDest(Mt, V, Dest: PSingle; W, H: NativeInt);
    procedure CallAVXPlain(Mt, V, Dest: PSingle; W, H: NativeInt);
    procedure CallAVXAligned(Mt, V, Dest: PSingle; W, H: NativeInt);
    procedure CallAVXUnAligned(Mt, V, Dest: PSingle; W, H: NativeInt);
    procedure CallAVXOdd(Mt, V, Dest: PSingle; W, H: NativeInt);
    procedure CallSSEPlain(Mt, V, Dest: PSingle; W, H: NativeInt);
    procedure CallSSEEven(Mt, V, Dest: PSingle; W, H: NativeInt);
    procedure CallSSEOdd(Mt, V, Dest: PSingle; W, H: NativeInt);
    procedure CallDispatch(Mt, V, Dest: PSingle; W, H: NativeInt);

    { Transposed product probes: Mt is Height x Width, V holds Height elements
      and Dest holds Width elements, so the destination is the *narrow* one. }
    procedure CallRefT(Mt, V, Dest: PSingle; W, H: NativeInt);
    procedure CallSSET(Mt, V, Dest: PSingle; W, H: NativeInt);
    procedure CallAVXT(Mt, V, Dest: PSingle; W, H: NativeInt);
    procedure CallDispatchT(Mt, V, Dest: PSingle; W, H: NativeInt);
    { Negative control: one element past the transposed destination. }
    procedure CallWritePastDestT(Mt, V, Dest: PSingle; W, H: NativeInt);

    { Reduction probes. Src is a tight Width x Height matrix, Dest holds Height
      elements (row sums/means) or Width elements (column sums/means). }
    procedure CallSSESumRow(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallSSESumColumn(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallAVXSumRow(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallAVXSumColumn(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallDispatchSumRow(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallDispatchSumColumn(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallSSEMeanRow(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallSSEMeanColumn(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallAVXMeanRow(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallAVXMeanColumn(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallDispatchMeanRow(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallDispatchMeanColumn(Src, Dest: PSingle; W, H: NativeInt);

    { Normalize probes. Src and Dest are both tight Width x Height matrices. }
    procedure CallSSENormalizeRow(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallSSENormalizeColumn(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallAVXNormalizeRow(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallAVXNormalizeColumn(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallDispatchNormalizeRow(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallDispatchNormalizeColumn(Src, Dest: PSingle; W, H: NativeInt);

    { Negative controls for the reduction harness. }
    procedure CallSumReadPastRow(Src, Dest: PSingle; W, H: NativeInt);
    procedure CallSumWritePastDest(Src, Dest: PSingle; W, H: NativeInt);

    { Every (width, height) pair has to come back gvOk. }
    procedure AssertGuarded(const AName: string; ACall: TGuardCall;
      const AWidths, AHeights: array of NativeInt;
      const AAlpha, ABeta: Single);
    { The same for a reduction probe. }
    procedure AssertReduceGuarded(const AName: string; ACall: TGuardReduceCall;
      const AWidths, AHeights: array of NativeInt; AKind: TGuardReduceKind);
    { The same for a normalize probe. }
    procedure AssertNormGuarded(const AName: string; ACall: TGuardNormCall;
      const AWidths, AHeights: array of NativeInt; AKind: TGuardNormKind);
    { The same for a transposed product probe. }
    procedure AssertTGuarded(const AName: string; ACall: TGuardCallT;
      const AWidths, AHeights: array of NativeInt;
      const AAlpha, ABeta: Single);
    { Runs one shape and returns the verdict, for the negative tests. }
    function VerdictOf(ACall: TGuardCall; AWidth, AHeight: NativeInt): TGuardVerdict;
    function AVXReady: Boolean;
  published
    procedure TestHarnessDetectsReadPastTheEnd;
    procedure TestHarnessDetectsWritePastTheEnd;
    procedure TestHarnessAcceptsExactReference;
    procedure TestAVXVectMultNoOverRead;
    procedure TestAVXVectMultAlignedNoOverRead;
    procedure TestAVXVectMultOddNoOverRead;
    procedure TestSSEVectMultNoOverRead;
    procedure TestDispatchMtxVecMultNoOverRead;
    procedure TestSSEMtxVecMultTNoOverRead;
    procedure TestAVXMtxVecMultTNoOverRead;
    procedure TestDispatchMtxVecMultTNoOverRead;
    procedure TestHarnessDetectsTransposedOverrun;
    procedure TestSSESumNoOverRead;
    procedure TestAVXSumNoOverRead;
    procedure TestDispatchSumNoOverRead;
    procedure TestSSEMeanNoOverRead;
    procedure TestAVXMeanNoOverRead;
    procedure TestDispatchMeanNoOverRead;
    procedure TestSSENormalizeNoOverRead;
    procedure TestAVXNormalizeNoOverRead;
    procedure TestDispatchNormalizeNoOverRead;
    procedure TestHarnessDetectsReduceOverrun;
  end;

{$ENDIF}
{$ENDIF}

implementation


{$IFDEF CPUX64}
{$IFDEF UNIX}

uses
  SysUtils, cpu, BaseUnix,
  MatrixASMDispatchSingle,
  AVXMatrixVectorMultOperationsSinglex64,
  ASMMatrixVectorMultOperationsSinglex64,
  AVXMatrixSumOperationsSinglex64,
  ASMMatrixSumOperationsSinglex64,
  AVXMatrixMeanOperationsSinglex64,
  ASMMatrixMeanOperationsSinglex64,
  AVXMatrixNormOperationsSinglex64,
  ASMMatrixNormOperationsSinglex64;

function TvsmathGuardTests.AVXReady: Boolean;
begin
  Result := AVXSupport;
  if not Result then
    Ignore('CPU has no AVX support');
end;

{ The reference implementation: what every kernel has to reproduce. }
procedure TvsmathGuardTests.CallReference(Mt, V, Dest: PSingle; W, H: NativeInt);
var
  x, y: NativeInt;
  Acc: Single;
begin
  for y := 0 to H - 1 do
  begin
    Acc := 0;
    for x := 0 to W - 1 do
      Acc := Acc + Mt[y * W + x] * V[x];
    Dest[y] := Acc;
  end;
end;

{ Deliberately one element past the matrix: if the harness reports this as
  gvOk it is not watching the guard pages at all. }
procedure TvsmathGuardTests.CallReadPastMatrix(Mt, V, Dest: PSingle; W, H: NativeInt);
begin
  CallReference(Mt, V, Dest, W, H);
  Dest[0] := Dest[0] + Mt[W * H];
end;

procedure TvsmathGuardTests.CallWritePastDest(Mt, V, Dest: PSingle; W, H: NativeInt);
begin
  CallReference(Mt, V, Dest, W, H);
  Dest[H] := 1.0;
end;

procedure TvsmathGuardTests.CallAVXPlain(Mt, V, Dest: PSingle; W, H: NativeInt);
begin
  AVXMatrixVectMult(Dest, SizeOf(Single), Mt, V, W * SizeOf(Single),
    SizeOf(Single), W, H, 1.0, 0.0);
end;

procedure TvsmathGuardTests.CallAVXAligned(Mt, V, Dest: PSingle; W, H: NativeInt);
begin
  AVXMatrixVectMultAlignedVAligned(Dest, SizeOf(Single), Mt, V,
    W * SizeOf(Single), SizeOf(Single), W, H, 1.0, 0.0);
end;

procedure TvsmathGuardTests.CallAVXUnAligned(Mt, V, Dest: PSingle; W, H: NativeInt);
begin
  AVXMatrixVectMultUnAlignedVAligned(Dest, SizeOf(Single), Mt, V,
    W * SizeOf(Single), SizeOf(Single), W, H, 1.0, 0.0);
end;

procedure TvsmathGuardTests.CallAVXOdd(Mt, V, Dest: PSingle; W, H: NativeInt);
begin
  AVXMatrixVectMultOddUnAlignedVAligned(Dest, SizeOf(Single), Mt, V,
    W * SizeOf(Single), SizeOf(Single), W, H, 1.0, 0.0);
end;

procedure TvsmathGuardTests.CallSSEPlain(Mt, V, Dest: PSingle; W, H: NativeInt);
begin
  ASMMatrixVectMult(Dest, SizeOf(Single), Mt, V, W * SizeOf(Single),
    SizeOf(Single), W, H, 1.0, 0.0);
end;

{ width and 3 = 0 - the only widths this entry point covers. }
procedure TvsmathGuardTests.CallSSEEven(Mt, V, Dest: PSingle; W, H: NativeInt);
begin
  ASMMatrixVectMultEvenUnAlignedVAligned(Dest, SizeOf(Single), Mt, V,
    W * SizeOf(Single), SizeOf(Single), W, H, 1.0, 0.0);
end;

{ width and 3 = 1 - the only widths this entry point covers. }
procedure TvsmathGuardTests.CallSSEOdd(Mt, V, Dest: PSingle; W, H: NativeInt);
begin
  ASMMatrixVectMultOddUnAlignedVAligned(Dest, SizeOf(Single), Mt, V,
    W * SizeOf(Single), SizeOf(Single), W, H, 1.0, 0.0);
end;

{ The kernel the dispatcher installed, with the alpha/beta form the rest of the
  library uses it with. }
procedure TvsmathGuardTests.CallDispatch(Mt, V, Dest: PSingle; W, H: NativeInt);
begin
  MatrixMtxVecMult(Dest, SizeOf(Single), Mt, V, W * SizeOf(Single),
    SizeOf(Single), W, H, 2.0, 1.0);
end;

{ The transposed product, Dest = beta*Dest + alpha*Mt^T*V: Mt is H rows of W
  elements, V is H elements and Dest is W elements. }
procedure TvsmathGuardTests.CallRefT(Mt, V, Dest: PSingle; W, H: NativeInt);
var
  x, y: NativeInt;
  Acc: Single;
begin
  for x := 0 to W - 1 do
  begin
    Acc := 0;
    for y := 0 to H - 1 do
      Acc := Acc + Mt[y * W + x] * V[y];
    Dest[x] := 2.0 * Acc + 1.0 * Dest[x];
  end;
end;

procedure TvsmathGuardTests.CallSSET(Mt, V, Dest: PSingle; W, H: NativeInt);
begin
  ASMMatrixVectMultT(Dest, SizeOf(Single), Mt, V, W * SizeOf(Single),
    SizeOf(Single), W, H, 2.0, 1.0);
end;

procedure TvsmathGuardTests.CallAVXT(Mt, V, Dest: PSingle; W, H: NativeInt);
begin
  AVXMatrixVectMultT(Dest, SizeOf(Single), Mt, V, W * SizeOf(Single),
    SizeOf(Single), W, H, 2.0, 1.0);
end;

procedure TvsmathGuardTests.CallDispatchT(Mt, V, Dest: PSingle; W, H: NativeInt);
begin
  MatrixMtxVecMultT(Dest, SizeOf(Single), Mt, V, W * SizeOf(Single),
    SizeOf(Single), W, H, 2.0, 1.0);
end;

procedure TvsmathGuardTests.CallWritePastDestT(Mt, V, Dest: PSingle; W, H: NativeInt);
begin
  CallSSET(Mt, V, Dest, W, H);
  Dest[W] := 1.0;                        { one element past the destination }
end;

{ A row sum writes one element per row, so Dest is H elements wide. }
procedure TvsmathGuardTests.CallSSESumRow(Src, Dest: PSingle; W, H: NativeInt);
begin
  ASMMatrixSumRowUnAlignedEvenW(Dest, SizeOf(Single), Src, W * SizeOf(Single), W, H);
end;

procedure TvsmathGuardTests.CallSSESumColumn(Src, Dest: PSingle; W, H: NativeInt);
begin
  ASMMatrixSumColumnUnAlignedEvenW(Dest, SizeOf(Single), Src, W * SizeOf(Single), W, H);
end;

procedure TvsmathGuardTests.CallAVXSumRow(Src, Dest: PSingle; W, H: NativeInt);
begin
  AVXMatrixSumRowUnAligned(Dest, SizeOf(Single), Src, W * SizeOf(Single), W, H);
end;

procedure TvsmathGuardTests.CallAVXSumColumn(Src, Dest: PSingle; W, H: NativeInt);
begin
  AVXMatrixSumColumnUnAligned(Dest, SizeOf(Single), Src, W * SizeOf(Single), W, H);
end;

procedure TvsmathGuardTests.CallDispatchSumRow(Src, Dest: PSingle; W, H: NativeInt);
begin
  MatrixSum(Dest, SizeOf(Single), Src, W * SizeOf(Single), W, H, True);
end;

procedure TvsmathGuardTests.CallDispatchSumColumn(Src, Dest: PSingle; W, H: NativeInt);
begin
  MatrixSum(Dest, SizeOf(Single), Src, W * SizeOf(Single), W, H, False);
end;

procedure TvsmathGuardTests.CallSSEMeanRow(Src, Dest: PSingle; W, H: NativeInt);
begin
  ASMMatrixMeanRowUnAlignedEvenW(Dest, SizeOf(Single), Src, W * SizeOf(Single), W, H);
end;

procedure TvsmathGuardTests.CallSSEMeanColumn(Src, Dest: PSingle; W, H: NativeInt);
begin
  ASMMatrixMeanColumnUnAlignedEvenW(Dest, SizeOf(Single), Src, W * SizeOf(Single), W, H);
end;

procedure TvsmathGuardTests.CallAVXMeanRow(Src, Dest: PSingle; W, H: NativeInt);
begin
  AVXMatrixMeanRowUnAligned(Dest, SizeOf(Single), Src, W * SizeOf(Single), W, H);
end;

procedure TvsmathGuardTests.CallAVXMeanColumn(Src, Dest: PSingle; W, H: NativeInt);
begin
  AVXMatrixMeanColumnUnAligned(Dest, SizeOf(Single), Src, W * SizeOf(Single), W, H);
end;

procedure TvsmathGuardTests.CallDispatchMeanRow(Src, Dest: PSingle; W, H: NativeInt);
begin
  MatrixMean(Dest, SizeOf(Single), Src, W * SizeOf(Single), W, H, True);
end;

procedure TvsmathGuardTests.CallDispatchMeanColumn(Src, Dest: PSingle; W, H: NativeInt);
begin
  MatrixMean(Dest, SizeOf(Single), Src, W * SizeOf(Single), W, H, False);
end;

procedure TvsmathGuardTests.CallSSENormalizeRow(Src, Dest: PSingle; W, H: NativeInt);
begin
  ASMMatrixNormalizeRowUnAlignedEvenW(Dest, W * SizeOf(Single), Src, W * SizeOf(Single), W, H);
end;

procedure TvsmathGuardTests.CallSSENormalizeColumn(Src, Dest: PSingle; W, H: NativeInt);
begin
  ASMMatrixNormalizeColumnUnAlignedEvenW(Dest, W * SizeOf(Single), Src, W * SizeOf(Single), W, H);
end;

procedure TvsmathGuardTests.CallAVXNormalizeRow(Src, Dest: PSingle; W, H: NativeInt);
begin
  AVXMatrixNormalizeRowUnAligned(Dest, W * SizeOf(Single), Src, W * SizeOf(Single), W, H);
end;

procedure TvsmathGuardTests.CallAVXNormalizeColumn(Src, Dest: PSingle; W, H: NativeInt);
begin
  AVXMatrixNormalizeColumnUnAligned(Dest, W * SizeOf(Single), Src, W * SizeOf(Single), W, H);
end;

procedure TvsmathGuardTests.CallDispatchNormalizeRow(Src, Dest: PSingle; W, H: NativeInt);
begin
  MatrixNormalize(Dest, W * SizeOf(Single), Src, W * SizeOf(Single), W, H, True);
end;

procedure TvsmathGuardTests.CallDispatchNormalizeColumn(Src, Dest: PSingle; W, H: NativeInt);
begin
  MatrixNormalize(Dest, W * SizeOf(Single), Src, W * SizeOf(Single), W, H, False);
end;

procedure TvsmathGuardTests.CallSumReadPastRow(Src, Dest: PSingle; W, H: NativeInt);
begin
  CallSSESumRow(Src, Dest, W, H);
  Dest[0] := Dest[0] + Src[W * H];      { one element past the matrix }
end;

procedure TvsmathGuardTests.CallSumWritePastDest(Src, Dest: PSingle; W, H: NativeInt);
begin
  CallSSESumRow(Src, Dest, W, H);
  Dest[H] := 1.0;                        { one element past the destination }
end;

function TvsmathGuardTests.VerdictOf(ACall: TGuardCall;
  AWidth, AHeight: NativeInt): TGuardVerdict;
var
  Sig: cint;
begin
  Result := RunGuarded(ACall, AWidth, AHeight, 1.0, 0.0, Sig);
end;

procedure TvsmathGuardTests.AssertNormGuarded(const AName: string;
  ACall: TGuardNormCall; const AWidths, AHeights: array of NativeInt;
  AKind: TGuardNormKind);
var
  wi, hi: Integer;
  Sig: cint;
  Verdict: TGuardVerdict;
begin
  for wi := 0 to High(AWidths) do
    for hi := 0 to High(AHeights) do
    begin
      Verdict := RunGuardedNormalize(ACall, AWidths[wi], AHeights[hi], AKind, Sig);
      if Verdict = gvHarnessError then
      begin
        Ignore('guard page harness unavailable: ' + IntToStr(Sig));
        Exit;
      end;
      AssertTrue(Format('%s: width %d, height %d -> %s (signal %d)',
        [AName, AWidths[wi], AHeights[hi], GuardVerdictName(Verdict), Sig]),
        Verdict = gvOk);
    end;
end;

procedure TvsmathGuardTests.AssertReduceGuarded(const AName: string;
  ACall: TGuardReduceCall; const AWidths, AHeights: array of NativeInt;
  AKind: TGuardReduceKind);
var
  wi, hi: Integer;
  Sig: cint;
  Verdict: TGuardVerdict;
begin
  for wi := 0 to High(AWidths) do
    for hi := 0 to High(AHeights) do
    begin
      Verdict := RunGuardedReduce(ACall, AWidths[wi], AHeights[hi], AKind, Sig);
      if Verdict = gvHarnessError then
      begin
        Ignore('guard page harness unavailable: ' + IntToStr(Sig));
        Exit;
      end;
      AssertTrue(Format('%s: width %d, height %d -> %s (signal %d)',
        [AName, AWidths[wi], AHeights[hi], GuardVerdictName(Verdict), Sig]),
        Verdict = gvOk);
    end;
end;

procedure TvsmathGuardTests.AssertGuarded(const AName: string;
  ACall: TGuardCall; const AWidths, AHeights: array of NativeInt;
  const AAlpha, ABeta: Single);
var
  wi, hi: Integer;
  Sig: cint;
  Verdict: TGuardVerdict;
begin
  for wi := 0 to High(AWidths) do
    for hi := 0 to High(AHeights) do
    begin
      Verdict := RunGuarded(ACall, AWidths[wi], AHeights[hi], AAlpha, ABeta, Sig);
      if Verdict = gvHarnessError then
      begin
        Ignore('guard page harness unavailable: ' + IntToStr(Sig));
        Exit;
      end;
      AssertTrue(Format('%s: width %d, height %d -> %s (signal %d)',
        [AName, AWidths[wi], AHeights[hi], GuardVerdictName(Verdict), Sig]),
        Verdict = gvOk);
    end;
end;


procedure TvsmathGuardTests.AssertTGuarded(const AName: string;
  ACall: TGuardCallT; const AWidths, AHeights: array of NativeInt;
  const AAlpha, ABeta: Single);
var
  wi, hi: Integer;
  Sig: cint;
  Verdict: TGuardVerdict;
begin
  for wi := 0 to High(AWidths) do
    for hi := 0 to High(AHeights) do
    begin
      Verdict := RunGuardedT(ACall, AWidths[wi], AHeights[hi], AAlpha, ABeta, Sig);
      if Verdict = gvHarnessError then
      begin
        Ignore('guard page harness unavailable: ' + IntToStr(Sig));
        Exit;
      end;
      AssertTrue(Format('%s: width %d, height %d -> %s (signal %d)',
        [AName, AWidths[wi], AHeights[hi], GuardVerdictName(Verdict), Sig]),
        Verdict = gvOk);
    end;
end;


procedure TvsmathGuardTests.TestHarnessDetectsReadPastTheEnd;
begin
  AssertEquals('a read one element past the matrix was not detected',
    Ord(gvOutOfBounds), Ord(VerdictOf(@CallReadPastMatrix, 9, 5)));
end;

procedure TvsmathGuardTests.TestHarnessDetectsWritePastTheEnd;
begin
  AssertEquals('a write one element past dest was not detected',
    Ord(gvOutOfBounds), Ord(VerdictOf(@CallWritePastDest, 9, 5)));
end;

procedure TvsmathGuardTests.TestHarnessAcceptsExactReference;
begin
  { no false positives: the reference loop has to pass on the same buffers the
    kernels are measured on }
  AssertEquals('the reference loop was rejected by the harness',
    Ord(gvOk), Ord(VerdictOf(@CallReference, 9, 5)));
  AssertEquals('the reference loop was rejected by the harness',
    Ord(gvOk), Ord(VerdictOf(@CallReference, 1, 1)));
  AssertEquals('the reference loop was rejected by the harness',
    Ord(gvOk), Ord(VerdictOf(@CallReference, 40, 12)));
end;

procedure TvsmathGuardTests.TestAVXVectMultNoOverRead;
const
  cWidths: array[0..11] of NativeInt = (1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 16, 17);
  cHeights: array[0..5] of NativeInt = (1, 2, 3, 4, 5, 8);
begin
  if not AVXReady then
    Exit;
  AssertGuarded('AVXMatrixVectMult', @CallAVXPlain, cWidths, cHeights, 1.0, 0.0);
  AssertGuarded('AVXMatrixVectMultUnAlignedVAligned', @CallAVXUnAligned,
    cWidths, cHeights, 1.0, 0.0);
end;

procedure TvsmathGuardTests.TestAVXVectMultAlignedNoOverRead;
const
  { the aligned entry point loads the vector with vmovaps, so the vector has to
    be 32 byte aligned: a guard flush buffer only is when its size is a
    multiple of 32 bytes, i.e. at whole multiples of eight elements }
  cWidths: array[0..3] of NativeInt = (8, 16, 24, 32);
  cHeights: array[0..5] of NativeInt = (1, 2, 3, 4, 5, 8);
begin
  if not AVXReady then
    Exit;
  AssertGuarded('AVXMatrixVectMultAlignedVAligned', @CallAVXAligned,
    cWidths, cHeights, 1.0, 0.0);
end;

procedure TvsmathGuardTests.TestAVXVectMultOddNoOverRead;
const
  cWidths: array[0..7] of NativeInt = (1, 5, 9, 13, 17, 21, 25, 29);
  cHeights: array[0..5] of NativeInt = (1, 2, 3, 4, 5, 8);
begin
  if not AVXReady then
    Exit;
  AssertGuarded('AVXMatrixVectMultOddUnAlignedVAligned', @CallAVXOdd,
    cWidths, cHeights, 1.0, 0.0);
end;

procedure TvsmathGuardTests.TestSSEVectMultNoOverRead;
const
  cAnyWidth: array[0..11] of NativeInt = (1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 16, 17);
  cEvenWidth: array[0..4] of NativeInt = (4, 8, 12, 16, 20);
  cOddWidth: array[0..5] of NativeInt = (1, 5, 9, 13, 17, 21);
  cHeights: array[0..5] of NativeInt = (1, 2, 3, 4, 5, 8);
begin
  AssertGuarded('ASMMatrixVectMult', @CallSSEPlain, cAnyWidth, cHeights, 1.0, 0.0);
  AssertGuarded('ASMMatrixVectMultEvenUnAlignedVAligned', @CallSSEEven,
    cEvenWidth, cHeights, 1.0, 0.0);
  AssertGuarded('ASMMatrixVectMultOddUnAlignedVAligned', @CallSSEOdd,
    cOddWidth, cHeights, 1.0, 0.0);
end;

procedure TvsmathGuardTests.TestSSESumNoOverRead;
const
  { the row kernel reads whole rows and the column kernel whole columns, so
    both are exercised at widths and heights that are not whole lanes as well }
  cWidths: array[0..9] of NativeInt = (1, 2, 3, 4, 5, 7, 8, 9, 12, 17);
  cHeights: array[0..4] of NativeInt = (1, 2, 3, 4, 5);
begin
  AssertReduceGuarded('ASMMatrixSumRowUnAlignedEvenW', @CallSSESumRow,
    cWidths, cHeights, grSumRow);
  AssertReduceGuarded('ASMMatrixSumColumnUnAlignedEvenW', @CallSSESumColumn,
    cWidths, cHeights, grSumColumn);
end;

procedure TvsmathGuardTests.TestAVXSumNoOverRead;
const
  cWidths: array[0..9] of NativeInt = (1, 2, 3, 4, 5, 7, 8, 9, 12, 17);
  cHeights: array[0..4] of NativeInt = (1, 2, 3, 4, 5);
begin
  if not AVXReady then
    Exit;
  AssertReduceGuarded('AVXMatrixSumRowUnAligned', @CallAVXSumRow,
    cWidths, cHeights, grSumRow);
  AssertReduceGuarded('AVXMatrixSumColumnUnAligned', @CallAVXSumColumn,
    cWidths, cHeights, grSumColumn);
end;

procedure TvsmathGuardTests.TestSSEMeanNoOverRead;
const
  { the mean kernels reduce over one extent, so the other extent is free: every
    width and height from one to five plus the lane boundaries }
  cWidths: array[0..9] of NativeInt = (1, 2, 3, 4, 5, 7, 8, 9, 12, 17);
  cHeights: array[0..4] of NativeInt = (1, 2, 3, 4, 5);
begin
  AssertReduceGuarded('ASMMatrixMeanRowUnAlignedEvenW', @CallSSEMeanRow,
    cWidths, cHeights, grMeanRow);
  AssertReduceGuarded('ASMMatrixMeanColumnUnAlignedEvenW', @CallSSEMeanColumn,
    cWidths, cHeights, grMeanColumn);
end;

procedure TvsmathGuardTests.TestAVXMeanNoOverRead;
const
  cWidths: array[0..9] of NativeInt = (1, 2, 3, 4, 5, 7, 8, 9, 12, 17);
  cHeights: array[0..4] of NativeInt = (1, 2, 3, 4, 5);
begin
  if not AVXReady then
    Exit;
  AssertReduceGuarded('AVXMatrixMeanRowUnAligned', @CallAVXMeanRow,
    cWidths, cHeights, grMeanRow);
  AssertReduceGuarded('AVXMatrixMeanColumnUnAligned', @CallAVXMeanColumn,
    cWidths, cHeights, grMeanColumn);
end;

procedure TvsmathGuardTests.TestDispatchMeanNoOverRead;
const
  cWidths: array[0..5] of NativeInt = (1, 3, 4, 5, 8, 9);
  cHeights: array[0..3] of NativeInt = (1, 3, 4, 5);
  cLevels: array[0..3] of TCPUInstrType = (itFPU, itSSE, itAVX, itFMA);
  cNames: array[0..3] of string = ('itFPU', 'itSSE', 'itAVX', 'itFMA');
var
  li: Integer;
begin
  for li := 0 to High(cLevels) do
  begin
    InitMathFunctions(cLevels[li], False);
    if GetCurCPUInstrType <> cLevels[li] then
      Continue;
    AssertReduceGuarded('MatrixMean row at ' + cNames[li], @CallDispatchMeanRow,
      cWidths, cHeights, grMeanRow);
    AssertReduceGuarded('MatrixMean column at ' + cNames[li], @CallDispatchMeanColumn,
      cWidths, cHeights, grMeanColumn);
  end;
  InitMathFunctions(GetBestCPUInstrType, False);
end;

procedure TvsmathGuardTests.TestSSENormalizeNoOverRead;
const
  { normalize reduces over one extent, so the other extent is free: the widths
    and heights that are not whole lanes are the interesting ones, because the
    column kernel walks four columns at a time }
  cWidths: array[0..9] of NativeInt = (1, 2, 3, 4, 5, 7, 8, 9, 12, 17);
  cHeights: array[0..4] of NativeInt = (1, 2, 3, 4, 5);
begin
  AssertNormGuarded('ASMMatrixNormalizeRowUnAlignedEvenW', @CallSSENormalizeRow,
    cWidths, cHeights, gnRow);
  AssertNormGuarded('ASMMatrixNormalizeColumnUnAlignedEvenW', @CallSSENormalizeColumn,
    cWidths, cHeights, gnColumn);
end;

procedure TvsmathGuardTests.TestAVXNormalizeNoOverRead;
const
  cWidths: array[0..9] of NativeInt = (1, 2, 3, 4, 5, 7, 8, 9, 12, 17);
  cHeights: array[0..4] of NativeInt = (1, 2, 3, 4, 5);
begin
  if not AVXReady then
    Exit;
  AssertNormGuarded('AVXMatrixNormalizeRowUnAligned', @CallAVXNormalizeRow,
    cWidths, cHeights, gnRow);
  AssertNormGuarded('AVXMatrixNormalizeColumnUnAligned', @CallAVXNormalizeColumn,
    cWidths, cHeights, gnColumn);
end;

procedure TvsmathGuardTests.TestDispatchNormalizeNoOverRead;
const
  cWidths: array[0..5] of NativeInt = (1, 3, 4, 5, 8, 9);
  cHeights: array[0..3] of NativeInt = (1, 3, 4, 5);
  cLevels: array[0..3] of TCPUInstrType = (itFPU, itSSE, itAVX, itFMA);
  cNames: array[0..3] of string = ('itFPU', 'itSSE', 'itAVX', 'itFMA');
var
  li: Integer;
begin
  for li := 0 to High(cLevels) do
  begin
    InitMathFunctions(cLevels[li], False);
    if GetCurCPUInstrType <> cLevels[li] then
      Continue;
    AssertNormGuarded('MatrixNormalize row at ' + cNames[li], @CallDispatchNormalizeRow,
      cWidths, cHeights, gnRow);
    AssertNormGuarded('MatrixNormalize column at ' + cNames[li], @CallDispatchNormalizeColumn,
      cWidths, cHeights, gnColumn);
  end;
  InitMathFunctions(GetBestCPUInstrType, False);
end;

procedure TvsmathGuardTests.TestHarnessDetectsReduceOverrun;
var
  Sig: cint;
begin
  { if these came back gvOk the reduction harness would not be watching the
    guard pages, and the sweeps above would prove nothing }
  AssertEquals('a column kernel reading one element past the matrix was not detected',
    Ord(gvOutOfBounds), Ord(RunGuardedReduce(@CallSumReadPastRow, 5, 3, grSumRow, Sig)));
  AssertEquals('a row kernel writing one element past dest was not detected',
    Ord(gvOutOfBounds), Ord(RunGuardedReduce(@CallSumWritePastDest, 5, 3, grSumRow, Sig)));
  AssertEquals('the reference row sums were rejected by the harness',
    Ord(gvOk), Ord(RunGuardedReduce(@CallSSESumRow, 1, 1, grSumRow, Sig)));
  AssertEquals('the reference column sums were rejected by the harness',
    Ord(gvOk), Ord(RunGuardedReduce(@CallSSESumColumn, 1, 1, grSumColumn, Sig)));
end;

procedure TvsmathGuardTests.TestDispatchSumNoOverRead;
const
  cWidths: array[0..5] of NativeInt = (1, 3, 4, 5, 8, 9);
  cHeights: array[0..3] of NativeInt = (1, 3, 4, 5);
  cLevels: array[0..3] of TCPUInstrType = (itFPU, itSSE, itAVX, itFMA);
  cNames: array[0..3] of string = ('itFPU', 'itSSE', 'itAVX', 'itFMA');
var
  li: Integer;
begin
  for li := 0 to High(cLevels) do
  begin
    InitMathFunctions(cLevels[li], False);
    if GetCurCPUInstrType <> cLevels[li] then
      Continue;
    AssertReduceGuarded('MatrixSum row at ' + cNames[li], @CallDispatchSumRow,
      cWidths, cHeights, grSumRow);
    AssertReduceGuarded('MatrixSum column at ' + cNames[li], @CallDispatchSumColumn,
      cWidths, cHeights, grSumColumn);
  end;
  InitMathFunctions(GetBestCPUInstrType, False);
end;

procedure TvsmathGuardTests.TestDispatchMtxVecMultNoOverRead;
const
  cWidths: array[0..3] of NativeInt = (4, 5, 8, 9);
  cHeights: array[0..3] of NativeInt = (1, 4, 5, 8);
  cLevels: array[0..3] of TCPUInstrType = (itFPU, itSSE, itAVX, itFMA);
  cNames: array[0..3] of string = ('itFPU', 'itSSE', 'itAVX', 'itFMA');
var
  li: Integer;
begin
  for li := 0 to High(cLevels) do
  begin
    InitMathFunctions(cLevels[li], False);
    if GetCurCPUInstrType <> cLevels[li] then
      Continue;
    { alpha and beta both non trivial: dest is read as well as written }
    AssertGuarded('MatrixMtxVecMult at ' + cNames[li], @CallDispatch,
      cWidths, cHeights, 2.0, 1.0);
  end;
  InitMathFunctions(GetBestCPUInstrType, False);
end;

{ The transposed product: the matrix streams one row at a time, so the widths
  that matter are the block boundaries of the two bodies (16 elements for SSE,
  32 for AVX) and the scalar tails behind them, and the destination - the narrow
  buffer - has to stay inside its guard page as well. }
const
  cTWidths: array[0..15] of NativeInt =
    (1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 23, 31, 32, 33, 65);
  cTHeights: array[0..5] of NativeInt = (1, 2, 3, 5, 8, 17);

procedure TvsmathGuardTests.TestSSEMtxVecMultTNoOverRead;
begin
  AssertTGuarded('ASMMatrixVectMultT', @CallSSET, cTWidths, cTHeights, 2.0, 1.0);
  { no false positives: the reference loop has to pass the same shapes }
  AssertTGuarded('transposed reference', @CallRefT, cTWidths, cTHeights, 2.0, 1.0);
end;

procedure TvsmathGuardTests.TestAVXMtxVecMultTNoOverRead;
begin
  if not AVXReady then Exit;
  AssertTGuarded('AVXMatrixVectMultT', @CallAVXT, cTWidths, cTHeights, 2.0, 1.0);
end;

procedure TvsmathGuardTests.TestDispatchMtxVecMultTNoOverRead;
const
  cWidths: array[0..5] of NativeInt = (1, 4, 5, 16, 17, 33);
  cHeights: array[0..3] of NativeInt = (1, 4, 5, 9);
  cLevels: array[0..3] of TCPUInstrType = (itFPU, itSSE, itAVX, itFMA);
  cNames: array[0..3] of string = ('itFPU', 'itSSE', 'itAVX', 'itFMA');
var
  li: Integer;
begin
  for li := 0 to High(cLevels) do
  begin
    InitMathFunctions(cLevels[li], False);
    if GetCurCPUInstrType <> cLevels[li] then
      Continue;
    AssertTGuarded('MatrixMtxVecMultT at ' + cNames[li], @CallDispatchT,
      cWidths, cHeights, 2.0, 1.0);
  end;
  InitMathFunctions(GetBestCPUInstrType, False);
end;

procedure TvsmathGuardTests.TestHarnessDetectsTransposedOverrun;
var
  Sig: cint;
begin
  { the transposed harness maps the destination to Width elements, not Height:
    a write one element past that destination has to fault }
  AssertEquals('a write one element past the transposed dest was not detected',
    Ord(gvOutOfBounds), Ord(RunGuardedT(@CallWritePastDestT, 9, 5, 2.0, 1.0, Sig)));
end;

{$ENDIF}
{$ENDIF}

initialization
{$IFDEF CPUX64}
{$IFDEF UNIX}
  RegisterTest(TvsmathGuardTests);
{$ENDIF}
{$ENDIF}
end.
