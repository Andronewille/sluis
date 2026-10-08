# Sluis

Masks the people out of Dutch text before an AI system sees it, and puts them back afterwards.
Offline: nothing in the core opens a socket, and the optional model runs from weights already
on disk.

`docs/design.md` is the design document — what each rule finds, why the tokens look the way they do,
where it is weak, and what is deliberately not built yet. Read it before changing behaviour.
This file is the rest.

## The map

One Composer workspace, two published packages. `composer install` at the root maps both `src/`
trees so the whole suite runs at once; each package's own `composer.json` is what gets published.

- `packages/core` — `andronewille/sluis`. Requires PHP, mbstring and sodium, and nothing else ever.
  - `src/Domain/` — `PiiType`, `Span`, `Spans`, `Vault`, and what the two halves answer.
  - `src/Application/` — `Anonymise`, `Deanonymise`, and the two ports they know.
  - `src/Infrastructure/` — the recognisers, the vault stores, the command.
  - `src/Sluis.php` — the composition root, and the whole API most callers need.
  - `data/` — seed word lists; `bin/sluis` — the pipe.
- `packages/onnx` — `andronewille/sluis-onnx`. A local model as one more recogniser, opt-in because
  it needs FFI and 178 MB of weights.
- `docker/` — the toolchain image, and the one with FFI.

Each package carries its own `README.md`, `LICENSE` and `.gitattributes`, because each is split out
to a read-only mirror and that mirror is what Packagist and a `composer require` see. The root
`README.md` is a symlink to `packages/core/README.md`: one pitch, shown in both places, so every
link in it is either a full URL or a file both places have.

## Running anything

There is no PHP on the host. Everything runs in the project's own image:

```sh
docker build -t sluis/php -f docker/php.Dockerfile .          # once
alias art='docker run --rm -u $(id -u):$(id -g) -e HOME=/tmp -v "$PWD":/w -w /w sluis/php php'
art vendor/bin/phpunit
art vendor/bin/pint --test
```

Pass `-u` and `HOME=/tmp`, or the container leaves root-owned files in the checkout. That image has
no FFI on purpose: `docker/php-ffi.Dockerfile` is for the ONNX package alone, and a test that only
passes there is a test in the wrong package.

`bin/check-pointers` re-reads every `path:line` below and in `docs/design.md` and fails when one no longer
lands on the code it names. It needs neither PHP nor Docker; run it after moving code, and write
pointers from the repository root so it can find them.

## Releasing

Both packages share one version. Composer reads a `composer.json` at the root of a repository and
nowhere else, so the `split` job in `.github/workflows/tests.yml` pushes `packages/core` to
`Andronewille/sluis-core` and `packages/onnx` to `Andronewille/sluis-onnx` once the suite is green:
`main` on every push, and a tag when one is pushed here. Packagist follows the mirrors. Nothing is
ever committed to a mirror by hand.

1. Date the entry in `CHANGELOG.md`.
2. `git tag v0.2.0 && git push origin main v0.2.0`.
3. On a new minor, move the `branch-alias` in both packages and the `andronewille/sluis` constraint
   in `packages/onnx/composer.json` along with it.

## Invariants

These are the point of the tool rather than preferences, and each one is enforced. The test is
where to look before arguing with it.

- **Nothing reaches the network** — not a fetch, not a fallback, not a one-off weight download.
  `packages/core/tests/ArchitectureTest.php:24`, `packages/onnx/tests/ArchitectureTest.php:16`.
- **`Vault::value()` has one caller: the reverse path.** Anything else that wants a value — a log
  line, a progress message, a nicer error — is the leak this tool exists to prevent.
  `packages/core/src/Domain/Vault.php:100`, kept true at
  `packages/core/tests/ArchitectureTest.php:97` and `packages/core/tests/ArchitectureTest.php:119`.
- **No plaintext in an exception, a log or a dump.** A message names the type and the recogniser,
  never the words.
- **A recogniser that cannot place what it found throws.** Skipping leaves the value in the text and
  reports success: `packages/core/src/Application/Anonymise.php:62`, `packages/onnx/src/Onnx.php:115`.
- **Masked text is checked on every run, not only in tests** —
  `packages/core/src/Application/Anonymise.php:106`.
- **The reverse path only substitutes.** No recogniser, no model, no branching on content.
- **The domain imports nothing and the application does not know its adapters.** `Sluis.php` is the
  one allowed exception.
- **Money is not personal data.** No rule masks an amount.

## Conventions

- PHPUnit, not Pest. Pint with the default Laravel preset is the formatter; run it, don't hand-style.
- Code, comments and commit messages in English. The mask labels and the lists in `data/` are Dutch,
  because the model reads them.
- Commits read `area: what changed and why` — lower case, no period, one line.
- A test that describes a promise says why the promise exists in its docblock. The architecture test
  strips comments before reading, so an explanation never fails the rule it explains.
