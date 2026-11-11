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


unit AVXMatrixNormOperationsSinglex64;

interface

{$MODE OBJFPC}{$H+}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}

uses MatrixConstSingle;

function AVXMatrixElementwiseNorm2Aligned(dest : PSingle; const LineWidth : NativeInt; Width, height : NativeInt) : single; assembler;
function AVXMatrixElementwiseNorm2UnAligned(dest : PSingle; const LineWidth : NativeInt; Width, height : NativeInt) : single; assembler;

procedure AVXMatrixNormalizeRowAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt); assembler;
procedure AVXMatrixNormalizeRowUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt); assembler;

procedure AVXMatrixNormalizeColumnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt); assembler;
procedure AVXMatrixNormalizeColumnUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

function AVXMatrixElementwiseNorm2Aligned(dest : PSingle; const LineWidth : NativeInt; Width, height : NativeInt) : single; assembler;
asm
   {$IFDEF UNIX}
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   vxorps ymm0, ymm0, ymm0;
   vxorps xmm2, xmm2, xmm2; // Remainder accumulator
   // an empty matrix has a zero sum of squares; the row loop below
   // would not terminate for a non positive extent
   test r9, r9;
   jle @@finish;
   test r8, r8;
   jle @@finish;
   
   @@foryloop:
      mov rax, rcx;
      mov r10, r8;
      
      @@forxloop:
         cmp r10, 8;
         jl @@lastX;
         
         vmovups ymm1, [rax];
         vmulps ymm1, ymm1, ymm1;
         vaddps ymm0, ymm0, ymm1;
         add rax, 32;
         sub r10, 8;
         cmp r10, 8;
      jge @@forxloop;
      
      @@lastX:
      test r10, r10;
      jz @@nextRow;
      
      @@forxremainder:
         vmovss xmm1, [rax];
         vmulss xmm1, xmm1, xmm1;
         vaddss xmm2, xmm2, xmm1;
         add rax, 4;
      dec r10;
      jnz @@forxremainder;
      
      @@nextRow:
      add rcx, rdx;
   dec r9;
   jnz @@foryloop;
   
   vextractf128 xmm1, ymm0, 1;
   vaddps xmm0, xmm0, xmm1;
   vaddps xmm0, xmm0, xmm2; // Add remainders
   @@finish:
   vhaddps xmm0, xmm0, xmm0;
   vhaddps xmm0, xmm0, xmm0;
   // sum of squares only: MatrixElementwiseNorm2 folds the uncovered columns and
   // takes the square root when the caller asked for it
   vzeroupper;
end;

function AVXMatrixElementwiseNorm2UnAligned(dest : PSingle; const LineWidth : NativeInt; Width, height : NativeInt) : single; assembler;
asm
   {$IFDEF UNIX}
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   vxorps ymm0, ymm0, ymm0;
   vxorps xmm2, xmm2, xmm2;
   // an empty matrix has a zero sum of squares; the row loop below
   // would not terminate for a non positive extent
   test r9, r9;
   jle @@finish;
   test r8, r8;
   jle @@finish;
   @@foryloop:
      mov rax, rcx;
      mov r10, r8;
      @@forxloop:
         cmp r10, 8;
         jl @@lastX;
         vmovups ymm1, [rax];
         vmulps ymm1, ymm1, ymm1;
         vaddps ymm0, ymm0, ymm1;
         add rax, 32;
         sub r10, 8;
         cmp r10, 8;
      jge @@forxloop;
      @@lastX:
      test r10, r10;
      jz @@nextRow;
      @@forxremainder:
         vmovss xmm1, [rax];
         vmulss xmm1, xmm1, xmm1;
         vaddss xmm2, xmm2, xmm1;
         add rax, 4;
      dec r10;
      jnz @@forxremainder;
      @@nextRow:
      add rcx, rdx;
   dec r9;
   jnz @@foryloop;
   vextractf128 xmm1, ymm0, 1;
   vaddps xmm0, xmm0, xmm1;
   vaddps xmm0, xmm0, xmm2;
   @@finish:
   vhaddps xmm0, xmm0, xmm0;
   vhaddps xmm0, xmm0, xmm0;
   // sum of squares only - see AVXMatrixElementwiseNorm2Aligned
   vzeroupper;
end;

// Normalization: dest[y][x] = Src[y][x] / sqrt(sum(x) Src[y][x]^2) - every row
// is scaled by the reciprocal of its 2-norm. AVX has no register form of
// vbroadcastss, so the factor goes through a stack slot.
procedure AVXMatrixNormalizeRowAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = Src, r9 = srcLineWidth
var width, height : NativeInt;
    tmp : single;
asm
   mov width, unixWidth;
   mov height, unixHeight;
   {$IFDEF UNIX}
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov r10, height;
   test r10, r10;
   jle @@done;

   mov rax, width;
   test rax, rax;
   jle @@done;

   @@foryloop:
       vxorps ymm0, ymm0, ymm0;
       vxorps xmm2, xmm2, xmm2;
       xor r11, r11;

       mov rax, width;
       shr rax, 3;
       jz @@tail;

       @@vecloop:
           vmovaps ymm1, [r8 + r11];
           vmulps ymm1, ymm1, ymm1;
           vaddps ymm0, ymm0, ymm1;
           add r11, 32;
           dec rax;
       jnz @@vecloop;

       @@tail:
       mov rax, width;
       and rax, 7;
       jz @@reduce;

       @@tailloop:
           vmovss xmm1, [r8 + r11];
           vmulss xmm1, xmm1, xmm1;
           vaddss xmm2, xmm2, xmm1;
           add r11, 4;
           dec rax;
       jnz @@tailloop;

       @@reduce:
       vextractf128 xmm1, ymm0, 1;
       vaddps xmm0, xmm0, xmm1;
       vaddss xmm0, xmm0, xmm2;
       vhaddps xmm0, xmm0, xmm0;
       vhaddps xmm0, xmm0, xmm0;
       vsqrtss xmm0, xmm0, xmm0;  // the norm
       vxorps xmm5, xmm5, xmm5;
       vucomiss xmm0, xmm5;
       jp @@scaleRow;             // NaN norm: divide, the reference yields NaN
       jne @@scaleRow;

       jmp @@zerorow;

       @@scaleRow:
       vmovss [tmp], xmm0;
       vbroadcastss ymm3, [tmp];

       // scale the row
       xor r11, r11;
       mov rax, width;
       shr rax, 3;
       jz @@tail2;

       @@vecloop2:
           vmovaps ymm1, [r8 + r11];
           vdivps ymm1, ymm1, ymm3;
           vmovaps [rcx + r11], ymm1;
           add r11, 32;
           dec rax;
       jnz @@vecloop2;

       @@tail2:
       mov rax, width;
       and rax, 7;
       jz @@nextline;

       @@tailloop2:
           vmovss xmm1, [r8 + r11];
           vdivss xmm1, xmm1, xmm3;
           vmovss [rcx + r11], xmm1;
           add r11, 4;
           dec rax;
       jnz @@tailloop2;

       jmp @@nextline;

       @@zerorow:
       vxorps ymm2, ymm2, ymm2;
       xor r11, r11;
       mov rax, width;
       shr rax, 3;
       jz @@zerotail;

       @@zeroloop:
           vmovups [rcx + r11], ymm2;
           add r11, 32;
           dec rax;
       jnz @@zeroloop;

       @@zerotail:
       mov rax, width;
       and rax, 7;
       jz @@nextline;

       @@zerotailloop:
           vmovss [rcx + r11], xmm2;
           add r11, 4;
           dec rax;
       jnz @@zerotailloop;

       @@nextline:
       add rcx, rdx;
       add r8, r9;
       dec r10;
   jnz @@foryloop;

   vzeroupper;

   @@done:
end;

procedure AVXMatrixNormalizeRowUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = Src, r9 = srcLineWidth
var width, height : NativeInt;
    tmp : single;
asm
   mov width, unixWidth;
   mov height, unixHeight;
   {$IFDEF UNIX}
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov r10, height;
   test r10, r10;
   jle @@done;

   mov rax, width;
   test rax, rax;
   jle @@done;

   @@foryloop:
       vxorps ymm0, ymm0, ymm0;
       vxorps xmm2, xmm2, xmm2;
       xor r11, r11;

       mov rax, width;
       shr rax, 3;
       jz @@tail;

       @@vecloop:
           vmovups ymm1, [r8 + r11];
           vmulps ymm1, ymm1, ymm1;
           vaddps ymm0, ymm0, ymm1;
           add r11, 32;
           dec rax;
       jnz @@vecloop;

       @@tail:
       mov rax, width;
       and rax, 7;
       jz @@reduce;

       @@tailloop:
           vmovss xmm1, [r8 + r11];
           vmulss xmm1, xmm1, xmm1;
           vaddss xmm2, xmm2, xmm1;
           add r11, 4;
           dec rax;
       jnz @@tailloop;

       @@reduce:
       vextractf128 xmm1, ymm0, 1;
       vaddps xmm0, xmm0, xmm1;
       vaddss xmm0, xmm0, xmm2;
       vhaddps xmm0, xmm0, xmm0;
       vhaddps xmm0, xmm0, xmm0;
       vsqrtss xmm0, xmm0, xmm0;  // the norm
       vxorps xmm5, xmm5, xmm5;
       vucomiss xmm0, xmm5;
       jp @@scaleRow;             // NaN norm: divide, the reference yields NaN
       jne @@scaleRow;

       jmp @@zerorow;

       @@scaleRow:
       vmovss [tmp], xmm0;
       vbroadcastss ymm3, [tmp];

       xor r11, r11;
       mov rax, width;
       shr rax, 3;
       jz @@tail2;

       @@vecloop2:
           vmovups ymm1, [r8 + r11];
           vdivps ymm1, ymm1, ymm3;
           vmovups [rcx + r11], ymm1;
           add r11, 32;
           dec rax;
       jnz @@vecloop2;

       @@tail2:
       mov rax, width;
       and rax, 7;
       jz @@nextline;

       @@tailloop2:
           vmovss xmm1, [r8 + r11];
           vdivss xmm1, xmm1, xmm3;
           vmovss [rcx + r11], xmm1;
           add r11, 4;
           dec rax;
       jnz @@tailloop2;

       jmp @@nextline;

       @@zerorow:
       vxorps ymm2, ymm2, ymm2;
       xor r11, r11;
       mov rax, width;
       shr rax, 3;
       jz @@zerotail;

       @@zeroloop:
           vmovups [rcx + r11], ymm2;
           add r11, 32;
           dec rax;
       jnz @@zeroloop;

       @@zerotail:
       mov rax, width;
       and rax, 7;
       jz @@nextline;

       @@zerotailloop:
           vmovss [rcx + r11], xmm2;
           add r11, 4;
           dec rax;
       jnz @@zerotailloop;

       @@nextline:
       add rcx, rdx;
       add r8, r9;
       dec r10;
   jnz @@foryloop;

   vzeroupper;

   @@done:
end;

// Column normalization: dest[y][x] = Src[y][x] / sqrt(sum(y) Src[y][x]^2).
// Eight columns are handled per block: first the per column sum of squares is
// accumulated while walking the rows, then the block is scaled while walking
// the rows again. Columns below a multiple of eight are handled one by one.
procedure AVXMatrixNormalizeColumnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = Src, r9 = srcLineWidth
var width, height : NativeInt;
    ione : single;
    iRSI, iR12 : NativeInt;
asm
   mov width, unixWidth;
   mov height, unixHeight;
   {$IFDEF UNIX}
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov iRSI, rsi;
   mov iR12, r12;
   mov eax, $3F800000;
   mov ione, eax;
   vbroadcastss ymm4, [ione];

   mov rax, height;
   test rax, rax;
   jle @@done;

   mov rax, width;
   test rax, rax;
   jle @@done;

   xor r11, r11;               // byte offset of the current column block
   mov r10, width;

   @@colblocks:
   cmp r10, 8;
   jl @@colscalar;

       // pass 1: sum of squares per column
       vxorps ymm0, ymm0, ymm0;
       lea rax, [r8 + r11];
       mov rsi, height;

       @@normloop:
           vmovaps ymm1, [rax];
           vmulps ymm1, ymm1, ymm1;
           vaddps ymm0, ymm0, ymm1;
           add rax, r9;
           dec rsi;
       jnz @@normloop;

       // a zero norm normalizes to zero. Those lanes get a 1.0 divisor so the
       // division never runs into a zero denominator - a program that unmasks
       // divide-by-zero would otherwise trap inside the kernel - and ymm5 masks
       // the stored result back to zero, which is what RefNormalize writes.
       vsqrtps ymm0, ymm0;
       vxorps ymm2, ymm2, ymm2;
       vcmpps ymm3, ymm0, ymm2, 0;
       vblendvps ymm0, ymm0, ymm4, ymm3;
       vpcmpeqd ymm2, ymm2, ymm2;
       vxorps ymm5, ymm3, ymm2;

       // pass 2: scale and store
       lea rax, [r8 + r11];
       lea r12, [rcx + r11];
       mov rsi, height;

       @@scaleloop:
           vmovaps ymm1, [rax];
           vdivps ymm1, ymm1, ymm0;
           vandps ymm1, ymm1, ymm5;
           vmovaps [r12], ymm1;
           add rax, r9;
           add r12, rdx;
           dec rsi;
       jnz @@scaleloop;

       add r11, 32;
       sub r10, 8;
   jmp @@colblocks;

   @@colscalar:
   test r10, r10;
   jz @@done;

       @@colloop:
           vxorps xmm0, xmm0, xmm0;
           lea rax, [r8 + r11];
           mov rsi, height;

           @@normloops:
               vmovss xmm1, [rax];
               vmulss xmm1, xmm1, xmm1;
               vaddss xmm0, xmm0, xmm1;
               add rax, r9;
               dec rsi;
           jnz @@normloops;

           vsqrtss xmm0, xmm0, xmm0;
           vxorps xmm1, xmm1, xmm1;
           vucomiss xmm0, xmm1;
           jp @@scalecol;
           jne @@scalecol;
           jmp @@zerocol;

           @@scalecol:

           lea rax, [r8 + r11];
           lea r12, [rcx + r11];
           mov rsi, height;

           @@scaleloops:
               vmovss xmm1, [rax];
               vdivss xmm1, xmm1, xmm0;
               vmovss [r12], xmm1;
               add rax, r9;
               add r12, rdx;
               dec rsi;
           jnz @@scaleloops;
           jmp @@nextcol;

           @@zerocol:
           lea r12, [rcx + r11];
           mov rsi, height;
           vxorps xmm1, xmm1, xmm1;

           @@zerocolloop:
               vmovss [r12], xmm1;
               add r12, rdx;
               dec rsi;
           jnz @@zerocolloop;

           @@nextcol:
           add r11, 4;
           dec r10;
       jnz @@colloop;

   @@done:
   vzeroupper;
   mov rsi, iRSI;
   mov r12, iR12;
end;

procedure AVXMatrixNormalizeColumnUnAligned(dest : PSingle; const destLineWidth : NativeInt; Src : PSingle; const srcLineWidth : NativeInt; unixWidth, unixHeight : NativeInt); assembler;
// rcx = dest, rdx = destLineWidth, r8 = Src, r9 = srcLineWidth
var width, height : NativeInt;
    ione : single;
    iRSI, iR12 : NativeInt;
asm
   mov width, unixWidth;
   mov height, unixHeight;
   {$IFDEF UNIX}
   mov r8, rdx;
   mov r9, rcx;
   mov rcx, rdi;
   mov rdx, rsi;
   {$ENDIF}

   mov iRSI, rsi;
   mov iR12, r12;
   mov eax, $3F800000;
   mov ione, eax;
   vbroadcastss ymm4, [ione];

   mov rax, height;
   test rax, rax;
   jle @@done;

   mov rax, width;
   test rax, rax;
   jle @@done;

   xor r11, r11;
   mov r10, width;

   @@colblocks:
   cmp r10, 8;
   jl @@colscalar;

       vxorps ymm0, ymm0, ymm0;
       lea rax, [r8 + r11];
       mov rsi, height;

       @@normloop:
           vmovups ymm1, [rax];
           vmulps ymm1, ymm1, ymm1;
           vaddps ymm0, ymm0, ymm1;
           add rax, r9;
           dec rsi;
       jnz @@normloop;

       // a zero norm normalizes to zero. Those lanes get a 1.0 divisor so the
       // division never runs into a zero denominator - a program that unmasks
       // divide-by-zero would otherwise trap inside the kernel - and ymm5 masks
       // the stored result back to zero, which is what RefNormalize writes.
       vsqrtps ymm0, ymm0;
       vxorps ymm2, ymm2, ymm2;
       vcmpps ymm3, ymm0, ymm2, 0;
       vblendvps ymm0, ymm0, ymm4, ymm3;
       vpcmpeqd ymm2, ymm2, ymm2;
       vxorps ymm5, ymm3, ymm2;

       lea rax, [r8 + r11];
       lea r12, [rcx + r11];
       mov rsi, height;

       @@scaleloop:
           vmovups ymm1, [rax];
           vdivps ymm1, ymm1, ymm0;
           vandps ymm1, ymm1, ymm5;
           vmovups [r12], ymm1;
           add rax, r9;
           add r12, rdx;
           dec rsi;
       jnz @@scaleloop;

       add r11, 32;
       sub r10, 8;
   jmp @@colblocks;

   @@colscalar:
   test r10, r10;
   jz @@done;

       @@colloop:
           vxorps xmm0, xmm0, xmm0;
           lea rax, [r8 + r11];
           mov rsi, height;

           @@normloops:
               vmovss xmm1, [rax];
               vmulss xmm1, xmm1, xmm1;
               vaddss xmm0, xmm0, xmm1;
               add rax, r9;
               dec rsi;
           jnz @@normloops;

           vsqrtss xmm0, xmm0, xmm0;
           vxorps xmm1, xmm1, xmm1;
           vucomiss xmm0, xmm1;
           jp @@scalecol;
           jne @@scalecol;
           jmp @@zerocol;

           @@scalecol:

           lea rax, [r8 + r11];
           lea r12, [rcx + r11];
           mov rsi, height;

           @@scaleloops:
               vmovss xmm1, [rax];
               vdivss xmm1, xmm1, xmm0;
               vmovss [r12], xmm1;
               add rax, r9;
               add r12, rdx;
               dec rsi;
           jnz @@scaleloops;
           jmp @@nextcol;

           @@zerocol:
           lea r12, [rcx + r11];
           mov rsi, height;
           vxorps xmm1, xmm1, xmm1;

           @@zerocolloop:
               vmovss [r12], xmm1;
               add r12, rdx;
               dec rsi;
           jnz @@zerocolloop;

           @@nextcol:
           add r11, 4;
           dec r10;
       jnz @@colloop;

   @@done:
   vzeroupper;
   mov rsi, iRSI;
   mov r12, iR12;
end;

{$ENDIF}

end.
