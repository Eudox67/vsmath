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


unit FMAMatrixVectorMultOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

uses MatrixConstSingle;

procedure FMAMatrixVectMultT(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle;{$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF}, {$ifdef UNIX}unixbeta {$ELSE}beta{$ENDIF} : single);
procedure FMAMatrixVectMultAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF}, {$ifdef UNIX}unixbeta {$ELSE}beta{$ENDIF} : single);
procedure FMAMatrixVectMultUnAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF}, {$ifdef UNIX}unixbeta {$ELSE}beta{$ENDIF} : single);
procedure FMAMatrixVecMultTDestVec(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; {$ifdef UNIX}unixLineWidthMT{$ELSE}LineWidthMT{$endif}, {$ifdef UNIX}unixLineWidthV{$ELSE}LineWidthV{$endif} : NativeInt; width, height : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF}, {$ifdef UNIX}unixbeta {$ELSE}beta{$ENDIF} : single);
procedure FMARank1UpdateSeq(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt; {$ifdef UNIX}unixX{$ELSE}X{$endif}, {$ifdef UNIX}unixY{$ELSE}Y{$ENDIF} : PSingle; incX, incY : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF} : single);
procedure FMARank1UpdateSeqAligned(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt; {$ifdef UNIX}unixX{$ELSE}X{$endif}, {$ifdef UNIX}unixY{$ELSE}Y{$ENDIF} : PSingle; incX, incY : NativeInt; {$ifdef UNIX}unixalpha {$ELSE}alpha{$ENDIF} : single);

{$ENDIF}

implementation

{$IFDEF CPUX64}

uses AVXMatrixVectorMultOperationsSinglex64;

// Both VAligned kernels delegate to the AVX twins: the inherited FMA bodies walked
// the x loop one lane group too far and read four elements past every row. Merging
// the multiply and the add into FMA instructions is a separate optimisation.
procedure FMAMatrixVectMultAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; unixLineWidthMT, unixLineWidthV : NativeInt; width, height : NativeInt; unixalpha, unixbeta : single);
begin
   AVXMatrixVectMultAlignedVAligned(dest, destLineWidth, mt1, v, unixLineWidthMT,
     unixLineWidthV, width, height, unixalpha, unixbeta);
end;
procedure FMAMatrixVectMultUnAlignedVAligned(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; unixLineWidthMT, unixLineWidthV : NativeInt; width, height : NativeInt; unixalpha, unixbeta : single);
begin
   AVXMatrixVectMultUnAlignedVAligned(dest, destLineWidth, mt1, v,
     unixLineWidthMT, unixLineWidthV, width, height, unixalpha, unixbeta);
end;

// These four delegate to the AVX kernels in AVXMatrixVectorMultOperationsSinglex64:
// FMA is a superset of AVX, so the delegation can never execute an unsupported
// instruction. Merging the multiply and the add into FMA instructions is a
// separate optimisation.
procedure FMAMatrixVectMultT(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; unixLineWidthMT, unixLineWidthV : NativeInt; width, height : NativeInt; unixalpha, unixbeta : single);
begin
   AVXMatrixVectMultT(dest, destLineWidth, mt1, v, unixLineWidthMT, unixLineWidthV, width, 
     height, unixalpha, unixbeta);
end;
procedure FMAMatrixVecMultTDestVec(dest : PSingle; destLineWidth : NativeInt; mt1, v : PSingle; unixLineWidthMT, unixLineWidthV : NativeInt; width, height : NativeInt; unixalpha, unixbeta : single);
begin
   AVXMatrixVecMultTDestVec(dest, destLineWidth, mt1, v, unixLineWidthMT, unixLineWidthV, 
     width, height, unixalpha, unixbeta);
end;
procedure FMARank1UpdateSeq(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt; unixX, unixY : PSingle; incX, incY : NativeInt; unixalpha : single);
begin
   AVXRank1UpdateSeq(A, LineWidthA, width, height, unixX, unixY, incX, incY, unixalpha);
end;
procedure FMARank1UpdateSeqAligned(A : PSingle; const LineWidthA : NativeInt; width, height : NativeInt; unixX, unixY : PSingle; incX, incY : NativeInt; unixalpha : single);
begin
   AVXRank1UpdateSeqAligned(A, LineWidthA, width, height, unixX, unixY, incX, incY, unixalpha);
end;

{$ENDIF}

end.