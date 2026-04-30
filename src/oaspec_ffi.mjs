// JavaScript-target counterparts for the helpers exposed in
// oaspec_ffi.erl. Only functions actually called from cross-target
// Gleam modules need a JS implementation; the BEAM-only CLI helpers
// (find_executable, run_executable, is_stdout_tty, no_color_set) are
// not declared with a JS @external and therefore do not need a JS
// version here.

export function monotonic_ms() {
  // performance.now() is monotonic (unaffected by system clock changes)
  // and available in modern Node (>= 16) and all browsers. Fall back to
  // Date.now() if performance is somehow unavailable; the elapsed-time
  // semantics tolerate the slight loss of monotonicity for the brief
  // intervals oaspec actually measures.
  const ms =
    typeof performance !== "undefined" &&
    typeof performance.now === "function"
      ? performance.now()
      : Date.now();
  return Math.trunc(ms);
}
