#!/bin/bash
BACKUP_DIR="./"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

sudo -u postgres pg_dump pharmacy > "$BACKUP_DIR/backup_${TIMESTAMP}.sql"