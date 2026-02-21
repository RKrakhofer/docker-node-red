# Use the official Node-RED base image
FROM nodered/node-red:4.1.5

# Build argument for Docker group GID
ARG DOCKER_GID=999

USER root

# Install required libraries for canvas
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
    font-noto

USER node-red

# Set working directory
WORKDIR /usr/src/node-red

# Install canvas in the Node-RED directory
RUN npm install canvas

# Start Node-RED as node-red user (not root)
CMD ["node", "node-red"]
