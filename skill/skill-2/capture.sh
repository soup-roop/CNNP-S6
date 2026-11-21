#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 2: Start Simultaneous 3-Point Packet Capture
# Points:
#   1. host1 (veth-h1)   -> /tmp/cap1.pcap
#   2. router (veth-r1)  -> /tmp/cap2.pcap
#   3. host2 (veth-h2)   -> /tmp/cap3.pcap
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root (sudo ./capture.sh)"
    exit 1
fi

echo "[*] Cleaning up old capture files in /tmp..."
rm -f /tmp/cap1.pcap /tmp/cap2.pcap /tmp/cap3.pcap

echo "[*] Starting Point 1 capture (host1 on veth-h1)..."
ip netns exec host1 tshark -i veth-h1 -w /tmp/cap1.pcap >/dev/null 2>&1 &
PID_CAP1=$!

echo "[*] Starting Point 2 capture (router on veth-r1)..."
ip netns exec router tshark -i veth-r1 -w /tmp/cap2.pcap >/dev/null 2>&1 &
PID_CAP2=$!

echo "[*] Starting Point 3 capture (host2 on veth-h2)..."
ip netns exec host2 tshark -i veth-h2 -w /tmp/cap3.pcap >/dev/null 2>&1 &
PID_CAP3=$!

# Save PIDs to file for easy termination
echo "$PID_CAP1" > /tmp/cnnp_cap1.pid
echo "$PID_CAP2" > /tmp/cnnp_cap2.pid
echo "$PID_CAP3" > /tmp/cnnp_cap3.pid

sleep 2
echo "[+] All 3 packet captures are running in background!"
echo "    Point 1 PID: $PID_CAP1 (/tmp/cap1.pcap)"
echo "    Point 2 PID: $PID_CAP2 (/tmp/cap2.pcap)"
echo "    Point 3 PID: $PID_CAP3 (/tmp/cap3.pcap)"
