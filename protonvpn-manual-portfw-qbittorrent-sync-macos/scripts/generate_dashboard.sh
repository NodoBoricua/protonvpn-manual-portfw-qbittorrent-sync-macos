#!/bin/bash
# =====================================================
# DASHBOARD PROTON VPN - VERSIÓN MEJORADA CON MÉTRICAS MAC CON BADGES DE INSTANCIA qBittorrent
# =====================================================

DASHBOARD="$HOME/vpn_dashboard.html"
LOG_FILE="$HOME/port_forwarding.log"
HISTORY_FILE="$HOME/vpn_port_history.log"
SESSION_LOG_FILE="/tmp/current_session.log"
PORT_FILE="/tmp/current_vpn_port.txt"

# ================================
# LEER ESTADÍSTICAS ACTUALIZADAS
# ================================

# Archivo de estadísticas sincronizadas
STATS_FILE="/tmp/vpn_current_stats.txt"

# Valores por defecto
DEFAULT_PORT="N/A"
DEFAULT_SUCCESS=0
DEFAULT_ERROR=0
DEFAULT_VPN_OFF=0
DEFAULT_CHANGES=0

# Leer del archivo de estadísticas si existe
if [ -f "$STATS_FILE" ]; then
    # Cargar variables desde el archivo
    source "$STATS_FILE" 2>/dev/null || true
    
    # Debug: mostrar lo que se cargó
    echo "DEBUG: Cargando stats desde $STATS_FILE" >> /tmp/dashboard_debug.log 2>/dev/null
    tail -n 3 "$STATS_FILE" >> /tmp/dashboard_debug.log 2>/dev/null || true
fi

# Usar valores del archivo o valores por defecto
CURRENT_PORT=${CURRENT_PORT:-$(cat "$PORT_FILE" 2>/dev/null || echo "$DEFAULT_PORT")}
SUCCESS_COUNT=${SUCCESS_COUNT:-$(grep -c "✅ ACTIVO" "$SESSION_LOG_FILE" 2>/dev/null || echo "$DEFAULT_SUCCESS")}
ERROR_COUNT=${ERROR_COUNT:-$(grep -c "ERROR NAT-PMP" "$SESSION_LOG_FILE" 2>/dev/null || echo "$DEFAULT_ERROR")}
VPN_DISC_COUNT=${VPN_DISC_COUNT:-$(grep -c "VPN DESCONECTADA" "$SESSION_LOG_FILE" 2>/dev/null || echo "$DEFAULT_VPN_OFF")}
PORT_CHANGES=${PORT_CHANGES:-$(grep -c "\[CAMBIO\]" "$SESSION_LOG_FILE" 2>/dev/null || echo "$DEFAULT_CHANGES")}

# Log para verificar
echo "DEBUG FINAL: Puerto=$CURRENT_PORT, Éxitos=$SUCCESS_COUNT, Errores=$ERROR_COUNT, VPN Off=$VPN_DISC_COUNT, Cambios=$PORT_CHANGES" >> /tmp/dashboard_debug.log 2>/dev/null

# ================================
# OBTENER MÉTRICAS DEL SISTEMA MAC
# ================================

# CPU Usage
cpu_usage=$(top -l 1 | awk '/CPU usage/ {print $3}' | tr -d '%' 2>/dev/null || echo "0")

# Memoria RAM
mem_info=$(memory_pressure 2>/dev/null || echo "")
if [[ -n "$mem_info" ]]; then
    mem_free=$(echo "$mem_info" | grep "System-wide memory free percentage" | awk '{print $5}' | tr -d '%' 2>/dev/null || echo "50")
    mem_used=$((100 - mem_free))
else
    mem_used="50"
fi

# Uptime del sistema
uptime_raw=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
uptime=$(echo "$uptime_raw" | sed 's/days/días/g; s/day/día/g; s/hours/horas/g; s/hour/hora/g; s/minutes/minutos/g; s/minute/minuto/g')

# Temperatura del CPU (Mac)
# Nota: ifstat es para estadísticas de red, NO para temperatura
# Alternativas sin sudo: istats (requiere instalación), osx-cpu-temp (requiere instalación)
# Temperatura CPU
TEMPERATURE="Instalar osx-cpu-temp"

if command -v istats &> /dev/null; then
    TEMPERATURE=$(istats cpu temp --no-graphs 2>/dev/null | awk '{print $3$4}' | head -1 || echo "N/A")
elif command -v osx-cpu-temp &> /dev/null; then
    TEMPERATURE=$(osx-cpu-temp 2>/dev/null | head -1 || echo "N/A")
elif command -v osascript &> /dev/null; then
    thermal_level=$(osascript -e "do shell script \"sysctl -n machdep.xcpm.cpu_thermal_level 2>/dev/null\"" 2>/dev/null || echo "")
    [[ -n "$thermal_level" ]] && TEMPERATURE="Nivel $thermal_level"
fi

# Mostrar en dashboard
echo "🌡️ CPU Temp: $TEMPERATURE"

# Si necesita instalación
if [ "$TEMPERATURE" = "Instalar osx-cpu-temp" ]; then
    echo "   💡 Sugerencia: brew install osx-cpu-temp"
    echo "   💡 Alternativa: sudo gem install iStats"
fi
# Si ninguna herramienta está disponible, mostrar "N/A" (no usar sudo powermetrics)

# Estado de la batería
battery_percent=$(pmset -g batt 2>/dev/null | grep -Eo "\d+%" | cut -d% -f1 || echo "0")
battery_status=$(pmset -g batt 2>/dev/null | grep -o "charging\|discharging\|charged\|AC attached" || echo "unknown")
case $battery_status in
    "charging") BATTERY_EMOJI="🔌" ;;
    "discharging") BATTERY_EMOJI="🔋" ;;
    "charged") BATTERY_EMOJI="✅" ;;
    "AC attached") BATTERY_EMOJI="⚡" ;;
    *) BATTERY_EMOJI="❓" ;;
esac

# Uso de Disco
disk_usage=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%' 2>/dev/null || echo "0")
disk_total=$(df -h / | tail -1 | awk '{print $2}' 2>/dev/null || echo "N/A")
disk_used=$(df -h / | tail -1 | awk '{print $3}' 2>/dev/null || echo "N/A")
disk_free=$(df -h / | tail -1 | awk '{print $4}' 2>/dev/null || echo "N/A")

# ==================
# CREAR HTML
# ==================
cat > "$DASHBOARD" << EOF
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Dashboard ProtonVPN & Mac Monitor</title>
<meta http-equiv="refresh" content="320">
<style>
    /* ===== ESTILO GENERAL MEJORADO ===== */
    /* # MODIFICAR AQUÍ 1: Estilos generales del cuerpo */
    body { 
        background: linear-gradient(135deg, #0d1117 0%, #161b22 100%); 
        color: #c9d1d9; 
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; 
        margin: 0; 
        padding: 0; 
        min-height: 100vh;
    }
    
    /* # MODIFICAR AQUÍ 2: Contenedor principal */
    .container { 
        width: 75%; 
        max-width: 1400px; 
        margin: auto; 
        padding: 18px; 
    }
    
    /* # MODIFICAR AQUÍ 3: Títulos */
    h1 { 
        text-align: center; 
        color: #58a6ff; 
        font-size: 2.5em; 
        margin-bottom: 5px; 
        text-shadow: 0 2px 4px rgba(0,0,0,0.5);
        background: linear-gradient(90deg, #58a6ff, #79c0ff);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
    }
    h2 { 
        color: #8b949e; 
        border-bottom: 2px solid #30363d; 
        padding-bottom: 10px; 
        margin-top: 0;
        font-size: 1.4em;
    }
    
    /* ===== SISTEMA DE GRID MEJORADO ===== */
    /* # MODIFICAR AQUÍ 4: Grid principal del dashboard */
    .dashboard-grid { 
        display: grid; 
        grid-template-columns: repeat(auto-fit, minmax(850px, 1fr)); 
        gap: 25px; 
        margin: 25px 0; 
    }
    
    /* ===== TARJETAS ===== */
    /* # MODIFICAR AQUÍ 5: Estilos de las tarjetas */
    .card { 
        background: linear-gradient(145deg, #161b22, #1a1f26); 
        padding: 15px; 
        border-radius: 12px; 
        box-shadow: 0 10px 20px rgba(0,0,0,0.3);
        border: 1px solid rgba(48, 54, 61, 0.5);
        transition: transform 0.3s ease, box-shadow 0.3s ease;
    }
    .card:hover {
        transform: translateY(-5px);
        box-shadow: 0 15px 30px rgba(0,0,0,0.4);
    }
    
    /* ===== ESTADÍSTICAS ===== */
    /* # MODIFICAR AQUÍ 6: Grid de estadísticas */
    .stats-grid { 
        display: grid; 
        grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); 
        gap: 15px; 
        margin: 15px 0; 
    }
    
    /* # MODIFICAR AQUÍ 7: Cajas de estadísticas */
    .stat-box { 
        background: linear-gradient(135deg, #21262d, #242a32); 
        padding: 16px; 
        border-radius: 12px; 
        text-align: center; 
        box-shadow: inset 0 4px 10px rgba(0,0,0,0.4);
        border: 1px solid #30363d;
        transition: all 0.3s ease;
    }
    .stat-box:hover {
        background: linear-gradient(135deg, #242a32, #272e37);
        box-shadow: inset 0 4px 10px rgba(0,0,0,0.5);
    }
    
    /* # MODIFICAR AQUÍ 8: Valor de las estadísticas */
    .stat-value { 
        font-size: 2.3em; 
        font-weight: 800; 
        margin: 12px 0; 
        text-shadow: 0 2px 4px rgba(0,0,0,0.5);
        font-family: 'SF Mono', Monaco, monospace;
    }
    
    /* # MODIFICAR AQUÍ 9: Etiquetas de las estadísticas */
    .stat-label { 
        font-size: 0.9em; 
        color: #8b949e; 
        margin-top: 6px;
        font-weight: 500;
        letter-spacing: 0.3px;
    }
    
    /* ===== COLORES ===== */
    /* # MODIFICAR AQUÍ 10: Paleta de colores */
    .color-success { color: #3fb950; }
    .color-error { color: #f85149; }
    .color-warning { color: #ffa657; }
    .color-info { color: #58a6ff; }
    .color-purple { color: #a371f7; }
    .color-pink { color: #ff79c6; }
    
    /* ===== BOTONES ===== */
    /* # MODIFICAR AQUÍ 11: Estilos de botones */
    .btn { 
        background: linear-gradient(135deg, #238636, #2ea043); 
        color: white; 
        padding: 14px 28px; 
        border-radius: 12px; 
        text-decoration: none; 
        font-size: 1.1em; 
        display: inline-block; 
        border: none; 
        cursor: pointer;
        transition: all 0.3s ease;
        font-weight: 600;
        letter-spacing: 0.5px;
        box-shadow: 0 4px 12px rgba(35, 134, 54, 0.3);
    }
    .btn:hover { 
        background: linear-gradient(135deg, #2ea043, #3fb950); 
        transform: translateY(-2px) scale(1.05);
        box-shadow: 0 6px 18px rgba(46, 160, 67, 0.4);
    }
    
    /* ===== BARRAS DE PROGRESO ===== */
    /* # MODIFICAR AQUÍ 12: Barras de progreso */
    .progress-bar { 
        background: #30363d; 
        height: 22px; 
        border-radius: 11px; 
        margin: 12px 0; 
        overflow: hidden; 
        box-shadow: inset 0 2px 6px rgba(0,0,0,0.4);
    }
    .progress-fill { 
        height: 100%; 
        border-radius: 11px; 
        transition: width 0.8s cubic-bezier(0.34, 1.56, 0.64, 1);
    }
    
    /* ===== FOOTER ===== */
    /* # MODIFICAR AQUÍ 13: Pie de página */
    .footer { 
        text-align: center; 
        margin-top: 35px; 
        color: #8b949e; 
        font-size: 0.9em; 
        padding: 25px;
        border-top: 1px solid #30363d;
        background: rgba(22, 27, 34, 0.7);
        border-radius: 12px;
    }
    
    /* ===== EMOJIS GRANDES ===== */
    /* # MODIFICAR AQUÍ 14: Tamaño de emojis grandes */
    .emoji-large { 
        font-size: 3em; 
        display: block; 
        margin-bottom: 12px; 
        filter: drop-shadow(0 3px 6px rgba(0,0,0,0.4));
        animation: float 3s ease-in-out infinite;
    }
    @keyframes float {
        0%, 100% { transform: translateY(0px); }
        50% { transform: translateY(-5px); }
    }
    
    /* ===== LOGS Y PRE ===== */
    /* # MODIFICAR AQUÍ 15: Área de logs */
    pre { 
        background: #0d1117; 
        padding: 14px; 
        border-radius: 10px; 
        overflow: auto; 
        max-height: 220px; 
        font-family: 'SF Mono', Monaco, 'Courier New', monospace;
        border: 1px solid #30363d;
        font-size: 0.9em;
        line-height: 1.5;
    }
    
    /* ===== HISTORIAL ===== */
    /* # MODIFICAR AQUÍ 16: Entradas del historial */
    .history-entry {
        padding: 12px;
        margin-bottom: 12px;
        border-radius: 12px;
        border-left: 5px solid;
        animation: slideIn 0.5s ease;
        background: rgba(33, 38, 45, 0.7);
        transition: all 0.3s ease;
    }
    .history-entry:hover {
        background: rgba(33, 38, 45, 0.9);
        transform: translateX(5px);
    }
    @keyframes slideIn {
        from { opacity: 0; transform: translateX(-20px); }
        to { opacity: 1; transform: translateX(0); }
    }
    
    /* ===== RESPONSIVE ===== */
    /* # MODIFICAR AQUÍ 17: Estilos responsivos */
    @media (max-width: 768px) {
        .dashboard-grid { grid-template-columns: 1fr; gap: 18px; }
        .stats-grid { grid-template-columns: repeat(2, 1fr); gap: 13px; }
        h1 { font-size: 2em; }
        .stat-box { padding: 30px; }
        .card { padding: 15px; }
    }
    
    /* ===== EFECTOS ESPECIALES ===== */
    /* # MODIFICAR AQUÍ 18: Efectos de animación */
    .pulse {
        animation: pulse 2s infinite;
    }
    @keyframes pulse {
        0% { opacity: 1; }
        50% { opacity: 0.7; }
        100% { opacity: 1; }
    }
    
    .glow {
        text-shadow: 0 0 10px currentColor, 0 0 20px currentColor;
    }
    
    /* ===== BADGES DE INSTANCIA qBittorrent ===== */
    .instance-badge {
        display: inline-block;
        padding: 3px 10px;
        border-radius: 15px;
        font-size: 0.75em;
        font-weight: 700;
        margin-left: 8px;
        vertical-align: middle;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }
    
    .instance-public {
        background: rgba(88, 166, 255, 0.2);
        color: #58a6ff;
        border: 1px solid #58a6ff;
        box-shadow: 0 0 8px rgba(88, 166, 255, 0.3);
    }
    
    .instance-private {
        background: rgba(163, 113, 247, 0.25);
        color: #a371f7;
        border: 1px solid #a371f7;
        box-shadow: 0 0 10px rgba(163, 113, 247, 0.4);
        font-weight: 800;
    }
</style>
</head>

<body>
<div class="container">

<!-- TÍTULO PRINCIPAL -->
<div style="text-align: center; margin-bottom: 30px;">
    <h1>📊 Dashboard ProtonVPN & Mac Monitor</h1>
    <p style="color: #8b949e; font-size: 1.1em; margin-top: 5px;">
        Monitoreo en tiempo real | Sistema MacBook | Instancia: <span class="instance-badge instance-private">PRIVADA</span>
    </p>
</div>

<!-- BOTÓN DE ACTUALIZAR -->
<div class="card" style="text-align:center; background: linear-gradient(135deg, #161b22, #1e242d);">
    <a href="#" onclick="location.reload();" class="btn">🔄 Actualizar Ahora</a>
    <p style="margin-top: 18px; color: #8b949e; font-size: 0.95em;">
        Última actualización: $(date '+%Y-%m-%d %H:%M:%S') | 
        <span id="live-indicator" style="color: #3fb950; font-weight: bold;">● EN VIVO</span>
        <span style="margin-left: 15px; color: #a371f7;">
            🎯 qBittorrent: <span class="instance-badge instance-private">PRIVADO</span>
        </span>
    </p>
</div>

<!-- GRID PRINCIPAL -->
<div class="dashboard-grid">

<!-- COLUMNA IZQUIERDA: VPN -->
<div>
    <!-- ESTADO VPN -->
    <div class="card">
        <h2>🔐 Estado VPN - Sesión Actual</h2>
        <div class="stats-grid">
            <div class="stat-box" style="border: 2px solid rgba(163, 113, 247, 0.3);">
                <span class="emoji-large">🔒</span>
                <div class="stat-value color-purple">$CURRENT_PORT</div>
                <div class="stat-label">
                    Puerto Actual
                    <span class="instance-badge instance-private">PRIVADO</span>
                </div>
                <div style="font-size: 0.8em; color: #a371f7; margin-top: 5px; font-weight: 600;">
                    🔗 Sincronizado con qBittorrent
                </div>
                <div class="progress-bar">
                    <div class='progress-fill' style='width: 75%; background: linear-gradient(90deg, #a371f7, #bc8cff);'></div>
                </div>
            </div>
            
            <div class="stat-box">
                <span class="emoji-large">✅</span>
                <div class="stat-value color-success">$SUCCESS_COUNT</div>
                <div class="stat-label">Éxitos NAT-PMP</div>
                <div class="progress-bar">
                    <div class='progress-fill' style='width: 65%; background: linear-gradient(90deg, #3fb950, #56d364);'></div>
                </div>
            </div>
            
            <div class="stat-box">
                <span class="emoji-large">⚠️</span>
                <div class="stat-value color-error">$ERROR_COUNT</div>
                <div class="stat-label">Errores NAT-PMP</div>
                <div class="progress-bar">
                    <div class='progress-fill' style='width: 65%; background: linear-gradient(90deg, #f85149, #ff7b72);'></div>
                </div>
            </div>
            
            <div class="stat-box">
                <span class="emoji-large">🔌</span>
                <div class="stat-value color-warning">$VPN_DISC_COUNT</div>
                <div class="stat-label">VPN Desconectada</div>
                <div class="progress-bar">
                    <div class='progress-fill' style='width: 65%; background: linear-gradient(90deg, #ffa657, #ffc680);'></div>
                </div>
            </div>
        </div>
        
        <!-- INDICADOR DE INSTANCIA PRINCIPAL -->
        <div style="background: rgba(163, 113, 247, 0.1); border-left: 4px solid #a371f7; padding: 10px; border-radius: 8px; margin: 15px 0;">
            <div style="display: flex; align-items: center;">
                <span style="color: #a371f7; font-size: 1.3em; margin-right: 10px;">🎯</span>
                <div>
                    <div style="color: #a371f7; font-weight: bold; font-size: 0.95em;">
                        Instancia Principal: qBittorrent <span class="instance-badge instance-private">PRIVADA</span>
                    </div>
                    <div style="color: #8b949e; font-size: 0.85em; margin-top: 3px;">
                        Puerto actualizado automáticamente en la instancia privada (tracker privado)
                    </div>
                </div>
            </div>
        </div>
        
        <!-- CAMBIOS DE PUERTO -->
        <div style="text-align:center; margin-top:25px;">
            <div class="stat-box" style="max-width: 320px; margin: 0 auto;">
                <span class="emoji-large">🔄</span>
                <div class="stat-value color-purple">$PORT_CHANGES</div>
                <div class="stat-label">Cambios de Puerto</div>
                <div class="progress-bar">
                    <div class='progress-fill' style='width: 35%; background: linear-gradient(90deg, #a371f7, #bc8cff);'></div>
                </div>
            </div>
        </div>
    </div>

    <!-- HISTORIAL DE CAMBIOS DE PUERTO -->
    <div class="card">
        <h2>🔄 Historial de Cambios de Puerto</h2>
        <pre>$(tail -n 10 "$HISTORY_FILE" 2>/dev/null || echo "No hay cambios de puerto registrados...")</pre>
    </div>
</div>

<!-- COLUMNA DERECHA: SISTEMA MAC -->
<div>
    <!-- MONITOREO DEL SISTEMA MAC -->
    <div class="card">
        <h2>🌡️ Monitoreo del Sistema Mac</h2>
        
        <div class="stats-grid">
            <div class="stat-box">
                <span class="emoji-large">🔥</span>
                <div class="stat-value" id="cpu-temp" style="color: #ffa657;">$TEMPERATURE</div>
                <div class="stat-label">Temperatura CPU</div>
                <div class="progress-bar">
                    <div class='progress-fill' style='width: 100%; background: linear-gradient(90deg, #ffa657, #ffc680);'></div>
                </div>
            </div>
            
            <div class="stat-box">
                <span class="emoji-large">$BATTERY_EMOJI</span>
                <div class="stat-value" style="color: #3fb950;">${battery_percent}%</div>
                <div class="stat-label">Batería</div>
                <div class="progress-bar">
                    <div class='progress-fill' style='width: ${battery_percent}%; background: linear-gradient(90deg, #3fb950, #56d364);'></div>
                </div>
            </div>
        </div>
        
        <!-- MÉTRICAS ADICIONALES -->
        <div style="margin-top: 25px;">
            <h3 style="color: #8b949e; margin-bottom: 15px; font-size: 1.1em;">📊 Rendimiento del Sistema:</h3>
            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px;">
                <div>
                    <div style="display: flex; justify-content: space-between; margin-bottom: 8px;">
                        <span style="color: #8b949e; font-size: 0.95em;">💻 CPU:</span>
                        <span style="color: #ffa657; font-weight: bold; font-size: 1.1em;">${cpu_usage}%</span>
                    </div>
                    <div class="progress-bar" style="height: 10px;">
                        <div class='progress-fill' style='width: ${cpu_usage}%; background: linear-gradient(90deg, #ffa657, #ffc680);'></div>
                    </div>
                </div>
                <div>
                    <div style="display: flex; justify-content: space-between; margin-bottom: 8px;">
                        <span style="color: #8b949e; font-size: 0.95em;">🧠 RAM:</span>
                        <span style="color: #a371f7; font-weight: bold; font-size: 1.1em;">${mem_used}%</span>
                    </div>
                    <div class="progress-bar" style="height: 10px;">
                        <div class='progress-fill' style='width: ${mem_used}%; background: linear-gradient(90deg, #a371f7, #bc8cff);'></div>
                    </div>
                </div>
            </div>
            
            <!-- DISCO Y UPTIME -->
            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-top: 20px;">
                <div>
                    <div style="color: #8b949e; font-size: 0.95em; margin-bottom: 5px;">💾 Disco:</div>
                    <div style="color: #58a6ff; font-weight: bold; font-size: 1.1em;">${disk_usage}% usado</div>
                    <div style="color: #8b949e; font-size: 0.85em; margin-top: 3px;">${disk_used}/${disk_total}</div>
                    <div class="progress-bar" style="height: 5px; margin-top: 5px;">
                        <div class='progress-fill' style='width: ${disk_usage}%; background: linear-gradient(90deg, #58a6ff, #79c0ff);'></div>
                    </div>
                </div>
                <div>
                    <div style="color: #8b949e; font-size: 0.85em; margin-bottom: 5px;">⏱️ Uptime:</div>
                    <div style="color: #ff79c6; font-weight: bold; font-size: 1.1em;">$uptime</div>
                    <div style="color: #8b949e; font-size: 0.75em; margin-top: 3px;">Tiempo activo sistema</div>
                </div>
            </div>
        </div>
    </div>

    <!-- EVENTOS RECIENTES DE SESIÓN -->
    <div class="card">
        <h2>📝 Eventos Recientes (Sesión)</h2>
        <div style="max-height: 520px; overflow-y: auto; padding-right: 18px; scroll-behavior: smooth;">
EOF

# MOSTRAR EVENTOS DE SESIÓN CON COLORES (SESSION_LOG_FILE)
# CORREGIDO: Redirigir la salida al archivo HTML
if [ -f "$SESSION_LOG_FILE" ]; then
    # Leer solo las últimas 10 líneas de la sesión y procesarlas
    tail -n 10 "$SESSION_LOG_FILE" | while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" == *"✅ ACTIVO"* ]]; then
            border_color="#3fb950"
            bg_color="rgba(63, 185, 80, 0.15)"
            emoji="✅"
            label="ACTIVO"
        elif [[ "$line" == *"ERROR NAT-PMP"* ]]; then
            border_color="#f85149"
            bg_color="rgba(248, 81, 73, 0.15)"
            emoji="⚠️"
            label="ERROR"
        elif [[ "$line" == *"VPN DESCONECTADA"* ]]; then
            border_color="#ffa657"
            bg_color="rgba(255, 166, 87, 0.15)"
            emoji="🔌"
            label="VPN OFF"
        elif [[ "$line" == *"[INICIO]"* ]]; then
            border_color="#58a6ff"
            bg_color="rgba(88, 166, 255, 0.15)"
            emoji="🟢"
            label="INICIO"
        elif [[ "$line" == *"[CAMBIO]"* ]]; then
            border_color="#a371f7"
            bg_color="rgba(163, 113, 247, 0.15)"
            emoji="🟠"
            label="CAMBIO"
        elif [[ "$line" == *"qBittorrent"* ]] && [[ "$line" == *"privado"* ]]; then
            border_color="#a371f7"
            bg_color="rgba(163, 113, 247, 0.2)"
            emoji="🔒"
            label="QBIT-PRIV"
        elif [[ "$line" == *"qBittorrent"* ]] && [[ "$line" == *"público"* ]]; then
            border_color="#58a6ff"
            bg_color="rgba(88, 166, 255, 0.15)"
            emoji="🔓"
            label="QBIT-PUB"
        elif [[ "$line" == *"qBittorrent"* ]] || [[ "$line" == *"QBITTORRENT"* ]]; then
            border_color="#a371f7"
            bg_color="rgba(163, 113, 247, 0.15)"
            emoji="🔧"
            label="QBIT"
        else
            border_color="#8b949e"
            bg_color="rgba(139, 148, 158, 0.1)"
            emoji="📄"
            label="OTRO"
        fi
        
        # Extraer timestamp y mensaje de forma más robusta
        timestamp_part=$(echo "$line" | cut -d' ' -f1-2 2>/dev/null | sed 's/^\[//;s/\]$//' || echo "")
        message_part=$(echo "$line" | cut -d' ' -f3- 2>/dev/null || echo "$line")
        
        # ESCAPAR caracteres especiales para HTML
        timestamp_part=$(echo "$timestamp_part" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        message_part=$(echo "$message_part" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        
        # Escribir directamente al archivo HTML
        cat >> "$DASHBOARD" << INNEREOF
<div class='history-entry' style='border-left-color: $border_color; background: $bg_color;'>
    <div style='display: flex; align-items: flex-start; gap: 12px;'>
        <div style='font-size: 1.4em;'>$emoji</div>
        <div style='flex: 1;'>
            <div style='display: flex; align-items: center; margin-bottom: 4px;'>
                <span style='color: $border_color; font-weight: bold; font-size: 0.85em; background: rgba(0,0,0,0.2); padding: 4px 10px; border-radius: 15px;'>$label</span>
                <span style='color: #6e7681; font-size: 0.8em; margin-left: 10px;'>$timestamp_part</span>
            </div>
            <div style='color: $border_color; font-family: "SF Mono", Monaco, monospace; font-size: 0.9em; line-height: 1.1;'>
                $message_part
            </div>
        </div>
    </div>
</div>
INNEREOF
    done
else
    cat >> "$DASHBOARD" << INNEREOF
<div style='text-align: center; padding: 40px; color: #8b949e;'>
    <div style='font-size: 3.5em; margin-bottom: 15px; opacity: 0.5;'>📭</div>
    <div style='font-size: 1.1em; margin-bottom: 8px;'>No hay eventos en sesión actual</div>
    <div style='font-size: 0.9em;'>El script VPN está iniciando...</div>
</div>
INNEREOF
fi

cat >> "$DASHBOARD" << EOF
        </div>
    </div>
</div>
</div>

<!-- LOG COMPLETO -->
<div class="card">
    <h2>📋 Log del Sistema (Últimas 15 líneas)</h2>
    <pre>$(if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then tail -n 15 "$LOG_FILE" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; else echo "No hay log disponible aún... El archivo se creará 
cuando el script VPN inicie."; fi)</pre>
</div>

<!-- FOOTER INFORMATIVO -->
<div class="footer">
    <div style="margin-bottom: 15px;">
        <span style="color: #58a6ff; font-weight: bold; font-size: 1.1em;">🚀 Dashboard ProtonVPN v2.3</span>
        <span style="color: #8b949e; margin: 0 10px;">•</span>
        <span style="color: #8b949e;">Generado automáticamente cada 6 minutos</span>
    </div>
    
    <div style="display: flex; justify-content: center; flex-wrap: wrap; gap: 20px; margin-top: 15px;">
        <div style="text-align: center;">
            <div style="color: #ffa657; font-size: 1.2em; font-weight: bold;">🔥 $TEMPERATURE</div>
            <div style="color: #8b949e; font-size: 0.85em;">CPU Temp</div>
        </div>
        <div style="text-align: center;">
            <div style="color: #a371f7; font-size: 1.2em; font-weight: bold;">💾 ${mem_used}%</div>
            <div style="color: #8b949e; font-size: 0.85em;">RAM Usada</div>
        </div>
        <div style="text-align: center;">
            <div style="color: #ff79c6; font-size: 1.2em; font-weight: bold;">⏱️ $uptime</div>
            <div style="color: #8b949e; font-size: 0.85em;">Uptime</div>
        </div>
        <div style="text-align: center;">
            <div style="color: #3fb950; font-size: 1.2em; font-weight: bold;">🔋 ${battery_percent}%</div>
            <div style="color: #8b949e; font-size: 0.85em;">Batería $BATTERY_EMOJI</div>
        </div>
    </div>
    
    <div style="margin-top: 20px; padding-top: 15px; border-top: 1px solid #30363d;">
        <div style="color: #6e7681; font-size: 0.85em; display: flex; justify-content: center; flex-wrap: wrap; gap: 15px;">
            <span>✅ <strong>$SUCCESS_COUNT</strong> éxitos</span>
            <span>⚠️ <strong>$ERROR_COUNT</strong> errores</span>
            <span>🔌 <strong>$VPN_DISC_COUNT</strong> desconexiones</span>
            <span>🔄 <strong>$PORT_CHANGES</strong> cambios</span>
        </div>
    </div>
</div>

</div>

<!-- SCRIPT PARA EFECTOS VISUALES -->
<script>
// Indicador en vivo que parpadea
function updateLiveIndicator() {
    const indicator = document.getElementById('live-indicator');
    if (indicator) {
        indicator.style.opacity = indicator.style.opacity === '0.5' ? '1' : '0.5';
        indicator.style.textShadow = indicator.style.opacity === '1' ? 
            '0 0 10px #3fb950, 0 0 20px #3fb950' : 'none';
    }
}

// Actualizar color de temperatura basado en valor
function updateTemperatureColor() {
    const tempElement = document.getElementById('cpu-temp');
    if (tempElement) {
        const tempText = tempElement.textContent;
        const tempMatch = tempText.match(/(\d+)/);
        if (tempMatch) {
            const temp = parseInt(tempMatch[1]);
            if (temp < 50) {
                tempElement.style.color = '#3fb950';
                tempElement.classList.remove('glow');
            } else if (temp < 70) {
                tempElement.style.color = '#ffa657';
                tempElement.classList.remove('glow');
            } else {
                tempElement.style.color = '#f85149';
                tempElement.classList.add('glow');
            }
        }
    }
}

// Efecto de pulso para estadísticas importantes
function pulseImportantStats() {
    const importantStats = ['$ERROR_COUNT', '$VPN_DISC_COUNT'];
    const statBoxes = document.querySelectorAll('.stat-value');
    
    statBoxes.forEach(box => {
        const value = box.textContent;
        if (importantStats.includes(value) && parseInt(value) > 0) {
            box.classList.add('pulse');
        } else {
            box.classList.remove('pulse');
        }
    });
}

// Actualizar hora actual
function updateCurrentTime() {
    const now = new Date();
    const timeElement = document.getElementById('current-time');
    if (timeElement) {
        timeElement.textContent = now.toLocaleTimeString('es-ES', { 
            hour12: false,
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });
    }
}

// Auto-scroll suave para el historial
function autoScrollHistory() {
    const historyContainer = document.querySelector('.card:last-child div[style*="max-height"]');
    if (historyContainer && historyContainer.scrollHeight > historyContainer.clientHeight) {
        historyContainer.scrollTop = historyContainer.scrollHeight;
    }
}

// Inicializar todo cuando la página cargue
document.addEventListener('DOMContentLoaded', function() {
    updateTemperatureColor();
    pulseImportantStats();
    autoScrollHistory();
    
    // Configurar intervalos
    setInterval(updateLiveIndicator, 800);
    setInterval(updateTemperatureColor, 15000);
    setInterval(pulseImportantStats, 10000);
    setInterval(updateCurrentTime, 1000);
    
    // Actualizar hora inmediatamente
    updateCurrentTime();
    
    // Agregar hora al título si no existe
    if (!document.getElementById('current-time')) {
        const title = document.querySelector('p');
        if (title) {
            const timeSpan = document.createElement('span');
            timeSpan.id = 'current-time';
            timeSpan.style.color = '#58a6ff';
            timeSpan.style.marginLeft = '10px';
            title.appendChild(document.createTextNode(' | '));
            title.appendChild(timeSpan);
        }
    }
});

// Efecto hover mejorado para tarjetas
document.querySelectorAll('.card').forEach(card => {
    card.addEventListener('mouseenter', function() {
        this.style.zIndex = '8';
    });
    card.addEventListener('mouseleave', function() {
        this.style.zIndex = '1';
    });
});
</script>
</body>
</html>
EOF

echo "✅ Dashboard mejorado actualizado y recreado usar comando open ~/vpn_dashboard.html para abrir panel: $DASHBOARD"

