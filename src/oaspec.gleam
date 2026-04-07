import argv
import glint
import oaspec/cli

pub fn main() {
  cli.app()
  |> glint.run(argv.load().arguments)
}
