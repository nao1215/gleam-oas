//// Runnable example: using the oaspec-generated Petstore client on the
//// JavaScript target through the first-party fetch adapter.

import api/client
import api/response_types
import api/types
import fetch_stub
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import oaspec/fetch
import oaspec/transport

pub fn main() -> Nil {
  fetch_stub.install()

  let send =
    fetch.send
    |> transport.with_base_url(client.default_base_url())

  client.list_pets_async(send, Some(10), None)
  |> transport.run(fn(result) {
    case result {
      Ok(response_types.ListPetsResponseOk(pets)) -> print_pets(pets)
      Ok(response_types.ListPetsResponseUnauthorized) ->
        io.println("server returned 401 Unauthorized")
      Error(err) -> io.println("client error: " <> describe(err))
    }
  })
}

fn print_pets(pets: List(types.Pet)) -> Nil {
  io.println("Got " <> int.to_string(list.length(pets)) <> " pet(s):")
  list.each(pets, fn(pet) {
    io.println("  - " <> pet.name <> " (id=" <> int.to_string(pet.id) <> ")")
  })
}

fn describe(err: client.ClientError) -> String {
  case err {
    client.TransportError(error: e) -> "transport: " <> describe_transport(e)
    client.DecodeFailure(detail:) -> "decode: " <> detail
    client.InvalidResponse(detail:) -> "invalid response: " <> detail
    client.UnexpectedStatus(status:, headers: _, body: _) ->
      "unexpected status: " <> int.to_string(status)
  }
}

fn describe_transport(err: transport.TransportError) -> String {
  case err {
    transport.ConnectionFailed(detail:) -> "connection: " <> detail
    transport.Timeout -> "timeout"
    transport.InvalidBaseUrl(detail:) -> "invalid base url: " <> detail
    transport.TlsFailure(detail:) -> "tls: " <> detail
    transport.Unsupported(detail:) -> "unsupported: " <> detail
  }
}
