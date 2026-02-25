#!/bin/bash
# =============================================================================
# MONITOR DE SERVICIOS
# Comprueba si los servicios definidos están corriendo.
# Si alguno está caído, lo reinicia y registra el evento en el log.
# Uso: ./1_monitor_servicios.sh
# Cron recomendado: */5 * * * * /ruta/1_monitor_servicios.sh
# =============================================================================

# --- CONFIGURACIÓN ---
SERVICES=("nginx" "ssh" "cron")          # Lista de servicios a monitorizar
LOG_FILE="/var/log/service-monitor.log"  # Archivo de log
MAX_REINTENTOS=3                         # Intentos antes de marcar como fallo crítico

# --- COLORES (solo para salida por terminal, no van al log) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# --- FUNCIONES ---
log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

check_log_file() {
    # Crear el archivo de log si no existe
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE" 2>/dev/null || {
            echo -e "${RED}ERROR:${NC} No se puede crear el log en $LOG_FILE. ¿Tienes permisos?"
            exit 1
        }
    fi
}

check_service() {
    local service="$1"

    if systemctl is-active --quiet "$service"; then
        echo -e "  [${GREEN}OK${NC}]  $service está corriendo"
        log "INFO" "$service está corriendo correctamente"
        return 0
    else
        echo -e "  [${RED}DOWN${NC}] $service está CAÍDO — intentando reiniciar..."
        log "WARN" "$service estaba caído. Iniciando reinicio..."

        # Intentar reiniciar
        local intento=1
        while [ $intento -le $MAX_REINTENTOS ]; do
            systemctl start "$service" 2>/dev/null
            sleep 2

            if systemctl is-active --quiet "$service"; then
                echo -e "  [${YELLOW}RECOVERED${NC}] $service reiniciado correctamente (intento $intento)"
                log "RECOVERED" "$service reiniciado con éxito en el intento $intento"
                return 0
            fi

            log "WARN" "Intento $intento/$MAX_REINTENTOS fallido para $service"
            ((intento++))
        done

        # Si llegamos aquí, el servicio no pudo reiniciarse
        echo -e "  [${RED}CRITICAL${NC}] $service NO pudo reiniciarse después de $MAX_REINTENTOS intentos"
        log "CRITICAL" "$service NO pudo reiniciarse después de $MAX_REINTENTOS intentos — REQUIERE ATENCIÓN MANUAL"
        return 1
    fi
}

# --- MAIN ---
check_log_file

echo "============================================"
echo " Monitor de Servicios — $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
log "INFO" "=== Inicio de comprobación de servicios ==="

FALLOS=0
for service in "${SERVICES[@]}"; do
    check_service "$service" || ((FALLOS++))
done

echo "--------------------------------------------"
if [ $FALLOS -eq 0 ]; then
    echo -e "  Resultado: ${GREEN}Todos los servicios OK${NC}"
    log "INFO" "Comprobación completada — Todos los servicios OK"
else
    echo -e "  Resultado: ${RED}$FALLOS servicio(s) con problemas${NC}"
    log "WARN" "Comprobación completada — $FALLOS servicio(s) con problemas"
fi
echo "============================================"

exit $FALLOS
