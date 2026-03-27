FROM alpine:3.22.3 AS downloader

RUN apk add --no-cache curl jq unzip && \
    curl -L \
        "https://github.com/LeMuffinMan/ChessGame/releases/dwonload/1.0.1/chessgame-wasm.zip" \
        -o chessgame-wasm.zip && \
    unzip chessgame-wasm.zip

FROM alpine:3.22.3

COPY --from=downloader /dist /www/html


# Building version (10 min)

# FROM alpine:3.22

# RUN apk add --no-cache \
#     build-base \
#     musl-dev \
#     git \
#     curl \
#     bash \
#     libgcc \
#     libstdc++

# WORKDIR /app

# RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly

# ENV PATH="/root/.cargo/bin:${PATH}"

# RUN git clone https://github.com/LeMuffinMan/ChessGame

# WORKDIR /app/ChessGame

# RUN cargo fetch

# RUN rustup target add wasm32-unknown-unknown
# RUN cargo install -f wasm-bindgen-cli --version 0.2.101
# RUN cargo build --release --target wasm32-unknown-unknown
# RUN wasm-bindgen target/wasm32-unknown-unknown/release/chess_game.wasm \
#         --out-dir /app/dist \
#         --target web

# CMD ["ls", "-la", "/app/dist"]
