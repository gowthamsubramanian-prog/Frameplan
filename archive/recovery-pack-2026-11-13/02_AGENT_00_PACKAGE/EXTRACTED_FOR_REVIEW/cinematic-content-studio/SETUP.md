# Agent 00 — setup and first test

This module is designed to be copied **into your existing Claude Code Cinematic Content Studio**. Merge `CLAUDE.md` instructions with your existing project instructions rather than replacing them blindly. Keep the `.claude/agents/` and `.claude/skills/` folders and `tools/` and `references/` together. Requires Python 3.9+; no packages or paid API are required for the catalog.

1. In Terminal, `cd` to the project folder and run `python3 tools/inspiration.py add 'https://www.instagram.com/reel/EXAMPLE/' --collection 'Instagram Saves'` (replace the example URL with a real public or saved link).
2. Run `python3 tools/inspiration.py import references/import-example.csv` to test a collection import; edit the CSV with your real exported links.
3. In Claude Code ask: **"Use Inspiration Intelligence to review REF-000001. If you cannot inspect the actual video, report the limitation and ask for a downloaded copy or screenshots. Save only verified observations."**
4. Once Claude submits a validated analysis JSON, run `python3 tools/inspiration.py search 'portal'`.
5. Run `python3 tools/inspiration.py export-shots data/shot_proposals.csv`. Inspect and approve proposed rows manually; leave the existing Master Shot Manifest untouched until then.

## Saved collections

- **Pasted links**: accept individual URLs and link lists. Import `url,creator,title,notes,collection` CSV or equivalent JSON.
- **Pinterest**: with permission and a working authenticated browser, browse user-accessible boards, record pin URLs and attribution; use exported link lists when browsing is unavailable.
- **Instagram Saved**: private saves typically require signed-in UI access. Have the user open their own saved collection in Chrome and let Claude inspect it interactively if the browser bridge supports it. No claim of bulk collection import should be made until a real session is tested. As fallback, collect shared links or a CSV assembled by the user.
- **Downloaded video**: ask for a local copy when access, playback, timecoding or frame extraction is unavailable. Keep copyrighted sources private and only use them for analysis.

## Boundaries and what is not built yet

The database, link/CSV/JSON ingest, analysis import, lookup and review-queue export are working local components. Live authenticated browser navigation, automatic video understanding, media download, semantic similarity, and direct Master Shot Manifest merge are **agent workflows to integrate and test on the user's Mac**, not completed connectors in this package. The search is keyword-based, not vector search. No Instagram/Pinterest account credentials are needed or stored.
