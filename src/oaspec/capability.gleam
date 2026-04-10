import gleam/list

/// Support level for an OpenAPI feature.
pub type SupportLevel {
  /// Fully supported in parsing and code generation
  Supported
  /// Parsed and preserved but not used by codegen (warning emitted)
  ParsedNotUsed
  /// Detected and rejected with a clear error
  Rejected
  /// Not handled (unknown to oaspec)
  NotHandled
}

/// A capability entry describing support for one OpenAPI feature.
pub type Capability {
  Capability(
    /// Feature name (e.g. "allOf", "webhooks", "const")
    name: String,
    /// Category (e.g. "schema", "security", "path", "codegen")
    category: String,
    /// Current support level
    level: SupportLevel,
    /// Brief description of the status
    note: String,
  )
}

/// The complete capability registry.
/// Single source of truth for what oaspec supports.
pub fn registry() -> List(Capability) {
  [
    // Schema features
    Capability(
      "object",
      "schema",
      Supported,
      "Object schemas with properties and required",
    ),
    Capability(
      "string",
      "schema",
      Supported,
      "String schemas with format, enum, pattern, minLength, maxLength",
    ),
    Capability(
      "integer",
      "schema",
      Supported,
      "Integer schemas with format, minimum, maximum, multipleOf",
    ),
    Capability(
      "number",
      "schema",
      Supported,
      "Number schemas with format, minimum, maximum, multipleOf",
    ),
    Capability("boolean", "schema", Supported, "Boolean schemas"),
    Capability(
      "array",
      "schema",
      Supported,
      "Array schemas with items, minItems, maxItems, uniqueItems",
    ),
    Capability("allOf", "schema", Supported, "Schema composition via allOf"),
    Capability(
      "oneOf",
      "schema",
      Supported,
      "Schema composition via oneOf with discriminator",
    ),
    Capability(
      "anyOf",
      "schema",
      Supported,
      "Schema composition via anyOf with discriminator",
    ),
    Capability(
      "nullable",
      "schema",
      Supported,
      "Nullable fields via nullable: true or type: [T, null]",
    ),
    Capability(
      "additionalProperties",
      "schema",
      Supported,
      "Typed, untyped (true), and forbidden (false)",
    ),
    Capability("$ref", "schema", Supported, "Local $ref resolution for schemas"),
    Capability("enum", "schema", Supported, "String enum values"),
    Capability(
      "discriminator",
      "schema",
      Supported,
      "Discriminator with propertyName and mapping",
    ),
    // Rejected JSON Schema 2020-12 keywords
    Capability(
      "const",
      "schema",
      Rejected,
      "Use enum with single value instead",
    ),
    Capability(
      "$defs",
      "schema",
      Rejected,
      "Move definitions to components/schemas",
    ),
    Capability("prefixItems", "schema", Rejected, "Tuple types not supported"),
    Capability("if/then/else", "schema", Rejected, "Use oneOf/anyOf instead"),
    Capability(
      "dependentSchemas",
      "schema",
      Rejected,
      "Not supported for codegen",
    ),
    Capability("not", "schema", Rejected, "Negation not supported"),
    Capability(
      "unevaluatedProperties",
      "schema",
      Rejected,
      "Not supported for codegen",
    ),
    Capability(
      "unevaluatedItems",
      "schema",
      Rejected,
      "Not supported for codegen",
    ),
    Capability(
      "contentEncoding",
      "schema",
      Rejected,
      "Not supported for codegen",
    ),
    Capability(
      "contentMediaType",
      "schema",
      Rejected,
      "Not supported for codegen",
    ),
    Capability("contentSchema", "schema", Rejected, "Not supported for codegen"),
    // Security
    Capability(
      "apiKey",
      "security",
      Supported,
      "Header, query, and cookie API keys",
    ),
    Capability("http", "security", Supported, "Bearer and basic auth schemes"),
    Capability("oauth2", "security", Supported, "OAuth2 flows with scopes"),
    Capability(
      "openIdConnect",
      "security",
      Supported,
      "OpenID Connect discovery",
    ),
    Capability(
      "mutualTLS",
      "security",
      Rejected,
      "TLS client certificates not supported",
    ),
    // Parameters
    Capability(
      "path parameters",
      "parameter",
      Supported,
      "With schema validation",
    ),
    Capability(
      "query parameters",
      "parameter",
      Supported,
      "Including array and deepObject styles",
    ),
    Capability(
      "header parameters",
      "parameter",
      Supported,
      "String, integer, float, boolean",
    ),
    Capability(
      "cookie parameters",
      "parameter",
      Supported,
      "With percent-decoding",
    ),
    Capability(
      "allowReserved",
      "parameter",
      Supported,
      "Skips percent-encoding for reserved chars",
    ),
    // Request bodies
    Capability("application/json", "request", Supported, "JSON request bodies"),
    Capability(
      "application/x-www-form-urlencoded",
      "request",
      Supported,
      "Form bodies with bracket encoding",
    ),
    Capability(
      "multipart/form-data",
      "request",
      Supported,
      "Multipart file upload",
    ),
    // Responses
    Capability(
      "application/json",
      "response",
      Supported,
      "JSON response bodies",
    ),
    Capability("text/plain", "response", Supported, "Text response passthrough"),
    Capability(
      "application/octet-stream",
      "response",
      Supported,
      "Binary response passthrough",
    ),
    // Codegen scope
    Capability("webhooks", "scope", ParsedNotUsed, "Parsed but no codegen"),
    Capability("externalDocs", "scope", ParsedNotUsed, "Parsed but no codegen"),
    Capability("tags", "scope", ParsedNotUsed, "Parsed but no codegen"),
    Capability("examples", "scope", ParsedNotUsed, "Parsed but no codegen"),
    Capability("links", "scope", ParsedNotUsed, "Parsed but no codegen"),
    Capability("xml", "scope", NotHandled, "XML annotations ignored"),
    Capability(
      "operation servers",
      "scope",
      ParsedNotUsed,
      "Client uses top-level server only",
    ),
    Capability(
      "path servers",
      "scope",
      ParsedNotUsed,
      "Client uses top-level server only",
    ),
    Capability(
      "response headers",
      "scope",
      ParsedNotUsed,
      "Parsed but no codegen",
    ),
    Capability("encoding", "scope", ParsedNotUsed, "Parsed but no codegen"),
  ]
}

/// Get capabilities filtered by support level.
pub fn by_level(level: SupportLevel) -> List(Capability) {
  list.filter(registry(), fn(c) { c.level == level })
}

/// Get capabilities filtered by category.
pub fn by_category(category: String) -> List(Capability) {
  list.filter(registry(), fn(c) { c.category == category })
}
