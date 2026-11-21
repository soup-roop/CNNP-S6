# CNNP - Skill 4: Percentiles, Bandwidth-Delay Product (BDP), and Buffer Analysis

## Aim of the Experiment
To establish network performance baselines, introduce network impairments (latency, jitter, packet loss, and bottleneck traffic), analyze latency percentiles (P50, P90, P95, P99) to identify misleading performance measurements (e.g., mean vs tail latency), calculate the **Bandwidth-Delay Product (BDP)**, and evaluate router buffer sizing tradeoffs.

---

## Network Architecture & Setup

```
+------------------------------------+               +------------------------------------+
|            Computer 1              |               |            Computer 2              |
|        (Server + Wireshark)        |               |             (Client)               |
|                                    |               |                                    |
|   Interface: eth0 / Wi-Fi          | <===========> |   Interface: eth0 / Wi-Fi          |
|   IP: 192.168.1.10/24              |  Same Subnet  |   IP: 192.168.1.20/24              |
|                                    |               |                                    |
|   iperf3 -s (Port 5201)            |               |   iperf3 -c 192.168.1.10           |
|   Wireshark Capture                |               |   ping -c 200 -i 0.2               |
+------------------------------------+               +------------------------------------+
```

*(Note: Can be executed on two physical machines, two VMs, or two Linux network namespaces `server` and `client` on Ubuntu).*

---

## Theoretical Foundation

### 1. Why Latency Percentiles (and Why the Average is Misleading)
In computer networking, network delay does not follow a Gaussian (normal) distribution. Packet delay is characterized by **heavy-tailed (Pareto or log-normal) distributions** caused by bursty queueing, packet loss, TCP retransmission timeouts (RTO), and head-of-line blocking.
- **Mean (Average) Latency:** $\mu = \frac{1}{N}\sum RTT_i$. The arithmetic mean is heavily smoothed by the large majority of low-latency packets. It completely masks severe latency spikes.
- **P50 (50th Percentile / Median):** Represents typical latency experienced by half the packets.
- **P90 / P95 (90th & 95th Percentiles):** Latency during short traffic bursts or moderate queue buildup.
- **P99 / P99.9 (Tail Latency):** Worst 1% or 0.1% of transactions. In distributed cloud applications, a single user request often triggers hundreds of backend queries. The slowest sub-request dictates total response time; hence **P99 latency governs user-perceived SLA**.

---

### 2. Bandwidth-Delay Product (BDP)
The **Bandwidth-Delay Product** measures the maximum capacity of data that can be in transit ("in flight") within the network pipe at any given instant:

$$\text{BDP (bits)} = \text{Bandwidth (bps)} \times \text{Round-Trip Time (RTT in seconds)}$$

$$\text{BDP (bytes)} = \frac{\text{BDP (bits)}}{8}$$

$$\text{Optimal TCP Window (packets)} = \frac{\text{BDP (bytes)}}{\text{MSS (Maximum Segment Size)}}$$

*(Where standard Ethernet MTU = 1500 bytes, $\text{MSS} = 1500 - 20 (\text{IP}) - 20 (\text{TCP}) = 1460\text{ bytes}$)*.

#### BDP Implications:
- If TCP sender window $< \text{BDP}$: The network pipe cannot be fully utilized; throughput is throttled regardless of available bandwidth.
- If TCP sender window $\ge \text{BDP}$: Maximum link throughput is achieved.
- For high-speed or high-latency paths (e.g., $10\text{ Gbps}$ or satellite links), BDP exceeds the legacy 16-bit TCP window limit ($65,535\text{ bytes}$), necessitating **TCP Window Scaling (RFC 7323)**.

---

### 3. Buffer Sizing Rules and Bufferbloat
- **Classical Rule of Thumb (Guaranteed full utilization for a single TCP Reno flow):**
  $$\text{Buffer Size} = \text{BDP} = B \times RTT$$
- **Stanford Rule of Thumb (for core routers carrying $N$ desynchronized TCP flows):**
  $$\text{Buffer Size} = \frac{B \times RTT}{\sqrt{N}}$$
- **Undersized Buffer ($< \text{BDP}$):** Causes premature packet drops, frequent TCP window collapse, and link underutilization.
- **Oversized Buffer ($>> \text{BDP}$):** Causes **Bufferbloat**. Packets accumulate in massive queues, increasing latency from milliseconds to seconds without any gain in throughput.

---

## Step-by-Step Ubuntu Terminal Instructions

### Step 1: Establish Network Connection & Identify IP
On Computer 1 (Server):
```bash
# On Ubuntu/Linux:
ip addr show
# Or on macOS:
# ipconfig getifaddr en0

# Expected IP: 192.168.1.10
```

On Computer 2 (Client):
```bash
ip addr show
# Expected IP: 192.168.1.20
```

---

### Step 2: Start iPerf3 Server
On Computer 1 (Server):
```bash
iperf3 -s
```
Output:
```text
-----------------------------------------------------------
Server listening on 5201 (test #1)
-----------------------------------------------------------
```
*Keep this terminal open.*

---

### Step 3: Start Wireshark Packet Capture
1. Launch Wireshark on Computer 1:
   ```bash
   wireshark &
   ```
2. Select the active network interface (`eth0`, `en0`, or `wlan0`).
3. Set the capture display filter:
   ```text
   icmp or tcp.port == 5201 or udp.port == 5201
   ```
4. Double-click the interface to start capturing.

---

### Step 4: Measure Baseline Network Latency
On Computer 2 (Client), send 200 ping probes at 0.2-second intervals without background traffic, filtering RTT values directly to a CSV file:

```bash
ping -c 200 -i 0.2 192.168.1.10 | sed -n 's/.*time[=<]\([0-9.]*\) ms.*/\1/p' > baseline_rtt_ms.csv
```

#### Inspect Wireshark:
- Display filter: `icmp`
- Observe **Echo (ping) Request** (Type 8) and **Echo (ping) Reply** (Type 0).
- Check the delta time between request and reply packets.

---

### Step 5: Introduce Network Impairments & Measure Loaded Latency
1. Introduce link impairment (delay, jitter, and loss) using Linux `tc netem`:
   ```bash
   sudo tc qdisc add dev eth0 root netem delay 25ms 5ms loss 1%
   ```
2. Generate concurrent background TCP traffic from Computer 2:
   ```bash
   iperf3 -c 192.168.1.10 -t 45 &
   ```
3. Simultaneously measure loaded ping latency into `loaded_rtt_ms.csv`:
   ```bash
   ping -c 200 -i 0.2 192.168.1.10 | sed -n 's/.*time[=<]\([0-9.]*\) ms.*/\1/p' > loaded_rtt_ms.csv
   ```
4. Remove the netem impairment after testing:
   ```bash
   sudo tc qdisc del dev eth0 root
   ```

---

### Step 6: Compute Percentiles & BDP
Run the provided analysis script:
```bash
python3 analyze_percentiles_bdp.py
```

---

## Experimental Observation Tables

### Observation Table 1: Latency Percentile Comparison (Baseline vs Impaired/Loaded)
| Metric | Baseline Network (No Impairment) | Impaired / Loaded Network | Percentage Increase |
| :--- | :---: | :---: | :---: |
| **Minimum Latency** | 0.42 ms | 20.15 ms | +4,697% |
| **P50 (Median)** | **0.85 ms** | **25.40 ms** | **+2,888%** |
| **P90 (90th Percentile)** | 1.15 ms | 31.80 ms | +2,665% |
| **P95 (95th Percentile)** | 1.34 ms | 38.65 ms | +2,784% |
| **P99 (Tail Latency)** | **2.45 ms** | **84.30 ms** | **+3,340%** |
| **Maximum Latency** | 3.82 ms | 128.50 ms | +3,263% |
| **Arithmetic Mean (Avg)** | 0.94 ms | 28.10 ms | +2,889% |
| **Standard Deviation ($\sigma$)** | 0.38 ms | 14.85 ms | +3,807% |

> **Key Observation on Misleading Averages:**
> In the loaded network, the **Mean is 28.10 ms**, while the **P99 tail latency is 84.30 ms** (3 times higher!). An SLA evaluated purely on mean latency would give a false impression of stability, failing to expose that 1% of transactions suffer severe 84+ ms delays.

---

### Observation Table 2: Bandwidth-Delay Product (BDP) Calculation Matrix
*Using $\text{MSS} = 1460\text{ bytes}$ ($11,680\text{ bits}$)*

| Scenario | Link Bandwidth ($B$) | Path RTT | BDP (Bits) | BDP (Bytes) | BDP (KB) | Required TCP Window (Packets) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Fast LAN** | 100 Mbps | 1 ms | $100,000$ bits | $12,500$ B | 12.2 KB | 9 packets |
| **Gigabit LAN** | 1 Gbps | 1 ms | $1,000,000$ bits | $125,000$ B | 122.1 KB | 86 packets |
| **Metropolitan WAN**| 100 Mbps | 20 ms | $2,000,000$ bits | $250,000$ B | 244.1 KB | 172 packets |
| **Cross-Country WAN**| 1 Gbps | 50 ms | $50,000,000$ bits | $6,250,000$ B | 6.1 MB | 4,281 packets |
| **Intercontinental WAN**| 10 Gbps | 100 ms | $1,000,000,000$ bits | $125,000,000$ B | 122.1 MB | 85,616 packets |

---

### Observation Table 3: Router Buffer Sizing Tradeoffs
| Buffer Size Regime | Configured Buffer | Achieved Throughput | RTT under Congestion | Drop Rate | Impact / Evaluation |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Undersized** ($< 0.2\times\text{BDP}$) | 16 KB | 42.1 Mbps | 22.4 ms | 12.4% | Severe under-utilization; TCP window repeatedly collapses |
| **Optimal** ($\approx 1\times\text{BDP}$) | 125 KB | 98.4 Mbps | 48.2 ms | 0.8% | **Maximum throughput** with bounded queueing delay |
| **Oversized / Bloated** ($> 5\times\text{BDP}$)| 1024 KB | 98.7 Mbps | 385.0 ms | 0.05% | **Bufferbloat:** Zero throughput gain, but 8x higher latency |

---

## Complete Viva Questions & Answers

1. **What is Bandwidth-Delay Product (BDP)?**
   - BDP is the product of available link bandwidth and round-trip time ($BDP = \text{Bandwidth} \times \text{RTT}$). It represents the volume of unacknowledged data that can be in flight simultaneously to fully saturate the link.

2. **Why is the arithmetic mean misleading when measuring network latency?**
   - Arithmetic mean is sensitive to normal clustering and masks extreme tail spikes. In real networks, latency distributions are skewed by queueing and packet loss. Evaluating by mean hides catastrophic tail delays experienced by users.

3. **What is tail latency and why does P99 matter?**
   - Tail latency refers to the highest percentiles of delay (P95, P99, P99.9). In cloud microservices where a user action depends on $N$ fan-out requests, the slowest request determines user response time ($P(\text{slow}) = 1 - (1 - p)^N$).

4. **What is TCP Window Scaling (RFC 7323)?**
   - Standard TCP header allows a maximum window field of 16 bits ($65,535\text{ bytes}$). The Window Scale option allows scaling by up to $2^{14}$, allowing receive windows up to $1\text{ GB}$ to satisfy high-BDP networks.

5. **What happens if the TCP socket buffer is smaller than the BDP?**
   - The sender is forced to stop transmitting and wait for ACKs before sending more data, preventing full utilization of the channel bandwidth.

6. **What is Bufferbloat?**
   - The undesirable condition where oversized packet buffers in network equipment become chronically full, causing excessive latency and jitter without improving throughput.

7. **How does packet loss affect TCP window growth?**
   - Standard TCP loss-based algorithms (like Reno and Cubic) interpret packet loss as an explicit signal of network congestion and drastically reduce their congestion window (`cwnd`).

8. **What is the Stanford Small Buffer rule?**
   - It states that for a core router multiplexing $N$ independent, asynchronous TCP flows, the required buffer size can be reduced from $B \times RTT$ to $\frac{B \times RTT}{\sqrt{N}}$ without throughput loss.

9. **What filter in Wireshark isolates iPerf3 and ICMP traffic?**
   - `icmp or tcp.port == 5201 or udp.port == 5201`.

10. **What is the significance of the `sed` command in baseline measurement?**
    - `sed -n 's/.*time[=<]\([0-9.]*\) ms.*/\1/p'` parses the ping console output and extracts purely the numeric RTT in milliseconds for statistical ingestion into CSV format.
