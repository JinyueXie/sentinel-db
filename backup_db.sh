#!/bin/bash

# Create backups folder if it doesn't exist
mkdir -p backups

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="backups/sentineldb_$TIMESTAMP.dump"

pg_dump -h localhost -U postgres -d sentineldb -F c -f "$BACKUP_FILE"

echo "✅ Backup saved to $BACKUP_FILE"
