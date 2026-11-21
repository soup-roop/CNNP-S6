#!/usr/bin/env bash
# ==============================================================================
# CNNP Skill 4: Setup Network Topology for Client and Server
# Configures 2 namespaces: server (192.168.1.10) and client (192.168.1.20)
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root (sudo ./setup_network.sh)"
    exit 1
fi

echo "[*] Cleaning up existing namespaces..."
ip netns del server 2>/dev/null || true
ip netns del client 2>/dev/null || true

echo "[*] Creating namespaces: server and client..."
ip netns add server
ip netns add client

echo "[*] Creating virtual Ethernet link pair..."
ip link add veth-srv type veth peer name veth-cli

echo "[*] Moving interfaces to namespaces..."
ip link set veth-srv netns server
ip link set veth-cli netns client

echo "[*] Configuring IP addresses..."
ip netns exec server ip addr add 192.168.1.10/24 dev veth-srv
ip netns exec server ip link set veth-srv up
ip netns exec server ip link set lo up

ip netns exec client ip addr add 192.168.1.20/24 dev veth-cli
ip netns exec client ip link set veth-cli up
ip netns exec client ip link set lo up

echo "[*] Testing baseline connectivity..."
ip netns exec client ping -c 3 192.168.1.10

echo "[+] Setup successfully completed!"
