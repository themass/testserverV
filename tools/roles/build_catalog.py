#!/usr/bin/env python3
"""Build vvv-roles' catalog.json from a checkout of msitarzewski/agency-agents (MIT).

Usage: python3 -I build_catalog.py <agency-agents-dir> <output-resources-roles-dir>

The source prompts are written for coding agents and are long (median ~14 KB). Every chat
message carries the role prompt, so we keep only the parts that define who the role is and
how it behaves, drop fenced code and long deliverable templates, and cap the size.
Output is deterministic: running it twice on the same input gives the same bytes.
"""
import json
import os
import re
import sys

KEEP_SECTIONS = {
    "identity memory": "identity",
    "identity role definition": "identity",
    "identity": "identity",
    "core mission": "mission",
    "mission": "mission",
    "critical rules you must follow": "rules",
    "critical rules": "rules",
    "communication style": "style",
    "core capabilities": "capabilities",
    "domain expertise": "capabilities",
}
SECTION_ORDER = ["identity", "mission", "rules", "capabilities", "style"]
SECTION_TITLES = {
    "identity": "Identity",
    "mission": "Core mission",
    "rules": "Rules",
    "capabilities": "Capabilities",
    "style": "Communication style",
}
SECTION_CAP = 1400
TOTAL_CAP = 4800
FALLBACK_CAP = 3000

EMOJI = re.compile(
    "[\U0001F000-\U0001FAFF☀-➿⬀-⯿️‍←-⇿]"
)
FENCE = re.compile(r"^```.*?^```[ \t]*\n?", re.S | re.M)
SPACES = re.compile(r"\n{3,}")


def parse_frontmatter(text):
    if not text.startswith("---"):
        return None, text
    end = text.find("\n---", 3)
    if end < 0:
        return None, text
    meta = {}
    for line in text[3:end].splitlines():
        m = re.match(r"^([A-Za-z_]+):\s*(.*)$", line)
        if m:
            meta[m.group(1)] = m.group(2).strip().strip("\"'")
    return meta, text[end + 4:].lstrip("\n")


def norm_heading(h):
    h = EMOJI.sub("", h).lower()
    h = re.sub(r"[^a-z ]+", " ", h)
    h = re.sub(r"\byour\b", " ", h)
    return re.sub(r"\s+", " ", h).strip()


def cut(text, cap):
    text = text.strip()
    if len(text) <= cap:
        return text
    cut_at = text.rfind("\n", 0, cap)
    if cut_at < cap // 2:
        cut_at = cap
    return text[:cut_at].rstrip()


def split_sections(body):
    """Return (intro, [(heading, text)]) splitting on level-2 headings outside code fences."""
    body = FENCE.sub("", body)
    parts = re.split(r"^## +(.+)$", body, flags=re.M)
    intro = parts[0]
    sections = []
    for i in range(1, len(parts), 2):
        sections.append((parts[i], parts[i + 1]))
    return intro, sections


def clean(text):
    text = EMOJI.sub("", text)
    text = re.sub(r"^#{1,6} +", "", text, flags=re.M)
    return SPACES.sub("\n\n", text).strip()


def build_prompt(name, body):
    intro, sections = split_sections(body)
    # The intro of each file is "# <Name> Agent Personality" plus a "You are **X**" paragraph.
    intro = re.sub(r"^# .*\n", "", intro, flags=re.M).strip()
    picked = {}
    for heading, text in sections:
        key = KEEP_SECTIONS.get(norm_heading(heading))
        if key and key not in picked:
            picked[key] = clean(text)
    chunks = []
    if intro:
        chunks.append(cut(clean(intro), SECTION_CAP))
    for key in SECTION_ORDER:
        if key in picked and picked[key]:
            chunks.append("## %s\n%s" % (SECTION_TITLES[key], cut(picked[key], SECTION_CAP)))
    prompt = "\n\n".join(chunks)
    if len(picked) == 0:
        # No recognisable sections: keep the opening of the document instead.
        prompt = cut(clean(FENCE.sub("", body)), FALLBACK_CAP)
    return cut(prompt, TOTAL_CAP)


def role_id(division, rel_path):
    stem = rel_path[:-3] if rel_path.endswith(".md") else rel_path
    parts = stem.split(os.sep)
    if parts[-1].startswith(division + "-"):
        parts[-1] = parts[-1][len(division) + 1:]
    slug = "-".join([division] + parts)
    return re.sub(r"[^a-z0-9-]+", "-", slug.lower()).strip("-")


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src, out = sys.argv[1], sys.argv[2]
    with open(os.path.join(src, "divisions.json"), encoding="utf-8") as f:
        divisions = json.load(f)["divisions"]

    featured_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "featured.txt")
    featured = set()
    if os.path.exists(featured_path):
        with open(featured_path, encoding="utf-8") as f:
            featured = {l.strip() for l in f if l.strip() and not l.startswith("#")}

    roles, seen = [], set()
    for division in sorted(divisions):
        base = os.path.join(src, division)
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames.sort()
            for fn in sorted(filenames):
                if not fn.endswith(".md"):
                    continue
                path = os.path.join(dirpath, fn)
                with open(path, encoding="utf-8") as f:
                    meta, body = parse_frontmatter(f.read())
                if not meta or "name" not in meta or "description" not in meta:
                    continue
                rid = role_id(division, os.path.relpath(path, base))
                if rid in seen:
                    sys.exit("duplicate role id: " + rid)
                seen.add(rid)
                roles.append({
                    "id": rid,
                    "division": division,
                    "name": meta["name"],
                    "description": meta["description"],
                    "emoji": meta.get("emoji", ""),
                    "color": meta.get("color", ""),
                    "vibe": meta.get("vibe", ""),
                    "featured": rid in featured,
                    "prompt": build_prompt(meta["name"], body),
                })
    missing = featured - seen
    if missing:
        sys.exit("featured ids not found: " + ", ".join(sorted(missing)))

    catalog = {
        "source": "https://github.com/msitarzewski/agency-agents",
        "license": "MIT",
        "divisions": [
            {"id": d, "label": v["label"], "icon": v["icon"], "color": v["color"]}
            for d, v in sorted(divisions.items())
        ],
        "roles": roles,
    }
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "catalog.json"), "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=1, sort_keys=True)
        f.write("\n")
    with open(os.path.join(src, "LICENSE"), encoding="utf-8") as f:
        lic = f.read()
    with open(os.path.join(out, "NOTICE"), "w", encoding="utf-8") as f:
        f.write("Role definitions in catalog.json are derived from\n"
                "https://github.com/msitarzewski/agency-agents\n"
                "and are redistributed under the MIT License below.\n"
                "Prompts were shortened and reformatted for use as chat system prompts.\n\n")
        f.write(lic)
    total = sum(len(r["prompt"]) for r in roles)
    print("roles=%d divisions=%d prompt_chars=%d max=%d" % (
        len(roles), len(catalog["divisions"]), total, max(len(r["prompt"]) for r in roles)))


if __name__ == "__main__":
    main()
