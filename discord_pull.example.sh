#!/bin/bash

# Discord-Benachrichtigung bei Git-Updates
# Kopiere diese Datei zu discord_pull.sh und trage deine Webhook-URL ein.

# Konfiguration
WEBHOOK_URL="YOUR_DISCORD_WEBHOOK_URL"
PROJECT_DIR="/media/pi/PROJEKTE/Wasserwage_App"

cd $PROJECT_DIR

# Git Pull ausführen und schauen, ob es Updates gab
UPDATE_MSG=$(git pull)

if [[ "$UPDATE_MSG" != "Already up to date." ]]; then
    LOG_INFO=$(git log -1 --pretty=format:"%h - %an: %s")
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"🚀 **Update**\n\`$LOG_INFO\`\"}" \
         $WEBHOOK_URL
fi
