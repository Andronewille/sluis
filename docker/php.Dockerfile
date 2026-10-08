# The toolchain image: PHP and Composer, and nothing else. The core carries no
# dependency and needs no extension beyond mbstring and sodium, so this image
# cannot run the ONNX adapter on purpose — that one needs FFI, and asking for FFI
# should be a decision someone makes, not something the test image quietly
# already had.
#
# PHP is named here rather than inherited from `composer:latest`, which follows
# whatever PHP is newest: the version the suite runs on is the floor in
# composer.json, and it moves when someone moves it.
FROM php:8.5-cli-alpine

RUN apk add --no-cache git unzip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
