#!/bin/bash
# =============================================================================
# BACKUP AUTOMÁTICO
# Realiza copias de seguridad comprimidas de los directorios definidos.
# Gestiona retención automática (borra backups más antiguos que N días).
# Uso: ./2_backup_automatico.sh
# Cron recomendado: 0 2 * * * /ruta/2_backup_automatico.sh
# =============================================================================

# --- CONFIGURACIÓN ---
BACKUP_DIRS=("/etc" "/home" "/var/www")  # Directorios a respaldar
DEST_BASE="/mnt/data/backups"            # Destino base de los backups
RETENTION_DAYS=7                         # Días que se conservan los backups
LOG_FILE="/var/log/backup.log"           # Archivo de log
MIN_FREE_GB=2                            # GB mínimos libres para hacer backup

# --- COLORES ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- FECHA para nombres de archivo ---
FECHA=$(date '+%Y%m%d_%H%M%S')
DEST_DIR="$DEST_BASE/$FECHA"

# --- FUNCIONES ---
log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

check_prerequisites() {
    # Crear directorio de destino
    mkdir -p "$DEST_DIR" 2>/dev/null || {
        echo -e "${RED}ERROR:${NC} No se puede crear el directorio $DEST_DIR"
        log "ERROR" "No se puede crear el directorio de destino: $DEST_DIR"
        exit 1
    }

    # Crear archivo de log si no existe
    touch "$LOG_FILE" 2>/dev/null || {
        echo -e "${RED}ERROR:${NC} No se puede escribir en $LOG_FILE"
        exit 1
    }

    # Comprobar espacio libre
    local free_gb
    free_gb=$(df -BG "$DEST_BASE" | awk 'NR==2 {gsub("G",""); print $4}')
    if [ "$free_gb" -lt "$MIN_FREE_GB" ]; then
        echo -e "${RED}ERROR:${NC} Espacio insuficiente en $DEST_BASE (${free_gb}GB libres, mínimo ${MIN_FREE_GB}GB)"
        log "ERROR" "Espacio insuficiente en $DEST_BASE — ${free_gb}GB libres"
        exit 1
    fi

    echo -e "  Espacio libre en destino: ${GREEN}${free_gb}GB${NC}"
}

backup_dir() {
    local source="$1"
    local nombre
    nombre=$(echo "$source" | tr '/' '_' | sed 's/^_//')
    local destino="$DEST_DIR/${nombre}_${FECHA}.tar.gz"

    if [ ! -d "$source" ]; then
        echo -e "  [${YELLOW}SKIP${NC}]  $source — directorio no existe"
        log "WARN" "Directorio no encontrado, omitido: $source"
        return 1
    fi

    echo -ne "  [....] Respaldando $source..."
    
    # Hacer el backup (excluir /proc, /sys, /dev si fuera necesario)
    if tar -czf "$destino" \
        --exclude="*.tmp" \
        --exclude="*.log" \
        "$source" 2>/dev/null; then
        
        local size
        size=$(du -sh "$destino" | cut -f1)
        echo -e "\r  [${GREEN}OK${NC}]  Respaldo de $source completado (${size})"
        log "INFO" "Backup exitoso: $source → $destino (${size})"
        return 0
    else
        echo -e "\r  [${RED}FAIL${NC}] Error al respaldar $source"
        log "ERROR" "Fallo al crear backup de $source"
        rm -f "$destino"  # Limpiar archivo corrupto
        return 1
    fi
}

limpiar_backups_antiguos() {
    echo ""
    echo -e "  ${BLUE}Limpiando backups con más de $RETENTION_DAYS días...${NC}"
    
    local eliminados=0
    while IFS= read -r -d '' archivo; do
        rm -f "$archivo"
        echo -e "    Eliminado: $(basename "$archivo")"
        log "INFO" "Backup antiguo eliminado: $archivo"
        ((eliminados++))
    done < <(find "$DEST_BASE" -name "*.tar.gz" -mtime +$RETENTION_DAYS -print0 2>/dev/null)

    if [ $eliminados -eq 0 ]; then
        echo -e "  No hay backups antiguos que eliminar"
    else
        echo -e "  ${eliminados} backup(s) eliminado(s)"
        log "INFO" "$eliminados backup(s) antiguos eliminados"
    fi
}

generar_checksum() {
    # Generar SHA256 de todos los backups de esta sesión para verificar integridad
    local checksum_file="$DEST_DIR/checksums.sha256"
    if command -v sha256sum &>/dev/null; then
        find "$DEST_DIR" -name "*.tar.gz" -exec sha256sum {} \; > "$checksum_file" 2>/dev/null
        echo -e "  Checksums guardados en: $checksum_file"
        log "INFO" "Checksums SHA256 generados en $checksum_file"
    fi
}

# --- MAIN ---
echo "============================================"
echo " Backup Automático — $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
log "INFO" "=== Inicio de proceso de backup — Destino: $DEST_DIR ==="

check_prerequisites

echo ""
echo -e "  ${BLUE}Iniciando backups...${NC}"

EXITOSOS=0
FALLIDOS=0

for dir in "${BACKUP_DIRS[@]}"; do
    if backup_dir "$dir"; then
        ((EXITOSOS++))
    else
        ((FALLIDOS++))
    fi
done

generar_checksum
limpiar_backups_antiguos

echo ""
echo "--------------------------------------------"
echo -e "  Exitosos: ${GREEN}$EXITOSOS${NC}  |  Fallidos: ${RED}$FALLIDOS${NC}"
echo -e "  Ubicación: $DEST_DIR"
log "INFO" "Backup completado — Exitosos: $EXITOSOS | Fallidos: $FALLIDOS"
echo "============================================"

[ $FALLIDOS -gt 0 ] && exit 1 || exit 0
