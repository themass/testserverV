#!/usr/bin/env python3
"""Merge translated slices into vvv-roles' catalog-zh.json.

Usage: python3 -I merge_zh.py <catalog.json> <dir-with-out-N.json> <output catalog-zh.json>

Fails (non-zero exit) if any catalog role is missing a translation or a translation has an
empty name/description, so a half-finished translation never ships silently.
"""
import glob
import json
import os
import sys

DIVISIONS_ZH = {
    "academic": "学术研究",
    "design": "设计",
    "engineering": "工程开发",
    "finance": "财务金融",
    "game-development": "游戏开发",
    "gis": "地理信息",
    "healthcare": "医疗健康",
    "marketing": "市场营销",
    "paid-media": "付费投放",
    "product": "产品",
    "project-management": "项目管理",
    "research": "调研",
    "sales": "销售",
    "security": "安全",
    "spatial-computing": "空间计算",
    "specialized": "专项",
    "support": "支持运营",
    "testing": "测试质量",
}


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    catalog_path, slices_dir, out_path = sys.argv[1:]
    with open(catalog_path, encoding="utf-8") as f:
        catalog = json.load(f)
    ids = [r["id"] for r in catalog["roles"]]
    division_ids = {d["id"] for d in catalog["divisions"]}

    merged = {}
    for path in sorted(glob.glob(os.path.join(slices_dir, "out-*.json"))):
        with open(path, encoding="utf-8") as f:
            part = json.load(f)
        dup = set(part) & set(merged)
        if dup:
            sys.exit("duplicate ids across slices: %s" % sorted(dup)[:5])
        merged.update(part)

    missing = [i for i in ids if i not in merged]
    extra = [i for i in merged if i not in set(ids)]
    bad = [i for i, v in merged.items() if not v.get("name", "").strip() or not v.get("description", "").strip()]
    if missing or extra or bad:
        sys.exit("missing=%s extra=%s empty=%s" % (missing[:5], extra[:5], bad[:5]))
    if set(DIVISIONS_ZH) != division_ids:
        sys.exit("division labels out of sync: %s" % sorted(set(DIVISIONS_ZH) ^ division_ids))

    out = {
        "divisions": DIVISIONS_ZH,
        "roles": {i: {"name": merged[i]["name"].strip(),
                      "description": merged[i]["description"].strip(),
                      "vibe": merged[i].get("vibe", "").strip()} for i in ids},
    }
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1, sort_keys=True)
        f.write("\n")
    print("merged %d roles, %d divisions" % (len(out["roles"]), len(out["divisions"])))


if __name__ == "__main__":
    main()
