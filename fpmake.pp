program fpmake;

{$mode objfpc}{$H+}

uses
{$ifdef unix}
  cthreads,
{$endif}
  fpmkunit;

var
  P: TPackage;
begin
  with Installer do
  begin
    P := AddPackage('vsmath');
    P.Version := '1.0.0';
    P.Author := 'vsmath Contributors';
    P.License := 'Apache-2.0';
    P.Description := 'Single-precision SIMD matrix/vector math for Free Pascal';

    P.OSes := [linux, win32, win64];
    P.CPUs := [x86_64];

    // SourcePath locates the files named in AddUnit; UnitPath feeds -Fu
    // and IncludePath feeds -Fi for the shared *.inc files.
    P.SourcePath.Add('src');
    P.UnitPath.Add('src');
    P.IncludePath.Add('src');

    // The units declare {$mode objfpc} themselves; stating it keeps the
    // package build identical to a hand-written fpc invocation.
    P.Options.Add('-Mobjfpc');

    // No target define is needed: the kernel units guard their bodies with
    // {$IFDEF CPUX64}, which the compiler defines for this target.

    // fpmkunit injects an implicit dependency on the "rtl" package, which
    // needs a per-package unit-config file (<unitdir>/rtl/rtl.fpc) that
    // many FPC installs do not ship; the lookup then aborts with
    //   Could not find unit directory for dependency package "rtl"
    // The compiler already knows where its own RTL is, so the dependency
    // is dropped and this package needs no external resolution.
    P.Dependencies.Clear;

    P.Targets.AddUnit('ASMMatrixAbsOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMMatrixAddSubOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMMatrixCumSumDiffOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMMatrixElementwiseMultOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMMatrixMeanOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMMatrixMinMaxOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMMatrixMultOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMMatrixMultTransposedOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMMatrixNormOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMMatrixRotationsSinglex64.pas');
    P.Targets.AddUnit('ASMMatrixScaleOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMMatrixSqrtOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMMatrixSumOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMMatrixTransposeOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMMatrixVectorMultOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMMoveOperationsSinglex64.pas');
    P.Targets.AddUnit('ASMVecConvolveSinglex64.pas');
    P.Targets.AddUnit('ASMVecDistSinglex64.pas');
    P.Targets.AddUnit('AVXFFT.pas');
    P.Targets.AddUnit('AVXMatrixAbsOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXMatrixAddSubOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXMatrixCumSumDiffOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXMatrixElementwiseMultOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXMatrixMeanOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXMatrixMinMaxOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXMatrixMultOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXMatrixMultTransposedOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXMatrixNormOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXMatrixRotationsSinglex64.pas');
    P.Targets.AddUnit('AVXMatrixScaleOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXMatrixSqrtOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXMatrixSumOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXMatrixTransposeOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXMatrixVectorMultOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXMoveOperationsSinglex64.pas');
    P.Targets.AddUnit('AVXRowMajorMultSinglex64.pas');
    P.Targets.AddUnit('AVXVecConvolveSinglex64.pas');
    P.Targets.AddUnit('CPUFeaturesSingle.pas');
    P.Targets.AddUnit('FMAMatrixMultOperationsSinglex64.pas');
    P.Targets.AddUnit('FMAMatrixMultTransposedOperationsSinglex64.pas');
    P.Targets.AddUnit('FMAMatrixVectorMultOperationsSinglex64.pas');
    P.Targets.AddUnit('FMAVecConvolveSinglex64.pas');
    P.Targets.AddUnit('MatrixASMDispatchSingle.pas');
    P.Targets.AddUnit('MatrixConstSingle.pas');

    Run;
  end;
end.
