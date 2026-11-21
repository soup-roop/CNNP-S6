#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 3: Setup 3-Node Topology with Bottleneck Queue (TBF)
# Topology: sender (192.168.10.2) <-> router (192.168.10.1, 192.168.20.1) <-> receiver (192.168.20.2)
# Bottleneck: TBF 5 Mbps, burst 32kb, limit 64kb on router r-eth1
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root (sudo ./setup_topology.sh)"
    exit 1
fi

echo "[*] Cleaning up old namespaces if present..."
ip netns del sender 2>/dev/null || true
ip netns del router 2>/dev/null || true
ip netns del receiver 2>/dev/null || true

echo "[*] Creating network namespaces..."
ip netns add sender
ip netns add router
ip netns add receiver

echo "[*] Creating veth pairs..."
ip link add s-eth0 type veth peer name r-eth0
ip link add r-eth1 type veth peer name rec-eth0

echo "[*] Connecting interfaces to namespaces..."
ip link set s-eth0 netns sender
ip link set r-eth0 netns router
ip link set r-eth1 netns router
ip link set rec-eth0 netns receiver

echo "[*] Configuring IP addresses..."
ip netns exec sender ip addr add 192.168.10.2/24 dev s-eth0
ip netns exec sender ip link set s-eth0 up
ip netns exec sender ip link set lo up

ip netns exec router ip addr add 192.168.10.1/24 dev r-eth0
ip netns exec router ip addr add 192.168.20.1/24 dev r-eth1
ip netns exec router ip link set r-eth0 up
ip netns exec router ip link set r-eth1 up
ip netns exec router ip link set lo up

ip netns exec receiver ip addr add 192.168.20.2/24 dev rec-eth0
ip netns exec receiver ip link set rec-eth0 up
ip netns exec receiver ip link set lo up

echo "[*] Enabling IPv4 forwarding on router..."
ip netns exec router sysctl -w net.ipv4.ip_forward=1 >/dev/null

echo "[*] Adding routes..."
ip netns exec sender ip route add 192.168.20.0/24 via 192.168.10.1
ip netns exec receiver ip route add 192.168.10.0/24 via 192.168.20.1

echo "[*] Testing baseline connectivity..."
ip netns exec sender ping -c 3 192.168.20.2

echo "[*] Configuring 5 Mbps Token Bucket Filter (TBF) on router r-eth1..."
ip netns exec router tc qdisc replace dev r-eth1 root tbf rate 5mbit burst 32kb limit 64kb

echo "[*] Current TBF qdisc status:"
ip netns exec router tc -s qdisc show dev r-eth1

echo "[+] Setup successfully completed!"
