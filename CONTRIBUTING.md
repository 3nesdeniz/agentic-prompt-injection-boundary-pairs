# Contributing

Corrections, new workflow scenarios and new boundary pairs are welcome.

## Before opening a pull request

1. Do not include customer data, private conversations, real credentials or proprietary prompts.
2. Follow the label rules in [`ANNOTATION_GUIDE.md`](ANNOTATION_GUIDE.md).
3. Keep every scenario in exactly one split.
4. Add or update source specifications rather than editing generated files by hand.
5. Run the full build and validation pipeline:

```bash
./scripts/build_all.sh
```

6. Review the generated diff and confirm that row counts, checksums and documentation are accurate.

## Reporting a labeling problem

Open an issue with:

- the row `id` and `pair_id`;
- the current label;
- the proposed correction;
- the security boundary you believe applies;
- a short explanation that does not include private data.

Label changes should update both members of the controlled pair when the scenario or boundary definition changes.
