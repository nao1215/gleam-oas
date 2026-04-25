import argv
import gleam/io
import glint
import oaspec/cli

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

/// CLI entry point for the oaspec code generator.
///
/// Routes diagnostic output to stderr while keeping requested output (such as
/// `--help` text) on stdout, following POSIX/CLIG conventions.
pub fn main() -> Nil {
  case glint.execute(cli.app(), argv.load().arguments) {
    Error(message) -> {
      io.println_error(message)
      halt(1)
    }
    Ok(glint.Help(text)) -> io.println(text)
    Ok(glint.Out(_)) -> Nil
  }
}
