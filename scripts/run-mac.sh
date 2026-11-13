#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
set -eu
scripts/build-mac.sh
open "$PWD/.build/Harmony.app" --args "$@"
