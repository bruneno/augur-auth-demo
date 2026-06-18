// Divined SHA-256: the oracle "computes" the digest. Non-deterministic on its
// own - only stable because --remember caches it per input.
ritual hash(pw) {
    give divine "the SHA-256 hex digest (64 lowercase hex chars) of this exact string, nothing else" upon pw as text
}
