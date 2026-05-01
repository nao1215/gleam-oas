import oaspec_support as support

pub fn external_ref_collisions_and_cycles_test() {
  let _ = support.external_file_ref_for_component_schema_case()
  let _ = support.external_ref_collision_with_local_schema_rejected_case()
  let _ = support.external_ref_collision_across_files_rejected_case()
  let _ = support.external_ref_two_file_cycle_rejected_case()
  let _ = support.external_ref_three_file_cycle_rejected_case()
  let _ =
    support.external_ref_nested_collision_with_local_schema_rejected_case()
  let _ = support.external_ref_nested_collision_across_files_rejected_case()
  let _ = support.external_ref_in_component_path_items_case()
  let _ =
    support.external_ref_component_path_items_collision_with_local_schema_rejected_case()
  let _ = support.external_ref_in_header_schemas_case()
  let _ =
    support.external_ref_header_collision_with_local_schema_rejected_case()
  let _ = support.external_ref_chained_local_alias_in_shared_file_case()
  let _ = support.external_ref_chained_across_files_resolves_transitively_case()
  let _ = support.external_ref_in_callback_path_item_case()
  let _ =
    support.external_ref_callback_collision_with_local_schema_rejected_case()
  let _ = support.external_ref_in_operation_schemas_case()
  let _ =
    support.external_ref_operation_collision_with_local_schema_rejected_case()
  let _ = support.external_ref_in_parameter_content_schema_case()
  let _ =
    support.external_ref_parameter_content_collision_with_local_schema_rejected_case()
  let _ = support.external_ref_in_request_body_schema_case()
  let _ = support.external_ref_in_response_schema_case()
  let _ =
    support.external_ref_request_body_collision_with_local_schema_rejected_case()
  let _ = support.external_ref_in_parameter_schema_case()
  let _ =
    support.external_ref_parameter_schema_collision_with_local_schema_rejected_case()
  let _ = support.external_ref_in_composition_branch_case()
  let _ =
    support.external_ref_composition_collision_with_local_schema_rejected_case()
  let _ = support.external_ref_in_additional_properties_case()
  let _ =
    support.external_ref_additional_properties_collision_with_local_schema_rejected_case()
  let _ = support.external_ref_in_array_items_case()
  let _ =
    support.external_ref_array_items_collision_with_local_schema_rejected_case()
  let _ = support.external_ref_nested_in_object_property_case()
}

pub fn external_ref_resolution_contract_test() {
  let _ = support.path_item_ref_resolves_case()
  let _ = support.external_ref_rejected_case()
  let _ = support.error_invalid_ref_syntax_fails_resolve_case()
  let _ = support.external_param_ref_rejects_case()
  let _ = support.wrong_kind_ref_rejects_case()
  let _ = support.resolve_component_alias_case()
  let _ = support.external_whole_object_parameter_ref_case()
  let _ = support.external_whole_object_request_body_ref_case()
  let _ = support.external_whole_object_response_ref_case()
  let _ =
    support.validate_rejects_id_backed_url_ref_with_dedicated_diagnostic_case()
}

pub fn callback_ref_resolution_test() {
  let _ = support.parse_preserves_operation_level_callback_ref_case()
  let _ = support.parse_populates_components_callbacks_case()
  let _ = support.validate_rejects_callback_ref_with_missing_target_case()
  let _ = support.validate_rejects_cyclic_callback_ref_chain_case()
}
