#!/usr/bin/env sh
set -e

SERVER_FOLDER="$(pwd)/waiter-server"

#Compile with musl for linux
sudo podman run --rm -it -e SQLX_OFFLINE=true -v "$SERVER_FOLDER":/home/rust/src ekidd/rust-musl-builder cargo build --release

#Start creating image from alpine linux
CONTAINER="$(buildah from alpine)"

buildah copy --add-history "$CONTAINER" "$SERVER_FOLDER/target/x86_64-unknown-linux-musl/release/Waiter" /Waiter
buildah copy --add-history "$CONTAINER" "$SERVER_FOLDER/migrations" /migrations

#Install sqlx-cli
buildah run --add-history "$CONTAINER" apk update
buildah run --add-history "$CONTAINER" apk upgrade

#Set entrypoint
buildah config --add-history=true --entrypoint "/Waiter" "$CONTAINER"

buildah commit "$CONTAINER" "waiter:$(cat $SERVER_FOLDER/Cargo.toml | grep version | head -n 1 | cut -d'"' -f2)"
buildah commit "$CONTAINER" "waiter:latest"
buildah rm "$CONTAINER"

