#!/bin/bash

# build.sh
# Einfacher Build ohne Host-spezifische Konfiguration
# Image funktioniert auf jedem Host durch dynamischen Entrypoint

echo "� Baue universelles Node-RED Image..."
echo "🌍 Image funktioniert auf jedem Host (dynamische Docker-Gruppe)"

# Stoppe bestehende Container
echo "🛑 Stoppe bestehende Container..."
docker compose down 2>/dev/null || true

# Baue universelles Image
echo "🏗️  Baue Image..."
docker build --no-cache -t node-red-node-red .

if [ $? -ne 0 ]; then
    echo "❌ Docker Build fehlgeschlagen!"
    exit 1
fi

# Starte Container
echo "🚀 Starte Container..."
docker compose up -d

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Container erfolgreich gestartet!"
    echo "🌍 Image funktioniert auf jedem Host (universell)"
    echo "🌐 Node-RED: http://localhost:1880"
    echo "💚 Healthcheck: http://localhost:1880/healthcheck"
    echo ""
    echo "🔧 Debug-Befehle:"
    echo "  docker compose ps                    # Container Status"
    echo "  docker compose logs -f node-red     # Live Logs"
    echo "  docker exec node-red id             # User/Group Info"
    echo "  docker exec node-red ls -la /var/run/docker.sock  # Socket Permissions"
else
    echo "❌ Container-Start fehlgeschlagen!"
    exit 1
fi