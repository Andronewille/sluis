# Changelog

Both packages are released together under one version. Until 1.0 a minor version may change
behaviour: a new rule masks text an older version left alone, and the changelog says so.

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
