#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 4: Measure Baseline Network Latency (200 probes)
# Matches the PDF: ping -c 200 -i 0.2 <ip> | sed -n 's/.*time[=<]\([0-9.]*\) ms.*/\1/p'
# ==============================================================================

set -euo pipefail

TARGET_IP="${1:-192.168.1.10}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_CSV="$SCRIPT_DIR/baseline_rtt_ms.csv"

echo "[*] Measuring baseline network latency to $TARGET_IP (200 probes at 0.2s intervals)..."

if ip netns list | grep -q "client"; then
    echo "[*] Executing inside 'client' namespace..."
    sudo ip netns exec client ping -c 200 -i 0.2 "$TARGET_IP" | sed -n 's/.*time[=<]\([0-9.]*\) ms.*/\1/p' > "$OUTPUT_CSV"
else
    echo "[*] Executing on host interface..."
    ping -c 200 -i 0.2 "$TARGET_IP" | sed -n 's/.*time[=<]\([0-9.]*\) ms.*/\1/p' > "$OUTPUT_CSV"
fi

TOTAL_SAMPLES=$(wc -l < "$OUTPUT_CSV")
echo "[+] Baseline measurement complete! Collected $TOTAL_SAMPLES samples into $OUTPUT_CSV"
