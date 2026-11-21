#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 4: Master Test Orchestrator
# Runs Setup -> Measure Baseline -> Measure Loaded -> Calculate Percentiles & BDP
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root: sudo ./run_all.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "======================================================================"
echo "          CNNP SKILL 4: COMPLETE EXPERIMENT SUITE"
echo "======================================================================"

echo ""
echo ">>> STEP 1: Setting up network namespaces (server and client)..."
bash setup_network.sh

echo ""
echo ">>> STEP 2: Measuring baseline RTT (200 probes)..."
bash measure_baseline.sh 192.168.1.10

echo ""
echo ">>> STEP 3: Injecting network impairment & measuring loaded RTT..."
bash introduce_impairments.sh 192.168.1.10

echo ""
echo ">>> STEP 4: Computing Percentiles and Bandwidth-Delay Product (BDP)..."
python3 analyze_percentiles_bdp.py

echo ""
read -p "Do you want to clean up namespaces now? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash cleanup.sh
else
    echo "Namespaces kept active. Run 'sudo ./cleanup.sh' when finished."
fi
