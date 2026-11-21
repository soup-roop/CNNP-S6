#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 3: Master Test Orchestrator
# Runs Setup -> iPerf Tests -> Buffer Tests -> Little's Law -> Analysis
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root: sudo ./run_all.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "======================================================================"
echo "          CNNP SKILL 3: COMPLETE EXPERIMENT SUITE"
echo "======================================================================"

echo ""
echo ">>> STEP 1: Setting up topology and 5 Mbps bottleneck (TBF)..."
bash setup_topology.sh

echo ""
echo ">>> STEP 2: Running iperf3 UDP bandwidth suite (1M to 10M)..."
bash run_iperf_tests.sh

echo ""
echo ">>> STEP 3: Running buffer sizing analysis (16KB, 64KB, 256KB)..."
bash buffer_analysis.sh

echo ""
echo ">>> STEP 4: Validating Little's Law..."
python3 validate_littles_law.py

echo ""
echo ">>> STEP 5: Visualizing Queueing Curve and Knee Point..."
python3 plot_queueing_curve.py

echo ""
read -p "Do you want to clean up namespaces now? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash cleanup.sh
else
    echo "Namespaces kept active. Run 'sudo ./cleanup.sh' when finished."
fi
