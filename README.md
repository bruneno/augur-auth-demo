# augur-auth-demo

A user/password auth API (register · authenticate · list-users) written almost
entirely in [Augur](https://github.com/bruneno/augur) `divine` — the LLM is the
hash function, the credential checker, the token generator, and the router.
Only **persistence** is deterministic (real SQLite via `certain`).

This is a joke about LLM-driven software. Do not deploy it.

## What is divined vs deterministic

| Piece | How |
|---|---|
| SHA-256 password hash | **divined** — `divine "the SHA-256 hex digest …" upon pw` (hallucinated, kept stable by `--remember`) |
| Credential check (the middleware) | **divined** — `divine "is there a stored user whose username and hash match?" … as bool` |
| Session token | **divined** — `divine "an opaque random session token"` |
| Username listing | **divined** — `divine "list only the usernames" upon store()` |
| Request routing (`==`) | **divined** (everything outside `certain`) |
| Storing / loading users | **deterministic** — real SQLite (`certain { commune … }`) |

## Run

Needs the Augur `aug` binary and an oracle key. Build the binary from the
[augur repo](https://github.com/bruneno/augur) and drop it next to this file:

```sh
# in the augur repo
bun build src/index.ts --compile --outfile aug
cp aug /path/to/augur-auth-demo/
```

…or skip the binary and run through the source: replace `./aug` below with
`bun run /path/to/augur/src/index.ts`.

**`--remember` is required** — a divined hash is non-deterministic, so the cache
is what makes `hash("s3cret")` line up between register and authenticate.

```sh
OPENROUTER_API_KEY=sk-... ./aug main.aug \
  --oracle openrouter --model openai/gpt-4o-mini --remember
```

## Layout

The program is split across files with Augur's `include`:

```
main.aug          # /// system note, includes the libs, starts the server
routes.aug        # ritual handle(req) — register / authenticate / users
lib/hash.aug      # ritual hash(pw)        — divined SHA-256
lib/store.aug     # ritual store()         — the deterministic SQLite layer
lib/auth.aug      # ritual valid(u, p)     — the divined auth middleware
```

## Endpoints

```sh
# register
curl -s -X POST localhost:8900/register     -d '{"username":"alice","password":"s3cret"}'
# authenticate -> divined session token
curl -s -X POST localhost:8900/authenticate -d '{"username":"alice","password":"s3cret"}'
# list users (protected — creds in headers, checked by the divined middleware)
curl -s -H 'x-username: alice' -H 'x-password: s3cret' localhost:8900/users
# without creds -> 401
curl -s localhost:8900/users
```

## Why this is not security

The "SHA-256" is invented by the model — it is not a real digest, it is only
*consistent* because identical inputs hit the `--remember` cache. The auth
decision is the model's opinion and is prompt-injectable. For anything real,
move the hash and the comparison into `certain { … }` with actual crypto.
