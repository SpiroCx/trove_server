# ============================
# 1. Build stage
# ============================
FROM rust:1.79-slim AS builder

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install diesel CLI compatible with rustc 1.79
RUN cargo install diesel_cli --version 2.2.2 --no-default-features --features postgres --locked

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo fetch

COPY . .

RUN cargo build --release


# ============================
# 2. Runtime stage
# ============================
FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/target/release/trove_server /usr/local/bin/trove_server
COPY --from=builder /app/migrations ./migrations

# Copy diesel CLI from builder stage
COPY --from=builder /usr/local/cargo/bin/diesel /usr/local/bin/diesel

EXPOSE 8080

CMD diesel migration run && exec trove_server

