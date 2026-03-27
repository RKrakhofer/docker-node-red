# Use the official Node-RED base image
FROM nodered/node-red:4.1.8

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

# Install canvas — GCC 15 (Alpine 3.21+) rejects std::min(uint32_t, int)
# type mismatch in Canvas.cc:646. Fix: cast PAGE_SIZE to uint32_t.
RUN npm install --ignore-scripts canvas && \
    sed -i 's/PAGE_SIZE/(uint32_t)PAGE_SIZE/g' node_modules/canvas/src/Canvas.cc && \
    cd node_modules/canvas && npx --yes node-gyp rebuild

USER node-red

# Start Node-RED as node-red user (not root)
CMD ["node", "node-red"]
