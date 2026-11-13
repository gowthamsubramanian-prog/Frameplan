"""Tests for studio/studio.py and the paid-generation hook.

Run from the repository root:  python3 -m unittest discover -s tests -v
Each test uses its own temporary database (STUDIO_DB); the real one is never touched.
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STUDIO = ROOT / "studio" / "studio.py"
HOOK = ROOT / ".claude" / "hooks" / "paid_gate.py"
SKILLS = ROOT / ".claude" / "skills"


class StudioCase(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.env = {**os.environ, "STUDIO_DB": str(Path(self.tmp.name) / "studio.db")}
        self.ok("init")

    def tearDown(self):
        self.tmp.cleanup()

    def run_cli(self, *args):
        p = subprocess.run([sys.executable, str(STUDIO), *args], capture_output=True, text=True, env=self.env)
        text = p.stdout if p.returncode == 0 else p.stderr
        try:
            data = json.loads(text)
        except json.JSONDecodeError:
            data = {"raw": p.stdout + p.stderr}
        return p.returncode, data

    def ok(self, *args):
        code, data = self.run_cli(*args)
        self.assertEqual(code, 0, f"{args} failed: {data}")
        return data

    def blocked(self, *args):
        code, data = self.run_cli(*args)
        self.assertEqual(code, 3, f"{args} should be blocked (exit 3), got {code}: {data}")
        return data

    def hook(self, tool):
        p = subprocess.run([sys.executable, str(HOOK)], input=json.dumps({"tool_name": tool}),
                           capture_output=True, text=True, env=self.env)
        return p.returncode, p.stderr

    def project(self, workflow, title="Test project"):
        return self.ok("project", "new", "--title", title, "--workflow", workflow)["project"]["id"]

    def approve(self, gate, pid, *extra):
        aid = self.ok("approval", "request", "--gate", gate, "--project", pid,
                      "--summary", f"{gate} for {pid}", *extra)["approval"]["id"]
        self.ok("approval", "decide", aid, "--approve", "--user-quote", "yes, approved")
        return aid

    def advance_to(self, pid, stage):
        for _ in range(20):
            if self.ok("project", "show", pid)["current_stage"] == stage:
                return
            self.ok("project", "advance", pid)
        self.fail(f"never reached {stage}")


class TestFoundation(StudioCase):
    def test_init_is_repeatable_and_creates_all_libraries(self):
        tables = set(self.ok("init")["tables"])
        for t in ("inspirations", "genres", "shot_manifest", "manifest_proposals", "projects",
                  "documents", "shots", "prompts", "generations", "assets", "agent_runs",
                  "approvals", "publications", "metrics"):
            self.assertIn(t, tables)

    def test_ids_are_sequential_and_prefixed(self):
        self.assertEqual(self.project("A"), "PRJ-0001")
        self.assertEqual(self.project("A"), "PRJ-0002")

    def test_snapshot_restores_a_missing_database(self):
        pid = self.project("A", "Snapshot me")
        self.ok("snapshot")
        os.remove(self.env["STUDIO_DB"])
        self.assertEqual(self.ok("project", "show", pid)["project"]["title"], "Snapshot me")
        self.assertEqual(self.project("A"), "PRJ-0002")  # counters survive the round trip


class TestRouting(StudioCase):
    CASES = {
        "A cinematic reel of a red saree at Bondi at sunrise": "A",
        "Make something like this https://www.instagram.com/p/DdlYkrlFHIk/": "B",
        "Use my saved Pinterest pins as inspiration for a beach shoot": "B",
        "Replicate this uploaded video shot by shot: ref.mp4": "C",
        "Create an AI video with Kling from this portrait": "D",
        "Make a motion graphics explainer about golden hour": "E",
    }

    def test_requests_route_to_the_expected_workflow(self):
        for text, wf in self.CASES.items():
            self.assertEqual(self.ok("route", text)["workflow"], wf, text)

    def test_project_new_routes_when_no_workflow_given(self):
        p = self.ok("project", "new", "--title", "Kinetic text explainer on lens choice")["project"]
        self.assertEqual((p["workflow"], p["stage"]), ("E", "topic"))


class TestInputRouting(StudioCase):
    """The owner's actual input decides the route. Regression for the 14 Nov 2026 failure, where
    the coordinator ran a built-in forklift example instead of the uploaded candle portraits."""

    def test_image_with_no_prompt_goes_to_agent00_as_a_reference(self):
        r = self.ok("route", "--attachment", "media/incoming/1000162216.jpg")
        self.assertEqual(r["workflow"], "B")
        self.assertIn("inspiration-intelligence", r["first_specialist"])
        self.assertEqual(r["input_detected"]["images"], ["media/incoming/1000162216.jpg"])
        self.assertEqual(r["pass_to_specialist"], ["media/incoming/1000162216.jpg"])
        self.assertIn("visual creative reference", r["rationale"])

    def test_several_images_and_other_extensions_are_recognised(self):
        r = self.ok("route", "--attachment", "a.PNG", "--attachment", "b.heic", "--attachment", "c.webp")
        self.assertEqual((r["workflow"], len(r["input_detected"]["images"])), ("B", 3))

    def test_no_input_is_an_error_not_a_sample_topic(self):
        code, data = self.run_cli("route")
        self.assertEqual(code, 1)
        self.assertIn("Ask the owner", data["error"])
        self.assertIn("Never substitute a sample", data["error"])

    def test_route_never_proposes_a_domain(self):
        for args in (["--attachment", "x.jpg"], ["a moody candlelit portrait series"], ["make a motion graphic"]):
            r = self.ok("route", *args)
            flat = json.dumps({k: v for k, v in r.items() if k != "rule"}).lower()
            for word in ("forklift", "whs", "hse", "linkedin", "safety"):
                self.assertNotIn(word, flat, (args, word))
            self.assertIn("never assume WHS/HSE or LinkedIn", r["rule"])

    def test_attachment_outranks_a_vague_prompt(self):
        r = self.ok("route", "something like this", "--attachment", "ref.jpg")
        self.assertEqual(r["workflow"], "B")

    def test_explicit_motion_graphics_request_keeps_the_image_as_its_subject(self):
        r = self.ok("route", "make a motion graphics piece from this", "--attachment", "ref.jpg")
        self.assertEqual(r["workflow"], "E")
        self.assertEqual(r["pass_to_specialist"], ["ref.jpg"])
        self.assertIn("owner's actual subject", r["first_specialist"])

    def test_video_reference_versus_own_footage(self):
        r = self.ok("route", "--attachment", "clip.mp4")
        self.assertEqual(r["workflow"], "C"); self.assertIsNotNone(r["needs_clarification"])
        r = self.ok("route", "edit this, it is my footage from Saturday", "--attachment", "clip.mov")
        self.assertEqual(r["workflow"], "A"); self.assertIn("rough-cut", r["rationale"])

    def test_orchestrator_and_project_rules_forbid_sample_topics(self):
        skill = (ROOT / ".claude/skills/studio/SKILL.md").read_text()
        self.assertLess(skill.index("## 0. Input handling"), skill.index("## 1. Start or resume"))
        for needle in ("Never substitute a sample", "No domain defaults", "Carry the attachments through",
                       "A named specialist does not change the subject"):
            self.assertIn(needle, skill)
        self.assertIn("The owner's input is the subject", (ROOT / "CLAUDE.md").read_text())

    def test_motion_director_itself_is_untouched(self):
        import hashlib
        a = (ROOT / ".claude/skills/motion-director/SKILL.md").read_bytes()
        b = (ROOT / "archive/recovery-pack-2026-11-13/01_RESTORED_ORIGINALS/SKILL(1).md").read_bytes()
        self.assertEqual(hashlib.sha256(a).hexdigest(), hashlib.sha256(b).hexdigest())


class TestApprovalGates(StudioCase):
    def test_concept_gate_blocks_until_user_approves(self):
        pid = self.project("A")
        self.advance_to(pid, "concept")
        doc = self.ok("doc", "add", "--project", pid, "--kind", "concept", "--content", "Concept v1")["document"]
        err = self.blocked("project", "advance", pid)
        self.assertEqual(err["gate"], "concept")
        aid = self.ok("approval", "request", "--gate", "concept", "--project", pid,
                      "--summary", "Concept v1", "--subject", doc)["approval"]["id"]
        self.blocked("project", "advance", pid)                      # pending is not approved
        st = self.ok("project", "show", pid)
        self.assertEqual(st["pending_approvals"][0]["id"], aid)
        self.ok("approval", "decide", aid, "--approve", "--user-quote", "Love it, go ahead")
        self.assertEqual(self.ok("project", "advance", pid)["to"], "creative_direction")
        self.assertEqual(self.ok("doc", "show", doc)["status"], "approved")

    def test_rejection_keeps_the_gate_closed(self):
        pid = self.project("A")
        self.advance_to(pid, "concept")
        aid = self.ok("approval", "request", "--gate", "concept", "--project", pid, "--summary", "v1")["approval"]["id"]
        self.ok("approval", "decide", aid, "--reject", "--user-quote", "not this one")
        self.blocked("project", "advance", pid)

    def test_agent_cannot_approve_without_user_words(self):
        pid = self.project("A")
        aid = self.ok("approval", "request", "--gate", "concept", "--project", pid, "--summary", "v1")["approval"]["id"]
        code, _ = self.run_cli("approval", "decide", aid, "--approve", "--user-quote", " ")
        self.assertEqual(code, 1)

    def test_decided_approval_cannot_be_changed(self):
        pid = self.project("A")
        aid = self.approve("concept", pid)
        code, _ = self.run_cli("approval", "decide", aid, "--reject", "--user-quote", "changed my mind")
        self.assertEqual(code, 1)

    def test_stages_cannot_be_skipped_but_rework_is_allowed(self):
        pid = self.project("A")
        code, _ = self.run_cli("project", "advance", pid, "--to", "storyboard")
        self.assertEqual(code, 1)
        self.advance_to(pid, "concept")
        self.assertEqual(self.ok("project", "advance", pid, "--to", "research")["direction"], "rework")

    def test_motion_graphics_sequence_concept_then_style(self):
        pid = self.project("E")
        self.advance_to(pid, "proposal")
        err = self.blocked("approval", "request", "--gate", "style", "--project", pid, "--summary", "Style B")
        self.assertIn("before the concept is approved", err["error"])
        self.blocked("project", "advance", pid)                      # style_options needs concept
        self.approve("concept", pid)
        self.assertEqual(self.ok("project", "advance", pid)["to"], "style_options")
        self.blocked("project", "advance", pid)                      # production needs style
        self.approve("style", pid)
        self.assertEqual(self.ok("project", "advance", pid)["to"], "production")

    def test_export_and_publish_are_gated(self):
        pid = self.project("A")
        self.advance_to(pid, "concept")
        self.approve("concept", pid)
        self.advance_to(pid, "qa")
        self.assertEqual(self.blocked("project", "advance", pid)["gate"], "export")
        self.approve("export", pid)
        self.ok("project", "advance", pid)
        self.assertEqual(self.blocked("project", "advance", pid)["gate"], "publish")
        pub = self.ok("pub", "draft", "--project", pid, "--platform", "instagram", "--caption", "hi")["publication"]
        self.blocked("pub", "set", pub, "--status", "scheduled", "--at", "2026-12-01T09:00:00Z")
        self.blocked("pub", "set", pub, "--status", "published")
        self.approve("publish", pid)
        self.assertEqual(self.ok("pub", "set", pub, "--status", "published",
                                 "--url", "https://example.com/p/1")["publication"]["status"], "published")


class TestPaidGenerationGate(StudioCase):
    PAID = "mcp__kling-ai__image_to_video"

    def test_hook_blocks_paid_tool_without_approval(self):
        code, msg = self.hook(self.PAID)
        self.assertEqual(code, 2)
        self.assertIn("BLOCKED", msg)

    def test_hook_ignores_free_tools(self):
        for tool in ("mcp__kling-ai__who_am_i", "mcp__kling-ai__query_membership_and_credits",
                     "mcp__Idea_AI__quote_cost", "Bash"):
            self.assertEqual(self.hook(tool)[0], 0, tool)

    def test_hook_blocks_every_paid_tool_name(self):
        for tool in ("mcp__kling-ai__text_to_image", "mcp__kling-ai__image_to_image",
                     "mcp__kling-ai__text_to_video", "mcp__kling-ai__motion_control",
                     "mcp__kling-ai__omni_ref_video", "mcp__Idea_AI__create_video",
                     "mcp__Idea_AI__create_image", "mcp__Idea_AI__generate"):
            self.assertEqual(self.hook(tool)[0], 2, tool)

    def test_approval_authorises_exactly_the_approved_number_of_calls(self):
        pid = self.project("D")
        self.approve("paid_generation", pid, "--max-cost", "4", "--uses", "2")
        self.assertEqual(self.hook(self.PAID)[0], 0)
        self.assertEqual(self.hook(self.PAID)[0], 0)
        self.assertEqual(self.hook(self.PAID)[0], 2)
        log = self.ok("gate", "log")
        self.assertEqual([r["decision"] for r in log], ["denied", "allowed", "allowed"])

    def test_pending_or_rejected_approval_does_not_authorise(self):
        pid = self.project("D")
        aid = self.ok("approval", "request", "--gate", "paid_generation", "--project", pid,
                      "--summary", "3 clips", "--max-cost", "3", "--uses", "3")["approval"]["id"]
        self.assertEqual(self.hook(self.PAID)[0], 2)
        self.ok("approval", "decide", aid, "--reject", "--user-quote", "no, too expensive")
        self.assertEqual(self.hook(self.PAID)[0], 2)

    def test_paused_project_authorisation_is_not_used(self):
        pid = self.project("D")
        self.approve("paid_generation", pid, "--max-cost", "4", "--uses", "2")
        self.ok("project", "pause", pid)
        self.assertEqual(self.hook(self.PAID)[0], 2)

    def test_hook_fails_closed_without_a_database(self):
        os.remove(self.env["STUDIO_DB"])
        self.assertEqual(self.hook(self.PAID)[0], 2)

    def test_budget_cap_blocks_overspend_requests(self):
        pid = self.project("D")
        self.approve("paid_generation", pid, "--max-cost", "7", "--uses", "3")
        err = self.blocked("approval", "request", "--gate", "paid_generation", "--project", pid,
                           "--summary", "more", "--max-cost", "5", "--uses", "2")
        self.assertIn("project budget", err["error"])
        a = self.ok("approval", "request", "--gate", "paid_generation", "--project", pid,
                    "--summary", "more", "--max-cost", "5", "--uses", "2", "--over-budget")["approval"]
        self.assertEqual((a["status"], a["over_budget"]), ("pending", 1))

    def test_generation_stage_needs_paid_approval(self):
        pid = self.project("D")
        self.approve("concept", pid)
        self.advance_to(pid, "prompt_engineering")
        self.assertEqual(self.blocked("project", "advance", pid)["gate"], "paid_generation")

    def test_actual_costs_are_tracked(self):
        pid = self.project("D")
        aid = self.approve("paid_generation", pid, "--max-cost", "6", "--uses", "3")
        b = self.ok("gen", "record", "--project", pid, "--provider", "kling", "--status", "succeeded",
                    "--approval", aid, "--cost", "1.25")["budget"]
        self.assertEqual((b["authorised_usd"], b["actual_usd"], b["remaining_usd"]), (6.0, 1.25, 4.0))


class TestInspirationLibrary(StudioCase):
    def test_instagram_link_variants_are_one_reference(self):
        a = self.ok("ins", "add", "--source", "instagram", "--title", "Beach high fashion",
                    "--url", "https://www.instagram.com/thebianca.m/p/DcuzAuICCUV/?img_index=4")
        self.assertTrue(a["created"])
        b = self.ok("ins", "add", "--source", "instagram", "--title", "Same post, other link",
                    "--url", "https://instagram.com/p/DcuzAuICCUV")
        self.assertEqual((b["created"], b["duplicate_of"]), (False, a["id"]))
        links = self.ok("ins", "show", a["id"])["links"]
        self.assertEqual(links, ["https://www.instagram.com/thebianca.m/p/DcuzAuICCUV/?img_index=4"])  # original kept

    def test_ideas_without_links_dedupe_on_title(self):
        a = self.ok("ins", "add", "--source", "idea", "--title", "Whispers of Heritage")
        b = self.ok("ins", "add", "--source", "idea", "--title", "whispers of  heritage!")
        self.assertEqual(b["duplicate_of"], a["id"])

    def test_inaccessible_reference_cannot_receive_analysis(self):
        i = self.ok("ins", "add", "--source", "instagram", "--title", "Private reel",
                    "--url", "https://www.instagram.com/reel/ABC123/")["id"]
        analysis = json.dumps({"lighting": "soft side light"})
        self.blocked("ins", "analysis", i, "--json", analysis, "--basis", "guess")       # unreviewed
        self.ok("ins", "access", i, "--status", "blocked", "--detail", "login wall")
        err = self.blocked("ins", "analysis", i, "--json", analysis, "--basis", "guess")
        self.assertIn("actually inspected", err["error"])
        shown = self.ok("ins", "show", i)
        self.assertEqual((shown["analysis_status"], shown["analysis_json"]), ("none", None))
        self.assertEqual(shown["links"], ["https://www.instagram.com/reel/ABC123/"])     # link preserved

    def test_accessible_reference_stores_analysis_with_basis(self):
        i = self.ok("ins", "add", "--source", "upload", "--title", "Ref photo", "--creator", "@someone")["id"]
        self.ok("ins", "access", i, "--status", "reviewed_images", "--detail", "uploaded JPEG")
        self.ok("ins", "analysis", i, "--json", json.dumps({"framing": "tight portrait"}),
                "--basis", "uploads/ref.jpg viewed directly")
        s = self.ok("ins", "show", i)
        self.assertEqual((s["analysis_status"], s["creator"]), ("complete", "@someone"))
        self.assertEqual(len(self.ok("ins", "list", "--search", "tight portrait")), 1)

    def test_genres_grow_from_references_without_duplicates(self):
        i = self.ok("ins", "add", "--source", "idea", "--title", "Gothic heritage portraits")["id"]
        g1 = self.ok("genre", "add", "--name", "Gothic Editorial", "--inspiration", i)
        g2 = self.ok("genre", "add", "--name", "gothic editorial")
        self.assertEqual((g1["created"], g2["created"]), (True, False))
        self.assertEqual(g1["genre"]["status"], "proposed")
        self.assertEqual(self.ok("genre", "list")[0]["inspirations"], 1)


class TestShotManifest(StudioCase):
    SPEC = json.dumps({"movement": "slow push-in", "lens": "85mm"})

    def test_proposal_does_not_touch_manifest_until_approved(self):
        p = self.ok("manifest", "propose", "--name", "Veil Reveal Push-In", "--spec", self.SPEC, "--source", "AST-0001")
        self.assertEqual(self.ok("manifest", "list"), [])
        d = self.ok("manifest", "decide", p["proposal"], "--approve", "--user-quote", "add it")
        self.assertEqual(d["manifest_id"], "SHT-0001")
        self.assertEqual(len(self.ok("manifest", "list")), 1)

    def test_duplicates_and_near_matches_are_caught(self):
        p = self.ok("manifest", "propose", "--name", "Veil Reveal Push-In", "--spec", self.SPEC)
        again = self.ok("manifest", "propose", "--name", "veil reveal push in", "--spec", self.SPEC)
        self.assertEqual((again["created"], again["duplicate_of"]), (False, p["proposal"]))
        self.ok("manifest", "decide", p["proposal"], "--approve", "--user-quote", "yes")
        exact = self.ok("manifest", "propose", "--name", "Veil reveal push-in", "--spec", self.SPEC)
        self.assertEqual(exact["duplicate_of"], "SHT-0001")
        near = self.ok("manifest", "propose", "--name", "Veil Reveal Push In Slow", "--spec", self.SPEC)
        self.assertEqual((near["created"], near["similar_to"]), (True, "SHT-0001"))

    def test_rejected_proposal_is_recorded_not_added(self):
        p = self.ok("manifest", "propose", "--name", "Whip Pan Match Cut", "--spec", self.SPEC)["proposal"]
        self.ok("manifest", "decide", p, "--reject", "--user-quote", "not needed")
        self.assertEqual(self.ok("manifest", "list"), [])
        self.assertEqual(self.ok("manifest", "list", "--proposals")[0]["status"], "rejected")


class TestDocumentsAndResume(StudioCase):
    def test_documents_are_versioned_and_approved_ones_superseded_not_edited(self):
        pid = self.project("A")
        d1 = self.ok("doc", "add", "--project", pid, "--kind", "concept", "--content", "v1")
        a1 = self.ok("approval", "request", "--gate", "concept", "--project", pid, "--summary", "v1",
                     "--subject", d1["document"])["approval"]["id"]
        self.ok("approval", "decide", a1, "--approve", "--user-quote", "ok")
        d2 = self.ok("doc", "add", "--project", pid, "--kind", "concept", "--content", "v2")
        self.assertEqual((d1["version"], d2["version"]), (1, 2))
        self.assertEqual(self.ok("doc", "show", d1["document"])["content"], "v1")
        self.assertEqual(self.ok("doc", "show", d1["document"])["status"], "approved")   # v2 is only a draft
        a2 = self.ok("approval", "request", "--gate", "concept", "--project", pid, "--summary", "v2",
                     "--subject", d2["document"])["approval"]["id"]
        self.ok("approval", "decide", a2, "--approve", "--user-quote", "v2 is better")
        self.assertEqual(self.ok("doc", "show", d1["document"])["status"], "superseded")

    def test_choosing_one_of_three_concepts_approves_it_and_keeps_the_others_as_rejected(self):
        pid = self.project("B")
        docs = [self.ok("doc", "add", "--project", pid, "--kind", "concept", "--variant", v, "--content", v)["document"]
                for v in "ABC"]
        aid = self.ok("approval", "request", "--gate", "concept", "--project", pid, "--summary", "pick one",
                      "--subject", ",".join(docs))["approval"]["id"]
        code, _ = self.run_cli("approval", "decide", aid, "--approve", "--user-quote", "B", "--chosen", "DOC-9999")
        self.assertEqual(code, 1)
        self.ok("approval", "decide", aid, "--approve", "--user-quote", "I choose B", "--chosen", docs[1])
        self.assertEqual([self.ok("doc", "show", d)["status"] for d in docs], ["rejected", "approved", "rejected"])
        self.assertEqual(self.ok("doc", "show", docs[0])["content"], "A")       # unchosen concepts are kept

    def test_multiple_creative_variants_coexist(self):
        pid = self.project("A")
        a = self.ok("doc", "add", "--project", pid, "--kind", "concept", "--variant", "A", "--content", "moody")
        b = self.ok("doc", "add", "--project", pid, "--kind", "concept", "--variant", "B", "--content", "bright")
        self.assertEqual((a["version"], b["version"]), (1, 1))

    def test_shot_list_is_stored_as_structured_shots(self):
        pid = self.project("A")
        content = json.dumps({"shots": [
            {"description": "Wide establishing, subject enters frame left", "lens": "35mm", "duration_s": 3},
            {"description": "Tight profile, veil lifts", "lens": "85mm", "fps": 50}]})
        d = self.ok("doc", "add", "--project", pid, "--kind", "shot_list", "--content", content)
        self.assertEqual(d["shots"], 2)
        shots = self.ok("doc", "show", d["document"])["shots"]
        self.assertEqual([s["seq"] for s in shots], [1, 2])
        self.assertEqual(json.loads(shots[1]["spec_json"])["lens"], "85mm")
        code, _ = self.run_cli("doc", "add", "--project", pid, "--kind", "shot_list", "--content", "not json")
        self.assertEqual(code, 1)

    def test_interrupted_project_resumes_from_the_database(self):
        pid = self.project("B", "Chaitra-inspired portrait")
        self.advance_to(pid, "adaptation")
        self.ok("doc", "add", "--project", pid, "--kind", "concept", "--content", "adapted concept")
        run = self.ok("run", "start", "--agent", "creative-director", "--project", pid, "--stage", "adaptation")["run"]
        self.ok("run", "finish", run, "--error", "session ended mid-task")
        self.ok("project", "pause", pid, "--note", "interrupted")
        code, _ = self.run_cli("project", "advance", pid)
        self.assertEqual(code, 1)                                    # paused projects do not move
        st = self.ok("project", "resume", pid)                       # a fresh process, no chat memory
        self.assertEqual(st["current_stage"], "adaptation")
        self.assertEqual(st["next_stage"], "storyboard")
        self.assertEqual(st["next_stage_blocked_by"]["gate"], "concept")
        self.assertEqual(st["last_runs"][0]["status"], "failed")
        self.assertEqual(len(st["documents"]), 1)

    def test_assets_dedupe_by_content(self):
        f1 = Path(self.tmp.name) / "a.bin"; f1.write_bytes(b"same bytes")
        f2 = Path(self.tmp.name) / "b.bin"; f2.write_bytes(b"same bytes")
        a = self.ok("asset", "add", "--path", str(f1), "--kind", "footage")
        b = self.ok("asset", "add", "--path", str(f2), "--kind", "footage")
        self.assertEqual((a["created"], b["created"], b["duplicate_of"]), (True, False, a["asset"]))


class TestExistingSkillsStillWork(unittest.TestCase):
    """The merged ig-* scripts and the copied skills must keep working."""

    def run_script(self, rel, *args, stdin=None):
        return subprocess.run([sys.executable, str(SKILLS / rel), *args], input=stdin,
                              capture_output=True, text=True)

    def test_ig_scripts_run(self):
        p = self.run_script("ig-reel/hookscore.py", "--hook", "I lit this entire reel with one $89 light")
        self.assertIn(p.returncode, (0, 1), p.stderr)        # 1 is its "score under 70" verdict
        self.assertIn("HOOK SCORE", p.stdout)
        with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as f:
            f.write("I lit this entire reel with one $89 light.\nHere is the setup.\nOne softbox, camera left.\n")
        try:
            p = self.run_script("ig-reel/beats.py", f.name, "--target", "15")
            self.assertEqual(p.returncode, 0, p.stderr); self.assertIn("BEAT SHEET", p.stdout)
            p = self.run_script("ig-caption/caption.py", f.name)
            self.assertIn(p.returncode, (0, 1), p.stderr); self.assertTrue(p.stdout.strip())
            p = self.run_script("ig-human/detect.py", f.name)
            self.assertIn(p.returncode, (0, 1), p.stderr); self.assertTrue(p.stdout.strip())
        finally:
            os.unlink(f.name)
        for rel in ("ig-human/humanize.py", "ig-viral/swipe.py"):
            self.assertEqual(self.run_script(rel, "--help").returncode, 0, rel)

    def test_every_skill_has_valid_frontmatter(self):
        expected = {"rough-cut", "colour-grading", "effects-and-transitions", "reel-assembly",
                    "cinematic-reel-editing", "ultra-realistic-portrait", "navratri-photoshoot", "studio"}
        found = set()
        for d in sorted(SKILLS.iterdir()):
            text = (d / "SKILL.md").read_text()
            self.assertTrue(text.startswith("---\n"), d.name)
            head = text.split("---\n")[1]
            self.assertIn("name:", head, d.name); self.assertIn("description:", head, d.name)
            found.add(d.name)
        self.assertTrue(expected <= found, expected - found)
        self.assertEqual(len([n for n in found if n.startswith("ig-")]), 13)

    def test_ig_skills_no_longer_point_at_the_home_directory(self):
        for f in SKILLS.rglob("*"):
            if f.is_file() and f.suffix in (".md", ".py"):
                self.assertNotIn("~/.claude/instagram", f.read_text(), str(f))


if __name__ == "__main__":
    unittest.main()
