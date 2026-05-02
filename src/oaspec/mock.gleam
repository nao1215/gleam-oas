//// Test helpers for `oaspec/transport`. The sync constructors return a
//// `transport.Send` value, and the `*_async` constructors return a
//// `transport.AsyncSend`, making it trivial to script fake responses in
//// tests without standing up a real HTTP runtime.

import oaspec/transport.{
  type AsyncSend, type Request, type Response, type Send, type TransportError,
  BytesBody, EmptyBody, Response, TextBody,
}

// Always respond with the given text body and status. Headers are empty.
pub fn text(status status: Int, body body: String) -> Send {
  fn(_req: Request) {
    Ok(Response(status: status, headers: [], body: TextBody(body)))
  }
}

// Async variant of `text`.
pub fn text_async(status status: Int, body body: String) -> AsyncSend {
  fn(_req: Request) {
    transport.resolve(
      Ok(Response(status: status, headers: [], body: TextBody(body))),
    )
  }
}

// Always respond with the given binary body and status. Headers are empty.
pub fn bytes(status status: Int, body body: BitArray) -> Send {
  fn(_req: Request) {
    Ok(Response(status: status, headers: [], body: BytesBody(body)))
  }
}

// Async variant of `bytes`.
pub fn bytes_async(status status: Int, body body: BitArray) -> AsyncSend {
  fn(_req: Request) {
    transport.resolve(
      Ok(Response(status: status, headers: [], body: BytesBody(body))),
    )
  }
}

// Always respond with the given status and an empty body.
pub fn empty(status status: Int) -> Send {
  fn(_req: Request) {
    Ok(Response(status: status, headers: [], body: EmptyBody))
  }
}

// Async variant of `empty`.
pub fn empty_async(status status: Int) -> AsyncSend {
  fn(_req: Request) {
    transport.resolve(
      Ok(Response(status: status, headers: [], body: EmptyBody)),
    )
  }
}

// Always fail with `transport.Timeout`.
pub fn timeout() -> Send {
  fn(_req: Request) { Error(transport.Timeout) }
}

// Async variant of `timeout`.
pub fn timeout_async() -> AsyncSend {
  fn(_req: Request) { transport.resolve(Error(transport.Timeout)) }
}

// Always fail with the given `TransportError`.
pub fn fail(error error: TransportError) -> Send {
  fn(_req: Request) { Error(error) }
}

// Async variant of `fail`.
pub fn fail_async(error error: TransportError) -> AsyncSend {
  fn(_req: Request) { transport.resolve(Error(error)) }
}

// Build a `Send` from an arbitrary handler — useful for asserting on
// the outbound request shape in tests.
pub fn from(
  handler handler: fn(Request) -> Result(Response, TransportError),
) -> Send {
  handler
}

// Build an `AsyncSend` from an arbitrary async handler.
pub fn from_async(
  handler handler: fn(Request) ->
    transport.Async(Result(Response, TransportError)),
) -> AsyncSend {
  handler
}
