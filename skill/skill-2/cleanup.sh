#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 2: Cleanup Network Namespaces and Temp Files
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root (sudo ./cleanup.sh)"
    exit 1
fi

echo "[*] Terminating any remaining capture processes..."
killall tshark 2>/dev/null || true
rm -f /tmp/cnnp_cap*.pid 2>/dev/null || true

echo "[*] Deleting network namespaces..."
ip netns del host1 2>/dev/null || true
ip netns del router 2>/dev/null || true
ip netns del host2 2>/dev/null || true

echo "[*] Removing temporary packet captures and logs..."
rm -f /tmp/cap1.pcap /tmp/cap2.pcap /tmp/cap3.pcap /tmp/received_messages.txt

echo "[*] Verifying namespace list (Must return blank):"
ip netns list

echo "[+] Cleanup complete!"
