#!/bin/bash
echo "🔍 DIAGNÓSTICO COMPLETO DEL SISTEMA"
echo "====================================="

echo "1. Sistema:"
echo "   macOS: $(sw_vers -productVersion)"
echo "   Shell: $SHELL"
echo "   Usuario: $(whoami)"

echo ""
echo "2. Python:"
which python3
python3 --version
python3 -m pip list | grep -E "(pip|py-natpmp)"

echo ""
echo "3. VPN:"
ifconfig | grep -A1 utun
ping -c 2 10.2.0.1

echo ""
echo "4. Port Forwarding:"
ls -la /tmp/current_vpn_port.txt 2>/dev/null && echo "Puerto: $(cat 
/tmp/current_vpn_port.txt)"
ps aux | grep -E "(natpmp|protonvpn)" | grep -v grep

echo ""
echo "5. qBittorrent:"
ps aux | grep qBittorrent | grep -v grep
ls -la "/Applications/qBittorrent.app" 2>/dev/null && echo "✅ Instalado"

echo ""
echo "6. Dashboard:"
ls -la ~/vpn_dashboard.html 2>/dev/null && echo "✅ Existe" || echo "❌ No 
existe"
