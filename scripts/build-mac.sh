#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
set -eu
configuration=debug
if [ "${1:-}" = --release ]; then configuration=release; fi
if [ -d /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk ] && [ "$(xcode-select -p)" = /Library/Developer/CommandLineTools ]; then
    swift build -c "$configuration" --sdk /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk --build-system native
    HARMONY_BIN=$(swift build -c "$configuration" --sdk /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk --build-system native --show-bin-path)
else
    swift build -c "$configuration"
    HARMONY_BIN=$(swift build -c "$configuration" --show-bin-path)
fi
HARMONY_APP="$PWD/.build/Harmony.app"
mkdir -p "$HARMONY_APP/Contents/MacOS" "$HARMONY_APP/Contents/Resources"
cp "$HARMONY_BIN/Harmony" "$HARMONY_APP/Contents/MacOS/Harmony"
cp assets/branding/harmony-512.png "$HARMONY_APP/Contents/Resources/Harmony.png"
python3 - "$HARMONY_APP" <<'PY'
import plistlib,sys,subprocess
from pathlib import Path
p=Path(sys.argv[1])/'Contents/Info.plist'
commit=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip() if subprocess.run(['git','rev-parse','--verify','HEAD'],capture_output=True).returncode==0 else 'uncommitted-development'
if subprocess.check_output(['git','status','--porcelain'],text=True).strip(): commit += '-dirty'
p.write_bytes(plistlib.dumps({'CFBundleIdentifier':'it.xarber.harmony','CFBundleName':'Harmony','CFBundleDisplayName':'Harmony','CFBundleExecutable':'Harmony','CFBundlePackageType':'APPL','CFBundleShortVersionString':'0.1.0','CFBundleVersion':'1','HarmonyCommit':commit,'CFBundleIconFile':'Harmony.png','NSHighResolutionCapable':True,'LSMinimumSystemVersion':'14.0'}))
PY
