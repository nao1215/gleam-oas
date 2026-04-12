import gleam/string

/// Supported content types for code generation.
pub type ContentType {
  ApplicationJson
  TextPlain
  MultipartFormData
  FormUrlEncoded
  ApplicationOctetStream
  ApplicationXml
  TextXml
  UnsupportedContentType(String)
}

/// Parse a content type string into a ContentType.
/// Recognizes structured syntax suffixes: types ending with `+json` are
/// treated as JSON-compatible, and types ending with `+xml` as XML-compatible.
pub fn from_string(content_type: String) -> ContentType {
  case content_type {
    "application/json" -> ApplicationJson
    "text/plain" -> TextPlain
    "multipart/form-data" -> MultipartFormData
    "application/x-www-form-urlencoded" -> FormUrlEncoded
    "application/octet-stream" -> ApplicationOctetStream
    "application/xml" -> ApplicationXml
    "text/xml" -> TextXml
    other ->
      case string.ends_with(other, "+json") {
        True -> ApplicationJson
        False ->
          case string.ends_with(other, "+xml") {
            True -> ApplicationXml
            False -> UnsupportedContentType(other)
          }
      }
  }
}

/// Check if a content type string is JSON-compatible.
/// Matches "application/json" and any type with a "+json" suffix.
pub fn is_json_compatible(s: String) -> Bool {
  s == "application/json" || string.ends_with(s, "+json")
}

/// Check if a content type string is XML-compatible.
/// Matches "application/xml", "text/xml", and any type with a "+xml" suffix.
pub fn is_xml_compatible(s: String) -> Bool {
  s == "application/xml" || s == "text/xml" || string.ends_with(s, "+xml")
}

/// Convert a ContentType back to its string representation.
pub fn to_string(content_type: ContentType) -> String {
  case content_type {
    ApplicationJson -> "application/json"
    TextPlain -> "text/plain"
    MultipartFormData -> "multipart/form-data"
    FormUrlEncoded -> "application/x-www-form-urlencoded"
    ApplicationOctetStream -> "application/octet-stream"
    ApplicationXml -> "application/xml"
    TextXml -> "text/xml"
    UnsupportedContentType(s) -> s
  }
}

/// Check if a content type is supported anywhere in code generation.
pub fn is_supported(content_type: ContentType) -> Bool {
  case content_type {
    ApplicationJson -> True
    TextPlain -> True
    MultipartFormData -> True
    FormUrlEncoded -> True
    ApplicationOctetStream -> True
    ApplicationXml -> True
    TextXml -> True
    _ -> False
  }
}

/// Check if a content type is supported for request bodies.
pub fn is_supported_request(content_type: ContentType) -> Bool {
  case content_type {
    ApplicationJson -> True
    MultipartFormData -> True
    FormUrlEncoded -> True
    _ -> False
  }
}

/// Check if a content type is supported for responses.
pub fn is_supported_response(content_type: ContentType) -> Bool {
  case content_type {
    ApplicationJson -> True
    TextPlain -> True
    ApplicationOctetStream -> True
    ApplicationXml -> True
    TextXml -> True
    _ -> False
  }
}
