#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

out=$(sed -n \
  -e 's/^just \([^ ]*\).*/JUST_VERSION=\1/p' \
  -e 's/^terraform \([^ ]*\).*/TERRAFORM_VERSION=\1/p' \
  -e 's/^tflint \([^ ]*\).*/TFLINT_VERSION=\1/p' \
  -e 's/^terraform-docs \([^ ]*\).*/TERRAFORM_DOCS_VERSION=\1/p' \
  .tool-versions)

for var in JUST_VERSION TERRAFORM_VERSION TFLINT_VERSION TERRAFORM_DOCS_VERSION; do
  if ! grep -qE "^${var}=.+" <<<"$out"; then
    echo "::error file=.tool-versions::no pin found for ${var%_VERSION}" >&2
    exit 1
  fi
done

printf '%s\n' "$out"
