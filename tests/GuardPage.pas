// ###########################################################
// #### vsmath - vector single math
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the Apache License, Version 2.0 - see LICENSE.
// ###########################################################
// Guard page harness for the SIMD kernels that take raw pointers.
//
// Every buffer ends on the last byte of a writable page followed by PROT_NONE, so
// a read or write past the end faults instead of returning a neighbour's data.
//
// The kernel runs in a forked child: the parent reports the fault as a test
// failure, the child restores the default SIGSEGV/SIGBUS action and leaves through
// _exit() so heaptrc prints no dump. The parent maps and fills the buffers before
// the fork; the child never allocates.
//
// Non-Unix targets have no mmap/fork, so the harness reports gvHarnessError and the
// calling test ignores itself.
unit GuardPage;

{$MODE OBJFPC}{$H+}

interface

{$IFDEF UNIX}

uses
  BaseUnix;

type
  { What a guarded call did. }
  TGuardVerdict = (
    gvOk,              { returned, exact values, nothing outside the buffers }
    gvWrongValues,     { returned, but Dest does not match the reference }
    gvOutOfBounds,     { died on SIGSEGV/SIGBUS: read or wrote past a buffer }
    gvException,       { raised a Pascal exception (ASignal holds its code) }
    gvHarnessError     { mmap/mprotect/fork failed, or no Unix primitives }
  );

  { The kernel under test. LineWidthMT is Width * SizeOf(Single). }
  TGuardCall = procedure(Mt, V, Dest : PSingle; Width, Height : NativeInt) of object;

{ Name of a verdict, for assertion messages. }
function GuardVerdictName(const AVerdict : TGuardVerdict) : string;

{ Runs ACall on three buffers that all end flush against a PROT_NONE page and
  compares Dest against alpha * Mt * V + beta * Dest. Width and Height are the
  live extents; the buffers hold exactly those extents, no padding.

  ASignal receives the terminating signal or the child's exit code, so a
  failure message can say what happened. }
function RunGuarded(ACall : TGuardCall; AWidth, AHeight : NativeInt;
  const AAlpha, ABeta : Single; out ASignal : cint) : TGuardVerdict;

type
  { The kernel under test for the transposed product, Dest = beta*Dest +
    alpha*Mt^T*V. Mt is Height rows of Width elements, V holds Height elements
    and Dest holds Width elements; all three buffers end flush against a guard
    page, so Dest having Width rather than Height elements matters. }
  TGuardCallT = procedure(Mt, V, Dest : PSingle; Width, Height : NativeInt) of object;

{ Runs ACall on three guard flush buffers and compares Dest against
  alpha*Mt^T*V + beta*Dest. Only the first Width elements of Dest are live. }
function RunGuardedT(ACall : TGuardCallT; AWidth, AHeight : NativeInt;
  const AAlpha, ABeta : Single; out ASignal : cint) : TGuardVerdict;

{ Element patterns used by the harness. They are small integers, so every dot
  product is exactly representable in Single and the comparison can be exact
  regardless of the order the kernel accumulates in. }
function GuardMtValue(AY, AX : NativeInt) : Single;
function GuardVValue(AX : NativeInt) : Single;
function GuardDestValue(AY : NativeInt) : Single;

type
  { Which reduction a guarded call performs. }
  TGuardReduceKind = (grSumRow, grSumColumn, grMeanRow, grMeanColumn);

  { A reduction under test. ASrc holds AWidth * AHeight elements, tightly packed
    (so ASrc[AHeight - 1][AWidth - 1] is the last live element); ADest holds
    AHeight elements for grSumRow and AWidth for grSumColumn, also tight. }
  TGuardReduceCall = procedure(ASrc, ADest : PSingle;
    AWidth, AHeight : NativeInt) of object;

{ Runs a reduction on two buffers that both end flush against a PROT_NONE page
  and compares ADest against the reference sums. GuardMtValue returns small
  integers, so the sums are exact in Single and the comparison ignores the
  accumulation order. The mean kinds divide that exact sum by the reduction
  length, which every kernel does with a single IEEE division, so the mean
  comparison is exact as well. }
function RunGuardedReduce(ACall : TGuardReduceCall; AWidth, AHeight : NativeInt;
  AKind : TGuardReduceKind; out ASignal : cint) : TGuardVerdict;

type
  { Which way a guarded normalize normalizes. }
  TGuardNormKind = (gnRow, gnColumn);

  { A normalize under test. ASrc and ADest are both full AWidth x AHeight
    matrices, tightly packed, so the last element of each ends on the guard
    page. }
  TGuardNormCall = procedure(ASrc, ADest : PSingle;
    AWidth, AHeight : NativeInt) of object;

{ Runs a normalize on two buffers that both end flush against a PROT_NONE page.
  The source is GuardMtValue, so every sum of squares is an exact integer in
  Single whatever order the kernel adds it in; the kernel and the reference
  therefore agree on the norm, take the same IEEE square root and divide with
  the same single rounding, which makes the element comparison exact. A zero
  norm has to come back as zero, never as Inf or NaN. }
function RunGuardedNormalize(ACall : TGuardNormCall; AWidth, AHeight : NativeInt;
  AKind : TGuardNormKind; out ASignal : cint) : TGuardVerdict;

{$ENDIF}

implementation

{$IFDEF UNIX}

const
  { x86_64 Linux uses 4 KiB pages; the harness verifies the mapping instead of
    trusting this value (a wrong page size makes mprotect fail, and then the
    test reports gvHarnessError rather than a false pass). }
  cGuardPageSize = 4096;
  cWrongValues   = 1;
  cHarnessError  = 2;
  cException     = 90;

function GuardVerdictName(const AVerdict : TGuardVerdict) : string;
const
  cNames : array[TGuardVerdict] of string = (
    'ok',
    'wrong values',
    'access past the end of a buffer',
    'exception',
    'guard page harness unavailable');
begin
  Result := cNames[AVerdict];
end;

function GuardMtValue(AY, AX : NativeInt) : Single;
begin
  Result := (((AY + 1) * (AX + 1)) mod 7) - 3;
end;

function GuardVValue(AX : NativeInt) : Single;
begin
  Result := (AX mod 5) - 2;
end;

function GuardDestValue(AY : NativeInt) : Single;
begin
  Result := (AY mod 3) - 1;
end;

{ Maps ASize bytes ending exactly at a PROT_NONE page. }
function MapFlush(ASize : PtrUInt; out AData : PSingle;
  out AMap : Pointer; out AMapSize : PtrUInt) : Boolean;
var
  Pages, Total : PtrUInt;
  P, Guard : PByte;
begin
  Result := False;
  AData := nil;
  AMap := nil;
  AMapSize := 0;
  if ASize = 0 then Exit;
  Pages := (ASize + cGuardPageSize - 1) div cGuardPageSize;
  Total := (Pages + 1) * cGuardPageSize;
  P := fpmmap(nil, Total, PROT_READ or PROT_WRITE,
    MAP_PRIVATE or MAP_ANONYMOUS, -1, 0);
  if P = MAP_FAILED then Exit;
  Guard := P + Total - cGuardPageSize;
  if fpmprotect(Guard, cGuardPageSize, PROT_NONE) <> 0 then
  begin
    fpmunmap(P, Total);
    Exit;
  end;
  AMap := P;
  AMapSize := Total;
  AData := PSingle(Guard - ASize);
  Result := True;
end;

function Compare(AWidth, AHeight : NativeInt; ADest : PSingle;
  const AAlpha, ABeta : Single) : Boolean;
var
  x, y : NativeInt;
  Acc, Expected : Single;
begin
  Result := True;
  for y := 0 to AHeight - 1 do
  begin
    Acc := 0;
    for x := 0 to AWidth - 1 do
      Acc := Acc + GuardMtValue(y, x) * GuardVValue(x);
    Expected := AAlpha * Acc + ABeta * GuardDestValue(y);
    if Abs(ADest[y] - Expected) > 1e-3 then
      Result := False;
  end;
end;

{ The child leaves without running exit handlers, so heaptrc stays quiet. }
procedure LibcExit(code : cint); cdecl; external 'c' name '_exit';

var
  gCall   : TGuardCall;
  gMt     : PSingle;
  gV      : PSingle;
  gDest   : PSingle;
  gWidth  : NativeInt;
  gHeight : NativeInt;

procedure InvokeCall;
begin
  gCall(gMt, gV, gDest, gWidth, gHeight);
end;

function RunGuarded(ACall : TGuardCall; AWidth, AHeight : NativeInt;
  const AAlpha, ABeta : Single; out ASignal : cint) : TGuardVerdict;
var
  MtMap, VMap, DMap : Pointer;
  MtSize, VSize, DSize : PtrUInt;
  Mt, V, D : PSingle;
  pid : TPid;
  st, rc : cint;
  act : SigActionRec;
  x, y : NativeInt;
begin
  ASignal := 0;
  Result := gvHarnessError;
  if (ACall = nil) or (AWidth <= 0) or (AHeight <= 0) then Exit;

  if not MapFlush(AWidth * AHeight * SizeOf(Single), Mt, MtMap, MtSize) then Exit;
  if not MapFlush(AWidth * SizeOf(Single), V, VMap, VSize) then
  begin
    fpmunmap(MtMap, MtSize);
    Exit;
  end;
  if not MapFlush(AHeight * SizeOf(Single), D, DMap, DSize) then
  begin
    fpmunmap(MtMap, MtSize);
    fpmunmap(VMap, VSize);
    Exit;
  end;

  try
    for y := 0 to AHeight - 1 do
      for x := 0 to AWidth - 1 do
        Mt[y * AWidth + x] := GuardMtValue(y, x);
    for x := 0 to AWidth - 1 do
      V[x] := GuardVValue(x);
    for y := 0 to AHeight - 1 do
      D[y] := GuardDestValue(y);

    gCall := ACall;
    gMt := Mt;
    gV := V;
    gDest := D;
    gWidth := AWidth;
    gHeight := AHeight;

    pid := fpFork;
    if pid = 0 then
    begin
      FillChar(act, SizeOf(act), 0);        { sa_handler = nil = SIG_DFL }
      fpsigaction(SIGSEGV, @act, nil);
      fpsigaction(SIGBUS, @act, nil);
      try
        InvokeCall;
      except
        LibcExit(cException);
      end;
      try
        if not Compare(AWidth, AHeight, D, AAlpha, ABeta) then
          LibcExit(cWrongValues);
      except
        LibcExit(cException);
      end;
      LibcExit(0);
    end;

    if pid < 0 then
      Exit(gvHarnessError);

    st := 0;
    repeat
      rc := fpWaitPid(pid, @st, 0);
    until (rc = pid) or (rc < 0);
    if rc < 0 then
      Exit(gvHarnessError);

    if WIFSIGNALED(st) then
    begin
      ASignal := WTERMSIG(st);
      if (ASignal = SIGSEGV) or (ASignal = SIGBUS) then
        Result := gvOutOfBounds
      else
        Result := gvHarnessError;
    end
    else if WIFEXITED(st) then
    begin
      ASignal := WEXITSTATUS(st);
      case ASignal of
        0            : Result := gvOk;
        cWrongValues : Result := gvWrongValues;
        cException   : Result := gvException;
      else
        Result := gvHarnessError;
      end;
    end;
  finally
    fpmunmap(MtMap, MtSize);
    fpmunmap(VMap, VSize);
    fpmunmap(DMap, DSize);
  end;
end;

{$ENDIF}

{$IFDEF UNIX}

var
  gReduceCall   : TGuardReduceCall;
  gReduceSrc    : PSingle;
  gReduceDest   : PSingle;
  gReduceWidth  : NativeInt;
  gReduceHeight : NativeInt;
  gReduceKind   : TGuardReduceKind;

procedure InvokeReduce;
begin
  gReduceCall(gReduceSrc, gReduceDest, gReduceWidth, gReduceHeight);
end;

function CompareReduce(AWidth, AHeight : NativeInt; ADest : PSingle;
  AKind : TGuardReduceKind) : Boolean;
var
  x, y : NativeInt;
  Acc : Single;
begin
  Result := True;
  if AKind in [grSumRow, grMeanRow] then
  begin
    for y := 0 to AHeight - 1 do
    begin
      Acc := 0;
      for x := 0 to AWidth - 1 do
        Acc := Acc + GuardMtValue(y, x);
      if AKind = grMeanRow then
        Acc := Acc / AWidth;
      if ADest[y] <> Acc then
        Result := False;
    end;
  end
  else
  begin
    for x := 0 to AWidth - 1 do
    begin
      Acc := 0;
      for y := 0 to AHeight - 1 do
        Acc := Acc + GuardMtValue(y, x);
      if AKind = grMeanColumn then
        Acc := Acc / AHeight;
      if ADest[x] <> Acc then
        Result := False;
    end;
  end;
end;

var
  gCallT   : TGuardCallT;
  gMtT     : PSingle;
  gVT      : PSingle;
  gDestT   : PSingle;
  gWidthT  : NativeInt;
  gHeightT : NativeInt;

procedure InvokeCallT;
begin
  gCallT(gMtT, gVT, gDestT, gWidthT, gHeightT);
end;

function CompareT(AWidth, AHeight : NativeInt; ADest : PSingle;
  const AAlpha, ABeta : Single) : Boolean;
var
  x, y : NativeInt;
  Acc, Expected : Single;
begin
  Result := True;
  for x := 0 to AWidth - 1 do
  begin
    Acc := 0;
    for y := 0 to AHeight - 1 do
      Acc := Acc + GuardMtValue(y, x) * GuardVValue(y);
    Expected := AAlpha * Acc + ABeta * GuardDestValue(x);
    if Abs(ADest[x] - Expected) > 1e-3 then
      Result := False;
  end;
end;

function RunGuardedT(ACall : TGuardCallT; AWidth, AHeight : NativeInt;
  const AAlpha, ABeta : Single; out ASignal : cint) : TGuardVerdict;
var
  MtMap, VMap, DMap : Pointer;
  MtSize, VSize, DSize : PtrUInt;
  Mt, V, D : PSingle;
  pid : TPid;
  st, rc : cint;
  act : SigActionRec;
  x, y : NativeInt;
begin
  ASignal := 0;
  Result := gvHarnessError;
  if (ACall = nil) or (AWidth <= 0) or (AHeight <= 0) then Exit;

  if not MapFlush(AWidth * AHeight * SizeOf(Single), Mt, MtMap, MtSize) then Exit;
  if not MapFlush(AHeight * SizeOf(Single), V, VMap, VSize) then
  begin
    fpmunmap(MtMap, MtSize);
    Exit;
  end;
  { the destination of the transposed product holds Width elements, not Height }
  if not MapFlush(AWidth * SizeOf(Single), D, DMap, DSize) then
  begin
    fpmunmap(MtMap, MtSize);
    fpmunmap(VMap, VSize);
    Exit;
  end;

  try
    for y := 0 to AHeight - 1 do
    begin
      for x := 0 to AWidth - 1 do
        Mt[y * AWidth + x] := GuardMtValue(y, x);
      V[y] := GuardVValue(y);
    end;
    for x := 0 to AWidth - 1 do
      D[x] := GuardDestValue(x);

    gCallT := ACall;
    gMtT := Mt;
    gVT := V;
    gDestT := D;
    gWidthT := AWidth;
    gHeightT := AHeight;

    pid := fpFork;
    if pid = 0 then
    begin
      FillChar(act, SizeOf(act), 0);        { sa_handler = nil = SIG_DFL }
      fpsigaction(SIGSEGV, @act, nil);
      fpsigaction(SIGBUS, @act, nil);
      try
        InvokeCallT;
      except
        LibcExit(cException);
      end;
      try
        if not CompareT(AWidth, AHeight, D, AAlpha, ABeta) then
          LibcExit(cWrongValues);
      except
        LibcExit(cException);
      end;
      LibcExit(0);
    end;

    if pid < 0 then
      Exit(gvHarnessError);

    st := 0;
    repeat
      rc := fpWaitPid(pid, @st, 0);
    until (rc = pid) or (rc < 0);
    if rc < 0 then
      Exit(gvHarnessError);

    if WIFSIGNALED(st) then
    begin
      ASignal := WTERMSIG(st);
      if (ASignal = SIGSEGV) or (ASignal = SIGBUS) then
        Result := gvOutOfBounds
      else
        Result := gvHarnessError;
    end
    else if WIFEXITED(st) then
    begin
      ASignal := WEXITSTATUS(st);
      case ASignal of
        0            : Result := gvOk;
        cWrongValues : Result := gvWrongValues;
        cException   : Result := gvException;
      else
        Result := gvHarnessError;
      end;
    end;
  finally
    fpmunmap(MtMap, MtSize);
    fpmunmap(VMap, VSize);
    fpmunmap(DMap, DSize);
  end;
end;


function RunGuardedReduce(ACall : TGuardReduceCall; AWidth, AHeight : NativeInt;
  AKind : TGuardReduceKind; out ASignal : cint) : TGuardVerdict;
const
  { anything the kernel did not write keeps this value and fails the compare }
  cPoison : Single = 1.0e6;
var
  SrcMap, DstMap : Pointer;
  SrcSize, DstSize : PtrUInt;
  Src, Dst : PSingle;
  DstCount : NativeInt;
  pid : TPid;
  st, rc : cint;
  act : SigActionRec;
  x, y : NativeInt;
begin
  ASignal := 0;
  Result := gvHarnessError;
  if (ACall = nil) or (AWidth <= 0) or (AHeight <= 0) then Exit;

  if AKind in [grSumRow, grMeanRow] then DstCount := AHeight else DstCount := AWidth;

  if not MapFlush(AWidth * AHeight * SizeOf(Single), Src, SrcMap, SrcSize) then Exit;
  if not MapFlush(DstCount * SizeOf(Single), Dst, DstMap, DstSize) then
  begin
    fpmunmap(SrcMap, SrcSize);
    Exit;
  end;

  try
    for y := 0 to AHeight - 1 do
      for x := 0 to AWidth - 1 do
        Src[y * AWidth + x] := GuardMtValue(y, x);
    for x := 0 to DstCount - 1 do
      Dst[x] := cPoison;

    gReduceCall := ACall;
    gReduceSrc := Src;
    gReduceDest := Dst;
    gReduceWidth := AWidth;
    gReduceHeight := AHeight;
    gReduceKind := AKind;

    pid := fpFork;
    if pid = 0 then
    begin
      FillChar(act, SizeOf(act), 0);        { sa_handler = nil = SIG_DFL }
      fpsigaction(SIGSEGV, @act, nil);
      fpsigaction(SIGBUS, @act, nil);
      try
        InvokeReduce;
      except
        LibcExit(cException);
      end;
      try
        if not CompareReduce(AWidth, AHeight, Dst, AKind) then
          LibcExit(cWrongValues);
      except
        LibcExit(cException);
      end;
      LibcExit(0);
    end;

    if pid < 0 then
      Exit(gvHarnessError);

    st := 0;
    repeat
      rc := fpWaitPid(pid, @st, 0);
    until (rc = pid) or (rc < 0);
    if rc < 0 then
      Exit(gvHarnessError);

    if WIFSIGNALED(st) then
    begin
      ASignal := WTERMSIG(st);
      if (ASignal = SIGSEGV) or (ASignal = SIGBUS) then
        Result := gvOutOfBounds
      else
        Result := gvHarnessError;
    end
    else if WIFEXITED(st) then
    begin
      ASignal := WEXITSTATUS(st);
      case ASignal of
        0            : Result := gvOk;
        cWrongValues : Result := gvWrongValues;
        cException   : Result := gvException;
      else
        Result := gvHarnessError;
      end;
    end;
  finally
    fpmunmap(SrcMap, SrcSize);
    fpmunmap(DstMap, DstSize);
  end;
end;

var
  gNormCall   : TGuardNormCall;
  gNormSrc    : PSingle;
  gNormDest   : PSingle;
  gNormWidth  : NativeInt;
  gNormHeight : NativeInt;

procedure InvokeNormalize;
begin
  gNormCall(gNormSrc, gNormDest, gNormWidth, gNormHeight);
end;

function CompareNormalize(AWidth, AHeight : NativeInt; ADest : PSingle;
  AKind : TGuardNormKind) : Boolean;
var
  x, y, i : NativeInt;
  Acc, Norm, Expected : Single;
begin
  Result := True;
  for y := 0 to AHeight - 1 do
    for x := 0 to AWidth - 1 do
    begin
      Acc := 0;
      if AKind = gnRow then
      begin
        for i := 0 to AWidth - 1 do
          Acc := Acc + Sqr(GuardMtValue(y, i));
      end
      else
      begin
        for i := 0 to AHeight - 1 do
          Acc := Acc + Sqr(GuardMtValue(i, x));
      end;

      if Acc = 0 then
        Norm := 0
      else
        Norm := Sqrt(Acc);

      if Norm = 0 then
        Expected := 0                       { a zero norm normalizes to zero }
      else
        Expected := GuardMtValue(y, x) / Norm;

      if ADest[y * AWidth + x] <> Expected then
        Result := False;
    end;
end;

function RunGuardedNormalize(ACall : TGuardNormCall; AWidth, AHeight : NativeInt;
  AKind : TGuardNormKind; out ASignal : cint) : TGuardVerdict;
const
  { anything the kernel did not write keeps this value and fails the compare }
  cPoison : Single = 1.0e6;
var
  SrcMap, DstMap : Pointer;
  SrcSize, DstSize : PtrUInt;
  Src, Dst : PSingle;
  Count : NativeInt;
  pid : TPid;
  st, rc : cint;
  act : SigActionRec;
  x, y : NativeInt;
begin
  ASignal := 0;
  Result := gvHarnessError;
  if (ACall = nil) or (AWidth <= 0) or (AHeight <= 0) then Exit;

  Count := AWidth * AHeight;

  if not MapFlush(Count * SizeOf(Single), Src, SrcMap, SrcSize) then Exit;
  if not MapFlush(Count * SizeOf(Single), Dst, DstMap, DstSize) then
  begin
    fpmunmap(SrcMap, SrcSize);
    Exit;
  end;

  try
    for y := 0 to AHeight - 1 do
      for x := 0 to AWidth - 1 do
        Src[y * AWidth + x] := GuardMtValue(y, x);
    for x := 0 to Count - 1 do
      Dst[x] := cPoison;

    gNormCall := ACall;
    gNormSrc := Src;
    gNormDest := Dst;
    gNormWidth := AWidth;
    gNormHeight := AHeight;

    pid := fpFork;
    if pid = 0 then
    begin
      FillChar(act, SizeOf(act), 0);        { sa_handler = nil = SIG_DFL }
      fpsigaction(SIGSEGV, @act, nil);
      fpsigaction(SIGBUS, @act, nil);
      try
        InvokeNormalize;
      except
        LibcExit(cException);
      end;
      try
        if not CompareNormalize(AWidth, AHeight, Dst, AKind) then
          LibcExit(cWrongValues);
      except
        LibcExit(cException);
      end;
      LibcExit(0);
    end;

    if pid < 0 then
      Exit(gvHarnessError);

    st := 0;
    repeat
      rc := fpWaitPid(pid, @st, 0);
    until (rc = pid) or (rc < 0);
    if rc < 0 then
      Exit(gvHarnessError);

    if WIFSIGNALED(st) then
    begin
      ASignal := WTERMSIG(st);
      if (ASignal = SIGSEGV) or (ASignal = SIGBUS) then
        Result := gvOutOfBounds
      else
        Result := gvHarnessError;
    end
    else if WIFEXITED(st) then
    begin
      ASignal := WEXITSTATUS(st);
      case ASignal of
        0            : Result := gvOk;
        cWrongValues : Result := gvWrongValues;
        cException   : Result := gvException;
      else
        Result := gvHarnessError;
      end;
    end;
  finally
    fpmunmap(SrcMap, SrcSize);
    fpmunmap(DstMap, DstSize);
  end;
end;

{$ENDIF}

end.
