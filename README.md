# 🎯 ProtonVPN Port Forwarding para macOS

> Configuración manual de Port Forwarding con Proton VPN en macOS usando WireGuard

[![macOS](https://img.shields.io/badge/macOS-Monterey%2B-000000?style=flat&logo=apple)](https://www.apple.com/macos/)
[![ProtonVPN](https://img.shields.io/badge/Proton%20VPN-Plus-6d4aff?style=flat)](https://protonvpn.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📋 Tabla de Contenidos

- [Introducción](#-introducción)
- [Características](#-características)
- [Requisitos](#-requisitos)
- [Instalación Rápida](#-instalación-rápida)
- [Uso](#-uso)
- [Scripts Disponibles](#-scripts-disponibles)
- [Configuración de qBittorrent](#-configuración-de-qbittorrent)
- [Solución de Problemas](#-solución-de-problemas)
- [FAQ](#-faq)
- [Contribuir](#-contribuir)
- [Licencia](#-licencia)

## 🚀 Introducción

La aplicación oficial de Proton VPN para macOS no incluye Port Forwarding automático en su interfaz(Currently, port forwarding on macOS is an early-access feature). Este repositorio proporciona 
scripts y guías para configurarlo manualmente usando WireGuard y Python.

### ¿Por qué es importante?

- ✅ Mejor conectividad con peers en torrents
- ✅ Mayor eficiencia en distribución de archivos
- ✅ Permite que otros usuarios se conecten a ti

## ✨ Características

### Versión Simple
- ✅ Comando único que funciona inmediatamente
- ✅ Manejo automático de reconexiones VPN
- ✅ Reintentos inteligentes ante errores

### Versión Avanzada
- 📊 Dashboard web con estadísticas en tiempo real
- 🔄 Sincronización automática con qBittorrent (instancias privada/pública)
- 📈 Métricas del sistema (CPU, RAM, temperatura, batería)
- 📝 Logging completo y persistente
- 🎯 Detección automática de instancias de qBittorrent (publica que es app normal o privado cuando se crea un perfil aparte)
- 🔍 Verificación y corrección automática de discrepancias de puerto
- ⚡ Manejo robusto de errores y desconexiones

## 📋 Requisitos

- 💻 macOS Monterey 12.7.4+ (probado, debería funcionar en versiones similares)
- 🔐 Cuenta Proton VPN Plus o superior
- 🐍 Python 3.x (preinstalado en macOS)
- 📡 Conexión a internet estable
- 🔧 Conocimientos básicos de Terminal

## ⚡ Instalación Rápida

### 1. Verificar Python

```bash
python3 --version
```
### 2. Configurar WireGuard

Sigue la [guía oficial de Proton VPN](https://protonvpn.com/support/wireguard-manual-macos/) para:
- Descargar el perfil de configuración
- Instalar WireGuard
- Conectarte a un servidor compatible (busca "P2P" o "PORT FORWARDING")

### 3. Instalar dependencias (usar el isntall.sh y hace esto automaticamente)

```bash
# Descargar pip
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py

# Instalar pip
python3 get-pip.py

# Instalar py-natpmp
python3 -m pip install py-natpmp
```

### 4. Clonar este repositorio (seguir guia y copiar los script sin no quieres clonar)

```bash
git clone https://github.com/NodoBoricua/protonvpn-manual-portfw-qbittorrent-sync-macos.git
cd protonvpn-manual-portfw-qbittorrent-sync-macos
```

## 🎯 Uso

### Opción 1: Comando Simple (Recomendado para principiantes)

```bash
while true; do
    date
    if ping -c 1 -W 3 10.2.0.1 > /dev/null 2>&1; then
        python3 /Library/Frameworks/Python.framework/Versions/3.12/lib/python3.12/site-packages/natpmp/natpmp_client.py -g 10.2.0.1 0 0 && {
            echo "✅ Port forwarding ACTIVO - $(date)"
        } || {
            echo "⚠️ Falló NAT-PMP, reintentando en 30s..."
            sleep 30
        }
    else
        echo "❌ VPN desconectada - esperando 60s"
        sleep 60
    fi
    sleep 45
done
```

**Nota:** Anota el número de puerto que aparece (ej: `39669`) para configurar qBittorrent (intrucciones adelante).

## 🔧 Configuración de qBittorrent

### Configuración Manual

1. **Preferences** (⌘+,) → **Connection**
2. Pega el puerto de la Terminal en "Port used for incoming connections"
3. **Desmarca** "Use UPnP / NAT-PMP port forwarding"
4. **Advanced** → **Network interface**: selecciona `utun2` o `utun3`
   ```bash
   # Para identificar tu interfaz:
   ifconfig | grep utun
   ```
5. **Optional IP address**: "All addresses"
6. **Apply** y **OK**

### Configuración Automática (Script Avanzado)


### Opción 2: Script Avanzado con Dashboard

```bash
# Dar permisos de ejecución
chmod +x scripts/*.sh

# Ejecutar script principal
./scripts/proton_avanzado_final.sh
```

Esto iniciará:
- ✅ Monitoreo continuo del port forwarding
- ✅ Sincronización automática con qBittorrent
- ✅ Generación de dashboard cada 5 minutos
- ✅ Verificación periódica de discrepancias de puerto

**Ver el dashboard:**
```bash
open ~/vpn_dashboard.html
```

## 📦 Scripts Disponibles

### `/scripts/`

| Script | Descripción | Uso |
|--------|-------------|-----|
| `protonvpn_portfw_simple.sh` | Script simple con funcionalidades basica pero no actualiza automaticamente el puerto | `./scripts/protonvpn_portfw_simple.sh` |
| `protonvpn_portfw_advanced.sh` | Script principal con todas las funcionalidades | `./scripts/protonvpn_portfw_advanced.sh` |
| `update_qbittorrent.sh` | Actualiza puerto en qBittorrent (automático) | `./scripts/update_qbittorrent.sh <puerto> [instancia]` |
| `generate_dashboard.sh` | Genera dashboard HTML con métricas | Ejecutado automáticamente |

### Archivos generados

- `~/port_forwarding.log` - Log principal con todos los eventos
- `~/vpn_port_history.log` - Historial de cambios de puerto
- `~/vpn_dashboard.html` - Dashboard web con estadísticas
- `/tmp/current_vpn_port.txt` - Puerto actual (temporal)
- `/tmp/current_session.log` - Log de la sesión actual
- `/tmp/vpn_current_stats.txt` - Estadísticas sincronizadas

El script detecta automáticamente (activar web UI en cliente qbittorrent):
- ✅ Qué instancia de qBittorrent está activa (privada en puerto 8081 o pública en 8080)
- ✅ Sincroniza el puerto automáticamente al detectar cambios
- ✅ Verifica discrepancias cada 5 minutos y corrige automáticamente

**Instancias soportadas (activar web UI en qbittorrent):**
- 🔒 **Privada**: Puerto WebUI 8081 (usuario: `admin`, pass: `adminadmin`)
- 🌐 **Pública**: Puerto WebUI 8080 (usuario: `admin`, pass: `adminadmin`)

**Verificar estado manualmente:**
```bash
./scripts/update_qbittorrent.sh --status
```

## 🛠️ Solución de Problemas

### Error: "Location: not found"

**Causa:** Error en el parsing del comando oficial de Proton VPN.

**Solución:** Usa el comando simple corregido o los scripts de este repo.

### Error: "gateway does not support NAT-PMP"

**Causa:** VPN temporalmente desconectada o servidor no compatible.

**Solución:**
1. Verifica que WireGuard esté conectado
2. Confirma que el servidor soporte Port Forwarding (busca "P2P")
3. Usa el comando simple que maneja este error automáticamente

### Puerto "firewalled" en qBittorrent

**Causa:** qBittorrent necesita tiempo para verificar el puerto.

**Solución:**
- Espera 1-2 minutos después de cambiar el puerto
- El script avanzado reanuncia torrents automáticamente
- Verifica que el puerto en qBittorrent coincida con el de la Terminal
- Si no se tiene conexion entrante ni saliente se queda en estado firewalled (llama de fuego color amarilla)
### Dashboard no se actualiza

**Verificar:**
```bash
# Ver si el script está corriendo
ps aux | grep protonvpn_portfw

# Ver logs recientes
tail -f ~/port_forwarding.log

# Regenerar manualmente
~/generate_dashboard.sh
```

## ❓ FAQ

<details>
<summary><b>¿Por qué el comando oficial de Proton no funciona?</b></summary>

El comando oficial tiene un error en el parsing de la ruta en macOS. Los scripts de este repo corrigen ese problema.
</details>

<details>
<summary><b>¿El puerto cambia frecuentemente?</b></summary>

Sí, es por diseño de Proton VPN para mayor seguridad. El script avanzado maneja esto automáticamente sincronizando con qBittorrent.
</details>

<details>
<summary><b>¿Puedo usar un puerto fijo?</b></summary>

No, Proton VPN no permite puertos fijos actualmente.
</details>

<details>
<summary><b>¿Puedo cerrar la Terminal?</b></summary>

Con el comando simple: No.

Con el script avanzado en background:
```bash
nohup ./scripts/protonvpn_portfw_advanced.sh > /dev/null 2>&1 &
```
</details>

<details>
<summary><b>¿Afecta mi velocidad de internet?</b></summary>

Sí, toda tu conexión pasa por la VPN. En macOS, Proton VPN no tiene split tunneling en la app oficial. Usa servidores cercanos para mejor velocidad.
</details>

<details>
<summary><b>¿Es seguro?</b></summary>

Sí, estás detrás de la VPN de Proton. No expones tu IP real, solo la IP de Proton.
</details>

## 📊 Características del Dashboard

El dashboard web incluye:

### Métricas VPN
- 🔒 Puerto actual sincronizado con qBittorrent
- ✅ Contador de éxitos NAT-PMP
- ⚠️ Contador de errores
- 🔌 Contador de desconexiones VPN
- 🔄 Contador de cambios de puerto
- 📜 Historial completo de cambios

### Métricas del Sistema (macOS)
- 🔥 Temperatura de CPU
- 🔋 Estado y porcentaje de batería
- 💻 Uso de CPU
- 🧠 Uso de RAM
- 💾 Uso de disco
- ⏱️ Uptime del sistema

### Eventos en Tiempo Real
- 📝 Últimos 10 eventos de la sesión actual
- 🎨 Codificación por colores (éxitos, errores, cambios)
- 🔍 Identificación de eventos de qBittorrent

### Actualización Automática
- ⚡ Dashboard se regenera cada 5 minutos
- 🔄 Página se auto-recarga cada 320 segundos
- 📊 Estadísticas sincronizadas en tiempo real

## 🤝 Contribuir

¡Las contribuciones son bienvenidas!

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Áreas donde puedes contribuir

- 📝 Mejorar documentación
- 🐛 Reportar bugs
- ✨ Agregar nuevas características
- 🧪 Probar en otras versiones de macOS
- 🌍 Traducciones

## 📝 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

## 🙏 Agradecimientos

- A la comunidad de Proton VPN por el soporte
- A los desarrolladores de py-natpmp
- A todos en la comunidad que ayudan a los novatos

## 📚 Recursos Adicionales

- [Documentación oficial de Proton VPN Port Forwarding](https://protonvpn.com/support/port-forwarding)
- [Guía de WireGuard en macOS](https://protonvpn.com/support/wireguard-manual-macos/)
- [Consideraciones de seguridad](https://protonvpn.com/support/port-forwarding-risks)

---

<div align="center">

**¿Te sirvió este proyecto?** ⭐ Dale una estrella en GitHub

Hecho con ❤️ para la comunidad de macOS y Proton VPN

[Reportar Bug](https://github.com/NodoBoricua/protonvpn-manual-portfw-qbittorrent-sync-macos/issues) · [Solicitar 
Feature](https://github.com/NodoBoricua/protonvpn-manual-portfw-qbittorrent-sync-macos/issues) · 
[Discusiones](https://github.com/NodoBoricua/protonvpn-manual-portfw-qbittorrent-sync-macos/discussions)

</div>
