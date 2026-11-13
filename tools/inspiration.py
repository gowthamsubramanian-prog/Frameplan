#!/usr/bin/env python3
"""Offline, stdlib-only catalog. It never scrapes URLs or retrieves private collections.

Modified 13 Nov 2026 with the owner's approval: `add` and `import` also accept a path to a local
media file (an upload or download with no known link). The original is kept unaltered in
archive/recovery-pack-2026-11-13/.
"""
import argparse
import csv
import hashlib
import json
import re
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit, parse_qsl, urlencode

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "data" / "inspirations.sqlite3"
SHOT_FIELDS = "index shot_id start_time end_time shot_size body_crop camera_angle camera_height composition model_movement camera_movement focal_length recording_settings actual_frame sketch confidence".split()


def now():
    return datetime.now(timezone.utc).isoformat()


def normalize(url):
    parts = urlsplit(url.strip())
    if parts.scheme not in ("http", "https") or not parts.netloc:
        raise ValueError(f"Not a valid HTTP(S) URL: {url!r}")
    host = parts.netloc.lower().removeprefix("www.")
    query = urlencode([(k, v) for k, v in parse_qsl(parts.query) if not k.lower().startswith("utm_") and k.lower() not in ("fbclid", "igshid")])
    return urlunsplit(("https", host, parts.path.rstrip("/") or "/", query, ""))


def local_source(value):
    """A local media file: returns (stored reference, duplicate key) or None if `value` is not a file.

    No URL is invented. The reference is `file:<path relative to the project>` and the duplicate
    key is the file's SHA-256, so the same file under another name is recognised.
    """
    path = Path(value[5:] if value.startswith("file:") else value).expanduser()
    if not path.is_file():
        return None
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            digest.update(chunk)
    resolved = path.resolve()
    try:
        shown = resolved.relative_to(ROOT).as_posix()
    except ValueError:
        shown = resolved.as_posix()
    return f"file:{shown}", f"sha256:{digest.hexdigest()}"


def connect():
    DB.parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(DB)
    db.row_factory = sqlite3.Row
    db.executescript("""
    CREATE TABLE IF NOT EXISTS refs (
      id INTEGER PRIMARY KEY, url TEXT NOT NULL, url_key TEXT UNIQUE NOT NULL,
      platform TEXT, creator TEXT DEFAULT '', title TEXT DEFAULT '',
      notes TEXT DEFAULT '', collection_name TEXT DEFAULT '',
      access_status TEXT NOT NULL DEFAULT 'unreviewed', genre_json TEXT DEFAULT '[]',
      summary TEXT DEFAULT '', difficulty TEXT DEFAULT '', analysis_json TEXT DEFAULT '{}',
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    );
    """)
    return db


def add(db, item, collection=''):
    url = (item.get('url') or '').strip()
    local = None if url.lower().startswith(('http://', 'https://')) else local_source(url)
    if local:
        url, key = local
        host = ''
    else:
        key = normalize(url)
        host = urlsplit(url).netloc.lower()
    platform = 'local' if local else 'instagram' if 'instagram.com' in host else 'pinterest' if 'pinterest.' in host or 'pin.it' in host else 'youtube' if 'youtube.' in host or 'youtu.be' in host else 'other'
    row = db.execute('SELECT id FROM refs WHERE url_key=?', (key,)).fetchone()
    if row:
        # Do not silently replace existing metadata or user's original notes.
        return row['id'], False
    cur = db.execute('INSERT INTO refs (url,url_key,platform,creator,title,notes,collection_name,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?)',
        (url,key,platform,item.get('creator',''),item.get('title',''),item.get('notes',''),item.get('collection',collection),now(),now()))
    db.commit()
    return cur.lastrowid, True


def output(row):
    print(f"REF-{row['id']:06d} | {row['platform']} | {row['access_status']} | {row['creator'] or 'creator unknown'} | {row['title'] or row['url']} | {row['collection_name']}")


def main():
    p = argparse.ArgumentParser(description='Inspiration Intelligence catalog; no automatic scraping')
    sub = p.add_subparsers(dest='cmd',required=True)
    a=sub.add_parser('add'); a.add_argument('url', help='an http(s) link, or the path of a local media file'); a.add_argument('--creator',default=''); a.add_argument('--title',default=''); a.add_argument('--notes',default=''); a.add_argument('--collection',default='')
    a=sub.add_parser('import'); a.add_argument('file'); a.add_argument('--collection',default='')
    a=sub.add_parser('analyse'); a.add_argument('file')
    a=sub.add_parser('search'); a.add_argument('query')
    sub.add_parser('list')
    a=sub.add_parser('export-shots'); a.add_argument('file')
    args=p.parse_args(); db=connect()
    if args.cmd=='add':
        try:
            rid,created=add(db,vars(args))
        except ValueError:
            p.error(f"{args.url!r} is neither an http(s) link nor an existing local file")
        print(f"REF-{rid:06d} {'added' if created else 'already exists'}")
    elif args.cmd=='import':
        path=Path(args.file)
        if path.suffix.lower()=='.csv':
            with path.open(newline='',encoding='utf-8-sig') as f: items=list(csv.DictReader(f))
        elif path.suffix.lower()=='.json':
            items=json.loads(path.read_text(encoding='utf-8'))
        else: p.error('Import requires CSV or JSON')
        if not isinstance(items,list): p.error('JSON must be an array')
        created=0; invalid=[]
        for item in items:
            if isinstance(item,str): item={'url':item}
            try:
                _,new=add(db,item,args.collection); created+=new
            except ValueError:
                invalid.append(item.get('url',''))
        print(f"Imported {created} new; {len(items)-created-len(invalid)} duplicates")
        for bad in invalid: print(f"Skipped (neither an http(s) link nor an existing local file): {bad!r}")
    elif args.cmd=='analyse':
        obj=json.loads(Path(args.file).read_text(encoding='utf-8'))
        ridstr=obj.get('reference_id','')
        if not re.fullmatch(r'REF-\d{6}',ridstr): p.error('reference_id must be REF-000001 format')
        rid=int(ridstr[4:]); row=db.execute('SELECT * FROM refs WHERE id=?',(rid,)).fetchone()
        if row is None: p.error('Reference ID not found; add URL first')
        statuses=('reviewed_video','reviewed_images','metadata_only','blocked','unreviewed')
        if obj.get('access_status') not in statuses: p.error(f'access_status must be one of {statuses}')
        for t in obj.get('techniques',[]):
            if t.get('certainty') not in ('observed','inferred','suggested','unverified'): p.error('Each technique needs a valid certainty')
        db.execute('UPDATE refs SET access_status=?,creator=?,title=?,genre_json=?,summary=?,difficulty=?,analysis_json=?,updated_at=? WHERE id=?',
           (obj['access_status'],obj.get('creator') or row['creator'],obj.get('title') or row['title'],json.dumps(obj.get('genre',[])),obj.get('story_summary',''),obj.get('difficulty',''),json.dumps(obj,ensure_ascii=False),now(),rid))
        db.commit(); print(f"Saved analysis for {ridstr}")
    elif args.cmd in ('search','list'):
        rows=db.execute('SELECT * FROM refs ORDER BY updated_at DESC').fetchall()
        for row in rows:
            haystack=' '.join(str(row[x]) for x in ('url','creator','title','notes','collection_name','genre_json','summary','analysis_json')).lower()
            if args.cmd=='list' or all(term in haystack for term in args.query.lower().split()): output(row)
    elif args.cmd=='export-shots':
        rows=db.execute('SELECT id,url,creator,analysis_json FROM refs ORDER BY id').fetchall()
        out=Path(args.file); out.parent.mkdir(parents=True,exist_ok=True)
        with out.open('w',newline='',encoding='utf-8') as f:
            w=csv.DictWriter(f,fieldnames=SHOT_FIELDS+['reference_id','source_url','creator','candidate_label','approval_status']); w.writeheader()
            count=0
            for r in rows:
                obj=json.loads(r['analysis_json'])
                for shot in obj.get('shot_candidates',[]):
                    count+=1; record={k:'' for k in SHOT_FIELDS}; record.update({
                        'index':count,'shot_id':f'PROPOSED-{count:04d}','shot_size':shot.get('shot_size',''),
                        'body_crop':shot.get('body_crop',''),'camera_angle':shot.get('camera_angle',''),
                        'camera_height':shot.get('camera_height',''),'composition':shot.get('composition',''),
                        'model_movement':shot.get('model_movement',''),'camera_movement':shot.get('camera_movement',''),
                        'confidence':shot.get('confidence','suggested')})
                    record.update(reference_id=f"REF-{r['id']:06d}",source_url=r['url'],creator=r['creator'],candidate_label=shot.get('label',''),approval_status='PENDING_REVIEW')
                    w.writerow(record)
        print(f"Exported {count} proposed shots to {out}")

if __name__=='__main__': main()
