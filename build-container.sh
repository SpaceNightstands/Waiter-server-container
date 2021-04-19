#!/usr/bin/env sh

SERVER_FOLDER="$(pwd)/waiter-server"

#Compile with musl for linux
sudo podman run --rm -it -v "$SERVER_FOLDER":/home/rust/src ekidd/rust-musl-builder cargo build --release

#Start creating image from alpine linux
CONTAINER="$(buildah from alpine)"

buildah copy --add-history "$CONTAINER" "$SERVER_FOLDER/target/x86_64-unknown-linux-musl/release/Waiter" /Waiter
buildah copy --add-history "$CONTAINER" "$SERVER_FOLDER/migrations" /migrations

#Install sqlx-cli
buildah run --add-history "$CONTAINER" apk update
buildah run --add-history "$CONTAINER" apk upgrade
buildah run --add-history "$CONTAINER" apk add cargo openssl-dev
buildah run --add-history "$CONTAINER" cargo install sqlx-cli --no-default-features --features mysql

#Set entrypoint
buildah config --add-history=true --entrypoint "/root/.cargo/bin/sqlx migrate run && /Waiter" "$CONTAINER"

buildah commit "$CONTAINER" "waiter:0.1.1"
buildah rm "$CONTAINER"

