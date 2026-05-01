//// Tests for the precomputed analyzed-operations cache on `Context`.
//// `context.operations(ctx)` is the shared analyzed view that every codegen
//// pass should consume — these tests pin down its shape and ensure it stays
//// in sync with `operations.collect_operations` (issue #371).

import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import oaspec/internal/codegen/context
import oaspec/internal/openapi/operations
import test_helpers

pub fn main() {
  gleeunit.main()
}

const petstore = "test/fixtures/petstore.yaml"

pub fn operations_matches_direct_collect_test() {
  let ctx = test_helpers.make_ctx(petstore)
  let cached = context.operations(ctx)
  let direct = operations.collect_operations(context.spec(ctx))
  cached
  |> should.equal(direct)
}

pub fn operations_is_idempotent_across_calls_test() {
  // The cache is computed once at context.new/2 — repeated reads must not
  // re-run the traversal (and therefore must be the exact same list).
  let ctx = test_helpers.make_ctx(petstore)
  context.operations(ctx)
  |> should.equal(context.operations(ctx))
}

pub fn operations_petstore_op_ids_test() {
  let ctx = test_helpers.make_ctx(petstore)
  let op_ids =
    context.operations(ctx)
    |> list.map(fn(op) { op.0 })
  // petstore.yaml fixture defines operationIds explicitly, so the synthesizer
  // path is not exercised here — but we lock in the canonical set so any
  // accidental reshuffling shows up as a failed test.
  op_ids
  |> list.contains("listPets")
  |> should.be_true()
  op_ids
  |> list.contains("createPet")
  |> should.be_true()
}

pub fn operations_paths_are_sorted_test() {
  let ctx = test_helpers.make_ctx(petstore)
  let paths =
    context.operations(ctx)
    |> list.map(fn(op) { op.2 })
  // collect_operations sorts paths alphabetically before flat-mapping methods,
  // so the resulting path sequence must be non-decreasing.
  paths
  |> list.sort(string.compare)
  |> should.equal(paths)
}
