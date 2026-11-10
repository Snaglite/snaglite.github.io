#!/usr/bin/env python3
"""Builds the search index for the KeyCheck user manual.

Run after adding or changing a chapter:

    python3 tools/build-keycheck-manual-search.py

It gives every h3 and h4 heading in the chapter pages an id (so search results can link
straight to it), then writes keycheck/manual-search-index.js with each section's heading
and text. Running it again is safe: existing ids are kept.
"""

import html
import json
import re
from pathlib import Path

KEYCHECK = Path(__file__).resolve().parent.parent / "keycheck"
HEADING = re.compile(r"<(h[34])((?:\s[^>]*)?)>(.*?)</\1>", re.S)


def plain(fragment):
    """Visible text of an HTML fragment, with tags removed and spaces tidied."""
    fragment = re.sub(r"<(script|style)\b.*?</\1>", " ", fragment, flags=re.S)
    fragment = re.sub(r"<[^>]+>", " ", fragment)
    return re.sub(r"\s+", " ", html.unescape(fragment)).strip()


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-") or "section"


def add_heading_ids(page):
    used = set(re.findall(r'\sid="([^"]+)"', page))

    def give_id(match):
        tag, attributes, inner = match.groups()
        if re.search(r'\sid="', attributes):
            return match.group(0)
        base = slug(plain(inner))
        new_id, n = base, 2
        while new_id in used:
            new_id, n = f"{base}-{n}", n + 1
        used.add(new_id)
        return f'<{tag}{attributes} id="{new_id}">{inner}</{tag}>'

    return HEADING.sub(give_id, page)


def sections(page, url):
    number = re.search(r"Chapter (\d+)", page)
    title = re.search(r"<h1>(.*?)</h1>", page, re.S)
    body = re.search(r'<section class="card"[^>]*>(.*)</section>', page, re.S)
    if not (number and title and body):
        return []
    chapter = f"{number.group(1)}. {plain(title.group(1))}"
    content = body.group(1)
    parts = HEADING.split(content)
    # parts: [intro, tag, attrs, inner, text, tag, attrs, inner, text, ...]
    result = [{"chapter": chapter, "heading": plain(title.group(1)), "url": url, "text": plain(parts[0])}]
    for i in range(1, len(parts), 4):
        attrs, inner, text = parts[i + 1], parts[i + 2], parts[i + 3]
        anchor = re.search(r'\sid="([^"]+)"', attrs)
        result.append({
            "chapter": chapter,
            "heading": plain(inner),
            "url": f"{url}#{anchor.group(1)}" if anchor else url,
            "text": plain(text),
        })
    return result


def chapter_number(path):
    match = re.search(r"Chapter (\d+)", path.read_text(encoding="utf-8"))
    return int(match.group(1)) if match else 999


def main():
    index = []
    pages = sorted(KEYCHECK.glob("manual-*.html"), key=chapter_number)
    for path in pages:
        page = path.read_text(encoding="utf-8")
        updated = add_heading_ids(page)
        if updated != page:
            path.write_text(updated, encoding="utf-8")
        index.extend(sections(updated, path.name))
    out = KEYCHECK / "manual-search-index.js"
    out.write_text(
        "// Made by tools/build-keycheck-manual-search.py. Don't edit by hand; run the script instead.\n"
        "window.KEYCHECK_MANUAL_INDEX = " + json.dumps(index, ensure_ascii=False, indent=1) + ";\n",
        encoding="utf-8",
    )
    print(f"{len(index)} sections from {len(pages)} chapters written to {out.name}")


if __name__ == "__main__":
    main()
