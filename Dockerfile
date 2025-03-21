# Use the official Node-RED base image
FROM nodered/node-red:latest

USER root
# Install required libraries
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

RUN npm install canvas


# Start Node-RED
CMD ["node", "node-red"]
