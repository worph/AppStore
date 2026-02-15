#!/bin/sh
IFACE=$(ip route show default | awk '{print $5}' | head -1)
iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o $IFACE -j MASQUERADE
iptables -D INPUT -p udp -m udp --dport 51820 -j ACCEPT
iptables -D FORWARD -i wg0 -j ACCEPT
iptables -D FORWARD -o wg0 -j ACCEPT
ip6tables -t nat -D POSTROUTING -s fd00::/64 -o $IFACE -j MASQUERADE
ip6tables -D FORWARD -i wg0 -j ACCEPT
ip6tables -D FORWARD -o wg0 -j ACCEPT
