# js_smoke

A minimal Gleam project that depends on `oaspec` with
`target = "javascript"`. It imports a few public modules from oaspec
that are documented as pure in [`ARCHITECTURE.md`](../../ARCHITECTURE.md)
and verifies they both compile and run on Node.

This is **not** an end-user example — it does not actually issue HTTP
calls (a JavaScript transport adapter is tracked under
[#347](https://github.com/nao1215/oaspec/issues/347)). It exists so
that CI catches any regression that re-couples one of the documented
pure modules to BEAM-only code.

## Run locally

```bash
cd examples/js_smoke
gleam run
```

You should see `oaspec js_smoke: ok`.
