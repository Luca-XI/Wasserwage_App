#!/bin/bash

# Konfiguration
WEBHOOK_URL="https://discordapp.com/api/webhooks/1469492893080223980/FXHz8kltPyOW-n8eWCN0lJWez7_jQR4CkAEXahoCiwrKHQxnDLuJ3Fz6xzNTcJm438rl"
PROJECT_DIR="/media/pi/PROJEKTE/Wasserwage_App"

cd $PROJECT_DIR

# Git Pull ausführen und schauen, ob es Updates gab
UPDATE_MSG=$(git pull)

if [[ "$UPDATE_MSG" != "Already up to date." ]]; then
    # Wenn es ein Update gab, hol den letzten Log-Eintrag
    LOG_INFO=$(git log -1 --pretty=format:"%h - %an: %s")
    
    # Nachricht an Discord senden
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"🚀 **Update auf dem Pi!**\nNeue Version geladen:\n\`$LOG_INFO\`\"}" \
         $WEBHOOK_URL
fi