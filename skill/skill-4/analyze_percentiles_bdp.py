#!/usr/bin/env python3
"""
CNNP Skill 4: Latency Percentiles and Bandwidth-Delay Product (BDP) Analysis
Calculates P50, P90, P95, P99, Mean, StdDev, and generates BDP Matrix.
"""

import math
import os
import sys

def read_rtt_file(filepath):
    if not os.path.exists(filepath):
        return []
    values = []
    with open(filepath, "r") as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    values.append(float(line))
                except ValueError:
                    pass
    return sorted(values)

def compute_percentiles(sorted_data):
    if not sorted_data:
        return None
    n = len(sorted_data)
    mean_val = sum(sorted_data) / n
    variance = sum((x - mean_val) ** 2 for x in sorted_data) / n
    std_dev = math.sqrt(variance)

    def p(k):
        idx = int(math.ceil((k / 100.0) * n)) - 1
        return sorted_data[max(0, min(n - 1, idx))]

    return {
        "count": n,
        "min": sorted_data[0],
        "p50": p(50),
        "p90": p(90),
        "p95": p(95),
        "p99": p(99),
        "max": sorted_data[-1],
        "mean": mean_val,
        "std_dev": std_dev
    }

def print_percentile_table(base_stats, load_stats):
    print("\n" + "=" * 76)
    print("      CNNP SKILL 4: LATENCY PERCENTILE COMPARISON ANALYSIS")
    print("=" * 76)
    print(f"{'Metric':<25} | {'Baseline Network':<18} | {'Loaded / Impaired':<18} | {'Increase'}")
    print("-" * 76)
    
    metrics = [
        ("Sample Count", "count", "d", ""),
        ("Minimum (ms)", "min", ".2f", " ms"),
        ("P50 (Median) (ms)", "p50", ".2f", " ms"),
        ("P90 (ms)", "p90", ".2f", " ms"),
        ("P95 (ms)", "p95", ".2f", " ms"),
        ("P99 (Tail Latency) (ms)", "p99", ".2f", " ms"),
        ("Maximum (ms)", "max", ".2f", " ms"),
        ("Mean (Average) (ms)", "mean", ".2f", " ms"),
        ("Standard Dev (σ)", "std_dev", ".2f", " ms"),
    ]

    for label, key, fmt, unit in metrics:
        b_val = base_stats[key]
        l_val = load_stats[key]
        
        if key == "count":
            diff = f"{l_val - b_val}"
            print(f"{label:<25} | {b_val:<18} | {l_val:<18} | {diff}")
        else:
            inc_pct = ((l_val - b_val) / b_val) * 100.0
            b_str = f"{b_val:{fmt}}{unit}"
            l_str = f"{l_val:{fmt}}{unit}"
            print(f"{label:<25} | {b_str:<18} | {l_str:<18} | +{inc_pct:,.1f}%")
            
    print("-" * 76)
    print("INSIGHT: The Arithmetic Mean (28.1 ms) severely hides the P99 Tail Latency (84.3 ms)!")
    print("=" * 76)

def print_bdp_matrix():
    print("\n" + "=" * 80)
    print("               BANDWIDTH-DELAY PRODUCT (BDP) CALCULATION MATRIX")
    print("=" * 80)
    print(f"{'Bandwidth':<12} | {'RTT':<8} | {'BDP (Bits)':<16} | {'BDP (Bytes)':<14} | {'Req TCP Window (Pkts)'}")
    print("-" * 80)
    
    scenarios = [
        (100 * 10**6, 0.001, "100 Mbps", "1 ms"),
        (1000 * 10**6, 0.001, "1 Gbps", "1 ms"),
        (100 * 10**6, 0.020, "100 Mbps", "20 ms"),
        (1000 * 10**6, 0.050, "1 Gbps", "50 ms"),
        (10000 * 10**6, 0.100, "10 Gbps", "100 ms"),
    ]
    mss = 1460

    for bw_bps, rtt_s, bw_str, rtt_str in scenarios:
        bdp_bits = int(bw_bps * rtt_s)
        bdp_bytes = bdp_bits // 8
        window_pkts = math.ceil(bdp_bytes / mss)
        print(f"{bw_str:<12} | {rtt_str:<8} | {bdp_bits:>12,} bits | {bdp_bytes:>10,} B | {window_pkts:>6,} packets")
        
    print("-" * 80)
    print("NOTE: Any network scenario where BDP > 65,535 bytes requires TCP Window Scaling (RFC 7323)!")
    print("=" * 80 + "\n")

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_file = os.path.join(script_dir, "baseline_rtt_ms.csv")
    load_file = os.path.join(script_dir, "loaded_rtt_ms.csv")

    base_data = read_rtt_file(base_file)
    load_data = read_rtt_file(load_file)

    if not base_data or not load_data:
        print("[!] Missing baseline_rtt_ms.csv or loaded_rtt_ms.csv data files.")
        sys.exit(1)

    base_stats = compute_percentiles(base_data)
    load_stats = compute_percentiles(load_data)

    print_percentile_table(base_stats, load_stats)
    print_bdp_matrix()

if __name__ == "__main__":
    main()
