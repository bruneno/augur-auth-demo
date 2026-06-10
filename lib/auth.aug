// The auth middleware: the oracle decides whether a credential is valid.
// Reused by /authenticate and by the protected /users route.
ritual valid(username, password) {
    summon hashed = hash(password)
    give divine "is there exactly one stored user whose username equals the given username AND whose stored hash equals the given hash?" upon {users: store(), username: username, hash: hashed} as bool
}
