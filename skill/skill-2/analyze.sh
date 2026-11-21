#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 2: Analyze Packet Captures (Stages 11 - 14)
# Checks file sizes, TTL decrements, payload, delay, retransmissions, and MTR
# ==============================================================================

set -euo pipefail

echo "====================================================================="
echo "           CNNP SKILL 2 - THREE-POINT CAPTURE ANALYSIS"
echo "====================================================================="

echo ""
echo "[1] Checking Capture File Sizes (Stage 12):"
ls -lh /tmp/cap1.pcap /tmp/cap2.pcap /tmp/cap3.pcap

echo ""
echo "[2] Checking IP TTL at All Three Points (Stage 13):"
echo "--- Point 1 (host1): cap1.pcap ---"
tshark -r /tmp/cap1.pcap -T fields -e ip.ttl -Y "ip" 2>/dev/null | sort | uniq -c
echo "Expected: TTL 64"

echo "--- Point 2 (router): cap2.pcap ---"
tshark -r /tmp/cap2.pcap -T fields -e ip.ttl -Y "ip" 2>/dev/null | sort | uniq -c
echo "Expected: TTL 64 (inbound) / 63 (outbound)"

echo "--- Point 3 (host2): cap3.pcap ---"
tshark -r /tmp/cap3.pcap -T fields -e ip.ttl -Y "ip" 2>/dev/null | sort | uniq -c
echo "Expected: TTL 63 (decremented by router)"

echo ""
echo "[3] Extracting Message Payload from Router Capture (Stage 14):"
tshark -r /tmp/cap2.pcap -Y "tcp.port == 1234" -T fields -e tcp.payload 2>/dev/null | xxd -r -p

echo ""
echo "[4] Checking Relative SYN Timestamps across Points (Delay Check):"
echo "Point 1 (host1):"
tshark -r /tmp/cap1.pcap -Y "tcp.flags.syn==1 && tcp.flags.ack==0" -T fields -e frame.time_relative 2>/dev/null || echo "N/A"
echo "Point 2 (router):"
tshark -r /tmp/cap2.pcap -Y "tcp.flags.syn==1 && tcp.flags.ack==0" -T fields -e frame.time_relative 2>/dev/null || echo "N/A"
echo "Point 3 (host2):"
tshark -r /tmp/cap3.pcap -Y "tcp.flags.syn==1 && tcp.flags.ack==0" -T fields -e frame.time_relative 2>/dev/null || echo "N/A"
echo "Analysis: Delay between Point 1 and Point 3 reflects ~20ms netem delay."

echo ""
echo "[5] Checking TCP Retransmissions:"
echo -n "cap1.pcap retransmissions: "
tshark -r /tmp/cap1.pcap -Y "tcp.analysis.retransmission" 2>/dev/null | wc -l
echo -n "cap2.pcap retransmissions: "
tshark -r /tmp/cap2.pcap -Y "tcp.analysis.retransmission" 2>/dev/null | wc -l
echo -n "cap3.pcap retransmissions: "
tshark -r /tmp/cap3.pcap -Y "tcp.analysis.retransmission" 2>/dev/null | wc -l

echo ""
echo "[6] MTR Path RTT Report:"
if ip netns list | grep -q "host1"; then
    sudo ip netns exec host1 mtr --report -c 5 10.0.2.2 || true
fi

echo ""
echo "====================================================================="
echo "                    ANALYSIS COMPLETED SUCCESSFULLY"
echo "====================================================================="
