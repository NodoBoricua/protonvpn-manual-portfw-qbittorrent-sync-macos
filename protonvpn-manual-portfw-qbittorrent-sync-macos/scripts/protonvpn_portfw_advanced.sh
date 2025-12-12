#!/bin/bash
# =====================================================
# PORT FORWARDING PROTON VPN - SCRIPT AVANZADO
# =====================================================

echo "========================================"
echo "🚀 PORT FORWARDING AVANZADO - PROTON VPN"
echo "========================================"

# =====================================================
# CONFIGURACIÓN PRINCIPAL
# =====================================================
VPN_GATEWAY="10.2.0.1"
PYTHON_SCRIPT="/Library/Frameworks/Python.framework/Versions/3.12/lib/python3.12/site-packages/natpmp/natpmp_client.py"
LOG_FILE="$HOME/port_forwarding.log"
HISTORY_FILE="$HOME/vpn_port_history.log"
SESSION_LOG="/tmp/current_session.log"
PORT_FILE="/tmp/current_vpn_port.txt"
DASHBOARD_SCRIPT="$HOME/generate_dashboard.sh"

# Limpiar archivos de sesión al iniciar
> "$SESSION_LOG"
> "$PORT_FILE"
> "/tmp/vpn_current_stats.txt" 2>/dev/null || true

# =====================================================
# VARIABLES DE CONTROL
# =====================================================
start_time=$(date +%s)
success_count=0
error_count=0
vpn_disconnect_count=0
last_port=""
last_net_check=0
last_dashboard_check=0
last_qbit_check=0
error_streak=0
max_errors=20
error_streak_natpmp=0
max_natpmp_errors=1
natpmp_errors=0
vpn_disconnect_limit=20
natpmp_error_limit=1
PORT_CHANGES=0  # Nueva variable para contar cambios

# =====================================================
# FUNCIÓN PARA LOGGING
# =====================================================
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message"
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# =====================================================
# FUNCIÓN PARA GUARDAR ESTADÍSTICAS ACTUALES
# =====================================================
save_current_stats() {
    local stats_file="/tmp/vpn_current_stats.txt"
    {
        echo "# Estadísticas VPN actualizadas: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "CURRENT_PORT=$port"
        echo "SUCCESS_COUNT=$success_count"
        echo "ERROR_COUNT=$error_count"
        echo "VPN_DISC_COUNT=$vpn_disconnect_count"
        echo "PORT_CHANGES=$PORT_CHANGES"
        echo "LAST_UPDATE=$(date +%s)"
        echo "UPTIME=$(( $(date +%s) - start_time ))"
    } > "$stats_file"
    chmod 644 "$stats_file" 2>/dev/null
}

# =====================================================
# FUNCIÓN PARA CONTAR CAMBIOS DE PUERTO
# =====================================================
count_port_changes() {
    PORT_CHANGES=$(grep -c "\[CAMBIO\]" "$SESSION_LOG" 2>/dev/null || echo "0")
}

# =====================================================
# FUNCIÓN PARA REGENERAR DASHBOARD
# =====================================================
regenerate_dashboard() {
    if [ -f "$DASHBOARD_SCRIPT" ]; then
        # Asegurar permisos de ejecución
        chmod +x "$DASHBOARD_SCRIPT" 2>/dev/null
        
        # Guardar estadísticas actuales ANTES de generar dashboard
        save_current_stats
        
        # Ejecutar dashboard en background con logging
        bash "$DASHBOARD_SCRIPT" >> /tmp/dashboard_generation.log 2>&1 &
        local dashboard_pid=$!
        
        log_message "📊 Dashboard regenerado (PID: $dashboard_pid)"
        log_message "   📈 Stats: Puerto:$port | Éxitos:$success_count | Errores:$error_count | VPN Off:$vpn_disconnect_count"
        
        return 0
    else
        log_message "❌ ERROR: No se encuentra $DASHBOARD_SCRIPT"
        return 1
    fi
}

# =====================================================
# FUNCIÓN PARA VERIFICAR Y SINCRONIZAR PUERTO DE qBITTORRENT
# =====================================================
check_qbittorrent_port() {
    # Solo verificar si tenemos un puerto VPN válido
    if [[ -z "$port" ]] || [[ "$port" == "N/A" ]]; then
        return 1  # No hay puerto VPN disponible aún
    fi
    
    local instance=""
    local host=""
    local web_port=""
    local user=""
    local pass=""
    
    # Detectar qué instancia está activa
    if lsof -i :8081 > /dev/null 2>&1; then
        instance="private"
        host="localhost"
        web_port="8081"
        user="admin"
        pass="adminadmin"
    elif lsof -i :8080 > /dev/null 2>&1; then
        instance="public"
        host="localhost"
        web_port="8080"
        user="admin"
        pass="adminadmin"
    else
        return 1  # Ninguna instancia activa
    fi
    
    local url="http://$host:$web_port"
    local cookie_file="/tmp/qbit_check_$$_$(date +%s).txt"
    
    # Autenticar
    local login_response=$(curl -s -c "$cookie_file" -X POST \
        -d "username=$user&password=$pass" \
        "$url/api/v2/auth/login" 2>/dev/null)
    
    if [[ "$login_response" != "Ok." ]]; then
        rm -f "$cookie_file" 2>/dev/null
        return 1
    fi
    
    # Obtener puerto actual de qBittorrent
    local prefs_response=$(curl -s -b "$cookie_file" "$url/api/v2/app/preferences" 2>/dev/null)
    local qbit_port=$(echo "$prefs_response" | grep -o '"listen_port":[0-9]*' | cut -d: -f2)
    
    rm -f "$cookie_file" 2>/dev/null
    
    if [[ -z "$qbit_port" ]]; then
        return 1  # No se pudo obtener el puerto
    fi
    
    # Comparar puerto de qBittorrent con puerto VPN actual
    if [[ "$qbit_port" != "$port" ]]; then
        # HAY DISCREPANCIA: qBittorrent tiene un puerto diferente al VPN
        log_message "⚠️ DISCREPANCIA detectada: qBittorrent [$instance] tiene puerto $qbit_port pero VPN tiene $port"
        log_message "🔄 Sincronizando qBittorrent [$instance] al puerto VPN correcto: $port"
        
        # Actualizar qBittorrent al puerto VPN correcto
        if [ -f ~/update_qbittorrent.sh ] && [ -x ~/update_qbittorrent.sh ]; then
            QBT_RESULT_FILE="/tmp/qbit_sync_$$_$(date +%s).txt"
            
            # Ejecutar en background para no bloquear
            (
                ~/update_qbittorrent.sh "$port" "$instance" > "$QBT_RESULT_FILE" 2>&1
                QBT_EXIT_CODE=$?
                
                if [ $QBT_EXIT_CODE -eq 0 ]; then
                    if grep -q "✅ Puerto actualizado\|✅ Conectado" "$QBT_RESULT_FILE"; then
                        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ qBittorrent [$instance] sincronizado exitosamente: $qbit_port → $port" >> "$LOG_FILE"
                    else
                        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ qBittorrent [$instance] sincronización procesada" >> "$LOG_FILE"
                    fi
                else
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Error al sincronizar qBittorrent [$instance] (código: $QBT_EXIT_CODE)" >> "$LOG_FILE"
                fi
                
                # Limpiar después de 5 minutos
                sleep 300
                rm -f "$QBT_RESULT_FILE"
            ) &
            
            log_message "⏳ Sincronización de qBittorrent [$instance] iniciada en background"
        else
            log_message "❌ Script update_qbittorrent.sh no encontrado o no ejecutable"
        fi
        
        return 0
    else
        # Puerto coincide - todo está sincronizado
        log_message "✅ qBittorrent [$instance]: Puerto sincronizado = $qbit_port (VPN: $port)"
        return 0
    fi
}

# =====================================================
# VERIFICACIÓN INICIAL
# =====================================================
log_message "=== INICIANDO SCRIPT DE PORT FORWARDING ==="
log_message "Gateway VPN: $VPN_GATEWAY"
log_message "Script Python: $PYTHON_SCRIPT"
log_message "Dashboard Script: $DASHBOARD_SCRIPT"

if [ ! -f "$PYTHON_SCRIPT" ]; then
    log_message "❌ ERROR: No se encuentra el script Python"
    log_message "   Ejecuta: python3 -m pip install py-natpmp"
    exit 1
fi

# Verificar script de dashboard
if [ ! -f "$DASHBOARD_SCRIPT" ]; then
    log_message "⚠️  ADVERTENCIA: No se encuentra el script de dashboard"
    log_message "   Crear en: $DASHBOARD_SCRIPT"
fi

# =====================================================
# CREAR ENCABEZADO DEL HISTORIAL
# =====================================================
if [ ! -f "$HISTORY_FILE" ]; then
    {
        echo "# ==========================================="
        echo "# HISTORIAL DE CAMBIOS DE PUERTO"
        echo "# Script: protonvpn_portfw_vanzado.sh"
        echo "# Iniciado: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# VPN Gateway: $VPN_GATEWAY"
        echo "# ==========================================="
        echo ""
    } > "$HISTORY_FILE"
fi

log_message "✅ Todo verificado correctamente"
echo ""

# =====================================================
# BUCLE PRINCIPAL
# =====================================================
while true; do
    current_time_epoch=$(date +%s)

    # =================================================
    # VERIFICACIÓN DE CONEXIÓN A INTERNET
    # =================================================
    if [ $((current_time_epoch - last_net_check)) -ge 3600 ]; then
        if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
            log_message "🌐 Verificación: Conexión a internet OK"
        else
            log_message "⚠️  Verificación: Sin conexión a internet"
        fi
        last_net_check=$current_time_epoch
    fi

    # =================================================
    # VERIFICAR PUERTO DE qBITTORRENT (CADA 15 MINUTOS)
    # =================================================
    if [ $((current_time_epoch - last_qbit_check)) -ge 900 ]; then
        check_qbittorrent_port
        last_qbit_check=$current_time_epoch
    fi

    # =================================================
    # VERIFICAR CONEXIÓN VPN
    # =================================================
    if ping -c 1 -W 3 "$VPN_GATEWAY" > /dev/null 2>&1; then
        output=$(python3 "$PYTHON_SCRIPT" -g "$VPN_GATEWAY" 0 0 2>&1)

        if echo "$output" | grep -q "PortMapResponse"; then
            port=$(echo "$output" | grep -o "public port [0-9]*" | tail -1 | awk '{print $3}')
            
            # Verificar que el puerto no esté vacío
            if [ -z "$port" ]; then
                log_message "⚠️  ERROR: No se pudo obtener el puerto. Reintentando..."
                sleep 10
                continue
            fi
            
            success_count=$((success_count + 1))
            error_streak=0
            natpmp_errors=0

            uptime=$(( current_time_epoch - start_time ))
            hours=$(( uptime / 3600 ))
            minutes=$(( (uptime % 3600) / 60 ))

            log_message "✅ ACTIVO | Puerto: $port | Éxitos: $success_count | Errores: $error_count"
            log_message "   ⏱️  Tiempo activo: ${hours}h ${minutes}m | Desconexiones VPN: $vpn_disconnect_count"
            echo "✅ ACTIVO | Puerto: $port | Éxitos: $success_count | Errores: $error_count" >> "$SESSION_LOG"

            # Guardar puerto actual
            echo "$port" > "$PORT_FILE"

            # =================================================
            # REGISTRAR CAMBIO DE PUERTO
            # =================================================
            if [ -z "$last_port" ]; then
                historia_entry="[INICIO] $(date '+%Y-%m-%d %H:%M:%S') → Puerto: $port | T.Activo: 0h 0m"
                echo "$historia_entry" >> "$HISTORY_FILE"
                echo "[INICIO] $(date '+%Y-%m-%d %H:%M:%S') → Puerto: $port" >> "$SESSION_LOG"
                log_message "📝 Historial: Puerto inicial $port registrado"
                last_port="$port"
                
                # =================================================
                # NOTIFICAR qBittorrent (DETECCIÓN AUTOMÁTICA - PRIMER PUERTO)
                # =================================================
                if [ -f ~/update_qbittorrent.sh ] && [ -x ~/update_qbittorrent.sh ]; then
                    # Detectar qué instancia está activa
                    QBIT_INSTANCE="private"  # Por defecto
                    
                    if lsof -i :8081 > /dev/null 2>&1; then
                        QBIT_INSTANCE="private"
                        log_message "🔍 Instancia PRIVADA detectada (puerto 8081 activo)"
                    elif lsof -i :8080 > /dev/null 2>&1; then
                        QBIT_INSTANCE="public"
                        log_message "🔍 Instancia PÚBLICA detectada (puerto 8080 activo)"
                    else
                        log_message "⚠️ Ninguna instancia de qBittorrent activa, usando PRIVADA por defecto"
                        QBIT_INSTANCE="private"
                    fi
                    
                    log_message "🔄 Notificando a qBittorrent $QBIT_INSTANCE sobre puerto inicial: $port"
                    
                    # Crear archivo temporal para resultado
                    QBT_RESULT_FILE="/tmp/qbit_update_$$_$(date +%s).txt"
                    
                    # Ejecutar en background y verificar resultado después
                    (
                        ~/update_qbittorrent.sh "$port" "$QBIT_INSTANCE" > "$QBT_RESULT_FILE" 2>&1
                        QBT_EXIT_CODE=$?
                        
                        # Verificar resultado y loguear
                        if [ $QBT_EXIT_CODE -eq 0 ]; then
                            if grep -q "✅ Puerto actualizado\|✅ Conectado" "$QBT_RESULT_FILE"; then
                                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ qBittorrent $QBIT_INSTANCE actualizado exitosamente a puerto $port" >> "$LOG_FILE"
                            else
                                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ qBittorrent $QBIT_INSTANCE procesado: $(head -1 "$QBT_RESULT_FILE" 2>/dev/null | tr -d '\n' || echo 'verificar')" >> 
"$LOG_FILE"
                            fi
                        else
                            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Error al actualizar qBittorrent $QBIT_INSTANCE (código: $QBT_EXIT_CODE)" >> "$LOG_FILE"
                        fi
                        
                        # Guardar log completo para debugging
                        if [ -s "$QBT_RESULT_FILE" ]; then
                            cat "$QBT_RESULT_FILE" >> "$LOG_FILE"
                        fi
                        
                        # Limpiar después de 25 minutos
                        sleep 1500
                        rm -f "$QBT_RESULT_FILE"
                    ) &
                    # NOTIFICAR qBittorrent PRIVADO (MEJORADO - EN BACKGROUND)
                    log_message "⏳ qBittorrent $QBIT_INSTANCE actualizándose en background (archivo: $QBT_RESULT_FILE)"
                else
                    log_message "⚠️ Script qBittorrent no encontrado o no ejecutable"
                fi
                
            elif [ "$port" != "$last_port" ]; then
                historia_entry="[CAMBIO] $(date '+%Y-%m-%d %H:%M:%S') → $last_port → $port | T.Activo: ${hours}h ${minutes}m"
                echo "$historia_entry" >> "$HISTORY_FILE"
                echo "[CAMBIO] $(date '+%Y-%m-%d %H:%M:%S') → $last_port → $port" >> "$SESSION_LOG"
                log_message "🔄 Cambio de puerto: $last_port → $port"
                last_port="$port"
                PORT_CHANGES=$(( ${PORT_CHANGES:-0} + 1 ))
            
                # NOTIFICAR qBittorrent PRIVADO (MEJORADO - EN BACKGROUND)
                # NOTIFICAR qBittorrent (DETECCIÓN AUTOMÁTICA - CAMBIO DE PUERTO)
                # =================================================
                if [ -f ~/update_qbittorrent.sh ] && [ -x ~/update_qbittorrent.sh ]; then
                    # Detectar qué instancia está activa
                    QBIT_INSTANCE="private"  # Por defecto
                    
                    if lsof -i :8081 > /dev/null 2>&1; then
                        QBIT_INSTANCE="private"
                        log_message "🔍 Instancia PRIVADA detectada (puerto 8081 activo)"
                    elif lsof -i :8080 > /dev/null 2>&1; then
                        QBIT_INSTANCE="public"
                        log_message "🔍 Instancia PÚBLICA detectada (puerto 8080 activo)"
                    else
                        log_message "⚠️ Ninguna instancia de qBittorrent activa, usando PRIVADA por defecto"
                        QBIT_INSTANCE="private"
                    fi
                    
                    log_message "🔄 Notificando a qBittorrent $QBIT_INSTANCE sobre nuevo puerto: $port"
                    
                    # Crear archivo temporal para resultado
                    QBT_RESULT_FILE="/tmp/qbit_update_$$_$(date +%s).txt"
                    
                    # Ejecutar en background para no bloquear el script principal
                    (
                        ~/update_qbittorrent.sh "$port" "$QBIT_INSTANCE" > "$QBT_RESULT_FILE" 2>&1
                        QBT_EXIT_CODE=$?
                        
                        # Verificar resultado y loguear
                        if [ $QBT_EXIT_CODE -eq 0 ]; then
                            if grep -q "✅ Puerto actualizado\|✅ Conectado" "$QBT_RESULT_FILE"; then
                                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ qBittorrent $QBIT_INSTANCE actualizado exitosamente a puerto $port" >> "$LOG_FILE"
                            else
                                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ qBittorrent $QBIT_INSTANCE procesado: $(head -1 "$QBT_RESULT_FILE" 2>/dev/null || echo 'verificar')" >> "$LOG_FILE"
                            fi
                        else
                            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Error al actualizar qBittorrent $QBIT_INSTANCE (código: $QBT_EXIT_CODE)" >> "$LOG_FILE"
                        fi
                        
                        # Guardar log completo para debugging
                        if [ -s "$QBT_RESULT_FILE" ]; then
                            cat "$QBT_RESULT_FILE" >> "$LOG_FILE"
                        fi
                        
                        # Limpiar después de 35 minutos
                        sleep 2100
                        rm -f "$QBT_RESULT_FILE"
                    ) &
                    
                    log_message "⏳ qBittorrent $QBIT_INSTANCE actualizándose en background (archivo: $QBT_RESULT_FILE)"
                else
                    log_message "⚠️ Script qBittorrent no encontrado o no ejecutable"
                fi
            fi

            # =================================================
            # ACTUALIZAR CONTADORES Y ESTADÍSTICAS
            # =================================================
            count_port_changes
            save_current_stats

            # =================================================
            # REGENERAR DASHBOARD (CADA 5 MINUTOS)
            # =================================================
            if [ $((current_time_epoch - last_dashboard_check)) -ge 300 ]; then
                regenerate_dashboard
                last_dashboard_check=$current_time_epoch
            fi

            sleep 60

        else
            error_count=$((error_count + 1))
            error_streak=$((error_streak + 1))
            natpmp_errors=$((natpmp_errors + 1))
            log_message "⚠️  ERROR NAT-PMP (#$error_count) | Esperando 30s"
            echo "ERROR NAT-PMP" >> "$SESSION_LOG"
            
            # Actualizar estadísticas incluso en errores
            count_port_changes
            save_current_stats

            if [ $natpmp_errors -ge $natpmp_error_limit ]; then
                log_message "🔄 NAT-PMP falló ($natpmp_errors), reiniciando script..."
                sleep 5
                exec "$0"
            fi

            if [ $error_streak -ge $max_errors ]; then
                log_message "🔄 Demasiados errores consecutivos, reiniciando script..."
                sleep 10
                exec "$0"
            fi

            sleep 30
        fi

    else
        vpn_disconnect_count=$((vpn_disconnect_count + 1))
        error_streak=$((error_streak + 1))
        log_message "❌ VPN DESCONECTADA (#$vpn_disconnect_count) | Esperando 60s"
        echo "VPN DESCONECTADA" >> "$SESSION_LOG"
        
        # Actualizar estadísticas incluso en desconexiones
        count_port_changes
        save_current_stats

        if [ $vpn_disconnect_count -gt $vpn_disconnect_limit ]; then
            log_message "🔄 Más de $vpn_disconnect_limit desconexiones VPN, reiniciando script..."
            sleep 5
            exec "$0"
        fi

        sleep 60
    fi
done
