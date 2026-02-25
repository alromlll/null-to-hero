#!/bin/bash
# =============================================================================
# MONITOR DE DISCO
# Comprueba el uso de todos los discos/particiones montados.
# Genera alertas cuando se superan los umbrales definidos.
# Uso: ./3_monitor_disco.sh
# Cron recomendado: */30 * * * * /ruta/3_monitor_disco.sh
# =============================================================================

# --- CONFIGURACIÓN ---
UMBRAL_WARN=70          # % de uso para advertencia (amarillo)
UMBRAL_CRIT=85          # % de uso para crítico (rojo)
UMBRAL_EMERG=95         # % de uso para emergencia (crítico máximo)
LOG_FILE="/var/log/disk-monitor.log"
# Puntos de montaje a IGNORAR (separados por espacio)
EXCLUIR=("/dev" "/run" "/sys/fs" "/proc")

# --- COLORES ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- FUNCIONES ---
log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

esta_excluido() {
    local punto="$1"
    for excluido in "${EXCLUIR[@]}"; do
        [[ "$punto" == "$excluido"* ]] && return 0
    done
    return 1
}

get_estado_color() {
    local pct="$1"
    if [ "$pct" -ge "$UMBRAL_EMERG" ]; then
        echo "${RED}"
        return 3
    elif [ "$pct" -ge "$UMBRAL_CRIT" ]; then
        echo "${RED}"
        return 2
    elif [ "$pct" -ge "$UMBRAL_WARN" ]; then
        echo "${YELLOW}"
        return 1
    else
        echo "${GREEN}"
        return 0
    fi
}

get_nivel() {
    local pct="$1"
    if [ "$pct" -ge "$UMBRAL_EMERG" ]; then
        echo "EMERGENCIA"
    elif [ "$pct" -ge "$UMBRAL_CRIT" ]; then
        echo "CRITICO"
    elif [ "$pct" -ge "$UMBRAL_WARN" ]; then
        echo "AVISO"
    else
        echo "OK"
    fi
}

barra_progreso() {
    local pct="$1"
    local ancho=20
    local llenos=$(( pct * ancho / 100 ))
    local vacios=$(( ancho - llenos ))
    local barra="["
    
    for ((i=0; i<llenos; i++)); do barra+="█"; done
    for ((i=0; i<vacios; i++)); do barra+="░"; done
    barra+="]"
    
    echo "$barra"
}

buscar_archivos_grandes() {
    local punto="$1"
    local top=5
    echo ""
    echo -e "      ${CYAN}Top $top archivos más grandes en $punto:${NC}"
    find "$punto" -maxdepth 4 -type f -printf '%s %p\n' 2>/dev/null \
        | sort -rn \
        | head -n $top \
        | while read -r size path; do
            local hr_size
            hr_size=$(numfmt --to=iec-i --suffix=B "$size" 2>/dev/null || echo "${size}B")
            echo "        $hr_size  $path"
        done
}

verificar_inodos() {
    # Los inodos agotados también impiden escribir archivos aunque haya espacio
    local punto="$1"
    local uso_inode
    uso_inode=$(df -i "$punto" 2>/dev/null | awk 'NR==2 {gsub("%",""); print $5}')
    
    if [ -n "$uso_inode" ] && [ "$uso_inode" -gt 80 ] 2>/dev/null; then
        echo -e "      ${YELLOW}⚠ Inodos: ${uso_inode}% usados${NC}"
        log "WARN" "Inodos al ${uso_inode}% en $punto — puede impedir crear nuevos archivos"
    fi
}

# --- MAIN ---
touch "$LOG_FILE" 2>/dev/null

echo "============================================"
echo -e " ${BOLD}Monitor de Disco${NC} — $(date '+%Y-%m-%d %H:%M:%S')"
echo -e " Umbrales: ${YELLOW}AVISO >$UMBRAL_WARN%${NC} | ${RED}CRITICO >$UMBRAL_CRIT%${NC} | ${RED}${BOLD}EMERGENCIA >$UMBRAL_EMERG%${NC}"
echo "============================================"
log "INFO" "=== Inicio de comprobación de discos ==="

AVISOS=0
CRITICOS=0
EMERGENCIAS=0

# Leer particiones del sistema (excluimos tmpfs, devtmpfs, etc.)
while IFS= read -r linea; do
    # Extraer campos: filesystem, tamaño, usado, disponible, %, punto de montaje
    read -r filesystem size used avail pct_raw mount <<< "$linea"
    
    # Limpiar el porcentaje (quitar %)
    pct="${pct_raw%\%}"
    
    # Saltar si no es un número
    [[ "$pct" =~ ^[0-9]+$ ]] || continue
    
    # Saltar puntos de montaje excluidos
    esta_excluido "$mount" && continue

    # Obtener color y nivel
    color=$(get_estado_color "$pct")
    nivel=$(get_nivel "$pct")
    barra=$(barra_progreso "$pct")

    # Mostrar línea
    printf "  %s%s %-25s %s %3d%%%s\n" \
        "$color" "$barra" "$mount" "$(echo "${NC}")" "$pct" "${NC}"
    printf "      Usado: %-8s  Libre: %-8s  Total: %s\n" "$used" "$avail" "$size"
    
    # Verificar inodos
    verificar_inodos "$mount"

    # Registrar en log según nivel
    case "$nivel" in
        "OK")
            log "INFO" "OK — $mount al ${pct}% (Usado: $used / Total: $size)"
            ;;
        "AVISO")
            echo -e "      ${YELLOW}⚠ AVISO: $mount supera el $UMBRAL_WARN%${NC}"
            log "WARN" "AVISO — $mount al ${pct}% (Usado: $used / Libre: $avail)"
            ((AVISOS++))
            ;;
        "CRITICO")
            echo -e "      ${RED}✖ CRÍTICO: $mount supera el $UMBRAL_CRIT% — Liberar espacio pronto${NC}"
            log "CRITICAL" "CRÍTICO — $mount al ${pct}% (Usado: $used / Libre: $avail)"
            buscar_archivos_grandes "$mount"
            ((CRITICOS++))
            ;;
        "EMERGENCIA")
            echo -e "      ${RED}${BOLD}✖✖ EMERGENCIA: $mount al ${pct}% — ACCIÓN INMEDIATA NECESARIA${NC}"
            log "CRITICAL" "EMERGENCIA — $mount al ${pct}% (LIBRE SOLO: $avail) — ACCIÓN INMEDIATA"
            buscar_archivos_grandes "$mount"
            ((EMERGENCIAS++))
            ;;
    esac
    echo ""

done < <(df -h --output=source,size,used,avail,pcent,target 2>/dev/null \
    | grep -v "^Filesystem\|tmpfs\|devtmpfs\|udev\|overlay\|squashfs" \
    | awk 'NF==6')

# --- RESUMEN FINAL ---
echo "--------------------------------------------"
echo -e "  Resumen:"
echo -e "    ${GREEN}OK${NC}:          $(( $(df -h | grep -v "^Filesystem\|tmpfs\|devtmpfs" | wc -l) - AVISOS - CRITICOS - EMERGENCIAS )) partición(es)"
[ $AVISOS -gt 0 ]      && echo -e "    ${YELLOW}Avisos${NC}:      $AVISOS partición(es) > ${UMBRAL_WARN}%"
[ $CRITICOS -gt 0 ]    && echo -e "    ${RED}Críticos${NC}:    $CRITICOS partición(es) > ${UMBRAL_CRIT}%"
[ $EMERGENCIAS -gt 0 ] && echo -e "    ${RED}${BOLD}Emergencias${NC}: $EMERGENCIAS partición(es) > ${UMBRAL_EMERG}%"

log "INFO" "Comprobación completada — Avisos: $AVISOS | Críticos: $CRITICOS | Emergencias: $EMERGENCIAS"
echo "============================================"

# Código de salida: 0=todo OK, 1=avisos, 2=críticos, 3=emergencias
[ $EMERGENCIAS -gt 0 ] && exit 3
[ $CRITICOS -gt 0 ]    && exit 2
[ $AVISOS -gt 0 ]      && exit 1
exit 0
