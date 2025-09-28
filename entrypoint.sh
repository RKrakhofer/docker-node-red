#!/bin/bash

# entrypoint.sh
# Dynamischer Entrypoint der zur Laufzeit die Docker-Gruppe anpasst

echo "🚀 Node-RED Container startet..."
echo "👤 Container User: $(id)"

# Prüfe ob Docker-Socket existiert
if [ -S "/var/run/docker.sock" ]; then
    echo "🐳 Docker-Socket gefunden: /var/run/docker.sock"
    
    # Ermittle GID des Docker-Sockets vom Host
    DOCKER_SOCK_GID=$(stat -c %g /var/run/docker.sock)
    echo "📋 Docker-Socket GID: $DOCKER_SOCK_GID"
    
    # Erstelle/aktualisiere Docker-Gruppe mit der richtigen GID
    if getent group docker > /dev/null 2>&1; then
        echo "🔄 Aktualisiere bestehende Docker-Gruppe..."
        groupmod -g $DOCKER_SOCK_GID docker
    else
        echo "➕ Erstelle Docker-Gruppe mit GID $DOCKER_SOCK_GID..."
        addgroup -g $DOCKER_SOCK_GID docker
    fi
    
    # Füge node-red User zur Docker-Gruppe hinzu
    echo "👥 Füge node-red zur Docker-Gruppe hinzu..."
    adduser node-red docker
    
    echo "✅ Docker-Socket Zugriff konfiguriert"
else
    echo "⚠️  Docker-Socket nicht gefunden - Container-Restart nicht verfügbar"
fi

# Wechsle zu node-red User und starte Node-RED
echo "🔄 Starte Node-RED als node-red user..."
exec su-exec node-red node-red "$@"