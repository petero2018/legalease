#!/usr/bin/env bash
ENV_FILE="${1:-.env}"

if [ ! -f "$ENV_FILE" ]; then
  echo "Environment file not found: $ENV_FILE"
  return 1 2>/dev/null || exit 1
fi

# Export all variables defined while sourcing the file.
set -a
. "$ENV_FILE"
set +a
echo "Loaded environment variables from $ENV_FILE"