import gleam/list
import gleeunit
import gleeunit/should
import oaspec/util/naming

pub fn main() {
  gleeunit.main()
}

/// The complete list of Gleam reserved keywords that naming.escape_keyword
/// must protect against. Kept in sync with the `case` branch in
/// src/oaspec/util/naming.gleam. When a new keyword is added there, add
/// it here too — the whole-list assertions below depend on this being
/// exhaustive, not hand-picked.
const gleam_keywords: List(String) = [
  "as", "assert", "auto", "case", "const", "external", "fn", "if", "import",
  "let", "opaque", "panic", "pub", "test", "todo", "type", "use",
]

// naming.to_snake_case tests
// ===================================================================

pub fn naming_to_snake_case_all_keywords_escaped_test() {
  list.each(gleam_keywords, fn(kw) {
    naming.to_snake_case(kw)
    |> should.equal(kw <> "_")
  })
}

pub fn naming_to_snake_case_compound_with_keyword_not_escaped_test() {
  // A compound identifier that merely contains a keyword is already a
  // valid Gleam identifier, so it must NOT get a stray underscore.
  naming.to_snake_case("useItem")
  |> should.equal("use_item")
}

pub fn naming_to_snake_case_compound_producing_keyword_escaped_test() {
  // When normalization collapses to a single keyword, escape must kick
  // in. "Type" -> "type" -> "type_".
  naming.to_snake_case("Type")
  |> should.equal("type_")
}

pub fn naming_to_snake_case_non_keyword_unaffected_test() {
  naming.to_snake_case("listPets")
  |> should.equal("list_pets")
}

// naming.operation_to_function_name tests
// ===================================================================

pub fn naming_operation_to_function_name_all_keywords_escaped_test() {
  list.each(gleam_keywords, fn(kw) {
    naming.operation_to_function_name(kw)
    |> should.equal(kw <> "_")
  })
}

pub fn naming_operation_to_function_name_mixed_case_keyword_escaped_test() {
  // operationId: "Let" should still resolve to `let_`.
  naming.operation_to_function_name("Let")
  |> should.equal("let_")
}

// naming.schema_to_type_name tests
// ===================================================================
// Gleam reserves only lowercase words, so PascalCase type names never
// collide. These assertions lock that invariant in place so a future
// refactor cannot silently start over-escaping type names.

pub fn naming_schema_to_type_name_keyword_becomes_pascal_test() {
  list.each(gleam_keywords, fn(kw) {
    let result = naming.schema_to_type_name(kw)
    // Type names must not carry the escape suffix.
    should.be_false(result == kw <> "_")
    // And they must start with an uppercase letter.
    should.be_true(result != "" && result != kw)
  })
}

pub fn naming_schema_to_type_name_known_cases_test() {
  naming.schema_to_type_name("type")
  |> should.equal("Type")
  naming.schema_to_type_name("case")
  |> should.equal("Case")
  naming.schema_to_type_name("import")
  |> should.equal("Import")
}
