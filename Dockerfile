FROM ubuntu:25.10 AS base

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    libglib2.0-0t64 \
    libgnome-autoar-0-0 \
    libjson-glib-1.0-0 \
    libsoup-3.0-0 \
    && rm -rf /var/lib/apt/lists/*


FROM base AS builder

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    meson \
    ninja-build \
    gcc \
    pkg-config \
    git \
    gettext \
    libglib2.0-dev \
    libgnome-autoar-0-dev \
    libjson-glib-dev \
    libsoup-3.0-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://gitlab.gnome.org/GNOME/gnome-shell.git /tmp/gnome-shell

WORKDIR /tmp/gnome-shell/subprojects/extensions-tool

RUN ./generate-translations.sh

RUN meson setup --prefix=/usr --buildtype=release -Dman=false builddir && \
    meson compile -C builddir && \
    meson install -C builddir


FROM base

COPY --from=builder /usr/bin/gnome-extensions /usr/bin/gnome-extensions
COPY --chown=root:root entrypoint.sh /entrypoint.sh

# Support for test mode: trust self-signed certificate if present
COPY cert.pe[m] /usr/local/share/ca-certificates/wiremock.crt* 2>/dev/null || :
RUN if [ -f /usr/local/share/ca-certificates/wiremock.crt ]; then \
        update-ca-certificates; \
    fi

WORKDIR /github/workspace

ENTRYPOINT ["/entrypoint.sh"]
