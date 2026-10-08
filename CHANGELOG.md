# Changelog

Both packages are released together under one version. Until 1.0 a minor version may change
behaviour: a new rule masks text an older version left alone, and the changelog says so.

## Unreleased

- Both packages need PHP 8.5 or newer; 0.1.0 is the last version that runs on 8.3 and 8.4.
- Every file declares strict types, and PHPStan reads the whole workspace at its strictest level.
- The command says what the API says: `sluis mask` and `sluis unmask`. `--reverse` is gone and
  says where it went; a bare `sluis` still masks.
- `sluis unmask --json` reads `{"text":…,"vault":…}`, which is what `sluis --json` answers, and
  answers `{"text":…,"unrestored":…,"stray":…}`. No vault file is needed for the round trip.
- Strict grouping belongs to the vault alone. `Sluis::nederlands(strict: true)` is gone: pass
  `Vault::empty(strict: true)` to `mask()`. `--strict` against a vault that began without it exits
  `2` instead of being ignored, and so does `--strict` with `unmask`.
- `Sluis::only()` and `Sluis::without()` choose which kinds are masked, without assembling the
  recognisers by hand.
- `mask()` and `unmask()` are `#[NoDiscard]`: throwing away what they return is a warning.
- `Sluis::with()` is gone, since it was the constructor under another name: `new Sluis($recogniser)`.
- `Span::$found` is `Span::$by`. It names the rule that found the span, and shared its name with
  the counts in `Masked::$found`.
- The command takes `--vault PATH` as well as `--vault=PATH`, answers `--version`, and builds no
  recogniser to unmask.
- `Gazetteer::fromFile()` throws when the list is not there, where it used to read as empty and
  mask nothing.
- `--help` says that `--raw=TEXT` is readable by every user on the machine while the command runs,
  and the README pipes the text in instead.
- A vault file that does not hold what Sluis wrote is refused with a message of its own, instead of
  being read as far as it went.

## 0.1.0 — 2026-10-08

The first release.

### andronewille/sluis

- Masks Dutch text and puts it back: `Sluis::nederlands()`, `mask()`, `unmask()`.
- Reads by format: `email`, `url`, `telefoon`, `iban` (mod-97), `bsn` (elfproef), `kvk`, `postcode`
  and `adres`.
- Reads names from the frame of a letter — the greeting, the signature, `heer` and `mevrouw` — and
  towns from the cue in front of them and a word list.
- A value found once is masked everywhere, and one value is one token however often it appears.
- `--strict` keeps every spelling on its own token, so the text comes back byte for byte.
- The `sluis` command: a pipe, `--reverse`, `--json`, and a vault file written mode `0600`.
- `SLUIS_VAULT_KEY` seals the vault file: Argon2id, then a secretbox.
- Masked text is checked on every run, and a mask the vault cannot place is reported as stray.

### andronewille/sluis-onnx

- A local ONNX model as one more recogniser: `Profile::ner()`, for the names, towns and
  organisations in prose that no pattern reaches.
- Refuses to run when the weights are not on disk, and never fetches them.
