FROM alpine:3.18

ENV DEST=/var/www/html/chessgame
COPY fallback/chessgame-wasm.zip /tmp/chessgame-fallback.zip

RUN apk add --no-cache curl unzip jq bash \
    && mkdir -p "$DEST" \
    && RELEASE_JSON=$(curl -s https://api.github.com/repos/LeMuffinMan/ChessGame/releases/latest) \
    && URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name == "chessgame-wasm.zip") | .browser_download_url') \
    && (curl -L "$URL" -o /tmp/chessgame.zip || \
        (echo "Download failed, using fallback archive"; cp /tmp/chessgame-fallback.zip /tmp/chessgame.zip)) \
    && unzip -o /tmp/chessgame.zip -d /tmp/chessgame_extracted \
    && cp -r /tmp/chessgame_extracted/dist/. "$DEST/" \
    && sed -i \
         -e 's|href="/chess_game-|href="./chess_game-|g' \
         -e 's|from '"'"'/chess_game-|from '"'"'./chess_game-|g' \
         -e 's|module_or_path: '"'"'/chess_game-|module_or_path: '"'"'./chess_game-|g' \
         "$DEST/index.html" \
    && sed -i 's|<script type="module">[^<]*import init from "./pkg/chessgame.js"[^<]*</script>||' "$DEST/index.html" \
    && rm -rf /tmp/chessgame.zip /tmp/chessgame_extracted /tmp/chessgame-fallback.zip

CMD ["echo", "ChessGame deployed successfully"]

#  -------- Curl  release and copy version (limited curl calls) ------

# FROM alpine:3.22.3

# RUN apk add --no-cache curl jq unzip

# COPY entrypoint.sh /entrypoint.sh
# RUN chmod +x /entrypoint.sh

# ENTRYPOINT ["/entrypoint.sh"]


# using rust ofiicial image (10 min)

# FROM rust:1.94.1

# RUN rustup target add wasm32-unknown-unknown
# RUN cargo install --locked trunk

# # RUN rustup component add rustfmt clippy

# WORKDIR /app

# COPY ChessGame/Cargo.toml ChessGame/Cargo.lock ./
# COPY ChessGame/src ./src

# CMD ["trunk", "build", "--release", "--public-url", "/chessgame/"]


# -------- Building from scratch version (10 min) ---------

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
