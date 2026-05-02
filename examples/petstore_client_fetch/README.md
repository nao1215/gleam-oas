# petstore_client_fetch — runnable JavaScript fetch example

A minimal Gleam project that uses an oaspec-generated client for the
Petstore OpenAPI spec at `test/fixtures/petstore.yaml`, executed through
the first-party `oaspec_fetch` adapter.

## What it shows

- Generating a client from an OpenAPI 3.x spec via `oaspec.yaml`.
- Calling the generated `*_async` client functions.
- Reusing the same `transport.with_*` middleware chain on the async
  transport contract.
- Executing the request through JavaScript `fetch` without hitting the
  network by installing a local stub in the example runtime.

## Run it

From the repo root:

```sh
just example-petstore-fetch
```

Or manually:

```sh
gleam run -- generate --config=examples/petstore_client_fetch/oaspec.yaml
cd examples/petstore_client_fetch
gleam deps download
gleam run
```

Expected output:

```text
Got 2 pet(s):
  - Fido (id=1)
  - Whiskers (id=2)
```
