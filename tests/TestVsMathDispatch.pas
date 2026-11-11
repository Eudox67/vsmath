unit TestVsMathDispatch;

{$MODE OBJFPC}{$H+}

interface

uses
  fpcunit, testregistry, MatrixASMDispatchSingle;

type
  { a matrix buffer with a caller chosen line width padding }
  TBuffer = record
    Data: PSingle;      { first live element }
    Base: Pointer;      { raw block, released with FreeMem }
    LineWidth: NativeInt;
  end;

  TLevelTest = procedure(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);

  TvsmathDispatchTests = class(TTestCase)
  private
    procedure AssertSame(const aName: string; const baseline, actual: TBuffer; width, height: NativeInt);
    procedure RunLevels(const aName: string; width, height: NativeInt;
                        const baseline: TBuffer; var actual: TBuffer; test: TLevelTest);
  published
    procedure TestCPULevelSelection;
    procedure TestDispatchSelectsVectorKernels;
    procedure TestMeanRandomShapes;
    procedure TestMemInit;
    procedure TestAllocHelpers;
    procedure TestCopyInit;
    procedure TestRowColSwap;
    procedure TestAddSub;
    procedure TestElemMultDiv;
    procedure TestAddVecSubVec;
    procedure TestVecAdd;
    procedure TestScalarOps;
    procedure TestSqrtAbs;
    procedure TestMinMax;
    procedure TestSumMean;
    procedure TestSumAnyExtent;
    procedure TestNorm2Normalize;
    procedure TestNormalizePaddedStrides;
    procedure TestNormalizeZeroNorm;
    procedure TestTranspose;
    procedure TestMult;
    procedure TestMtxVecMult;
    procedure TestMtxVecMultT;
    procedure TestMtxVecMultTStrided;
    procedure TestVecDotMult;
    procedure TestRank1Update;
    procedure TestRank1UpdateStrided;
    procedure TestRank1UpdateAlignedPath;
    procedure TestPlaneRotations;
    procedure TestDistance;
  end;

implementation

uses
  SysUtils, Math, MatrixConstSingle;

var
  cLevels: array[0..3] of TCPUInstrType = (itFPU, itSSE, itAVX, itFMA);
  cLevelNames: array[0..3] of string = ('itFPU', 'itSSE', 'itAVX', 'itFMA');

procedure MakeBuffer(out B: TBuffer; width, height, padBytes: NativeInt);
begin
  { the line width stays a multiple of sizeof(Single); padBytes shifts the row
    start so it is no longer 16 byte aligned }
  B.LineWidth := ((width + 3) and not 3) * sizeof(Single) + padBytes;
  B.Base := nil;
  B.Data := MtxAllocAlign(B.LineWidth * height + 64, B.Base);
  if B.Data = nil then
    raise Exception.CreateFmt('MakeBuffer: allocation of %d bytes failed', [B.LineWidth * height + 64]);
end;

{ a contiguous vector: the line width is exactly one element }
procedure MakeVector(out B: TBuffer; n: NativeInt);
begin
  B.LineWidth := sizeof(Single);
  B.Base := nil;
  B.Data := MtxAllocAlign(n * sizeof(Single) + 64, B.Base);
  if B.Data = nil then
    raise Exception.CreateFmt('MakeVector: allocation of %d elements failed', [n]);
end;

{ a vector whose elements are strideBytes apart: element x lives at row x of a
  one element wide buffer, so it is addressed as IndexOf(B, 0, x) and n such
  elements need n * strideBytes bytes }
procedure MakeStridedVector(out B: TBuffer; n, strideBytes: NativeInt);
begin
  B.LineWidth := strideBytes;
  B.Base := nil;
  B.Data := MtxAllocAlign(strideBytes * n + 64, B.Base);
  if B.Data = nil then
    raise Exception.CreateFmt('MakeStridedVector: allocation of %d bytes failed',
                              [strideBytes * n + 64]);
end;

procedure FreeBuffer(var B: TBuffer);
begin
  if B.Base <> nil then FreeMem(B.Base);
  B.Base := nil;
  B.Data := nil;
end;

function IndexOf(const B: TBuffer; x, y: NativeInt): NativeInt; inline;
begin
  Result := x + (y*B.LineWidth) div sizeof(Single);
end;

{ live elements become start + (x + 3*y)*step, exactly representable in Single }
procedure FillBuffer(var B: TBuffer; width, height: NativeInt; start, step: Single);
var x, y: NativeInt;
begin
  for y := 0 to height - 1 do
    for x := 0 to width - 1 do
      B.Data[IndexOf(B, x, y)] := start + (x + 3*y) * step;
end;

procedure CopyBuffer(const src: TBuffer; var dst: TBuffer; width, height: NativeInt);
var x, y: NativeInt;
begin
  for y := 0 to height - 1 do
    for x := 0 to width - 1 do
      dst.Data[IndexOf(dst, x, y)] := src.Data[IndexOf(src, x, y)];
end;

function SelectLevel(lvl: TCPUInstrType): Boolean;
begin
  InitMathFunctions(lvl, False);
  Result := GetCurCPUInstrType = lvl;
end;

procedure TvsmathDispatchTests.AssertSame(const aName: string; const baseline, actual: TBuffer; width, height: NativeInt);
var x, y: NativeInt; e, a: Single;
begin
  for y := 0 to height - 1 do
    for x := 0 to width - 1 do
    begin
      e := baseline.Data[IndexOf(baseline, x, y)];
      a := actual.Data[IndexOf(actual, x, y)];
      if e <> a then
        Fail(Format('%s: mismatch at (%d,%d): expected %.8g, got %.8g',
                    [aName, x, y, e, a]));
    end;
end;

procedure TvsmathDispatchTests.RunLevels(const aName: string; width, height: NativeInt;
                                         const baseline: TBuffer; var actual: TBuffer; test: TLevelTest);
var i: Integer;
begin
  for i := 0 to High(cLevels) do
    if SelectLevel(cLevels[i]) then
    begin
      test(width, height, baseline, actual, cLevelNames[i]);
      AssertSame(aName + ' at ' + cLevelNames[i], baseline, actual, width, height);
    end;
end;

// shared operands

var
  gA, gB, gC, gBase, gAct: TBuffer;
  { lane aligned widths plus the scalar tail cases }
  cWidths: array[0..4] of NativeInt = (8, 6, 5, 3, 1);
  cPads: array[0..1] of NativeInt = (0, 4);

// level selection

procedure TvsmathDispatchTests.TestCPULevelSelection;
begin
  AssertTrue('itFPU must always be selectable', SelectLevel(itFPU));
  AssertEquals('itFPU reported back', Ord(itFPU), Ord(GetCurCPUInstrType));

  if SelectLevel(itSSE) then
    AssertEquals('itSSE reported back', Ord(itSSE), Ord(GetCurCPUInstrType));
  if SelectLevel(itAVX) then
    AssertEquals('itAVX reported back', Ord(itAVX), Ord(GetCurCPUInstrType));
  if SelectLevel(itFMA) then
    AssertEquals('itFMA reported back', Ord(itFMA), Ord(GetCurCPUInstrType));

  { the best level of this machine must be executable, so asking for it is
    never clamped down to something else }
  InitMathFunctions(GetBestCPUInstrType, False);
  AssertEquals('GetBestCPUInstrType is executable',
               Ord(GetBestCPUInstrType), Ord(GetCurCPUInstrType));

  { a request for a level the CPU cannot run must be clamped, never honoured }
  if GetBestCPUInstrType <> itFMA then
  begin
    InitMathFunctions(itFMA, False);
    AssertTrue('itFMA request clamped to an executable level',
               GetCurCPUInstrType <> itFMA);
  end;

  SelectLevel(itFPU);
end;

// memory

procedure TvsmathDispatchTests.TestDispatchSelectsVectorKernels;
var
  src, scalarDest, vectorDest : array[0..3] of Single;
  scalarSum, laneSum : Single;
  lvl : TCPUInstrType;
  li : Integer;
const
  cLevels: array[0..2] of TCPUInstrType = (itSSE, itAVX, itFMA);
  cNames: array[0..2] of string = ('itSSE', 'itAVX', 'itFMA');
begin
  { Tripwire for the packaging bug fixed in this release: x64 was undefined in
    MatrixASMDispatchSingle, so the kernel tables compiled out and every level
    ran the scalar reference. A row sum is enough to see the difference, because
    a lane grouped kernel adds the four values in a different order than the
    reference loop. }
  src[0] := 0.824157119;
  src[1] := 0.001580831;
  src[2] := 21.8402481;
  src[3] := 0.109356605;

  scalarSum := ((src[0] + src[1]) + src[2]) + src[3];
  laneSum := (src[0] + src[2]) + (src[1] + src[3]);
  AssertTrue('the probe values do not separate the two summation orders',
    scalarSum <> laneSum);

  InitMathFunctions(itFPU, False);
  MatrixSum(@scalarDest[0], SizeOf(Single), @src[0], 4 * SizeOf(Single), 4, 1, True);
  AssertEquals('the reference row sum is not the sequential order',
    scalarSum, scalarDest[0]);

  for li := 0 to High(cLevels) do
  begin
    lvl := cLevels[li];
    InitMathFunctions(lvl, False);
    if GetCurCPUInstrType <> lvl then
      Continue;

    vectorDest[0] := -1;
    MatrixSum(@vectorDest[0], SizeOf(Single), @src[0], 4 * SizeOf(Single), 4, 1, True);
    AssertEquals(cNames[li] + ': MatrixSum did not use a vector kernel ' +
      '(the scalar reference ran instead)', laneSum, vectorDest[0]);

    vectorDest[0] := -1;
    MatrixMean(@vectorDest[0], SizeOf(Single), @src[0], 4 * SizeOf(Single), 4, 1, True);
    AssertEquals(cNames[li] + ': MatrixMean did not use a vector kernel ' +
      '(the scalar reference ran instead)', laneSum / 4, vectorDest[0]);
  end;

  InitMathFunctions(GetBestCPUInstrType, False);
end;
procedure TvsmathDispatchTests.TestMeanRandomShapes;
const
  cLevels: array[0..3] of TCPUInstrType = (itFPU, itSSE, itAVX, itFMA);
  cNames: array[0..3] of string = ('itFPU', 'itSSE', 'itAVX', 'itFMA');
  cTrials = 200;
var
  src, dst, ref: PSingle;
  w, h, i, t, li, count: NativeInt;
  dwElements, idx, y, x: NativeInt;
  rowWise: Boolean;
  mag, rel, want, got: Double;
begin
  { The fixed shapes above use integers so the comparison can be exact. This
    sweep uses random reals at random extents (including destination padding) and
    compares every level against the scalar reference with a tolerance scaled by
    the row/column magnitude, which is what a reordered Single sum is worth. }
  RandSeed := 20261028;
  for t := 0 to cTrials - 1 do
  begin
    w := 1 + Random(40);
    h := 1 + Random(9);
    dwElements := 1 + Random(3);
    rowWise := (t and 1) = 0;
    count := w;
    if rowWise then count := h;

    GetMem(src, w * h * SizeOf(Single));
    GetMem(dst, (count + 3) * dwElements * SizeOf(Single));
    GetMem(ref, (count + 3) * dwElements * SizeOf(Single));
    try
      for i := 0 to w * h - 1 do
        src[i] := (Random - 0.5) * 1000;

      SelectLevel(itFPU);
      for i := 0 to (count + 3) * dwElements - 1 do
        ref[i] := -12345;
      MatrixMean(ref, dwElements * SizeOf(Single), src, w * SizeOf(Single), w, h, rowWise);

      for li := 1 to High(cLevels) do
        if SelectLevel(cLevels[li]) then
        begin
          for i := 0 to (count + 3) * dwElements - 1 do
            dst[i] := -12345;
          MatrixMean(dst, dwElements * SizeOf(Single), src, w * SizeOf(Single), w, h, rowWise);

          for idx := 0 to count - 1 do
          begin
            mag := 0;
            if rowWise then
            begin
              for x := 0 to w - 1 do
                mag := mag + Abs(src[idx * w + x]);
              mag := mag / w;
            end
            else
            begin
              for y := 0 to h - 1 do
                mag := mag + Abs(src[y * w + idx]);
              mag := mag / h;
            end;
            if mag < 1.0 then mag := 1.0;

            got := dst[idx * dwElements];
            want := ref[idx * dwElements];
            rel := Abs(got - want) / mag;
            AssertTrue(Format('%s: %s mean at %dx%d, dest %d elements, entry %d: ' +
              'got %.9g, reference %.9g (relative %.3g)', [cNames[li],
              BoolToStr(rowWise, 'row', 'column'), w, h, dwElements, idx,
              got, want, rel]), rel <= 1.0e-5);
          end;
        end;
    finally
      FreeMem(src);
      FreeMem(dst);
      FreeMem(ref);
    end;
  end;

  InitMathFunctions(GetBestCPUInstrType, False);
end;
procedure TvsmathDispatchTests.TestMemInit;
var i, k, n: Integer; base: Pointer; p: PSingle;
begin
  n := 96;                     { 384 bytes, an exact multiple of 32 }
  for i := 0 to High(cLevels) do
    if SelectLevel(cLevels[i]) then
    begin
      base := nil;
      p := MtxAllocAlign((n + 16) * sizeof(Single), base);
      try
        { start one element in, so the block handed to the kernel is not 32
          byte aligned, and stop two elements short of the end }
        MtxMemInit(p + 1, (n - 3) * sizeof(Single), 2.25);

        AssertEquals(cLevelNames[i] + ': head stays untouched', 0.0, p[0]);
        for k := 1 to n - 3 do
          AssertEquals(Format('%s: element %d', [cLevelNames[i], k]), 2.25, p[k]);
        AssertEquals(cLevelNames[i] + ': first element after the block', 0.0, p[n-2]);
        AssertEquals(cLevelNames[i] + ': last element', 0.0, p[n-1]);
      finally
        FreeMem(base);
      end;
    end;
end;

procedure TvsmathDispatchTests.TestAllocHelpers;
var p, q: Pointer; pl, ql: NativeInt;
begin
  { MtxAlloc zeroes the block and rounds it up to a multiple of 32 bytes }
  p := MtxAlloc(100);
  AssertTrue('MtxAlloc(100) returned nil', p <> nil);
  try
    AssertEquals('MtxAlloc is 32 byte aligned', 0, NativeUInt(p) and $1F);
    AssertEquals('MtxAlloc zeroed the block', 0.0, PSingle(p)^);
  finally
    FreeMem(p);
  end;

  { MtxAllocAlign(width, height, ...) rounds width up to a multiple of four }
  p := nil; q := nil;
  pl := 0; ql := 0;
  p := MtxAllocAlign(5, 3, pl, q);
  AssertTrue('MtxAllocAlign(5,3) returned nil', p <> nil);
  try
    AssertEquals('line width rounded to a lane group', 8 * sizeof(Single), pl);
    AssertEquals('data pointer is 32 byte aligned', 0, NativeUInt(p) and $1F);
    AssertEquals('first element', 0.0, PSingle(p)[0]);
    AssertEquals('last element of the last row', 0.0, PSingle(p)[(2*(pl div sizeof(Single))) + 4]);
  finally
    FreeMem(q);
  end;
end;

// copy / init / swaps

procedure DoCopy(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  MatrixCopy(dst.Data, dst.LineWidth, gA.Data, gA.LineWidth, width, height);
end;

procedure DoInit(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  MatrixInit(dst.Data, dst.LineWidth, width, height, 2.5);
end;

procedure TvsmathDispatchTests.TestCopyInit;
var wi, pi: Integer; w, h: NativeInt;
begin
  h := 5;
  for wi := 0 to High(cWidths) do
    for pi := 0 to High(cPads) do
    begin
      w := cWidths[wi];
      MakeBuffer(gA, w, h, cPads[pi]);
      MakeBuffer(gBase, w, h, cPads[pi]);
      MakeBuffer(gAct, w, h, cPads[pi]);
      try
        FillBuffer(gA, w, h, -3.75, 1.25);

        SelectLevel(itFPU);
        MatrixCopy(gBase.Data, gBase.LineWidth, gA.Data, gA.LineWidth, w, h);
        RunLevels('MatrixCopy', w, h, gBase, gAct, @DoCopy);

        FillBuffer(gAct, w, h, 0, 0);
        SelectLevel(itFPU);
        MatrixInit(gBase.Data, gBase.LineWidth, w, h, 2.5);
        RunLevels('MatrixInit', w, h, gBase, gAct, @DoInit);
      finally
        FreeBuffer(gA); FreeBuffer(gBase); FreeBuffer(gAct);
      end;
    end;
end;

procedure DoRowSwap(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  { in place operation: start from the pristine input every time }
  CopyBuffer(gA, dst, width, height);
  MatrixRowSwap(dst.Data, dst.Data + dst.LineWidth div sizeof(Single), width);
end;

procedure TvsmathDispatchTests.TestRowColSwap;
var wi: Integer; w, h, x, y: NativeInt;
begin
  h := 4;

  { row swap: gA holds the input, row 0 is exchanged with row 1 }
  for wi := 0 to High(cWidths) do
  begin
    w := cWidths[wi];
    MakeBuffer(gA, w, h, 4);
    MakeBuffer(gBase, w, h, 4);
    MakeBuffer(gAct, w, h, 4);
    try
      FillBuffer(gA, w, h, 100.0, 1.0);

      CopyBuffer(gA, gBase, w, h);
      SelectLevel(itFPU);
      MatrixRowSwap(gBase.Data, gBase.Data + gBase.LineWidth div sizeof(Single), w);
      RunLevels('MatrixRowSwap', w, h, gBase, gAct, @DoRowSwap);
    finally
      FreeBuffer(gA); FreeBuffer(gBase); FreeBuffer(gAct);
    end;
  end;

  { column swap: column 0 against column 2 }
  w := 6;
  MakeBuffer(gA, w, h, 0);
  MakeBuffer(gBase, w, h, 0);
  try
    FillBuffer(gA, w, h, 1.0, 1.0);
    CopyBuffer(gA, gBase, w, h);

    SelectLevel(itFPU);
    MatrixColSwap(gBase.Data, gBase.Data + 2, gBase.LineWidth, h);

    for y := 0 to h - 1 do
    begin
      AssertEquals(Format('MatrixColSwap (0,%d)', [y]),
                   gA.Data[IndexOf(gA, 2, y)], gBase.Data[IndexOf(gBase, 0, y)]);
      AssertEquals(Format('MatrixColSwap (1,%d) stays', [y]),
                   gA.Data[IndexOf(gA, 1, y)], gBase.Data[IndexOf(gBase, 1, y)]);
      AssertEquals(Format('MatrixColSwap (2,%d)', [y]),
                   gA.Data[IndexOf(gA, 0, y)], gBase.Data[IndexOf(gBase, 2, y)]);
      for x := 3 to w - 1 do
        AssertEquals(Format('MatrixColSwap (%d,%d) stays', [x, y]),
                     gA.Data[IndexOf(gA, x, y)], gBase.Data[IndexOf(gBase, x, y)]);
    end;
  finally
    FreeBuffer(gA); FreeBuffer(gBase);
  end;
end;

// elementwise binary operations

procedure DoAdd(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  MatrixAdd(dst.Data, dst.LineWidth, gA.Data, gB.Data, width, height, gA.LineWidth, gB.LineWidth);
end;

procedure DoSub(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  MatrixSub(dst.Data, dst.LineWidth, gA.Data, gB.Data, width, height, gA.LineWidth, gB.LineWidth);
end;

procedure DoElemMult(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  MatrixElemMult(dst.Data, dst.LineWidth, gA.Data, gB.Data, width, height, gA.LineWidth, gB.LineWidth);
end;

procedure DoElemDiv(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  MatrixElemDiv(dst.Data, dst.LineWidth, gA.Data, gB.Data, width, height, gA.LineWidth, gB.LineWidth);
end;

procedure TvsmathDispatchTests.TestAddSub;
var wi, pi: Integer; w, h: NativeInt;
begin
  h := 4;
  for wi := 0 to High(cWidths) do
    for pi := 0 to High(cPads) do
    begin
      w := cWidths[wi];
      MakeBuffer(gA, w, h, cPads[pi]);
      MakeBuffer(gB, w, h, cPads[pi]);
      MakeBuffer(gBase, w, h, cPads[pi] + 0);
      MakeBuffer(gAct, w, h, cPads[pi] + 0);
      try
        FillBuffer(gA, w, h, -6.5, 1.25);
        FillBuffer(gB, w, h, 2.5, 0.5);

        SelectLevel(itFPU);
        MatrixAdd(gBase.Data, gBase.LineWidth, gA.Data, gB.Data, w, h, gA.LineWidth, gB.LineWidth);
        RunLevels('MatrixAdd', w, h, gBase, gAct, @DoAdd);

        SelectLevel(itFPU);
        MatrixSub(gBase.Data, gBase.LineWidth, gA.Data, gB.Data, w, h, gA.LineWidth, gB.LineWidth);
        RunLevels('MatrixSub', w, h, gBase, gAct, @DoSub);

      finally
        FreeBuffer(gA); FreeBuffer(gB); FreeBuffer(gBase); FreeBuffer(gAct);
      end;
    end;
end;

procedure TvsmathDispatchTests.TestElemMultDiv;
var wi, pi: Integer; w, h: NativeInt;
begin
  h := 4;
  for wi := 0 to High(cWidths) do
    for pi := 0 to High(cPads) do
    begin
      w := cWidths[wi];
      MakeBuffer(gA, w, h, cPads[pi]);
      MakeBuffer(gB, w, h, cPads[pi]);
      MakeBuffer(gBase, w, h, cPads[pi]);
      MakeBuffer(gAct, w, h, cPads[pi]);
      try
        FillBuffer(gA, w, h, -6.5, 1.25);
        FillBuffer(gB, w, h, 2.5, 0.5);

        SelectLevel(itFPU);
        MatrixElemMult(gBase.Data, gBase.LineWidth, gA.Data, gB.Data, w, h, gA.LineWidth, gB.LineWidth);
        RunLevels('MatrixElemMult', w, h, gBase, gAct, @DoElemMult);

        SelectLevel(itFPU);
        MatrixElemDiv(gBase.Data, gBase.LineWidth, gA.Data, gB.Data, w, h, gA.LineWidth, gB.LineWidth);
        RunLevels('MatrixElemDiv', w, h, gBase, gAct, @DoElemDiv);
      finally
        FreeBuffer(gA); FreeBuffer(gB); FreeBuffer(gBase); FreeBuffer(gAct);
      end;
    end;
end;

// vector add / subtract

procedure DoAddVecRow(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, width, height);
  MatrixAddVec(dst.Data, dst.LineWidth, gB.Data, sizeof(Single), width, height, True);
end;

procedure DoAddVecRowStrided(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, width, height);
  MatrixAddVec(dst.Data, dst.LineWidth, gB.Data, 2 * sizeof(Single), width, height, True);
end;

procedure DoAddVecCol(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, width, height);
  MatrixAddVec(dst.Data, dst.LineWidth, gB.Data, sizeof(Single), width, height, False);
end;

procedure DoSubVecRow(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, width, height);
  MatrixSubVec(dst.Data, dst.LineWidth, gB.Data, sizeof(Single), width, height, True);
end;

procedure DoSubVecCol(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, width, height);
  MatrixSubVec(dst.Data, dst.LineWidth, gB.Data, sizeof(Single), width, height, False);
end;

procedure TvsmathDispatchTests.TestAddVecSubVec;
var wi: Integer; w, h: NativeInt;
begin
  h := 5;
  for wi := 0 to High(cWidths) do
  begin
    w := cWidths[wi];
    MakeBuffer(gA, w, h, 4);
    MakeBuffer(gB, w + 8, 1, 0);
    MakeBuffer(gBase, w, h, 4);
    MakeBuffer(gAct, w, h, 4);
    try
      FillBuffer(gA, w, h, 1.0, 0.5);
      FillBuffer(gB, w + 8, 1, 100.0, 2.0);

      SelectLevel(itFPU);
      MatrixAddVec(gA.Data, gA.LineWidth, gB.Data, sizeof(Single), w, h, True);
      CopyBuffer(gA, gBase, w, h);
      FillBuffer(gA, w, h, 1.0, 0.5);
      RunLevels('MatrixAddVec rowWise', w, h, gBase, gAct, @DoAddVecRow);

      SelectLevel(itFPU);
      MatrixAddVec(gA.Data, gA.LineWidth, gB.Data, 2 * sizeof(Single), w, h, True);
      CopyBuffer(gA, gBase, w, h);
      FillBuffer(gA, w, h, 1.0, 0.5);
      RunLevels('MatrixAddVec rowWise strided', w, h, gBase, gAct, @DoAddVecRowStrided);

      SelectLevel(itFPU);
      MatrixAddVec(gA.Data, gA.LineWidth, gB.Data, sizeof(Single), w, h, False);
      CopyBuffer(gA, gBase, w, h);
      FillBuffer(gA, w, h, 1.0, 0.5);
      RunLevels('MatrixAddVec columnWise', w, h, gBase, gAct, @DoAddVecCol);

      SelectLevel(itFPU);
      MatrixSubVec(gA.Data, gA.LineWidth, gB.Data, sizeof(Single), w, h, True);
      CopyBuffer(gA, gBase, w, h);
      FillBuffer(gA, w, h, 1.0, 0.5);
      RunLevels('MatrixSubVec rowWise', w, h, gBase, gAct, @DoSubVecRow);

      SelectLevel(itFPU);
      MatrixSubVec(gA.Data, gA.LineWidth, gB.Data, sizeof(Single), w, h, False);
      CopyBuffer(gA, gBase, w, h);
      FillBuffer(gA, w, h, 1.0, 0.5);
      RunLevels('MatrixSubVec columnWise', w, h, gBase, gAct, @DoSubVecCol);
    finally
      FreeBuffer(gA); FreeBuffer(gB); FreeBuffer(gBase); FreeBuffer(gAct);
    end;
  end;
end;

// X := X + alpha*Y

procedure DoVecAddSeq(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, width, height);
  MatrixVecAdd(dst.Data, sizeof(Single), gB.Data, sizeof(Single), width, 1.5);
end;

procedure TvsmathDispatchTests.TestVecAdd;
var i, k, n, si: NativeInt; sx, sy: NativeInt;
    sizes: array[0..2] of NativeInt = (8, 6, 5);
begin
  for si := 0 to High(sizes) do
  begin
    n := sizes[si];
    MakeBuffer(gA, n, 1, 4);
    MakeBuffer(gB, n, 1, 4);
    MakeBuffer(gBase, n, 1, 4);
    MakeBuffer(gAct, n, 1, 4);
    try
      FillBuffer(gA, n, 1, 1.0, 1.0);
      FillBuffer(gB, n, 1, -2.0, 0.5);

      SelectLevel(itFPU);
      MatrixVecAdd(gA.Data, sizeof(Single), gB.Data, sizeof(Single), n, 1.5);
      CopyBuffer(gA, gBase, n, 1);
      FillBuffer(gA, n, 1, 1.0, 1.0);
      RunLevels('MatrixVecAdd', n, 1, gBase, gAct, @DoVecAddSeq);
    finally
      FreeBuffer(gA); FreeBuffer(gB); FreeBuffer(gBase); FreeBuffer(gAct);
    end;
  end;

  { the strided path writes every second element only, so check it directly }
  n := 6;
  MakeBuffer(gA, 2*n, 1, 0);
  MakeBuffer(gB, n, 1, 0);
  try
    for k := 0 to 2*n - 1 do
      gA.Data[k] := 2.0;
    for k := 0 to n - 1 do
      gB.Data[k] := 0.5;

    for i := 0 to High(cLevels) do
      if SelectLevel(cLevels[i]) then
      begin
        for k := 0 to 2*n - 1 do
          gA.Data[k] := 2.0;
        MatrixVecAdd(gA.Data, 2 * sizeof(Single), gB.Data, sizeof(Single), n, 2.0);
        for k := 0 to n - 1 do
        begin
          sx := 2*k;
          sy := sx + 1;
          AssertEquals(Format('%s: even element %d', [cLevelNames[i], k]), 3.0, gA.Data[sx]);
          AssertEquals(Format('%s: odd element %d untouched', [cLevelNames[i], k]), 2.0, gA.Data[sy]);
        end;
      end;
  finally
    FreeBuffer(gA); FreeBuffer(gB);
  end;
end;

// scalar add / scale

procedure DoElemAdd(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, width, height);
  MatrixElemAdd(dst.Data, dst.LineWidth, width, height, 2.5);
end;

procedure DoAddAndScale(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, width, height);
  MatrixAddAndScale(dst.Data, dst.LineWidth, width, height, 1.5, 2.0);
end;

procedure DoScaleAndAdd(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, width, height);
  MatrixScaleAndAdd(dst.Data, dst.LineWidth, width, height, 1.5, 2.0);
end;

procedure TvsmathDispatchTests.TestScalarOps;
var wi, pi: Integer; w, h: NativeInt;
begin
  h := 4;
  for wi := 0 to High(cWidths) do
    for pi := 0 to High(cPads) do
    begin
      w := cWidths[wi];
      MakeBuffer(gA, w, h, cPads[pi]);
      MakeBuffer(gBase, w, h, cPads[pi]);
      MakeBuffer(gAct, w, h, cPads[pi]);
      try
        FillBuffer(gA, w, h, -3.5, 0.5);

        CopyBuffer(gA, gBase, w, h);
        SelectLevel(itFPU);
        MatrixElemAdd(gBase.Data, gBase.LineWidth, w, h, 2.5);
        RunLevels('MatrixElemAdd', w, h, gBase, gAct, @DoElemAdd);

        CopyBuffer(gA, gBase, w, h);
        SelectLevel(itFPU);
        MatrixAddAndScale(gBase.Data, gBase.LineWidth, w, h, 1.5, 2.0);
        RunLevels('MatrixAddAndScale', w, h, gBase, gAct, @DoAddAndScale);

        CopyBuffer(gA, gBase, w, h);
        SelectLevel(itFPU);
        MatrixScaleAndAdd(gBase.Data, gBase.LineWidth, w, h, 1.5, 2.0);
        RunLevels('MatrixScaleAndAdd', w, h, gBase, gAct, @DoScaleAndAdd);
      finally
        FreeBuffer(gA); FreeBuffer(gBase); FreeBuffer(gAct);
      end;
    end;
end;

// sqrt / abs

{ exact squares, so Sqrt is exact in Single }
procedure FillSquares(var B: TBuffer; width, height: NativeInt);
var x, y, n: NativeInt;
begin
  for y := 0 to height - 1 do
    for x := 0 to width - 1 do
    begin
      n := x + 3*y + 1;
      B.Data[IndexOf(B, x, y)] := n * n;
    end;
end;

procedure DoSqrt(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, width, height);
  MatrixSQRT(dst.Data, dst.LineWidth, width, height);
end;

procedure DoAbs(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, width, height);
  MatrixAbs(dst.Data, dst.LineWidth, width, height);
end;

procedure TvsmathDispatchTests.TestSqrtAbs;
var wi, pi: Integer; w, h, x, y: NativeInt;
begin
  h := 4;
  for wi := 0 to High(cWidths) do
    for pi := 0 to High(cPads) do
    begin
      w := cWidths[wi];
      MakeBuffer(gA, w, h, cPads[pi]);
      MakeBuffer(gBase, w, h, cPads[pi]);
      MakeBuffer(gAct, w, h, cPads[pi]);
      try
        FillSquares(gA, w, h);
        CopyBuffer(gA, gBase, w, h);
        SelectLevel(itFPU);
        MatrixSQRT(gBase.Data, gBase.LineWidth, w, h);
        RunLevels('MatrixSQRT', w, h, gBase, gAct, @DoSqrt);

        { the reference is the geometric expectation, checked explicitly }
        for y := 0 to h - 1 do
          for x := 0 to w - 1 do
            AssertEquals(Format('MatrixSQRT value at (%d,%d)', [x, y]),
                         x + 3*y + 1, gBase.Data[IndexOf(gBase, x, y)]);

        FillBuffer(gA, w, h, -8.0, -0.5);
        CopyBuffer(gA, gBase, w, h);
        SelectLevel(itFPU);
        MatrixAbs(gBase.Data, gBase.LineWidth, w, h);
        RunLevels('MatrixAbs', w, h, gBase, gAct, @DoAbs);
      finally
        FreeBuffer(gA); FreeBuffer(gBase); FreeBuffer(gAct);
      end;
    end;
end;

// min / max

procedure TvsmathDispatchTests.TestMinMax;
var wi, i: Integer; w, h, x, y: NativeInt;
    mn, mx, amn, amx, v: Single;
    lvl: string;
begin
  h := 4;
  for wi := 0 to High(cWidths) do
  begin
    w := cWidths[wi];
    MakeBuffer(gA, w, h, 4);
    try
      FillBuffer(gA, w, h, -6.5, 0.5);

      mn := 1.0E30; mx := -1.0E30; amn := 1.0E30; amx := -1.0E30;
      for y := 0 to h - 1 do
        for x := 0 to w - 1 do
        begin
          v := gA.Data[IndexOf(gA, x, y)];
          if v < mn then mn := v;
          if v > mx then mx := v;
          if Abs(v) < amn then amn := Abs(v);
          if Abs(v) > amx then amx := Abs(v);
        end;

      for i := 0 to High(cLevels) do
        if SelectLevel(cLevels[i]) then
        begin
          lvl := cLevelNames[i];
          AssertEquals(lvl + ': MatrixMin', mn, MatrixMin(gA.Data, w, h, gA.LineWidth));
          AssertEquals(lvl + ': MatrixMax', mx, MatrixMax(gA.Data, w, h, gA.LineWidth));
          AssertEquals(lvl + ': MatrixAbsMin', amn, MatrixAbsMin(gA.Data, w, h, gA.LineWidth));
          AssertEquals(lvl + ': MatrixAbsMax', amx, MatrixAbsMax(gA.Data, w, h, gA.LineWidth));
        end;
    finally
      FreeBuffer(gA);
    end;
  end;
end;

// sum / mean

{ The kernels reduce over `width` (rows) or `height` (columns) and carry their
  own tail loop, so neither extent has to be a multiple of the vector width any
  more. Every value is a multiple of 0.5 and every partial sum is small enough
  to be exact in Single, so the comparison stays exact even though the kernels
  accumulate lane wise. Both a tightly packed destination (one vector store) and
  a padded one (one store per lane) are covered. }
procedure TvsmathDispatchTests.TestSumAnyExtent;
const
  cExtents: array[0..7] of NativeInt = (1, 2, 3, 4, 5, 7, 8, 11);
  cDestPads: array[0..1] of NativeInt = (0, 4);
var
  i, ei, ej, pi: Integer;
  w, h, j, x: NativeInt;
  sumRow, sumCol: TBuffer;
  s: Single;
  lvl: string;
begin
  for i := 0 to High(cLevels) do
    if SelectLevel(cLevels[i]) then
    begin
      lvl := cLevelNames[i];
      for ei := 0 to High(cExtents) do
        for ej := 0 to High(cExtents) do
        begin
          w := cExtents[ei];
          h := cExtents[ej];
          MakeBuffer(gA, w, h, 4);
          try
            FillBuffer(gA, w, h, 0.5, 0.5);

            for pi := 0 to High(cDestPads) do
            begin
              MakeBuffer(sumRow, 1, h, cDestPads[pi]);
              MakeBuffer(sumCol, 1, w, cDestPads[pi]);
              try
                MatrixSum(sumRow.Data, sumRow.LineWidth, gA.Data, gA.LineWidth,
                  w, h, True);
                for j := 0 to h - 1 do
                begin
                  s := 0;
                  for x := 0 to w - 1 do s := s + gA.Data[IndexOf(gA, x, j)];
                  AssertEquals(Format('%s: row sum %dx%d pad %d row %d',
                    [lvl, w, h, cDestPads[pi], j]), s,
                    sumRow.Data[IndexOf(sumRow, 0, j)]);
                end;

                MatrixSum(sumCol.Data, sumCol.LineWidth, gA.Data, gA.LineWidth,
                  w, h, False);
                for j := 0 to w - 1 do
                begin
                  s := 0;
                  for x := 0 to h - 1 do s := s + gA.Data[IndexOf(gA, j, x)];
                  AssertEquals(Format('%s: column sum %dx%d pad %d column %d',
                    [lvl, w, h, cDestPads[pi], j]), s,
                    sumCol.Data[IndexOf(sumCol, 0, j)]);
                end;
              finally
                FreeBuffer(sumRow); FreeBuffer(sumCol);
              end;
            end;
          finally
            FreeBuffer(gA);
          end;
        end;
    end;
end;


procedure TvsmathDispatchTests.TestSumMean;
var i, wi: Integer; w, h, j, x: NativeInt;
    sumRow, meanCol: TBuffer;
    s: Single;
    lvl: string;
begin
  h := 4;
  for wi := 0 to High(cWidths) do
  begin
    w := cWidths[wi];
    MakeBuffer(gA, w, h, 4);
    { one element per row / column, padded line width }
    MakeBuffer(sumRow, 1, h, 4);
    MakeBuffer(meanCol, 1, w, 4);
    try
      FillBuffer(gA, w, h, 0.5, 0.5);

      for i := 0 to High(cLevels) do
        if SelectLevel(cLevels[i]) then
        begin
          lvl := cLevelNames[i];

          MatrixSum(sumRow.Data, sumRow.LineWidth, gA.Data, gA.LineWidth, w, h, True);
          for j := 0 to h - 1 do
          begin
            s := 0;
            for x := 0 to w - 1 do s := s + gA.Data[IndexOf(gA, x, j)];
            AssertEquals(Format('%s: row sum %d', [lvl, j]), s,
                         sumRow.Data[IndexOf(sumRow, 0, j)]);
          end;

          { the column reduction walks height = 4, which is lane aligned, so the
            mean kernel path is taken; every value is exact };
          MatrixMean(meanCol.Data, meanCol.LineWidth, gA.Data, gA.LineWidth, w, h, False);
          for j := 0 to w - 1 do
          begin
            s := 0;
            for x := 0 to h - 1 do s := s + gA.Data[IndexOf(gA, j, x)];
            AssertEquals(Format('%s: column mean %d', [lvl, j]), s / h,
                         meanCol.Data[IndexOf(meanCol, 0, j)]);
          end;
        end;
    finally
      FreeBuffer(gA); FreeBuffer(sumRow); FreeBuffer(meanCol);
    end;
  end;
end;

// norm / normalize

procedure TvsmathDispatchTests.TestNorm2Normalize;
var i, wi: Integer; w, h, x, y: NativeInt; n2, s: Single;
    dst: TBuffer;
begin
  h := 4;
  for wi := 0 to High(cWidths) do
  begin
    w := cWidths[wi];
    MakeBuffer(gA, w, h, 4);
    MakeBuffer(dst, w, h, 4);
    try
      FillBuffer(gA, w, h, 1.0, 1.0);

      s := 0;
      for y := 0 to h - 1 do
        for x := 0 to w - 1 do
          s := s + Sqr(gA.Data[IndexOf(gA, x, y)]);

      for i := 0 to High(cLevels) do
        if SelectLevel(cLevels[i]) then
        begin
          n2 := MatrixElementwiseNorm2(gA.Data, gA.LineWidth, w, h, False);
          AssertEquals(Format('%s: norm2 (no sqrt)', [cLevelNames[i]]), s, n2);
          n2 := MatrixElementwiseNorm2(gA.Data, gA.LineWidth, w, h, True);
          AssertEquals(Format('%s: norm2 (sqrt)', [cLevelNames[i]]), Sqrt(s), n2);
        end;

      { normalize: every row is divided by its own norm. With w = 4 and every
        element equal to 2.0 the row norm is 4, a power of two, which keeps the
        division exact so the comparison is meaningful. }
      if w = 4 then
        for i := 0 to High(cLevels) do
          if SelectLevel(cLevels[i]) then
          begin
            FillBuffer(gA, w, h, 2.0, 0.0);
            MatrixNormalize(dst.Data, dst.LineWidth, gA.Data, gA.LineWidth, w, h, True);
            s := 4.0;
            for y := 0 to h - 1 do
              for x := 0 to w - 1 do
                AssertEquals(Format('%s: normalize row (%d,%d)', [cLevelNames[i], x, y]),
                             2.0 / s, dst.Data[IndexOf(dst, x, y)]);

            { column wise: the reduction dimension is height = 4, also exact }
            MatrixNormalize(dst.Data, dst.LineWidth, gA.Data, gA.LineWidth, w, h, False);
            for y := 0 to h - 1 do
              for x := 0 to w - 1 do
                AssertEquals(Format('%s: normalize column (%d,%d)', [cLevelNames[i], x, y]),
                             2.0 / s, dst.Data[IndexOf(dst, x, y)]);
          end;
    finally
      FreeBuffer(gA); FreeBuffer(dst);
    end;
  end;
end;

// normalize over padded strides
//
// RefNormalize and the kernels both walk rows with their own line width. A row
// kernel reads width elements at destLineWidth steps, a column kernel reads one
// element per row at srcLineWidth steps and writes at destLineWidth steps.

procedure TvsmathDispatchTests.TestNormalizePaddedStrides;
const
  cW: array[0..8] of NativeInt = (1, 2, 3, 4, 5, 6, 7, 9, 17);
  cH: array[0..4] of NativeInt = (1, 2, 3, 5, 8);
  cSrcPads: array[0..1] of NativeInt = (0, 4);
  cDstPads: array[0..1] of NativeInt = (0, 4);
var
  wi, hi, si, di, li, i: Integer;
  w, h, x, y: NativeInt;
  base, act: TBuffer;
  rowWise: Boolean;
  e, a: Single;
begin
  for wi := 0 to High(cW) do
    for hi := 0 to High(cH) do
      for si := 0 to High(cSrcPads) do
        for di := 0 to High(cDstPads) do
        begin
          w := cW[wi];
          h := cH[hi];
          MakeBuffer(gA, w, h, cSrcPads[si]);
          MakeBuffer(base, w, h, cDstPads[di]);
          MakeBuffer(act, w, h, cDstPads[di]);
          try
            FillBuffer(gA, w, h, 1.0, 0.25);

            for i := 0 to 1 do
            begin
              rowWise := i = 0;

              SelectLevel(itFPU);
              MatrixNormalize(base.Data, base.LineWidth, gA.Data, gA.LineWidth,
                w, h, rowWise);

              for li := 1 to High(cLevels) do
                if SelectLevel(cLevels[li]) then
                begin
                  for y := 0 to h - 1 do
                    for x := 0 to w - 1 do
                      act.Data[IndexOf(act, x, y)] := -12345;
                  MatrixNormalize(act.Data, act.LineWidth, gA.Data, gA.LineWidth,
                    w, h, rowWise);

                  for y := 0 to h - 1 do
                    for x := 0 to w - 1 do
                    begin
                      e := base.Data[IndexOf(base, x, y)];
                      a := act.Data[IndexOf(act, x, y)];
                      AssertEquals(Format('%s: %s at %dx%d, pads %d/%d, (%d,%d)',
                        [cLevelNames[li], BoolToStr(rowWise, 'rows', 'columns'),
                         w, h, cSrcPads[si], cDstPads[di], x, y]), e, a, 1e-5);
                    end;
                end;
            end;
          finally
            FreeBuffer(gA); FreeBuffer(base); FreeBuffer(act);
          end;
        end;
  InitMathFunctions(GetBestCPUInstrType, False);
end;

procedure TvsmathDispatchTests.TestNormalizeZeroNorm;
const
  cW: array[0..5] of NativeInt = (1, 2, 3, 4, 7, 8);
  cH: array[0..3] of NativeInt = (1, 2, 5, 8);
var
  wi, hi, li, i: Integer;
  w, h, x, y: NativeInt;
  dst: TBuffer;
  rowWise: Boolean;
  v: Single;
begin
  { A zero row or column has a zero norm. Dividing by it gives Inf, and Inf * 0
    is NaN, so a raw division would poison the destination and a program that
    unmasks divide-by-zero would die inside the kernel. The contract, and what
    RefNormalize does, is to write zeros. }
  for wi := 0 to High(cW) do
    for hi := 0 to High(cH) do
    begin
      w := cW[wi];
      h := cH[hi];
      MakeBuffer(gA, w, h, 0);
      MakeBuffer(dst, w, h, 0);
      try
        FillBuffer(gA, w, h, 1.0, 0.5);
        for x := 0 to w - 1 do
          gA.Data[IndexOf(gA, x, h - 1)] := 0;   { last row is all zeros }
        for y := 0 to h - 1 do
          gA.Data[IndexOf(gA, 0, y)] := 0;       { first column is all zeros }

        for i := 0 to 1 do
        begin
          rowWise := i = 0;
          for li := 0 to High(cLevels) do
            if SelectLevel(cLevels[li]) then
            begin
              for y := 0 to h - 1 do
                for x := 0 to w - 1 do
                  dst.Data[IndexOf(dst, x, y)] := -12345;
              MatrixNormalize(dst.Data, dst.LineWidth, gA.Data, gA.LineWidth,
                w, h, rowWise);

              if rowWise then
              begin
                for x := 0 to w - 1 do
                  AssertEquals(Format('%s: zero row at %dx%d, (%d,%d)',
                    [cLevelNames[li], w, h, x, h - 1]),
                    0.0, dst.Data[IndexOf(dst, x, h - 1)]);
              end
              else
                for y := 0 to h - 1 do
                  AssertEquals(Format('%s: zero column at %dx%d, (%d,%d)',
                    [cLevelNames[li], w, h, 0, y]),
                    0.0, dst.Data[IndexOf(dst, 0, y)]);

              { everything else still has to be a normalized column or row, and
                above all it has to be a number }
              for y := 0 to h - 1 do
                for x := 0 to w - 1 do
                begin
                  v := dst.Data[IndexOf(dst, x, y)];
                  AssertTrue(Format('%s: %dx%d (%d,%d) is not finite',
                    [cLevelNames[li], w, h, x, y]),
                    not (IsNan(v) or IsInfinite(v)));
                end;
            end;
        end;
      finally
        FreeBuffer(gA); FreeBuffer(dst);
      end;
    end;
  InitMathFunctions(GetBestCPUInstrType, False);
end;

// rank-1 with a strided Y
//
// The Seq kernels assume Y is contiguous; MatrixRank1Update routes a caller whose
// increments are larger element multiples to the NonSeq kernels. This sweep uses
// increments of two and three elements and compares every level against the scalar
// reference.

procedure TvsmathDispatchTests.TestRank1UpdateStrided;
const
  cIncX = 2 * SizeOf(Single);
  cIncY = 3 * SizeOf(Single);
  cAlpha = 0.5;
  cCases: array[0..2, 0..1] of NativeInt = ((4, 4), (7, 5), (9, 6));
var
  ci, li: Integer;
  w, h, x, y: NativeInt;
  xs, ys: array of Single;
  base, act: TBuffer;
begin
  for ci := 0 to High(cCases) do
  begin
    w := cCases[ci][0];
    h := cCases[ci][1];

    MakeBuffer(gA, w, h, 4);
    MakeBuffer(base, w, h, 4);
    MakeBuffer(act, w, h, 4);
    try
      FillBuffer(gA, w, h, 1.0, 0.5);

      SetLength(xs, h * 2);
      for y := 0 to h - 1 do
      begin
        xs[y * 2] := 1.0 + y * 0.5;      { the element the kernel reads }
        xs[y * 2 + 1] := -7.0;           { gap, must never be touched }
      end;

      SetLength(ys, w * 3);
      for x := 0 to w - 1 do
      begin
        ys[x * 3] := -1.0 + x * 0.5;
        ys[x * 3 + 1] := -7.0;
        ys[x * 3 + 2] := -7.0;
      end;

      for li := 0 to High(cLevels) do
        if SelectLevel(cLevels[li]) then
        begin
          CopyBuffer(gA, base, w, h);
          MatrixRank1Update(base.Data, base.LineWidth, w, h, @xs[0], @ys[0],
            cIncX, cIncY, cAlpha);

          for y := 0 to h - 1 do
            for x := 0 to w - 1 do
              AssertEquals(Format('%s: strided rank-1 %dx%d (%d,%d)',
                [cLevelNames[li], w, h, x, y]),
                gA.Data[IndexOf(gA, x, y)] + cAlpha * xs[y * 2] * ys[x * 3],
                base.Data[IndexOf(base, x, y)]);
        end;
    finally
      FreeBuffer(gA); FreeBuffer(base); FreeBuffer(act);
      xs := nil; ys := nil;
    end;
  end;
  InitMathFunctions(GetBestCPUInstrType, False);
end;

// transpose

var
  gSrcW, gSrcH: NativeInt;

procedure DoTranspose(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  MatrixTranspose(dst.Data, dst.LineWidth, gA.Data, gA.LineWidth, gSrcW, gSrcH);
end;

procedure TvsmathDispatchTests.TestTranspose;
var wi, hi: Integer; w, h, x, y: NativeInt;
    orig: TBuffer;
    heights: array[0..2] of NativeInt = (8, 4, 6);
begin
  for wi := 0 to High(cWidths) do
    for hi := 0 to High(heights) do
    begin
      w := cWidths[wi];
      h := heights[hi];
      MakeBuffer(gA, w, h, 4);
      MakeBuffer(gBase, h, w, 4);
      MakeBuffer(gAct, h, w, 4);
      try
        FillBuffer(gA, w, h, 1.25, 1.25);

        gSrcW := w; gSrcH := h;
        SelectLevel(itFPU);
        MatrixTranspose(gBase.Data, gBase.LineWidth, gA.Data, gA.LineWidth, w, h);
        RunLevels('MatrixTranspose', h, w, gBase, gAct, @DoTranspose);

        { the transposed values must be the exchanged ones }
        for y := 0 to h - 1 do
          for x := 0 to w - 1 do
            AssertEquals(Format('MatrixTranspose value (%d,%d)', [x, y]),
                         gA.Data[IndexOf(gA, x, y)], gBase.Data[IndexOf(gBase, y, x)]);
      finally
        FreeBuffer(gA); FreeBuffer(gBase); FreeBuffer(gAct);
      end;
    end;

  { in place transpose of a square matrix }
  w := 8;
  MakeBuffer(orig, w, w, 4);
  MakeBuffer(gAct, w, w, 4);
  try
    FillBuffer(orig, w, w, -4.0, 0.5);
    CopyBuffer(orig, gAct, w, w);
    for wi := 0 to High(cLevels) do
      if SelectLevel(cLevels[wi]) then
      begin
        CopyBuffer(orig, gAct, w, w);
        MatrixTransposeInplace(gAct.Data, gAct.LineWidth, w);
        for y := 0 to w - 1 do
          for x := 0 to w - 1 do
            AssertEquals(Format('%s: transpose in place (%d,%d)', [cLevelNames[wi], x, y]),
                         orig.Data[IndexOf(orig, y, x)], gAct.Data[IndexOf(gAct, x, y)]);
      end;
  finally
    FreeBuffer(orig); FreeBuffer(gAct);
  end;
end;

// matrix product

var
  gW1, gH1, gW2, gH2: NativeInt;

procedure DoMult(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  MatrixMult(dst.Data, dst.LineWidth, gA.Data, gB.Data, gW1, gH1, gW2, gH2,
             gA.LineWidth, gB.LineWidth);
end;

procedure TvsmathDispatchTests.TestMult;
var ci, k: Integer; x, y: NativeInt;
    cases: array[0..3, 0..3] of NativeInt =
      ((8, 8, 8, 8), (4, 4, 4, 4), (8, 6, 4, 8), (5, 7, 3, 5));
    s: Single;
begin
  for ci := 0 to High(cases) do
  begin
    gW1 := cases[ci][0]; gH1 := cases[ci][1];
    gW2 := cases[ci][2]; gH2 := cases[ci][3];

    MakeBuffer(gA, gW1, gH1, 4);          { width1 x height1 }
    MakeBuffer(gB, gW2, gH2, 4);          { width2 x height2 }
    MakeBuffer(gBase, gW2, gH1, 4);       { width2 x height1 }
    MakeBuffer(gAct, gW2, gH1, 4);
    try
      FillBuffer(gA, gW1, gH1, 1.0, 0.5);
      FillBuffer(gB, gW2, gH2, -2.0, 0.25);

      SelectLevel(itFPU);
      MatrixMult(gBase.Data, gBase.LineWidth, gA.Data, gB.Data, gW1, gH1, gW2, gH2,
                 gA.LineWidth, gB.LineWidth);
      RunLevels('MatrixMult', gW2, gH1, gBase, gAct, @DoMult);

      { spot check one element of the reference against the dot product }
      s := 0;
      for k := 0 to gW1 - 1 do
        s := s + gA.Data[IndexOf(gA, k, 0)] * gB.Data[IndexOf(gB, 0, k)];
      AssertEquals(Format('MatrixMult reference element (0,0) case %d', [ci]),
                   s, gBase.Data[IndexOf(gBase, 0, 0)]);
      for y := 0 to gH1 - 1 do
        for x := 0 to gW2 - 1 do
          AssertTrue('mult result is finite', not IsNan(gBase.Data[IndexOf(gBase, x, y)]));
    finally
      FreeBuffer(gA); FreeBuffer(gB); FreeBuffer(gBase); FreeBuffer(gAct);
    end;
  end;
end;

// matrix vector product and dot product

var
  gMtxW, gMtxH: NativeInt;

procedure DoMtxVecMult(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  { dest is also an input (beta term), so start from the pristine copy }
  CopyBuffer(gC, dst, 1, height);
  MatrixMtxVecMult(dst.Data, sizeof(Single), gA.Data, gB.Data, gA.LineWidth,
                   sizeof(Single), gMtxW, gMtxH, 2.0, 1.0);
end;

procedure TvsmathDispatchTests.TestMtxVecMult;
var ci: Integer; x, y: NativeInt; s: Single;
    cases: array[0..3, 0..1] of NativeInt = ((8, 8), (4, 4), (8, 5), (5, 7));
begin
  for ci := 0 to High(cases) do
  begin
    gMtxW := cases[ci][0];
    gMtxH := cases[ci][1];

    MakeBuffer(gA, gMtxW, gMtxH, 4);      { the matrix }
    MakeBuffer(gB, gMtxW, 1, 0);          { the vector, contiguous }
    MakeVector(gC, gMtxH);          { initial dest, contiguous }
    MakeVector(gBase, gMtxH);
    MakeVector(gAct, gMtxH);
    try
      FillBuffer(gA, gMtxW, gMtxH, 1.0, 0.5);
      FillBuffer(gB, gMtxW, 1, 2.0, 0.25);
      FillBuffer(gC, 1, gMtxH, -1.0, 0.5);

      CopyBuffer(gC, gBase, 1, gMtxH);
      SelectLevel(itFPU);
      MatrixMtxVecMult(gBase.Data, sizeof(Single), gA.Data, gB.Data, gA.LineWidth,
                       sizeof(Single), gMtxW, gMtxH, 2.0, 1.0);
      RunLevels('MatrixMtxVecMult', 1, gMtxH, gBase, gAct, @DoMtxVecMult);

      { reference: dest[y] = 2*dot(row y, v) + dest[y] }
      for y := 0 to gMtxH - 1 do
      begin
        s := 0;
        for x := 0 to gMtxW - 1 do
          s := s + gA.Data[IndexOf(gA, x, y)] * gB.Data[x];
        AssertEquals(Format('MatrixMtxVecMult element %d case %d', [y, ci]),
                     2.0 * s + gC.Data[y], gBase.Data[y]);
      end;
    finally
      FreeBuffer(gA); FreeBuffer(gB); FreeBuffer(gC); FreeBuffer(gBase); FreeBuffer(gAct);
    end;
  end;
end;

procedure TvsmathDispatchTests.TestMtxVecMultT;
var ci, li: Integer; x, y: NativeInt; s: Single;
    cases: array[0..5, 0..1] of NativeInt =
      ((8, 8), (4, 4), (8, 5), (5, 7), (33, 3), (17, 1));
begin
  for ci := 0 to High(cases) do
  begin
    { the transposed product: the matrix is height rows of width elements, the
      vector holds height elements and the destination holds width elements }
    gMtxW := cases[ci][0];
    gMtxH := cases[ci][1];

    MakeBuffer(gA, gMtxW, gMtxH, 4);      { the matrix, padded line width }
    MakeVector(gB, gMtxH);                { v, contiguous }
    MakeVector(gC, gMtxW);                { initial dest, contiguous }
    MakeVector(gBase, gMtxW);
    MakeVector(gAct, gMtxW);
    try
      FillBuffer(gA, gMtxW, gMtxH, 1.0, 0.5);
      FillBuffer(gB, 1, gMtxH, 2.0, 0.25);
      FillBuffer(gC, 1, gMtxW, -1.0, 0.5);

      { reference: dest[x] = 2 * sum(y, mt[y][x]*v[y]) + dest[x]. Every operand
        is a small multiple of 0.125, so the sums are exact in Single whatever
        order a kernel adds them in - the comparison needs no tolerance and still
        catches a dropped or duplicated term. }
      for x := 0 to gMtxW - 1 do
      begin
        s := 0;
        for y := 0 to gMtxH - 1 do
          s := s + gA.Data[IndexOf(gA, x, y)] * gB.Data[y];
        gBase.Data[x] := 2.0 * s + gC.Data[x];
      end;

      for li := 0 to High(cLevels) do
        if SelectLevel(cLevels[li]) then
        begin
          CopyBuffer(gC, gAct, 1, gMtxW);
          MatrixMtxVecMultT(gAct.Data, sizeof(Single), gA.Data, gB.Data,
                            gA.LineWidth, sizeof(Single), gMtxW, gMtxH, 2.0, 1.0);
          AssertSame('MatrixMtxVecMultT at ' + cLevelNames[li], gBase, gAct, gMtxW, 1);
        end;
    finally
      FreeBuffer(gA); FreeBuffer(gB); FreeBuffer(gC); FreeBuffer(gBase); FreeBuffer(gAct);
    end;
  end;
end;

procedure TvsmathDispatchTests.TestMtxVecMultTStrided;
var li: Integer; x, y: NativeInt; s: Single;
begin
  gMtxW := 11;
  gMtxH := 6;

  { nothing is contiguous here: a matrix line width that is not a multiple of 16
    bytes, a vector whose elements are 6 elements apart, and a destination whose
    elements are 14 elements apart - i.e. a column of a wider matrix. The kernels
    take their scalar column path for such a destination, and every stride has to
    be honoured for the matrix and the vector as well. }
  MakeBuffer(gA, gMtxW, gMtxH, 4);
  MakeStridedVector(gB, gMtxH, 6 * sizeof(Single));
  MakeStridedVector(gC, gMtxW, 14 * sizeof(Single));
  MakeStridedVector(gBase, gMtxW, 14 * sizeof(Single));
  MakeStridedVector(gAct, gMtxW, 14 * sizeof(Single));
  try
    FillBuffer(gA, gMtxW, gMtxH, 1.0, 0.5);
    FillBuffer(gB, 1, gMtxH, 2.0, 0.25);
    FillBuffer(gC, 1, gMtxW, -1.0, 0.5);

    { reference: dest[x] = 2 * sum(y, mt[y][x]*v[y]) + dest[x] }
    for x := 0 to gMtxW - 1 do
    begin
      s := 0;
      for y := 0 to gMtxH - 1 do
        s := s + gA.Data[IndexOf(gA, x, y)] * gB.Data[IndexOf(gB, 0, y)];
      gBase.Data[IndexOf(gBase, 0, x)] := 2.0 * s + gC.Data[IndexOf(gC, 0, x)];
    end;

    for li := 0 to High(cLevels) do
      if SelectLevel(cLevels[li]) then
      begin
        CopyBuffer(gC, gAct, 1, gMtxW);
        MatrixMtxVecMultT(gAct.Data, gAct.LineWidth, gA.Data, gB.Data,
                          gA.LineWidth, gB.LineWidth, gMtxW, gMtxH, 2.0, 1.0);
        { both buffers hold the destinations as one element wide rows }
        AssertSame('MatrixMtxVecMultT (strided) at ' + cLevelNames[li],
                   gBase, gAct, 1, gMtxW);
      end;
  finally
    FreeBuffer(gA); FreeBuffer(gB); FreeBuffer(gC); FreeBuffer(gBase); FreeBuffer(gAct);
  end;
end;

procedure TvsmathDispatchTests.TestVecDotMult;
var i, k, n, si: Integer; sizes: array[0..2] of NativeInt = (8, 6, 5);
    sx, sy: Single; expect: Single;
begin
  for si := 0 to High(sizes) do
  begin
    n := sizes[si];
    MakeBuffer(gA, n, 1, 4);
    MakeBuffer(gB, n, 1, 4);
    try
      FillBuffer(gA, n, 1, 1.5, 0.5);
      FillBuffer(gB, n, 1, -2.0, 0.25);

      expect := 0;
      for k := 0 to n - 1 do
        expect := expect + gA.Data[k] * gB.Data[k];

      for i := 0 to High(cLevels) do
        if SelectLevel(cLevels[i]) then
        begin
          sx := MatrixVecDotMult(gA.Data, sizeof(Single), gB.Data, sizeof(Single), n);
          AssertEquals(Format('%s: dot %d', [cLevelNames[i], n]), expect, sx);
        end;

      { strided: every second element of a and b }
      MakeBuffer(gC, 2*n, 1, 0);
      try
        for k := 0 to 2*n - 1 do
          gC.Data[k] := 1.0;
        expect := 0;
        for k := 0 to n - 1 do
          expect := expect + gA.Data[k] * gB.Data[k];
        for i := 0 to High(cLevels) do
          if SelectLevel(cLevels[i]) then
          begin
            sy := MatrixVecDotMult(gA.Data, sizeof(Single), gB.Data, sizeof(Single), n);
            AssertEquals(Format('%s: dot (repeat) %d', [cLevelNames[i], n]), expect, sy);
          end;
      finally
        FreeBuffer(gC);
      end;
    finally
      FreeBuffer(gA); FreeBuffer(gB);
    end;
  end;
end;

// rank 1 update

var
  gRankW, gRankH: NativeInt;

procedure DoRank1(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, gRankW, gRankH);
  MatrixRank1Update(dst.Data, dst.LineWidth, gRankW, gRankH, gB.Data, gC.Data,
                    sizeof(Single), sizeof(Single), 0.5);
end;

procedure TvsmathDispatchTests.TestRank1Update;
var ci: Integer; x, y: NativeInt;
    cases: array[0..3, 0..1] of NativeInt = ((8, 8), (4, 4), (8, 5), (5, 7));
begin
  for ci := 0 to High(cases) do
  begin
    gRankW := cases[ci][0];
    gRankH := cases[ci][1];

    MakeBuffer(gA, gRankW, gRankH, 4);      { A }
    MakeBuffer(gB, gRankH, 1, 0);           { X, contiguous }
    MakeBuffer(gC, gRankW, 1, 0);           { Y, contiguous }
    MakeBuffer(gBase, gRankW, gRankH, 4);
    MakeBuffer(gAct, gRankW, gRankH, 4);
    try
      FillBuffer(gA, gRankW, gRankH, 1.0, 0.5);
      FillBuffer(gB, gRankH, 1, 1.0, 0.5);
      FillBuffer(gC, gRankW, 1, -1.0, 0.5);

      CopyBuffer(gA, gBase, gRankW, gRankH);
      SelectLevel(itFPU);
      MatrixRank1Update(gBase.Data, gBase.LineWidth, gRankW, gRankH, gB.Data, gC.Data,
                        sizeof(Single), sizeof(Single), 0.5);
      RunLevels('MatrixRank1Update', gRankW, gRankH, gBase, gAct, @DoRank1);

      for y := 0 to gRankH - 1 do
        for x := 0 to gRankW - 1 do
          AssertEquals(Format('MatrixRank1Update (%d,%d) case %d', [x, y, ci]),
                       gA.Data[IndexOf(gA, x, y)]
                         + 0.5 * gB.Data[y] * gC.Data[x],
                       gBase.Data[IndexOf(gBase, x, y)]);
    finally
      FreeBuffer(gA); FreeBuffer(gB); FreeBuffer(gC); FreeBuffer(gBase); FreeBuffer(gAct);
    end;
  end;
end;

// plane rotations

var
  gRotW, gRotH: NativeInt;
  gCArr, gSArr: PSingle;
  gCBase, gSBase: Pointer;

procedure DoRVB(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, gRotW, gRotH);
  ApplyPlaneRotSeqRVB(gRotW, gRotH, dst.Data, dst.LineWidth, PConstSingleArr(gCArr), PConstSingleArr(gSArr));
end;

procedure DoRVF(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, gRotW, gRotH);
  ApplyPlaneRotSeqRVF(gRotW, gRotH, dst.Data, dst.LineWidth, PConstSingleArr(gCArr), PConstSingleArr(gSArr));
end;

procedure DoLVB(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, gRotW, gRotH);
  ApplyPlaneRotSeqLVB(gRotW, gRotH, dst.Data, dst.LineWidth, PConstSingleArr(gCArr), PConstSingleArr(gSArr));
end;

procedure DoLVF(width, height: NativeInt; const baseline: TBuffer; var dst: TBuffer; const lvl: string);
begin
  CopyBuffer(gA, dst, gRotW, gRotH);
  ApplyPlaneRotSeqLVF(gRotW, gRotH, dst.Data, dst.LineWidth, PConstSingleArr(gCArr), PConstSingleArr(gSArr));
end;

procedure TvsmathDispatchTests.TestRank1UpdateAlignedPath;
const
  cAlpha = 0.5;
var
  li, x, y: Integer;
  w, h: NativeInt;
  base, act: TBuffer;
begin
  { MatrixRank1Update picks the *aligned* kernel when the matrix base, the
    matrix line width and Y are all 16 byte aligned: ASMRank1UpdateSeqAligned at
    itSSE, AVXRank1UpdateSeqAligned at itAVX/itFMA. Both load matrix rows and Y
    with aligned moves, so this is the only shape that reaches them - the other
    rank-1 tests use a padded line width on purpose and take the unaligned
    kernel. Width 8 gives a 32 byte line width, a multiple of 16, and
    MtxAllocAlign hands out 32 byte aligned blocks. }
  w := 8;
  h := 4;

  MakeBuffer(gA, w, h, 0);
  MakeBuffer(base, w, h, 0);
  MakeBuffer(gB, h, 1, 0);
  MakeBuffer(gC, w, 1, 0);
  MakeBuffer(act, w, h, 0);
  try
    FillBuffer(gA, w, h, 1.0, 0.5);
    FillBuffer(gB, h, 1, 1.0, 0.5);
    FillBuffer(gC, w, 1, -1.0, 0.5);

    CopyBuffer(gA, base, w, h);
    SelectLevel(itFPU);
    MatrixRank1Update(base.Data, base.LineWidth, w, h, gB.Data, gC.Data,
                      sizeof(Single), sizeof(Single), cAlpha);

    for li := 0 to High(cLevels) do
      if SelectLevel(cLevels[li]) then
      begin
        CopyBuffer(gA, act, w, h);
        MatrixRank1Update(act.Data, act.LineWidth, w, h, gB.Data, gC.Data,
                          sizeof(Single), sizeof(Single), cAlpha);
        for y := 0 to h - 1 do
          for x := 0 to w - 1 do
            AssertEquals(Format('%s: aligned rank-1 %dx%d (%d,%d)',
              [cLevelNames[li], w, h, x, y]),
              base.Data[IndexOf(base, x, y)], act.Data[IndexOf(act, x, y)]);
      end;
  finally
    FreeBuffer(gA); FreeBuffer(base); FreeBuffer(gB); FreeBuffer(gC);
    FreeBuffer(act);
  end;
  InitMathFunctions(GetBestCPUInstrType, False);
end;

procedure TvsmathDispatchTests.TestPlaneRotations;
var wi, hi, i, k: Integer; w, h: NativeInt;
    heights: array[0..1] of NativeInt = (8, 5);
    dx, dy, baseDx, baseDy: TBuffer;
begin
  for wi := 0 to High(cWidths) do
    for hi := 0 to High(heights) do
    begin
      w := cWidths[wi];
      h := heights[hi];

      gCBase := nil; gSBase := nil;
      gCArr := MtxAllocAlign((w + 2*h + 8) * sizeof(Single), gCBase);
      gSArr := MtxAllocAlign((w + 2*h + 8) * sizeof(Single), gSBase);
      MakeBuffer(gA, w, h, 4);
      MakeBuffer(gBase, w, h, 4);
      MakeBuffer(gAct, w, h, 4);
      try
        FillBuffer(gA, w, h, 1.0, 0.5);
        for k := 0 to w + 2*h + 7 do
        begin
          gCArr[k] := 0.5;
          gSArr[k] := -0.5;
        end;

        gRotW := w; gRotH := h;

        CopyBuffer(gA, gBase, w, h);
        SelectLevel(itFPU);
        ApplyPlaneRotSeqRVB(w, h, gBase.Data, gBase.LineWidth, PConstSingleArr(gCArr), PConstSingleArr(gSArr));
        RunLevels('ApplyPlaneRotSeqRVB', w, h, gBase, gAct, @DoRVB);

        CopyBuffer(gA, gBase, w, h);
        SelectLevel(itFPU);
        ApplyPlaneRotSeqRVF(w, h, gBase.Data, gBase.LineWidth, PConstSingleArr(gCArr), PConstSingleArr(gSArr));
        RunLevels('ApplyPlaneRotSeqRVF', w, h, gBase, gAct, @DoRVF);

        CopyBuffer(gA, gBase, w, h);
        SelectLevel(itFPU);
        ApplyPlaneRotSeqLVB(w, h, gBase.Data, gBase.LineWidth, PConstSingleArr(gCArr), PConstSingleArr(gSArr));
        RunLevels('ApplyPlaneRotSeqLVB', w, h, gBase, gAct, @DoLVB);

        CopyBuffer(gA, gBase, w, h);
        SelectLevel(itFPU);
        ApplyPlaneRotSeqLVF(w, h, gBase.Data, gBase.LineWidth, PConstSingleArr(gCArr), PConstSingleArr(gSArr));
        RunLevels('ApplyPlaneRotSeqLVF', w, h, gBase, gAct, @DoLVF);

        for i := 0 to h - 1 do
          AssertTrue(Format('rotation keeps row %d finite', [i]),
                     not IsNan(gBase.Data[IndexOf(gBase, 0, i)]));
      finally
        FreeMem(gCBase); FreeMem(gSBase);
        FreeBuffer(gA); FreeBuffer(gBase); FreeBuffer(gAct);
      end;
    end;

  { MatrixRotate on a pair of strided vectors }
  MakeBuffer(dx, 8, 1, 4);
  MakeBuffer(dy, 8, 1, 4);
  MakeBuffer(baseDx, 8, 1, 4);
  MakeBuffer(baseDy, 8, 1, 4);
  MakeBuffer(gAct, 8, 1, 0);
  MakeBuffer(gBase, 8, 1, 0);
  try
    FillBuffer(dx, 8, 1, 1.0, 1.0);
    FillBuffer(dy, 8, 1, -1.0, 0.5);

    CopyBuffer(dx, baseDx, 8, 1);
    CopyBuffer(dy, baseDy, 8, 1);
    SelectLevel(itFPU);
    MatrixRotate(8, baseDx.Data, sizeof(Single), baseDy.Data, sizeof(Single), 0.5, -0.5);

    for i := 0 to High(cLevels) do
      if SelectLevel(cLevels[i]) then
      begin
        CopyBuffer(dx, gAct, 8, 1);
        CopyBuffer(dy, gBase, 8, 1);
        MatrixRotate(8, gAct.Data, sizeof(Single), gBase.Data, sizeof(Single), 0.5, -0.5);
        for k := 0 to 7 do
          AssertEquals(Format('%s: MatrixRotate x %d', [cLevelNames[i], k]),
                       baseDx.Data[k], gAct.Data[k]);
        for k := 0 to 7 do
          AssertEquals(Format('%s: MatrixRotate y %d', [cLevelNames[i], k]),
                       baseDy.Data[k], gBase.Data[k]);
      end;
  finally
    FreeBuffer(dx); FreeBuffer(dy); FreeBuffer(baseDx); FreeBuffer(baseDy);
    FreeBuffer(gAct); FreeBuffer(gBase);
  end;
end;

// pairwise distance

procedure TvsmathDispatchTests.TestDistance;
var i, x, y, xLen, yLen: NativeInt;
    sqrArr, absArr: TBuffer;
begin
  xLen := 5;
  yLen := 6;
  MakeBuffer(gA, xLen, 1, 4);
  MakeBuffer(gB, yLen, 1, 4);
  MakeBuffer(sqrArr, yLen, xLen, 4);
  MakeBuffer(absArr, yLen, xLen, 4);
  try
    FillBuffer(gA, xLen, 1, -2.0, 0.5);
    FillBuffer(gB, yLen, 1, 3.0, 0.25);

    for i := 0 to High(cLevels) do
      if SelectLevel(cLevels[i]) then
      begin
        MtxDistanceSqr(sqrArr.Data, sqrArr.LineWidth, gA.Data, gB.Data, xLen, yLen);
        MtxDistanceAbs(absArr.Data, absArr.LineWidth, gA.Data, gB.Data, xLen, yLen);
        for y := 0 to xLen - 1 do
          for x := 0 to yLen - 1 do
          begin
            AssertEquals(Format('%s: distance sqr (%d,%d)', [cLevelNames[i], x, y]),
                         Sqr(gA.Data[y] - gB.Data[x]), sqrArr.Data[IndexOf(sqrArr, x, y)]);
            AssertEquals(Format('%s: distance abs (%d,%d)', [cLevelNames[i], x, y]),
                         Abs(gA.Data[y] - gB.Data[x]), absArr.Data[IndexOf(absArr, x, y)]);
          end;
      end;
  finally
    FreeBuffer(gA); FreeBuffer(gB); FreeBuffer(sqrArr); FreeBuffer(absArr);
  end;
end;

initialization
  RegisterTest(TvsmathDispatchTests);

end.
