# 🎯 GUÍA: Port Forwarding Manual con Proton VPN en macOS 🍎

**Experiencia personal y solución a errores comunes | macOS Monterey**

---

## ⚠️ AVISO PRÁCTICO

Esta guía es 100% funcional, pero implica usar **Terminal**, **Python**, **Scripts** y configuración manual de **WireGuard**. Se asume conocimiento básico de línea de comandos. A través de la guía 
verás notas con advertencias, soluciones a errores reales y pasos verificados.

---

## 📌 ÍNDICE RÁPIDO

1. [Introducción y contexto](#1--introducción-y-contexto)
2. [Requisitos previos](#2--requisitos-previos)
3. [Configuración de WireGuard](#3--configuración-de-wireguard)
4. [Activación manual de Port Forwarding](#4-️-activación-manual-de-port-forwarding)
5. [Comando simple corregido](#5--comando-simple-corregido-100-funciona)
6. [Configuración de qBittorrent](#6-️-configuración-de-qbittorrent)
7. [Script mejorado para usuarios avanzados](#7--script-mejorado-para-usuarios-avanzados)
8. [Problemas encontrados y soluciones técnicas](#8--para-usuarios-técnicos-que-quieren-entender-las-posibles-causas-y-el-porqué)
9. [Monitoreo y mantenimiento](#9--monitoreo-y-mantenimiento)
10. [Preguntas frecuentes](#10--preguntas-frecuentes)
11. [Recursos adicionales oficiales](#11--recursos-adicionales-oficiales)
12. [Conclusión y agradecimientos](#12--conclusión-y-agradecimientos)

---

## 1. 🚀 INTRODUCCIÓN Y CONTEXTO

Después de adquirir **[Proton VPN Plus](https://protonvpn.com/pricing)** durante las ofertas del Black Friday 🛒, descubrí que la aplicación oficial para macOS **no incluye la opción de Port 
Forwarding automático** en su interfaz, ya que según Proton VPN: *"Currently, port forwarding on macOS is an early-access feature"* (*"Actualmente, el reenvío de puertos en macOS es una función en 
acceso anticipado"*). Esto me llevó a investigar cómo configurarlo manualmente, documentando todo el proceso para compartirlo con la comunidad.

### ¿Por qué es importante el Port Forwarding para torrents?

- ✅ Permite conectarse con más peers (mayor conectividad)
- ✅ Esencial para mantener una buena ratio en trackers privados
- ✅ Aumenta la eficiencia en la distribución de archivos
- ✅ Necesario para que otros usuarios puedan conectarse a ti

> **⚠️ NOTA IMPORTANTE:** Esta guía está específicamente probada en **macOS Monterey 12.7.4**, pero debería funcionar en versiones similares. Documento mi experiencia real incluyendo errores y 
soluciones.

---

## 2. 📋 REQUISITOS PREVIOS

Antes de comenzar, necesitas:

- 💻 **macOS** (Probado en Monterey)
- 🔐 **Cuenta Proton VPN Plus** (con soporte para Port Forwarding)
- 🐍 **Python 3** instalado (viene preinstalado en macOS)
- 📡 **Conexión a internet estable**
- ⌚ **Tiempo y paciencia** (aproximadamente 10-20 minutos)
- 🔧 **Terminal** (aplicación incluida en macOS)

### Verifica que tienes Python instalado:

```bash
python3 --version
```

Deberías ver algo como: `Python 3.12.x`

---

## 3. 🔧 CONFIGURACIÓN DE WIREGUARD

El primer paso es configurar WireGuard manualmente:

1. Visita la **[guía oficial de Proton VPN](https://protonvpn.com/support/wireguard-manual-macos/)**
2. Sigue cuidadosamente las instrucciones para:
   - Descargar el perfil de configuración desde tu cuenta Proton
   - Instalar WireGuard desde:
     - [Mac App Store](https://apps.apple.com/us/app/wireguard/id1451685025?mt=12)
     - [Página oficial](https://www.wireguard.com/install/)
   - Importar el perfil en WireGuard
   - Conectarte a un servidor compatible con Port Forwarding

### 🔍 Cómo identificar servidores compatibles:

- En la app de Proton VPN, busca servidores marcados con **"P2P"**
- O busca **"PORT FORWARDING"** en la descripción
- Los servidores en **Países Bajos, Suiza y Suecia** suelen tener soporte

> **💡 CONSEJO CRÍTICO:** Anota la dirección IP del gateway que aparece en WireGuard. Generalmente es **10.2.0.1** pero puede variar. La necesitarás para los próximos pasos.

---

## 4. ⚙️ ACTIVACIÓN MANUAL DE PORT FORWARDING

### 📊 DIAGRAMA DEL PROCESO

```
macOS → WireGuard → Proton VPN → Script Python → Port Forwarding Activo
```

Sigue EXACTAMENTE estos pasos de la **[guía oficial de Proton VPN](https://protonvpn.com/support/port-forwarding-manual-setup/)**:

### Paso 1: Descargar el instalador de pip

```bash
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
```

Deberías ver algo similar a:

```
% Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 2644k  100 2644k    0     0  1544k      0  0:00:01  0:00:01 --:--:-- 1546k
```

### Paso 2: Instalar pip

```bash
python3 get-pip.py
```

Deberías ver algo similar a:

```
Collecting pip
  Downloading pip-24.0-py3-none-any.whl (2.1 MB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 2.1/2.1 MB 1.2 MB/s eta 0:00:00
Collecting wheel
  Downloading wheel-0.42.0-py3-none-any.whl (65 kB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 65.2/65.2 kB 1.8 MB/s eta 0:00:00
Installing collected packages: wheel, pip
Successfully installed pip-24.0 wheel-0.42.0
```

### Paso 3: Instalar py-natpmp

```bash
python3 -m pip install py-natpmp
```

Deberías ver algo similar a:

```
Collecting py-natpmp
  Downloading py_natpmp-0.2.5-py3-none-any.whl (9.1 kB)
Installing collected packages: py-natpmp
Successfully installed py-natpmp-0.2.5
```

### Paso 4: Ejecutar el comando oficial de Proton VPN

```bash
cd "$(python3 -m pip show py-natpmp | grep Location | cut -d\  -f 2)/natpmp" && while true ; do date ; python3 natpmp_client.py -g 10.2.0.1 0 0 || { echo -e "ERROR with natpmpc command \a" ; break ; 
} ; sleep 45 ; done
```

### ✅ Si todo funciona correctamente, deberías ver esto en tu terminal:

![Terminal Output](https://res.cloudinary.com/dbulfrlrz/images/w_1024,h_408,c_scale/f_auto,q_auto/v1721662669/wp-vpn/macos-natpmpc/macos-natpmpc.png?_i=AA)

- **✅ Eso es lo que deberías ver** cuando el script funciona correctamente
- **🔢 El número 39669** es el puerto que debes usar en tu cliente
- **📋 Cópialo exactamente** para configurar qBittorrent como se describe en la sección #7

> **⚠️ IMPORTANTE:** El Port Forwarding ya está activado. Necesitas dejar la ventana de Terminal abierta para que el script continúe funcionando. Para desactivar la notificación de sonido (bell) 
cada vez que el script se repite:
> 
> 1. **Terminal** → **Settings**
> 2. Pestaña **Profiles** → **Advanced**
> 3. **Bell** → desmarca **"Audible Bell"**

---

## 🚨 ¡EN EL PASO #4 ME SALIÓ ESTE ERROR!

```bash
cd: no such file or directory: Location: /Library/Frameworks/Python.framework/Versions/3.12/lib/python3.12/site-packages/natpmp
```

*→ Se debe a ruta incorrecta en el comando oficial de Proton*

### 🔽 ¿QUÉ HACER ANTE EL ERROR? 🔽

### ¡SOLUCIÓN INMEDIATA!

## ⚡ EN LA PRÓXIMA SECCIÓN EL COMANDO QUE YA ESTÁ CORREGIDO, FUNCIONA SIN MÁS COMPLICACIONES!

---

## 5. 🎯 COMANDO SIMPLE CORREGIDO (100% FUNCIONA)

Este es el comando que he estado utilizando después de superar las primeras 24 horas de configuración inicial. Desde entonces, nunca más he vuelto a experimentar el error "The gateway does not 
support NAT-PMP". Lo he empleado durante más de tres días consecutivos y funciona impecablemente, cumpliendo su función de port forwarding sin inconvenientes.

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

### ✅ Eso es lo que deberías ver cuando el script funciona correctamente

![Terminal Output](https://res.cloudinary.com/dbulfrlrz/images/w_1024,h_408,c_scale/f_auto,q_auto/v1721662669/wp-vpn/macos-natpmpc/macos-natpmpc.png?_i=AA)

- **🔢 El número 39669** es el puerto que debes usar en tu cliente
- **📋 Cópialo exactamente** para configurar qBittorrent

---

<details>
<summary><b>🎯 HAZ CLIC PARA VER CÓMO USAR EL COMANDO SIMPLE PASO A PASO</b></summary>

1. Copia y pega todo el bloque en Terminal
2. Presiona Enter
3. Si tu gateway es diferente a `10.2.0.1`, cámbialo en el comando (mayormente no es diferente)
4. Deja la Terminal abierta mientras usas torrents

</details>

<details>
<summary><b>🔍 HAZ CLIC PARA VER POR QUÉ FUNCIONA MEJOR</b></summary>

- ✅ Primero verifica si la VPN está conectada (`ping -c 1 -W 3 10.2.0.1`)
- ✅ Solo intenta NAT-PMP si la VPN está activa
- ✅ Maneja errores de forma elegante con reintentos
- ✅ Proporciona feedback claro del estado
- ✅ Evita el error "gateway does not support NAT-PMP"

</details>

---

## 6. ⚙️ CONFIGURACIÓN DE qBITTORRENT

### 🎯 CONFIGURACIÓN RÁPIDA DE qBittorrent:

1. **📂 Abre qBittorrent** → "Preferences / Preferencias" (⌘+,)
2. **🔗 Ve a "Connection / Conexión"** en la barra lateral
3. **📋 Copia el puerto** de la Terminal (ej: 39669)
4. **🔢 Pégalo** en "Port used for incoming connections / Puerto usado para conexiones entrantes"
5. **❌ Desmarca** "Use UPnP / NAT-PMP port forwarding / Usar reenvío de puertos UPnP/NAT-PMP"
6. **⚙️ Ve a "Advanced / Avanzado"** en la barra lateral
7. **🌐 En "Network interface / Interfaz de red"** selecciona: `utun2` o `utun3`
   - *Para identificar tu interfaz usa en la terminal el comando:* 
     ```bash
     ifconfig | grep utun
     ```
8. **🔒 En "Optional IP address / Dirección IP opcional"** déjalo en "All addresses / Todas las direcciones"
9. **✅ Haz clic en "Apply / Aplicar"** y luego **"OK / Aceptar"**

> **💡 CONSEJO IMPORTANTE:** Cada vez que el script asigne un puerto nuevo (Verificar periódicamente, ya que en ocasiones pueden pasar muchas horas manteniendo el mismo puerto, pero si hay varias 
interrupciones de conexión, es posible que cambie), deberás actualizarlo manualmente en qBittorrent.

---

## 7. 🚀 SCRIPT MEJORADO PARA USUARIOS AVANZADOS

> **Nota:** Para quienes desean más funcionalidades (logging, estadísticas, etc.), aquí está mi script mejorado.

<details>
<summary><b>🛠️ HAZ CLIC PARA VER CARACTERÍSTICAS DEL SCRIPT AVANZADO</b></summary>

- 📊 **Logging completo** en archivo `~/port_forwarding.log`
- 📈 **Estadísticas** de éxitos, errores y desconexiones
- ⏱️ **Tiempo activo** calculado automáticamente
- 💾 **Puerto guardado** en `/tmp/current_vpn_port.txt` para fácil acceso
- 🔧 **Verificación inicial** de que todo está instalado correctamente
- 🚨 **Manejo robusto** de todos los tipos de errores

</details>

<details>
<summary><b>🔧 HAZ CLIC PARA VER CÓMO USAR EL SCRIPT AVANZADO - GUÍA PARA PRINCIPIANTES PASO A PASO COMPLETO</b></summary>

1. **Crear el archivo del script:**
   
   Escribe exactamente esto y presiona Enter:
   ```bash
   nano ~/vpn_advanced.sh
   ```
   Se abrirá el editor de texto Nano dentro de la Terminal.

2. **Pegar el código del script:**
   - Ve al **Script Avanzado** (está en la próxima sección) y cópialo TODO (desde `#!/bin/bash` hasta el final)
   - Vuelve a la Terminal
   - Haz clic derecho → Pegar, o presiona **⌘+V**
   - Deberías ver todo el código pegado en Nano

3. **Guardar el archivo:**
   - Presiona **Ctrl+X** (para salir)
   - Te preguntará: "Save modified buffer?"
   - Presiona **Y** (Yes/Sí)
   - Te pedirá el nombre de archivo (ya está puesto)
   - Presiona **Enter** para confirmar

4. **Dar permisos de ejecución:**
   
   Escribe esto y presiona Enter:
   ```bash
   chmod +x ~/vpn_advanced.sh
   ```
   No verás mensaje de confirmación (es normal).

5. **Ejecutar el script (OPCIÓN A - Terminal visible):**
   
   Escribe esto y presiona Enter:
   ```bash
   ~/vpn_advanced.sh
   ```
   ✅ Deberías ver los mensajes del script funcionando.
   ⚠️ No cierres esta ventana de Terminal.

6. **Ejecutar en segundo plano (OPCIÓN B - Terminal oculta):**
   
   Si prefieres que la Terminal no esté visible:
   ```bash
   nohup ~/vpn_advanced.sh > /dev/null 2>&1 &
   ```
   ✅ El script sigue corriendo aunque cierres Terminal.
   🔍 Para ver los logs después: 
   ```bash
   tail -f ~/port_forwarding.log
   ```

7. **🔍 VERIFICACIÓN DE QUE FUNCIONA:**
   - Verás mensajes como "✅ ACTIVO | Puerto: XXXXX"
   - Se creará el archivo: `~/port_forwarding.log`
   - Para detener el script: Presiona **Ctrl+C** en la Terminal

</details>

<details>
<summary><b>🛠️ HAZ CLIC PARA VER EL SCRIPT AVANZADO</b></summary>

```bash
#!/bin/bash

# ============================================
# PORT FORWARDING PROTON VPN - SCRIPT AVANZADO
# Incluye logging, estadísticas y mejor manejo de errores
# ============================================

echo "========================================"
echo "🚀 PORT FORWARDING AVANZADO - PROTON VPN"
echo "========================================"

# CONFIGURACIÓN
VPN_GATEWAY="10.2.0.1"
PYTHON_SCRIPT="/Library/Frameworks/Python.framework/Versions/3.12/lib/python3.12/site-packages/natpmp/natpmp_client.py"
LOG_FILE="$HOME/port_forwarding.log"

# ESTADÍSTICAS
start_time=$(date +%s)
success_count=0
error_count=0
vpn_disconnect_count=0

# FUNCIÓN PARA LOGGING
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message"
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# VERIFICACIÓN INICIAL
log_message "=== INICIANDO SCRIPT DE PORT FORWARDING ==="
log_message "Gateway VPN: $VPN_GATEWAY"
log_message "Script Python: $PYTHON_SCRIPT"

if [ ! -f "$PYTHON_SCRIPT" ]; then
    log_message "❌ ERROR: No se encuentra el script Python"
    log_message "   Ejecuta: python3 -m pip install py-natpmp"
    exit 1
fi

log_message "✅ Todo verificado correctamente"
echo ""

# BUCLE PRINCIPAL
while true; do
    current_time=$(date '+%H:%M:%S')
    
    # Verificar conexión VPN
    if ping -c 1 -W 3 "$VPN_GATEWAY" > /dev/null 2>&1; then
        # VPN CONECTADA - Intentar port forwarding
        output=$(python3 "$PYTHON_SCRIPT" -g "$VPN_GATEWAY" 0 0 2>&1)
        
        if echo "$output" | grep -q "PortMapResponse"; then
            # ÉXITO: Extraer puerto
            port=$(echo "$output" | grep -o "public port [0-9]*" | tail -1 | awk '{print $3}')
            success_count=$((success_count + 1))
            
            # Calcular tiempo activo
            uptime=$(( $(date +%s) - start_time ))
            hours=$(( uptime / 3600 ))
            minutes=$(( (uptime % 3600) / 60 ))
            
            log_message "✅ ACTIVO | Puerto: $port | Éxitos: $success_count | Errores: $error_count"
            log_message "   ⏱️  Tiempo activo: ${hours}h ${minutes}m | Desconexiones VPN: $vpn_disconnect_count"
            
            # Guardar puerto en archivo temporal
            echo "$port" > /tmp/current_vpn_port.txt
            
            sleep 45
        else
            # ERROR en NAT-PMP
            error_count=$((error_count + 1))
            log_message "⚠️  ERROR NAT-PMP (#$error_count) | Esperando 30s"
            sleep 30
        fi
    else
        # VPN DESCONECTADA
        vpn_disconnect_count=$((vpn_disconnect_count + 1))
        log_message "❌ VPN DESCONECTADA (#$vpn_disconnect_count) | Esperando 60s"
        sleep 60
    fi
done
```

</details>

<details>
<summary><b>🔍 HAZ CLIC PARA VER LOS ARCHIVOS Y FUNCIONES DEL SCRIPT</b></summary>

### 🎯 PROPÓSITO PRINCIPAL:
Este script mantiene activo el Port Forwarding de forma automática, manejando errores y desconexiones sin intervención manual.

### 📂 ARCHIVOS QUE CREA:

1. **~/port_forwarding.log** - Archivo principal de registro
   - Guarda TODO lo que sucede (éxitos, errores, desconexiones)
   - Formato: `[2024-12-01 14:30:45] ✅ ACTIVO | Puerto: 39669`
   - Útil para diagnosticar problemas
   - Crece con el tiempo (puedes borrarlo si es muy grande)

2. **/tmp/current_vpn_port.txt** - Puerto actual disponible
   - Contiene SOLO el número de puerto actual (ej: `39669`)
   - Se actualiza cada vez que se obtiene un puerto nuevo
   - Ubicación temporal (se borra al reiniciar la Mac)
   - Para verlo rápido: `cat /tmp/current_vpn_port.txt`

### 📊 ESTADÍSTICAS QUE LLEVA:

- ✅ **Éxitos:** Veces que obtuvo un puerto correctamente
- ⚠️ **Errores NAT-PMP:** Fallos temporales del protocolo
- ❌ **Desconexiones VPN:** Veces que perdió conexión con el gateway
- ⏱️ **Tiempo activo:** Cuánto lleva funcionando (horas:minutos)

### 🔄 CÓMO FUNCIONA EL BUCLE (cada ~45 segundos):

1. **SI está conectada → Intenta obtener puerto**
   - Éxito: Guarda puerto, actualiza estadísticas, espera 45s
   - Error NAT-PMP: Registra error, espera 30s, reintenta

2. **SI NO está conectada → Espera reconexión**
   - Registra desconexión, espera 60s, vuelve a verificar

### 🔒 CARACTERÍSTICAS DE SEGURIDAD:

- ✅ **Verificación inicial:** Comprueba que todo esté instalado
- ✅ **Manejo de errores:** No se detiene ante fallos temporales
- ✅ **Logging completo:** Todo queda registrado para revisión
- ✅ **Puerto temporal:** Guardado en `/tmp/` (se borra al reiniciar)

### 👁️ EJEMPLO DE LO QUE VERÁS EN TERMINAL:

```
[2024-12-01 14:30:45] ✅ ACTIVO | Puerto: 39669 | Éxitos: 15 | Errores: 2
   ⏱️  Tiempo activo: 2h 15m | Desconexiones VPN: 1
[2024-12-01 14:31:30] ✅ ACTIVO | Puerto: 39669 | Éxitos: 16 | Errores: 2
   ⏱️  Tiempo activo: 2h 16m | Desconexiones VPN: 1
```

</details>

---

## 8. ❌ Para usuarios técnicos que quieren entender las posibles causas y el porqué: 🛠️

<details>
<summary><b>🚀 HAZ CLIC PARA VER DETALLES TÉCNICOS COMPLETOS</b></summary>

El problema tiene DOS capas:

### CAPA 1: Error en el parsing del comando

El comando de Proton usa `cut -d\  -f 2` que no maneja correctamente los espacios en la salida de `pip show` en macOS.

### CAPA 2: Ruta incompleta incluso si el parsing funcionara

Si examinamos manualmente dónde se instaló todo:

1. Primero, verifica dónde se instaló el paquete:
   ```bash
   python3 -m pip show py-natpmp | grep Location
   ```
   
   Verás:
   ```
   Location: /Library/Frameworks/Python.framework/Versions/3.12/lib/python3.12/site-packages
   ```

2. Ahora, verifica qué hay realmente en ese directorio:
   ```bash
   ls -la "/Library/Frameworks/Python.framework/Versions/3.12/lib/python3.12/site-packages/" | grep natpmp
   ```
   
   Verás DOS entradas:
   ```
   drwxr-xr-x    6 usuario  staff     192 Nov 29 14:43 natpmp
   drwxr-xr-x   11 usuarios staff     352 Nov 29 14:43 py_natpmp-0.2.5.dist-info
   ```

3. Exploremos el directorio `natpmp`:
   ```bash
   ls -la "/Library/Frameworks/Python.framework/Versions/3.12/lib/python3.12/site-packages/natpmp/"
   ```
   
   Contenido real:
   ```
   -rw-r--r--   1 usuario  staff   1024 Nov 29 14:43 natpmp_client.py
   -rw-r--r--   1 usuario  staff  20506 Nov 29 14:43 NATPMP.py
   -rw-r--r--   1 usuario  staff     28 Nov 29 14:43 __init__.py
   ```

### El error fundamental:

- ✅ **Lo que Proton intenta:** `cd .../site-packages/natpmp/` (cambiar al directorio)
- ❌ **Lo que realmente necesita:** Ejecutar `.../site-packages/natpmp/natpmp_client.py` (el archivo Python)

### Comprobación con comando directo:

```bash
# Esto muestra la ruta COMPLETA que necesitas:
echo "python3 $(python3 -m pip show py-natpmp | grep Location | cut -d' ' -f2)/natpmp/natpmp_client.py -g 10.2.0.1 0 0"
```

**Mi solución práctica:** Usar la ruta completa manualmente en el script.

</details>

<details>
<summary><b>⚠️ HAZ CLIC PARA VER DETALLES DEL PROBLEMA 2: Error NAT-PMP</b></summary>

### PROBLEMA 2: Error "The gateway does not support NAT-PMP"

```
natpmp.NATPMP.NATPMPUnsupportedError: (-11, 'The gateway does not support NAT-PMP')
```

### Mi experiencia REAL paso a paso:

**FASE 1 (Primeras 24 horas):**
- Usaba el comando básico de Proton (con la ruta corregida)
- **Funcionaba bien por horas** (3-12 horas continuas)
- **Pero ocasionalmente fallaba** con el error NAT-PMP
- Cuando fallaba, el script SE DETENÍA completamente
- Tenía que reiniciarlo manualmente cada vez

**FASE 2 (Después del día 1):**
- Modifiqué el script (sencillo) para que:
  1. Primero verifique la VPN con `ping`
  2. Si la VPN está desconectada, espere 60s en lugar de fallar
  3. Si NAT-PMP falla, reintente en 30s en lugar de detenerse
- **Resultado:** El error NAT-PMP **DESAPARECIÓ COMPLETAMENTE**
- El script ahora se recupera automáticamente de desconexiones temporales

**FASE 3 (A partir del cuarto día):**
Realicé pruebas exhaustivas con el script (avanzado) y, tras confirmar su funcionamiento, comencé a utilizarlo regularmente. Este es el script que les comparto actualmente y que sigue operando 
correctamente como se espera.

### Análisis técnico del error NAT-PMP:

El mensaje es engañoso. En realidad significa:
- "No puedo contactar al gateway 10.2.0.1" (VPN desconectada)
- NO "Tu gateway no soporta el protocolo NAT-PMP"

### Por qué el script mejorado funciona:

```
ANTES (falla con desconexiones breves):
VPN desconecta por 2 segundos → Script intenta NAT-PMP → Error → Script muere

DESPUÉS (sobrevive a desconexiones):
VPN desconecta por 2 segundos → Ping falla → "VPN desconectada" → Espera 60s → VPN se reconecta → Continúa normal
```

</details>

---

## 9. 📊 MONITOREO Y MANTENIMIENTO

<details>
<summary><b>📈 HAZ CLIC PARA VER COMANDOS DE MONITOREO</b></summary>

### Comandos útiles para monitoreo:

**Ver puerto actual (si usas script avanzado):**
```bash
cat /tmp/current_vpn_port.txt
```

**Ver logs del script avanzado (actualización en tiempo real):**
```bash
tail -f ~/port_forwarding.log
```

**Verificar si el puerto está realmente abierto:**
```bash
puerto=$(cat /tmp/current_vpn_port.txt)
resultado=$(curl -s "https://portchecker.co/check?port=$puerto" | grep -o "open\|closed")
echo "Puerto $puerto: $resultado"
```

**Ver procesos del script:**
```bash
ps aux | grep vpn_advanced
```

</details>

<details>
<summary><b>🔧 HAZ CLIC PARA VER SOLUCIÓN DE PROBLEMAS</b></summary>

### Solución de problemas comunes:

1. **"VPN desconectada" aparece frecuentemente:**
   - Verifica que WireGuard esté conectado
   - Revisa tu conexión a internet
   - Intenta cambiar a otro servidor Proton

2. **El puerto no aparece como "open" en portchecker:**
   - Espera 1-2 minutos después de iniciar el script
   - Verifica que no haya firewall bloqueando
   - Prueba reiniciando WireGuard

3. **El script se detiene inesperadamente:**
   - Verifica logs con `tail -f ~/port_forwarding.log`
   - Revisa si hay actualizaciones de Python pendientes
   - Ejecútalo de nuevo simplemente

</details>

<details>
<summary><b>✅ SEÑALES DE QUE FUNCIONA CORRECTAMENTE</b></summary>

- 📊 **Éxitos > 0:** Al menos un ciclo obtuvo puerto
- 📁 **Archivos creados:** Existen ambos archivos
- 🔗 **Puerto válido:** Número entre 10000-65535
- 📝 **Logs completos:** Información detallada en el log

### ❌ SEÑALES DE PROBLEMAS

- ⚠️ **0 éxitos:** Ningún ciclo obtuvo puerto
- 🚫 **"VPN desconectada":** Problemas de conexión VPN
- 💥 **Errores Python:** py-natpmp no instalado correctamente
- 🔒 **Permisos denegados:** Script sin permisos de ejecución

### 🔄 SI EL SCRIPT AVANZADO FALLA:

1. Primero detén cualquier script con **Ctrl+C**
2. Vuelve al **Comando Simple** de la sección 5 (siempre funciona)

</details>

---

## 10. ❓ PREGUNTAS FRECUENTES

<details>
<summary><b>❓ ¿Por qué el comando oficial de Proton no funciona en mi Mac?</b></summary>

El comando oficial de Proton VPN tiene un error en la ruta del script. En lugar de eso, usa el comando corregido de la sección 5 que funciona siempre.

</details>

<details>
<summary><b>❓ ¿Hay otra forma de solucionarlo además del comando que muestras?</b></summary>

La solución universal es usar el comando corregido. Otras opciones podrían ser:

- Ajustar manualmente la ruta en el comando de Proton
- Crear un enlace simbólico a la ubicación esperada
- Usar el script avanzado de la sección 7

Pero el comando de la sección 5 es la solución más simple y directa.

</details>

<details>
<summary><b>❓ ¿Por qué mi puerto cambia?</b></summary>

Es por diseño de Proton VPN para mayor seguridad y rotación de puertos. No se puede desactivar.

</details>

<details>
<summary><b>❓ ¿Puedo usar un puerto fijo?</b></summary>

No, Proton VPN no permite puertos fijos en su implementación actual.

</details>

<details>
<summary><b>❓ ¿Qué hago si el script dice "VPN desconectada" pero WireGuard muestra conectado?</b></summary>

Espera 60 segundos (o más tiempo), generalmente se reconecta automáticamente. Si persiste, reinicia WireGuard.

</details>

<details>
<summary><b>❓ ¿Necesito pagar por Proton VPN Plus?</b></summary>

Sí, el Port Forwarding solo está disponible en planes Plus y superiores.

</details>

<details>
<summary><b>❓ ¿Puedo cerrar la Terminal después de ejecutar el script?</b></summary>

No, a menos que uses `nohup` como se explica en la sección 7.

</details>

<details>
<summary><b>❓ ¿Afecta esto a mi velocidad de internet normal?</b></summary>

✅ **Sí, toda tu conexión pasa por la VPN.** En macOS, Proton VPN no tiene split tunneling en su app oficial (al menos en mi versión). Esto significa que:

- 🌐 **Todo el tráfico** (torrents + navegación) usa la VPN
- 📉 **Posible reducción** de velocidad por el cifrado VPN
- 🔒 **Mayor privacidad** ya que todo está protegido
- ⚡ **Consejo:** Usa servidores cercanos para mejor velocidad

</details>

<details>
<summary><b>❓ ¿Es seguro usar Port Forwarding con VPN?</b></summary>

Sí, porque estás detrás de la VPN de Proton. No expones tu IP real, solo la de Proton.

</details>

---

## 11. 🔗 RECURSOS ADICIONALES OFICIALES

<details>
<summary><b>📚 HAZ CLIC PARA VER RECURSOS OFICIALES DE PROTON VPN</b></summary>

- **📚 Sobre Port Forwarding:** [Port Forwarding - Documentación oficial](https://protonvpn.com/support/port-forwarding)
- **⚠️ Seguridad:** [Port forwarding security considerations](https://protonvpn.com/support/port-forwarding-risks)
- **🛠️ Para routers:** [How to set up port forwarding on various routers](https://protonvpn.com/blog/port-forwarding/)

> **Nota:** Estos recursos son útiles para entender el contexto general, pero recuerda que esta guía se enfoca específicamente en la configuración manual para macOS con WireGuard.

</details>

---

## 12. 🎉 CONCLUSIÓN Y AGRADECIMIENTOS

<details>
<summary><b>📝 HAZ CLIC PARA VER CONCLUSIÓN COMPLETA</b></summary>

### Resumen de mi experiencia:

1. **Día 1:** Comando oficial falla → Error de ruta macOS → Script básico falla → Error "gateway does not support NAT-PMP"
2. **Día 2:** Script con verificación VPN → FUNCIONA PERFECTAMENTE
3. **Día 3+:** Comencé a usar el **script avanzado** (con archivo de logs y puerto) → **Funciona perfectamente desde entonces**.

### Estadísticas después de 1 semana:

- Tiempo activo máximo: 14+ horas continuas

---

### **• Para la mayoría:** Usa el **comando simple corregido** (sección 5)

### **• Para power users:** Usa el **script avanzado** (sección 7)

### **• Importante:** Actualiza manualmente el puerto en qBittorrent cuando cambie

### **• Recordatorio:** Deja Terminal abierta o usa `nohup ~/vpn_advanced.sh > /dev/null 2>&1 &` para segundo plano (sección 7)

---

### 🙏 Agradecimientos:

A la comunidad por compartir conocimiento, a los desarrolladores de software libre, y a todos los que mantienen vivo el espíritu de compartir archivos "legalmente".¡Agradecido infinitamente!

Y a todos los de la comunidad que siempre tienen ánimo para ayudar a nosotros los novatos. Espero que esto les guste, pero sobre todo, que sea de gran ayuda en su educación.

---

## ¡Que tengas excelentes ratios y mucha paciencia con los puertos cambiantes! 🎯🚀

</details>

---

**Guía basada en experiencia real | MacBook (late 2010) macOS Monterey 12.7.4 | Proton VPN Plus | Diciembre 2025**

*¿Te sirvió la guía? ¿Tienes otra solución? ¡Comparte tu experiencia!* 💬👇
