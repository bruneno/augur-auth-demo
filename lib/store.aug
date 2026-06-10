// The only deterministic piece: where the users actually live (real SQLite).
ritual store() {
    certain {
        commune with "sqlite://./auth.db"
        give recall "every registered user" from users
    }
}
