# Sluis — the design

What each rule finds, why the tokens look the way they do, where it is weak, and what is
deliberately not built yet. The [README](../README.md) is the short version.

Sluis takes the people out of Dutch text before it reaches an AI system, and puts them back afterwards.

A *sluis* is a lock. A ship goes in at one level and comes out at another, and the same lock works
in reverse: what went up comes down again, unchanged. Sluis does that with a mail. On the way in it
takes out the names, the address, the town, the telephone number, the iban — everything that is a
person — and leaves a token where each one stood. On the way out it puts them back, into whatever
the model wrote around them.

It is fully offline. Nothing in the core opens a socket and the core has no dependency that could;
the optional model runs on this machine from weights already on disk. Text goes through Sluis
precisely because it should not go anywhere else, and `tests/ArchitectureTest.php` checks that
mechanically rather than trusting it.

```
Hey Karel, mijn boot kost 250 euro, te bezichtigen aan de Maanstraat 123 in Haasterdam.
ik ben te bereiken op 0612345678. Mvg, Bob

                                    ↓  sluis

Hey voornaam1mask, mijn boot kost 250 euro, te bezichtigen aan de adres1mask in stad1mask.
ik ben te bereiken op telefoon1mask. Mvg, voornaam2mask

                                    ↓  the model rewrites it, and never saw a person

Beste voornaam1mask, de boot op adres1mask in stad1mask is te bezichtigen. Bel telefoon1mask.

                                    ↓  sluis --reverse

Beste Karel, de boot op Maanstraat 123 in Haasterdam is te bezichtigen. Bel 0612345678.
```

The amount is untouched on purpose. Money is not personal data, and a masked amount makes the
reply nonsense.

## Using it

```sh
composer require andronewille/sluis
```

PHP 8.5 or newer with mbstring and sodium, and no other package comes with it. As a library:

```php
use Sluis\Sluis;

$sluis = Sluis::nederlands();

$masked = $sluis->mask($mail);          // $masked->text has no people in it
$answer = $model->rewrite($masked->text);
$back = $sluis->unmask($answer, $masked->vault);

$back->text;        // the answer, with the people put back
$back->stray;       // masks the vault could not place — never ignore these
$masked->found;     // ['voornaam' => 2, 'adres' => 1, …], safe to log
```

As a pipe, where `sluis` is `vendor/bin/sluis`:

```sh
sluis < mail.txt > masked.txt          # the vault lands in sluis-vault.json, mode 0600
cat masked.txt | your-ai | sluis --reverse
sluis --json --raw="$body"             # {"text":…,"found":…,"vault":…} and nothing on disk
sluis --help
```

A vault that is already at `--vault` is read and extended rather than replaced, so a run of mail
through the same vault keeps one person on one token. That also means the file grows: it is a pile
of personal data in a working directory, and `SLUIS_VAULT_KEY` is the answer whenever it rests for
longer than the command that made it.

`--json` is the shape an API wants: the vault comes back in the answer and Sluis keeps nothing.
`SLUIS_VAULT_KEY` in the environment seals the vault file with that passphrase; the key is taken
from the environment and not from an argument, because an argument is in every `ps` on the machine.

Exit codes: `0` done, `1` went wrong, `2` asked wrongly, `3` no vault, `4` a mask reached the output.

## What Sluis promises

Every one of these is a test in `packages/core/tests/ArchitectureTest.php`, because a rule kept by
discipline alone drifts the first evening someone is tired.

- **It is offline.** Nothing opens a connection, and the core's only requirements are PHP and two
  extensions. The model adapter reads weights from a directory and refuses to run if they are not
  there, rather than fetching them mid-mail.
- **The vault is the only thing that holds a person.** `Vault::value()` is the one way back to what
  was taken out, and only the reverse path may call it. Every other feature that wants it — a
  report, a progress line, a log message — is the leak that test refuses.
- **The reverse path only substitutes.** It cannot recognise, cannot call a model, cannot decide.
  That is what makes it safe to run over whatever the AI sent back.
- **Nothing is written anywhere but the caller's output.** No `error_log`, no `var_dump`, and no
  exception message carries the words it was about.
- **The domain imports nothing** and the application layer does not know its adapters, so the model
  is a choice and never a dependency.
- **Masked text holds nothing the vault took out.** Checked on every single run, not just in tests:
  `Anonymise` refuses to return text in which a value it masked is still readable, and refuses a
  recogniser whose span does not point at the words it says it does — which is the one way the model
  adapter can be wrong, since it works its offsets out itself.

## What it finds, and how

The split is deliberate. Anything with a format is read as its format, because a check digit is
certainty and a model is a guess; the model is for prose, which is the part no pattern reaches.

| What | How | Needs a model |
|---|---|---|
| `email`, `url` | pattern | no |
| `telefoon` | ten digits, with a separator allowed between any two of them, so every grouping people use is one rule: `0612345678`, `06-12345678`, `06 12 34 56 78`, `030 123 45 67`, `+31 (0)6 12345678`. The count is the check — a date is eight digits | no |
| `iban` | pattern in either case, then mod-97. A number that fails is a typo, not an account | no |
| `bsn` | nine digits, then the elfproef | no |
| `kvk` | eight digits behind the word that announces them | no |
| `postcode` | `1234 AB`, with or without the space | no |
| `adres` | the street says what it is in its own suffix: `Maanstraat`, `Waterlooplein`, `Oudegracht`, plus a house number with `12a` and `12 bis` | no |
| `voornaam`, `achternaam`, `naam` | the frame of a letter: the words after `Hey` (every one of them — a mail is addressed to everyone it names), the name under `Met vriendelijke groet,` across `\r\n` and a blank line, a surname after `heer` or `mevrouw` | no |
| `stad` | the cue in front of it (`in Haasterdam`), plus a word list | no |
| all of the above, in prose | a local model | yes |
| `organisatie` | a local model, or a list of your own | yes |

Two of those deserve their reasons written down.

**The frame of a letter is the best free name recogniser there is.** The word after `Hey` is a
person and the word under `Mvg,` is a person, whatever the word is, in a language nothing was
trained on, for nothing. In a mailbox that is where the names almost always are.

**A value found once is masked everywhere.** The rules are good at the places a name announces
itself and blind to the fourth mention halfway down, so one sighting is enough for all of them.
It costs the odd ordinary word that happens to be somebody's name — which is the direction to be
wrong in.

**Where two rules overlap, the loser keeps what it still covers alone.** `Maanstraat 1234 AB` is an
address claiming `Maanstraat 1234` and a postcode claiming `1234 AB`. The postcode outranks the
address, and dropping the address whole left the street name standing in the middle of masked text
with nothing to say so. A remainder is kept only when it still reads as something — two characters
and a letter — or a telephone number that lost its digits to a bsn comes back as a mask over `0`.

## The tokens

`voornaam1mask`: a Dutch label, a number, and `mask`.

The label is Dutch because the model reads it. `voornaam1mask` tells a Dutch model that a first
name stood there, and a model that knows what stood there writes a sentence that still fits around
it. It is one word with no punctuation because everything else gets mangled: markdown eats
brackets, tokenizers split underscores, and a model asked to rewrite a sentence reflows
`[VOORNAAM_1]` into something no substitution finds again. Restoring is case-insensitive, because a
model that starts a sentence with a token capitalises it.

One value is one token, however often it appears — otherwise the model reads two people where the
mail had one, and answers the wrong one. Two spellings of one value (`Karel`, `KAREL`) are one
person by default, which means the second one comes back in the first one's spelling. Pass
`--strict` (or `Sluis::nederlands(strict: true)`) when the text has to come back byte for byte, and
every spelling gets its own token instead.

A token is never minted onto a string the document already uses, so text that itself reads like a
masked document does not have its own words overwritten.

## The vault

The vault is the trust boundary. Everything else in Sluis works on text that no longer holds a
person; the vault is the one object that does. So:

- A vault file is written mode `0600`, and the permissions are set before the bytes go in.
- `SLUIS_VAULT_KEY` seals it: Argon2id over the passphrase with a per-file salt, then a secretbox.
  Without the key it is bytes. Use this whenever a vault rests longer than the one command that
  made it, or anywhere a backup sweeps it up.
- Over an API, the vault is not stored at all: it goes back in the answer and the caller holds it.
  A service that keeps vaults keeps a pile of pure personal data, and there is no version of that
  which is safer than handing it to the one party that already has the text.

## The model

Optional, local, and a second pair of eyes rather than a replacement:

```sh
composer require andronewille/sluis-onnx
```

Composer asks whether `codewithkyrian/platform-package-installer` may run: it is the plugin that
picks the ONNX Runtime build for this machine, and the model does not load without it.

```php
use Sluis\Onnx\{Onnx, Profile, Transformers};

$profile = Profile::ner();
$sluis = Sluis::nederlands()->plus(new Onnx(new Transformers($profile, '/models'), $profile));
```

| Profile | Weights (int8) | What it adds | Measured here |
|---|---|---|---|
| `Profile::ner()` | 178 MB | person, place, organisation, Dutch among ten languages | ~350 MB in memory, 0.1 s to load, 10–40 ms a mail; next to a core that already reads every format, this is most of what is left |

It was run on this machine, offline, on Dutch mail (PHP 8.5, linux/arm64, TransformersPHP 0.6.2,
the container started with `--network none`). What that showed:

- **`ner` closes most of what the core leaves open.** `Haasterdam is mooi, zegt Fatima El Amrani van
  Timmerbedrijf De Zaag.` comes through the core untouched and through the model as `stad1mask is
  mooi, zegt naam1mask van organisatie1mask.` It finds a town with no cue in front of it, a surname
  mid-sentence, a company name and the name in a quoting header. It reads no number, which is the
  core's half: together they mask what neither does alone.
- **It mislabels more than it misses.** A signature of a double-barrelled name above a company with
  the same word in it came back as `naam2mask organisatie1mask-naam3mask`. Nothing was left
  readable; the labels are a guess.
- **Piiranha was the second profile and was taken out.** It is trained on personal data itself,
  seventeen kinds of it, and its 317 MB int8 weights are not the model on the card: on sentences
  where the full-precision weights find the first name, the street and the town, the int8 weights
  find a house number. Run through ONNX Runtime directly, without PHP, they answer the same, so it
  is the quantisation and not this adapter. The full weights are 1.1 GB and ~1.9 GB in memory, and
  still read a Dutch telephone number as a username.
- **`ner` is BERT, not DistilBERT.** The 135 MB DistilBERT of the same name was the first choice and
  does not load: TransformersPHP 0.6 has no token classification for it.

It needs PHP's FFI extension, because TransformersPHP drives ONNX Runtime through it. That is why
it is a package of its own: `composer require andronewille/sluis` gets you a masker with no FFI, no
weights and no extension beyond mbstring and sodium, and the model is something you decide to add.

The weights are fetched once, deliberately, by `vendor/bin/transformers download <model>
token-classification --cache-dir=<models>`, on a machine that may. Sluis itself never fetches: a
run that finds no weights stops and says which command puts them there. It checks each of the four
files the runtime reads and not the directory, because the runtime has no offline switch — it
fetches whichever file is missing, and a download that stopped halfway looks like a model.

**The pipeline reports words, not positions.** TransformersPHP answers
`['entity_group' => 'PER', 'word' => 'Karel']` and no offsets, and a masker needs offsets. So the
adapter places every word itself, in reading order, loose about whitespace the tokenizer changed and
strict about everything else — and when it cannot find a word, it throws. Guessing would put a mask
over the wrong words; skipping would leave the name the model just found sitting in the text.

**A piece of a word takes the whole word.** A SentencePiece tokenizer such as Piiranha's reports a
word in pieces, and the first long mail put the `Ge` of `Geertruidenberg` over the end of `Vorige`: a token glued to the
letters left over, which the reverse path does not recognise as a token. A piece is now placed at
the start of a word before anywhere else, and widened to the words it touches.

A label this version has no mapping for becomes `onbekend1mask` rather than being dropped. The
model said it was personal data; not having a name for it is our problem, not the reader's.

## Where it is weak

Written down rather than discovered later.

- **A town is the shallowest rule here.** `in Haasterdam` works, `Haasterdam is mooi` does not. The
  word lists in `data/` are seeds — a few dozen names and towns — and real coverage means either
  the model or feeding `Gazetteer::fromFile()` the open BAG or CBS lists yourself. Sluis reads a
  file; it never fetches one.
- **Masking more than needed is the failure mode.** A first name that is also an ordinary word gets
  masked wherever it appears once it has been recognised anywhere. The text suffers; nothing leaks.
- **`aan de adres1mask`.** The article stays, unlike in the first sketch of this tool: leaving `de`
  gives the model Dutch it can build on, where swallowing it leaves a sentence to repair.
- **A company name is prose.** Without a model or a list of your own, `organisatie` finds nothing.
  A signature's second line is usually the company, and it stays. `Profile::ner()` finds it.
- **A listed first name can leave its own surname standing.** `Bel Sanne de Vries op 06-12345678.`
  masks to `Bel voornaam1mask de Vries op telefoon1mask.`: `Sanne` is in `data/voornamen.txt`, while
  the surname rules want the frame of a letter — after `Hey`, under `Mvg,`, behind `heer` or
  `mevrouw` — and mid-sentence is none of those. So even where a person is already established, half
  of them stays: that half is the model's — `Profile::ner()` masks the whole name here — or a
  surname list of your own via `Gazetteer::fromFile()`.
- **A name in a quoting header stays.** `Op 1 oktober schreef Sietske <s@voorbeeld.nl>:` masks the
  address and not the name: it is a frame, and not one the core reads yet. The model does.
- **A mask that starts inside a word does not come back.** The core's rules match whole words
  and the ONNX adapter widens to them, so nothing here produces one — but nothing in
  `Anonymise` refuses one either, and a recogniser of your own that points at half a word gets a
  token the reverse path reports as unrestored.
- **Hand-written formats drift.** A `kenteken` is not read at all yet, and the Dutch sidecodes are
  the kind of pattern that wants a test per sidecode before it is trusted.

## What belongs where

| What | Whose it is |
|---|---|
| Finding the people in the text, masking them, putting them back | Sluis |
| Holding the vault | the caller. Over an API it is returned, never stored |
| Deciding what is sensitive enough to mask | the caller, by choosing recognisers |
| Calling the AI in the middle | the caller. Sluis never calls a model that is not on this machine |
| Keeping a record of what was masked | the caller. Sluis remembers nothing between runs |

## Layout

```
packages/core/            andronewille/sluis — no dependency, no model, no network
  src/Domain/             PiiType, Span, Spans, Vault, and what the two halves answer
  src/Application/        Anonymise, Deanonymise, and the two ports they know
  src/Infrastructure/     the recognisers, the vault stores, the command
  data/                   seed word lists: first names, towns
  bin/sluis               the pipe
packages/onnx/            andronewille/sluis-onnx — the model, opt-in, still offline
  src/Onnx.php            words the model reports → spans Sluis can point at
  src/Profile.php         which model, what its labels mean, how much it may see at once
  src/Transformers.php    the one class that loads a model, and refuses to fetch one
docker/                   the toolchain image, and the one with FFI
```

## What is not built yet

Everything above this line is what Sluis does today.

**A Laravel bridge.** `andronewille/sluis-laravel`: a service provider, a config file and an
artisan command. Nothing in the core needs it; it is convenience for an application that wants
`Sluis` from the container.

**A test that runs the real model.** The model has been run here, by hand, and what that
showed is under [The model](#the-model). The suite still tests the adapter against recorded
answers only: nothing re-runs the weights when TransformersPHP or a profile changes, and a handful
of mails is a first look, not a measurement of recall.

**A kenteken, a company name, a date of birth, a quoting header.** Each wants its own rule and its
own tests.
