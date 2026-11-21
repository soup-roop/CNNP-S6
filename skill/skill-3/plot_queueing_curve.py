#!/usr/bin/env python3
"""
CNNP Skill 3: Plot Queueing Curve and Identify Knee Point
Plots Offered Traffic vs Received Throughput and Delay
"""

def generate_ascii_plot():
    tests = [
        {"offered": 1.0, "recv": 1.00, "delay": 0.82, "loss": 0.0},
        {"offered": 2.0, "recv": 2.00, "delay": 0.88, "loss": 0.0},
        {"offered": 4.0, "recv": 3.99, "delay": 1.15, "loss": 0.0},
        {"offered": 5.0, "recv": 4.98, "delay": 4.20, "loss": 0.1},  # Knee Point
        {"offered": 7.0, "recv": 4.99, "delay": 48.60, "loss": 28.5},
        {"offered": 10.0, "recv": 5.00, "delay": 102.40, "loss": 49.8},
    ]

    print("\n" + "=" * 70)
    print("          CNNP SKILL 3: QUEUEING CURVE & KNEE POINT PLOT")
    print("=" * 70)
    print("Offered (Mbps) | Throughput (Mbps) | Delay (ms) | ASCII Delay Visualization")
    print("-" * 70)
    for t in tests:
        bars = int(t["delay"] / 3)
        marker = " <--- KNEE POINT (Threshold)" if t["offered"] == 5.0 else ""
        print(f"    {t['offered']:4.1f} Mbps   |    {t['recv']:4.2f} Mbps     |  {t['delay']:6.2f} ms | {'#' * bars}{marker}")
    print("-" * 70)
    print("Analysis:")
    print(" - For Offered Load <= 5 Mbps: Delay is flat (~1 ms), Throughput = Offered Load.")
    print(" - At 5 Mbps (Knee Point): Bottleneck capacity reached.")
    print(" - For Offered Load > 5 Mbps: Throughput caps at 5 Mbps; Delay spikes to 102 ms.")
    print("=" * 70 + "\n")

if __name__ == "__main__":
    generate_ascii_plot()
