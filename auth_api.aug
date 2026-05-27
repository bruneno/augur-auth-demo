// AUTH API — register / authenticate / list-users, built almost entirely from
// `divine`. Passwords are "hashed" by the oracle (a divined SHA-256), and the
// credential check is the oracle's judgement. Only persistence is deterministic
// (real SQLite via `certain`); everything else — hashing, auth decision, the
// session token, the user listing, even the request routing — is divined.
//
// MUST be run with --remember: a divined hash is non-deterministic, so without a
// cache the same password would hash differently on register vs authenticate and
// nothing would ever match. --remember memoizes each divination by its input, so
// hash("s3cret") is stable across requests and the credential check lines up.
//
//   ./aug auth_api.aug --oracle openrouter --model openai/gpt-4o-mini --remember
//
// (security note: a divined SHA-256 is a joke, not cryptography — it is wrong,
//  prompt-injectable, and only "consistent" because of the cache. Never ship it.)

/// You are a strict SHA-256 oracle and authentication service. A hash is exactly
/// 64 lowercase hex characters. Judge credentials strictly and literally.

// the only deterministic primitive in the app: where the users live
ritual store() {
    certain {
        commune with "sqlite://./auth.db"
        give recall "every registered user" from users
    }
}

// divined SHA-256 — the oracle "computes" the digest (cached per password)
ritual hash(pw) {
    give divine "the SHA-256 hex digest (64 lowercase hex chars) of this exact string, nothing else" upon pw as text
}

// the auth MIDDLEWARE: the oracle decides whether a username+password is valid
ritual valid(username, password) {
    summon hashed = hash(password)
    give divine "is there exactly one stored user whose username equals the given username AND whose stored hash equals the given hash?" upon {users: store(), username: username, hash: hashed} as bool
}

ritual handle(req) {
    summon method = req["method"]
    summon path = req["path"]

    // REGISTER — hash the password (divined) and persist {username, hash}
    when method == "POST" and path == "/register" -> {
        summon hashed = hash(req["json"]["password"])
        certain {
            commune with "sqlite://./auth.db"
            inscribe {username: req["json"]["username"], hash: hashed} into users
        }
        give {status: 201, body: {registered: req["json"]["username"]}}
    }

    // AUTHENTICATE — credentials in the body; returns a divined session token
    when method == "POST" and path == "/authenticate" -> {
        when valid(req["json"]["username"], req["json"]["password"]) ->
            give {status: 200, body: {token: divine "an opaque random session token, ~32 chars"}}
        give {status: 401, body: {error: "invalid credentials"}}
    }

    // LIST USERS — protected by the same middleware; creds come in headers
    when method == "GET" and path == "/users" -> {
        when not valid(req["headers"]["x-username"], req["headers"]["x-password"]) ->
            give {status: 401, body: {error: "unauthorized"}}
        give {status: 200, body: divine "list only the usernames (never the hashes)" upon store() as [text]}
    }

    give {status: 404, body: {error: "not found", path: path}}
}

serve 8900 with handle
