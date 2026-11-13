# Test results

Run on 13 November 2026 with `python3 -m unittest discover -s tests -v`
(Python 3.13, SQLite 3.53). **38 tests, 38 passed.**

These tests cover the database tool, the workflow gates, the paid-generation hook script and the
merged skills. They do not cover subagents, real reference analysis, video analysis or any live
generation, none of which exists yet.

## Coverage of the twelve validation scenarios

| # | Scenario | Status |
|---|---|---|
| 1 | Start a project from a simple idea | Partly: project creation and routing tested; no creative output yet |
| 2 | Create a project from an inspiration link | Partly: routing, link storage and dedupe tested; no analysis yet |
| 3 | Handle an inaccessible Instagram or Pinterest reference | Tested at the data layer: analysis is refused, link preserved |
| 4 | Generate a concept and pause for approval | Gate tested; concept generation not built |
| 5 | Storyboard and structured shot list | Storage and versioning tested; generation not built |
| 6 | Analyse a reference video | Not built |
| 7 | Propose new Master Shot Manifest entries | Proposal, duplicate detection and approval tested; detection from footage not built |
| 8 | AI video production specification | Not built |
| 9 | Motion graphics approval sequence | Gate order tested; production blocked on Motion Director |
| 10 | Resume an interrupted project | Tested |
| 11 | Prevent unauthorised paid generation or publishing | Tested (hook script invoked directly; live firing not yet observed) |
| 12 | Existing skills remain functional | Tested for script execution and skill frontmatter |

## Full output

```
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
