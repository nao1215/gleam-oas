//// User-owned handler implementations for the server_adapter example.
////
//// `oaspec generate` writes panic stubs into this file on first
//// generation and skips it on subsequent runs (`SkipIfExists`), so
//// edits made here survive regeneration. Issue #264 introduced the
//// `State` type as a placeholder for application-level dependencies
//// (database connections, configuration, loggers, etc.) — extend the
//// constructor here when you start wiring real values.

import api/guards
import api/request_types
import api/response_types
import api/types
import gleam/option.{None, Some}

/// Application state passed to every handler. The example does not
/// need any DB connection or configuration, so this is an empty
/// constructor — extend with fields when wiring real dependencies.
pub type State {
  State
}

pub fn list_pets(
  state: State,
  req: request_types.ListPetsRequest,
) -> response_types.ListPetsResponse {
  let _ = state
  let _ = req
  response_types.ListPetsResponseOk([
    types.Pet(
      id: 1,
      name: "Fido",
      status: types.PetStatusAvailable,
      tag: Some("dog"),
    ),
    types.Pet(
      id: 2,
      name: "Whiskers",
      status: types.PetStatusPending,
      tag: None,
    ),
  ])
}

pub fn create_pet(
  state: State,
  req: request_types.CreatePetRequest,
) -> response_types.CreatePetResponse {
  let _ = state
  // Run the generated validation guard before constructing the response.
  // A well-formed OpenAPI spec will reject out-of-range values at the
  // guard layer; returning 400 is the idiomatic mapping.
  case guards.validate_create_pet_request(req.body) {
    Error(_) -> response_types.CreatePetResponseBadRequest
    Ok(_) ->
      response_types.CreatePetResponseCreated(types.Pet(
        id: 100,
        name: req.body.name,
        status: types.PetStatusAvailable,
        tag: req.body.tag,
      ))
  }
}

pub fn get_pet(
  state: State,
  req: request_types.GetPetRequest,
) -> response_types.GetPetResponse {
  let _ = state
  case req.pet_id {
    1 ->
      response_types.GetPetResponseOk(types.Pet(
        id: 1,
        name: "Fido",
        status: types.PetStatusAvailable,
        tag: Some("dog"),
      ))
    _ -> response_types.GetPetResponseNotFound
  }
}

pub fn delete_pet(
  state: State,
  req: request_types.DeletePetRequest,
) -> response_types.DeletePetResponse {
  let _ = state
  case req.pet_id {
    1 -> response_types.DeletePetResponseNoContent
    _ -> response_types.DeletePetResponseNotFound
  }
}
