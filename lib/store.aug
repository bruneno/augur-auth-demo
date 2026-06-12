// The only deterministic piece: where the users actually live (real MySQL).
ritual store() {
    certain {
        commune with "mysql://augur:augur@127.0.0.1:3308/augur"
        give recall "every registered user" from users
    }
}
