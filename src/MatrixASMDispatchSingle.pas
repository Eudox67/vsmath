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

unit MatrixASMDispatchSingle;

// CPU level dispatch for the single precision kernels.
//
//   itFPU   scalar reference code
//   itSSE   ASM...Singlex64 kernels, scalar code where a kernel is a stub
//   itAVX   AVX...Singlex64 kernels, then SSE, then scalar code
//   itFMA   FMA...Singlex64 kernels, then AVX, then SSE, then scalar
//
// Only the *UnAligned* variants are installed, so alignment is never a
// precondition. The *EvenW* variants get a row width that is a multiple of four
// and the last zero to three columns are computed in scalar code. Sum and mean
// stay scalar unless the reduction dimension is a multiple of four; min/max and
// the norm fold the uncovered columns into the kernel result.

interface

{$MODE OBJFPC}{$H+}

// CPU target macros, exactly like the kernel units.
{$I VsMath_CPU.inc}

uses
  MatrixConstSingle;

type
  TCPUInstrType = (itFPU, itSSE, itAVX, itFMA);

// memory

function MtxAlloc(NumBytes: NativeInt): Pointer;
function MtxAllocAlign(NumBytes: NativeInt; var mem: Pointer): Pointer; overload;
function MtxAllocAlign(width, height: NativeInt; var LineWidth: NativeInt; var Mem: Pointer): Pointer; overload;
function MtxMallocAlign(NumBytes: NativeInt; var mem: Pointer): Pointer; overload;
function MtxMallocAlign(width, height: NativeInt; var LineWidth: NativeInt; var Mem: Pointer): Pointer; overload;
procedure MtxMemInit(A: PSingle; NumBytes: NativeInt; const Value: Single);

procedure MatrixCopy(dest: PSingle; const destLineWidth: NativeInt; Src: PSingle; const srcLineWidth: NativeInt; width, height: NativeInt);
procedure MatrixInit(dest: PSingle; const destLineWidth: NativeInt; Width, Height: NativeInt; const value: Single);
procedure MatrixRowSwap(A, B: PSingle; width: NativeInt);
procedure MatrixColSwap(A, B: PSingle; const LineWidthAB: NativeInt; Height: NativeInt);

// elementwise arithmetic

procedure MatrixAdd(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width: NativeInt; height: NativeInt; const LineWidth1, LineWidth2: NativeInt);
procedure MatrixSub(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width: NativeInt; height: NativeInt; const LineWidth1, LineWidth2: NativeInt);
procedure MatrixElemMult(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width: NativeInt; height: NativeInt; const LineWidth1, LineWidth2: NativeInt);
procedure MatrixElemDiv(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width: NativeInt; height: NativeInt; const LineWidth1, LineWidth2: NativeInt);

procedure MatrixAddVec(A: PSingle; LineWidthA: NativeInt; B: PSingle; incX: NativeInt; width, Height: NativeInt; rowWise: Boolean);
procedure MatrixSubVec(A: PSingle; LineWidthA: NativeInt; B: PSingle; incX: NativeInt; width, Height: NativeInt; rowWise: Boolean);
procedure MatrixVecAdd(X: PSingle; incX: NativeInt; y: PSingle; incY: NativeInt; N: NativeInt; const alpha: Single);

procedure MatrixElemAdd(Dest: PSingle; LineWidth, Width, Height: NativeInt; const dOffset: Single);
procedure MatrixAddAndScale(Dest: PSingle; LineWidth, Width, Height: NativeInt; const dOffset, Scale: Single);
procedure MatrixScaleAndAdd(Dest: PSingle; LineWidth, Width, Height: NativeInt; const dOffset, Scale: Single);

procedure MatrixSQRT(Dest: PSingle; LineWidth: NativeInt; Width, Height: NativeInt);
procedure MatrixAbs(Dest: PSingle; LineWidth: NativeInt; Width, Height: NativeInt);

// reductions

function MatrixMax(mt: PSingle; width, height: NativeInt; const LineWidth: NativeInt): Single;
function MatrixMin(mt: PSingle; width, height: NativeInt; const LineWidth: NativeInt): Single;
function MatrixAbsMax(mt: PSingle; width, height: NativeInt; const LineWidth: NativeInt): Single;
function MatrixAbsMin(mt: PSingle; width, height: NativeInt; const LineWidth: NativeInt): Single;

procedure MatrixSum(dest: PSingle; destLineWidth: NativeInt; Src: PSingle; srcLineWidth: NativeInt; width, height: NativeInt; RowWise: Boolean);
procedure MatrixMean(dest: PSingle; destLineWidth: NativeInt; Src: PSingle; srcLineWidth: NativeInt; width, height: NativeInt; RowWise: Boolean);
function MatrixElementwiseNorm2(dest: PSingle; LineWidth: NativeInt; Width, height: NativeInt; doSqrt: Boolean): Single;
procedure MatrixNormalize(dest: PSingle; destLineWidth: NativeInt; Src: PSingle; srcLineWidth: NativeInt; width, height: NativeInt; RowWise: Boolean);

// structure

procedure MatrixTranspose(dest: PSingle; const destLineWidth: NativeInt; mt: PSingle; const LineWidth: NativeInt; width, height: NativeInt);
procedure MatrixTransposeInplace(mt: PSingle; const LineWidth: NativeInt; N: NativeInt);

procedure MatrixMult(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width1: NativeInt; height1: NativeInt; width2: NativeInt; height2: NativeInt; const LineWidth1, LineWidth2: NativeInt);
procedure MatrixMtxVecMult(dest: PSingle; destLineWidth: NativeInt; mt1, v: PSingle; LineWidthMT, LineWidthV: NativeInt; width, height: NativeInt; alpha, beta: Single);
procedure MatrixMtxVecMultT(dest: PSingle; destLineWidth: NativeInt; mt1, v: PSingle; LineWidthMT, LineWidthV: NativeInt; width, height: NativeInt; alpha, beta: Single);
function MatrixVecDotMult(x: PSingle; incX: NativeInt; y: PSingle; incY: NativeInt; N: NativeInt): Single;
procedure MatrixRank1Update(A: PSingle; const LineWidthA: NativeInt; width, height: NativeInt; X, Y: PSingle; incX, incY: NativeInt; alpha: Single);

// rotations and geometry

procedure ApplyPlaneRotSeqRVB(width, height: NativeInt; A: PSingle; const LineWidthA: NativeInt; C, S: PConstSingleArr);
procedure ApplyPlaneRotSeqRVF(width, height: NativeInt; A: PSingle; const LineWidthA: NativeInt; C, S: PConstSingleArr);
procedure ApplyPlaneRotSeqLVB(width, height: NativeInt; A: PSingle; const LineWidthA: NativeInt; C, S: PConstSingleArr);
procedure ApplyPlaneRotSeqLVF(width, height: NativeInt; A: PSingle; const LineWidthA: NativeInt; C, S: PConstSingleArr);
procedure MatrixRotate(N: NativeInt; DX: PSingle; const LineWidthDX: NativeInt; DY: PSingle; LineWidthDY: NativeInt; const c, s: Single);

procedure MtxDistanceSqr(dist: PSingle; LineWidthDist: NativeInt; X, Y: PSingle; xLen, yLen: NativeInt);
procedure MtxDistanceAbs(dist: PSingle; LineWidthDist: NativeInt; X, Y: PSingle; xLen, yLen: NativeInt);

// CPU level selection

function GetCurCPUInstrType: TCPUInstrType;
function GetBestCPUInstrType: TCPUInstrType;

// useStrassenMult is accepted and ignored: there is no Strassen path.
procedure InitMathFunctions(instrType: TCPUInstrType; useStrassenMult: Boolean);
procedure InitSSEOptFunctions(instrType: TCPUInstrType);
procedure InitMult(useStrassenMult: Boolean);

implementation

uses
  SysUtils, Math,
{$IFDEF CPUX64}
  ASMMoveOperationsSinglex64,
  AVXMoveOperationsSinglex64,
  ASMMatrixAddSubOperationsSinglex64,
  AVXMatrixAddSubOperationsSinglex64,
  ASMMatrixElementwiseMultOperationsSinglex64,
  AVXMatrixElementwiseMultOperationsSinglex64,
  ASMMatrixScaleOperationsSinglex64,
  AVXMatrixScaleOperationsSinglex64,
  ASMMatrixSqrtOperationsSinglex64,
  AVXMatrixSqrtOperationsSinglex64,
  ASMMatrixAbsOperationsSinglex64,
  AVXMatrixAbsOperationsSinglex64,
  ASMMatrixSumOperationsSinglex64,
  AVXMatrixSumOperationsSinglex64,
  ASMMatrixMeanOperationsSinglex64,
  AVXMatrixMeanOperationsSinglex64,
  ASMMatrixMinMaxOperationsSinglex64,
  AVXMatrixMinMaxOperationsSinglex64,
  ASMMatrixNormOperationsSinglex64,
  AVXMatrixNormOperationsSinglex64,
  ASMMatrixTransposeOperationsSinglex64,
  AVXMatrixTransposeOperationsSinglex64,
  ASMMatrixMultOperationsSinglex64,
  AVXMatrixMultOperationsSinglex64,
  FMAMatrixMultOperationsSinglex64,
  ASMMatrixVectorMultOperationsSinglex64,
  AVXMatrixVectorMultOperationsSinglex64,
  FMAMatrixVectorMultOperationsSinglex64,
  ASMMatrixRotationsSinglex64,
  AVXMatrixRotationsSinglex64,
  ASMVecDistSinglex64,
{$ENDIF}
  CPUFeaturesSingle;

type
  TMemInitKernel       = procedure(A: PSingle; NumBytes: NativeInt; Value: Single);
  TMatrixInitKernel    = procedure(dest: PSingle; const destLineWidth: NativeInt; Width, Height: NativeInt; Value: Single);
  TMatrixCopyKernel    = procedure(dest: PSingle; const destLineWidth: NativeInt; src: PSingle; const srcLineWidth: NativeInt; width, height: NativeInt);
  TRowSwapKernel       = procedure(A, B: PSingle; width: NativeInt);
  TMatrixBinaryKernel  = procedure(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width, height: NativeInt; const LineWidth1, LineWidth2: NativeInt);
  TMatrixVecOpKernel   = procedure(A: PSingle; LineWidthA: NativeInt; B: PSingle; incX: NativeInt; width, Height: NativeInt);
  TVecAddKernel        = procedure(X: PSingle; y: PSingle; N: NativeInt; alpha: Single);
  TVecAddNonSeqKernel  = procedure(X: PSingle; y: PSingle; N: NativeInt; incX, incY: NativeInt; alpha: Single);
  TMatrixScalarKernel  = procedure(Dest: PSingle; const LineWidth, Width, Height: NativeInt; dOffset, Scale: Single);
  TMatrixOffsetKernel  = procedure(Dest: PSingle; const LineWidth, Width, Height: NativeInt; dOffset: Single);
  TMatrixUnaryKernel   = procedure(Dest: PSingle; const LineWidth, Width, Height: NativeInt);
  TMatrixMinMaxKernel  = function(mt: PSingle; width, height: NativeInt; const LineWidth: NativeInt): Single;
  TMatrixReduceKernel  = procedure(dest: PSingle; const destLineWidth: NativeInt; Src: PSingle; const srcLineWidth: NativeInt; width, height: NativeInt);
  TNorm2Kernel         = function(dest: PSingle; const LineWidth: NativeInt; Width, height: NativeInt): Single;
  TTransposeKernel     = procedure(dest: PSingle; const destLineWidth: NativeInt; mt: PSingle; const LineWidth: NativeInt; width, height: NativeInt);
  TTransposeInplaceKernel = procedure(mt: PSingle; const LineWidth: NativeInt; N: NativeInt);
  TMatrixMultKernel    = procedure(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width1, height1, width2, height2: NativeInt; const LineWidth1, LineWidth2: NativeInt);
  TMatrixVecMultKernel = procedure(dest: PSingle; destLineWidth: NativeInt; mt1, v: PSingle; LineWidthMT, LineWidthV: NativeInt; width, height: NativeInt; alpha, beta: Single);
  TDotMultKernel       = function(x, y: PSingle; N: NativeInt): Single;
  TDotMultUnevenKernel = function(x, Y: PSingle; incX, incY: NativeInt; N: NativeInt): Single;
  TRank1Kernel         = procedure(A: PSingle; const LineWidthA: NativeInt; width, height: NativeInt; X, Y: PSingle; incX, incY: NativeInt; alpha: Single);
  TPlaneRotKernel      = procedure(width, height: NativeInt; A: PSingle; const LineWidthA: NativeInt; C, S: PConstSingleArr);
  TMatrixRotateKernel  = procedure(N: NativeInt; X: PSingle; const LineWidthDX: NativeInt; Y: PSingle; LineWidthDY: NativeInt; const c, s: Single);
  TDistanceKernel      = procedure(dist: PSingle; LineWidthDist: NativeInt; X, Y: PSingle; xLen, yLen: NativeInt);

var
  // kernels of the current CPU level. nil means "no kernel at this
  // level", the wrapper then takes the scalar reference path.
  gMemInit           : TMemInitKernel;
  gMatrixInit        : TMatrixInitKernel;
  gMatrixCopy        : TMatrixCopyKernel;
  gRowSwap           : TRowSwapKernel;
  gAdd, gSub         : TMatrixBinaryKernel;
  gElemMult          : TMatrixBinaryKernel;
  gElemDiv           : TMatrixBinaryKernel;
  gAddVecRow         : TMatrixVecOpKernel;
  gAddVecCol         : TMatrixVecOpKernel;
  gAddVecVecRow      : TMatrixVecOpKernel;
  gSubVecRow         : TMatrixVecOpKernel;
  gSubVecCol         : TMatrixVecOpKernel;
  gSubVecVecRow      : TMatrixVecOpKernel;
  gVecAddSeq         : TVecAddKernel;
  gVecAddNonSeq      : TVecAddNonSeqKernel;
  gElemAdd           : TMatrixOffsetKernel;
  gAddAndScale       : TMatrixScalarKernel;
  gScaleAndAdd       : TMatrixScalarKernel;
  gSqrt, gAbs        : TMatrixUnaryKernel;
  gMax, gMin         : TMatrixMinMaxKernel;
  gAbsMax, gAbsMin   : TMatrixMinMaxKernel;
  gSumRow, gSumCol   : TMatrixReduceKernel;
  gMeanRow, gMeanCol : TMatrixReduceKernel;
  gNorm2             : TNorm2Kernel;
  gNormalizeRow      : TMatrixReduceKernel;
  gNormalizeCol      : TMatrixReduceKernel;
  gTranspose         : TTransposeKernel;
  gTransposeInplace  : TTransposeInplaceKernel;
  gMult              : TMatrixMultKernel;
  gMtxVecMult        : TMatrixVecMultKernel;
  gMtxVecMultT       : TMatrixVecMultKernel;
  gDotMultAligned    : TDotMultKernel;
  gDotMultUnAligned  : TDotMultKernel;
  gDotMultUneven     : TDotMultUnevenKernel;
  gRank1Seq          : TRank1Kernel;
  gRank1SeqAligned   : TRank1Kernel;
  gRank1NonSeq       : TRank1Kernel;
  gRotRVB, gRotRVF   : TPlaneRotKernel;
  gRotLVB, gRotLVF   : TPlaneRotKernel;
  gMatrixRotate      : TMatrixRotateKernel;
  gDistSqr, gDistAbs : TDistanceKernel;

  curUsedCPUInstrSet  : TCPUInstrType = itFPU;
  curUsedStrassenMult : Boolean = False;

// Scalar reference implementations: they define the semantics the kernels are
// tested against, and serve as the fallback whenever the current CPU level has
// no working kernel for an operation.

procedure RefMatrixCopy(dest: PSingle; const destLineWidth: NativeInt; src: PSingle; const srcLineWidth: NativeInt; width, height: NativeInt);
var x, y: NativeInt;
begin
  for y := 0 to height - 1 do
    for x := 0 to width - 1 do
      dest[x + (y*destLineWidth) div sizeof(Single)] := src[x + (y*srcLineWidth) div sizeof(Single)];
end;

procedure RefMatrixInit(dest: PSingle; const destLineWidth: NativeInt; Width, Height: NativeInt; const value: Single);
var x, y: NativeInt;
begin
  for y := 0 to Height - 1 do
    for x := 0 to Width - 1 do
      dest[x + (y*destLineWidth) div sizeof(Single)] := value;
end;

procedure RefRowSwap(A, B: PSingle; width: NativeInt);
var x: NativeInt; tmp: Single;
begin
  for x := 0 to width - 1 do
  begin
    tmp := A[x];
    A[x] := B[x];
    B[x] := tmp;
  end;
end;

procedure RefBinary(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width, height: NativeInt; const LineWidth1, LineWidth2: NativeInt; op: Byte);
var x, y: NativeInt; i1, i2, id: NativeInt;
begin
  for y := 0 to height - 1 do
  begin
    i1 := (y*LineWidth1) div sizeof(Single);
    i2 := (y*LineWidth2) div sizeof(Single);
    id := (y*destLineWidth) div sizeof(Single);
    for x := 0 to width - 1 do
    begin
      case op of
        0: dest[x+id] := mt1[x+i1] + mt2[x+i2];
        1: dest[x+id] := mt1[x+i1] - mt2[x+i2];
        2: dest[x+id] := mt1[x+i1] * mt2[x+i2];
      else
        dest[x+id] := mt1[x+i1] / mt2[x+i2];
      end;
    end;
  end;
end;

// A := A +/- B, where B is either a row vector (applied to every row)
// or a column vector (applied to every column). add = True for +.
procedure RefMatrixVecOp(A: PSingle; LineWidthA: NativeInt; B: PSingle; incB: NativeInt; width, Height: NativeInt; rowWise: Boolean; add: Boolean);
var x, y: NativeInt; ia, ib: NativeInt;
begin
  for y := 0 to Height - 1 do
  begin
    ia := (y*LineWidthA) div sizeof(Single);
    for x := 0 to width - 1 do
    begin
      if rowWise then ib := (x*incB) div sizeof(Single)
      else ib := (y*incB) div sizeof(Single);
      if add then A[x+ia] := A[x+ia] + B[ib]
      else A[x+ia] := A[x+ia] - B[ib];
    end;
  end;
end;

// X := X + alpha * Y
procedure RefVecAdd(X: PSingle; incX: NativeInt; y: PSingle; incY: NativeInt; N: NativeInt; const alpha: Single);
var i, ix, iy: NativeInt;
begin
  for i := 0 to N - 1 do
  begin
    ix := (i*incX) div sizeof(Single);
    iy := (i*incY) div sizeof(Single);
    X[ix] := X[ix] + alpha * y[iy];
  end;
end;

procedure RefElemAdd(Dest: PSingle; LineWidth, Width, Height: NativeInt; const dOffset: Single);
var x, y, id: NativeInt;
begin
  for y := 0 to Height - 1 do
  begin
    id := (y*LineWidth) div sizeof(Single);
    for x := 0 to Width - 1 do
      Dest[x+id] := Dest[x+id] + dOffset;
  end;
end;

// Dest := (Dest + dOffset) * Scale
procedure RefAddAndScale(Dest: PSingle; LineWidth, Width, Height: NativeInt; const dOffset, Scale: Single);
var x, y, id: NativeInt;
begin
  for y := 0 to Height - 1 do
  begin
    id := (y*LineWidth) div sizeof(Single);
    for x := 0 to Width - 1 do
      Dest[x+id] := (Dest[x+id] + dOffset) * Scale;
  end;
end;

// Dest := Dest * Scale + dOffset
procedure RefScaleAndAdd(Dest: PSingle; LineWidth, Width, Height: NativeInt; const dOffset, Scale: Single);
var x, y, id: NativeInt;
begin
  for y := 0 to Height - 1 do
  begin
    id := (y*LineWidth) div sizeof(Single);
    for x := 0 to Width - 1 do
      Dest[x+id] := Dest[x+id] * Scale + dOffset;
  end;
end;

// op: 0 = sqrt, 1 = abs
procedure RefUnary(Dest: PSingle; LineWidth, Width, Height: NativeInt; op: Byte);
var x, y, id: NativeInt;
begin
  for y := 0 to Height - 1 do
  begin
    id := (y*LineWidth) div sizeof(Single);
    for x := 0 to Width - 1 do
      if op = 0 then Dest[x+id] := Sqrt(Dest[x+id])
      else Dest[x+id] := Abs(Dest[x+id]);
  end;
end;

// op: 0 = max, 1 = min. The absolute variants fold |value| instead.
function RefMinMax(mt: PSingle; width, height: NativeInt; const LineWidth: NativeInt; op, absMode: Byte): Single;
var x, y, id: NativeInt; v: Single;
begin
  Result := 0;
  if (width <= 0) or (height <= 0) then exit;

  for y := 0 to height - 1 do
  begin
    id := (y*LineWidth) div sizeof(Single);
    for x := 0 to width - 1 do
    begin
      v := mt[x+id];
      if absMode = 1 then v := Abs(v);
      if (x = 0) and (y = 0) then Result := v
      else if op = 0 then
      begin
        if v > Result then Result := v;
      end
      else if v < Result then Result := v;
    end;
  end;
end;

// op: 0 = sum, 1 = mean. RowWise reduces every row (dest gets one element
// per row), otherwise every column.
procedure RefSumMean(dest: PSingle; destLineWidth: NativeInt; Src: PSingle; srcLineWidth: NativeInt; width, height: NativeInt; RowWise: Boolean; mean: Boolean);
var x, y, isrc, idst: NativeInt; s: Single;
begin
  if RowWise then
  begin
    for y := 0 to height - 1 do
    begin
      isrc := (y*srcLineWidth) div sizeof(Single);
      idst := (y*destLineWidth) div sizeof(Single);
      s := 0;
      for x := 0 to width - 1 do s := s + Src[x+isrc];
      if mean then s := s / width;
      dest[idst] := s;
    end;
  end
  else
  begin
    for x := 0 to width - 1 do
    begin
      s := 0;
      for y := 0 to height - 1 do
        s := s + Src[x + (y*srcLineWidth) div sizeof(Single)];
      if mean then s := s / height;
      dest[(x*destLineWidth) div sizeof(Single)] := s;
    end;
  end;
end;

function RefNorm2(dest: PSingle; LineWidth: NativeInt; Width, height: NativeInt; doSqrt: Boolean): Single;
var x, y, id: NativeInt;
begin
  Result := 0;
  for y := 0 to height - 1 do
  begin
    id := (y*LineWidth) div sizeof(Single);
    for x := 0 to Width - 1 do
      Result := Result + Sqr(dest[x+id]);
  end;
  if doSqrt then Result := Sqrt(Result);
end;

// every row (or column) is divided by its own L2 norm
procedure RefNormalize(dest: PSingle; destLineWidth: NativeInt; Src: PSingle; srcLineWidth: NativeInt; width, height: NativeInt; RowWise: Boolean);
var x, y, isrc, idst: NativeInt; n: Single;
begin
  if RowWise then
  begin
    for y := 0 to height - 1 do
    begin
      isrc := (y*srcLineWidth) div sizeof(Single);
      idst := (y*destLineWidth) div sizeof(Single);
      n := 0;
      for x := 0 to width - 1 do n := n + Sqr(Src[x+isrc]);
      n := Sqrt(n);
      for x := 0 to width - 1 do
        if n <> 0 then dest[x+idst] := Src[x+isrc] / n
        else dest[x+idst] := 0;
    end;
  end
  else
  begin
    for x := 0 to width - 1 do
    begin
      n := 0;
      for y := 0 to height - 1 do
        n := n + Sqr(Src[x + (y*srcLineWidth) div sizeof(Single)]);
      n := Sqrt(n);
      for y := 0 to height - 1 do
      begin
        isrc := (y*srcLineWidth) div sizeof(Single);
        idst := (y*destLineWidth) div sizeof(Single);
        if n <> 0 then dest[x+idst] := Src[x+isrc] / n
        else dest[x+idst] := 0;
      end;
    end;
  end;
end;

procedure RefTranspose(dest: PSingle; const destLineWidth: NativeInt; mt: PSingle; const LineWidth: NativeInt; width, height: NativeInt);
var x, y: NativeInt;
begin
  for y := 0 to height - 1 do
    for x := 0 to width - 1 do
      dest[y + (x*destLineWidth) div sizeof(Single)] := mt[x + (y*LineWidth) div sizeof(Single)];
end;

procedure RefTransposeInplace(mt: PSingle; const LineWidth: NativeInt; N: NativeInt);
var x, y: NativeInt; tmp: Single;
begin
  for y := 0 to N - 1 do
    for x := y + 1 to N - 1 do
    begin
      tmp := mt[x + (y*LineWidth) div sizeof(Single)];
      mt[x + (y*LineWidth) div sizeof(Single)] := mt[y + (x*LineWidth) div sizeof(Single)];
      mt[y + (x*LineWidth) div sizeof(Single)] := tmp;
    end;
end;

procedure RefMult(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width1, height1, width2, height2: NativeInt; const LineWidth1, LineWidth2: NativeInt);
var x, y, k, i1, i2, id: NativeInt; s: Single;
begin
  for y := 0 to height1 - 1 do
  begin
    i1 := (y*LineWidth1) div sizeof(Single);
    id := (y*destLineWidth) div sizeof(Single);
    for x := 0 to width2 - 1 do
    begin
      s := 0;
      i2 := x;
      for k := 0 to width1 - 1 do
      begin
        s := s + mt1[k+i1] * mt2[i2];
        inc(i2, LineWidth2 div sizeof(Single));
      end;
      dest[x+id] := s;
    end;
  end;
end;

procedure RefMtxVecMult(dest: PSingle; destLineWidth: NativeInt; mt1, v: PSingle; LineWidthMT, LineWidthV: NativeInt; width, height: NativeInt; alpha, beta: Single);
var x, y, i1, iv, id: NativeInt; s: Single;
begin
  for y := 0 to height - 1 do
  begin
    i1 := (y*LineWidthMT) div sizeof(Single);
    id := (y*destLineWidth) div sizeof(Single);
    s := 0;
    iv := 0;
    for x := 0 to width - 1 do
    begin
      s := s + mt1[x+i1] * v[iv];
      inc(iv, LineWidthV div sizeof(Single));
    end;
    dest[id] := alpha * s + beta * dest[id];
  end;
end;

// transposed product: mt1 is height rows of width elements, v holds height
// elements and dest holds width elements, so dest = beta*dest + alpha*mt1^T*v
procedure RefMtxVecMultT(dest: PSingle; destLineWidth: NativeInt; mt1, v: PSingle; LineWidthMT, LineWidthV: NativeInt; width, height: NativeInt; alpha, beta: Single);
var col, row: NativeInt; s: Single; pd: PSingle;
begin
  for col := 0 to width - 1 do
  begin
    s := 0;
    for row := 0 to height - 1 do
      s := s + PSingle(PByte(mt1) + row*LineWidthMT + col*sizeof(Single))^
                * PSingle(PByte(v) + row*LineWidthV)^;

    pd := PSingle(PByte(dest) + col*destLineWidth);
    pd^ := alpha * s + beta * pd^;
  end;
end;

function RefDotMult(x: PSingle; incX: NativeInt; y: PSingle; incY: NativeInt; N: NativeInt): Single;
var i, ix, iy: NativeInt;
begin
  Result := 0;
  ix := 0;
  iy := 0;
  for i := 0 to N - 1 do
  begin
    Result := Result + x[ix] * y[iy];
    inc(ix, incX div sizeof(Single));
    inc(iy, incY div sizeof(Single));
  end;
end;

procedure RefRank1(A: PSingle; const LineWidthA: NativeInt; width, height: NativeInt; X, Y: PSingle; incX, incY: NativeInt; alpha: Single);
var col, row, ia, ix, iy: NativeInt;
begin
  for row := 0 to height - 1 do
  begin
    ia := (row*LineWidthA) div sizeof(Single);
    ix := (row*incX) div sizeof(Single);
    for col := 0 to width - 1 do
    begin
      iy := (col*incY) div sizeof(Single);
      A[col+ia] := A[col+ia] + alpha * X[ix] * Y[iy];
    end;
  end;
end;

procedure RefDistance(dist: PSingle; LineWidthDist: NativeInt; X, Y: PSingle; xLen, yLen: NativeInt; absMode: Boolean);
var i, j, id: NativeInt; d: Single;
begin
  for i := 0 to xLen - 1 do
  begin
    id := (i*LineWidthDist) div sizeof(Single);
    for j := 0 to yLen - 1 do
    begin
      d := X[i] - Y[j];
      if absMode then dist[j+id] := Abs(d)
      else dist[j+id] := Sqr(d);
    end;
  end;
end;

// kernel table

procedure ClearKernels;
begin
  gMemInit := nil;
  gMatrixInit := nil;
  gMatrixCopy := nil;
  gRowSwap := nil;
  gAdd := nil;
  gSub := nil;
  gElemMult := nil;
  gElemDiv := nil;
  gAddVecRow := nil;
  gAddVecCol := nil;
  gAddVecVecRow := nil;
  gSubVecRow := nil;
  gSubVecCol := nil;
  gSubVecVecRow := nil;
  gVecAddSeq := nil;
  gVecAddNonSeq := nil;
  gElemAdd := nil;
  gAddAndScale := nil;
  gScaleAndAdd := nil;
  gSqrt := nil;
  gAbs := nil;
  gMax := nil;
  gMin := nil;
  gAbsMax := nil;
  gAbsMin := nil;
  gSumRow := nil;
  gSumCol := nil;
  gMeanRow := nil;
  gMeanCol := nil;
  gNorm2 := nil;
  gNormalizeRow := nil;
  gNormalizeCol := nil;
  gTranspose := nil;
  gTransposeInplace := nil;
  gMult := nil;
  gMtxVecMult := nil;
  gMtxVecMultT := nil;
  gDotMultAligned := nil;
  gDotMultUnAligned := nil;
  gDotMultUneven := nil;
  gRank1Seq := nil;
  gRank1SeqAligned := nil;
  gRank1NonSeq := nil;
  gRotRVB := nil;
  gRotRVF := nil;
  gRotLVB := nil;
  gRotLVF := nil;
  gMatrixRotate := nil;
  gDistSqr := nil;
  gDistAbs := nil;
end;

{$IFDEF CPUX64}
{ The SSE matrix*vector kernels come in three flavours and only two of them
  cover a width class: ASMMatrixVectMultEvenUnAlignedVAligned handles
  width and 3 = 0, ASMMatrixVectMultOddUnAlignedVAligned handles
  width and 3 = 1 (its block loop consumes width - 1 elements four at a time
  and adds the last one scalar), and the plain ASMMatrixVectMult covers the
  rest. Picking here keeps that precondition out of every caller.

  The matrix rows are only assumed to be Single aligned, so both SIMD arms use
  the *UnAligned* variants: they load the matrix with movups. This is what
  makes the kernel usable on a matrix whose line width is not a multiple of
  16 bytes, which is the normal case for a sub matrix. }
procedure SSEMtxVecMult(dest: PSingle; destLineWidth: NativeInt;
  mt1, v: PSingle; LineWidthMT, LineWidthV: NativeInt;
  width, height: NativeInt; alpha, beta: Single);
begin
  case width and 3 of
    0: ASMMatrixVectMultEvenUnAlignedVAligned(dest, destLineWidth, mt1, v,
         LineWidthMT, LineWidthV, width, height, alpha, beta);
    1: ASMMatrixVectMultOddUnAlignedVAligned(dest, destLineWidth, mt1, v,
         LineWidthMT, LineWidthV, width, height, alpha, beta);
  else
    ASMMatrixVectMult(dest, destLineWidth, mt1, v,
      LineWidthMT, LineWidthV, width, height, alpha, beta);
  end;
end;

procedure SelectSSE;
begin
  ClearKernels;

  gMemInit          := @ASMInitMemAligned;
  gMatrixInit       := @ASMMatrixInitUnAligned;
  gMatrixCopy       := @ASMMatrixCopyUnAlignedEvenW;
  gRowSwap          := @ASMRowSwapUnAlignedEvenW;

  gAdd              := @ASMMatrixAddUnAlignedEvenW;
  gSub              := @ASMMatrixSubUnAlignedEvenW;
  gElemMult         := @ASMMatrixElemMultUnAlignedEvenW;
  gElemDiv          := @ASMMatrixElemDivUnAlignedEvenW;

  gAddVecRow        := @ASMMatrixAddVecUnalignedRow;
  gAddVecCol        := @ASMMatrixAddVecUnalignedCol;
  gAddVecVecRow     := @ASMMatrixAddVecUnalignedVecRow;
  gSubVecRow        := @ASMMatrixSubVecUnalignedRow;
  gSubVecCol        := @ASMMatrixSubVecUnalignedCol;
  gSubVecVecRow     := @ASMMatrixSubVecUnalignedVecRow;
  gVecAddSeq        := @ASMVecAddUnAlignedSeq;
  gVecAddNonSeq     := @ASMVecAddNonSeq;

  gElemAdd          := @ASMMatrixElemAddUnAlignedEvenW;
  gAddAndScale      := @ASMMatrixAddScaleUnAlignedEvenW;
  gScaleAndAdd      := @ASMMatrixScaleAddUnAlignedEvenW;

  gSqrt             := @ASMMatrixSQRTUnAlignedEvenW;
  gAbs              := @ASMMatrixAbsUnAlignedEvenW;

  gMax              := @ASMMatrixMaxUnAlignedEvenW;
  gMin              := @ASMMatrixMinUnAlignedEvenW;
  gAbsMax           := @ASMMatrixAbsMaxUnAlignedEvenW;
  gAbsMin           := @ASMMatrixAbsMinUnAlignedEvenW;

  // the SSE sum/mean/norm2 and normalize kernels carry their own tail handling,
  // so no parity or alignment precondition is left
  gSumRow           := @ASMMatrixSumRowUnAlignedEvenW;
  gSumCol           := @ASMMatrixSumColumnUnAlignedEvenW;
  gMeanRow          := @ASMMatrixMeanRowUnAlignedEvenW;
  gMeanCol          := @ASMMatrixMeanColumnUnAlignedEvenW;
  gNorm2            := @ASMMatrixElementwiseNorm2UnAlignedEvenW;
  gNormalizeRow     := @ASMMatrixNormalizeRowUnAlignedEvenW;
  gNormalizeCol     := @ASMMatrixNormalizeColumnUnAlignedEvenW;

  gTranspose        := @ASMMatrixTransposeUnAlignedEvenWEvenH;
  gTransposeInplace := @ASMMatrixTransposeInplace;

  gMult             := @ASMMatrixMultUnAlignedEvenW1EvenW2;
  gMtxVecMult       := @SSEMtxVecMult;
  // unaligned loads, dest used as the accumulator; a destination that is not
  // contiguous falls back to the scalar column loop inside the kernel
  gMtxVecMultT      := @ASMMatrixVectMultT;
  gDotMultAligned   := @ASMMatrixVecDotMultAligned;
  gDotMultUnAligned := @ASMMatrixVecDotMultUnAligned;
  gDotMultUneven    := @ASMMatrixVecDotMultUneven;
  gRank1Seq         := @ASMRank1UpdateSeq;
  gRank1SeqAligned  := @ASMRank1UpdateSeqAligned;
  gRank1NonSeq      := @ASMRank1UpdateNonSeq;

  gRotRVB           := @ASMApplyPlaneRotSeqRVB;
  gRotRVF           := @ASMApplyPlaneRotSeqRVF;
  gRotLVB           := @ASMApplyPlaneRotSeqLVB;
  gRotLVF           := @ASMApplyPlaneRotSeqLVF;
  gMatrixRotate     := @ASMMatrixRotate;

  gDistSqr          := @ASMMtxDistanceSqr;
  gDistAbs          := @ASMMtxDistanceAbs;
end;

procedure SelectAVX;
begin
  SelectSSE;

  gMemInit          := @AVXInitMemAligned;
  gMatrixInit       := @AVXMatrixInitUnAligned;
  gMatrixCopy       := @AVXMatrixCopyUnAligned;
  gRowSwap          := @AVXRowSwapUnAligned;

  gAdd              := @AVXMatrixAddUnAligned;
  gSub              := @AVXMatrixSubUnAligned;
  gElemMult         := @AVXMatrixElemMultUnAligned;
  gElemDiv          := @AVXMatrixElemDivUnAligned;

  gAddVecRow        := @AVXMatrixAddVecUnalignedRow;
  gAddVecCol        := @AVXMatrixAddVecUnalignedCol;
  gAddVecVecRow     := @AVXMatrixAddVecUnalignedVecRow;
  gSubVecRow        := @AVXMatrixSubVecUnalignedRow;
  gSubVecCol        := @AVXMatrixSubVecUnalignedCol;
  gSubVecVecRow     := @AVXMatrixSubVecUnalignedVecRow;

  gElemAdd          := @AVXMatrixAddUnAlignedEvenW;
  gAddAndScale      := @AVXMatrixAddscaleUnAlignedEvenW;
  gScaleAndAdd      := @AVXMatrixScaleAddUnAlignedEvenW;

  gSqrt             := @AVXMatrixSQRTUnAligned;
  gAbs              := @AVXMatrixAbsUnAligned;

  gMax              := @AVXMatrixMaxUnAligned;
  gMin              := @AVXMatrixMinUnAligned;

  gSumRow           := @AVXMatrixSumRowUnAligned;
  gSumCol           := @AVXMatrixSumColumnUnAligned;
  gMeanRow          := @AVXMatrixMeanRowUnAligned;
  gMeanCol          := @AVXMatrixMeanColumnUnAligned;
  gNorm2            := @AVXMatrixElementwiseNorm2UnAligned;
  gNormalizeRow     := @AVXMatrixNormalizeRowUnAligned;
  gNormalizeCol     := @AVXMatrixNormalizeColumnUnAligned;

  gTranspose        := @AVXMatrixTransposeUnaligned;
  gTransposeInplace := @AVXMatrixTransposeInplace;

  gMult             := @AVXMatrixMultUnAligned;
  gMtxVecMult       := @AVXMatrixVectMultUnAlignedVAligned;
  gMtxVecMultT      := @AVXMatrixVectMultT;
  gDotMultAligned   := @AVXMatrixVecDotMultAligned;
  gDotMultUnAligned := @AVXMatrixVecDotMultUnAligned;
  gDotMultUneven    := @AVXMatrixVecDotMultUneven;
  // SeqAligned forwards to Seq rather than risking an alignment fault for a saving
  // no AVX core pays; the strided twin is a plain scalar loop because a stride
  // leaves nothing to vectorise.
  gRank1Seq         := @AVXRank1UpdateSeq;
  gRank1SeqAligned  := @AVXRank1UpdateSeqAligned;
  gRank1NonSeq      := @AVXRank1UpdateNonSeq;

  gRotRVB           := @AVXApplyPlaneRotSeqRVB;
  gRotRVF           := @AVXApplyPlaneRotSeqRVF;
  gRotLVB           := @AVXApplyPlaneRotSeqLVB;
  gRotLVF           := @AVXApplyPlaneRotSeqLVF;
  gMatrixRotate     := @AVXMatrixRotate;

  // no AVX kernel exists for the pairwise distance matrix -> stays on SSE
end;

procedure SelectFMA;
begin
  SelectAVX;

  // FMA kernels only exist for the plain matrix multiplication; the AVX twins
  // serve the vector-mult and rank-1 entries.
  gMult := @FMAMatrixMultUnAligned;
end;
{$ENDIF}

procedure SelectKernels(instrType: TCPUInstrType);
begin
  ClearKernels;
{$IFDEF CPUX64}
  case instrType of
    itSSE: SelectSSE;
    itAVX: SelectAVX;
    itFMA: SelectFMA;
  end;
{$ENDIF}
  curUsedCPUInstrSet := instrType;
end;

// CPU level inspection / selection

function GetBestCPUInstrType: TCPUInstrType;
begin
  if IsAVXPresent and IsFMAPresent then Result := itFMA
  else if IsAVXPresent then Result := itAVX
  else if IsSSE3Present then Result := itSSE
  else Result := itFPU;
end;

function GetCurCPUInstrType: TCPUInstrType;
begin
  Result := curUsedCPUInstrSet;
end;

procedure InitMathFunctions(instrType: TCPUInstrType; useStrassenMult: Boolean);
var lvl: TCPUInstrType;
begin
  curUsedStrassenMult := useStrassenMult;

  // the scalar level is always available and never upgraded
  if instrType = itFPU then
    lvl := itFPU
  else
  begin
    // never select a level the running CPU cannot execute
    lvl := itFPU;
    if IsSSE3Present then lvl := itSSE;
    if IsAVXPresent and (instrType in [itAVX, itFMA]) then lvl := itAVX;
    if IsAVXPresent and IsFMAPresent and (instrType = itFMA) then lvl := itFMA;
  end;

  SelectKernels(lvl);
end;

procedure InitSSEOptFunctions(instrType: TCPUInstrType);
begin
  InitMathFunctions(instrType, curUsedStrassenMult);
end;

procedure InitMult(useStrassenMult: Boolean);
begin
  // no Strassen or blocked multiplication in vsmath - flag is only recorded
  curUsedStrassenMult := useStrassenMult;
end;

// memory helpers

procedure MtxMemInit(A: PSingle; NumBytes: NativeInt; const Value: Single);
var p: PSingle; rest, body, n, k: NativeInt;
begin
  if (A = nil) or (NumBytes < sizeof(Single)) then exit;

  p := A;
  rest := NumBytes;

  // head: single elements until the block is 32 byte aligned
  while (rest >= sizeof(Single)) and ((NativeUInt(p) and $1F) <> 0) do
  begin
    p^ := Value;
    inc(p);
    dec(rest, sizeof(Single));
  end;

  // body: whole lane groups of four, filled by the kernel when one is selected
  body := rest and not 3;
  if body > 0 then
  begin
    if gMemInit <> nil then
    begin
      gMemInit(p, body, Value);
      inc(p, body div sizeof(Single));
    end
    else
    begin
      n := body div sizeof(Single);
      k := 0;
      while k < n do
      begin
        p^ := Value;
        inc(p);
        inc(k);
      end;
    end;
    dec(rest, body);
  end;

  // tail: the remaining zero to three singles
  while rest >= sizeof(Single) do
  begin
    p^ := Value;
    inc(p);
    dec(rest, sizeof(Single));
  end;
end;

function MtxMallocAlign(NumBytes: NativeInt; var mem: Pointer): Pointer;
begin
  Result := nil;
  mem := nil;
  if NumBytes <= 0 then exit;

  inc(NumBytes, $40);
  if (NumBytes and $1F) <> 0 then
    NumBytes := (NumBytes and not $1F) + $20;

  mem := GetMemory(NumBytes);
  if mem <> nil then
    Result := AlignPtr32(mem);
end;

function MtxMallocAlign(width, height: NativeInt; var LineWidth: NativeInt; var mem: Pointer): Pointer;
begin
  if (width and 3) <> 0 then
    width := width + 4 - (width and 3);

  LineWidth := sizeof(Single) * width;
  Result := MtxMallocAlign($20 + Height*LineWidth, mem);
end;

function MtxAlloc(NumBytes: NativeInt): Pointer;
begin
  Result := MtxMallocAlign(NumBytes, Result);
  if Result <> nil then
    MtxMemInit(Result, NumBytes, 0);
end;

function MtxAllocAlign(NumBytes: NativeInt; var mem: Pointer): Pointer;
begin
  Result := MtxMallocAlign(NumBytes, mem);
  if Result <> nil then
    MtxMemInit(Result, NumBytes, 0);
end;

function MtxAllocAlign(width, height: NativeInt; var LineWidth: NativeInt; var Mem: Pointer): Pointer;
begin
  Result := MtxMallocAlign(width, height, LineWidth, Mem);
  if Result <> nil then
    MtxMemInit(Result, $20 + Height*LineWidth, 0);
end;

// memory operations

procedure MatrixCopy(dest: PSingle; const destLineWidth: NativeInt; Src: PSingle; const srcLineWidth: NativeInt; width, height: NativeInt);
var bulk, x, y: NativeInt;
begin
  if (width <= 0) or (height <= 0) then exit;

  if gMatrixCopy = nil then
  begin
    RefMatrixCopy(dest, destLineWidth, Src, srcLineWidth, width, height);
    exit;
  end;

  bulk := width and not 3;
  if bulk > 0 then
    gMatrixCopy(dest, destLineWidth, Src, srcLineWidth, bulk, height);

  if bulk < width then
    for y := 0 to height - 1 do
      for x := bulk to width - 1 do
        dest[x + (y*destLineWidth) div sizeof(Single)] := Src[x + (y*srcLineWidth) div sizeof(Single)];
end;

procedure MatrixInit(dest: PSingle; const destLineWidth: NativeInt; Width, Height: NativeInt; const value: Single);
var bulk, x, y: NativeInt;
begin
  if (Width <= 0) or (Height <= 0) then exit;

  if gMatrixInit = nil then
  begin
    RefMatrixInit(dest, destLineWidth, Width, Height, value);
    exit;
  end;

  bulk := Width and not 3;
  if bulk > 0 then
    gMatrixInit(dest, destLineWidth, bulk, Height, value);

  if bulk < Width then
    for y := 0 to Height - 1 do
      for x := bulk to Width - 1 do
        dest[x + (y*destLineWidth) div sizeof(Single)] := value;
end;

procedure MatrixRowSwap(A, B: PSingle; width: NativeInt);
var bulk, x: NativeInt; tmp: Single;
begin
  if width <= 0 then exit;

  if gRowSwap = nil then
  begin
    RefRowSwap(A, B, width);
    exit;
  end;

  bulk := width and not 3;
  if bulk > 0 then
    gRowSwap(A, B, bulk);

  for x := bulk to width - 1 do
  begin
    tmp := A[x];
    A[x] := B[x];
    B[x] := tmp;
  end;
end;

procedure MatrixColSwap(A, B: PSingle; const LineWidthAB: NativeInt; Height: NativeInt);
var y, i: NativeInt; tmp: Single;
begin
  for y := 0 to Height - 1 do
  begin
    i := (y*LineWidthAB) div sizeof(Single);
    tmp := A[i];
    A[i] := B[i];
    B[i] := tmp;
  end;
end;

// elementwise arithmetic

procedure BinaryOp(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width, height: NativeInt; const LineWidth1, LineWidth2: NativeInt; kernel: TMatrixBinaryKernel; op: Byte);
var bulk, x, y, i1, i2, id: NativeInt;
begin
  if (width <= 0) or (height <= 0) then exit;

  if kernel = nil then
  begin
    RefBinary(dest, destLineWidth, mt1, mt2, width, height, LineWidth1, LineWidth2, op);
    exit;
  end;

  bulk := width and not 3;
  if bulk > 0 then
    kernel(dest, destLineWidth, mt1, mt2, bulk, height, LineWidth1, LineWidth2);

  if bulk < width then
    for y := 0 to height - 1 do
    begin
      i1 := (y*LineWidth1) div sizeof(Single);
      i2 := (y*LineWidth2) div sizeof(Single);
      id := (y*destLineWidth) div sizeof(Single);
      for x := bulk to width - 1 do
        case op of
          0: dest[x+id] := mt1[x+i1] + mt2[x+i2];
          1: dest[x+id] := mt1[x+i1] - mt2[x+i2];
          2: dest[x+id] := mt1[x+i1] * mt2[x+i2];
        else
          dest[x+id] := mt1[x+i1] / mt2[x+i2];
        end;
    end;
end;

procedure MatrixAdd(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width: NativeInt; height: NativeInt; const LineWidth1, LineWidth2: NativeInt);
begin
  BinaryOp(dest, destLineWidth, mt1, mt2, width, height, LineWidth1, LineWidth2, gAdd, 0);
end;

procedure MatrixSub(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width: NativeInt; height: NativeInt; const LineWidth1, LineWidth2: NativeInt);
begin
  BinaryOp(dest, destLineWidth, mt1, mt2, width, height, LineWidth1, LineWidth2, gSub, 1);
end;

procedure MatrixElemMult(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width: NativeInt; height: NativeInt; const LineWidth1, LineWidth2: NativeInt);
begin
  BinaryOp(dest, destLineWidth, mt1, mt2, width, height, LineWidth1, LineWidth2, gElemMult, 2);
end;

procedure MatrixElemDiv(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width: NativeInt; height: NativeInt; const LineWidth1, LineWidth2: NativeInt);
begin
  BinaryOp(dest, destLineWidth, mt1, mt2, width, height, LineWidth1, LineWidth2, gElemDiv, 3);
end;

procedure MatrixVecOp(A: PSingle; LineWidthA: NativeInt; B: PSingle; incX: NativeInt; width, Height: NativeInt; rowWise: Boolean; add: Boolean);
var kernel: TMatrixVecOpKernel; bulk, x, y, ia, ib: NativeInt;
begin
  if (width <= 0) or (Height <= 0) then exit;

  if rowWise and (incX = sizeof(Single)) then
  begin
    if add then kernel := gAddVecVecRow
    else kernel := gSubVecVecRow;
  end
  else if rowWise then
  begin
    if add then kernel := gAddVecRow
    else kernel := gSubVecRow;
  end
  else
  begin
    if add then kernel := gAddVecCol
    else kernel := gSubVecCol;
  end;

  if kernel = nil then
  begin
    RefMatrixVecOp(A, LineWidthA, B, incX, width, Height, rowWise, add);
    exit;
  end;

  bulk := width and not 3;
  if bulk > 0 then
    kernel(A, LineWidthA, B, incX, bulk, Height);

  if bulk < width then
    for y := 0 to Height - 1 do
    begin
      ia := (y*LineWidthA) div sizeof(Single);
      for x := bulk to width - 1 do
      begin
        if rowWise then ib := (x*incX) div sizeof(Single)
        else ib := (y*incX) div sizeof(Single);
        if add then A[x+ia] := A[x+ia] + B[ib]
        else A[x+ia] := A[x+ia] - B[ib];
      end;
    end;
end;

procedure MatrixAddVec(A: PSingle; LineWidthA: NativeInt; B: PSingle; incX: NativeInt; width, Height: NativeInt; rowWise: Boolean);
begin
  MatrixVecOp(A, LineWidthA, B, incX, width, Height, rowWise, True);
end;

procedure MatrixSubVec(A: PSingle; LineWidthA: NativeInt; B: PSingle; incX: NativeInt; width, Height: NativeInt; rowWise: Boolean);
begin
  MatrixVecOp(A, LineWidthA, B, incX, width, Height, rowWise, False);
end;

procedure MatrixVecAdd(X: PSingle; incX: NativeInt; y: PSingle; incY: NativeInt; N: NativeInt; const alpha: Single);
begin
  if N <= 0 then exit;

  // X[i] := X[i] + alpha*y[i]. The contiguous kernel carries a scalar tail, so
  // only the strided pair still has a lane aligned precondition.
  if (incX = sizeof(Single)) and (incY = sizeof(Single)) and (gVecAddSeq <> nil) then
    gVecAddSeq(X, y, N, alpha)
  else if ((incX and 3) = 0) and ((incY and 3) = 0) and (gVecAddNonSeq <> nil) then
    gVecAddNonSeq(X, y, N, incX, incY, alpha)
  else
    RefVecAdd(X, incX, y, incY, N, alpha);
end;

procedure MatrixElemAdd(Dest: PSingle; LineWidth, Width, Height: NativeInt; const dOffset: Single);
var bulk, x, y, id: NativeInt;
begin
  if (Width <= 0) or (Height <= 0) then exit;

  if gElemAdd <> nil then
  begin
    bulk := Width and not 3;
    if bulk > 0 then gElemAdd(Dest, LineWidth, bulk, Height, dOffset);
    if bulk >= Width then exit;
  end
  else
  begin
    RefElemAdd(Dest, LineWidth, Width, Height, dOffset);
    exit;
  end;

  for y := 0 to Height - 1 do
  begin
    id := (y*LineWidth) div sizeof(Single);
    for x := bulk to Width - 1 do
      Dest[x+id] := Dest[x+id] + dOffset;
  end;
end;

procedure ScalarOp(Dest: PSingle; LineWidth, Width, Height: NativeInt; const dOffset, Scale: Single; kernel: TMatrixScalarKernel; addAndScale: Boolean);
var bulk, x, y, id: NativeInt;
begin
  if (Width <= 0) or (Height <= 0) then exit;

  if kernel = nil then
  begin
    if addAndScale then RefAddAndScale(Dest, LineWidth, Width, Height, dOffset, Scale)
    else RefScaleAndAdd(Dest, LineWidth, Width, Height, dOffset, Scale);
    exit;
  end;

  bulk := Width and not 3;
  if bulk > 0 then kernel(Dest, LineWidth, bulk, Height, dOffset, Scale);

  if bulk < Width then
    for y := 0 to Height - 1 do
    begin
      id := (y*LineWidth) div sizeof(Single);
      for x := bulk to Width - 1 do
        if addAndScale then Dest[x+id] := (Dest[x+id] + dOffset) * Scale
        else Dest[x+id] := Dest[x+id] * Scale + dOffset;
    end;
end;

procedure MatrixAddAndScale(Dest: PSingle; LineWidth, Width, Height: NativeInt; const dOffset, Scale: Single);
begin
  ScalarOp(Dest, LineWidth, Width, Height, dOffset, Scale, gAddAndScale, True);
end;

procedure MatrixScaleAndAdd(Dest: PSingle; LineWidth, Width, Height: NativeInt; const dOffset, Scale: Single);
begin
  ScalarOp(Dest, LineWidth, Width, Height, dOffset, Scale, gScaleAndAdd, False);
end;

procedure UnaryOp(Dest: PSingle; LineWidth, Width, Height: NativeInt; kernel: TMatrixUnaryKernel; op: Byte);
var bulk, x, y, id: NativeInt;
begin
  if (Width <= 0) or (Height <= 0) then exit;

  if kernel = nil then
  begin
    RefUnary(Dest, LineWidth, Width, Height, op);
    exit;
  end;

  bulk := Width and not 3;
  if bulk > 0 then kernel(Dest, LineWidth, bulk, Height);

  if bulk < Width then
    for y := 0 to Height - 1 do
    begin
      id := (y*LineWidth) div sizeof(Single);
      for x := bulk to Width - 1 do
        if op = 0 then Dest[x+id] := Sqrt(Dest[x+id])
        else Dest[x+id] := Abs(Dest[x+id]);
    end;
end;

procedure MatrixSQRT(Dest: PSingle; LineWidth: NativeInt; Width, Height: NativeInt);
begin
  UnaryOp(Dest, LineWidth, Width, Height, gSqrt, 0);
end;

procedure MatrixAbs(Dest: PSingle; LineWidth: NativeInt; Width, Height: NativeInt);
begin
  UnaryOp(Dest, LineWidth, Width, Height, gAbs, 1);
end;

// reductions

function MinMaxOp(mt: PSingle; width, height: NativeInt; const LineWidth: NativeInt; kernel: TMatrixMinMaxKernel; op, absMode: Byte): Single;
var bulk, x, y, id: NativeInt; v: Single; have: Boolean;
begin
  if (width <= 0) or (height <= 0) then exit(0);

  if kernel = nil then
  begin
    Result := RefMinMax(mt, width, height, LineWidth, op, absMode);
    exit;
  end;

  bulk := width and not 3;
  have := False;
  Result := 0;

  if bulk > 0 then
  begin
    Result := kernel(mt, bulk, height, LineWidth);
    have := True;
  end;

  // fold the columns the kernel did not cover
  for y := 0 to height - 1 do
  begin
    id := (y*LineWidth) div sizeof(Single);
    for x := bulk to width - 1 do
    begin
      v := mt[x+id];
      if absMode = 1 then v := Abs(v);
      if not have then
      begin
        Result := v;
        have := True;
      end
      else if op = 0 then
      begin
        if v > Result then Result := v;
      end
      else if v < Result then Result := v;
    end;
  end;
end;

function MatrixMax(mt: PSingle; width, height: NativeInt; const LineWidth: NativeInt): Single;
begin
  Result := MinMaxOp(mt, width, height, LineWidth, gMax, 0, 0);
end;

function MatrixMin(mt: PSingle; width, height: NativeInt; const LineWidth: NativeInt): Single;
begin
  Result := MinMaxOp(mt, width, height, LineWidth, gMin, 1, 0);
end;

function MatrixAbsMax(mt: PSingle; width, height: NativeInt; const LineWidth: NativeInt): Single;
begin
  Result := MinMaxOp(mt, width, height, LineWidth, gAbsMax, 0, 1);
end;

function MatrixAbsMin(mt: PSingle; width, height: NativeInt; const LineWidth: NativeInt): Single;
begin
  Result := MinMaxOp(mt, width, height, LineWidth, gAbsMin, 1, 1);
end;

procedure MatrixSum(dest: PSingle; destLineWidth: NativeInt; Src: PSingle; srcLineWidth: NativeInt; width, height: NativeInt; RowWise: Boolean);
var kernel: TMatrixReduceKernel;
begin
  if (width <= 0) or (height <= 0) then exit;

  // Both sum kernels handle a reduction length that is not a whole number of
  // lanes, so no parity test is needed here.
  if RowWise then kernel := gSumRow else kernel := gSumCol;

  if kernel = nil then
    RefSumMean(dest, destLineWidth, Src, srcLineWidth, width, height, RowWise, False)
  else
    kernel(dest, destLineWidth, Src, srcLineWidth, width, height);
end;

procedure MatrixMean(dest: PSingle; destLineWidth: NativeInt; Src: PSingle; srcLineWidth: NativeInt; width, height: NativeInt; RowWise: Boolean);
var kernel: TMatrixReduceKernel;
begin
  if (width <= 0) or (height <= 0) then exit;

  // both mean kernels reduce over one extent with a vector loop plus a scalar
  // tail, so no extent has to be lane aligned
  if RowWise then kernel := gMeanRow else kernel := gMeanCol;

  if kernel = nil then
    RefSumMean(dest, destLineWidth, Src, srcLineWidth, width, height, RowWise, True)
  else
    kernel(dest, destLineWidth, Src, srcLineWidth, width, height);
end;

function MatrixElementwiseNorm2(dest: PSingle; LineWidth: NativeInt; Width, height: NativeInt; doSqrt: Boolean): Single;
begin
  if (Width <= 0) or (height <= 0) then exit(0);

  // the kernels sum the squares of every column themselves, so the root is taken
  // once here and no column is folded in twice
  if gNorm2 = nil then
    Result := RefNorm2(dest, LineWidth, Width, height, doSqrt)
  else
  begin
    Result := gNorm2(dest, LineWidth, Width, height);
    if doSqrt then Result := Sqrt(Result);
  end;
end;

procedure MatrixNormalize(dest: PSingle; destLineWidth: NativeInt; Src: PSingle; srcLineWidth: NativeInt; width, height: NativeInt; RowWise: Boolean);
var kernel: TMatrixReduceKernel;
begin
  if (width <= 0) or (height <= 0) then exit;

  // the kernels zero a zero norm, so the empty matrix case above is the only
  // precondition
  if RowWise then kernel := gNormalizeRow else kernel := gNormalizeCol;

  if kernel = nil then
    RefNormalize(dest, destLineWidth, Src, srcLineWidth, width, height, RowWise)
  else
    kernel(dest, destLineWidth, Src, srcLineWidth, width, height);
end;

// structure

procedure MatrixTranspose(dest: PSingle; const destLineWidth: NativeInt; mt: PSingle; const LineWidth: NativeInt; width, height: NativeInt);
begin
  if (width <= 0) or (height <= 0) then exit;

  // the EvenW/EvenH variants need both dimensions to be lane aligned
  if (gTranspose = nil) or ((width and 3) <> 0) or ((height and 3) <> 0) then
    RefTranspose(dest, destLineWidth, mt, LineWidth, width, height)
  else
    gTranspose(dest, destLineWidth, mt, LineWidth, width, height);
end;

procedure MatrixTransposeInplace(mt: PSingle; const LineWidth: NativeInt; N: NativeInt);
begin
  if N <= 1 then exit;

  if gTransposeInplace = nil then
    RefTransposeInplace(mt, LineWidth, N)
  else
    gTransposeInplace(mt, LineWidth, N);
end;

// products

procedure MatrixMult(dest: PSingle; const destLineWidth: NativeInt; mt1, mt2: PSingle; width1: NativeInt; height1: NativeInt; width2: NativeInt; height2: NativeInt; const LineWidth1, LineWidth2: NativeInt);
begin
  if (width1 <= 0) or (height1 <= 0) or (width2 <= 0) or (height2 <= 0) then exit;

  // the EvenW1EvenW2 variants need both loop dimensions to be lane aligned
  if (gMult = nil) or ((width1 and 3) <> 0) or ((width2 and 3) <> 0) then
    RefMult(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2)
  else
    gMult(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2);
end;

procedure MatrixMtxVecMult(dest: PSingle; destLineWidth: NativeInt; mt1, v: PSingle; LineWidthMT, LineWidthV: NativeInt; width, height: NativeInt; alpha, beta: Single);
begin
  if (width <= 0) or (height <= 0) then exit;

  if gMtxVecMult = nil then
    RefMtxVecMult(dest, destLineWidth, mt1, v, LineWidthMT, LineWidthV, width, height, alpha, beta)
  else
    gMtxVecMult(dest, destLineWidth, mt1, v, LineWidthMT, LineWidthV, width, height, alpha, beta);
end;

procedure MatrixMtxVecMultT(dest: PSingle; destLineWidth: NativeInt; mt1, v: PSingle; LineWidthMT, LineWidthV: NativeInt; width, height: NativeInt; alpha, beta: Single);
begin
  if (width <= 0) or (height <= 0) then exit;

  if gMtxVecMultT = nil then
    RefMtxVecMultT(dest, destLineWidth, mt1, v, LineWidthMT, LineWidthV, width, height, alpha, beta)
  else
    gMtxVecMultT(dest, destLineWidth, mt1, v, LineWidthMT, LineWidthV, width, height, alpha, beta);
end;

function MatrixVecDotMult(x: PSingle; incX: NativeInt; y: PSingle; incY: NativeInt; N: NativeInt): Single;
begin
  Result := 0;
  if N <= 0 then exit;

  if (incX = sizeof(Single)) and (incY = sizeof(Single)) then
  begin
    if ((NativeUInt(x) and $0F) = 0) and ((NativeUInt(y) and $0F) = 0) and (gDotMultAligned <> nil) then
      Result := gDotMultAligned(x, y, N)
    else if gDotMultUnAligned <> nil then
      Result := gDotMultUnAligned(x, y, N)
    else
      Result := RefDotMult(x, incX, y, incY, N);
  end
  else if ((incX and 3) = 0) and ((incY and 3) = 0) and (gDotMultUneven <> nil) then
    Result := gDotMultUneven(x, y, incX, incY, N)
  else
    Result := RefDotMult(x, incX, y, incY, N);
end;

procedure MatrixRank1Update(A: PSingle; const LineWidthA: NativeInt; width, height: NativeInt; X, Y: PSingle; incX, incY: NativeInt; alpha: Single);
begin
  if (width <= 0) or (height <= 0) then exit;

  if (incX = sizeof(Single)) and (incY = sizeof(Single)) then
  begin
    // ASMRank1UpdateSeqAligned loads with movaps, so it needs the matrix base, the
    // matrix line width and Y to be 16 byte aligned - X is only read with movss.
    if ((NativeUInt(A) and $0F) = 0) and ((LineWidthA and $0F) = 0) and
       ((NativeUInt(Y) and $0F) = 0) and (gRank1SeqAligned <> nil) then
      gRank1SeqAligned(A, LineWidthA, width, height, X, Y, incX, incY, alpha)
    else if gRank1Seq <> nil then
      gRank1Seq(A, LineWidthA, width, height, X, Y, incX, incY, alpha)
    else
      RefRank1(A, LineWidthA, width, height, X, Y, incX, incY, alpha);
  end
  else if ((incX and 3) = 0) and ((incY and 3) = 0) and (gRank1NonSeq <> nil) then
    gRank1NonSeq(A, LineWidthA, width, height, X, Y, incX, incY, alpha)
  else
    RefRank1(A, LineWidthA, width, height, X, Y, incX, incY, alpha);
end;

// plane rotations

// rows: the pairs are (x, x + 1) inside a row, C/S are indexed by x

procedure RefPlaneRotRow(width, height: NativeInt; A: PSingle; const LineWidthA: NativeInt; C, S: PConstSingleArr; backward: Boolean);
var x, y, i: NativeInt; u, t, cv, sv: Single;
begin
  if (width < 2) or (height < 1) then exit;

  for y := 0 to height - 1 do
  begin
    i := (y*LineWidthA) div sizeof(Single);
    if backward then
    begin
      x := width - 2;
      while x >= 0 do
      begin
        u := A[x+i]; t := A[x+1+i]; cv := C^[x]; sv := S^[x];
        A[x+i] := u*cv + t*sv;
        A[x+1+i] := t*cv - u*sv;
        dec(x);
      end;
    end
    else
      for x := 0 to width - 2 do
      begin
        u := A[x+i]; t := A[x+1+i]; cv := C^[x]; sv := S^[x];
        A[x+i] := u*cv + t*sv;
        A[x+1+i] := t*cv - u*sv;
      end;
  end;
end;

// columns: the pairs are (y, y + 1) inside a column, C/S indexed by y
procedure RefPlaneRotCol(width, height: NativeInt; A: PSingle; const LineWidthA: NativeInt; C, S: PConstSingleArr; backward: Boolean);
var x, y, i, j: NativeInt; u, t, cv, sv: Single;
begin
  if (width < 1) or (height < 2) then exit;

  for x := 0 to width - 1 do
  begin
    if backward then
    begin
      y := height - 2;
      while y >= 0 do
      begin
        i := (y*LineWidthA) div sizeof(Single);
        j := ((y+1)*LineWidthA) div sizeof(Single);
        u := A[x+i]; t := A[x+j]; cv := C^[y]; sv := S^[y];
        A[x+i] := u*cv + t*sv;
        A[x+j] := t*cv - u*sv;
        dec(y);
      end;
    end
    else
      for y := 0 to height - 2 do
      begin
        i := (y*LineWidthA) div sizeof(Single);
        j := ((y+1)*LineWidthA) div sizeof(Single);
        u := A[x+i]; t := A[x+j]; cv := C^[y]; sv := S^[y];
        A[x+i] := u*cv + t*sv;
        A[x+j] := t*cv - u*sv;
      end;
  end;
end;

procedure ApplyPlaneRotSeqRVB(width, height: NativeInt; A: PSingle; const LineWidthA: NativeInt; C, S: PConstSingleArr);
begin
  if gRotRVB = nil then RefPlaneRotRow(width, height, A, LineWidthA, C, S, True)
  else gRotRVB(width, height, A, LineWidthA, C, S);
end;

procedure ApplyPlaneRotSeqRVF(width, height: NativeInt; A: PSingle; const LineWidthA: NativeInt; C, S: PConstSingleArr);
begin
  if gRotRVF = nil then RefPlaneRotRow(width, height, A, LineWidthA, C, S, False)
  else gRotRVF(width, height, A, LineWidthA, C, S);
end;

procedure ApplyPlaneRotSeqLVB(width, height: NativeInt; A: PSingle; const LineWidthA: NativeInt; C, S: PConstSingleArr);
begin
  if gRotLVB = nil then RefPlaneRotCol(width, height, A, LineWidthA, C, S, True)
  else gRotLVB(width, height, A, LineWidthA, C, S);
end;

procedure ApplyPlaneRotSeqLVF(width, height: NativeInt; A: PSingle; const LineWidthA: NativeInt; C, S: PConstSingleArr);
begin
  if gRotLVF = nil then RefPlaneRotCol(width, height, A, LineWidthA, C, S, False)
  else gRotLVF(width, height, A, LineWidthA, C, S);
end;

procedure MatrixRotate(N: NativeInt; DX: PSingle; const LineWidthDX: NativeInt; DY: PSingle; LineWidthDY: NativeInt; const c, s: Single);
var i, ix, iy: NativeInt; u, t: Single;
begin
  if N <= 0 then exit;

  if gMatrixRotate <> nil then
  begin
    gMatrixRotate(N, DX, LineWidthDX, DY, LineWidthDY, c, s);
    exit;
  end;

  for i := 0 to N - 1 do
  begin
    ix := (i*LineWidthDX) div sizeof(Single);
    iy := (i*LineWidthDY) div sizeof(Single);
    u := DX[ix];
    t := DY[iy];
    DX[ix] := u*c + t*s;
    DY[iy] := t*c - u*s;
  end;
end;

// distance matrices

procedure MtxDistanceSqr(dist: PSingle; LineWidthDist: NativeInt; X, Y: PSingle; xLen, yLen: NativeInt);
begin
  if (xLen <= 0) or (yLen <= 0) then exit;

  if gDistSqr = nil then RefDistance(dist, LineWidthDist, X, Y, xLen, yLen, False)
  else gDistSqr(dist, LineWidthDist, X, Y, xLen, yLen);
end;

procedure MtxDistanceAbs(dist: PSingle; LineWidthDist: NativeInt; X, Y: PSingle; xLen, yLen: NativeInt);
begin
  if (xLen <= 0) or (yLen <= 0) then exit;

  if gDistAbs = nil then RefDistance(dist, LineWidthDist, X, Y, xLen, yLen, True)
  else gDistAbs(dist, LineWidthDist, X, Y, xLen, yLen);
end;

initialization
  InitMathFunctions(GetBestCPUInstrType, False);

end.
