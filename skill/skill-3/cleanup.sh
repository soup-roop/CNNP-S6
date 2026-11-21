#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 3: Cleanup Namespaces and Processes
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root (sudo ./cleanup.sh)"
    exit 1
fi

echo "[*] Killing running iperf3 and tshark instances..."
killall iperf3 2>/dev/null || true
killall tshark 2>/dev/null || true

echo "[*] Deleting network namespaces..."
ip netns del sender 2>/dev/null || true
ip netns del router 2>/dev/null || true
ip netns del receiver 2>/dev/null || true

echo "[*] Verifying namespaces (must be empty):"
ip netns list

echo "[+] Cleanup completed!"
