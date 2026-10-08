# Contributing

Read [docs/design.md](docs/design.md) before changing what Sluis masks: it says what every rule is
for and where it is weak on purpose. A leak is not an issue but a [security report](SECURITY.md).

## Running it

There is no PHP on the host. Everything runs in the project's own image:

```sh
docker build -t sluis/php -f docker/php.Dockerfile .
alias art='docker run --rm -u $(id -u):$(id -g) -e HOME=/tmp -v "$PWD":/w -w /w sluis/php php'

art /usr/bin/composer install
art vendor/bin/phpunit
art vendor/bin/pint --test
art vendor/bin/phpstan
art packages/core/bin/sluis --raw="Hey Karel, bel 0612345678. Mvg, Bob" --json
```

The ONNX adapter needs FFI, which this image deliberately does not have —
`docker/php-ffi.Dockerfile` is the one that does. A test that only passes there is a test in the
wrong package. Running the model itself:

```sh
docker build -t sluis/php-ffi -f docker/php-ffi.Dockerfile .
alias ffi='docker run --rm -u $(id -u):$(id -g) -e HOME=/tmp -v "$PWD":/w -w /w/packages/onnx'

ffi sluis/php-ffi composer install                  # TransformersPHP and ONNX Runtime, into packages/onnx/vendor
ffi sluis/php-ffi php vendor/bin/transformers download \
    Xenova/bert-base-multilingual-cased-ner-hrl token-classification --cache-dir=/w/models
ffi --network none sluis/php-ffi php your-script.php # and from here on it needs no network
```

## Before a pull request

- `art vendor/bin/phpunit`, `art vendor/bin/pint --test` and `art vendor/bin/phpstan` pass. Pint
  formats; nobody hand-styles.
- `bin/check-pointers` passes: it re-reads every `path:line` in the docs.
- A new rule comes with its tests, and a test that describes a promise says why in its docblock.
- No real person in an example or a fixture. A made-up name and number do the same work.
- Commits read `area: what changed and why` — lower case, no period, one line.
