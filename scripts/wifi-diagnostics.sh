#!/usr/bin/env bash

echo "=== WiFi Diagnostics ==="
echo

echo "Current Connection:"
/nix/store/h91szsp5bk28zddrdp3y0bpl7nx9pkj4-networkmanager-1.54.1/bin/nmcli device wifi list | grep "^\*"
echo

echo "Signal Quality:"
cat /proc/net/wireless
echo

echo "Link Information:"
/nix/store/qdxkgwjm7y18zmh0zw27kay9fvxrjnqf-iw-6.17/bin/iw dev wlp62s0 link 2>/dev/null || echo "iw command not available"
echo

echo "Latency Test:"
/nix/store/0rfz69vp1nl0q2hxzig20hc60sk72z62-curl-8.17.0-bin/bin/curl -w "\nTempo DNS: %{time_namelookup}s\nTempo conexão: %{time_connect}s\nTempo total: %{time_total}s\n" -o /dev/null -s https://1.1.1.1
echo

echo "DNS Query Time:"
/nix/store/bd8jw6zxag35dwkb046cqv43dqnl1s3r-bind-9.20.15-dnsutils/bin/dig @1.1.1.1 google.com | grep "Query time"
