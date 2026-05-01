import oaspec_support as support

pub fn guard_integration_cases_test() {
  let _ = support.guard_integration_server_router_validates_body_case()
  let _ = support.guard_integration_server_no_validation_when_disabled_case()
  let _ = support.guard_integration_client_validates_body_case()
  let _ = support.guard_integration_client_no_validation_when_disabled_case()
  let _ = support.guard_integration_client_validates_optional_body_case()
  let _ = support.guard_integration_no_validation_for_unconstrained_body_case()
  let _ = support.guard_schema_has_validator_case()
  let _ = support.guard_schema_has_no_validator_case()
  let _ = support.guard_schema_has_validator_nonexistent_case()
}

pub fn server_override_cases_test() {
  let _ = support.server_override_operation_level_case()
  let _ = support.server_override_path_level_case()
  let _ = support.server_override_operation_takes_precedence_case()
  let _ = support.server_override_top_level_only_unchanged_case()
  let _ = support.server_override_no_capability_warnings_case()
  let _ = support.server_override_relative_url_case()
}
