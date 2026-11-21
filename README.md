# CNNP-S6: Computer Networks and Network Protocols (Semester 6)

This repository contains the complete experimental implementations, laboratory guides, automation scripts, measurement datasets, and theoretical analyses for the **Computer Networks and Network Protocols (CNNP)** course.

All experiments are designed to run in an **Ubuntu Linux** environment (Native or WSL2) utilizing standard Linux kernel networking primitives (`ip netns`, `veth`, `tc`, `iptables`, `sysctl`), along with standard network measurement tools (`iperf3`, `tshark`, `wireshark`, `mtr`, `netcat`).

---

## Repository Directory Layout

```
CNNP-S6/
├── README.md                           # Main repository documentation & guide
├── .gitignore                          # Git ignore rules
│
├── skill/                              # Core Laboratory Skill Experiments
│   ├── skill-2/                        # Skill 2: Three-Point Packet Capture Analysis
│   │   ├── README.md                   # Comprehensive 14-stage laboratory guide & viva answers
│   │   ├── setup_network.sh            # Automated network namespace topology setup
│   │   ├── capture.sh                  # Simultaneous tshark capture orchestrator
│   │   ├── send_traffic.sh             # Real netcat traffic generator
│   │   ├── analyze.sh                  # Tshark TTL, payload, delay & retransmission analysis
│   │   ├── cleanup.sh                  # Namespace teardown and pcap cleanup
│   │   ├── run_all.sh                  # Master test runner
│   │   └── analysis_results.txt        # Verified terminal execution logs
│   │
│   ├── skill-3/                        # Skill 3: Queueing Curve, Little's Law & Buffer Analysis
│   │   ├── README.md                   # Full lab report, observation tables & 19 viva answers
│   │   ├── setup_topology.sh           # 3-node topology with 5 Mbps TBF bottleneck
│   │   ├── run_iperf_tests.sh          # Automated UDP test suite across 6 bandwidth levels
│   │   ├── buffer_analysis.sh          # Buffer sizing evaluation (16KB, 64KB, 256KB)
│   │   ├── validate_littles_law.py     # Python mathematical validation of Little's Law (L = λ * W)
│   │   ├── plot_queueing_curve.py      # Queueing curve and Knee point visualization
│   │   ├── cleanup.sh                  # Namespace & process cleanup script
│   │   ├── run_all.sh                  # Complete experiment runner
│   │   └── data/
│   │       ├── queueing_curve_results.csv
│   │       ├── buffer_analysis_results.csv
│   │       └── littles_law_results.json
│   │
│   └── skill-4/                        # Skill 4: Latency Percentiles, BDP & Buffer Sizing
│       ├── README.md                   # Full lab guide, observation tables & viva answers
│       ├── setup_network.sh            # Client-Server network namespace setup
│       ├── measure_baseline.sh         # 200 ping RTT collection with sed extraction
│       ├── introduce_impairments.sh    # Netem impairment injection & loaded RTT measurement
│       ├── analyze_percentiles_bdp.py  # Statistical percentiles (P50/P90/P99) & BDP matrix calculator
│       ├── baseline_rtt_ms.csv         # 200 baseline ping RTT observations
│       ├── loaded_rtt_ms.csv           # 200 loaded/impaired ping RTT observations
│       ├── cleanup.sh                  # Namespace cleanup script
│       └── run_all.sh                  # Master experiment runner
│
├── practical/                          # Reserved for Lab Practical Exercises & Assessments
│   └── .gitkeep
│
└── project/                            # Reserved for Semester 6 Course Project
    └── .gitkeep
```

---

## Overview of Skill Experiments

### 1. [Skill 2: Three-Point Packet Capture Analysis](skill/skill-2/README.md)
- **Objective:** Emulate a 3-node routed network (`host1` $\leftrightarrow$ `router` $\leftrightarrow$ `host2`) with network namespaces and veth pairs, introduce link delay ($20\text{ ms}$) and packet loss ($1\%$) via Linux Netem, simultaneously capture traffic at all three points (`/tmp/cap1.pcap`, `/tmp/cap2.pcap`, `/tmp/cap3.pcap`), transmit real TCP payloads via Netcat, and verify IP TTL decrements ($64 \to 63$), path delay addition ($\approx 20\text{ ms}$), and retransmissions.
- **Run command:**
  ```bash
  cd skill/skill-2 && sudo ./run_all.sh
  ```

### 2. [Skill 3: Queueing Curve, Little's Law, and Buffer Analysis](skill/skill-3/README.md)
- **Objective:** Establish a rate-limited link using Token Bucket Filter (`tbf rate 5mbit burst 32kb limit 64kb`), sweep UDP traffic across $1\text{M}$ to $10\text{M}$ using `iperf3`, identify the **knee point** at link saturation ($5\text{ Mbps}$), analyze buffer occupancy and packet drops across multiple buffer limits ($16\text{ KB}$, $64\text{ KB}$, $256\text{ KB}$), and experimentally validate **Little's Law** ($L = \lambda \times W$).
- **Run command:**
  ```bash
  cd skill/skill-3 && sudo ./run_all.sh
  ```

### 3. [Skill 4: Percentiles, Bandwidth-Delay Product (BDP), and Buffer Analysis](skill/skill-4/README.md)
- **Objective:** Measure baseline RTT across 200 ping probes, inject network impairments (delay, jitter, and loss), measure loaded RTT under concurrent iPerf3 background load, compute statistical percentiles ($P_{50}, P_{90}, P_{95}, P_{99}$), demonstrate why arithmetic mean is misleading for network latency analysis, calculate the **Bandwidth-Delay Product (BDP)** across various network profiles, and examine optimal buffer sizing vs bufferbloat.
- **Run command:**
  ```bash
  cd skill/skill-4 && sudo ./run_all.sh
  ```

---

## Quickstart Guide for Ubuntu / WSL2

Ensure your Linux environment has the required packages installed:
```bash
sudo apt update
sudo apt install -y iproute2 iperf3 tshark wireshark netcat-openbsd mtr-tiny python3
```

All bash scripts in each skill directory are executable and include validation, automated namespace configuration, logging, and graceful teardown.
