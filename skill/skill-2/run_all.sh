#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 2: Master Test Orchestrator
# Runs Setup -> Start Captures -> Send Traffic -> Analyze -> Optional Cleanup
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root: sudo ./run_all.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "======================================================================"
echo "          CNNP SKILL 2: AUTOMATED EXPERIMENT EXECUTION"
echo "======================================================================"

echo ""
echo ">>> STEP 1: Setting up 3-node network topology and impairment..."
bash setup_network.sh

echo ""
echo ">>> STEP 2: Starting 3 simultaneous packet captures (tshark)..."
bash capture.sh

echo ""
echo ">>> STEP 3: Transmitting netcat messages from host1 to host2..."
bash send_traffic.sh

echo ""
echo ">>> STEP 4: Running automated analysis of pcap captures..."
bash analyze.sh

echo ""
echo "======================================================================"
echo "Experiment complete! Capture files are located at:"
echo "  - /tmp/cap1.pcap (host1)"
echo "  - /tmp/cap2.pcap (router)"
echo "  - /tmp/cap3.pcap (host2)"
echo "You can inspect them with Wireshark: wireshark /tmp/cap2.pcap &"
echo ""
read -p "Do you want to clean up namespaces now? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash cleanup.sh
else
    echo "Namespaces kept active. Run 'sudo ./cleanup.sh' when finished."
fi
