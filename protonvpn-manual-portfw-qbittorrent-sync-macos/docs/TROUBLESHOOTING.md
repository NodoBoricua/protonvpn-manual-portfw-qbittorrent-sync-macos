# 🔧 Solución de Problemas - ProtonVPN Port Forwarding macOS

```bash
# 🔧 Problemas de Instalación

# Error: "Python not found"
python3 --version
open https://www.python.org/downloads/
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install python@3.12

# Error: "pip: command not found"
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
rm get-pip.py
python3 -m pip --version

# Error: "ModuleNotFoundError: No module named 'natpmp'"
python3 -m pip uninstall py-natpmp -y
python3 -m pip install py-natpmp --force-reinstall
python3 -c "import natpmp; print(natpmp.__file__)"

# Error: "Permission denied" al ejecutar scripts
chmod +x scripts/*.sh
chmod +x tools/*.sh
chmod 755 scripts/protonvpn_portfw_advanced.sh
chmod 755 tools/install.sh

# Error: "Command not found" después de instalar
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
~/vpn-portforwarding-macos/scripts/protonvpn_portfw_simple.sh

# 🔗 Problemas de Conexión VPN

# WireGuard no se conecta
cat ~/Downloads/*.conf | head -10
pkill WireGuard
sleep 5
open -a WireGuard

# Error: "No se puede contactar al gateway 10.2.0.1"
ifconfig | grep -A2 utun
ping -c 4 10.2.0.1
ping -c 4 10.2.0.2
ping -c 4 10.5.0.1
netstat -rn | grep utun

# La VPN se desconecta frecuentemente
ping -c 100 10.2.0.1 | grep "packet loss"
sudo ifconfig en0 down
sudo ifconfig en0 up
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# 🔄 Problemas de Port Forwarding

# Error: "gateway does not support NAT-PMP"
if ping -c 1 -W 2 10.2.0.1 &> /dev/null; then
    echo "✅ VPN conectada"
else
    echo "❌ VPN desconectada"
fi
python3 $(python3 -m pip show py-natpmp | grep Location | awk '{print $2}')/natpmp/natpmp_client.py -g 10.2.0.1 0 0
./scripts/protonvpn_portfw_simple.sh
./scripts/protonvpn_portfw_advanced.sh

# El puerto no se actualiza automáticamente
ps aux | grep protonvpn_portfw
tail -f ~/port_forwarding.log
./tools/update_port.sh
cat /tmp/current_vpn_port.txt

# Error: "No se puede mapear el puerto"
pkill -f protonvpn_portfw
./scripts/protonvpn_portfw_advanced.sh

# 🧲 Problemas con qBittorrent

# qBittorrent no se conecta al puerto
VPN_PORT=$(cat /tmp/current_vpn_port.txt 2>/dev/null)
echo "Puerto VPN: $VPN_PORT"
QBITTORRENT_CONFIG="$HOME/Library/Application Support/qBittorrent/qBittorrent.conf"
QB_PORT=$(grep "Connection\\\PortRangeMin" "$QBITTORRENT_CONFIG" | cut -d= -f2)
echo "Puerto qBittorrent: $QB_PORT"
if [ "$VPN_PORT" != "$QB_PORT" ]; then
    ./scripts/qbittorrent_sync.sh "$VPN_PORT"
fi

# Estado "Firewalled" en qBittorrent
PORT=$(cat /tmp/current_vpn_port.txt)
open "https://portchecker.co/check?port=$PORT"
curl -s "https://portchecker.co/check?port=$PORT" | grep -o "open\|closed"

# qBittorrent no inicia con perfil privado
ls -la ~/qbt_perfil_privado/
chmod 700 ~/qbt_perfil_privado/
/Applications/qBittorrent.app/Contents/MacOS/qBittorrent --profile="$HOME/qbt_perfil_privado"

# 📊 Problemas del Dashboard

ls -la scripts/create_dashboard_fixed.sh
chmod +x scripts/create_dashboard_fixed.sh
./scripts/create_dashboard_fixed.sh
ls -la ~/vpn_dashboard.html
crontab -l | grep create_dashboard
(crontab -l 2>/dev/null; echo "*/5 * * * * cd $(pwd) && ./scripts/create_dashboard_fixed.sh >/dev/null 2>&1") | crontab -
tail -f ~/port_forwarding.log | grep -i dashboard

# 💻 Problemas del Sistema

xattr -d com.apple.quarantine scripts/*.sh
xattr -d com.apple.quarantine tools/*.sh
xattr -l scripts/protonvpn_portfw_advanced.sh

sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/qBittorrent.app

top -o cpu -n 5 | grep -E "(python|qBittorrent|WireGuard)"
ps aux | grep -E "(protonvpn_portfw|natpmp_client)" | grep -v grep
pkill -f protonvpn_portfw
sleep 2
./scripts/protonvpn_portfw_advanced.sh

which -a python3
/usr/bin/python3 --version
ls -la /usr/local/bin/python3
ls -la /usr/bin/python3

# 🚨 Errores Específicos y Soluciones

PYTHON_PATH=$(python3 -m pip show py-natpmp | grep Location | awk '{print $2}')
if [ -d "$PYTHON_PATH/natpmp" ]; then
    cd "$PYTHON_PATH/natpmp"
else
    python3 -m pip uninstall py-natpmp -y
    python3 -m pip install py-natpmp
fi

sudo chown -R $(whoami) ~/vpn-portforwarding-macos
chmod -R 755 scripts/
chmod -R 755 tools/

sleep 30
./scripts/protonvpn_portfw_simple.sh

lsof -ti:8080 | xargs kill -9 2>/dev/null
lsof -ti:8081 | xargs kill -9 2>/dev/null

tail -f ~/port_forwarding.log
grep -i "error\|fail\|❌" ~/port_forwarding.log
grep -c "✅ ACTIVO" ~/port_forwarding.log
grep -c "❌ VPN" ~/port_forwarding.log
PORT=$(cat /tmp/current_vpn_port.txt 2>/dev/null)
[ -n "$PORT" ] && echo "https://portchecker.co/check?port=$PORT"
bash -x scripts/protonvpn_portfw_advanced.sh
./scripts/protonvpn_portfw_advanced.sh 2>&1 | tee debug.log
pkill -f "qBittorrent|WireGuard|protonvpn"
sleep 5
./tools/install.sh
./scripts/protonvpn_portfw_advanced.sh
./scripts/protonvpn_portfw_simple.sh
tail -n 50 ~/port_forwarding.log
tail -n 50 /tmp/current_session.log

