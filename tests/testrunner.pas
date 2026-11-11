// ###########################################################
// #### vsmath - vector single math
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the Apache License, Version 2.0 - see LICENSE.
// ###########################################################
// #### FPCUnit console runner. Build from this directory:
// ####
// ####   fpc -Mobjfpc -Fu../src -Fi../src \
// ####       -Fu$FPCDIR/packages/fcl-fpcunit/src \
// ####       -gh -gl -FE./bin testrunner.pas
// ####
// #### Exit code 0 means every test passed.
// ###########################################################
program testrunner;

{$MODE OBJFPC}{$H+}

uses
  consoletestrunner, fpcunit,
  TestVsMath, TestVsMathAVX, TestVsMathDispatch, TestVsMathGuard, TestVsMathFFT;

type
  { TvsmathTestRunner }
  TvsmathTestRunner = class(TTestRunner)
  end;

var
  App: TvsmathTestRunner;

begin
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  App := TvsmathTestRunner.Create(nil);
  try
    App.Initialize;
    App.Title := 'vsmath FPCUnit test runner';
    App.Run;
  finally
    App.Free;
  end;
end.
