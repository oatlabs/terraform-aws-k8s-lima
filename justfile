tflint_config := justfile_directory() / ".tflint.hcl"
tfdocs_config := justfile_directory() / ".terraform-docs.yml"
tool_versions := justfile_directory() / ".tool-versions"
plugin_cache := env("TF_PLUGIN_CACHE_DIR", home_directory() / ".terraform.d/plugin-cache")

default:
    @just --list

check: tools fmt-check validate lint docs-check

tools:
    #!/usr/bin/env bash
    set -euo pipefail

    installed() {
      case "$1" in
        terraform)      terraform version </dev/null 2>/dev/null | sed -n '1s/^Terraform v//p' ;;
        tflint)         tflint --version </dev/null 2>/dev/null | sed -n '1s/^TFLint version //p' ;;
        just)           just --version </dev/null 2>/dev/null | sed -n '1s/^just //p' ;;
        terraform-docs) terraform-docs version </dev/null 2>/dev/null | sed -n '1s/^terraform-docs version v\([^ ]*\).*/\1/p' ;;
      esac
    }

    fail=0
    while read -r tool want _; do
      [ -n "$tool" ] || continue
      got=$(installed "$tool" || true)
      if [ -z "$got" ]; then
        echo "missing: $tool (CI uses $want)"
        fail=1
      elif [ "$got" != "$want" ]; then
        echo "drift:   $tool $got installed, CI uses $want"
        fail=1
      fi
    done < "{{tool_versions}}"

    if [ "$fail" -ne 0 ]; then
      echo "pins live in .tool-versions; 'mise install' or 'asdf install' matches them"
      exit 1
    fi

fmt:
    terraform fmt -recursive .

fmt-check:
    terraform fmt -check -recursive -diff .

dirs:
    @printf '%s\n' . modules/*/ examples/*/

validate:
    #!/usr/bin/env bash
    set -euo pipefail
    while read -r d; do
      just validate-dir "$d"
    done < <(just dirs)

validate-dir dir:
    #!/usr/bin/env bash
    set -euo pipefail
    export TF_PLUGIN_CACHE_DIR="{{plugin_cache}}"
    mkdir -p "$TF_PLUGIN_CACHE_DIR"
    echo "==> {{dir}}"
    terraform -chdir="{{dir}}" init -backend=false -input=false >/dev/null
    terraform -chdir="{{dir}}" validate

lint:
    tflint --init --config="{{tflint_config}}"
    tflint --recursive --config="{{tflint_config}}" --format compact

docs:
    #!/usr/bin/env bash
    set -euo pipefail
    for d in modules/*/; do
      terraform-docs markdown "$d" --config "{{tfdocs_config}}" --output-file README.md
    done

docs-check:
    #!/usr/bin/env bash
    set -euo pipefail
    fail=0
    for d in modules/*/; do
      if ! terraform-docs markdown "$d" --config "{{tfdocs_config}}" --output-file README.md --output-check; then
        if [ -n "${GITHUB_ACTIONS:-}" ]; then
          echo "::error file=${d%/}/README.md::README is stale — run 'just docs' and commit"
        else
          echo "stale: ${d%/}/README.md — run 'just docs'"
        fi
        fail=1
      fi
    done
    exit $fail

clean:
    #!/usr/bin/env bash
    set -euo pipefail
    dirs=$(find . -type d -name .terraform -prune)
    if [ -z "$dirs" ]; then
      echo "nothing to clean"
      exit 0
    fi
    echo "freeing $(echo "$dirs" | xargs du -shc | tail -1 | cut -f1) from $(echo "$dirs" | wc -l | tr -d ' ') directories"
    find . -type d -name .terraform -prune -exec rm -rf {} +
    rm -f .terraform.lock.hcl modules/*/.terraform.lock.hcl
    echo "removed .terraform/ directories and the gitignored lock files"
    echo "the shared provider cache is untouched: ${TF_PLUGIN_CACHE_DIR:-$HOME/.terraform.d/plugin-cache}"
