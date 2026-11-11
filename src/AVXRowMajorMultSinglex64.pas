// ###########################################################
// #### vsmath - vector single math
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the Apache License, Version 2.0 - see LICENSE.
// ###########################################################
unit AVXRowMajorMultSinglex64;

interface

{$MODE OBJFPC}{$H+}
{$ASMMODE INTEL}

{$I VsMath_CPU.inc}

{$IFDEF CPUX64}
uses MatrixConstSingle;

// Full matrix operations
procedure AVXRowMajorMultAligned(dest: Pointer; const destLineWidth: NativeInt; mt1, mt2: Pointer; width1, height1, width2, height2: NativeInt; const LineWidth1, LineWidth2: NativeInt); assembler;
procedure AVXRowMajorMultUnAligned(dest: Pointer; const destLineWidth: NativeInt; mt1, mt2: Pointer; width1, height1, width2, height2: NativeInt; const LineWidth1, LineWidth2: NativeInt); assembler;

// Special types
procedure AVXRowMajorMtxMultTria2T1(dest : PSingle; LineWidthDest : NativeInt; mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; width1, height1, width2, height2 : NativeInt); assembler;
procedure AVXRowMajorMtxMultTria2Store1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; width1, height1, width2, height2 : NativeInt); assembler;
procedure AVXRowMajorMtxMultTria2TUpperUnit(dest : PSingle; LineWidthDest : NativeInt; mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; width1, height1, width2, height2 : NativeInt); assembler;
procedure AVXRowMajorMtxMultTria2Store1Unit(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; width1, height1, width2, height2 : NativeInt); assembler;
procedure AVXRowMajorMtxMultLowTria2T2Store1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; width1, height1, width2, height2 : NativeInt); assembler;
procedure AVXRowMajorMtxMultTria2T1StoreT1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; width1, height1, width2, height2 : NativeInt); assembler;
procedure AVXRowMajorSymRank2UpdateUpperUnaligned(C : PSingle; LineWidthC : NativeInt; A : PSingle; LineWidthA : NativeInt; B : PSingle; LineWidthB : NativeInt; N : NativeInt; k : NativeInt); assembler;

{$ENDIF}

implementation

{$IFDEF CPUX64}

// Helper macro to save complexity
// NOTE: In FPC assembler blocks with local variables, FPC handles the frame.
// We just need to preserve callee-saved regs: RBX, RSI, RDI, R12-R15.

procedure AVXRowMajorMultAligned(dest: Pointer; const destLineWidth: NativeInt; mt1, mt2: Pointer; width1, height1, width2, height2: NativeInt; const LineWidth1, LineWidth2: NativeInt); assembler;
var
  iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15, iRBP: NativeInt;
asm
  mov iRBX, rbx; mov iRSI, rsi; mov iRDI, rdi;
  mov iR12, r12; mov iR13, r13; mov iR14, r14; mov iR15, r15;
  mov iRBP, rbp;

  // RDI=dest, RSI=destLineWidth, RDX=mt1, RCX=mt2, R8=width1, R9=height1
  mov r10, rdi;   // dest
  mov r11, rdx;   // mt1
  mov r12, rcx;   // mt2
  mov r13, rsi;   // destLineWidth
  
  mov rax, LineWidth1; mov r14, rax;
  mov rax, LineWidth2; mov r15, rax;

  mov rsi, height1; 
  mov rdi, width1;  
  mov rbx, width2;  

  @@foryloop:
    test rsi, rsi;
    jz @@end;

    // Zero Destination Row
    mov rax, r10;    
    mov rcx, rbx;    
    vxorps ymm0, ymm0, ymm0;
    @@zeroDest:
      cmp rcx, 8;
      jl @@zeroScalar;
      vmovaps [rax], ymm0; 
      add rax, 32;
      sub rcx, 8;
      jmp @@zeroDest;
    @@zeroScalar:
      test rcx, rcx;
      jz @@startK;
      vmovss [rax], xmm0;
      add rax, 4;
      dec rcx;
      jmp @@zeroScalar;

    @@startK:
    mov r8, rdi;    
    mov r9, r11;    
    mov rdx, r12;   

    @@forkloop:
      vbroadcastss ymm1, [r9]; 

      mov rcx, rbx;  
      mov rax, r10;  
      
      // Use R11 as temp B-row ptr. PUSH/POP to preserve A-row base.
      push r11;
      mov r11, rdx;  // Current B row ptr

      @@forjloop:
        cmp rcx, 8;
        jl @@lastJ;

        vmovaps ymm2, [r11];
        vmulps ymm2, ymm2, ymm1;
        vaddps ymm0, ymm2, [rax];
        vmovaps [rax], ymm0;

        add rax, 32;
        add r11, 32;
        sub rcx, 8;
        jnz @@forjloop;
        jmp @@nextK;

      @@lastJ:
        test rcx, rcx;
        jz @@nextK;
        vmovss xmm2, [r11];
        vmulss xmm2, xmm2, xmm1;
        vaddss xmm0, xmm2, [rax];
        vmovss [rax], xmm0;
        add rax, 4;
        add r11, 4;
        dec rcx;
        jnz @@lastJ;

    @@nextK:
      pop r11;             // Restore A-row base
      add r9, 4;           
      add rdx, r15;        
      dec r8;
      jnz @@forkloop;

    add r11, r14;          
    add r10, r13;          
    dec rsi;
    jnz @@foryloop;

  @@end:
  mov rbx, iRBX; mov rsi, iRSI; mov rdi, iRDI;
  mov r12, iR12; mov r13, iR13; mov r14, iR14; mov r15, iR15;
  mov rbp, iRBP;
  vzeroupper;
end;

procedure AVXRowMajorMultUnAligned(dest: Pointer; const destLineWidth: NativeInt; mt1, mt2: Pointer; width1, height1, width2, height2: NativeInt; const LineWidth1, LineWidth2: NativeInt); assembler;
var
  iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15, iRBP: NativeInt;
asm
  // 1. Preserve Registers
  mov iRBX, rbx; mov iRSI, rsi; mov iRDI, rdi;
  mov iR12, r12; mov iR13, r13; mov iR14, r14; mov iR15, r15;
  mov iRBP, rbp;

  // 2. Capture parameters from Linux x64 ABI registers
  // RDI=dest, RSI=destLineWidth, RDX=mt1, RCX=mt2, R8=width1, R9=height1
  mov r10, rdi;   // dest
  mov r11, rdx;   // mt1
  mov r12, rcx;   // mt2
  mov r13, rsi;   // destLineWidth
  
  // Stack parameters (FPC managed names)
  mov rax, LineWidth1;
  mov r14, rax;
  mov rax, LineWidth2;
  mov r15, rax;

  mov rsi, height1; 
  mov rdi, width1;  
  mov rbx, width2;  

  @@foryloop:
    test rsi, rsi;
    jz @@end;

    // Zero Destination Row
    mov rax, r10;    
    mov rcx, rbx;    
    vxorps ymm0, ymm0, ymm0;
    @@zeroDest:
      cmp rcx, 8;
      jl @@zeroScalar;
      vmovups [rax], ymm0; 
      add rax, 32;
      sub rcx, 8;
      jmp @@zeroDest;
    @@zeroScalar:
      test rcx, rcx;
      jz @@startK;
      vmovss [rax], xmm0;
      add rax, 4;
      dec rcx;
      jmp @@zeroScalar;

    @@startK:
    mov r8, rdi;    // K-counter
    mov r9, r11;    // Current A row ptr
    mov rdx, r12;   // Current B base ptr

    @@forkloop:
      vbroadcastss ymm1, [r9]; 

      mov rcx, rbx;  // J-counter
      mov rax, r10;  // Current Dest row ptr
      
      // Use R11 as temp B-row ptr. PUSH/POP to preserve A-row base.
      push r11;
      mov r11, rdx;  // Current B row ptr

      @@forjloop:
        cmp rcx, 8;
        jl @@lastJ;

        vmovups ymm2, [r11];
        vmulps ymm2, ymm2, ymm1;
        vmovups ymm0, [rax];
        vaddps ymm0, ymm0, ymm2;
        vmovups [rax], ymm0;

        add rax, 32;
        add r11, 32;
        sub rcx, 8;
        jnz @@forjloop;
        jmp @@nextK;

      @@lastJ:
        test rcx, rcx;
        jz @@nextK;
        vmovss xmm2, [r11];
        vmulss xmm2, xmm2, xmm1;
        vaddss xmm0, xmm2, [rax];
        vmovss [rax], xmm0;
        add rax, 4;
        add r11, 4;
        dec rcx;
        jnz @@lastJ;

    @@nextK:
      pop r11;             // Restore A-row base
      add r9, 4;           
      add rdx, r15;        // LineWidth2
      dec r8;
      jnz @@forkloop;

    add r11, r14;          // LineWidth1
    add r10, r13;          // destLineWidth
    dec rsi;
    jnz @@foryloop;

  @@end:
  mov rbx, iRBX; mov rsi, iRSI; mov rdi, iRDI;
  mov r12, iR12; mov r13, iR13; mov r14, iR14; mov r15, iR15;
  mov rbp, iRBP;
  vzeroupper;
end;

procedure AVXRowMajorMtxMultTria2T1(dest : PSingle; LineWidthDest : NativeInt; mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; width1, height1, width2, height2 : NativeInt); assembler;
var
  iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
asm
  mov iRBX, rbx; mov iRSI, rsi; mov iRDI, rdi;
  mov iR12, r12; mov iR13, r13; mov iR14, r14; mov iR15, r15;

  mov rsi, width1;   // In T1, width1 is the outer loop
  mov rdi, height1;  // Inner K count
  mov r12, width2;   // J count

  @@foryloop:
    test rsi, rsi;
    jz @@end;

    mov r14, dest;
    mov rax, r12;
    @@zeroDest:
      vxorps ymm0, ymm0, ymm0;
      cmp rax, 8;
      jl @@zeroScalar;
      vmovups [r14], ymm0;
      add r14, 32;
      sub rax, 8;
      jmp @@zeroDest;
    @@zeroScalar:
      test rax, rax;
      jz @@startK;
      vmovss [r14], xmm0;
      add r14, 4;
      dec rax;
      jmp @@zeroScalar;

    @@startK:
    mov r10, mt1;
    mov r11, mt2;
    mov r13, rdi;

    @@forkloop:
      vbroadcastss ymm1, [r10]; // Row-Major T1 access is actually strided?
      // Logic check: if mt1 is Transposed, A[i,k] is actually A_orig[k, i].
      // In row major, A_orig[k, i] is at (k * LW1 + i).
      // Here mt1 is moving by columns.

      mov rax, r12;
      mov r14, dest;
      mov r15, r11;

      @@forjloop:
        cmp rax, 8;
        jl @@lastJ;
        vmovups ymm2, [r15];
        vmulps ymm2, ymm2, ymm1;
        vaddps ymm0, ymm2, [r14];
        vmovups [r14], ymm0;
        add r14, 32;
        add r15, 32;
        sub rax, 8;
        jnz @@forjloop;
        jmp @@nextK;

      @@lastJ:
        test rax, rax;
        jz @@nextK;
        vmovss xmm2, [r15];
        vmulss xmm2, xmm2, xmm1;
        vaddss xmm0, xmm2, [r14];
        vmovss [r14], xmm0;
        add r14, 4;
        add r15, 4;
        dec rax;
        jnz @@lastJ;

    @@nextK:
      add r10, LineWidth1; // Move down a row (which is next column element in RowMajor)
      add r11, LineWidth2;
      dec r13;
      jnz @@forkloop;

    add mt1, 4;            // Next Column of Orig A
    add dest, LineWidthDest;
    dec rsi;
    jnz @@foryloop;

  @@end:
  mov rbx, iRBX; mov rsi, iRSI; mov rdi, iRDI;
  mov r12, iR12; mov r13, iR13; mov r14, iR14; mov r15, iR15;
  vzeroupper;
end;

procedure AVXRowMajorMtxMultTria2Store1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; width1, height1, width2, height2 : NativeInt); assembler;
var
  iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
  pTmpRow : PSingle;
asm
  mov iRBX, rbx; mov iRSI, rsi; mov iRDI, rdi;
  mov iR12, r12; mov iR13, r13; mov iR14, r14; mov iR15, r15;

  mov rsi, height1;
  mov rdi, width1;
  mov r12, width2;

  @@foryloop:
    mov rax, r12;
    shl rax, 2;
    add rax, 15;      // Align allocation
    and rax, -16;     // Ensure 16-byte alignment
    sub rsp, rax;
    mov pTmpRow, rsp;

    mov r14, rsp;
    mov rax, r12;
    vxorps ymm0, ymm0, ymm0;
    @@zeroTmp:
      cmp rax, 8;
      jl @@zeroScalar;
      vmovups [r14], ymm0;
      add r14, 32;
      sub rax, 8;
      jmp @@zeroTmp;
    @@zeroScalar:
      test rax, rax;
      jz @@startK;
      vmovss [r14], xmm0;
      add r14, 4;
      dec rax;
      jmp @@zeroScalar;

    @@startK:
    mov r10, mt1;
    mov r11, mt2;
    mov r13, rdi;

    @@forkloop:
      vbroadcastss ymm1, [r10];
      mov rax, r12;
      mov r14, pTmpRow;
      mov r15, r11;

      @@forjloop:
        cmp rax, 8;
        jl @@lastJ;
        vmovups ymm2, [r15];
        vmulps ymm2, ymm2, ymm1;
        vaddps ymm0, ymm2, [r14];
        vmovups [r14], ymm0;
        add r14, 32;
        add r15, 32;
        sub rax, 8;
        jnz @@forjloop;
        jmp @@nextK;
      @@lastJ:
        test rax, rax;
        jz @@nextK;
        vmovss xmm2, [r15];
        vmulss xmm2, xmm2, xmm1;
        vaddss xmm0, xmm2, [r14];
        vmovss [r14], xmm0;
        add r14, 4;
        add r15, 4;
        dec rax;
        jnz @@lastJ;

    @@nextK:
      add r10, 4;
      add r11, LineWidth2;
      dec r13;
      jnz @@forkloop;

    // Copy Back
    mov r14, pTmpRow;
    mov r15, mt1;
    mov rax, r12;
    @@copyBack:
      cmp rax, 8;
      jl @@copyScalar;
      vmovups ymm0, [r14];
      vmovups [r15], ymm0;
      add r14, 32;
      add r15, 32;
      sub rax, 8;
      jmp @@copyBack;
    @@copyScalar:
      test rax, rax;
      jz @@rowDone;
      vmovss xmm0, [r14];
      vmovss [r15], xmm0;
      add r14, 4;
      add r15, 4;
      dec rax;
      jmp @@copyScalar;

    @@rowDone:
    // Safe stack restore
    mov rsp, pTmpRow; // We can't rely on ADD because we aligned. Move RSP back to known state.
    // Actually, we must restore to frame. FPC frame is RBP.
    // Just reversing the sub is cleaner if we know size.
    mov rax, r12;
    shl rax, 2;
    add rax, 15;
    and rax, -16;
    add rsp, rax;

    add mt1, LineWidth1;
    dec rsi;
    jnz @@foryloop;

  @@end:
  mov rbx, iRBX; mov rsi, iRSI; mov rdi, iRDI;
  mov r12, iR12; mov r13, iR13; mov r14, iR14; mov r15, iR15;
  vzeroupper;
end;

procedure AVXRowMajorMtxMultTria2TUpperUnit(dest : PSingle; LineWidthDest : NativeInt; mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; width1, height1, width2, height2 : NativeInt); assembler;
var
  iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
asm
  mov iRBX, rbx; mov iRSI, rsi; mov iRDI, rdi;
  mov iR12, r12; mov iR13, r13; mov iR14, r14; mov iR15, r15;

  mov rsi, height1;
  mov rdi, 0;

  @@foryloop:
    test rsi, rsi;
    jz @@end;

    // B_row_start = mt2 + i * LineWidth2
    mov rax, rdi;
    imul rax, LineWidth2;
    add rax, mt2;

    mov r14, dest;
    mov r12, width2;

    @@copyB:
      cmp r12, 8;
      jl @@copyScalar;
      vmovups ymm0, [rax];
      vmovups [r14], ymm0;
      add rax, 32;
      add r14, 32;
      sub r12, 8;
      jmp @@copyB;
    @@copyScalar:
      test r12, r12;
      jz @@startK;
      vmovss xmm0, [rax];
      vmovss [r14], xmm0;
      add rax, 4;
      add r14, 4;
      dec r12;
      jmp @@copyScalar;

    @@startK:
    mov r13, rdi;
    inc r13; // k = i + 1
    cmp r13, width1;
    jge @@nextRow;

    // MT1 (A) ptr = mt1 + (i*LineWidth1) + k*4
    // Actually mt1 is updated per row in outer loop? No, mt1 passed as base.
    // Wait, previous func updated mt1. This one: `mt1` is var param? No.
    // We should use `mt1` as base.
    mov r10, mt1;
    // But mt1 needs to move down rows. Let's just update `mt1` at end of loop.
    // Address A[i, k] -> mt1 + (k*4)
    mov rax, r13;
    shl rax, 2;
    add r10, rax;

    // MT2 (B) ptr = mt2 + k*LineWidth2
    mov r11, mt2;
    mov rax, r13;
    imul rax, LineWidth2;
    add r11, rax;

    @@forkloop:
      vbroadcastss ymm1, [r10];

      mov rax, width2;
      mov r14, dest;
      mov r15, r11;

      @@forjloop:
        cmp rax, 8;
        jl @@lastJ;
        vmovups ymm2, [r15];
        vmulps ymm2, ymm2, ymm1;
        vmovups ymm0, [r14];
        vaddps ymm0, ymm0, ymm2;
        vmovups [r14], ymm0;
        add r14, 32;
        add r15, 32;
        sub rax, 8;
        jnz @@forjloop;
        jmp @@nextK;
      @@lastJ:
        test rax, rax;
        jz @@nextK;
        vmovss xmm2, [r15];
        vmulss xmm2, xmm2, xmm1;
        vmovss xmm0, [r14];
        vaddss xmm0, xmm0, xmm2;
        vmovss [r14], xmm0;
        add r14, 4;
        add r15, 4;
        dec rax;
        jnz @@lastJ;

    @@nextK:
      add r10, 4;
      add r11, LineWidth2;
      inc r13;
      cmp r13, width1;
      jl @@forkloop;

    @@nextRow:
    add mt1, LineWidth1;
    add dest, LineWidthDest;
    inc rdi;
    dec rsi;
    jnz @@foryloop;

  @@end:
  mov rbx, iRBX; mov rsi, iRSI; mov rdi, iRDI;
  mov r12, iR12; mov r13, iR13; mov r14, iR14; mov r15, iR15;
  vzeroupper;
end;

procedure AVXRowMajorMtxMultTria2Store1Unit(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; width1, height1, width2, height2 : NativeInt); assembler;
var
  iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
  pTmpRow : PSingle;
asm
  mov iRBX, rbx; mov iRSI, rsi; mov iRDI, rdi;
  mov iR12, r12; mov iR13, r13; mov iR14, r14; mov iR15, r15;

  mov rsi, height1;
  mov rdi, 0;

  @@foryloop:
    mov rax, width2;
    shl rax, 2;
    add rax, 15;
    and rax, -16;
    sub rsp, rax;
    mov pTmpRow, rsp;

    mov rax, rdi;
    imul rax, LineWidth2;
    add rax, mt2;

    mov r14, pTmpRow;
    mov r12, width2;
    @@initTemp:
      cmp r12, 8;
      jl @@initScalar;
      vmovups ymm0, [rax];
      vmovups [r14], ymm0;
      add rax, 32;
      add r14, 32;
      sub r12, 8;
      jmp @@initTemp;
    @@initScalar:
      test r12, r12;
      jz @@startK;
      vmovss xmm0, [rax];
      vmovss [r14], xmm0;
      add rax, 4;
      add r14, 4;
      dec r12;
      jmp @@initScalar;

    @@startK:
    mov r10, mt1;
    mov r11, mt2;
    mov r13, width1;
    xor rbx, rbx;

    @@forkloop:
      cmp rbx, rdi;
      je @@skipK;

      vbroadcastss ymm1, [r10];

      mov rax, width2;
      mov r14, pTmpRow;
      mov r15, r11;

      @@forjloop:
        cmp rax, 8;
        jl @@lastJ;
        vmovups ymm2, [r15];
        vmulps ymm2, ymm2, ymm1;
        vmovups ymm0, [r14];
        vaddps ymm0, ymm0, ymm2;
        vmovups [r14], ymm0;
        add r14, 32;
        add r15, 32;
        sub rax, 8;
        jnz @@forjloop;
        jmp @@skipK;

      @@lastJ:
        test rax, rax;
        jz @@skipK;
        vmovss xmm2, [r15];
        vmulss xmm2, xmm2, xmm1;
        vmovss xmm0, [r14];
        vaddss xmm0, xmm0, xmm2;
        vmovss [r14], xmm0;
        add r14, 4;
        add r15, 4;
        dec rax;
        jnz @@lastJ;

    @@skipK:
      add r10, 4;
      add r11, LineWidth2;
      inc rbx;
      dec r13;
      jnz @@forkloop;

    mov r14, pTmpRow;
    mov r15, mt1;
    mov rax, width2;
    @@copyBack:
      cmp rax, 8;
      jl @@copyBackScalar;
      vmovups ymm0, [r14];
      vmovups [r15], ymm0;
      add r14, 32;
      add r15, 32;
      sub rax, 8;
      jmp @@copyBack;
    @@copyBackScalar:
      test rax, rax;
      jz @@rowDone;
      vmovss xmm0, [r14];
      vmovss [r15], xmm0;
      add r14, 4;
      add r15, 4;
      dec rax;
      jmp @@copyBackScalar;

    @@rowDone:
    mov rax, width2;
    shl rax, 2;
    add rax, 15;
    and rax, -16;
    add rsp, rax;

    add mt1, LineWidth1;
    inc rdi;
    dec rsi;
    jnz @@foryloop;

  @@end:
  mov rbx, iRBX; mov rsi, iRSI; mov rdi, iRDI;
  mov r12, iR12; mov r13, iR13; mov r14, iR14; mov r15, iR15;
  vzeroupper;
end;

procedure AVXRowMajorMtxMultLowTria2T2Store1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; width1, height1, width2, height2 : NativeInt); assembler;
var
  iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
  pTmpRow : PSingle;
asm
  mov iRBX, rbx; mov iRSI, rsi; mov iRDI, rdi;
  mov iR12, r12; mov iR13, r13; mov iR14, r14; mov iR15, r15;

  mov rsi, height1;
  mov rdi, mt1;

  @@foryloop:
    mov rax, width2;
    shl rax, 2;
    add rax, 15;
    and rax, -16;
    sub rsp, rax;
    mov pTmpRow, rsp;

    mov r12, height2;
    mov r13, mt2;
    mov r14, pTmpRow;

    @@forjloop:
      vxorps ymm0, ymm0, ymm0;
      vxorps ymm1, ymm1, ymm1;
      vxorps ymm2, ymm2, ymm2;
      vxorps ymm3, ymm3, ymm3;

      mov rax, width1;
      mov r8, rdi;
      mov r9, r13;

      // UNROLLED DOT PRODUCT (4x) for Latency Hiding
      @@dotLoop:
        cmp rax, 32;
        jl @@dotSingle;

        vmovups ymm4, [r8];
        vmulps ymm4, ymm4, [r9];
        vaddps ymm0, ymm0, ymm4;

        vmovups ymm4, [r8+32];
        vmulps ymm4, ymm4, [r9+32];
        vaddps ymm1, ymm1, ymm4;

        vmovups ymm4, [r8+64];
        vmulps ymm4, ymm4, [r9+64];
        vaddps ymm2, ymm2, ymm4;

        vmovups ymm4, [r8+96];
        vmulps ymm4, ymm4, [r9+96];
        vaddps ymm3, ymm3, ymm4;

        add r8, 128;
        add r9, 128;
        sub rax, 32;
        jmp @@dotLoop;

      @@dotSingle:
        cmp rax, 8;
        jl @@dotScalar;
        vmovups ymm4, [r8];
        vmulps ymm4, ymm4, [r9];
        vaddps ymm0, ymm0, ymm4;
        add r8, 32;
        add r9, 32;
        sub rax, 8;
        jmp @@dotSingle;

      @@dotScalar:
        test rax, rax;
        jz @@dotFinish;
        vmovss xmm4, [r8];
        vmulss xmm4, xmm4, [r9];
        vaddss xmm0, xmm0, xmm4;
        add r8, 4;
        add r9, 4;
        dec rax;
        jmp @@dotScalar;

      @@dotFinish:
      // Reduce 4 accumulators
      vaddps ymm0, ymm0, ymm1;
      vaddps ymm2, ymm2, ymm3;
      vaddps ymm0, ymm0, ymm2;

      vhaddps ymm0, ymm0, ymm0;
      vhaddps ymm0, ymm0, ymm0;
      vextractf128 xmm1, ymm0, 1;
      vaddss xmm0, xmm0, xmm1;

      vmovss [r14], xmm0;
      add r14, 4;

      add r13, LineWidth2;
      dec r12;
      jnz @@forjloop;

    mov r14, pTmpRow;
    mov r15, rdi;
    mov rax, width2;

    @@copyBack:
      cmp rax, 8;
      jl @@copyScalar;
      vmovups ymm0, [r14];
      vmovups [r15], ymm0;
      add r14, 32;
      add r15, 32;
      sub rax, 8;
      jmp @@copyBack;
    @@copyScalar:
      test rax, rax;
      jz @@rowDone;
      vmovss xmm0, [r14];
      vmovss [r15], xmm0;
      add r14, 4;
      add r15, 4;
      dec rax;
      jmp @@copyScalar;

    @@rowDone:
    mov rax, width2;
    shl rax, 2;
    add rax, 15;
    and rax, -16;
    add rsp, rax;

    add rdi, LineWidth1;
    dec rsi;
    jnz @@foryloop;

  mov rbx, iRBX; mov rsi, iRSI; mov rdi, iRDI;
  mov r12, iR12; mov r13, iR13; mov r14, iR14; mov r15, iR15;
  vzeroupper;
end;

procedure AVXRowMajorMtxMultTria2T1StoreT1(mt1 : PSingle; LineWidth1 : NativeInt; mt2 : PSingle; LineWidth2 : NativeInt; width1, height1, width2, height2 : NativeInt); assembler;
var
  iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
  pTmpRow : PSingle;
asm
  mov iRBX, rbx; mov iRSI, rsi; mov iRDI, rdi;
  mov iR12, r12; mov iR13, r13; mov iR14, r14; mov iR15, r15;

  mov rsi, width1;
  mov rdi, 0;

  @@foryloop:
    mov rax, width2;
    shl rax, 2;
    add rax, 15;
    and rax, -16;
    sub rsp, rax;
    mov pTmpRow, rsp;

    mov r14, pTmpRow;
    mov r8, width2;
    vxorps ymm0, ymm0, ymm0;
    @@zeroLoop:
       cmp r8, 8;
       jl @@zeroFin;
       vmovups [r14], ymm0;
       add r14, 32;
       sub r8, 8;
       jmp @@zeroLoop;
    @@zeroFin:
       test r8, r8;
       jz @@startK;
       vmovss [r14], xmm0;
       add r14, 4;
       dec r8;
       jmp @@zeroFin;

    @@startK:
    mov r12, height1;
    mov r13, mt1;

    mov rax, rdi;
    shl rax, 2;
    add r13, rax;

    mov r15, mt2;

    @@forkloop:
      vbroadcastss ymm1, [r13];

      mov rax, width2;
      mov r14, pTmpRow;
      mov r8, r15;

      @@forjloop:
        cmp rax, 8;
        jl @@lastJ;
        vmovups ymm2, [r8];
        vmulps ymm2, ymm2, ymm1;
        vmovups ymm0, [r14];
        vaddps ymm0, ymm0, ymm2;
        vmovups [r14], ymm0;
        add r14, 32;
        add r8, 32;
        sub rax, 8;
        jnz @@forjloop;

      @@lastJ:
        test rax, rax;
        jz @@nextK;
        vmovss xmm2, [r8];
        vmulss xmm2, xmm2, xmm1;
        vmovss xmm0, [r14];
        vaddss xmm0, xmm0, xmm2;
        vmovss [r14], xmm0;
        add r14, 4;
        add r8, 4;
        dec rax;
        jnz @@lastJ;

    @@nextK:
      add r13, LineWidth1;
      add r15, LineWidth2;
      dec r12;
      jnz @@forkloop;

    mov r15, mt1;
    mov rax, rdi;
    imul rax, LineWidth1;
    add r15, rax;

    mov r14, pTmpRow;
    mov rax, width2;
    @@copyBack:
      cmp rax, 8;
      jl @@copyScalar;
      vmovups ymm0, [r14];
      vmovups [r15], ymm0;
      add r14, 32;
      add r15, 32;
      sub rax, 8;
      jmp @@copyBack;
    @@copyScalar:
      test rax, rax;
      jz @@rowDone;
      vmovss xmm0, [r14];
      vmovss [r15], xmm0;
      add r14, 4;
      add r15, 4;
      dec rax;
      jmp @@copyScalar;

    @@rowDone:
    mov rax, width2;
    shl rax, 2;
    add rax, 15;
    and rax, -16;
    add rsp, rax;

    inc rdi;
    dec rsi;
    jnz @@foryloop;

  mov rbx, iRBX; mov rsi, iRSI; mov rdi, iRDI;
  mov r12, iR12; mov r13, iR13; mov r14, iR14; mov r15, iR15;
  vzeroupper;
end;

procedure AVXRowMajorSymRank2UpdateUpperUnaligned(C : PSingle; LineWidthC : NativeInt; A : PSingle; LineWidthA : NativeInt; B : PSingle; LineWidthB : NativeInt; N : NativeInt; k : NativeInt); assembler;
var
  iRBX, iRSI, iRDI, iR12, iR13, iR14, iR15 : NativeInt;
asm
  mov iRBX, rbx; mov iRSI, rsi; mov iRDI, rdi;
  mov iR12, r12; mov iR13, r13; mov iR14, r14; mov iR15, r15;

  mov rsi, N;
  mov rdi, 0;

  @@loopI:
    mov r12, N;
    sub r12, rdi;
    jz @@done;

    mov r10, A;
    mov rax, rdi;
    imul rax, LineWidthA;
    add r10, rax;

    mov r11, B;
    mov rax, rdi;
    imul rax, LineWidthB;
    add r11, rax;

    mov r14, C;
    mov rax, rdi;
    imul rax, LineWidthC;
    add r14, rax;
    mov rax, rdi;
    shl rax, 2;
    add r14, rax;

    mov r13, rdi;

    @@loopJ:
      mov r8, A;
      mov rax, r13;
      imul rax, LineWidthA;
      add r8, rax;

      mov r9, B;
      mov rax, r13;
      imul rax, LineWidthB;
      add r9, rax;

      mov r15, k; // ACCESS PARAM BY NAME! Safe and Clean.

      vxorps ymm0, ymm0, ymm0;
      vxorps ymm5, ymm5, ymm5;

      // Additional accumulators for loop unrolling
      vxorps ymm1, ymm1, ymm1;
      vxorps ymm2, ymm2, ymm2;

      mov rax, r10;
      mov rbx, r11;
      mov rcx, r8;
      mov rdx, r9;

      @@dotLoop:
        cmp r15, 16;
        jl @@dotSingle;

        // UNROLLING
        // Term 1: A[i] * B[j]
        vmovups ymm3, [rax];
        vmulps ymm3, ymm3, [rdx];
        vaddps ymm0, ymm0, ymm3;

        vmovups ymm3, [rax+32];
        vmulps ymm3, ymm3, [rdx+32];
        vaddps ymm1, ymm1, ymm3;

        // Term 2: B[i] * A[j]
        vmovups ymm4, [rbx];
        vmulps ymm4, ymm4, [rcx];
        vaddps ymm5, ymm5, ymm4;

        vmovups ymm4, [rbx+32];
        vmulps ymm4, ymm4, [rcx+32];
        vaddps ymm2, ymm2, ymm4;

        add rax, 64; add rdx, 64;
        add rbx, 64; add rcx, 64;
        sub r15, 16;
        jmp @@dotLoop;

      @@dotSingle:
        cmp r15, 8;
        jl @@dotScalar;

        vmovups ymm3, [rax];
        vmulps ymm3, ymm3, [rdx];
        vaddps ymm0, ymm0, ymm3;

        vmovups ymm4, [rbx];
        vmulps ymm4, ymm4, [rcx];
        vaddps ymm5, ymm5, ymm4;

        add rax, 32; add rdx, 32;
        add rbx, 32; add rcx, 32;
        sub r15, 8;
        jmp @@dotSingle;

      @@dotScalar:
        test r15, r15;
        jz @@dotCombine;

        vmovss xmm3, [rax];
        vmulss xmm3, xmm3, [rdx];
        vaddss xmm0, xmm0, xmm3;

        vmovss xmm4, [rbx];
        vmulss xmm4, xmm4, [rcx];
        vaddss xmm5, xmm5, xmm4;

        add rax, 4; add rdx, 4;
        add rbx, 4; add rcx, 4;
        dec r15;
        jmp @@dotScalar;

      @@dotCombine:
      // Merge unrolled accumulators
      vaddps ymm0, ymm0, ymm1;
      vaddps ymm5, ymm5, ymm2;

      vaddps ymm0, ymm0, ymm5;
      vhaddps ymm0, ymm0, ymm0;
      vhaddps ymm0, ymm0, ymm0;
      vextractf128 xmm1, ymm0, 1;
      vaddss xmm0, xmm0, xmm1;

      vmovss xmm1, [r14];
      vaddss xmm0, xmm0, xmm1;
      vmovss [r14], xmm0;

      add r14, 4;
      inc r13;
      dec r12;
      jnz @@loopJ;

    inc rdi;
    dec rsi;
    jnz @@loopI;

  @@done:
  mov rbx, iRBX; mov rsi, iRSI; mov rdi, iRDI;
  mov r12, iR12; mov r13, iR13; mov r14, iR14; mov r15, iR15;
  vzeroupper;
end;

{$ENDIF}

end.
