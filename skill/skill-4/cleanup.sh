#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 4: Cleanup Network Namespaces and Temp Files
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root (sudo ./cleanup.sh)"
    exit 1
fi

echo "[*] Stopping iperf3 and capture processes..."
killall iperf3 2>/dev/null || true
killall wireshark 2>/dev/null || true

echo "[*] Deleting network namespaces..."
ip netns del server 2>/dev/null || true
ip netns del client 2>/dev/null || true

echo "[*] Verifying namespaces (must be empty):"
ip netns list

echo "[+] Cleanup complete!"
