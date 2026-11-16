#!/bin/sh
# Compatibility boundary for callers which still select the historical filename.
# All application build behavior is implemented by the Grease entrypoint.
set -eu
project_root=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
exec "${AVE_GREASE:-grease}" "$project_root/build.grease" "$@"
