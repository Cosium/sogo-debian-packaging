# SOGo Debian packaging

## Requirements
+ Docker: https://docs.docker.com/get-docker/

## Building SOGo deb packages
+ `cp .env.example .env` and adjust `.env` to your needs
+ Run `docker run --rm -it -v "$(pwd):/data" debian:bookworm /data/build.sh`
+ Find the packages inside the `vendor` directory

## Older Debian releases
See the respective branches for older Debian releases
