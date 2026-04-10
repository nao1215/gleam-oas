import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set
import gleam/string
import oaspec/openapi/diagnostic.{type Diagnostic}
import oaspec/openapi/spec.{
  type Callback, type Components, type OpenApiSpec, type Operation,
  type Parameter, type PathItem, type RefOr, type RequestBody, type Resolved,
  type Response, type Unresolved, Callback, Components, Operation, PathItem, Ref,
  Value,
}

/// Resolve all RefOr aliases in the spec.
/// Call after parse and normalize, before capability_check and codegen.
/// Resolves both component-level aliases and inline $ref within operations.
pub fn resolve(
  spec: OpenApiSpec(Unresolved),
) -> Result(OpenApiSpec(Resolved), List(Diagnostic)) {
  use resolved <- result.try(resolve_internal(spec))
  Ok(coerce_stage(resolved))
}

/// Safe phantom type cast — stage has no runtime representation.
@external(erlang, "gleam_stdlib", "identity")
fn coerce_stage(spec: OpenApiSpec(a)) -> OpenApiSpec(b)

/// Internal resolve that preserves the input stage parameter.
fn resolve_internal(
  spec: OpenApiSpec(stage),
) -> Result(OpenApiSpec(stage), List(Diagnostic)) {
  case spec.components {
    None -> Ok(spec)
    Some(components) -> {
      use parameters <- result.try(
        resolve_component_dict(components.parameters, "components.parameters")
        |> result.map_error(fn(e) { [e] }),
      )
      use request_bodies <- result.try(
        resolve_component_dict(
          components.request_bodies,
          "components.requestBodies",
        )
        |> result.map_error(fn(e) { [e] }),
      )
      use responses <- result.try(
        resolve_component_dict(components.responses, "components.responses")
        |> result.map_error(fn(e) { [e] }),
      )
      use security_schemes <- result.try(
        resolve_component_dict(
          components.security_schemes,
          "components.securitySchemes",
        )
        |> result.map_error(fn(e) { [e] }),
      )
      use path_items <- result.try(
        resolve_component_dict(components.path_items, "components.pathItems")
        |> result.map_error(fn(e) { [e] }),
      )
      let resolved_components =
        Components(
          ..components,
          parameters: parameters,
          request_bodies: request_bodies,
          responses: responses,
          security_schemes: security_schemes,
          path_items: path_items,
        )
      // Resolve inline $ref in paths and webhooks
      let resolved_paths = resolve_inline_paths(spec.paths, resolved_components)
      let resolved_webhooks =
        resolve_inline_paths(spec.webhooks, resolved_components)
      Ok(
        spec.OpenApiSpec(
          ..spec,
          components: Some(resolved_components),
          paths: resolved_paths,
          webhooks: resolved_webhooks,
        ),
      )
    }
  }
}

/// Resolve all aliases in a component dict.
/// After resolution, all entries are Value.
fn resolve_component_dict(
  entries: Dict(String, RefOr(a)),
  context: String,
) -> Result(Dict(String, RefOr(a)), Diagnostic) {
  dict.to_list(entries)
  |> list.try_fold(entries, fn(acc, entry) {
    let #(name, value) = entry
    case value {
      Value(_) -> Ok(acc)
      Ref(ref) -> {
        use resolved <- result.try(resolve_alias(
          entries,
          ref,
          context <> "." <> name,
          set.new(),
        ))
        Ok(dict.insert(acc, name, Value(resolved)))
      }
    }
  })
}

/// Follow a $ref chain to find the concrete value.
fn resolve_alias(
  entries: Dict(String, RefOr(a)),
  ref: String,
  context: String,
  seen: set.Set(String),
) -> Result(a, Diagnostic) {
  case set.contains(seen, ref) {
    True ->
      Error(diagnostic.resolve_error(
        path: context,
        detail: "Circular component alias detected: " <> ref,
      ))
    False -> {
      let new_seen = set.insert(seen, ref)
      let ref_name = extract_ref_name(ref)
      case dict.get(entries, ref_name) {
        Ok(Value(value)) -> Ok(value)
        Ok(Ref(next_ref)) -> resolve_alias(entries, next_ref, context, new_seen)
        Error(_) ->
          Error(diagnostic.resolve_error(
            path: context,
            detail: "Unresolved component alias: "
              <> ref
              <> " — target '"
              <> ref_name
              <> "' not found.",
          ))
      }
    }
  }
}

/// Extract the last segment of a $ref path.
fn extract_ref_name(ref: String) -> String {
  ref
  |> string.split("/")
  |> list.last
  |> result.unwrap("unknown")
}

// ============================================================================
// Inline ref resolution: resolve Ref(...) within paths, operations, etc.
// ============================================================================

/// Resolve inline refs in a paths dict by looking up components.
fn resolve_inline_paths(
  paths: Dict(String, RefOr(PathItem(stage))),
  components: Components(stage),
) -> Dict(String, RefOr(PathItem(stage))) {
  dict.map_values(paths, fn(_path, ref_or) {
    case ref_or {
      Ref(ref_str) -> resolve_path_item_ref(ref_str, components)
      Value(pi) -> Value(resolve_inline_path_item(pi, components))
    }
  })
}

/// Resolve a path-level $ref by looking it up in components.pathItems.
fn resolve_path_item_ref(
  ref_str: String,
  components: Components(stage),
) -> RefOr(PathItem(stage)) {
  let ref_name = extract_ref_name(ref_str)
  case dict.get(components.path_items, ref_name) {
    Ok(Value(pi)) -> Value(resolve_inline_path_item(pi, components))
    Ok(Ref(_)) -> Ref(ref_str)
    Error(_) -> Ref(ref_str)
  }
}

/// Resolve inline refs within a path item.
fn resolve_inline_path_item(
  pi: PathItem(stage),
  components: Components(stage),
) -> PathItem(stage) {
  PathItem(
    ..pi,
    get: option_map(pi.get, resolve_inline_operation(_, components)),
    post: option_map(pi.post, resolve_inline_operation(_, components)),
    put: option_map(pi.put, resolve_inline_operation(_, components)),
    delete: option_map(pi.delete, resolve_inline_operation(_, components)),
    patch: option_map(pi.patch, resolve_inline_operation(_, components)),
    head: option_map(pi.head, resolve_inline_operation(_, components)),
    options: option_map(pi.options, resolve_inline_operation(_, components)),
    trace: option_map(pi.trace, resolve_inline_operation(_, components)),
    parameters: list.map(pi.parameters, resolve_param_ref(_, components)),
  )
}

/// Resolve inline refs within an operation.
fn resolve_inline_operation(
  op: Operation(stage),
  components: Components(stage),
) -> Operation(stage) {
  Operation(
    ..op,
    parameters: list.map(op.parameters, resolve_param_ref(_, components)),
    request_body: option_map(op.request_body, resolve_request_body_ref(
      _,
      components,
    )),
    responses: dict.map_values(op.responses, fn(_code, ref_or) {
      resolve_response_ref(ref_or, components)
    }),
    callbacks: dict.map_values(op.callbacks, fn(_name, cb) {
      resolve_inline_callback(cb, components)
    }),
  )
}

/// Resolve inline refs within a callback.
fn resolve_inline_callback(
  cb: Callback(stage),
  components: Components(stage),
) -> Callback(stage) {
  Callback(
    entries: dict.map_values(cb.entries, fn(_url, ref_or) {
      case ref_or {
        Ref(ref_str) -> resolve_path_item_ref(ref_str, components)
        Value(pi) -> Value(resolve_inline_path_item(pi, components))
      }
    }),
  )
}

/// Resolve a parameter Ref by looking it up in components.parameters.
fn resolve_param_ref(
  ref_or: RefOr(Parameter(stage)),
  components: Components(stage),
) -> RefOr(Parameter(stage)) {
  case ref_or {
    Value(_) -> ref_or
    Ref(ref_str) -> {
      let ref_name = extract_ref_name(ref_str)
      case dict.get(components.parameters, ref_name) {
        Ok(Value(p)) -> Value(p)
        _ -> ref_or
      }
    }
  }
}

/// Resolve a request body Ref by looking it up in components.request_bodies.
fn resolve_request_body_ref(
  ref_or: RefOr(RequestBody(stage)),
  components: Components(stage),
) -> RefOr(RequestBody(stage)) {
  case ref_or {
    Value(_) -> ref_or
    Ref(ref_str) -> {
      let ref_name = extract_ref_name(ref_str)
      case dict.get(components.request_bodies, ref_name) {
        Ok(Value(rb)) -> Value(rb)
        _ -> ref_or
      }
    }
  }
}

/// Resolve a response Ref by looking it up in components.responses.
fn resolve_response_ref(
  ref_or: RefOr(Response(stage)),
  components: Components(stage),
) -> RefOr(Response(stage)) {
  case ref_or {
    Value(_) -> ref_or
    Ref(ref_str) -> {
      let ref_name = extract_ref_name(ref_str)
      case dict.get(components.responses, ref_name) {
        Ok(Value(r)) -> Value(r)
        _ -> ref_or
      }
    }
  }
}

/// Map over an Option value.
fn option_map(opt: Option(a), f: fn(a) -> a) -> Option(a) {
  case opt {
    Some(v) -> Some(f(v))
    None -> None
  }
}
