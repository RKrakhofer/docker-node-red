# Dockerized Node-RED with Canvas Support

This repository provides a **Dockerfile** for running Node-RED with additional **Canvas support**. It is built on top of the official Node-RED Docker image and includes necessary dependencies for graphics rendering.

## Features
- Based on official **Node-RED 4.1.5** (Node.js 20)
- Includes necessary **system libraries** for rendering (Cairo, Pango, Fontconfig, Pixman, etc.)
- Installs **canvas** for graphical operations in Node-RED
- Persistent data storage with Docker volumes
- Healthcheck monitoring
- Runs as the **node-red** user for security

## Security & Updates

> **Note on Base Image Updates:**  
> Current version uses Node.js 20 Alpine base image. Waiting for official Node-RED release with Node.js 24 support to reduce security vulnerabilities (currently -3H, -2L compared to Node 20).  
> Base image will be updated once `nodered/node-red` officially supports Node 24 Alpine.

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/RKrakhofer/docker-node-red.git
cd docker-node-red
```

### 2. Build & Start
```bash
docker compose up -d
```

### 3. Access Node-RED
Open your browser and navigate to:
```
http://localhost:1880
```

## Configuration

### Docker Compose Setup
The `docker-compose.yml` includes:
- **Volume mounting** for persistent data storage
- **Healthcheck configuration** for monitoring
- **Auto-restart policy** (unless manually stopped)

```yaml
services:
  node-red:
    build: 
      context: .
      dockerfile: Dockerfile
    volumes:
      - node-red-volume:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:1880/healthcheck"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Dynamic Docker Group
The build process automatically:
1. **Detects** the host Docker group GID
2. **Creates** matching group in container
3. **Adds** node-red user to Docker group
4. **Enables** Docker socket access without root

## Security Features
- ✅ **No root user**: Node-RED runs as `node-red` user
- ✅ **Docker group access**: Minimal required permissions
- ✅ **Dynamic GID**: Adapts to any host system
- ✅ **Container isolation**: Proper user namespacing

## Installed System Dependencies
The following system libraries are installed for **Canvas** and **Docker** support:
- `build-base`
- `cairo-dev`
- `pango-dev`
- `giflib-dev`
- `libjpeg-turbo-dev`
- `freetype-dev`
- `pixman-dev`
- `pkgconf`
- `fontconfig`
- `ttf-dejavu`
- `font-noto`
- `curl` (for healthchecks)
- `docker-cli` (for container management)

## API Endpoints
- **GET /**: Node-RED web interface
- **GET /healthcheck**: Custom healthcheck endpoint
  - Returns HTTP 200 (healthy) or 503 (unhealthy)
  - JSON response with timestamp and health status

## Container Management

### Accessing Node-RED
- **Web Interface**: http://localhost:1880
- **Healthcheck**: http://localhost:1880/healthcheck

### Container Commands
```bash
# View container status (including health)
docker compose ps
      start_period: 40s
```

## Management Commands

```bash
# Build the image
docker compose build

# Start the container
docker compose up -d

# Stop the container
docker compose down

# View healthcheck status
docker inspect node-red | grep -A 10 Health

# View logs
docker compose logs -f node-red

# Restart container
docker compose restart node-red
```

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker compose logs node-red

# Rebuild completely
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Healthcheck Failures
```bash
# Test healthcheck manually
docker exec node-red curl -f http://localhost:1880/healthcheck

# The healthcheck endpoint is provided by Node-RED
```

## File Structure
```
├── Dockerfile                # Custom Node-RED image with Canvas
├── docker-compose.yml        # Container configuration
└── README.md                 # This file
```

## Data Persistence

All Node-RED data (flows, settings, installed nodes) is stored in the `node-red-volume` Docker volume:
```bash
# Inspect volume
docker volume inspect node-red-volume

# Backup volume
docker run --rm -v node-red-volume:/data -v $(pwd):/backup alpine tar czf /backup/node-red-backup.tar.gz /data

# Restore volume
docker run --rm -v node-red-volume:/data -v $(pwd):/backup alpine tar xzf /backup/node-red-backup.tar.gz -C /
```

## License
This project is licensed under the **MIT License**.

## Repository
GitHub Repository: [docker-node-red](https://github.com/RKrakhofer/docker-node-red)

