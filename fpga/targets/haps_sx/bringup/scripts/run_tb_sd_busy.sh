#!/bin/bash
# run_tb_sd_busy.sh <sdio-controller rtl directory> [label]
# Unit bench for the card-busy detection of sdfrontend after a written block (MBT-72, MBT-73, MBT-75).
# Compiles tb_sd_busy.v with sdckgen.v and sdfrontend.v of the given directory (VCS), once per case, and prints the
# RESULT lines. Run it on a checkout of 2f8d794 and of 1e02358 to see the fault and the fix
# (expected output: tb_sd_busy_20261125.log).
[ $# -ge 1 ] || { sed -n 2,6p "$0"; exit 1; }
rtl=$(cd "$1" && pwd); label=${2:-run}
tb=$(cd "$(dirname "$0")" && pwd)/tb_sd_busy.v
run() {   # <clock divider> <card busy in us> <token: 1 accepted, 2 CRC error, 0 none> <mode: 0 data block, 1 R1b command>
  d=work_${label}_$1_$2_$3_$4; mkdir -p "$d"
  ( cd "$d" && vcs -full64 -sverilog -q -nc +define+SDFRONTEND_SPLIT_TRISTATE \
        -pvalue+tb_busy.CKSPD=$1 -pvalue+tb_busy.BUSY_US=$2 -pvalue+tb_busy.TOKEN=$3 -pvalue+tb_busy.MODE=$4 \
        "$tb" "$rtl/sdckgen.v" "$rtl/sdfrontend.v" -o simv > compile.log 2>&1 && ./simv -q > run.log 2>&1
    grep -h -A1 "RESULT" run.log || tail -5 compile.log ) | sed "s/^/[$label] /"
}
run 3 230 1 0; run 3 3000 1 0; run 16 230 1 0; run 32 230 1 0; run 65 230 1 0
run 3 230 2 0; run 3 230 0 0; run 3 500 1 1; run 32 500 1 1
