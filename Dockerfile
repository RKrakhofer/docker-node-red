# Use the official Node-RED base image
FROM nodered/node-red:latest

USER root
# Install required libraries including docker cli and su-exec
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
    docker-cli \
    su-exec

USER node-red
# Set working directory
WORKDIR /usr/src/node-red

RUN npm install canvas

# Copy dynamic entrypoint
COPY --chown=root:root entrypoint.sh /usr/local/bin/entrypoint.sh
USER root
RUN chmod +x /usr/local/bin/entrypoint.sh

# Use dynamic entrypoint that configures Docker group at runtime
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["node-red"]
