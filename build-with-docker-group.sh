#!/bin/bash

# build-with-docker-group.sh
# Dynamisch Docker-Gruppe ermitteln und Container bauen

echo "Ermittle Docker-Gruppe GID..."
DOCKER_GID=$(getent group docker | cut -d: -f3)

if [ -z "$DOCKER_GID" ]; then
    echo "Fehler: Docker-Gruppe nicht gefunden!"
    echo "Stelle sicher, dass Docker installiert ist und die Gruppe existiert."
    exit 1
fi

echo "Docker-Gruppe GID: $DOCKER_GID"

# Stoppe bestehende Container
echo "Stoppe bestehende Container..."
docker compose down

# Baue Image mit dynamischer Docker-GID
echo "Baue Node-RED Image mit Docker-Gruppe GID $DOCKER_GID..."
docker build \
    --build-arg DOCKER_GID=$DOCKER_GID \
    --no-cache \
    -t node-red-node-red \
    .

# Starte Container
echo "Starte Container..."
docker compose up -d

echo "✅ Container erfolgreich gestartet mit Docker-Gruppe GID: $DOCKER_GID"
echo "Node-RED läuft unter: http://localhost:1880"