#!/bin/sh
IFACE=$(ip route show default | awk '{print $5}' | head -1)
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $IFACE -j MASQUERADE
iptables -A INPUT -p udp -m udp --dport 51820 -j ACCEPT
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -A FORWARD -o wg0 -j ACCEPT
ip6tables -t nat -A POSTROUTING -s fd00::/64 -o $IFACE -j MASQUERADE
ip6tables -A FORWARD -i wg0 -j ACCEPT
ip6tables -A FORWARD -o wg0 -j ACCEPT
