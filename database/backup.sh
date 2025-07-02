#!/bin/bash
# 简单的MySQL备份脚本

DB_NAME=${1:-car_maintenance_system}
DB_USER=${2:-root}
DB_PASS=${3:-}
BACKUP_DIR="$(dirname "$0")/backups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILE="$BACKUP_DIR/${DB_NAME}_$TIMESTAMP.sql"

mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$FILE"

echo "Backup created at $FILE"

