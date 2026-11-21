#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 2: Send Real Message from host1 to host2
# Starts nc listener on host2 (port 1234) and sends test messages from host1
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root (sudo ./send_traffic.sh)"
    exit 1
fi

echo "[*] Starting netcat listener on host2 (port 1234)..."
ip netns exec host2 nc -l 1234 > /tmp/received_messages.txt 2>&1 &
NC_PID=$!
sleep 1

echo "[*] Sending messages from host1 to host2 (10.0.2.2:1234)..."
ip netns exec host1 bash -c 'cat << "EOF" | nc 10.0.2.2 1234
Hello from host1!
This is Alekhya
Computer Networks Lab
Three Point Capture Experiment
Message traveling through router
EOF'

sleep 2
kill $NC_PID 2>/dev/null || true

echo "[+] Messages received at host2:"
cat /tmp/received_messages.txt

# Stop background captures if running
if [ -f /tmp/cnnp_cap1.pid ]; then
    echo "[*] Stopping background captures..."
    kill $(cat /tmp/cnnp_cap1.pid) 2>/dev/null || true
    kill $(cat /tmp/cnnp_cap2.pid) 2>/dev/null || true
    kill $(cat /tmp/cnnp_cap3.pid) 2>/dev/null || true
    rm -f /tmp/cnnp_cap*.pid
fi

chmod 644 /tmp/cap1.pcap /tmp/cap2.pcap /tmp/cap3.pcap 2>/dev/null || true
echo "[+] Traffic transmission complete!"
