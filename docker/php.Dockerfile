# The toolchain image: PHP and Composer, and nothing else. The core carries no
# dependency and needs no extension beyond mbstring, so this image cannot run
# the ONNX adapter on purpose — that one needs FFI, and asking for FFI should be
# a decision someone makes, not something the test image quietly already had.
FROM composer:latest
