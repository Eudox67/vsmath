// ###########################################################
// #### vsmath - vector single math
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the Apache License, Version 2.0 - see LICENSE.
// ###########################################################
// FPCUnit tests for AVX_FFT_Execute: round trips, a batched pass, and every
// spectrum compared against a naive O(N^2) DFT over data that is exact in
// Single. The kernels are raw AVX code, so every test ignores itself on a CPU
// without AVX.
unit TestVsMathFFT;

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

interface

uses
  fpcunit, testregistry;

{$IFDEF CPUX64}

type
  TvsmathFFTTests = class(TTestCase)
  private
    function AVXReady: Boolean;
  published
    procedure TestForwardMatchesDFT;
    procedure TestRoundTrip;
    procedure TestShiftedImpulseSpectrum;
    procedure TestInverseReconstructsDelta;
    procedure TestBatchedRows;
    procedure TestSizeSweep;
    procedure TestNonPowerOfTwoRejected;
  end;

{$ENDIF}

implementation

{$IFDEF CPUX64}

uses
  SysUtils, Math, cpu, AVXFFT;

const
  cTol = 1e-4;   { the kernel computes in Single, the reference in Double }

type
  TSingleArr = array of Single;

// Deterministic complex signal: real parts are multiples of 1/2, imaginary
// parts multiples of 1/4, so every input value is exact in Single.
function MakeSignal(ALen: Integer): TSingleArr;
var
  n: Integer;
begin
  SetLength(Result, ALen * 2);
  for n := 0 to ALen - 1 do
  begin
    Result[n * 2]     := ((n * 3) mod 7 - 3) * 0.5;
    Result[n * 2 + 1] := ((n * 5) mod 5 - 2) * 0.25;
  end;
end;

// The definition the kernel has to reproduce, evaluated in Double.
procedure RefDFT(pIn: PSingle; ALen: Integer; Inverse: Boolean; pOut: PSingle);
var
  k, n: Integer;
  Theta, Sgn, SumR, SumI, R, I, C, S: Double;
begin
  if Inverse then
    Sgn := 1.0
  else
    Sgn := -1.0;

  for k := 0 to ALen - 1 do
  begin
    SumR := 0.0;
    SumI := 0.0;
    for n := 0 to ALen - 1 do
    begin
      R := pIn[n * 2];
      I := pIn[n * 2 + 1];
      Theta := Sgn * 2.0 * Pi * k * n / ALen;
      C := Cos(Theta);
      S := Sin(Theta);
      SumR := SumR + R * C - I * S;
      SumI := SumI + R * S + I * C;
    end;
    if Inverse then
    begin
      SumR := SumR / ALen;
      SumI := SumI / ALen;
    end;
    pOut[k * 2] := SumR;
    pOut[k * 2 + 1] := SumI;
  end;
end;

procedure CheckBins(const AMsg: string; pGot, pWant: PSingle; ALen: Integer);
var
  k: Integer;
begin
  for k := 0 to ALen - 1 do
  begin
    TAssert.AssertEquals(Format('%s: bin %d real', [AMsg, k]),
      pWant[k * 2], pGot[k * 2], cTol);
    TAssert.AssertEquals(Format('%s: bin %d imag', [AMsg, k]),
      pWant[k * 2 + 1], pGot[k * 2 + 1], cTol);
  end;
end;

function TvsmathFFTTests.AVXReady: Boolean;
begin
  Result := AVXSupport;
  if not Result then
    Ignore('CPU has no AVX support');
end;

procedure TvsmathFFTTests.TestForwardMatchesDFT;
const
  cN = 8;
var
  Data, Want: TSingleArr;
begin
  if not AVXReady then
    Exit;

  Data := MakeSignal(cN);
  SetLength(Want, cN * 2);
  RefDFT(@Data[0], cN, False, @Want[0]);

  AVX_FFT_Execute(@Data[0], 1, cN, False);
  CheckBins('forward', @Data[0], @Want[0], cN);
end;

// A forward/inverse pair has to return the input, imaginary parts included.
procedure TvsmathFFTTests.TestRoundTrip;
const
  cN = 8;
var
  Data, Want: TSingleArr;
begin
  if not AVXReady then
    Exit;

  Data := MakeSignal(cN);
  Want := Copy(Data);

  AVX_FFT_Execute(@Data[0], 1, cN, False);
  AVX_FFT_Execute(@Data[0], 1, cN, True);
  CheckBins('round trip', @Data[0], @Want[0], cN);
end;


// The transform of a real, shifted impulse is complex: if the butterfly pass
// drops the imaginary half of the data, these bins come back zeroed.
procedure TvsmathFFTTests.TestShiftedImpulseSpectrum;
const
  cN = 8;
var
  Data, Want: TSingleArr;
  n: Integer;
begin
  if not AVXReady then
    Exit;

  SetLength(Data, cN * 2);
  for n := 0 to cN - 1 do
  begin
    Data[n * 2] := 0.0;
    Data[n * 2 + 1] := 0.0;
  end;
  Data[1 * 2] := 1.0;   { x[1] = 1, every other sample zero }

  SetLength(Want, cN * 2);
  RefDFT(@Data[0], cN, False, @Want[0]);

  AVX_FFT_Execute(@Data[0], 1, cN, False);
  CheckBins('shifted impulse', @Data[0], @Want[0], cN);

  { X[k] = e^(-2*pi*i*k/N), so |imag| peaks just inside the band edges }
  AssertTrue('bin 1 must carry an imaginary part',
    Abs(Data[1 * 2 + 1]) > 0.5);
  AssertTrue('bin cN-1 must carry an imaginary part',
    Abs(Data[(cN - 1) * 2 + 1]) > 0.5);
end;

// Flat spectrum in, delta out: pins the inverse twiddle sign and the 1/N.
procedure TvsmathFFTTests.TestInverseReconstructsDelta;
const
  cN = 8;
var
  Data: TSingleArr;
  n: Integer;
begin
  if not AVXReady then
    Exit;

  SetLength(Data, cN * 2);
  for n := 0 to cN - 1 do
  begin
    Data[n * 2] := 1.0;
    Data[n * 2 + 1] := 0.0;
  end;

  AVX_FFT_Execute(@Data[0], 1, cN, True);

  AssertEquals('delta real', 1.0, Data[0], cTol);
  AssertEquals('delta imag', 0.0, Data[1], cTol);
  for n := 1 to cN - 1 do
  begin
    AssertEquals(Format('zero real %d', [n]), 0.0, Data[n * 2], cTol);
    AssertEquals(Format('zero imag %d', [n]), 0.0, Data[n * 2 + 1], cTol);
  end;
end;

// Three rows in one call, scaled by powers of two so the data stays exact.
procedure TvsmathFFTTests.TestBatchedRows;
const
  cN = 8;
  cBatch = 3;
  cScale: array[0 .. 2] of Single = (1.0, 2.0, -0.5);
var
  Data, Row, Want: TSingleArr;
  b, i: Integer;
begin
  if not AVXReady then
    Exit;

  SetLength(Data, cBatch * cN * 2);
  SetLength(Want, cBatch * cN * 2);
  for b := 0 to cBatch - 1 do
  begin
    Row := MakeSignal(cN);
    for i := 0 to cN * 2 - 1 do
    begin
      Data[b * cN * 2 + i] := Row[i] * cScale[b];
      Row[i] := Row[i] * cScale[b];   { RefDFT writes its output, so it needs
                                        a source buffer of its own }
    end;
    RefDFT(@Row[0], cN, False, @Want[b * cN * 2]);
  end;

  AVX_FFT_Execute(@Data[0], cBatch, cN, False);

  for b := 0 to cBatch - 1 do
    CheckBins(Format('batch row %d', [b]),
      @Data[b * cN * 2], @Want[b * cN * 2], cN);
end;

// Every power-of-two size the radix-2 pass covers, including the stages that
// fall through to the scalar butterfly tail.
procedure TvsmathFFTTests.TestSizeSweep;
const
  cSizes: array[0 .. 4] of Integer = (2, 4, 8, 16, 32);
var
  s: Integer;
  Data, Want: TSingleArr;
begin
  if not AVXReady then
    Exit;

  for s := Low(cSizes) to High(cSizes) do
  begin
    Data := MakeSignal(cSizes[s]);
    Want := Copy(Data);

    AVX_FFT_Execute(@Data[0], 1, cSizes[s], False);
    AVX_FFT_Execute(@Data[0], 1, cSizes[s], True);
    CheckBins(Format('round trip N=%d', [cSizes[s]]), @Data[0], @Want[0],
      cSizes[s]);
  end;
end;

procedure TvsmathFFTTests.TestNonPowerOfTwoRejected;
var
  Data: TSingleArr;
  Raised: Boolean;

  procedure Run(ASize: Integer);
  begin
    Raised := False;
    try
      AVX_FFT_Execute(@Data[0], 1, ASize, False);
    except
      on E: EArgumentException do
        Raised := True;
    end;
  end;

begin
  if not AVXReady then
    Exit;

  SetLength(Data, 32 * 2);
  FillChar(Data[0], Length(Data) * SizeOf(Single), 0);

  Run(6);
  AssertTrue('N = 6 must fail loudly, not return a wrong spectrum', Raised);

  Run(12);
  AssertTrue('N = 12 must fail loudly, not return a wrong spectrum', Raised);

  Run(1);   { below one butterfly: a documented no-op, not an error }
  AssertFalse('N = 1 is a no-op', Raised);
end;

{$ENDIF}

initialization
{$IFDEF CPUX64}
  RegisterTest(TvsmathFFTTests);
{$ENDIF}
end.

