#!/bin/bash
# =====================================================
# VERIFICADOR DE DEPENDENCIAS - PROTONVPN PORT FORWARDING
# =====================================================

set -e

echo "=========================================="
echo "🔍 VERIFICADOR DE DEPENDENCIAS"
echo "=========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
ALL_GOOD=true
MISSING_DEPS=()

# Funciones
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ALL_GOOD=false
    MISSING_DEPS+=("$1")
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_check() {
    printf "%-40s" "$1"
}

# =============================
# 1. VERIFICAR SISTEMA
# =============================
print_info "=== VERIFICANDO SISTEMA ==="

print_check "Sistema operativo"
if [[ "$(uname)" == "Darwin" ]]; then
    print_success "macOS"
    
    # Versión de macOS
    MACOS_VERSION=$(sw_vers -productVersion)
    print_check "Versión macOS"
    print_success "$MACOS_VERSION"
else
    print_error "NO macOS"
    echo ""
    echo "Este sistema está diseñado exclusivamente para macOS"
    exit 1
fi

# =============================
# 2. VERIFICAR DEPENDENCIAS BÁSICAS
# =============================
print_info ""
print_info "=== DEPENDENCIAS BÁSICAS ==="

# Python 3
print_check "Python 3"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    if [[ $(echo "$PYTHON_VERSION" | cut -d. -f1) -ge 3 ]]; then
        print_success "$PYTHON_VERSION"
    else
        print_error "Versión $PYTHON_VERSION (necesita 3.0+)"
    fi
else
    print_error "No encontrado"
fi

# pip
print_check "pip"
if python3 -m pip --version &> /dev/null; then
    PIP_VERSION=$(python3 -m pip --version | awk '{print $2}')
    print_success "$PIP_VERSION"
else
    print_error "No encontrado"
fi

# curl
print_check "curl"
if command -v curl &> /dev/null; then
    CURL_VERSION=$(curl --version | head -1 | awk '{print $2}')
    print_success "$CURL_VERSION"
else
    print_error "No encontrado"
fi

# =============================
# 3. VERIFICAR PAQUETES PYTHON
# =============================
print_info ""
print_info "=== PAQUETES PYTHON ==="

# py-natpmp
print_check "py-natpmp"
if python3 -m pip show py-natpmp &> /dev/null; then
    NATPMP_VERSION=$(python3 -m pip show py-natpmp | grep Version | awk '{print $2}')
    NATPMP_PATH=$(python3 -m pip show -f py-natpmp 2>/dev/null | grep -A1 "Files:" | tail -1 | xargs || echo "")
    
    if [ -n "$NATPMP_PATH" ] && [ -f "$NATPMP_PATH" ]; then
        print_success "$NATPMP_VERSION"
        
        # Verificar script específico
        print_check "  └─ natpmp_client.py"
        if find "$(python3 -m pip show py-natpmp | grep Location | awk '{print $2}')" -name "natpmp_client.py" -type f 2>/dev/null | grep -q .; then
            print_success "Encontrado"
        else
            print_error "No encontrado"
        fi
    else
        print_error "$NATPMP_VERSION (ruta inválida)"
    fi
else
    print_error "No instalado"
fi

# =============================
# 4. VERIFICAR APLICACIONES
# =============================
print_info ""
print_info "=== APLICACIONES ==="

# WireGuard
print_check "WireGuard"
if [ -d "/Applications/WireGuard.app" ]; then
    print_success "Instalado"
    
    # Verificar si está en ejecución
    if pgrep -x "WireGuard" > /dev/null; then
        print_check "  └─ Estado"
        print_success "En ejecución"
    else
        print_check "  └─ Estado"
        print_warning "No está ejecutándose"
    fi
else
    print_warning "No instalado"
fi

# qBittorrent
print_check "qBittorrent"
if [ -d "/Applications/qBittorrent.app" ]; then
    QBITTORRENT_VERSION=$(defaults read /Applications/qBittorrent.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo "Desconocida")
    print_success "$QBITTORRENT_VERSION"
    
    # Verificar perfil privado
    print_check "  └─ Perfil privado"
    if [ -d "$HOME/qbt_perfil_privado" ]; then
        print_success "Configurado"
    else
        print_warning "No configurado"
    fi
else
    print_warning "No instalado"
fi

# ProtonVPN
print_check "ProtonVPN"
if [ -d "/Applications/ProtonVPN.app" ] || [ -d "/Applications/Proton VPN.app" ]; then
    print_success "Instalado"
else
    print_warning "No instalado (opcional)"
fi

# =============================
# 5. VERIFICAR SCRIPTS LOCALES
# =============================
print_info ""
print_info "=== SCRIPTS DEL PROYECTO ==="

# Verificar scripts principales
SCRIPTS=("protonvpn_portfw_simple.sh" "create_dashboard_fixed.sh")
for script in "${SCRIPTS[@]}"; do
    print_check "$script"
    if [ -f "./scripts/$script" ]; then
        if [ -x "./scripts/$script" ]; then
            print_success "Ejecutable"
        else
            print_warning "No ejecutable"
        fi
    else
        print_error "No encontrado"
    fi
done

# =============================
# 6. VERIFICAR CONEXIÓN
# =============================
print_info ""
print_info "=== CONEXIÓN DE RED ==="

# Internet
print_check "Conexión a Internet"
if ping -c 1 -t 2 8.8.8.8 &> /dev/null; then
    print_success "Conectado"
else
    print_error "Sin conexión"
fi

# VPN activa
print_check "Conexión VPN activa"
if ifconfig | grep -q "utun"; then
    UTUN_INTERFACE=$(ifconfig | grep "utun" | head -1 | awk '{print $1}' | tr -d ':')
    print_success "Sí ($UTUN_INTERFACE)"
else
    print_warning "No detectada"
fi

# =============================
# 7. VERIFICAR PERMISOS
# =============================
print_info ""
print_info "=== PERMISOS ==="

# Permisos de scripts
print_check "Permisos de ejecución"
if [ -x "./scripts/protonvpn_portfw_simple.sh" ]; then
    print_success "Correctos"
else
    print_warning "Faltan permisos"
fi

# Permisos de escritura
print_check "Permisos de escritura"
if [ -w "." ]; then
    print_success "Correctos"
else
    print_error "Problemas de escritura"
fi

# =============================
# 8. RESUMEN Y RECOMENDACIONES
# =============================
echo ""
echo "=========================================="
echo "📋 RESUMEN DE VERIFICACIÓN"
echo "=========================================="

if [ "$ALL_GOOD" = true ]; then
    print_success "✅ TODAS las dependencias están instaladas"
    echo ""
    print_info "Puedes ejecutar el script principal:"
    echo "   ./scripts/protonvpn_portfw_simple.sh"
else
    print_error "⚠️  Faltan algunas dependencias"
    echo ""
    echo "Dependencias faltantes:"
    for dep in "${MISSING_DEPS[@]}"; do
        echo "  ❌ $dep"
    done
    
    echo ""
    print_info "RECOMENDACIONES:"
    echo "1. Ejecuta el instalador: ./install.sh"
    echo "2. Instala manualmente:"
    echo "   - Python 3: https://www.python.org/downloads/"
    echo "   - WireGuard: Mac App Store"
    echo "3. Verifica la conexión a Internet"
fi

# =============================
# 9. INFORMACIÓN ADICIONAL
# =============================
echo ""
echo "=========================================="
echo "🔧 INFORMACIÓN DEL SISTEMA"
echo "=========================================="

# Espacio en disco
DISK_INFO=$(df -h . | tail -1)
echo "💾 Disco: $(echo $DISK_INFO | awk '{print $4 " libres de " $2}')"

# Memoria
MEMORY=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
MEMORY_MB=$((MEMORY * 4096 / 1024 / 1024))
echo "🧠 RAM libre: ${MEMORY_MB} MB"

# Usuario
echo "👤 Usuario: $(whoami)"

# Uptime
UPTIME=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
echo "⏱️  Uptime: $UPTIME"

echo ""
echo "=========================================="
print_info "Verificación completada"
echo "=========================================="

# Código de salida
if [ "$ALL_GOOD" = true ]; then
    exit 0
else
    exit 1
fi
