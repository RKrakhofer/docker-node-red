# Use the official Node-RED base image
FROM nodered/node-red:latest

# Build argument for Docker group GID
ARG DOCKER_GID=999

USER root
# Install required libraries including docker cli
RUN apk add --no-cache \
    build-base \
    cairo-dev \
    pango-dev \
    giflib-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    pixman-dev \
    pkgconf \
    fontconfig \
    ttf-dejavu \
    font-noto \
    curl \
    docker-cli

# Create docker group with dynamic GID from host and add node-red user to it
RUN addgroup -g ${DOCKER_GID} docker || addgroup docker
RUN adduser node-red docker

USER node-red
# Set working directory
WORKDIR /usr/src/node-red

RUN npm install canvas

# Start Node-RED as node-red user (not root)
CMD ["node", "node-red"]
