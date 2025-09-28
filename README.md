# Dockerized Node-RED with Canvas Support & Auto-Restart

This repository provides a **Dockerfile** for running Node-RED with additional **Canvas support** and **automatic container restart** functionality. It is built on top of the official Node-RED Docker image and includes necessary dependencies for graphics rendering and Docker socket access.

## Features
- Based on official **Node-RED**:latest
- Includes necessary **system libraries** for rendering (e.g., Cairo, Pango, Fontconfig, Pixman)
- Installs **canvas** for graphical operations in Node-RED
- **Docker CLI** integration for container management
- **Automatic container restart** via Healthcheck
- **Dynamic Docker group** configuration
- Runs as the **node-red** user for security (not root)

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/RKrakhofer/docker-node-red.git
cd docker-node-red
```

### 2. Build & Start (Recommended)
Use the dynamic build script that automatically configures Docker group permissions:
```bash
./build-with-docker-group.sh
```

### 3. Manual Build (Alternative)
```bash
# Get Docker group GID
DOCKER_GID=$(getent group docker | cut -d: -f3)

# Build with Docker group
docker build --build-arg DOCKER_GID=$DOCKER_GID -t node-red-node-red .

# Start with Docker Compose
docker compose up -d
```

## Healthcheck & Auto-Restart

### Features
- **Custom Healthcheck Endpoint**: `/healthcheck`
- **Automatic Container Restart**: When healthcheck fails
- **Docker Socket Integration**: Container can restart itself
- **Flow Context Control**: Set health status from any Node-RED flow

### Available Flows
These flows need to be imported manually in the Node-RED web interface:

#### 1. Simple Healthcheck Flow
- Basic healthcheck without auto-restart
- Uses flow context: `{ health: { state: true|false, text: "message" } }`
- **Import**: Copy and paste the flow from generated `simple-healthcheck-flow.json`

#### 2. Auto-Restart Healthcheck Flow  
- **Automatic container restart** on healthcheck failure
- Includes Docker socket integration
- Test buttons for triggering restarts
- **Import**: Copy and paste the flow from generated `healthcheck-auto-restart-flow.json`

**Note**: Flow JSON files are generated locally and not included in this repository. Import them manually via Node-RED's import function.

### Usage Example
```javascript
// In any Node-RED Function node

// Set healthy status
flow.set('health', {
    state: true,
    text: 'All systems operational'
});

// Trigger container restart
flow.set('health', {
    state: false,
    text: 'Critical error - restarting container'
});
```

## Configuration

### Docker Compose Setup
The `docker-compose.yml` includes:
- **Volume mounting** for persistent data
- **Docker socket access** for container management
- **Healthcheck configuration** with curl
- **Auto-restart policy**

```yaml
services:
  node-red:
    volumes:
      - node-red-volume:/data
      - /var/run/docker.sock:/var/run/docker.sock  # Docker access
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

# View healthcheck logs
docker inspect node-red | grep -A 10 Health

# Manual restart
docker compose restart node-red

# View logs
docker compose logs -f node-red
```

### Testing Auto-Restart
1. Start the container: `./build-with-docker-group.sh`
2. Access Node-RED: http://localhost:1880
3. Create or import an auto-restart healthcheck flow
4. Set unhealthy status via flow context or inject node
5. Wait 5 seconds - container will restart automatically

## Troubleshooting

### Permission Issues
If you get Docker socket permission errors:
```bash
# Rebuild with correct Docker group
./build-with-docker-group.sh
```

### Healthcheck Failures
```bash
# Test healthcheck manually
docker exec node-red curl -f http://localhost:1880/healthcheck

# Check if healthcheck flow is deployed in Node-RED web interface
# Create a flow that responds to GET /healthcheck
```

### Container Won't Start
```bash
# Check logs
docker compose logs node-red

# Rebuild completely
docker compose down
docker system prune -f
./build-with-docker-group.sh
```

## File Structure
```
├── Dockerfile                           # Main Docker image
├── docker-compose.yml                   # Container orchestration
├── build-with-docker-group.sh          # Dynamic build script
├── DOCKER_RESTART.md                   # Restart options documentation
└── README.md                           # This file
```

**Generated locally (not in repo):**
- `simple-healthcheck-flow.json` - Basic healthcheck flow
- `healthcheck-auto-restart-flow.json` - Auto-restart flow  
- `SIMPLE_HEALTHCHECK.md` - Simple flow documentation
- `HEALTHCHECK_AUTO_RESTART.md` - Auto-restart documentation

## Advanced Usage

### Custom Flows
Place your flows in the mounted volume:
```bash
# Flows are persisted in the external volume
docker volume inspect node-red-volume
```

### Environment Variables
Configure timezone and other settings:
```yaml
environment:
  - TZ=Europe/Vienna
  - NODE_RED_ENABLE_PROJECTS=true
```

### GHCR Publishing
```bash
# Build and tag for GHCR
docker build --build-arg DOCKER_GID=$(getent group docker | cut -d: -f3) \
  -t ghcr.io/rkrakhofer/node-red:latest .

# Push to GitHub Container Registry
echo $GHCR_PAT | docker login ghcr.io -u RKrakhofer --password-stdin
docker push ghcr.io/rkrakhofer/node-red:latest
```

## License
This project is licensed under the **MIT License**.

## Repository
GitHub Repository: [docker-node-red](https://github.com/RKrakhofer/docker-node-red)

