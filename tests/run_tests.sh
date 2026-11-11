#!/usr/bin/env bash
# ###########################################################
# #### vsmath - vector single math
# ####
# #### Copyright 2026 Eudox67. All rights reserved.
# #### Licensed under the Apache License, Version 2.0 - see LICENSE.
# ###########################################################
# #### Builds and runs the fpcunit suite in tests/.
# ####
# #### The suite is built with -gh (heaptrc), so a leak shows up as a non-zero
# #### "unfreed memory blocks" line in the runner output.
# ####
# #### Usage:
# ####   tests/run_tests.sh
# ####   FPC=/path/to/ppcx64 FPCUNIT=/path/to/fcl-fpcunit/src tests/run_tests.sh
# ####
# #### Exits non-zero when the build fails or any test fails.
# ###########################################################
set -u

TESTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$TESTS/.." && pwd)"
FPC="${FPC:-fpc}"

if ! command -v "$FPC" >/dev/null 2>&1; then
  echo "fpc not found (set FPC=/path/to/ppcx64)" >&2
  exit 2
fi
FPC="$(command -v "$FPC")"
FPCBIN="$(cd "$(dirname "$FPC")" && pwd)"

# Locate the fcl-fpcunit sources/units: either a source tree (fpcunit.pp plus
# the fpcunit*.pas siblings) or an installed unit directory.
find_fpcunit() {
  local cand p
  for cand in "${FPCUNIT:-}" \
              "$FPCBIN/../../../fpcsrc" \
              "$FPCBIN/../../../.." \
              "$FPCBIN/.."; do
    [ -d "$cand" ] || continue
    p="$(find "$cand" -maxdepth 4 -type d -path '*packages/fcl-fpcunit/src' 2>/dev/null | head -1)"
    if [ -n "$p" ] && [ -f "$p/fpcunit.pp" ]; then echo "$p"; return 0; fi
  done
  local v t
  v="$("$FPC" -iV 2>/dev/null)"
  t="$("$FPC" -iTP 2>/dev/null)-$("$FPC" -iTO 2>/dev/null)"
  for cand in "/usr/lib/fpc/$v/units/$t/fcl-fpcunit" \
              "/usr/lib/$t/fpc/$v/units/$t/fcl-fpcunit" \
              "/usr/local/lib/fpc/$v/units/$t/fcl-fpcunit"; do
    if [ -d "$cand" ]; then echo "$cand"; return 0; fi
  done
  return 1
}

FPCUNITDIR="$(find_fpcunit)" || {
  echo "cannot locate the fcl-fpcunit package" >&2
  echo "install fcl-fpcunit or set FPCUNIT=<dir with fpcunit.pp / fpcunit.ppu>" >&2
  exit 2
}

mkdir -p "$TESTS/bin"
echo "fpc        : $FPC"
echo "fpcunit    : $FPCUNITDIR"

# -FU keeps the .ppu/.o in tests/bin (a source tree that keeps them next to the
# sources shadows an edited unit whenever a clock step makes the artifact look
# newer, and then the suite silently tests the old code), and -B rebuilds every
# unit so the run always reflects the working tree.
if ! "$FPC" -B -Mobjfpc -O1 \
      -Fu"$ROOT/src" -Fi"$ROOT/src" \
      -Fu"$FPCUNITDIR" \
      -FU"$TESTS/bin" -FE"$TESTS/bin" \
      -gh -gl \
      "$TESTS/testrunner.pas"; then
  echo "build failed" >&2
  exit 1
fi

echo "-----------------------------------------------------------"
# heaptrc writes its dump to stderr when the output is a pipe; tee keeps it
# visible and lets the leak count be checked below.
LOG="$TESTS/test_run.log"
set -o pipefail
"$TESTS/bin/testrunner" 2>&1 | tee "$LOG"
rc=${PIPESTATUS[0]}
echo "-----------------------------------------------------------"

leaks="$(grep -oE '^[0-9]+ unfreed memory blocks' "$LOG" | head -1 | cut -d' ' -f1)"
if [ -n "$leaks" ] && [ "$leaks" -ne 0 ]; then
  echo "heaptrc: $leaks unfreed memory blocks" >&2
  rc=1
fi
exit $rc
