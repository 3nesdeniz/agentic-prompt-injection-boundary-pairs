#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

command -v duckdb >/dev/null 2>&1 || {
  echo "duckdb is required to validate Parquet files" >&2
  exit 1
}

for split in train validation test; do
  case "$split" in
    train) expected_count=840 ;;
    validation) expected_count=120 ;;
    test) expected_count=240 ;;
  esac

  json_count="$(duckdb -csv -noheader -c "SELECT count(*) FROM read_json_auto('data/${split}.jsonl', format='newline_delimited');")"
  parquet_count="$(duckdb -csv -noheader -c "SELECT count(*) FROM read_parquet('data/${split}.parquet');")"

  if [[ "$json_count" != "$expected_count" ]]; then
    echo "Unexpected JSONL row count for ${split}: ${json_count}" >&2
    exit 1
  fi

  if [[ "$parquet_count" != "$json_count" ]]; then
    echo "Parquet row mismatch for ${split}: ${parquet_count} != ${json_count}" >&2
    exit 1
  fi
done

echo "Parquet row counts match JSONL for all splits."
