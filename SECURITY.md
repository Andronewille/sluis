# Security

Sluis exists to keep personal data out of places it should not reach, so these are security
problems and not ordinary bugs:

- a value that is still readable in masked text and that the README does not already list under
  "Where it is weak";
- a value that reaches an exception message, a log line or anything else that is not the caller's
  output;
- anything that makes Sluis open a network connection;
- a sealed vault that can be read without its key.

Report them privately through "Report a vulnerability" on the repository's Security tab, not in a
public issue. Rewrite the example so it holds no real person: a made-up name and number that
trigger the same behaviour are all a report needs.

A name or a town the rules simply do not recognise is a known limit rather than a vulnerability,
and a normal issue is the right place for it.
