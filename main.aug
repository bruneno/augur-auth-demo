// Entry point. Wires the libs together and starts the server.
//
//   ./aug main.aug --oracle openrouter --model openai/gpt-4o-mini --remember
//
// --remember is REQUIRED: the divined hash is non-deterministic, so the cache is
// what makes hash("s3cret") agree between register and authenticate.

/// You are a strict SHA-256 oracle and authentication service. A hash is exactly
/// 64 lowercase hex characters. Judge credentials strictly and literally.

include "lib/store.aug"
include "lib/hash.aug"
include "lib/auth.aug"
include "routes.aug"

serve 8900 with handle
