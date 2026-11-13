# Test results

Run on 13 November 2026 with `python3 -m unittest discover -s tests -v`
(Python 3.13, SQLite 3.53). **61 tests, 61 passed.**

These tests cover the database tool, the workflow gates, the paid-generation hook script, the
merged skills, the video breakdown script (on a synthetic clip built by ffmpeg), the agent
contracts, the Kling dry-run adapter and the structure of the two subagent files.

They do not cover: any subagent actually running, analysis of real footage or real references,
any live generation, or the hook firing inside a live session.

## Coverage of the twelve validation scenarios

| # | Scenario | Status |
|---|---|---|
| 1 | Start a project from a simple idea | Partly: project creation and routing tested; no creative output yet |
| 2 | Create a project from an inspiration link | Partly: routing, link storage and dedupe tested; no analysis yet |
| 3 | Handle an inaccessible Instagram or Pinterest reference | Tested at the data layer: analysis is refused, link preserved |
| 4 | Generate a concept and pause for approval | Gate tested; concept generation not built |
| 5 | Storyboard and structured shot list | Storage and versioning tested; generation not built |
| 6 | Analyse a reference video | Partly: cuts, timings and frames tested on a synthetic clip; framing and movement analysis needs the agent and real footage |
| 7 | Propose new Master Shot Manifest entries | Proposal, duplicate detection and approval tested; detection from footage not built |
| 8 | AI video production specification | Partly: spec contract and Kling dry-run tested; the agent that writes specs has not been run |
| 9 | Motion graphics approval sequence | Gate order tested; production blocked on Motion Director |
| 10 | Resume an interrupted project | Tested |
| 11 | Prevent unauthorised paid generation or publishing | Tested (hook script invoked directly; live firing not yet observed) |
| 12 | Existing skills remain functional | Tested for script execution and skill frontmatter |

## Full output

```
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
test_agent_cannot_approve_without_user_words [TestApprovalGates] ... ok
test_concept_gate_blocks_until_user_approves [TestApprovalGates] ... ok
test_decided_approval_cannot_be_changed [TestApprovalGates] ... ok
test_export_and_publish_are_gated [TestApprovalGates] ... ok
test_motion_graphics_sequence_concept_then_style [TestApprovalGates] ... ok
test_rejection_keeps_the_gate_closed [TestApprovalGates] ... ok
test_stages_cannot_be_skipped_but_rework_is_allowed [TestApprovalGates] ... ok
test_assets_dedupe_by_content [TestDocumentsAndResume] ... ok
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
