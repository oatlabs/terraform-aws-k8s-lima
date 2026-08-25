# Shared by every directory in the repo. TFLint's --recursive mode looks for a
# .tflint.hcl inside each directory it descends into, so this file has to be
# passed explicitly by absolute path:
#
#   tflint --recursive --config="$PWD/.tflint.hcl"
#
# `just lint` and the CI job both do that.

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.44.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
