#!/bin/bash
# HAPS UART capture: one reader per port, correct line settings, timestamped files.
# Usage: [MAP=42] haps_capture.sh <seconds> [logger_dev] [console_dev]   (MAP selects the logger bus map; default 44)
#   e.g. haps_capture.sh 90 /dev/ttyUSB0 /dev/ttyUSB1
# Capture dir: ~/haps_captures/<date>_<time>/
set -u
SECS=${1:-90}
LOGGER=${2:-/dev/ttyUSB0}
CONSOLE=${3:-/dev/ttyACM0}
OUT=~/haps_captures/$(date +%Y%m%d_%H%M%S)
mkdir -p "$OUT"

# 1. Refuse to run if anything else already has a serial port open (bug N4).
for d in /dev/ttyUSB* /dev/ttyACM*; do
    [ -e "$d" ] || continue
    if fuser "$d" >/dev/null 2>&1; then
        echo "ERROR: $d is already open by PID(s): $(fuser "$d" 2>/dev/null). Kill them first:"
        echo "       kill $(fuser "$d" 2>/dev/null)"
        exit 1
    fi
done
for d in "$LOGGER" "$CONSOLE"; do
    [ -r "$d" ] || { echo "ERROR: $d missing or not readable (is the cable in? are you in group dialout?)"; exit 1; }
done

# 2. 115200 8N1, raw, no flow control, no echo - on both ports.
for d in "$LOGGER" "$CONSOLE"; do
    stty -F "$d" 115200 cs8 -cstopb -parenb raw -echo -echoe -echok -ixon -ixoff -crtscts
done

# 3. Exactly one reader per port, for a fixed time.
echo "Capturing $SECS s -> $OUT  (logger=$LOGGER console=$CONSOLE)"
timeout "$SECS" cat "$LOGGER"  > "$OUT/logger.log"  &
P1=$!
timeout "$SECS" cat "$CONSOLE" > "$OUT/console.log" &
P2=$!
wait $P1 $P2

echo "logger : $(wc -l < "$OUT/logger.log") lines, $(wc -c < "$OUT/logger.log") bytes"
echo "console: $(wc -l < "$OUT/console.log") lines, $(wc -c < "$OUT/console.log") bytes"
echo "--- console (printable only, first 20 lines):"
tr -cd '\11\12\15\40-\176' < "$OUT/console.log" | head -20
echo "--- logger summary:"
python3 ~/script/haps_parse_logger.py --map "${MAP:-44}" "$OUT/logger.log"   # MAP=42 for build 41/42 bitstreams
