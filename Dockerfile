####################################################################################################
## Builder
####################################################################################################
FROM clux/muslrust:nightly-2021-10-23 AS builder

# Build only for Postgresql backend
ARG DB=postgresql

# Build time options to avoid dpkg warnings and help with reproducible builds.
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    TERM=xterm-256color \
    CARGO_HOME="/root/.cargo" \
    USER="root"

ENV RUSTFLAGS='-C link-arg=-s'

RUN mkdir -pv "${CARGO_HOME}" \
    && rustup set profile minimal

# Get Vaultwarden project files
RUN git clone https://github.com/dani-garcia/vaultwarden.git /tmp/vaultwarden

# Creates a dummy project used to grab dependencies
RUN USER=root cargo new --bin /vaultwarden
WORKDIR /vaultwarden

# Copy over manifests and build files
RUN cp -r /tmp/vaultwarden/Cargo.toml ./ \
    && cp -r /tmp/vaultwarden/Cargo.lock ./ \
    && cp -r /tmp/vaultwarden/rust-toolchain ./rust-toolchain \
    && cp -r /tmp/vaultwarden/build.rs ./build.rs

RUN rustup target add x86_64-unknown-linux-musl

# Builds dependencies and removes dummy project, except for target folder
RUN cargo build --features ${DB} --release --target=x86_64-unknown-linux-musl \
    && find . -not -path "./target*" -delete

# Copy over the complete vaultwarden source
RUN cp -r /tmp/vaultwarden/. ./

# Make sure that we actually build vaultwarden
RUN touch src/main.rs

# Builds vaultwarden
RUN cargo build --features ${DB} --release --target=x86_64-unknown-linux-musl

####################################################################################################
## Final image
####################################################################################################
FROM alpine:3.14

ENV ROCKET_ENV="production" \
    ROCKET_PORT=80 \
    ROCKET_WORKERS=10

ENV SSL_CERT_DIR=/etc/ssl/certs

ENV WEB_VAULT_ENABLED=false \
    ATTACHMENTS_FOLDER=/vw-attachments \
    SENDS_FOLDER=/vw-sends \
    ICON_CACHE_FOLDER=/vw-icon-cache

RUN apk add --no-cache \
    openssl \
    tzdata \
    tini \
    postgresql-libs \
    ca-certificates

# Add persistant data directories
RUN mkdir -p /data \
    && mkdir -p /vw-attachments \
    && mkdir -p /vw-sends \
    && mkdir -p /vw-icon-cache

WORKDIR /vaultwarden

COPY --from=builder /tmp/vaultwarden/Rocket.toml .
COPY --from=builder /vaultwarden/target/x86_64-unknown-linux-musl/release/vaultwarden .
COPY ./start.sh .

# Add an unprivileged user and set directory permissions
RUN adduser --disabled-password --gecos "" --no-create-home vaultwarden \
    && chown -R vaultwarden:vaultwarden /data \
    && chown -R vaultwarden:vaultwarden /vw-attachments \
    && chown -R vaultwarden:vaultwarden /vw-icon-cache \
    && chown -R vaultwarden:vaultwarden /vaultwarden

USER vaultwarden

VOLUME /data
VOLUME /vw-attachments
VOLUME /vw-sends
VOLUME /vw-icon-cache

EXPOSE 80
EXPOSE 3012

ENTRYPOINT ["/sbin/tini", "--", "./start.sh"]

STOPSIGNAL SIGTERM

HEALTHCHECK \
    --start-period=15s \ 
    --interval=1m \ 
    --timeout=5s \ 
    CMD wget --spider --q http://localhost:80/alive || exit 1