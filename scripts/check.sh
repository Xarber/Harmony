#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
set -eu
# CLT 27 SDK omits SwiftUIMacros; use the existing stable SDK for local macOS QA.
if [ -d /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk ] && [ "$(xcode-select -p)" = /Library/Developer/CommandLineTools ]; then
    exec swift test --sdk /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk --build-system native -Xswiftc -F -Xswiftc /Library/Developer/CommandLineTools/Library/Developer/Frameworks -Xlinker -rpath -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks "$@"
fi
exec swift test "$@"
