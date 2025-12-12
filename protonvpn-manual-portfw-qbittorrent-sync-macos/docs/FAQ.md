# ❓ FAQ - ProtonVPN Port Forwarding macOS

```bash
# Instalación

# Pregunta: ¿Cómo instalo Python y pip si no los tengo?
# Respuesta:
# Python: https://www.python.org/downloads/ o brew install python@3.12
# Pip: curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3 get-pip.py

# Pregunta: ¿Por qué recibo "ModuleNotFoundError: No module named 'natpmp'"?
# Respuesta:
python3 -m pip uninstall py-natpmp -y
python3 -m pip install py-natpmp --force-reinstall

# Conexión VPN

# Pregunta: WireGuard no se conecta, ¿qué hago?
# Respuesta: Descargar e importar un perfil nuevo, eliminar perfiles antiguos, verificar credenciales
cat ~/Downloads/*.conf | head -10
pkill WireGuard
sleep 5
open -a WireGuard

# Pregunta: La VPN se desconecta frecuentemente, ¿por qué?
ping -c 100 10.2.0.1 | grep "packet loss"
sudo ifconfig en0 down
sudo ifconfig en0 up
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Port Forwarding

# Pregunta: Recibo "gateway does not support NAT-PMP", ¿qué hago?
if ping -c 1 -W 2 10.2.0.1 &> /dev/null; then echo "✅ VPN conectada"; else echo "❌ VPN desconectada"; fi
python3 $(python3 -m pip show py-natpmp | grep Location | awk '{print $2}')/natpmp/natpmp_client.py -g 10.2.0.1 0 0
./scripts/protonvpn_portfw_simple.sh

# Pregunta: El puerto no se actualiza automáticamente
ps aux | grep protonvpn_portfw
tail -f ~/port_forwarding.log
./tools/update_port.sh
cat /tmp/current_vpn_port.txt

# qBittorrent

# Pregunta: qBittorrent está en estado "Firewalled"
PORT=$(cat /tmp/current_vpn_port.txt)
open "https://portchecker.co/check?port=$PORT"
curl -s "https://portchecker.co/check?port=$PORT" | grep -o "open\|closed"

# Pregunta: qBittorrent no inicia con perfil privado
ls -la ~/qbt_perfil_privado/
chmod 700 ~/qbt_perfil_privado/
/Applications/qBittorrent.app/Contents/MacOS/qBittorrent --profile="$HOME/qbt_perfil_privado"

# Dashboard

# Pregunta: El dashboard no se genera ni se actualiza
ls -la scripts/create_dashboard_fixed.sh
chmod +x scripts/create_dashboard_fixed.sh
./scripts/create_dashboard_fixed.sh
(crontab -l 2>/dev/null; echo "*/5 * * * * cd $(pwd) && ./scripts/create_dashboard_fixed.sh >/dev/null 2>&1") | crontab -

# Sistema

# Pregunta: macOS bloquea la ejecución de scripts
xattr -d com.apple.quarantine scripts/*.sh
xattr -d com.apple.quarantine tools/*.sh

# Pregunta: El firewall bloquea conexiones
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/qBittorrent.app

# Pregunta: Problemas con múltiples versiones de Python
which -a python3
/usr/bin/python3 --version
ls -la /usr/local/bin/python3
ls -la /usr/bin/python3

