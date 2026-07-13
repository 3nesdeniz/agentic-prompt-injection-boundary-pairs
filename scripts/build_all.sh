#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ruby scripts/build_dataset.rb
bash scripts/build_parquet.sh
ruby scripts/update_checksums.rb
ruby scripts/validate_dataset.rb
bash scripts/validate_parquet.sh

echo "Dataset build and validation completed successfully."
