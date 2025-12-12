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
