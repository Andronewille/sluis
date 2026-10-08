# Changelog

Both packages are released together under one version. Until 1.0 a minor version may change
behaviour: a new rule masks text an older version left alone, and the changelog says so.

## Unreleased

- Both packages need PHP 8.5 or newer; 0.1.0 is the last version that runs on 8.3 and 8.4.
- Every file declares strict types, and PHPStan reads the whole workspace at its strictest level.
- The command says what the API says: `sluis mask` and `sluis unmask`. `--reverse` is gone and
  says where it went; a bare `sluis` still masks.
- `sluis unmask --json` reads `{"text":…,"vault":…}`, which is what `sluis --json` answers, and
  answers `{"text":…,"unrestored":…,"stray":…}`. No vault file is needed for the round trip, and
  none is used unless `--vault` names it.
- Strict grouping belongs to the vault alone. `Sluis::nederlands(strict: true)` is gone: pass
  `Vault::empty(strict: true)` to `mask()`. `--strict` against a vault that began without it exits
  `2` instead of being ignored, and so does `--strict` with `unmask`.
- `Sluis::only()` and `Sluis::without()` choose which kinds are masked, without assembling the
  recognisers by hand. A kind that is left out is as if there were no rule for it.
- Text that is not UTF-8 is refused, on the way in and on the way back. It used to come through
  unmasked with exit `0`, because a pattern that cannot read a text reports that it found nothing.
- A long thread is masked in a fraction of the time, and at all: 200 kB with the same few names in
  every mail ran out of memory in 0.1.0, and now takes about half a second.
- A recogniser reports every claim and no longer settles its own overlaps; `Anonymise` settles them
  once. A recogniser of your own may keep settling, and loses nothing but the choice above.
- A vault says that it is one: `version` 1 and `entries`, every entry filed under a mask. Other
  JSON at `--vault` is refused instead of read as empty and written over.
- A directory at `--vault` is refused before it is touched.
- `sluis --json` writes `found` and `entries` as objects also when they are empty.
- An argument the command does not know is not quoted back unless it is the name of an option.
- `mask()` and `unmask()` are `#[NoDiscard]`: throwing away what they return is a warning.
- `Sluis::with()` is gone, since it was the constructor under another name: `new Sluis($recogniser)`.
- `Span::$found` is `Span::$by`. It names the rule that found the span, and shared its name with
  the counts in `Masked::$found`.
- The command takes `--vault PATH` as well as `--vault=PATH`, answers `--version`, and builds no
  recogniser to unmask.
- `Gazetteer::fromFile()` throws when the list is not there or holds no words, where it used to
  read as empty and mask nothing, and reads past a byte order mark.
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
