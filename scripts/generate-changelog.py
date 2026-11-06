#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-only
import json
from pathlib import Path
root=Path(__file__).resolve().parent.parent
catalog=json.loads((root/'Sources/HarmonyApp/Resources/releases.json').read_text())
lines=['# Changelog','', 'This is development metadata, not evidence of a published release.', '']
for release in catalog['releases']:
    lines += [f"## {release['version']} — {release['date']} ({release['channel']})", '', '### Added', '']
    lines += ['- '+h['title'] for h in release['highlights']]
    lines += ['', '### Fixes & Improvements', ''] + ['- '+text for text in release['fixes']]
    lines += ['', '### Known limitations', ''] + ['- '+text for text in release['limitations']] + ['']
(root/'CHANGELOG.md').write_text('\n'.join(lines))
