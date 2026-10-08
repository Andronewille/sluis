# The image with FFI, for the ONNX adapter alone: TransformersPHP drives ONNX
# Runtime through FFI. Nothing in the core is tested with this, so a test that
# only passes here is a test in the wrong package.
#
# Not the toolchain image with a switch flipped: that one is Alpine, which ships
# PHP without FFI, and ONNX Runtime's prebuilt libraries are linked against glibc
# and do not load on musl. So this one is Debian, builds the
# extension, and borrows Composer.
FROM php:8.5-cli

RUN apt-get update \
    && apt-get install -y --no-install-recommends libffi-dev libgomp1 git unzip \
    && docker-php-ext-install ffi \
    && printf 'ffi.enable=true\nmemory_limit=-1\n' > /usr/local/etc/php/conf.d/ffi.ini \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
