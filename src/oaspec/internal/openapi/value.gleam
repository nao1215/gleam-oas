//// Target-neutral JSON-compatible value type used to preserve arbitrary data
//// from OpenAPI specs (default, example, const, ...). This module is pure
//// Gleam: it defines the type only, with no `yay` or BEAM-specific
//// dependency, so it can be compiled on any Gleam target.
////
//// The yay → JsonValue bridge helpers (`extract_optional`, `extract_map`)
//// live in the BEAM-coupled `parser_value` sibling module.

import gleam/dict.{type Dict}

/// A JSON-compatible value type for preserving arbitrary data from OpenAPI specs.
/// Used for example, default, const, and other values that aren't necessarily strings.
pub type JsonValue {
  JsonNull
  JsonBool(Bool)
  JsonInt(Int)
  JsonFloat(Float)
  JsonString(String)
  JsonArray(List(JsonValue))
  JsonObject(Dict(String, JsonValue))
}
