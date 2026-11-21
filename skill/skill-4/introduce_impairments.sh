#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 4: Introduce Network Impairments & Measure Loaded Latency
# Adds netem delay, jitter, loss and measures latency under active traffic
# ==============================================================================

set -euo pipefail

TARGET_IP="${1:-192.168.1.10}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_CSV="$SCRIPT_DIR/loaded_rtt_ms.csv"

echo "[*] Injecting network impairment (delay 25ms, jitter 5ms, loss 1%)..."

if ip netns list | grep -q "server"; then
    # In namespace mode
    sudo ip netns exec client tc qdisc add dev veth-cli root netem delay 25ms 5ms loss 1% 2>/dev/null || \
    sudo ip netns exec client tc qdisc change dev veth-cli root netem delay 25ms 5ms loss 1%
    
    echo "[*] Starting background iperf3 server and client traffic..."
    sudo ip netns exec server iperf3 -s -D 2>/dev/null || true
    sleep 1
    sudo ip netns exec client iperf3 -c "$TARGET_IP" -t 45 >/dev/null 2>&1 &
    IPERF_PID=$!
    
    echo "[*] Measuring loaded network latency (200 probes at 0.2s intervals)..."
    sudo ip netns exec client ping -c 200 -i 0.2 "$TARGET_IP" | sed -n 's/.*time[=<]\([0-9.]*\) ms.*/\1/p' > "$OUTPUT_CSV"
    
    wait $IPERF_PID 2>/dev/null || true
    sudo ip netns exec client tc qdisc del dev veth-cli root 2>/dev/null || true
else
    # Host mode
    sudo tc qdisc add dev eth0 root netem delay 25ms 5ms loss 1% 2>/dev/null || true
    echo "[*] Measuring loaded network latency..."
    ping -c 200 -i 0.2 "$TARGET_IP" | sed -n 's/.*time[=<]\([0-9.]*\) ms.*/\1/p' > "$OUTPUT_CSV"
    sudo tc qdisc del dev eth0 root 2>/dev/null || true
fi

TOTAL_SAMPLES=$(wc -l < "$OUTPUT_CSV")
echo "[+] Loaded measurement complete! Collected $TOTAL_SAMPLES samples into $OUTPUT_CSV"
