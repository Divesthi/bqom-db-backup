# 🗄️ Supabase Backup — GitHub Actions

Automated weekly backup of a Supabase PostgreSQL database to **Google Drive**, with **Telegram notifications** on success and failure.

---

## 📁 Project Structure

```
supabase-backup/
├── .github/
│   └── workflows/
│       └── supabase-backup.yml   # GitHub Actions workflow
├── scripts/
│   ├── manual-backup.sh          # Run a backup manually from your machine
│   └── restore.sh                # Restore a backup from Google Drive
├── .env.example                  # Environment variable template
├── .gitignore
└── README.md
```

---

## ⚙️ How It Works

1. **GitHub Actions** triggers every Sunday at 2:00 AM UTC
2. `pg_dump` creates a `.dump` file of your Supabase database
3. `rclone` uploads the file to a folder in **Google Drive**
4. Backups older than **90 days** are automatically deleted
5. A **Telegram message** is sent on success or failure

---

## 🚀 Setup

### 1. GitHub Secrets

Go to your repo → **Settings → Secrets and variables → Actions** and add:

| Secret | Description |
|---|---|
| `SUPABASE_DATABASE_URL` | Supabase → Settings → Database → URI connection string |
| `GDRIVE_SERVICE_ACCOUNT_JSON` | Full contents of your Google Cloud service account JSON key |
| `GDRIVE_FOLDER_ID` | ID from your Google Drive backup folder URL |
| `TELEGRAM_BOT_TOKEN` | Token from Telegram @BotFather |
| `TELEGRAM_CHAT_ID` | Your Telegram chat ID (see setup below) |

---

### 2. Google Drive Setup

1. Go to [console.cloud.google.com](https://console.cloud.google.com) → create a free project
2. Enable the **Google Drive API** under APIs & Services
3. Go to **IAM & Admin → Service Accounts → Create Service Account**
4. Under **Keys**, create a new **JSON key** and download it
5. Create a folder in your Google Drive called `supabase-backups`
6. Share the folder with the service account email (Editor access)
7. Copy the folder ID from the URL and save as `GDRIVE_FOLDER_ID`

---

### 3. Telegram Bot Setup

1. Open Telegram → search **@BotFather** → `/newbot`
2. Copy the **Bot Token** → save as `TELEGRAM_BOT_TOKEN`
3. Send a message to your bot, then open:
   ```
   https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
   ```
4. Find `"chat":{"id": ...}` → save as `TELEGRAM_CHAT_ID`

---

## 🖥️ Running Locally

### Manual Backup
```bash
cp .env.example .env
# Fill in your values in .env

chmod +x scripts/manual-backup.sh
source .env
./scripts/manual-backup.sh
```

### Restore from Backup
```bash
chmod +x scripts/restore.sh
source .env
./scripts/restore.sh backup_2025-01-01_02-00-00.dump
```

---

## 📅 Changing the Schedule

Edit the cron expression in `.github/workflows/supabase-backup.yml`:

```yaml
- cron: '0 2 * * 0'   # Every Sunday at 2:00 AM UTC
```

Use [crontab.guru](https://crontab.guru) to generate a custom schedule.

---

## 📬 Telegram Notifications

| Event | Message |
|---|---|
| ✅ Success | Filename, date, Google Drive location |
| ❌ Failure | Date, direct link to GitHub Actions log |
