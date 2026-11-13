"""Global routing coverage: every entry point, the two enforcement hooks, and the ban on
built-in topics in production files. Sample subjects used here are test fixtures only.

Run from the repository root:  python3 -m unittest discover -s tests -v
"""
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STUDIO = ROOT / "studio" / "studio.py"
HOOKS = ROOT / ".claude" / "hooks"


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.env = {**os.environ, "STUDIO_DB": str(Path(self.tmp.name) / "studio.db")}
        self.ok("init")

    def tearDown(self):
        self.tmp.cleanup()

    def cli(self, *args):
        p = subprocess.run([sys.executable, str(STUDIO), *args], capture_output=True, text=True, env=self.env)
        text = p.stdout if p.returncode == 0 else p.stderr
        try:
            return p.returncode, json.loads(text)
        except json.JSONDecodeError:
            return p.returncode, {"raw": p.stdout + p.stderr}

    def ok(self, *args):
        code, data = self.cli(*args)
        self.assertEqual(code, 0, f"{args}: {data}")
        return data

    def candle_project(self):
        return self.ok("project", "new", "--title", "Candle portrait shoot", "--workflow", "B")["project"]["id"]

    def hook(self, name, payload):
        p = subprocess.run([sys.executable, str(HOOKS / name)], input=json.dumps(payload),
                           capture_output=True, text=True, env=self.env)
        return p.returncode, p.stdout, p.stderr


class TestEntryPoints(Base):
    # ---- E1 direct request, words only
    def test_direct_request_in_words_uses_the_owners_subject(self):
        r = self.ok("route", "a moody portrait series lit only by candles")
        self.assertEqual((r["action"], r["workflow"]), ("new_work", "A"))
        self.assertEqual(r["input_detected"]["text"], "a moody portrait series lit only by candles")

    # ---- E2/E3 uploads
    def test_uploaded_image_without_words(self):
        r = self.ok("route", "--attachment", "media/incoming/ref.jpg")
        self.assertEqual((r["action"], r["workflow"]), ("new_work", "B"))
        self.assertIn("inspiration-intelligence", r["first_specialist"])
        self.assertEqual(r["pass_to_specialist"], ["media/incoming/ref.jpg"])

    def test_uploaded_video_without_words_asks_what_it_is(self):
        r = self.ok("route", "--attachment", "clip.mp4")
        self.assertEqual(r["workflow"], "C")
        self.assertIn("ambiguous_video", r["flags"]); self.assertTrue(r["needs_clarification"])

    def test_uploaded_own_footage_enters_at_the_edit(self):
        r = self.ok("route", "edit this, I shot it on Saturday", "--attachment", "take1.mov")
        self.assertEqual(r["workflow"], "A"); self.assertIn("rough-cut", r["rationale"])

    # ---- E4 link
    def test_link_is_a_reference(self):
        r = self.ok("route", "https://www.instagram.com/p/DdlYkrlFHIk/")
        self.assertEqual(r["workflow"], "B")

    # ---- E5 continue / E6 resume
    def test_continue_stays_on_the_current_project(self):
        pid = self.candle_project()
        for words in ("continue", "Proceed", "go ahead", "carry on please", "next"):
            r = self.ok("route", words)
            self.assertEqual((r["action"], r["current_project"]["id"]), ("continue_project", pid), words)
            self.assertEqual(r["pass_to_specialist"], [pid])

    def test_continue_with_no_project_asks(self):
        r = self.ok("route", "continue")
        self.assertEqual(r["action"], "clarify"); self.assertIn("missing_subject", r["flags"])
        self.assertIn("Do not pick a subject", r["needs_clarification"])

    def test_resumed_project_becomes_current_and_cancelled_one_does_not_linger(self):
        a = self.candle_project()
        b = self.ok("project", "new", "--title", "Second", "--workflow", "A")["project"]["id"]
        self.assertEqual(self.ok("route", "continue")["current_project"]["id"], b)
        self.ok("project", "cancel", b)
        self.assertEqual(self.ok("route", "continue")["action"], "clarify")       # never falls back silently
        self.ok("project", "use", a)
        self.assertEqual(self.ok("route", "continue")["current_project"]["id"], a)
        self.ok("project", "pause", a); self.ok("project", "resume", a)
        self.assertTrue(self.ok("project", "show", a)["is_current_project"])

    def test_new_input_while_a_project_is_current_keeps_it_in_view(self):
        pid = self.candle_project()
        r = self.ok("route", "--attachment", "another.jpg")
        self.assertEqual(r["current_project"]["id"], pid)
        self.assertIn("current_project_exists", r["flags"])
        self.assertIn("Never drop the current project silently", r["project_note"])
        r = self.ok("route", "new project: a rain-soaked street portrait")
        self.assertNotIn("current_project_exists", r["flags"])

    # ---- E7 named specialist
    def test_the_14_november_failure_is_now_caught(self):
        """'proceed with Motion Director testing' while the candle project is current."""
        pid = self.candle_project()
        r = self.ok("route", "proceed with Motion Director testing")
        self.assertEqual((r["action"], r["named_specialist"]), ("clarify", "motion-director"))
        self.assertIn("incompatible_specialist", r["flags"])
        self.assertIn(pid, r["needs_clarification"]); self.assertIn("Do not pick a subject", r["needs_clarification"])
        self.assertIsNone(r["workflow"])

    def test_named_specialist_with_no_subject_and_no_project_asks(self):
        for words in ("test motion director", "run the storyboard skill", "use Agent 00", "try the QA reviewer"):
            r = self.ok("route", words)
            self.assertEqual(r["action"], "clarify", words)
            self.assertIn("missing_subject", r["flags"], words)

    def test_named_specialist_that_fits_the_current_project_continues_it(self):
        pid = self.candle_project()
        r = self.ok("route", "run Agent 00 again")
        self.assertEqual((r["action"], r["first_specialist"], r["pass_to_specialist"]),
                         ("continue_project", "inspiration-intelligence", [pid]))

    def test_named_specialist_with_the_owners_own_subject_is_allowed(self):
        r = self.ok("route", "use Motion Director for a title sequence about candle rituals")
        self.assertEqual((r["action"], r["workflow"], r["first_specialist"]), ("new_work", "E", "motion-director"))
        self.assertIn("candle rituals", r["input_detected"]["text"])

    def test_named_specialist_that_does_not_fit_the_attachment_is_flagged(self):
        r = self.ok("route", "storyboard this", "--attachment", "photo.jpg")
        self.assertEqual(r["action"], "clarify"); self.assertIn("incompatible_specialist", r["flags"])
        self.assertIn("Do not change the subject to suit the specialist", r["needs_clarification"])
        r = self.ok("route", "storyboard this", "--attachment", "reel.mp4")
        self.assertEqual((r["action"], r["first_specialist"]), ("new_work", "cinematic-reel-storyboard"))

    # ---- E8 nothing at all
    def test_empty_input_is_refused(self):
        code, data = self.cli("route")
        self.assertEqual(code, 1); self.assertIn("Never substitute a sample", data["error"])

    def test_no_route_ever_names_a_subject_domain_or_platform(self):
        self.candle_project()
        for args in (["continue"], ["proceed with Motion Director testing"], ["--attachment", "x.jpg"],
                     ["make a motion graphic"], ["test the generation director"]):
            r = self.ok("route", *args)
            r.pop("rule", None); r.pop("input_detected", None); r.pop("current_project", None)
            flat = re.sub(r'PRJ-\d+ \\"[^"]*\\"', "", json.dumps(r).lower())
            for word in ("forklift", "whs", "hse", "linkedin", "safety", "instagram", "fashion"):
                self.assertNotIn(word, flat, (args, word))


class TestContextHook(Base):
    def test_every_message_gets_the_current_project_and_rules(self):
        pid = self.candle_project()
        code, out, _ = self.hook("context_hook.py", {"prompt": "what next?"})
        self.assertEqual(code, 0)
        self.assertIn(f"Current project: {pid}", out); self.assertIn("Never substitute a sample", out)
        self.assertIn("not a message from the owner", out)

    def test_hook_raises_the_stop_for_the_failure_case(self):
        self.candle_project()
        _, out, _ = self.hook("context_hook.py", {"prompt": "proceed with Motion Director testing"})
        self.assertIn("STOP AND ASK", out); self.assertIn("incompatible_specialist", out)

    def test_hook_shows_pending_approvals(self):
        pid = self.candle_project()
        self.ok("approval", "request", "--gate", "concept", "--project", pid, "--summary", "pick")
        _, out, _ = self.hook("context_hook.py", {"prompt": "A"})
        self.assertIn("Waiting on the owner: APR-0001 (concept)", out)

    def test_hook_never_blocks_even_when_broken(self):
        os.remove(self.env["STUDIO_DB"])
        code, out, _ = self.hook("context_hook.py", {"prompt": "hello"})
        self.assertEqual(code, 0); self.assertIn("Never substitute a sample", out)
        p = subprocess.run([sys.executable, str(HOOKS / "context_hook.py")], input="not json",
                           capture_output=True, text=True, env=self.env)
        self.assertEqual(p.returncode, 0)


class TestBriefGate(Base):
    def agent(self, kind, prompt):
        return self.hook("brief_gate.py", {"tool_name": "Agent", "tool_input": {"subagent_type": kind, "prompt": prompt}})[0]

    def test_studio_specialists_cannot_start_without_the_owners_input(self):
        for kind in ("inspiration-intelligence", "generation-director", "qa-reviewer"):
            self.assertEqual(self.agent(kind, "Please analyse something interesting and report back."), 2, kind)

    def test_brief_with_project_reference_file_or_link_is_allowed(self):
        for brief in ("Project PRJ-0001: write the spec.", "Review REF-000002.", "Check AST-0004 against DOC-0003.",
                      "Analyse media/incoming/1000162216.jpg", "Catalogue https://www.pinterest.com/pin/1/",
                      "Probe /home/user/Frameplan/media/incoming/clip.MOV"):
            self.assertEqual(self.agent("inspiration-intelligence", brief), 0, brief)

    def test_other_agents_and_tools_are_not_affected(self):
        self.assertEqual(self.agent("general-purpose", "anything"), 0)
        self.assertEqual(self.agent("Explore", "find the tests"), 0)
        self.assertEqual(self.hook("brief_gate.py", {"tool_name": "Bash", "tool_input": {"command": "ls"}})[0], 0)

    def test_subject_driven_skills_need_the_owners_subject(self):
        skill = lambda name, args: self.hook("brief_gate.py", {"tool_name": "Skill", "tool_input": {"skill": name, "args": args}})
        code, _, err = skill("motion-director", "")
        self.assertEqual(code, 2); self.assertIn("Never use an example", err)
        self.assertEqual(skill("motion-director", "  ")[0], 2)
        self.assertEqual(skill("cinematic-reel-storyboard", "")[0], 2)
        self.assertEqual(skill("motion-director", "Candle rituals title sequence platform=instagram")[0], 0)
        self.assertEqual(skill("studio", "")[0], 0)
        self.assertEqual(skill("rough-cut", "")[0], 0)

    def test_hooks_are_registered(self):
        cfg = json.loads((ROOT / ".claude" / "settings.json").read_text())["hooks"]
        self.assertIn("context_hook.py", json.dumps(cfg["UserPromptSubmit"]))
        gates = {h["matcher"]: json.dumps(h) for h in cfg["PreToolUse"]}
        self.assertIn("brief_gate.py", gates["Agent|Task|Skill"])
        self.assertTrue(any("paid_gate.py" in v for v in gates.values()))


class TestNoBuiltInTopics(unittest.TestCase):
    """Production files must not carry a subject, audience or platform that could be picked up as live input."""

    BANNED = ["forklift", "pedestrian segregation", r"\bwhs\b", r"\bhse\b", "linkedin", "safe work australia",
              "portal silhouette", "portal reference", "saved reels", "pinterest ideas"]

    def production_files(self):
        skills = ROOT / ".claude" / "skills"
        files = [ROOT / "CLAUDE.md", *(ROOT / ".claude" / "agents").glob("*.md"),
                 *(ROOT / ".claude" / "hooks").glob("*.py"), *(ROOT / "studio").rglob("*.py"),
                 *(ROOT / "studio").rglob("*.json"), *(ROOT / "tools").glob("*.py"), *(ROOT / "references").glob("*")]
        for d in sorted(skills.iterdir()):
            if d.name.startswith("ig-"):
                continue      # Instagram tools by purpose; only run when the owner asks for Instagram content
            files += [f for f in d.rglob("*") if f.is_file() and f.suffix in (".md", ".py", ".json")]
        return files

    def test_no_sample_subject_or_default_domain_in_production_files(self):
        hits = []
        for f in self.production_files():
            text = f.read_text(errors="ignore").lower()
            hits += [(str(f.relative_to(ROOT)), b) for b in self.BANNED if re.search(b, text)]
        self.assertEqual(hits, [])

    def test_motion_director_has_no_default_subject_audience_or_platform(self):
        text = (ROOT / ".claude/skills/motion-director/SKILL.md").read_text()
        self.assertIn("There is no default subject", text)
        self.assertIn("There is no default audience or domain", text)
        self.assertIn("There is no default platform", text)
        self.assertIn("If it is empty, ask the user for a title and stop", text)
        self.assertNotIn("e.g. `/motion-director", text)

    def test_sample_data_lives_only_in_test_fixtures(self):
        self.assertTrue((ROOT / "tests" / "fixtures" / "agent00-import-sample.csv").is_file())
        self.assertFalse((ROOT / "references" / "import-example.csv").exists())
        schema = (ROOT / "references" / "analysis-schema.json").read_text()
        self.assertIn("never copy a placeholder or an example", schema)

    def test_worked_examples_that_remain_are_marked_as_illustration(self):
        text = (ROOT / ".claude/skills/ultra-realistic-portrait/SKILL.md").read_text()
        self.assertIn("illustration of the method only; never use it as a live subject", text)


if __name__ == "__main__":
    unittest.main()
