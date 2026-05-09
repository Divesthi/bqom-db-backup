#!/bin/bash
# ─────────────────────────────────────────────────────────────
# restore.sh
# Restore a Supabase database from a backup file in Google Drive.
#
# Usage:
#   chmod +x scripts/restore.sh
#   ./scripts/restore.sh backup_2025-01-01_02-00-00.dump
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# ── Validate inputs ──────────────────────────────────────────
BACKUP_FILE="${1:?❌ Usage: ./scripts/restore.sh <backup_filename>}"
: "${DATABASE_URL:?❌ DATABASE_URL is not set}"
GDRIVE_SA_FILE="${GDRIVE_SA_FILE:-/tmp/gdrive-sa.json}"
: "${GDRIVE_FOLDER_ID:?❌ GDRIVE_FOLDER_ID is not set}"

echo "⚠️  WARNING: This will OVERWRITE your current database!"
echo "   Restoring: $BACKUP_FILE"
read -rp "   Are you sure? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "❌ Restore cancelled."
  exit 1
fi

# ── Configure rclone ─────────────────────────────────────────
mkdir -p ~/.config/rclone
cat > ~/.config/rclone/rclone.conf << EOF
[gdrive]
type = drive
scope = drive
service_account_file = ${GDRIVE_SA_FILE}
root_folder_id = ${GDRIVE_FOLDER_ID}
EOF

# ── Download backup from Google Drive ───────────────────────
echo "⬇️  Downloading $BACKUP_FILE from Google Drive..."
rclone copy "gdrive:supabase-backups/$BACKUP_FILE" . --progress

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "❌ Download failed. File not found: $BACKUP_FILE"
  exit 1
fi

echo "✅ Downloaded: $BACKUP_FILE ($(du -sh "$BACKUP_FILE" | cut -f1))"

# ── Restore database ─────────────────────────────────────────
echo "🔄 Restoring database..."
pg_restore "$DATABASE_URL" \
  --format=custom \
  --no-acl \
  --no-owner \
  --clean \
  --if-exists \
  "$BACKUP_FILE"

# ── Clean up downloaded file ─────────────────────────────────
rm -f "$BACKUP_FILE"
echo "🧹 Local file cleaned up."
echo ""
echo "🎉 Restore complete!"
