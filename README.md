# Dockerized Node-RED with Canvas Support

This repository provides a **Dockerfile** for running Node-RED with additional **Canvas support**. It is built on top of the official Node-RED Docker image and includes necessary dependencies to enable graphics rendering using the **canvas** package.

## Features
- Based on official **Node-RED**:latest
- Includes necessary **system libraries** for rendering (e.g., Cairo, Pango, Fontconfig, Pixman)
- Installs **canvas** for graphical operations in Node-RED
- Runs as the **node-red** user for security

## Usage

### Cloning the Repository
Clone this repository to your local machine:
```sh
git clone https://github.com/RKrakhofer/docker-node-red.git
cd docker-node-red
```

### Building the Image
To build the Docker image locally, run:
```sh
docker build -t ghcr.io/rkrakhofer/node-red:latest .
```

### Running the Container
To start a Node-RED container using this image:
```sh
docker run -d \
  --name node-red \
  -p 1880:1880 \
  ghcr.io/rkrakhofer/node-red:latest
```

### Pushing to GitHub Container Registry (GHCR)
If you want to push this image to GHCR.io:
```sh
# Authenticate with GitHub Container Registry
echo $GHCR_PAT | docker login ghcr.io -u RKrakhofer --password-stdin

# Push the image
docker push ghcr.io/RKrakhofer/node-red:latest
```
Make sure `$GHCR_PAT` is set to your **GitHub Personal Access Token** with `write:packages` permission.

## Installed System Dependencies
The following system libraries are installed for **Canvas** support:
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

## Exposed Ports
- **1880**: Default Node-RED web interface

## Customization
You can extend this Docker image by adding custom flows or additional Node-RED modules using a `package.json` file and mounting a persistent volume:
```sh
docker run -d \
  -v $(pwd)/node-red-data:/data \
  -p 1880:1880 \
  ghcr.io/RKrakhofer/node-red:latest
```

## License
This project is licensed under the **MIT License**.

## Repository
GitHub Repository: [docker-node-red](https://github.com/RKrakhofer/docker-node-red)

