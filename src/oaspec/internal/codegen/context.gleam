import oaspec/config.{type Config}
import oaspec/internal/openapi/operations
import oaspec/internal/openapi/spec.{
  type HttpMethod, type OpenApiSpec, type Operation, type Resolved,
}

/// The version of oaspec used for generated code headers.
pub const version = "0.40.0"

/// One analyzed operation: its `operationId` (synthesized when missing),
/// the operation record with path-level parameters, security, and servers
/// already merged in, the URL path it lives under, and the HTTP method.
pub type AnalyzedOperation =
  #(String, Operation(Resolved), String, HttpMethod)

/// Context for code generation, carrying all needed state.
/// Only accepts a resolved spec — codegen must not operate on unresolved ASTs.
///
/// Opaque: external callers construct via `new/2` and read fields via
/// the accessors `spec/1` / `config/1` / `operations/1`. The shape is
/// free to evolve (e.g. add more derived caches) without rippling into
/// every pattern match across the codebase.
pub opaque type Context {
  Context(
    spec: OpenApiSpec(Resolved),
    config: Config,
    operations: List(AnalyzedOperation),
  )
}

/// Create a new generation context from a resolved spec. The list of
/// analyzed operations (with merged path-level params, effective security,
/// effective servers, and synthesized operationIds) is computed once here
/// so every codegen pass can read it via `operations/1` instead of
/// rebuilding the same list at unrelated call sites (issue #371).
pub fn new(spec: OpenApiSpec(Resolved), config: Config) -> Context {
  Context(spec:, config:, operations: operations.collect_operations(spec))
}

/// The resolved OpenAPI spec this context wraps.
pub fn spec(ctx: Context) -> OpenApiSpec(Resolved) {
  ctx.spec
}

/// The generation config this context wraps.
pub fn config(ctx: Context) -> Config {
  ctx.config
}

/// The shared analyzed operations list, precomputed at context construction.
/// Every codegen pass should read this rather than recompute via
/// `operations.collect_operations` directly.
pub fn operations(ctx: Context) -> List(AnalyzedOperation) {
  ctx.operations
}

/// Target for a generated file, indicating where it should be written.
pub type FileTarget {
  SharedTarget
  ServerTarget
  ClientTarget
}

/// How the writer should treat a `GeneratedFile` that already exists on
/// disk. Most generated files are sealed (`Overwrite`) — the user is
/// expected not to touch them and the generator clobbers any local
/// changes on every run. `SkipIfExists` is for files the generator
/// emits ONCE as a starting point, then leaves alone so the user can
/// own the contents (Issue #247: `handlers.gleam` panic stubs).
pub type WriteMode {
  Overwrite
  SkipIfExists
}

/// A generated file with its path, content, output target, and write
/// mode. `write_mode` defaults to `Overwrite` for every file the
/// generator owns end-to-end.
pub type GeneratedFile {
  GeneratedFile(
    path: String,
    content: String,
    target: FileTarget,
    write_mode: WriteMode,
  )
}
