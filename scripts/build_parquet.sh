#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

command -v duckdb >/dev/null 2>&1 || {
  echo "duckdb is required to build Parquet files" >&2
  exit 1
}

for split in train validation test; do
  rm -f "data/${split}.parquet"
  duckdb -c "COPY (SELECT * FROM read_json_auto('data/${split}.jsonl', format='newline_delimited')) TO 'data/${split}.parquet' (FORMAT PARQUET, COMPRESSION ZSTD);"
done

echo "Built Parquet files for train, validation and test."
