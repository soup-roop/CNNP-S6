#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 2: Setup 3-Node Network Namespace Topology
# Topology: host1 (10.0.1.1/30) <-> router (10.0.1.2/30, 10.0.2.1/30) <-> host2 (10.0.2.2/30)
# ==============================================================================

set -euo pipefail

# Ensure script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root (sudo ./setup_network.sh)"
    exit 1
fi

echo "[*] Cleaning up any existing namespaces..."
ip netns del host1 2>/dev/null || true
ip netns del router 2>/dev/null || true
ip netns del host2 2>/dev/null || true

echo "[*] Stage 2: Creating network namespaces..."
ip netns add host1
ip netns add router
ip netns add host2

echo "[*] Creating virtual Ethernet (veth) cable pairs..."
ip link add veth-h1 type veth peer name veth-r1
ip link add veth-r2 type veth peer name veth-h2

echo "[*] Assigning veth endpoints to namespaces..."
ip link set veth-h1 netns host1
ip link set veth-r1 netns router
ip link set veth-r2 netns router
ip link set veth-h2 netns host2

echo "[*] Stage 3: Configuring IP addresses and bringing links UP..."
# Host1 Configuration
ip netns exec host1 ip addr add 10.0.1.1/30 dev veth-h1
ip netns exec host1 ip link set veth-h1 up
ip netns exec host1 ip link set lo up

# Router Configuration
ip netns exec router ip addr add 10.0.1.2/30 dev veth-r1
ip netns exec router ip addr add 10.0.2.1/30 dev veth-r2
ip netns exec router ip link set veth-r1 up
ip netns exec router ip link set veth-r2 up
ip netns exec router ip link set lo up

# Host2 Configuration
ip netns exec host2 ip addr add 10.0.2.2/30 dev veth-h2
ip netns exec host2 ip link set veth-h2 up
ip netns exec host2 ip link set lo up

echo "[*] Stage 4: Enabling IPv4 routing on router..."
ip netns exec router sysctl -w net.ipv4.ip_forward=1 >/dev/null

echo "[*] Adding static routing entries..."
ip netns exec host1 ip route add 10.0.2.0/30 via 10.0.1.2
ip netns exec host2 ip route add 10.0.1.0/30 via 10.0.2.1

echo "[*] Stage 5: Verifying basic connectivity (host1 -> host2)..."
ip netns exec host1 ping -c 3 10.0.2.2

echo "[*] Stage 6: Injecting network impairment (delay 20ms, loss 1%) on router veth-r2..."
ip netns exec router tc qdisc add dev veth-r2 root netem delay 20ms loss 1%

echo "[*] Current tc configuration on veth-r2:"
ip netns exec router tc qdisc show dev veth-r2

echo "[+] Network topology setup complete successfully!"
