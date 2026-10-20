FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg python3 tar \
        libasound2t64 libatk1.0-0t64 libatk-bridge2.0-0t64 libatspi2.0-0t64 \
        libcairo2 libdbus-1-3 libdbus-glib-1-2 libdrm2 libgbm1 \
        libgdk-pixbuf-2.0-0 libglib2.0-0t64 libgtk-3-0t64 \
        libpango-1.0-0 libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1 \
        libxext6 libxfixes3 libxi6 libxkbcommon0 libxkbcommon-x11-0 \
        libxrandr2 libxrender1 libxss1 libxt6 libxtst6 \
    && rm -rf /var/lib/apt/lists/*