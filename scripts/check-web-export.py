#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-only
"""Check the production export and its initial JavaScript budget."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
export = root / "web/dist"
manifest = json.loads((export / "manifest.webmanifest").read_text())
build = json.loads((export / "build.json").read_text())
budget = json.loads((root / "Config/performance-budgets.json").read_text())
files = ["index.html", "app/index.html", "sw.js"]
files.extend(icon["src"].lstrip("/") for icon in manifest["icons"])
if missing := [file for file in files if not (export / file).is_file()]:
    raise SystemExit(f"Missing export files: {', '.join(missing)}")
if manifest["start_url"] != "/app/" or manifest["display"] != "standalone":
    raise SystemExit("Invalid installation entry or display mode")
if not build["production"] or (export / "tests").exists():
    raise SystemExit("Production export contains development configuration")
size = sum(file.stat().st_size for file in export.rglob("*.js") if file.name != "sw.js")
limit = budget["web"]["initialJavaScriptBytes"]
if size > limit:
    raise SystemExit(f"JavaScript budget exceeded: {size} of {limit} bytes")
print(f"Production export verified, JavaScript {size} of {limit} bytes")
