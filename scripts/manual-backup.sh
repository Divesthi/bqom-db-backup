#!/bin/bash
# ─────────────────────────────────────────────────────────────
# manual-backup.sh
# Run this locally to trigger a one-off Supabase backup
# to Google Drive using the same logic as the GitHub Action.
#
# Usage:
#   chmod +x scripts/manual-backup.sh
#   DATABASE_URL="your_db_url" GDRIVE_FOLDER_ID="your_folder_id" ./scripts/manual-backup.sh
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# ── Validate required env vars ───────────────────────────────
: "${DATABASE_URL:?❌ DATABASE_URL is not set}"
: "${GDRIVE_FOLDER_ID:?❌ GDRIVE_FOLDER_ID is not set}"
GDRIVE_SA_FILE="${GDRIVE_SA_FILE:-/tmp/gdrive-sa.json}"

echo "🚀 Starting manual Supabase backup..."

# ── Create backup filename ───────────────────────────────────
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="backup_${TIMESTAMP}.dump"

# ── Dump database ────────────────────────────────────────────
echo "📦 Dumping database..."
pg_dump "$DATABASE_URL" \
  --format=custom \
  --no-acl \
  --no-owner \
  --file="$FILENAME"

echo "✅ Dump created: $FILENAME ($(du -sh "$FILENAME" | cut -f1))"

# ── Configure rclone ─────────────────────────────────────────
mkdir -p ~/.config/rclone
cat > ~/.config/rclone/rclone.conf << EOF
[gdrive]
type = drive
scope = drive
service_account_file = ${GDRIVE_SA_FILE}
root_folder_id = ${GDRIVE_FOLDER_ID}
EOF

# ── Upload to Google Drive ───────────────────────────────────
echo "☁️  Uploading to Google Drive..."
rclone copy "$FILENAME" gdrive:supabase-backups/ --progress

echo "✅ Uploaded: supabase-backups/$FILENAME"

# ── Clean up local file ──────────────────────────────────────
rm -f "$FILENAME"
echo "🧹 Local file cleaned up."
echo ""
echo "🎉 Manual backup complete!"
