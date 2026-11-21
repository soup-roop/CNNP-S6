# CNNP - Skill 2: Three-Point Packet Capture Analysis

## Aim of the Experiment
To analyze packet captures from three distinct vantage points in an emulated network path (Host1, Router, Host2) to observe packet flow, verify IPv4 packet forwarding, examine Time-to-Live (TTL) decrements, measure transit delay, analyze TCP retransmissions under loss, and inspect packet payloads using `tshark` and `Wireshark`.

---

## Network Topology

```
+-------------------+                      +-------------------+                      +-------------------+
|       host1       |                      |      router       |                      |       host2       |
|  (Network Netns)  |                      |  (Network Netns)  |                      |  (Network Netns)  |
|                   |                      |                   |                      |                   |
|  veth-h1          | <==================> |  veth-r1  veth-r2 | <==================> |  veth-h2          |
|  10.0.1.1/30      |      Subnet A        |  10.0.1.2 10.0.2.1|      Subnet B        |  10.0.2.2/30      |
+-------------------+     10.0.1.0/30      +-------------------+     10.0.2.0/30      +-------------------+
  [Point 1 Capture]                          [Point 2 Capture]                          [Point 3 Capture]
   /tmp/cap1.pcap                             /tmp/cap2.pcap                             /tmp/cap3.pcap
```

### IP Addressing Table
| Node | Interface | IP Address | Subnet Mask | Gateway | Netem Impairment |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **host1** | `veth-h1` | `10.0.1.1` | `255.255.255.252` (/30) | `10.0.1.2` | None |
| **router** | `veth-r1` | `10.0.1.2` | `255.255.255.252` (/30) | N/A | None |
| **router** | `veth-r2` | `10.0.2.1` | `255.255.255.252` (/30) | N/A | `delay 20ms loss 1%` |
| **host2** | `veth-h2` | `10.0.2.2` | `255.255.255.252` (/30) | `10.0.2.1` | None |

---

## Step-by-Step Execution Guide (Ubuntu Terminal)

### STAGE 1 — Install Required Tools
Open Ubuntu terminal and install the required networking and capture utilities:
```bash
sudo apt update
sudo apt install -y tshark iperf3 mtr-tiny iproute2 wireshark netcat-openbsd
```
> When prompted during Wireshark/tshark installation whether non-superusers should be able to capture packets, select **Yes**.

---

### STAGE 2 — Build the Network Topology
Create three isolated network namespaces and connect them using virtual Ethernet (`veth`) cable pairs:
```bash
# 1. Create 3 network namespaces
sudo ip netns add host1
sudo ip netns add router
sudo ip netns add host2

# 2. Create virtual ethernet cable pairs
sudo ip link add veth-h1 type veth peer name veth-r1
sudo ip link add veth-r2 type veth peer name veth-h2

# 3. Connect cables to respective namespaces
sudo ip link set veth-h1 netns host1
sudo ip link set veth-r1 netns router
sudo ip link set veth-r2 netns router
sudo ip link set veth-h2 netns host2

# Verify namespaces
sudo ip netns list
# Expected output:
# host2
# router
# host1
```

---

### STAGE 3 — Configure IP Addresses and Bring Interfaces Up

#### Configure host1:
```bash
sudo ip netns exec host1 ip addr add 10.0.1.1/30 dev veth-h1
sudo ip netns exec host1 ip link set veth-h1 up
sudo ip netns exec host1 ip link set lo up
```

#### Configure router:
```bash
sudo ip netns exec router ip addr add 10.0.1.2/30 dev veth-r1
sudo ip netns exec router ip addr add 10.0.2.1/30 dev veth-r2
sudo ip netns exec router ip link set veth-r1 up
sudo ip netns exec router ip link set veth-r2 up
sudo ip netns exec router ip link set lo up
```

#### Configure host2:
```bash
sudo ip netns exec host2 ip addr add 10.0.2.2/30 dev veth-h2
sudo ip netns exec host2 ip link set veth-h2 up
sudo ip netns exec host2 ip link set lo up
```

---

### STAGE 4 — Enable Routing and Add Static Routes
Enable packet forwarding on the router and configure static routes on host1 and host2:
```bash
# Enable IPv4 forwarding inside router namespace
sudo ip netns exec router sysctl -w net.ipv4.ip_forward=1

# Add route on host1 to reach 10.0.2.0/30 via router (10.0.1.2)
sudo ip netns exec host1 ip route add 10.0.2.0/30 via 10.0.1.2

# Add route on host2 to reach 10.0.1.0/30 via router (10.0.2.1)
sudo ip netns exec host2 ip route add 10.0.1.0/30 via 10.0.2.1
```

---

### STAGE 5 — Test Basic Connectivity
Verify end-to-end communication from host1 to host2:
```bash
sudo ip netns exec host1 ping -c 3 10.0.2.2
```
**Expected Output:**
```text
PING 10.0.2.2 (10.0.2.2) 56(84) bytes of data.
64 bytes from 10.0.2.2: icmp_seq=1 ttl=63 time=... ms
64 bytes from 10.0.2.2: icmp_seq=2 ttl=63 time=... ms
64 bytes from 10.0.2.2: icmp_seq=3 ttl=63 time=... ms

--- 10.0.2.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time ...ms
```

---

### STAGE 6 — Add Delay and Packet Loss (Emulate WAN Link)
Introduce network impairment on the router's egress link to `host2` using Linux Traffic Control (`tc` netem):
```bash
sudo ip netns exec router tc qdisc add dev veth-r2 root netem delay 20ms loss 1%

# Verify configuration:
sudo ip netns exec router tc qdisc show dev veth-r2
# Expected output:
# qdisc netem 8001: root refcnt 13 limit 1000 delay 20ms loss 1%
```

---

### STAGE 7 & 8 — Start Simultaneous Three-Point Captures
Open multiple terminals (or run background capture processes):

- **Terminal 1 (Point 1: host1 egress/ingress):**
  ```bash
  sudo ip netns exec host1 tshark -i veth-h1 -w /tmp/cap1.pcap
  ```

- **Terminal 2 (Point 2: router ingress):**
  ```bash
  sudo ip netns exec router tshark -i veth-r1 -w /tmp/cap2.pcap
  ```

- **Terminal 3 (Point 3: host2 ingress):**
  ```bash
  sudo ip netns exec host2 tshark -i veth-h2 -w /tmp/cap3.pcap
  ```

---

### STAGE 9 & 10 — Send Real Messages from host1 to host2
- **Terminal 4 (host2 receiver):**
  ```bash
  sudo ip netns exec host2 nc -l 1234
  ```

- **Terminal 5 (host1 sender):**
  ```bash
  sudo ip netns exec host1 nc 10.0.2.2 1234
  ```
  Type the following messages and press `Enter` after each line:
  ```text
  Hello from host1!
  This is Alekhya
  Computer Networks Lab
  Three Point Capture Experiment
  Message traveling through router
  ```
  Observe the messages appearing in real-time in Terminal 4, and observe packet counters increasing in Terminals 1, 2, and 3.
  Once completed, press `Ctrl+C` in all terminals to stop netcat and tshark captures.

---

### STAGE 11 & 12 — Fix Capture Permissions and Verify Files
```bash
sudo chmod 644 /tmp/cap1.pcap /tmp/cap2.pcap /tmp/cap3.pcap
ls -lh /tmp/cap1.pcap /tmp/cap2.pcap /tmp/cap3.pcap
```

---

### STAGE 13 — TTL Analysis Across Vantage Points
Examine the IP Time-To-Live (TTL) field at each point:
```bash
echo "=== Point 1 (host1) TTL ==="
tshark -r /tmp/cap1.pcap -T fields -e ip.ttl -Y "ip" 2>/dev/null | sort | uniq -c

echo "=== Point 2 (router) TTL ==="
tshark -r /tmp/cap2.pcap -T fields -e ip.ttl -Y "ip" 2>/dev/null | sort | uniq -c

echo "=== Point 3 (host2) TTL ==="
tshark -r /tmp/cap3.pcap -T fields -e ip.ttl -Y "ip" 2>/dev/null | sort | uniq -c
```

**Observation & Analysis:**
- `cap1.pcap` (Point 1): Packets originate at host1 with default TTL = **64**.
- `cap2.pcap` (Point 2): Packets enter router interface `veth-r1` with TTL = **64**.
- `cap3.pcap` (Point 3): Packets arrive at host2 with TTL = **63**.
- **Theoretical Explanation:** In accordance with RFC 791, every intermediate router decrements the IP TTL header by at least 1 before forwarding to prevent routing loops.

---

### STAGE 14 — Payload & Performance Inspection

#### 1. Extract Transmitted Text from Packet Capture:
```bash
tshark -r /tmp/cap2.pcap -Y "tcp.port == 1234" -T fields -e tcp.payload 2>/dev/null | xxd -r -p
```
**Extracted Output:**
```text
Hello from host1!
This is Alekhya
Computer Networks Lab
Three Point Capture Experiment
Message traveling through router
```

#### 2. Check Delay Addition across Vantage Points:
```bash
tshark -r /tmp/cap1.pcap -Y "tcp.flags.syn==1 && tcp.flags.ack==0" -T fields -e frame.time_relative 2>/dev/null
tshark -r /tmp/cap2.pcap -Y "tcp.flags.syn==1 && tcp.flags.ack==0" -T fields -e frame.time_relative 2>/dev/null
tshark -r /tmp/cap3.pcap -Y "tcp.flags.syn==1 && tcp.flags.ack==0" -T fields -e frame.time_relative 2>/dev/null
```
- **Difference between `cap1` and `cap3`:** $\approx 20\text{ ms}$, corresponding exactly to the netem delay configured on `veth-r2`.

#### 3. Check TCP Retransmissions:
```bash
tshark -r /tmp/cap1.pcap -Y "tcp.analysis.retransmission" 2>/dev/null | wc -l
tshark -r /tmp/cap2.pcap -Y "tcp.analysis.retransmission" 2>/dev/null | wc -l
tshark -r /tmp/cap3.pcap -Y "tcp.analysis.retransmission" 2>/dev/null | wc -l
```
- When packets are dropped across `veth-r2` due to the 1% netem loss, `cap3.pcap` misses the dropped segment, triggering TCP duplicate ACKs and retransmissions from host1.

#### 4. Path RTT Verification with MTR:
```bash
sudo ip netns exec host1 mtr --report 10.0.2.2
```

---

## Graphical Wireshark Instructions
1. Open Wireshark on Ubuntu:
   ```bash
   wireshark /tmp/cap2.pcap &
   ```
2. **Filter by port:** Enter display filter `tcp.port == 1234`.
3. **Inspect IP TTL:** Expand `Internet Protocol Version 4` $\to$ verify `Time to Live: 64`.
4. **Inspect Payload:** Expand `Data` $\to$ verify message text `Hello from host1!`.
5. **Merge Captures:**
   - Go to `File` $\to$ `Merge...`
   - Select `cap1.pcap` and `cap3.pcap`.
6. **Add Custom TTL Column:**
   - Right-click column header $\to$ `Column Preferences` $\to$ click `+` (Add).
   - Title: `TTL`, Type: `Custom`, Field: `ip.ttl` $\to$ click `OK`.
   - Observe TTL changing from 64 to 63 across capture points.
7. **Expert Information:**
   - Go to `Analyze` $\to$ `Expert Information` to view packet loss warnings and TCP retransmissions.

---

## CLEANUP Procedure
```bash
sudo ip netns del host1
sudo ip netns del router
sudo ip netns del host2
sudo rm -f /tmp/cap1.pcap /tmp/cap2.pcap /tmp/cap3.pcap

# Verify all namespaces are removed
sudo ip netns list
```

---

## Viva Questions & Answers

1. **What is a Three-Point Packet Capture and why is it useful?**
   - Capturing traffic simultaneously at source, router, and destination allows network engineers to observe path-dependent modifications (e.g., TTL decrements, NAT changes, fragmentation), isolate where packet loss or latency occurs, and troubleshoot routing issues.

2. **Why does TTL decrease by 1 at the router?**
   - RFC 791 specifies that every router processing an IPv4 packet must decrement its Time-To-Live (TTL) field by 1. If TTL reaches 0, the packet is discarded and an ICMP Time Exceeded (Type 11) message is returned to the source, preventing packets from looping indefinitely.

3. **What is Linux Netem?**
   - Netem (Network Emulation) is an iproute2 traffic control queueing discipline that allows emulation of network properties such as transmission delay, jitter, packet loss, packet duplication, and packet reordering.

4. **What is a virtual Ethernet (veth) pair?**
   - A `veth` device is a local Ethernet tunnel represented as a pair of virtual network interfaces. Packets transmitted on one interface are immediately received on the peer interface, making them ideal for connecting Linux network namespaces.
