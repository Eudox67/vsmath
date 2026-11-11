# vsmath - vector single math

**vsmath** is a SIMD matrix and vector math library for Free Pascal
(`{$mode objfpc}`) that targets **32-bit single precision (Float32)**. It is
the CPU SIMD backend for AI inference workloads: the kernels stay in single
precision end to end (no double round trips), widths and strides are byte
counts, and every routine is inline x86 assembler behind a small Pascal API.

All 44 units compile on `x86_64-linux` (`fpmake compile`); the SSE and AVX 
kernels are covered by a 125 test fpcunit suite, all green and heap-leak clean, 
including guard-page checks for the matrix-vector, transposed matrix-vector, rank-1 
and copy families. The public entry points in `MatrixASMDispatchSingle` take any 
width, height and stride - no parity or alignment argument ever reaches the caller. 
The triangular entry points `...TUpperUnit` and `...T1StoreT1` raise 
`ENotImplemented` rather than computing.

## Requirements

- Free Pascal 3.2.2 or newer (developed against 3.3.1 trunk), target
  `x86_64-linux`.
- The assembler kernels are **x86_64 only**. On any other target the kernel
  units declare nothing and `MatrixASMDispatchSingle` still compiles and runs
  as a scalar-only build.
- No external library dependencies. Running the test suite additionally needs
  `fcl-fpcunit` (ships with FPC).

## Layout

```
vsmath/
  src/                       44 units
                             *Singlex64      x86_64 SSE/AVX/FMA kernels
                             VsMath_CPU.inc  CPU target switches, shared
                             MatrixConstSingle.pas, CPUFeaturesSingle.pas,
                             MatrixASMDispatchSingle.pas  shared support units
  tests/
    TestVsMath.pas           fpcunit test case (x86_64 SSE kernels)
    TestVsMathAVX.pas        fpcunit test case (x86_64 AVX kernels)
    TestVsMathDispatch.pas   fpcunit test case (CPU level dispatch, all levels)
    TestVsMathGuard.pas      guard page harness: buffers flush against PROT_NONE
    TestVsMathFFT.pas        fpcunit test case (AVX FFT, against a DFT reference)
    GuardPage.pas            the mmap/mprotect helper that harness uses
    testrunner.pas           console test runner
    run_tests.sh             build + run the suite (heaptrc enabled)
  fpmake.pp                  FPC package manifest (fpmake)
  vsmath.lpk                 Lazarus package
  vsmath.cfg                 plain fpc config fragment (-Fu/-Fi)
```

## Using it

### 1. As an installable FPC package (fpmake)

```bash
fpc fpmake.pp
./fpmake compile
./fpmake install --prefix=$HOME/.local
```

The 44 units are defined by the `AddUnit` calls in `fpmake.pp` and the `<Files>`
block in `vsmath.lpk`; keep the two in step when a unit is added.

`./fpmake compile` is the packaging check that runs against this release
(`[100%] Compiled package vsmath`, all 44 units); it needs no external package. 
`install` was not exercised here - it writes under `<prefix>/lib/fpc/<version>/vsmath`.

### 2. Straight from the checkout with fpc

```bash
fpc @vsmath.cfg MyProgram.pas
```

`vsmath.cfg` adds `src/` to the unit and include paths and selects
`-Mobjfpc`. Its paths are relative to the current directory, so run fpc from
the package root (or edit the two `-Fu`/`-Fi` lines).


### 3. Lazarus

**IDE:** *Package -> Open Package File (.lpk)* -> `vsmath.lpk` -> *Compile* ->
*Use -> Add to Project*, which adds `vsmath` (type `RunTime`) to the project's
required packages.

```bash
# headless: make the package visible to the package graph, then build it
lazbuild --add-package-link vsmath.lpk
lazbuild vsmath.lpk            # -> lib/x86_64-linux/*.ppu
```

The package exports `src` as its unit path and compiles one `.ppu` per unit plus
`vsmath.ppu`. Lazarus writes the package main unit `vsmath.pas` on every build
from the `.lpk` file list: keep it committed, never edit it.

### API conventions

- Buffers are `PSingle`; `LineWidth`/`DestLineWidth` strides are in **bytes**,
  widths and heights are in elements.
- `ASMVecMin*` / `ASMVecMax*` are in-place reductions:
  `Dest[i] := Min(Dest[i], Src[i])` / `Max(...)`.
- `*Aligned*` variants require 16-byte (SSE) or 32-byte (AVX) aligned data;
  use the matching `*UnAligned*` variant otherwise.
- `EvenW`/`OddW`, `EvenH`/`OddH` suffixes select the kernel for that width or
  height parity; picking the wrong one produces wrong results, not an error.
  They are **internal kernel selectors**, not part of the calling contract.

## CPU level dispatch

`MatrixASMDispatchSingle` is the front door for callers that do not want to pick
a kernel variant by hand. It keeps a table of the kernels of the current CPU
level and exposes the aggregate entry points (`MatrixAdd`, `MatrixSum`,
`MatrixMult`, `MatrixTranspose`, ...) plus the memory helpers.

```pascal
uses MatrixASMDispatchSingle;

InitMathFunctions(itAVX, False);   // itFPU / itSSE / itAVX / itFMA
MatrixAdd(dst, dstLineWidth, a, b, width, height, lwA, lwB);
```

- `InitMathFunctions` never selects a level the CPU cannot execute; a wish that
  is too high is clamped down, `itFPU` always stays `itFPU`. `GetCurCPUInstrType`
  reports what is in use, `GetBestCPUInstrType` what the machine can do. The unit
  initialises itself to the best available level, so calling it is optional.
- `itFPU` is a complete scalar implementation of every entry point, so it is also
  the reference the test suite compares against.
- Line widths and vectors follow the kernel conventions: strides in bytes,
  widths/heights in elements. A *vector* operand (`v` in `MatrixMtxVecMult`, `X`
  and `Y` in `MatrixRank1Update`/`MatrixVecDotMult`) uses `sizeof(Single)` as its
  line width, not a padded row width.
- Only `*UnAligned` kernels are used, so alignment is never a precondition; row
  widths that are not a multiple of four are split into a kernel part and a
  scalar tail.

## Coverage of this release

| family | unit (x86_64) | compiles | tested |
|---|---|---|---|
| min/max, abs-min/abs-max | `ASMMatrixMinMaxOperationsSinglex64` | yes | yes |
| scale / add-scale / elementwise add | `ASMMatrixScaleOperationsSinglex64`, `ASMMatrixAddSubOperationsSinglex64` | yes | yes |
| mean, variance | `ASMMatrixMeanOperationsSinglex64` | yes | yes |
| dot product | `ASMMatrixVectorMultOperationsSinglex64` | yes | yes |
| const helpers | `MatrixConstSingle` | yes | yes |
| abs, rotations | `ASMMatrixAbsOperationsSinglex64`, `ASMMatrixRotationsSinglex64` | yes | yes |
| sqrt, sum, cumsum/diff, norm, convolve, distance, mult, move | `ASM*Singlex64` | yes | convolve yes, rest no |
| FFT (radix-2, power-of-two sizes) | `AVXFFT` | yes | yes (`tests/TestVsMathFFT.pas`, against a DFT reference) |
| transpose | `ASMMatrixTransposeOperationsSinglex64` | yes | yes (8 entry points, inplace) |
| AVX abs / add / sub / scale / add-scale / elementwise mult+div / sqrt | `AVX*Singlex64` | yes | yes |
| AVX sum-column, mean-row, variance-row, norm2, min/max | `AVX*Singlex64` | yes | yes |
| AVX dot product, matrix multiply, matrix-vector multiply, cumulative sum | `AVX*Singlex64` | yes | yes |
| AVX move (copy, init) | `AVXMoveOperationsSinglex64` | yes | yes |
| AVX rotations | `AVXMatrixRotationsSinglex64` | yes | yes (aligned, odd `N`, strided, plane-rot sequences) |
| AVX mult-transposed | `AVXMatrixMultTransposedOperationsSinglex64` | yes | yes (aligned, unaligned, Mod16 twins) |
| AVX convolve | `AVXVecConvolveSinglex64`, `FMAVecConvolveSinglex64` | yes | yes (`bLen` 0..16) |
| AVX sum-row, normalize row/column | `AVXMatrixSumOperationsSinglex64`, `AVXMatrixNormOperationsSinglex64` | yes | yes |
| FMA units | `FMA*Singlex64` | yes | convolve yes; `VectMultT`/`VecMultTDestVec`/`VectMult{Aligned,UnAligned}VAligned`/`Rank1*` forward to the AVX kernels and are compared lane by lane; rest no |
| triangular multiply / rank update | `AVX*Singlex64`, `FMA*Singlex64`, `ASM*Singlex64` | yes | `T1`/`Store1`/`Store1Unit`/`LowTria2T2Store1`/`SymRank2` forwarders yes; `TUpperUnit` and `T1StoreT1` **raise `ENotImplemented`** |
| CPU level dispatch | `MatrixASMDispatchSingle` | yes | yes (`tests/TestVsMathDispatch.pas`, every level) |

## Tests

```bash
./tests/run_tests.sh              # build + run: 125 tests (23 SSE + 43 AVX/SSE + 30 dispatch + 22 guard page + 7 FFT)
fpc fpmake.pp && ./fpmake compile # packaging build: all 44 units
```

- The suite is built with `-gh` (heaptrc); `run_tests.sh` fails if the
  `unfreed memory blocks` count is not zero.
- Every kernel is compared against a plain Pascal reference over data that is
  exactly representable in `Single` (multiples of 1/4, power-of-two divisors,
  exact square roots), so a pass means the kernel computes the same values, not
  merely "close enough".
- The AVX tests live in `tests/TestVsMathAVX.pas` and skip themselves with
  `Ignore()` on a CPU without AVX (they are raw AVX code, they would fault);
  `tests/TestVsMathFFT.pas` does the same for `AVX_FFT_Execute`.
- The FFT is compared against a naive `O(N^2)` DFT for every power-of-two size
  from 2 to 32, for one batched call, and on a shifted impulse whose imaginary
  bins a butterfly pass that drops the imaginary half of the data would return
  as zero.
- Over-reads and over-writes are caught by a poisoned pad behind the live data
  (`cPoison`): a kernel that leaves its buffers pays for it with a wrong result
  instead of silently reading zeros. The pad is checked after every call.
- The forwarder tests in `tests/TestVsMathAVX.pas` compare a delegating entry
  point against the kernel it delegates to, element for element, and require the
  result to differ from the untouched input. The two triangular kernels that are
  not implemented must raise `ENotImplemented`; no test asserts wrong output.

## License

Licensed under the **Apache License, Version 2.0** - see [`LICENSE`](LICENSE)
and [`NOTICE`](NOTICE).

- Upstream (mrMath) copyright: (c) 2011-2024 Michael Rabatscher
- Vmath modifications: Copyright 2026 Eudox67
