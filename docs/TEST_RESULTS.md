# Test results

Run on 14 November 2026 with `python3 -m unittest discover -s tests -v`
(Python 3.13, SQLite 3.53). **140 tests, 140 passed.**

These tests cover the database tool, the workflow gates, the paid-generation hook script, the
merged skills, the video breakdown script (on a synthetic clip built by ffmpeg), the agent
contracts, the Kling dry-run adapter and the structure of the two subagent files.

Added on 13 November for the migration: recovered files are byte-identical to the originals; the
schema upgrade keeps every row; the Agent 00 mirror is idempotent, read-only towards Agent 00,
keeps IDs, URLs, creator, access status, certainty labels and analysis history, and folds
duplicate links into one record; the 15-column manifest round-trips the owner's template exactly.

Agent 00 was also run once on its own; that is a behavioural test, logged separately in
`docs/tests/AGENT00_TEST_2026-11-13.md`, and is not part of the 140.

They do not cover: any subagent actually running, analysis of real footage or real references,
any live generation, or the hook firing inside a live session.

## Coverage of the twelve validation scenarios

| # | Scenario | Status |
|---|---|---|
| 1 | Start a project from a simple idea | Partly: project creation and routing tested; no creative output yet |
| 2 | Create a project from an inspiration link | Partly: routing, link storage, dedupe and the Agent 00 mirror tested; no real accessible reference analysed yet |
| 3 | Handle an inaccessible Instagram or Pinterest reference | Tested at the data layer and by one Agent 00 run on a real Instagram link (blocked by this environment's network, reported accurately) |
| 4 | Generate a concept and pause for approval | Gate tested; concept generation not built |
| 5 | Storyboard and structured shot list | Storage and versioning tested; generation not built |
| 6 | Analyse a reference video | Partly: cuts, timings and frames tested on a synthetic clip; framing and movement analysis needs the agent and real footage |
| 7 | Propose new Master Shot Manifest entries | Tested for both libraries: 15-column reference shots and linked techniques; no proposal from real footage yet |
| 8 | AI video production specification | Partly: spec contract and Kling dry-run tested; the agent that writes specs has not been run |
| 9 | Motion graphics approval sequence | Gate order tested; production blocked on Motion Director |
| 10 | Resume an interrupted project | Tested |
| 11 | Prevent unauthorised paid generation or publishing | Tested (hook script invoked directly; live firing not yet observed) |
| 12 | Existing skills remain functional | Tested for script execution and skill frontmatter |

## Full output

```
test_blocked_needs_a_reason_and_it_is_shown_and_mirrored [TestAgent00GapFixes] ... ok
test_catalog_made_by_the_original_tool_is_upgraded_in_place [TestAgent00GapFixes] ... ok
test_export_carries_timecodes_and_frames_from_the_analysis [TestAgent00GapFixes] ... ok
test_export_says_when_there_is_nothing_to_export [TestAgent00GapFixes] ... ok
test_network_block_and_login_wall_are_distinguishable [TestAgent00GapFixes] ... ok
test_reason_is_refused_on_a_reference_that_was_reviewed_and_cleared_on_later_review [TestAgent00GapFixes] ... ok
test_skill_documents_the_three_additions [TestAgent00GapFixes] ... ok
test_bad_input_is_a_clean_error_not_a_traceback [TestAgent00LocalFiles] ... ok
test_import_accepts_files_and_reports_bad_rows_without_stopping [TestAgent00LocalFiles] ... ok
test_links_behave_exactly_as_before [TestAgent00LocalFiles] ... ok
test_local_file_analysis_mirrors_and_exports_with_its_true_source [TestAgent00LocalFiles] ... ok
test_local_file_is_catalogued_without_inventing_a_url [TestAgent00LocalFiles] ... ok
test_same_file_under_another_name_or_spelling_is_a_duplicate [TestAgent00LocalFiles] ... ok
test_analysis_history_is_kept_when_agent00_revises [TestAgent00Mirror] ... ok
test_blocked_reference_is_mirrored_as_blocked_with_no_analysis_status [TestAgent00Mirror] ... ok
test_mirror_preserves_ids_urls_creator_access_and_certainty [TestAgent00Mirror] ... ok
test_missing_catalog_is_a_clear_error [TestAgent00Mirror] ... ok
test_observed_claims_on_a_blocked_reference_are_flagged [TestAgent00Mirror] ... ok
test_reference_already_in_the_studio_is_linked_not_duplicated [TestAgent00Mirror] ... ok
test_same_post_under_two_links_becomes_one_record_with_both_ref_ids [TestAgent00Mirror] ... ok
test_sync_is_idempotent [TestAgent00Mirror] ... ok
test_sync_never_writes_to_agent00s_catalog [TestAgent00Mirror] ... ok
test_agent00_proposals_import_pending_and_link_to_their_reference [TestReferenceShotManifest] ... ok
test_import_is_idempotent_even_when_agent00_renumbers_its_proposals [TestReferenceShotManifest] ... ok
test_only_approved_shots_reach_the_exported_manifest_and_are_then_frozen [TestReferenceShotManifest] ... ok
test_technique_library_is_kept_and_links_back_to_reference_shots [TestReferenceShotManifest] ... ok
test_template_header_is_the_schema [TestReferenceShotManifest] ... ok
test_video_breakdown_csv_imports_against_an_asset [TestReferenceShotManifest] ... ok
test_wrong_format_is_refused [TestReferenceShotManifest] ... ok
test_old_database_is_refused_until_upgraded [TestSchemaUpgrade] ... ok
test_upgrade_keeps_every_row_and_maps_access_states [TestSchemaUpgrade] ... ok
test_agent00_definition_is_unchanged_and_has_no_model_pinned [TestVerbatimInstall] ... ok
test_agent00_skill_keeps_every_original_line_and_declares_its_additions [TestVerbatimInstall] ... ok
test_analysis_schema_keeps_every_original_field [TestVerbatimInstall] ... ok
test_archive_still_matches_the_packs_own_checksums [TestVerbatimInstall] ... ok
test_catalog_tool_original_is_preserved_and_the_change_is_declared [TestVerbatimInstall] ... ok
test_installed_files_are_byte_identical_to_the_recovered_originals [TestVerbatimInstall] ... ok
test_motion_director_gate_order_is_intact [TestVerbatimInstall] ... ok
test_motion_director_keeps_its_method_after_the_topic_removal [TestVerbatimInstall] ... ok
test_recovered_skills_have_their_original_names [TestVerbatimInstall] ... ok
test_v04_editing_skills_were_not_replaced_by_the_older_drafts [TestVerbatimInstall] ... ok
test_agents_have_no_generation_or_approval_powers [TestAgentDefinitions] ... ok
test_agents_have_valid_frontmatter_and_allowed_models [TestAgentDefinitions] ... ok
test_no_agent_name_collides_with_a_skill_or_the_recovered_agent [TestAgentDefinitions] ... ok
test_qa_cannot_accept_with_failed_or_unchecked_items [TestContracts] ... ok
test_qa_cannot_accept_without_inspection [TestContracts] ... ok
test_qa_pass_or_fail_needs_evidence_and_retry_needs_fixes [TestContracts] ... ok
test_spec_cannot_carry_an_unsourced_cost_or_extra_paid_calls [TestContracts] ... ok
test_spec_needs_acceptance_criteria_and_identity_invariants [TestContracts] ... ok
test_templates_are_valid [TestContracts] ... ok
test_adapter_source_contains_no_network_or_process_calls [TestKlingDryRun] ... ok
test_keyframe_model_accepts_first_and_last_frame_and_vertical [TestKlingDryRun] ... ok
test_no_price_is_ever_invented [TestKlingDryRun] ... ok
test_planned_tool_names_are_covered_by_the_paid_gate [TestKlingDryRun] ... ok
test_settings_the_account_does_not_have_are_rejected [TestKlingDryRun] ... ok
test_unverified_tools_are_refused_rather_than_guessed [TestKlingDryRun] ... ok
test_valid_spec_becomes_a_planned_call_and_nothing_is_submitted [TestKlingDryRun] ... ok
test_every_shot_has_real_start_middle_and_end_frames [TestVideoProbe] ... ok
test_hard_cuts_are_found_within_a_frame_or_two [TestVideoProbe] ... ok
test_metadata_is_read_from_the_file [TestVideoProbe] ... ok
test_missing_or_unreadable_file_fails_cleanly [TestVideoProbe] ... ok
test_refuses_to_write_into_a_non_empty_folder [TestVideoProbe] ... ok
test_shot_list_uses_the_owners_manifest_columns_and_invents_nothing [TestVideoProbe] ... ok
test_source_video_is_untouched [TestVideoProbe] ... ok
test_brief_with_project_reference_file_or_link_is_allowed [TestBriefGate] ... ok
test_hooks_are_registered [TestBriefGate] ... ok
test_other_agents_and_tools_are_not_affected [TestBriefGate] ... ok
test_studio_specialists_cannot_start_without_the_owners_input [TestBriefGate] ... ok
test_subject_driven_skills_need_the_owners_subject [TestBriefGate] ... ok
test_every_message_gets_the_current_project_and_rules [TestContextHook] ... ok
test_hook_never_blocks_even_when_broken [TestContextHook] ... ok
test_hook_raises_the_stop_for_the_failure_case [TestContextHook] ... ok
test_hook_shows_pending_approvals [TestContextHook] ... ok
test_continue_stays_on_the_current_project [TestEntryPoints] ... ok
test_continue_with_no_project_asks [TestEntryPoints] ... ok
test_direct_request_in_words_uses_the_owners_subject [TestEntryPoints] ... ok
test_empty_input_is_refused [TestEntryPoints] ... ok
test_link_is_a_reference [TestEntryPoints] ... ok
test_named_specialist_that_does_not_fit_the_attachment_is_flagged [TestEntryPoints] ... ok
test_named_specialist_that_fits_the_current_project_continues_it [TestEntryPoints] ... ok
test_named_specialist_with_no_subject_and_no_project_asks [TestEntryPoints] ... ok
test_named_specialist_with_the_owners_own_subject_is_allowed [TestEntryPoints] ... ok
test_new_input_while_a_project_is_current_keeps_it_in_view [TestEntryPoints] ... ok
test_no_route_ever_names_a_subject_domain_or_platform [TestEntryPoints] ... ok
test_resumed_project_becomes_current_and_cancelled_one_does_not_linger [TestEntryPoints] ... ok
'proceed with Motion Director testing' while the candle project is current. ... ok
test_uploaded_image_without_words [TestEntryPoints] ... ok
test_uploaded_own_footage_enters_at_the_edit [TestEntryPoints] ... ok
test_uploaded_video_without_words_asks_what_it_is [TestEntryPoints] ... ok
test_motion_director_has_no_default_subject_audience_or_platform [TestNoBuiltInTopics] ... ok
test_no_sample_subject_or_default_domain_in_production_files [TestNoBuiltInTopics] ... ok
test_sample_data_lives_only_in_test_fixtures [TestNoBuiltInTopics] ... ok
test_worked_examples_that_remain_are_marked_as_illustration [TestNoBuiltInTopics] ... ok
test_agent_cannot_approve_without_user_words [TestApprovalGates] ... ok
test_concept_gate_blocks_until_user_approves [TestApprovalGates] ... ok
test_decided_approval_cannot_be_changed [TestApprovalGates] ... ok
test_export_and_publish_are_gated [TestApprovalGates] ... ok
test_motion_graphics_sequence_concept_then_style [TestApprovalGates] ... ok
test_rejection_keeps_the_gate_closed [TestApprovalGates] ... ok
test_stages_cannot_be_skipped_but_rework_is_allowed [TestApprovalGates] ... ok
test_assets_dedupe_by_content [TestDocumentsAndResume] ... ok
test_choosing_one_of_three_concepts_approves_it_and_keeps_the_others_as_rejected [TestDocumentsAndResume] ... ok
test_documents_are_versioned_and_approved_ones_superseded_not_edited [TestDocumentsAndResume] ... ok
test_interrupted_project_resumes_from_the_database [TestDocumentsAndResume] ... ok
test_multiple_creative_variants_coexist [TestDocumentsAndResume] ... ok
test_shot_list_is_stored_as_structured_shots [TestDocumentsAndResume] ... ok
test_every_skill_has_valid_frontmatter [TestExistingSkillsStillWork] ... ok
test_ig_scripts_run [TestExistingSkillsStillWork] ... ok
test_ig_skills_no_longer_point_at_the_home_directory [TestExistingSkillsStillWork] ... ok
test_ids_are_sequential_and_prefixed [TestFoundation] ... ok
test_init_is_repeatable_and_creates_all_libraries [TestFoundation] ... ok
test_snapshot_restores_a_missing_database [TestFoundation] ... ok
test_attachment_outranks_a_vague_prompt [TestInputRouting] ... ok
test_explicit_motion_graphics_request_keeps_the_image_as_its_subject [TestInputRouting] ... ok
test_image_with_no_prompt_goes_to_agent00_as_a_reference [TestInputRouting] ... ok
test_no_input_is_an_error_not_a_sample_topic [TestInputRouting] ... ok
test_orchestrator_and_project_rules_forbid_sample_topics [TestInputRouting] ... ok
test_route_never_proposes_a_domain [TestInputRouting] ... ok
test_several_images_and_other_extensions_are_recognised [TestInputRouting] ... ok
test_video_reference_versus_own_footage [TestInputRouting] ... ok
test_accessible_reference_stores_analysis_with_basis [TestInspirationLibrary] ... ok
test_genres_grow_from_references_without_duplicates [TestInspirationLibrary] ... ok
test_ideas_without_links_dedupe_on_title [TestInspirationLibrary] ... ok
test_inaccessible_reference_cannot_receive_analysis [TestInspirationLibrary] ... ok
test_instagram_link_variants_are_one_reference [TestInspirationLibrary] ... ok
test_actual_costs_are_tracked [TestPaidGenerationGate] ... ok
test_approval_authorises_exactly_the_approved_number_of_calls [TestPaidGenerationGate] ... ok
test_budget_cap_blocks_overspend_requests [TestPaidGenerationGate] ... ok
test_generation_stage_needs_paid_approval [TestPaidGenerationGate] ... ok
test_hook_blocks_every_paid_tool_name [TestPaidGenerationGate] ... ok
test_hook_blocks_paid_tool_without_approval [TestPaidGenerationGate] ... ok
test_hook_fails_closed_without_a_database [TestPaidGenerationGate] ... ok
test_hook_ignores_free_tools [TestPaidGenerationGate] ... ok
test_paused_project_authorisation_is_not_used [TestPaidGenerationGate] ... ok
test_pending_or_rejected_approval_does_not_authorise [TestPaidGenerationGate] ... ok
test_project_new_routes_when_no_workflow_given [TestRouting] ... ok
test_requests_route_to_the_expected_workflow [TestRouting] ... ok
test_duplicates_and_near_matches_are_caught [TestShotManifest] ... ok
test_proposal_does_not_touch_manifest_until_approved [TestShotManifest] ... ok
test_rejected_proposal_is_recorded_not_added [TestShotManifest] ... ok
```
