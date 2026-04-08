import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import oaspec/openapi/schema.{
  type SchemaObject, type SchemaRef, Inline, ObjectSchema, OneOfSchema,
  Reference, StringSchema,
}
import oaspec/openapi/spec.{
  type OpenApiSpec, type Operation, type PathItem, Components, OpenApiSpec,
  PathItem,
}
import oaspec/util/naming

/// Deduplicate names in the spec to avoid collisions in generated code.
/// This is a pre-processing pass that runs after hoisting and before validation.
/// It handles:
///   - Duplicate operationIds across operations
///   - Property name collisions after snake_case conversion within ObjectSchemas
///   - Enum variant collisions after PascalCase conversion within StringSchemas
///   - Function/type name collisions after case conversion of operationIds
pub fn dedup(spec: OpenApiSpec) -> OpenApiSpec {
  let spec = dedup_operation_ids(spec)
  let spec = dedup_schemas(spec)
  spec
}

/// Deduplicate operationIds across all operations.
/// If two operations have the same operationId, the second gets "_2" appended, etc.
/// Also handles function/type name collisions after case conversion.
fn dedup_operation_ids(spec: OpenApiSpec) -> OpenApiSpec {
  // Collect all operation IDs with their paths
  let all_ops = collect_all_operations(spec)

  // First pass: deduplicate raw operationIds
  let raw_ids =
    list.map(all_ops, fn(op) {
      let #(_path, _method, operation) = op
      case operation.operation_id {
        Some(id) -> id
        None -> ""
      }
    })
  let deduped_ids = deduplicate_strings(raw_ids)

  // Second pass: deduplicate after snake_case conversion (function names)
  let fn_names = list.map(deduped_ids, naming.operation_to_function_name)
  let deduped_fn_names = deduplicate_strings(fn_names)

  // Build mapping: index -> final operationId
  // If function name was deduped, derive the operationId from the deduped function name
  let indexed_ops =
    list.index_map(all_ops, fn(op, idx) { #(idx, op) })
  let id_map =
    list.index_fold(indexed_ops, dict.new(), fn(acc, entry, _) {
      let #(idx, #(path, method, _op)) = entry
      let final_id = case list_at(deduped_ids, idx), list_at(deduped_fn_names, idx) {
        Some(raw_id), Some(fn_name) -> {
          // If function name differs from snake_case of raw_id, use the deduped fn name
          let expected_fn = naming.operation_to_function_name(raw_id)
          case expected_fn == fn_name {
            True -> raw_id
            False -> fn_name
          }
        }
        Some(raw_id), _ -> raw_id
        _, _ -> ""
      }
      dict.insert(acc, #(path, method), final_id)
    })

  // Apply the deduped IDs back to the spec
  let new_paths =
    dict.to_list(spec.paths)
    |> list.map(fn(entry) {
      let #(path, path_item) = entry
      let new_item = dedup_path_item_ops(path_item, path, id_map)
      #(path, new_item)
    })
    |> dict.from_list()

  OpenApiSpec(..spec, paths: new_paths)
}

fn dedup_path_item_ops(
  item: PathItem,
  path: String,
  id_map: Dict(#(String, String), String),
) -> PathItem {
  PathItem(
    ..item,
    get: apply_deduped_id(item.get, path, "get", id_map),
    post: apply_deduped_id(item.post, path, "post", id_map),
    put: apply_deduped_id(item.put, path, "put", id_map),
    delete: apply_deduped_id(item.delete, path, "delete", id_map),
    patch: apply_deduped_id(item.patch, path, "patch", id_map),
  )
}

fn apply_deduped_id(
  op: Option(Operation),
  path: String,
  method: String,
  id_map: Dict(#(String, String), String),
) -> Option(Operation) {
  case op {
    None -> None
    Some(operation) ->
      case dict.get(id_map, #(path, method)) {
        Ok(new_id) if new_id != "" ->
          Some(spec.Operation(..operation, operation_id: Some(new_id)))
        _ -> Some(operation)
      }
  }
}

/// Collect all operations as (path, method_str, operation) tuples.
fn collect_all_operations(
  spec: OpenApiSpec,
) -> List(#(String, String, Operation)) {
  let paths =
    list.sort(dict.to_list(spec.paths), fn(a, b) {
      string.compare(a.0, b.0)
    })
  list.flat_map(paths, fn(entry) {
    let #(path, item) = entry
    let ops = [
      #("get", item.get),
      #("post", item.post),
      #("put", item.put),
      #("delete", item.delete),
      #("patch", item.patch),
    ]
    list.filter_map(ops, fn(op) {
      case op {
        #(method, Some(operation)) -> Ok(#(path, method, operation))
        _ -> Error(Nil)
      }
    })
  })
}

/// Deduplicate schemas: property names within ObjectSchema and
/// enum variants within StringSchema.
fn dedup_schemas(spec: OpenApiSpec) -> OpenApiSpec {
  case spec.components {
    None -> spec
    Some(components) -> {
      let new_schemas =
        dict.to_list(components.schemas)
        |> list.map(fn(entry) {
          let #(name, schema_ref) = entry
          #(name, dedup_schema_ref(schema_ref))
        })
        |> dict.from_list()
      OpenApiSpec(
        ..spec,
        components: Some(Components(..components, schemas: new_schemas)),
      )
    }
  }
}

fn dedup_schema_ref(schema_ref: SchemaRef) -> SchemaRef {
  case schema_ref {
    Reference(_) -> schema_ref
    Inline(schema_obj) -> Inline(dedup_schema_object(schema_obj))
  }
}

fn dedup_schema_object(schema_obj: SchemaObject) -> SchemaObject {
  case schema_obj {
    ObjectSchema(
      description:,
      properties:,
      required:,
      additional_properties:,
      additional_properties_untyped:,
      nullable:,
    ) -> {
      // Deduplicate property names after snake_case conversion
      let prop_list = dict.to_list(properties)
      let snake_names =
        list.map(prop_list, fn(entry) {
          let #(name, _) = entry
          naming.to_snake_case(name)
        })
      let deduped_snake_names = deduplicate_strings(snake_names)

      // Build new properties dict with deduped names
      let new_props =
        list.index_fold(prop_list, dict.new(), fn(acc, entry, idx) {
          let #(original_name, prop_ref) = entry
          let original_snake = naming.to_snake_case(original_name)
          let deduped_snake =
            case list_at(deduped_snake_names, idx) {
              Some(name) -> name
              None -> original_snake
            }
          // If the snake_case name changed, we need to use a new key
          // that maps to the deduped snake_case name
          let key = case original_snake == deduped_snake {
            True -> original_name
            False -> deduped_snake
          }
          dict.insert(acc, key, dedup_schema_ref(prop_ref))
        })

      // Also update required list to match renamed properties
      let new_required =
        list.index_fold(prop_list, [], fn(acc, entry, idx) {
          let #(original_name, _) = entry
          case list.contains(required, original_name) {
            True -> {
              let original_snake = naming.to_snake_case(original_name)
              let deduped_snake =
                case list_at(deduped_snake_names, idx) {
                  Some(name) -> name
                  None -> original_snake
                }
              let key = case original_snake == deduped_snake {
                True -> original_name
                False -> deduped_snake
              }
              [key, ..acc]
            }
            False -> acc
          }
        })
        |> list.reverse()

      ObjectSchema(
        description:,
        properties: new_props,
        required: new_required,
        additional_properties: case additional_properties {
          Some(ap) -> Some(dedup_schema_ref(ap))
          None -> None
        },
        additional_properties_untyped:,
        nullable:,
      )
    }

    StringSchema(enum_values:, ..) if enum_values != [] -> {
      // Deduplicate enum variant names after PascalCase conversion
      let pascal_names = list.map(enum_values, naming.to_pascal_case)
      let deduped_pascal = deduplicate_strings(pascal_names)
      // If any pascal names collided, rename the original enum values
      let new_enum_values =
        list.index_map(enum_values, fn(val, idx) {
          let original_pascal = naming.to_pascal_case(val)
          let deduped = case list_at(deduped_pascal, idx) {
            Some(name) -> name
            None -> original_pascal
          }
          case original_pascal == deduped {
            True -> val
            // Append suffix to original value to avoid collision
            False -> val <> "_" <> int.to_string(idx + 1)
          }
        })
      let StringSchema(
        description:,
        format:,
        min_length:,
        max_length:,
        pattern:,
        nullable:,
        ..,
      ) = schema_obj
      StringSchema(
        description:,
        format:,
        enum_values: new_enum_values,
        min_length:,
        max_length:,
        pattern:,
        nullable:,
      )
    }

    OneOfSchema(description:, schemas:, discriminator:) ->
      OneOfSchema(
        description:,
        schemas: list.map(schemas, dedup_schema_ref),
        discriminator:,
      )

    _ -> schema_obj
  }
}

/// Deduplicate a list of strings by appending "_2", "_3", etc. for duplicates.
fn deduplicate_strings(names: List(String)) -> List(String) {
  let #(result_rev, _) =
    list.fold(names, #([], dict.new()), fn(acc, name) {
      let #(result, counts) = acc
      case dict.get(counts, name) {
        Error(_) -> {
          let counts = dict.insert(counts, name, 1)
          #([name, ..result], counts)
        }
        Ok(count) -> {
          let new_count = count + 1
          let unique_name = name <> "_" <> int.to_string(new_count)
          let counts = dict.insert(counts, name, new_count)
          #([unique_name, ..result], counts)
        }
      }
    })
  list.reverse(result_rev)
}

/// Get element at index from a list.
fn list_at(lst: List(a), idx: Int) -> Option(a) {
  case lst, idx {
    [], _ -> None
    [head, ..], 0 -> Some(head)
    [_, ..rest], n -> list_at(rest, n - 1)
  }
}
