#!/usr/bin/env python3
import json
import csv
import re
from pathlib import Path


def titlecase_word(w: str) -> str:
    if w.isupper() and len(w) > 1:
        return w
    # handle hyphens and slashes
    for sep in ['-', '/']:
        if sep in w:
            return sep.join(titlecase_word(part) for part in w.split(sep))
    # preserve punctuation attached
    m = re.match(r"^(\W*)(.*?)(\W*)$", w)
    if m:
        pre, core, post = m.groups()
        return pre + core.capitalize() + post
    return w.capitalize()


def titlecase_string(s: str) -> str:
    parts = s.split(' ')
    return ' '.join(titlecase_word(p) for p in parts)


def process_json_path(p: Path) -> int:
    changed = 0
    data = json.loads(p.read_text())

    def recur(obj):
        nonlocal changed
        if isinstance(obj, dict):
            for k, v in list(obj.items()):
                if k == 'name' and isinstance(v, str):
                    new = titlecase_string(v)
                    if new != v:
                        obj[k] = new
                        changed += 1
                else:
                    recur(v)
        elif isinstance(obj, list):
            for item in obj:
                recur(item)

    recur(data)
    if changed:
        p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    return changed


def process_csv_path(p: Path) -> int:
    changed = 0
    rows = []
    with p.open(newline='') as fh:
        reader = csv.DictReader(fh)
        fieldnames = reader.fieldnames
        for r in reader:
            if 'name' in r and r['name']:
                new = titlecase_string(r['name'])
                if new != r['name']:
                    r['name'] = new
                    changed += 1
            rows.append(r)
    if changed:
        with p.open('w', newline='') as fh:
            writer = csv.DictWriter(fh, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)
    return changed


def main():
    root = Path(__file__).resolve().parents[1]
    total = 0
    for path in [root / 'data' / 'items.json', root / 'nookipedia_items.json', root / 'sample_items.csv']:
        if path.exists():
            if path.suffix == '.json':
                c = process_json_path(path)
                print(f'Updated {c} names in {path}')
                total += c
            elif path.suffix == '.csv':
                c = process_csv_path(path)
                print(f'Updated {c} names in {path}')
                total += c
    if total == 0:
        print('No changes made.')
    else:
        print(f'Total names updated: {total}')


if __name__ == '__main__':
    main()
