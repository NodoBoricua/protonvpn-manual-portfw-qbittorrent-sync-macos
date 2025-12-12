#!/bin/bash
# =====================================================
# SCRIPT: update_qbittorrent.sh - VERSIÓN SIMPLIFICADA
# =====================================================

# CONFIGURACIÓN
QB_PRIVATE_HOST="localhost"
QB_PRIVATE_PORT="8081"
QB_PRIVATE_USER="admin"
QB_PRIVATE_PASS="adminadmin"

QB_PUBLIC_HOST="localhost"
QB_PUBLIC_PORT="8080"
QB_PUBLIC_USER="admin"
QB_PUBLIC_PASS="adminadmin"

DEFAULT_INSTANCE="private"
LOG_FILE="$HOME/port_forwarding.log"

# COLORES
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# LOG
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[${timestamp}] [qBittorrent] $1"
    echo "$message" | tee -a "$LOG_FILE"
}

# AUTENTICAR
authenticate() {
    local host="$1"
    local port="$2"
    local user="$3"
    local pass="$4"
    local cookie_file="/tmp/qbit_auth_$$.txt"
    
    local response=$(curl -s -c "$cookie_file" -X POST \
        -d "username=$user&password=$pass" \
        "http://$host:$port/api/v2/auth/login")
    
    if [[ "$response" == "Ok." ]]; then
        echo "$cookie_file"
        return 0
    else
        rm -f "$cookie_file" 2>/dev/null
        return 1
    fi
}

# ACTUALIZAR PUERTO (FUNCIÓN SIMPLIFICADA)
update_port_simple() {
    local port="$1"
    local instance="$2"
    
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent] 🚀 Iniciando actualización para instancia: $instance${NC}"
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent] 📌 Puerto objetivo: $port${NC}"
    
    # Configurar según instancia
    if [[ "$instance" == "public" ]]; then
        host="$QB_PUBLIC_HOST"
        web_port="$QB_PUBLIC_PORT"
        user="$QB_PUBLIC_USER"
        pass="$QB_PUBLIC_PASS"
    else
        host="$QB_PRIVATE_HOST"
        web_port="$QB_PRIVATE_PORT"
        user="$QB_PRIVATE_USER"
        pass="$QB_PRIVATE_PASS"
    fi
    
    url="http://$host:$web_port"
    
    # 1. Autenticar
    log_message "🔐 Autenticando en $instance..."
    local cookie_file=$(authenticate "$host" "$web_port" "$user" "$pass")
    
    if [ -z "$cookie_file" ]; then
        echo -e "${RED}❌ Error de autenticación${NC}"
        echo "Verifica usuario/contraseña en $url"
        return 1
    fi
    
    # 2. Verificar versión
    local version=$(curl -s -b "$cookie_file" "$url/api/v2/app/version")
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent] ✅ Conectado a $instance (v$version)${NC}"
    
    # 3. Obtener puerto actual antes del cambio
    local prefs_before=$(curl -s -b "$cookie_file" "$url/api/v2/app/preferences")
    local old_port=$(echo "$prefs_before" | grep -o '"listen_port":[0-9]*' | cut -d: -f2)
    
    if [[ -n "$old_port" && "$old_port" -eq "$port" ]]; then
        echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent] ✅ Puerto ya está configurado correctamente: $port${NC}"
        rm -f "$cookie_file"
        return 0
    fi
    
    # 4. Cambiar puerto
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent] 🔧 Actualizando puerto de ${old_port:-N/A} a $port...${NC}"
    
    local update_response=$(curl -s -b "$cookie_file" -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "json={\"listen_port\":$port}" \
        "$url/api/v2/app/setPreferences")
    
    # 5. Esperar y verificar que se aplicó
    sleep 3
    local prefs_after=$(curl -s -b "$cookie_file" "$url/api/v2/app/preferences")
    local new_port=$(echo "$prefs_after" | grep -o '"listen_port":[0-9]*' | cut -d: -f2)
    
    # 6. Forzar reconexión reiniciando la conexión de red
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent] 🔄 Forzando reconexión de red...${NC}"
    
    curl -s -b "$cookie_file" -X POST "$url/api/v2/transfer/reannounce" > /dev/null 2>&1
    
    # Esperar un poco más para que se aplique
    sleep 2
    
    # 7. Verificar estado de conexión
    local transfer_info=$(curl -s -b "$cookie_file" "$url/api/v2/transfer/info" 2>/dev/null)
    local connection_status=$(echo "$transfer_info" | grep -o '"connection_status":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    
    # Limpiar
    rm -f "$cookie_file"
    
    # 8. Resultado
    if [[ -n "$new_port" && "$new_port" -eq "$port" ]]; then
        echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent] ✅ Puerto actualizado exitosamente a $port${NC}"
        echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent] 📊 Estado de conexión: ${connection_status:-verificando}${NC}"
        
        if [[ "$connection_status" == "firewalled" ]]; then
            echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent] ⚠️ Estado: FIREWALLED (flecha amarilla)${NC}"
            echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent]    Posibles causas:${NC}"
            echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent]    1. El puerto $port puede no estar abierto en Proton VPN${NC}"
            echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent]    2. qBittorrent necesita tiempo para verificar el puerto (1-2 min)${NC}"
            echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent]    3. Verifica en: $url → Opciones → Conexión${NC}"
        else
            echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent] ✅ Estado: CONECTADO o verificando...${NC}"
            echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent] 💡 Nota: Puede tardar 1-2 minutos en mostrar 'Connected' (globo verde)${NC}"
        fi
        return 0
    else
        echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent] ⚠️ Puerto configurado pero no verificado (actual: ${new_port:-N/A}, esperado: $port)${NC}"
        echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent]    qBittorrent puede requerir reinicio manual${NC}"
        echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [qBittorrent]    Verifica en $url → Herramientas → Opciones → Conexión${NC}"
        return 0
    fi
}

# ESTADO (versión simplificada sin detección VPN)
check_instance_status() {
    local instance="$1"
    
    if [[ "$instance" == "public" ]]; then
        host="$QB_PUBLIC_HOST"
        port="$QB_PUBLIC_PORT"
        user="$QB_PUBLIC_USER"
        pass="$QB_PUBLIC_PASS"
    else
        host="$QB_PRIVATE_HOST"
        port="$QB_PRIVATE_PORT"
        user="$QB_PRIVATE_USER"
        pass="$QB_PRIVATE_PASS"
    fi
    
    url="http://$host:$port"
    
    # Verificar puerto
    if ! lsof -i :$port > /dev/null 2>&1; then
        echo -e "   Estado: ${RED}❌ INACTIVA${NC}"
        echo "   Error: Puerto $port no está en uso"
        return 1
    fi
    
    echo "   Proceso: $(lsof -i :$port | tail -1 | awk '{print $1, $2}')"
    
    # Verificar HTTP
    if ! curl -s --max-time 3 "$url" > /dev/null; then
        echo -e "   Estado: ${YELLOW}⚠️ PUERTO OCUPADO pero no responde${NC}"
        return 1
    fi
    
    # Autenticar
    local cookie_file="/tmp/qbit_check_$$.txt"
    local login_response=$(curl -s -c "$cookie_file" -X POST \
        -d "username=$user&password=$pass" \
        "$url/api/v2/auth/login")
    
    if [[ "$login_response" != "Ok." ]]; then
        echo -e "   Estado: ${YELLOW}⚠️ ACTIVA pero NO AUTENTICADA${NC}"
        echo "   WebUI: ✅ ACCESIBLE"
        rm -f "$cookie_file" 2>/dev/null
        return 1
    fi
    
    # Verificar API
    local version=$(curl -s -b "$cookie_file" "$url/api/v2/app/version")
    
    if [[ -n "$version" ]]; then
        echo -e "   Estado: ${GREEN}✅ ACTIVA${NC}"
        echo "   WebUI: ✅ ACCESIBLE"
        echo "   Versión: v$version"
        
        # Obtener puerto y estado de conexión
        local prefs_response=$(curl -s -b "$cookie_file" "$url/api/v2/app/preferences")
        local current_port=$(echo "$prefs_response" | grep -o '"listen_port":[0-9]*' | cut -d: -f2)
        
        if [[ -n "$current_port" ]]; then
            echo "   Puerto actual: $current_port"
        fi
        
        # Obtener información de transferencia para ver estado de conexión
        local transfer_info=$(curl -s -b "$cookie_file" "$url/api/v2/transfer/info" 2>/dev/null)
        local connection_status=$(echo "$transfer_info" | grep -o '"connection_status":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
        
        if [[ -n "$connection_status" && "$connection_status" != "unknown" ]]; then
            if [[ "$connection_status" == "connected" ]]; then
                echo -e "   Estado conexión: ${GREEN}✅ CONECTADO (globo verde)${NC}"
            elif [[ "$connection_status" == "firewalled" ]]; then
                echo -e "   Estado conexión: ${YELLOW}⚠️ FIREWALLED (flecha amarilla)${NC}"
                echo -e "   ${YELLOW}   → Verifica que el puerto $current_port esté abierto en Proton VPN${NC}"
            else
                echo -e "   Estado conexión: ${YELLOW}⚠️ $connection_status${NC}"
            fi
        fi
        
        rm -f "$cookie_file" 2>/dev/null
        return 0
    else
        echo -e "   Estado: ${YELLOW}⚠️ ACTIVA pero API no responde${NC}"
        echo "   WebUI: ✅ ACCESIBLE"
        rm -f "$cookie_file" 2>/dev/null
        return 1
    fi
}

show_status() {
    echo -e "${BLUE}"
    echo "ESTADO DE INSTANCIAS qBittorrent"
    echo "================================="
    echo -e "${NC}"
    
    echo -e "\n1. ${BLUE}INSTANCIA PÚBLICA:${NC}"
    echo "   Puerto WebUI: $QB_PUBLIC_PORT"
    echo "   URL: http://localhost:$QB_PUBLIC_PORT"
    check_instance_status "public"
    
    echo -e "\n2. ${BLUE}INSTANCIA PRIVADA:${NC}"
    echo "   Puerto WebUI: $QB_PRIVATE_PORT"
    echo "   URL: http://localhost:$QB_PRIVATE_PORT"
    check_instance_status "private"
    
    echo -e "\n${YELLOW}CONFIGURACIÓN RECOMENDADA:${NC}"
    echo "------------------------------------------"
    echo "1. INSTANCIA PÚBLICA:"
    echo "   - Puerto WebUI: 8080"
    echo "   - Usuario: admin"
    echo ""
    echo "2. INSTANCIA PRIVADA:"
    echo "   - Puerto WebUI: 8081"
    echo "   - Usuario: admin"
    echo ""
}

show_help() {
    echo -e "${BLUE}USO:${NC}"
    echo "  $0 <puerto> [instancia]    Actualizar puerto"
    echo "  $0 --status                 Ver estado"
    echo "  $0 --help                   Mostrar ayuda"
    echo ""
    echo -e "${BLUE}EJEMPLOS:${NC}"
    echo "  $0 54321 private            Actualizar instancia privada"
    echo "  $0 6881 public              Actualizar instancia pública"
    echo "  $0 --status                 Verificar estado"
    echo ""
    echo -e "${BLUE}INSTANCIAS:${NC}"
    echo "  - public:  Puerto WebUI 8080"
    echo "  - private: Puerto WebUI 8081 (predeterminado)"
    echo ""
    echo -e "${YELLOW}NOTA:${NC}"
    echo "  Este script solo actualiza el puerto de escucha."
    echo "  La interfaz VPN debe configurarse manualmente en qBittorrent."
}

# MAIN
main() {
    case "$1" in
        --status|-s)
            show_status
            ;;
        --help|-h)
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            # Validar puerto
            if ! [[ "$1" =~ ^[0-9]+$ ]] || [[ "$1" -lt 1024 ]] || [[ "$1" -gt 65535 ]]; then
                echo -e "${RED}Error: Puerto inválido ($1)${NC}"
                echo "Debe ser un número entre 1024 y 65535"
                exit 1
            fi
            
            local port="$1"
            local instance="${2:-$DEFAULT_INSTANCE}"
            
            # Validar instancia
            if [[ "$instance" != "public" && "$instance" != "private" ]]; then
                echo -e "${RED}Error: Instancia debe ser 'public' o 'private'${NC}"
                exit 1
            fi
            
            update_port_simple "$port" "$instance"
            ;;
    esac
}

# EJECUTAR
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

main "$1" "$2"
