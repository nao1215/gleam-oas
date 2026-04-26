import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile
import yay

/// Configuration for oaspec code generation.
///
/// Opaque: external callers construct via `new/6` and read fields via
/// the accessors below. Mutators (`with_mode`, `with_validate`,
/// `with_output`) live in this module too, so every change to a
/// `Config` value goes through an explicit function.
pub opaque type Config {
  Config(
    input: String,
    output_server: String,
    output_client: String,
    package: String,
    mode: GenerateMode,
    validate: Bool,
  )
}

/// Construct a new `Config` from its six fields. Prefer `load/1` in
/// production code; `new/6` is primarily for tests and ad-hoc tooling
/// that assembles a config in memory.
pub fn new(
  input input: String,
  output_server output_server: String,
  output_client output_client: String,
  package package: String,
  mode mode: GenerateMode,
  validate validate: Bool,
) -> Config {
  Config(input:, output_server:, output_client:, package:, mode:, validate:)
}

/// Path to the OpenAPI spec this config was built for.
pub fn input(cfg: Config) -> String {
  cfg.input
}

/// Output directory for server-side generated files.
pub fn output_server(cfg: Config) -> String {
  cfg.output_server
}

/// Output directory for client-side generated files.
pub fn output_client(cfg: Config) -> String {
  cfg.output_client
}

/// Gleam package name (module prefix) for generated files.
pub fn package(cfg: Config) -> String {
  cfg.package
}

/// Generation mode: server, client, or both.
pub fn mode(cfg: Config) -> GenerateMode {
  cfg.mode
}

/// Whether guard-based runtime validation is enabled.
pub fn validate(cfg: Config) -> Bool {
  cfg.validate
}

/// Generation mode.
pub type GenerateMode {
  Server
  Client
  Both
}

/// Errors that can occur when loading config.
pub type ConfigError {
  FileNotFound(path: String)
  FileReadError(path: String, detail: String)
  ParseError(detail: String)
  MissingField(field: String)
  InvalidValue(field: String, detail: String)
}

/// Parse a mode string into GenerateMode.
pub fn parse_mode(mode: String) -> Result(GenerateMode, ConfigError) {
  case mode {
    "server" -> Ok(Server)
    "client" -> Ok(Client)
    "both" -> Ok(Both)
    _ ->
      Error(InvalidValue(
        field: "mode",
        detail: "must be one of: server, client, both",
      ))
  }
}

/// Load config from a YAML file.
pub fn load(path: String) -> Result(Config, ConfigError) {
  use content <- result.try(
    simplifile.read(path)
    |> result.map_error(fn(e) {
      case e {
        simplifile.Enoent -> FileNotFound(path:)
        _ ->
          FileReadError(
            path:,
            detail: "Failed to read file: " <> simplifile.describe_error(e),
          )
      }
    }),
  )

  use docs <- result.try(
    yay.parse_string(content)
    |> result.map_error(fn(e) {
      ParseError(detail: "YAML parse error: " <> yaml_error_to_string(e))
    }),
  )

  use doc <- result.try(case docs {
    [first, ..] -> Ok(first)
    [] -> Error(ParseError(detail: "Empty YAML document"))
  })

  let root = yay.document_root(doc)

  use input <- result.try(
    yay.extract_string(root, "input")
    // nolint: error_context_lost -- yay ExtractionError details (KeyMissing vs KeyTypeMismatch) are internal; surfacing MissingField is the user-facing contract
    |> result.map_error(fn(_) { MissingField(field: "input") }),
  )

  let package =
    yay.extract_optional_string(root, "package")
    |> result.unwrap(None)
    |> option.unwrap("api")

  // Determine output base directory first, then derive server/client paths.
  // Priority: output.server/client (explicit) > output.dir (base) > default "./gen"
  //
  // Both default paths land *inside* the base dir (Issue #248): the previous
  // sibling `<dir>_client/<package>` derivation put client code where
  // `gleam build` could not see it. The new layout is
  //   server: <dir>/<package>
  //   client: <dir>/<package>_client
  // so a single `gleam build` rooted at <dir> sees both. Users who actually
  // want server and client in separate Gleam projects keep setting
  // output.server / output.client explicitly.
  let output_dir =
    extract_nested_string(root, "output", "dir")
    |> option.unwrap("./gen")

  let output_server =
    extract_nested_string(root, "output", "server")
    |> option.unwrap(output_dir <> "/" <> package)

  let output_client =
    extract_nested_string(root, "output", "client")
    |> option.unwrap(output_dir <> "/" <> package <> "_client")

  use mode <- result.try(
    case yay.extract_optional_string(root, "mode") |> result.unwrap(None) {
      Some("server") -> Ok(Server)
      Some("client") -> Ok(Client)
      Some("both") -> Ok(Both)
      None -> Ok(Both)
      Some(other) ->
        Error(InvalidValue(
          field: "mode",
          detail: "must be one of: server, client, both (got: " <> other <> ")",
        ))
    },
  )

  // When `validate:` is omitted, the default is mode-dependent (issue #268).
  // Server-mode codegen with `validate: false` lets schema-invalid input
  // (`minimum`, `maximum`, `pattern`, `minLength`, `maxLength` violations)
  // through to user handlers — security-adjacent and surprising. The
  // generator emits the guard functions either way; the only knob is whether
  // the router calls them. So fail-closed by default for any mode that
  // produces a server (`Server` and `Both`), and keep `False` only for the
  // pure-client case where pre-validating before send is nice but optional.
  // Explicit `validate: true` / `validate: false` continues to override.
  use validate <- result.try(
    case yay.select_sugar(from: root, selector: "validate") {
      Ok(yay.NodeBool(True)) | Ok(yay.NodeStr("true")) -> Ok(True)
      Ok(yay.NodeBool(False)) | Ok(yay.NodeStr("false")) -> Ok(False)
      // nolint: thrown_away_error -- missing optional 'validate' key defaults to mode-dependent value
      Error(_) ->
        case mode {
          Server | Both -> Ok(True)
          Client -> Ok(False)
        }
      Ok(_) ->
        Error(InvalidValue(
          field: "validate",
          detail: "must be a boolean (true or false)",
        ))
    },
  )

  Ok(Config(input:, output_server:, output_client:, package:, mode:, validate:))
}

/// Apply CLI overrides to a config.
pub fn with_mode(config: Config, mode: GenerateMode) -> Config {
  Config(..config, mode:)
}

/// Apply validation mode override.
pub fn with_validate(config: Config, validate: Bool) -> Config {
  Config(..config, validate:)
}

/// Apply output base directory override.
/// Derives server/client paths as <dir>/<package> and <dir>/<package>_client.
/// Issue #248: the client default used to be a sibling `<dir>_client/<package>`,
/// which left the generated client code outside any Gleam src/ root. The new
/// layout keeps both paths under <dir> so a single `gleam build` sees both.
pub fn with_output(config: Config, output: Option(String)) -> Config {
  case output {
    Some(dir) ->
      Config(
        ..config,
        output_server: dir <> "/" <> config.package,
        output_client: dir <> "/" <> config.package <> "_client",
      )
    None -> config
  }
}

/// Validate that output directory basenames are valid Gleam module names
/// usable as import roots.
///
/// Server output must end in `<package>` so generated imports such as
/// `import <package>/types` resolve. Client output may end in either
/// `<package>` (when client lives in its own project) or `<package>_client`
/// (the new default since Issue #248 — both server and client share the same
/// `<dir>` and need distinct basenames). Anything else is a misconfigured
/// package/output mismatch the user should be told about.
pub fn validate_output_package_match(config: Config) -> Result(Nil, ConfigError) {
  case config.mode {
    Server | Both ->
      case basename(config.output_server) == config.package {
        True -> Ok(Nil)
        False ->
          Error(InvalidValue(
            field: "output.server",
            detail: "Directory basename '"
              <> basename(config.output_server)
              <> "' must match package '"
              <> config.package
              <> "'",
          ))
      }
    Client -> Ok(Nil)
  }
  |> result.try(fn(_) {
    case config.mode {
      Client | Both -> {
        let client_basename = basename(config.output_client)
        let client_suffix = config.package <> "_client"
        case
          client_basename == config.package || client_basename == client_suffix
        {
          True -> Ok(Nil)
          False ->
            Error(InvalidValue(
              field: "output.client",
              detail: "Directory basename '"
                <> client_basename
                <> "' must match package '"
                <> config.package
                <> "' or '"
                <> client_suffix
                <> "'",
            ))
        }
      }
      Server -> Ok(Nil)
    }
  })
}

/// Get the basename of a path (last segment after /).
fn basename(path: String) -> String {
  path
  |> string.split("/")
  |> list.last
  |> result.unwrap("")
}

/// Convert config error to a human-readable string.
pub fn error_to_string(error: ConfigError) -> String {
  case error {
    FileNotFound(path:) ->
      "Config file not found: "
      <> path
      <> " (paths resolve relative to the current working directory)"
    FileReadError(path:, detail:) ->
      "Error reading config file " <> path <> ": " <> detail
    ParseError(detail:) -> "Config parse error: " <> detail
    MissingField(field:) -> "Missing required config field: " <> field
    InvalidValue(field:, detail:) ->
      "Invalid value for " <> field <> ": " <> detail
  }
}

/// Extract a nested string value from YAML like output.server.
fn extract_nested_string(
  root: yay.Node,
  key1: String,
  key2: String,
) -> Option(String) {
  case yay.select_sugar(from: root, selector: key1 <> "." <> key2) {
    Ok(yay.NodeStr(value)) -> Some(value)
    _ -> None
  }
}

/// Convert a yay YAML error to string.
fn yaml_error_to_string(error: yay.YamlError) -> String {
  case error {
    yay.UnexpectedParsingError -> "Unexpected parsing error"
    yay.ParsingError(msg:, ..) -> msg
  }
}
