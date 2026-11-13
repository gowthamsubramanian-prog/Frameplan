"""Tests for the reference-video breakdown, agent contracts, Kling dry-run adapter and agent files.

Run from the repository root:  python3 -m unittest discover -s tests -v
The video tests build a small synthetic clip with ffmpeg; they are skipped if ffmpeg is missing.
"""
import copy
import csv
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "studio"))
sys.path.insert(0, str(ROOT / "studio" / "adapters"))

import contracts  # noqa: E402
import kling  # noqa: E402
import video_probe  # noqa: E402

TEMPLATE_CSV = ROOT / "archive" / "recovery-pack-2026-11-13" / "01_RESTORED_ORIGINALS" / "SHOT_MANIFEST_TEMPLATE.csv"


def make_clip(path: Path) -> None:
    """Vertical 540x960, 25 fps, 5 s, with hard cuts at 2.0 s and 3.5 s, plus audio."""
    subprocess.run([
        "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
        "-f", "lavfi", "-i", "testsrc=s=540x960:r=25:d=2",
        "-f", "lavfi", "-i", "mandelbrot=s=540x960:r=25",
        "-f", "lavfi", "-i", "color=c=red:s=540x960:r=25:d=1.5",
        "-f", "lavfi", "-i", "sine=f=440:d=5",
        "-filter_complex", "[1:v]trim=duration=1.5,setpts=PTS-STARTPTS[b];[0:v][b][2:v]concat=n=3:v=1:a=0[v]",
        "-map", "[v]", "-map", "3:a", "-t", "5", "-pix_fmt", "yuv420p", str(path)], check=True)


@unittest.skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe"), "ffmpeg not installed")
class TestVideoProbe(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.dir = Path(cls.tmp.name)
        cls.clip = cls.dir / "sample ref.mp4"
        make_clip(cls.clip)
        cls.out = cls.dir / "out"
        cls.result = video_probe.probe(cls.clip, cls.out)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_metadata_is_read_from_the_file(self):
        s = self.result["source"]
        self.assertEqual((s["width"], s["height"], s["aspect_ratio"], s["orientation"]), (540, 960, "9:16", "vertical"))
        self.assertAlmostEqual(s["duration_s"], 5.0, delta=0.1)
        self.assertAlmostEqual(s["fps"], 25.0, delta=0.01)
        self.assertTrue(s["has_audio"])

    def test_hard_cuts_are_found_within_a_frame_or_two(self):
        shots = self.result["shots"]
        self.assertEqual(len(shots), 3)
        self.assertAlmostEqual(shots[0]["end_s"], 2.0, delta=0.09)
        self.assertAlmostEqual(shots[1]["end_s"], 3.5, delta=0.09)
        self.assertAlmostEqual(shots[2]["end_s"], 5.0, delta=0.1)

    def test_every_shot_has_real_start_middle_and_end_frames(self):
        for s in self.result["shots"]:
            for key in ("actual_frame", "start_frame", "end_frame"):
                f = self.out / s[key]
                self.assertTrue(f.is_file() and f.stat().st_size > 500, f)
        self.assertEqual(self.result["files"]["frames_extracted"], 9)
        self.assertTrue((self.out / self.result["files"]["contact_sheet"]).is_file())

    def test_shot_list_uses_the_owners_manifest_columns_and_invents_nothing(self):
        with (self.out / self.result["files"]["shot_list_csv"]).open() as f:
            rows = list(csv.DictReader(f))
            f.seek(0)
            header = f.readline().strip()
        self.assertEqual(header, TEMPLATE_CSV.read_text().strip())
        self.assertEqual([r["shot_id"] for r in rows], ["S01", "S02", "S03"])
        for r in rows:
            self.assertTrue(r["start_time"] and r["end_time"] and r["actual_frame"])
            for unmeasured in ("shot_size", "body_crop", "camera_angle", "camera_height", "composition",
                               "model_movement", "camera_movement", "focal_length", "recording_settings",
                               "sketch", "confidence"):
                self.assertEqual(r[unmeasured], "", f"{unmeasured} must be left for a reviewer")

    def test_refuses_to_write_into_a_non_empty_folder(self):
        with self.assertRaises(video_probe.ProbeError):
            video_probe.probe(self.clip, self.out)

    def test_source_video_is_untouched(self):
        before = self.clip.stat().st_size, self.clip.stat().st_mtime_ns
        video_probe.probe(self.clip, self.dir / "out2", edges=False)
        self.assertEqual(before, (self.clip.stat().st_size, self.clip.stat().st_mtime_ns))

    def test_missing_or_unreadable_file_fails_cleanly(self):
        with self.assertRaises(video_probe.ProbeError):
            video_probe.probe(self.dir / "nope.mp4", self.dir / "o3")
        bad = self.dir / "bad.mp4"
        bad.write_text("not a video")
        with self.assertRaises(video_probe.ProbeError):
            video_probe.probe(bad, self.dir / "o4")
        p = subprocess.run([sys.executable, str(ROOT / "studio" / "video_probe.py"), str(bad), "--out", str(self.dir / "o5")],
                           capture_output=True, text=True)
        self.assertEqual(p.returncode, 1)
        self.assertFalse(json.loads(p.stderr)["ok"])


class TestContracts(unittest.TestCase):
    def spec(self):
        return copy.deepcopy(contracts.TEMPLATES["generation_spec"])

    def report(self):
        r = copy.deepcopy(contracts.TEMPLATES["qa_report"])
        r["checks"][0]["result"] = "pass"
        r["verdict"] = "accept"
        return r

    def test_templates_are_valid(self):
        self.assertEqual(contracts.validate("generation_spec", self.spec()), [])
        self.assertEqual(contracts.validate("qa_report", self.report()), [])

    def test_spec_needs_acceptance_criteria_and_identity_invariants(self):
        s = self.spec(); s["shots"][0]["acceptance"] = []
        self.assertTrue(any("acceptance" in e for e in contracts.validate("generation_spec", s)))
        s = self.spec(); s["identity"]["invariants"] = []
        self.assertTrue(any("invariants" in e for e in contracts.validate("generation_spec", s)))

    def test_spec_cannot_carry_an_unsourced_cost_or_extra_paid_calls(self):
        s = self.spec(); s["cost"]["estimate_usd"] = 3.5
        self.assertTrue(any("never invent" in e for e in contracts.validate("generation_spec", s)))
        s["cost"]["source"] = "user: 35 credits per clip, 1 credit = $0.05"
        self.assertEqual(contracts.validate("generation_spec", s), [])
        s = self.spec(); s["cost"]["calls_requested"] = 5
        self.assertTrue(any("exceeds" in e for e in contracts.validate("generation_spec", s)))

    def test_qa_cannot_accept_without_inspection(self):
        r = self.report(); r["inspected"] = []
        errors = contracts.validate("qa_report", r)
        self.assertTrue(any("nothing was inspected" in e for e in errors))
        self.assertTrue(any("cannot accept without" in e for e in errors))

    def test_qa_cannot_accept_with_failed_or_unchecked_items(self):
        for result in ("fail", "not_checked"):
            r = self.report(); r["checks"][0]["result"] = result
            self.assertTrue(any("cannot accept while" in e for e in contracts.validate("qa_report", r)), result)

    def test_qa_pass_or_fail_needs_evidence_and_retry_needs_fixes(self):
        r = self.report(); r["checks"][0]["evidence"] = " "
        self.assertTrue(any("evidence" in e for e in contracts.validate("qa_report", r)))
        r = self.report(); r["checks"][0]["result"] = "fail"; r["verdict"] = "regenerate"; r["fixes"] = []
        self.assertTrue(any("fixes" in e for e in contracts.validate("qa_report", r)))


class TestKlingDryRun(unittest.TestCase):
    def spec(self, **shot):
        s = copy.deepcopy(contracts.TEMPLATES["generation_spec"])
        s["shots"][0].update(shot)
        return s

    def test_valid_spec_becomes_a_planned_call_and_nothing_is_submitted(self):
        r = kling.plan(self.spec())
        self.assertTrue(r["ok"], r["errors"])
        self.assertEqual((r["dry_run"], r["submitted"]), (True, False))
        call = r["calls"][0]
        self.assertEqual(call["mcp_tool"], "mcp__kling-ai__image_to_video")
        self.assertEqual(call["arguments"]["duration"], "5")
        self.assertEqual(r["paid_calls_if_all_attempts_used"], 2)

    def test_no_price_is_ever_invented(self):
        self.assertIsNone(kling.plan(self.spec())["cost"]["estimate_usd"])

    def test_settings_the_account_does_not_have_are_rejected(self):
        cases = {
            "1080p": dict(resolution="1080p"),
            "does not support 20s": dict(duration_s=20),
            "not available": dict(model="kling-video-v9"),
            "takes its aspect ratio": dict(aspect_ratio="9:16"),
            "no input 'tail_image'": dict(inputs={"first_image": "AST-1", "tail_image": "AST-2"}),
            "requires input 'first_image'": dict(inputs={}),
        }
        for needle, change in cases.items():
            r = kling.plan(self.spec(**change))
            self.assertFalse(r["ok"], needle)
            self.assertEqual(r["calls"], [])
            self.assertTrue(any(needle in e for e in r["errors"]), (needle, r["errors"]))

    def test_keyframe_model_accepts_first_and_last_frame_and_vertical(self):
        r = kling.plan(self.spec(model="kling-video-v4_0", duration_s=12, aspect_ratio="9:16",
                                 inputs={"first_image": "AST-1", "tail_image": "AST-2"}))
        self.assertTrue(r["ok"], r["errors"])

    def test_unverified_tools_are_refused_rather_than_guessed(self):
        r = kling.plan(self.spec(tool="text_to_video"))
        self.assertFalse(r["ok"])
        self.assertTrue(any("who_am_i" in e for e in r["errors"]))

    def test_adapter_source_contains_no_network_or_process_calls(self):
        src = (ROOT / "studio" / "adapters" / "kling.py").read_text()
        for banned in ("urllib", "requests", "http.client", "socket", "subprocess", "os.system"):
            self.assertNotIn(banned, src)

    def test_planned_tool_names_are_covered_by_the_paid_gate(self):
        import re
        pattern = json.loads((ROOT / "studio" / "config" / "studio.json").read_text())["paid_tools"]["pattern"]
        caps = kling.capabilities()
        for name, tool in caps["tools"].items():
            self.assertRegex(tool["mcp_tool"], re.compile(pattern), name)


class TestAgentDefinitions(unittest.TestCase):
    AGENTS = ROOT / ".claude" / "agents"

    def front(self, name):
        text = (self.AGENTS / f"{name}.md").read_text()
        self.assertTrue(text.startswith("---\n"), name)
        head = text.split("---\n")[1]
        return dict(line.split(":", 1) for line in head.strip().splitlines()), text

    def test_agents_have_valid_frontmatter_and_allowed_models(self):
        models = json.loads((ROOT / "studio" / "config" / "studio.json").read_text())["models"]
        for name in ("generation-director", "qa-reviewer"):
            fm, _ = self.front(name)
            self.assertEqual(fm["name"].strip(), name)
            self.assertTrue(fm["description"].strip())
            self.assertIn(fm["model"].strip(), ("opus", "sonnet", "haiku"))
            self.assertEqual(fm["model"].strip(), models[name])

    def test_agents_have_no_generation_or_approval_powers(self):
        for name in ("generation-director", "qa-reviewer"):
            fm, text = self.front(name)
            tools = {t.strip() for t in fm["tools"].split(",")}
            self.assertTrue(tools <= {"Read", "Glob", "Grep", "Bash", "Write"}, tools)
            self.assertNotIn("approval decide", text)

    def test_no_agent_name_collides_with_a_skill_or_the_recovered_agent(self):
        names = {p.stem for p in self.AGENTS.glob("*.md")}
        skills = {p.name for p in (ROOT / ".claude" / "skills").iterdir()}
        self.assertFalse((names & skills) - {"inspiration-intelligence"})   # that pair ships together in the pack
        self.assertNotIn("reference-analyst", names)   # superseded by the owner's Agent 00


if __name__ == "__main__":
    unittest.main()
