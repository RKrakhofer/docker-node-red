#!/bin/bash
#
# Node-RED Healthcheck-Monitor
# Prüft den Health-Endpunkt alle 5 Minuten, startet nach 3 Fehlern neu.
#
# HINWEIS: Läuft auf dem Docker-Host (nicht im Container!).
# Überwacht den node-red Container von außen per HTTP.
# Ausführungsort: reserve (SSH: richard@reserve)
#
# Erstellt: 2025-11-13
# Crontab:  */5 * * * * /home/richard/workspaces/node-red/healthcheck-monitor.sh
#

# Configuration
HEALTHCHECK_URL="http://node-red.krakhofer.org:1880/healthcheck"
FAILURE_THRESHOLD=3
STATE_FILE="/tmp/node-red-healthcheck-state"
LOG_FILE="$HOME/node-red-healthcheck.log"
DOCKER_CONTAINER="node-red"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to send notification (optional - configure as needed)
send_notification() {
    local message="$1"
    # Example: echo "$message" | mail -s "Node-RED Alert" admin@example.com
    # Example: curl -X POST "https://api.telegram.org/bot<token>/sendMessage" -d "chat_id=<id>&text=$message"
    log "NOTIFICATION: $message"
}

# Initialize state file if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo "0" > "$STATE_FILE"
    log "Initialized state file: $STATE_FILE"
fi

# Read current failure count
FAILURE_COUNT=$(cat "$STATE_FILE")

# Perform healthcheck with timeout
log "Performing healthcheck: $HEALTHCHECK_URL"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$HEALTHCHECK_URL" 2>&1)
CURL_EXIT=$?

# Check if curl succeeded and HTTP status is 200
if [ $CURL_EXIT -eq 0 ] && [ "$HTTP_CODE" = "200" ]; then
    log "✅ Healthcheck PASSED (HTTP $HTTP_CODE)"
    
    # Reset failure count on success
    if [ "$FAILURE_COUNT" -gt 0 ]; then
        log "Resetting failure count from $FAILURE_COUNT to 0"
        send_notification "Node-RED healthcheck recovered after $FAILURE_COUNT failures"
    fi
    echo "0" > "$STATE_FILE"
    
else
    # Increment failure count
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    echo "$FAILURE_COUNT" > "$STATE_FILE"
    
    log "❌ Healthcheck FAILED (HTTP $HTTP_CODE, curl exit: $CURL_EXIT) - Failure count: $FAILURE_COUNT/$FAILURE_THRESHOLD"
    
    # Check if threshold is reached
    if [ "$FAILURE_COUNT" -ge "$FAILURE_THRESHOLD" ]; then
        log "🚨 CRITICAL: Reached $FAILURE_THRESHOLD consecutive failures - Restarting Docker container '$DOCKER_CONTAINER'"
        send_notification "🚨 Node-RED: $FAILURE_THRESHOLD consecutive healthcheck failures detected - Initiating restart"
        
        # Restart Docker container
        if docker restart "$DOCKER_CONTAINER" >> "$LOG_FILE" 2>&1; then
            log "✅ Docker container '$DOCKER_CONTAINER' restarted successfully"
            send_notification "✅ Node-RED container restarted successfully"
            
            # Reset failure count after restart
            echo "0" > "$STATE_FILE"
            
            # Wait 30 seconds and perform verification check
            sleep 30
            VERIFY_HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$HEALTHCHECK_URL" 2>&1)
            if [ "$VERIFY_HTTP" = "200" ]; then
                log "✅ Post-restart verification successful (HTTP $VERIFY_HTTP)"
                send_notification "✅ Node-RED is healthy after restart"
            else
                log "⚠️ Post-restart verification failed (HTTP $VERIFY_HTTP) - May need manual intervention"
                send_notification "⚠️ Node-RED restart completed but healthcheck still failing - Manual check required"
            fi
        else
            log "❌ ERROR: Failed to restart Docker container '$DOCKER_CONTAINER'"
            send_notification "❌ CRITICAL: Failed to restart Node-RED container - Manual intervention required"
        fi
    else
        send_notification "⚠️ Node-RED healthcheck failure $FAILURE_COUNT/$FAILURE_THRESHOLD"
    fi
fi

exit 0
