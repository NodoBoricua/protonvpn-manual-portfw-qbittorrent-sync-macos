#!/bin/bash
# =====================================================
# DESINSTALADOR COMPLETO - PROTONVPN PORT FORWARDING
# =====================================================

echo "=========================================="
echo "🗑️  DESINSTALADOR - ProtonVPN Port Forwarding"
echo "=========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones para mensajes
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

# Confirmar desinstalación
read -p "⚠️  ¿Estás seguro de desinstalar todo? [y/N]: " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Desinstalación cancelada"
    exit 0
fi

# =============================
# 1. DETENER PROCESOS ACTIVOS
# =============================
print_info "Deteniendo procesos activos..."

# Buscar y detener procesos del script
PIDS=$(pgrep -f "protonvpn_portfw_simple\|port_forwarding\|natpmp_client" 2>/dev/null || true)
if [ -n "$PIDS" ]; then
    print_info "Deteniendo procesos: $PIDS"
    kill -15 $PIDS 2>/dev/null || true
    sleep 2
    kill -9 $PIDS 2>/dev/null || true
    print_success "Procesos detenidos"
else
    print_success "No hay procesos activos"
fi

# =============================
# 2. ELIMINAR ARCHIVOS DE USUARIO
# =============================
print_info "Eliminando archivos del usuario..."

# Archivos de logs
if [ -d "$HOME/logs" ]; then
    rm -rf "$HOME/logs"
    print_success "Logs eliminados"
fi

# Dashboard
if [ -f "$HOME/vpn_dashboard.html" ]; then
    rm -f "$HOME/vpn_dashboard.html"
    print_success "Dashboard eliminado"
fi

# Archivos temporales
rm -f "$HOME/port_forwarding.log" 2>/dev/null || true
rm -f "$HOME/vpn_port_history.log" 2>/dev/null || true
rm -f "/tmp/current_session.log" 2>/dev/null || true
rm -f "/tmp/current_vpn_port.txt" 2>/dev/null || true
rm -f "/tmp/vpn_current_stats.txt" 2>/dev/null || true
rm -f "/tmp/dashboard_debug.log" 2>/dev/null || true

print_success "Archivos temporales eliminados"

# =============================
# 3. DESINSTALAR PAQUETES PYTHON
# =============================
print_info "Desinstalando paquetes Python..."

if python3 -m pip show py-natpmp &> /dev/null; then
    python3 -m pip uninstall py-natpmp -y
    print_success "py-natpmp desinstalado"
else
    print_success "py-natpmp no estaba instalado"
fi

# =============================
# 4. ELIMINAR CONFIGURACIONES
# =============================
print_info "Eliminando configuraciones..."

# Eliminar alias del shell
SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_RC="$HOME/.bash_profile"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
    # Crear copia de seguridad antes de modificar
    cp "$SHELL_RC" "${SHELL_RC}.backup.$(date +%Y%m%d)"
    
    # Eliminar líneas relacionadas con este proyecto
    grep -v "protonvpn_portfw\|vpn_dashboard\|qbt_perfil_privado" "$SHELL_RC" > "${SHELL_RC}.tmp"
    mv "${SHELL_RC}.tmp" "$SHELL_RC"
    print_success "Configuraciones de shell eliminadas"
fi

# =============================
# 5. ELIMINAR SERVICIOS AUTOMÁTICOS
# =============================
print_info "Eliminando servicios automáticos..."

# Verificar si hay servicios launchd
if [ -f "$HOME/Library/LaunchAgents/com.user.vpn-portforward.plist" ]; then
    launchctl unload "$HOME/Library/LaunchAgents/com.user.vpn-portforward.plist" 2>/dev/null || true
    rm -f "$HOME/Library/LaunchAgents/com.user.vpn-portforward.plist"
    print_success "Servicio launchd eliminado"
fi

# Verificar cron jobs
crontab -l 2>/dev/null | grep -v "create_dashboard_fixed\|protonvpn_portfw" | crontab - 2>/dev/null || true
print_success "Tareas cron eliminadas"

# =============================
# 6. ELIMINAR PERFILES qBITTORRENT
# =============================
print_info "¿Quieres eliminar el perfil de qBittorrent privado? [y/N]: "
read -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "$HOME/qbt_perfil_privado" ]; then
        print_warning "ATENCIÓN: Esto eliminará todos los torrents y configuraciones del perfil privado"
        read -p "⚠️  ¿Continuar? [y/N]: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$HOME/qbt_perfil_privado"
            print_success "Perfil qBittorrent privado eliminado"
        fi
    else
        print_success "No existe perfil qBittorrent privado"
    fi
fi

# =============================
# 7. ELIMINAR EL PROYECTO COMPLETO
# =============================
print_info "¿Deseas eliminar también la carpeta del proyecto actual? [y/N]: "
read -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ "$PROJECT_DIR" != "$HOME" ] && [ -d "$PROJECT_DIR" ]; then
        print_warning "Eliminando: $PROJECT_DIR"
        rm -rf "$PROJECT_DIR"
        print_success "Carpeta del proyecto eliminada"
    fi
fi

# =============================
# 8. RESUMEN FINAL
# =============================
echo ""
echo "=========================================="
echo "📋 RESUMEN DE DESINSTALACIÓN"
echo "=========================================="
print_success "✓ Procesos detenidos"
print_success "✓ Archivos de usuario eliminados"
print_success "✓ Paquetes Python desinstalados"
print_success "✓ Configuraciones removidas"
print_success "✓ Servicios automáticos eliminados"
echo ""
print_warning "⚠️  Algunos elementos NO se eliminaron:"
echo "   - WireGuard (debido a ser una app independiente)"
echo "   - Python 3 (sistema básico)"
echo "   - Archivos de descargas de torrents"
echo ""
print_info "Si quieres una limpieza completa, manualmente:"
echo "   1. Desinstala WireGuard desde Launchpad"
echo "   2. Elimina archivos de torrents manualmente"
echo "   3. Revisa ~/.zshrc o ~/.bash_profile"
echo ""
echo "=========================================="
print_success "¡Desinstalación completada!"
echo "=========================================="
