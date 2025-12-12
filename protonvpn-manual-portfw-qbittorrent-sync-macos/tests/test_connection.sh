
#!/bin/bash
# =====================================================
# TEST DE CONEXIÓN - VPN PORT FORWARDING
# =====================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

echo "========================================"
echo "🔍 TEST DE CONEXIÓN COMPLETO"
echo "========================================"

# Variables
ALL_TESTS_PASSED=true
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Función para ejecutar test
run_test() {
    TEST_COUNT=$((TEST_COUNT + 1))
    local test_name="$1"
    local command="$2"
    local expected="$3"
    
    printf "%-40s" "$test_name..."
    
    if eval "$command" > /dev/null 2>&1; then
        PASS_COUNT=$((PASS_COUNT + 1))
        echo -e "${GREEN}PASS${NC}"
        return 0
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        ALL_TESTS_PASSED=false
        echo -e "${RED}FAIL${NC}"
        return 1
    fi
}

# =============================
# 1. TEST DE SISTEMA
# =============================
echo ""
print_info "=== SISTEMA ==="

run_test "Sistema operativo macOS" \
    "[[ \$(uname) == 'Darwin' ]]" \
    "true"

run_test "Python 3 instalado" \
    "command -v python3" \
    "true"

run_test "Pip instalado" \
    "python3 -m pip --version" \
    "true"

# =============================
# 2. TEST DE PYTHON
# =============================
echo ""
print_info "=== PYTHON Y DEPENDENCIAS ==="

run_test "Módulo natpmp disponible" \
    "python3 -c 'import natpmp'" \
    "true"

run_test "Script natpmp_client.py existe" \
    "find \$(python3 -m pip show py-natpmp | grep Location | cut -d' ' -f2) -name 'natpmp_client.py' -type f | grep -q ." \
    "true"

# =============================
# 3. TEST DE VPN
# =============================
echo ""
print_info "=== CONEXIÓN VPN ==="

run_test "WireGuard instalado" \
    "[ -d '/Applications/WireGuard.app' ]" \
    "true"

run_test "Interfaz VPN activa" \
    "ifconfig | grep -q utun" \
    "true"

# Obtener interfaz VPN
VPN_INTERFACE=$(ifconfig | grep utun | head -1 | cut -d: -f1)
if [ -n "$VPN_INTERFACE" ]; then
    print_success "Interfaz VPN detectada: $VPN_INTERFACE"
else
    print_warning "No se detectó interfaz VPN activa"
fi

# =============================
# 4. TEST DE PORT FORWARDING
# =============================
echo ""
print_info "=== PORT FORWARDING ==="

# Verificar si hay puerto actual
if [ -f "/tmp/current_vpn_port.txt" ]; then
    CURRENT_PORT=$(cat /tmp/current_vpn_port.txt)
    if [[ "$CURRENT_PORT" =~ ^[0-9]+$ ]]; then
        print_success "Puerto actual: $CURRENT_PORT"
        
        # Test de puerto abierto (opcional)
        run_test "Puerto válido (1000-65535)" \
            "[[ $CURRENT_PORT -ge 1000 && $CURRENT_PORT -le 65535 ]]" \
            "true"
    else
        print_warning "Puerto inválido en archivo: $CURRENT_PORT"
    fi
else
    print_warning "No hay archivo de puerto actual (/tmp/current_vpn_port.txt)"
fi

# =============================
# 5. TEST DE CONEXIÓN EXTERNA
# =============================
echo ""
print_info "=== CONEXIÓN EXTERNA ==="

run_test "Conexión a internet" \
    "ping -c 1 -W 2 8.8.8.8" \
    "true"

# Solo testear gateway si hay VPN
if [ -n "$VPN_INTERFACE" ]; then
    run_test "Conexión al gateway VPN (10.2.0.1)" \
        "ping -c 1 -W 2 10.2.0.1" \
        "true"
fi

# =============================
# 6. TEST DE SCRIPTS
# =============================
echo ""
print_info "=== SCRIPTS DEL PROYECTO ==="

run_test "Script principal existe" \
    "[ -f 'scripts/protonvpn_portfw_advanced.sh' ]" \
    "true"

run_test "Script principal es ejecutable" \
    "[ -x 'scripts/protonvpn_portfw_advanced.sh' ]" \
    "true"

run_test "Instalador existe" \
    "[ -f 'tools/install.sh' ]" \
    "true"

# =============================
# 7. RESUMEN FINAL
# =============================
echo ""
echo "========================================"
echo "📊 RESUMEN DE TESTS"
echo "========================================"
echo "Total tests ejecutados: $TEST_COUNT"
echo -e "✅ Tests pasados: ${GREEN}$PASS_COUNT${NC}"
echo -e "❌ Tests fallados: ${RED}$FAIL_COUNT${NC}"

if [ "$ALL_TESTS_PASSED" = true ]; then
    echo ""
    print_success "✅ ¡TODOS LOS TESTS PASARON!"
    echo ""
    print_info "El sistema está listo para usar Port Forwarding"
    echo "Puedes ejecutar: ./scripts/protonvpn_portfw_advanced.sh"
    exit 0
else
    echo ""
    print_error "⚠️  ALGUNOS TESTS FALLARON"
    echo ""
    print_warning "Recomendaciones:"
    
    if [ "$FAIL_COUNT" -eq 1 ] && [ ! -d "/Applications/WireGuard.app" ]; then
        echo "1. Instala WireGuard desde Mac App Store"
    fi
    
    if ! command -v python3 &> /dev/null; then
        echo "1. Instala Python 3 desde https://www.python.org"
    fi
    
    if ! python3 -m pip show py-natpmp &> /dev/null; then
        echo "2. Ejecuta: python3 -m pip install py-natpmp"
    fi
    
    if ! ifconfig | grep -q utun; then
        echo "3. Conéctate a la VPN en WireGuard"
    fi
    
    echo ""
    echo "Ejecuta el instalador para solucionar problemas:"
    echo "  ./tools/install.sh"
    
    exit 1
fi
