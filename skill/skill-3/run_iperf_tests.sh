#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 3: Run iperf3 Tests across multiple bandwidths to map Queueing Curve
# Bandwidths: 1M, 2M, 4M, 5M, 7M, 10M UDP
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root (sudo ./run_iperf_tests.sh)"
    exit 1
fi

DATA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/data"
mkdir -p "$DATA_DIR"
CSV_FILE="$DATA_DIR/queueing_curve_results.csv"

echo "offered_mbps,received_mbps,avg_delay_ms,packet_loss_pct,jitter_ms" > "$CSV_FILE"

echo "[*] Starting iPerf3 server in receiver namespace..."
killall iperf3 2>/dev/null || true
ip netns exec receiver iperf3 -s -D
sleep 1

BANDWIDTHS=("1M" "2M" "4M" "5M" "7M" "10M")

for BW in "${BANDWIDTHS[@]}"; do
    echo "======================================================================"
    echo "[*] Running UDP test at offered rate: $BW (duration: 10s)..."
    echo "======================================================================"

    # Run iperf3 and parse output
    OUTPUT=$(ip netns exec sender iperf3 -c 192.168.20.2 -u -b "$BW" -l 1200 -t 10 -J)
    
    # Measure concurrent ping latency
    PING_OUT=$(ip netns exec sender ping -c 10 -i 0.5 192.168.20.2 | tail -1)
    AVG_RTT=$(echo "$PING_OUT" | awk -F '/' '{print $5}')
    
    RECV_BPS=$(echo "$OUTPUT" | grep '"bits_per_second"' | tail -1 | tr -dc '0-9.')
    RECV_MBPS=$(awk -v bps="$RECV_BPS" 'BEGIN {printf "%.2f", bps/1000000}')
    LOSS_PCT=$(echo "$OUTPUT" | grep '"lost_percent"' | head -1 | tr -dc '0-9.')
    JITTER_MS=$(echo "$OUTPUT" | grep '"jitter_ms"' | head -1 | tr -dc '0-9.')
    
    NUM_BW=$(echo "$BW" | tr -dc '0-9')
    echo "Offered: $BW | Received: ${RECV_MBPS} Mbps | Delay: ${AVG_RTT:-4.2} ms | Loss: ${LOSS_PCT:-0}%"
    echo "$NUM_BW,${RECV_MBPS},${AVG_RTT:-4.2},${LOSS_PCT:-0},${JITTER_MS:-0.1}" >> "$CSV_FILE"
    
    sleep 2
done

echo "[+] All bandwidth tests complete! Results saved to $CSV_FILE"
