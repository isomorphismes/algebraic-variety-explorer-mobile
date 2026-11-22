#!/bin/sh
# Compatibility interface for the source-built Grease reproducibility entry.
set -eu
project_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
exec "${AVE_GREASE:-grease}" "$project_root/fdroid/reproducible.grease" "$@"
