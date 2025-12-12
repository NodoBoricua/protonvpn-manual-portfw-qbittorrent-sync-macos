#!/bin/bash
# =====================================================
# INSTALADOR AUTOMÁTICO - PROTONVPN PORT FORWARDING
# =====================================================

set -e  # Detener en caso de error

echo "========================================"
echo "🚀 INSTALADOR - ProtonVPN Port Forwarding"
echo "========================================"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mensajes
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Verificar macOS
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "Este script solo funciona en macOS"
    exit 1
fi

print_success "macOS detectado"

# Verificar Python 3
print_info "Verificando Python 3..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    print_success "Python $PYTHON_VERSION encontrado"
else
    print_error "Python 3 no encontrado"
    print_info "Instala Python 3 desde https://www.python.org/downloads/"
    exit 1
fi

# Instalar pip si no está
print_info "Verificando pip..."
if ! python3 -m pip --version &> /dev/null; then
    print_warning "pip no encontrado, instalando..."
    curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
    python3 /tmp/get-pip.py
    rm /tmp/get-pip.py
    print_success "pip instalado"
else
    print_success "pip ya está instalado"
fi

# Instalar py-natpmp
print_info "Instalando py-natpmp..."
if python3 -m pip show py-natpmp &> /dev/null; then
    print_success "py-natpmp ya está instalado"
else
    python3 -m pip install py-natpmp
    print_success "py-natpmp instalado"
fi

# Verificar ruta del script natpmp
NATPMP_PATH=$(python3 -m pip show py-natpmp | grep Location | awk '{print $2}')/natpmp/natpmp_client.py
if [ -f "$NATPMP_PATH" ]; then
    print_success "Script natpmp_client.py encontrado en:"
    echo "   $NATPMP_PATH"
else
    print_error "No se pudo localizar natpmp_client.py"
    exit 1
fi

# Dar permisos a los scripts
print_info "Configurando permisos de scripts..."
chmod +x scripts/*.sh
print_success "Permisos configurados"

# Verificar WireGuard
print_info "Verificando WireGuard..."
if [ -d "/Applications/WireGuard.app" ]; then
    print_success "WireGuard instalado"
else
    print_warning "WireGuard NO encontrado"
    print_info "Descarga WireGuard desde:"
    echo "   - Mac App Store: https://apps.apple.com/us/app/wireguard/id1451685025"
    echo "   - O sitio oficial: https://www.wireguard.com/install/"
fi

# Crear directorios necesarios
print_info "Creando directorios..."
mkdir -p ~/logs
mkdir -p /tmp
print_success "Directorios creados"

# Resumen
echo ""
echo "========================================"
echo "📋 RESUMEN DE INSTALACIÓN"
echo "========================================"
print_success "Python 3: $PYTHON_VERSION"
print_success "pip: Instalado"
print_success "py-natpmp: Instalado"
print_success "Scripts: Configurados"

echo ""
echo "========================================"
echo "🎯 PRÓXIMOS PASOS"
echo "========================================"
echo ""
echo "1. Configura WireGuard siguiendo la guía:"
echo "   https://protonvpn.com/support/wireguard-manual-macos/"
echo ""
echo "2. Conéctate a un servidor con Port Forwarding (busca 'P2P')"
echo ""
echo "3. Ejecuta el script:"
echo "   ${BLUE}./scripts/protonvpn_portfw_simple.sh${NC}"
echo ""
echo "4. O usa el comando simple documentado en README.md"
echo ""
echo "========================================"
print_success "¡Instalación completada!"
echo "========================================"
