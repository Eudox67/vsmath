// ###################################################################
// #### This file is part of the vsmath project - a 32-bit, single-
// #### precision (mode objfpc) fork of mrMath:
// ####   https://github.com/mikerabat/mrmath
// ####
// #### Derived from mrMath. Copyright (c) 2023, Michael R. All rights reserved.
// #### Licensed under the Apache License, Version 2.0 - see LICENSE.
// ####
// #### Modifications Copyright 2026 Eudox67.
// #### Ported from double/x64 to 32-bit single precision; converted
// #### to {$mode objfpc}. See NOTICE for details.
// ####
// #### vsmath is an independent fork and is not affiliated with,
// #### endorsed by, or supported by the mrMath project or its author.
// ###################################################################
// CPU target switches, included before the first {$IFDEF CPUX64} of every unit:
//   CPUX64        64 bit AMD/Intel (FPC's own macro) - the only target with
//                 assembler kernels
//   VSMATH_NOASM  any other target - the kernel units declare nothing
//
// The include is required: the assembler bodies need the mode and stack switches
// below, so a unit that omits it fails to assemble.
{$IFNDEF CPUX64}
  {$DEFINE VSMATH_NOASM}
{$ENDIF}

{$DEFINE AVXSUP}  // assembler support for AVX/FMA built in

// asm routines use Intel syntax; stack checking off for the assembler bodies
{$IFNDEF VSMATH_NOASM}
{$ASMMODE intel} {$S-}
{$ENDIF}
