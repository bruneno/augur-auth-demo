// HTTP routes. Uses store()/hash()/valid() from the included libs; rituals are
// resolved at call time, so include order does not matter as long as everything
// is loaded before the first request.
ritual handle(req) {
    summon method = req["method"]
    summon path = req["path"]

    // REGISTER — hash the password (divined) and persist {username, hash}
    when method == "POST" and path == "/register" -> {
        summon hashed = hash(req["json"]["password"])
        certain {
            commune with "mysql://augur:augur@127.0.0.1:3308/augur"
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

    // LIST USERS — protected by the divined middleware; creds in headers
    when method == "GET" and path == "/users" -> {
        when not valid(req["headers"]["x-username"], req["headers"]["x-password"]) ->
            give {status: 401, body: {error: "unauthorized"}}
        give {status: 200, body: divine "list only the usernames (never the hashes)" upon store() as [text]}
    }

    give {status: 404, body: {error: "not found", path: path}}
}
