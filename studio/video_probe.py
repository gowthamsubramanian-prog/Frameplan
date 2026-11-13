#!/usr/bin/env python3
"""Reference-video shot breakdown (local, free: ffmpeg + ffprobe only).

Measures what can be measured: metadata, hard cuts, and real frames per shot.
It does NOT judge framing, movement or lighting. Those columns are left blank
for a reviewer who has looked at the extracted frames.

    python3 studio/video_probe.py ref.mp4 --out media/work/ref_breakdown

Outputs in --out:
    breakdown.json                 metadata, shots, file list, limitations
    <name>_Shot_List.csv           one row per shot, Master Shot Manifest columns
    shot_XX_actual_frame.jpg       middle frame of each shot
    shot_XX_start_frame.jpg / shot_XX_end_frame.jpg   (unless --no-edges)
    <name>_Contact_Sheet.jpg       all middle frames, in order
"""
from __future__ import annotations

import argparse
import csv
import json
import math
import re
import shutil
import subprocess
import sys
from pathlib import Path

# Column order of the owner's SHOT_MANIFEST_TEMPLATE.csv
MANIFEST_FIELDS = ("shot_id start_time end_time shot_size body_crop camera_angle camera_height "
                   "composition model_movement camera_movement focal_length recording_settings "
                   "actual_frame sketch confidence").split()

LIMITATIONS = [
    "Only hard cuts are detected. Dissolves, whip-pan transitions, speed ramps and match cuts "
    "may be missed or split; check the contact sheet against the video.",
    "Shot boundaries are accurate to about one frame.",
    "Framing, camera movement, model movement, lens and lighting are NOT measured. They must be "
    "judged from the extracted start/middle/end frames and labelled observed or inferred.",
    "Source camera settings cannot be recovered from the file.",
]


class ProbeError(Exception):
    pass


def run(cmd: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True)


def timecode(t: float) -> str:
    m, s = divmod(max(t, 0.0), 60)
    return f"{int(m):02d}:{s:06.3f}"


def metadata(video: Path) -> dict:
    p = run(["ffprobe", "-v", "error", "-print_format", "json", "-show_format", "-show_streams", str(video)])
    if p.returncode != 0:
        raise ProbeError(f"ffprobe could not read {video}: {p.stderr.strip()[:300]}")
    info = json.loads(p.stdout)
    v = next((s for s in info.get("streams", []) if s.get("codec_type") == "video"), None)
    if not v:
        raise ProbeError(f"{video} has no video stream")
    a = next((s for s in info["streams"] if s.get("codec_type") == "audio"), None)
    num, _, den = (v.get("avg_frame_rate") or "0/1").partition("/")
    fps = float(num) / float(den or 1) if float(den or 1) else 0.0
    duration = float(info.get("format", {}).get("duration") or v.get("duration") or 0)
    rotation = 0
    for sd in v.get("side_data_list", []) or []:
        if "rotation" in sd:
            rotation = int(sd["rotation"])
    w, h = int(v["width"]), int(v["height"])
    if abs(rotation) in (90, 270):
        w, h = h, w
    g = math.gcd(w, h) or 1
    return {
        "file": video.name, "duration_s": round(duration, 3), "fps": round(fps, 3),
        "width": w, "height": h, "aspect_ratio": f"{w // g}:{h // g}",
        "orientation": "vertical" if h > w else "horizontal" if w > h else "square",
        "video_codec": v.get("codec_name"), "rotation": rotation,
        "has_audio": a is not None, "audio_codec": a.get("codec_name") if a else None,
        "size_bytes": int(info.get("format", {}).get("size") or 0),
    }


def detect_cuts(video: Path, threshold: float) -> list[float]:
    p = run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(video),
             "-filter:v", f"select='gt(scene,{threshold})',showinfo", "-an", "-f", "null", "-"])
    if p.returncode != 0:
        raise ProbeError(f"ffmpeg scene detection failed: {p.stderr.strip()[-300:]}")
    return sorted(float(m) for m in re.findall(r"pts_time:([0-9.]+)", p.stderr))


def build_shots(cuts: list[float], duration: float, min_shot: float) -> list[dict]:
    bounds = [0.0]
    for c in cuts:
        if c - bounds[-1] >= min_shot and duration - c >= min_shot:
            bounds.append(c)
    bounds.append(duration)
    return [{"shot_id": f"S{i:02d}", "index": i, "start_s": round(a, 3), "end_s": round(b, 3),
             "duration_s": round(b - a, 3), "start_time": timecode(a), "end_time": timecode(b)}
            for i, (a, b) in enumerate(zip(bounds, bounds[1:]), 1)]


def grab(video: Path, t: float, dest: Path, long_edge: int) -> bool:
    scale = f"scale='if(gt(iw,ih),min({long_edge},iw),-2)':'if(gt(iw,ih),-2,min({long_edge},ih))'"
    p = run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-ss", f"{max(t, 0):.3f}",
             "-i", str(video), "-frames:v", "1", "-vf", scale, "-q:v", "3", str(dest)])
    return p.returncode == 0 and dest.exists() and dest.stat().st_size > 0


def contact_sheet(out: Path, n: int, dest: Path) -> bool:
    cols = min(6, max(1, math.ceil(math.sqrt(n))))
    rows = math.ceil(n / cols)
    p = run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-start_number", "1",
             "-i", str(out / "shot_%02d_actual_frame.jpg"),
             "-vf", f"scale=320:-2,tile={cols}x{rows}:padding=6:margin=6", "-frames:v", "1",
             "-q:v", "3", str(dest)])
    return p.returncode == 0 and dest.exists()


def probe(video: Path, out: Path, threshold: float = 0.3, min_shot: float = 0.4,
          edges: bool = True, long_edge: int = 1280) -> dict:
    for tool in ("ffmpeg", "ffprobe"):
        if not shutil.which(tool):
            raise ProbeError(f"{tool} is not installed")
    if not video.is_file():
        raise ProbeError(f"video not found: {video}")
    if out.exists() and any(out.iterdir()):
        raise ProbeError(f"output folder {out} is not empty; choose a new folder (nothing is overwritten)")
    out.mkdir(parents=True, exist_ok=True)
    meta = metadata(video)
    if meta["duration_s"] <= 0:
        raise ProbeError("could not determine the video duration")
    shots = build_shots(detect_cuts(video, threshold), meta["duration_s"], min_shot)
    if len(shots) > 99:
        raise ProbeError(f"{len(shots)} shots detected; raise --threshold or --min-shot")
    frame = 1.0 / meta["fps"] if meta["fps"] else 0.04
    warnings = []
    for s in shots:
        n = s["index"]
        mid = (s["start_s"] + s["end_s"]) / 2
        s["actual_frame"] = f"shot_{n:02d}_actual_frame.jpg"
        if not grab(video, mid, out / s["actual_frame"], long_edge):
            warnings.append(f"{s['shot_id']}: middle frame could not be extracted")
            s["actual_frame"] = None
        if edges:
            for label, t in (("start", s["start_s"] + frame), ("end", s["end_s"] - 2 * frame)):
                name = f"shot_{n:02d}_{label}_frame.jpg"
                t = min(max(t, s["start_s"]), max(s["end_s"] - frame, s["start_s"]))
                s[f"{label}_frame"] = name if grab(video, t, out / name, long_edge) else None
    stem = re.sub(r"[^A-Za-z0-9_-]+", "_", video.stem).strip("_") or "video"
    sheet = f"{stem}_Contact_Sheet.jpg"
    have_all = all(s["actual_frame"] for s in shots)
    sheet_ok = have_all and contact_sheet(out, len(shots), out / sheet)
    if not sheet_ok:
        warnings.append("contact sheet was not created")
    csv_name = f"{stem}_Shot_List.csv"
    with (out / csv_name).open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=MANIFEST_FIELDS)
        w.writeheader()
        for s in shots:
            row = {k: "" for k in MANIFEST_FIELDS}
            row.update(shot_id=s["shot_id"], start_time=s["start_time"], end_time=s["end_time"],
                       actual_frame=s["actual_frame"] or "")
            w.writerow(row)
    result = {
        "ok": True, "source": meta, "settings": {"threshold": threshold, "min_shot_s": min_shot},
        "shot_count": len(shots), "shots": shots,
        "average_shot_s": round(meta["duration_s"] / len(shots), 3),
        "files": {"shot_list_csv": csv_name, "contact_sheet": sheet if sheet_ok else None,
                  "frames_extracted": len([p for p in out.glob("shot_*_frame.jpg")])},
        "measured": ["metadata", "cut times", "shot durations", "extracted frames"],
        "not_measured": ["shot_size", "body_crop", "camera_angle", "camera_height", "composition",
                         "model_movement", "camera_movement", "focal_length", "recording_settings",
                         "sketch", "confidence"],
        "limitations": LIMITATIONS, "warnings": warnings,
    }
    (out / "breakdown.json").write_text(json.dumps(result, indent=2))
    return result


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("video")
    ap.add_argument("--out", required=True, help="new or empty output folder")
    ap.add_argument("--threshold", type=float, default=0.3, help="scene-change sensitivity 0-1 (lower = more cuts)")
    ap.add_argument("--min-shot", type=float, default=0.4, help="ignore cuts closer together than this many seconds")
    ap.add_argument("--no-edges", action="store_true", help="skip start/end frames")
    ap.add_argument("--long-edge", type=int, default=1280)
    a = ap.parse_args(argv)
    try:
        r = probe(Path(a.video), Path(a.out), a.threshold, a.min_shot, not a.no_edges, a.long_edge)
    except ProbeError as e:
        print(json.dumps({"ok": False, "error": str(e)}, indent=2), file=sys.stderr)
        return 1
    print(json.dumps(r, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
