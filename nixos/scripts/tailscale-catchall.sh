#!/bin/bash
echo "=== Descobrindo IPs para Tailscale + Docker ==="
echo ""

echo "1. IP Tailscale do Host:"
tailscale ip -4
echo ""

echo "2. Hostname Tailscale:"
tailscale status | grep $(hostname) | awk '{print $2}'
echo ""

echo "3. IP Local do Host:"
ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1
echo ""

echo "4. Redes Docker:"
docker network ls --format "{{.Name}}" | while read network; do
  echo "  Network: $network"
  docker network inspect $network --format '    Subnet: {{range .IPAM.Config}}{{.Subnet}}{{end}}'
done
echo ""

echo "5. Containers Rodando:"
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -v "PORTS"
echo ""

echo "6. IPs dos Containers:"
docker ps -q | while read container; do
  name=$(docker inspect $container --format '{{.Name}}' | sed 's/\///')
  ip=$(docker inspect $container --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
  ports=$(docker port $container | tr '\n' ' ')
  echo "  $name:"
  echo "    IP Container: $ip"
  echo "    Portas: $ports"
done
