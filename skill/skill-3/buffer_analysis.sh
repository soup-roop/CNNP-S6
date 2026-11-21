#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 3: Buffer Sizing Analysis (16KB, 64KB, 256KB)
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root (sudo ./buffer_analysis.sh)"
    exit 1
fi

DATA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/data"
mkdir -p "$DATA_DIR"
CSV_FILE="$DATA_DIR/buffer_analysis_results.csv"

echo "buffer_limit_kb,max_backlog_kb,packet_drops,ping_rtt_ms" > "$CSV_FILE"

BUFFERS=("16kb" "64kb" "256kb")

for BUF in "${BUFFERS[@]}"; do
    echo "======================================================================"
    echo "[*] Testing buffer limit: $BUF with 10 Mbps UDP overload..."
    echo "======================================================================"

    # Configure buffer on router
    ip netns exec router tc qdisc replace dev r-eth1 root tbf rate 5mbit burst 32kb limit "$BUF"
    
    # Run overload traffic in background
    ip netns exec sender iperf3 -c 192.168.20.2 -u -b 10M -l 1200 -t 15 >/dev/null 2>&1 &
    IPERF_PID=$!
    
    sleep 2
    # Measure RTT under congestion
    PING_OUT=$(ip netns exec sender ping -c 10 -i 0.5 192.168.20.2 | tail -1)
    AVG_RTT=$(echo "$PING_OUT" | awk -F '/' '{print $5}')
    
    # Capture qdisc statistics
    TC_STATS=$(ip netns exec router tc -s qdisc show dev r-eth1)
    DROPS=$(echo "$TC_STATS" | grep -o 'dropped [0-9]*' | awk '{print $2}')
    BACKLOG=$(echo "$TC_STATS" | grep -o 'backlog [0-9]*b' | tr -dc '0-9')
    BACKLOG_KB=$(awk -v b="${BACKLOG:-0}" 'BEGIN {printf "%.1f", b/1024}')
    
    wait $IPERF_PID 2>/dev/null || true
    
    NUM_BUF=$(echo "$BUF" | tr -dc '0-9')
    echo "Buffer: $BUF | Max Backlog: ${BACKLOG_KB} KB | Drops: ${DROPS:-0} | Ping RTT: ${AVG_RTT:-0} ms"
    echo "$NUM_BUF,${BACKLOG_KB},${DROPS:-0},${AVG_RTT:-0}" >> "$CSV_FILE"
    
    sleep 2
done

echo "[+] Buffer analysis tests complete! Results saved to $CSV_FILE"
