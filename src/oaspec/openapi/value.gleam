import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/option.{type Option}

/// A lossless representation of arbitrary JSON/YAML values.
/// Used for default, example, and examples fields that can hold
/// any JSON type, not just strings.
pub type JsonValue {
  JsonNull
  JsonBool(Bool)
  JsonInt(Int)
  JsonFloat(Float)
  JsonString(String)
  JsonArray(List(JsonValue))
  JsonObject(Dict(String, JsonValue))
}

/// Convert a JsonValue to a display string.
pub fn to_string(value: JsonValue) -> String {
  case value {
    JsonNull -> "null"
    JsonBool(True) -> "true"
    JsonBool(False) -> "false"
    JsonInt(n) -> int.to_string(n)
    JsonFloat(f) -> float.to_string(f)
    JsonString(s) -> "\"" <> s <> "\""
    JsonArray(_) -> "[...]"
    JsonObject(_) -> "{...}"
  }
}

/// Try to extract a string value, returning None for non-strings.
pub fn as_string(value: JsonValue) -> Option(String) {
  case value {
    JsonString(s) -> option.Some(s)
    _ -> option.None
  }
}
