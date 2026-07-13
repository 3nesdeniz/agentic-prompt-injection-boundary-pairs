# Dataset Card

## Summary

Agentic Prompt-Injection Boundary Pairs is a synthetic English dataset for studying the difference between legitimate agentic requests and prompt-injection attempts. It contains 600 controlled pairs across 50 workflow scenarios and 12 attack families.

The dataset is designed for hard-negative evaluation. The benign and malicious members of a pair share the same workflow context, assets and vocabulary. Their labels differ because the malicious member attempts to cross a security boundary.

## Motivation

Attack-only corpora are useful for coverage but can reward shallow detection. A model may learn that words such as `system prompt`, `administrator`, `tool` or `approval` imply an attack. That behavior creates false positives whenever a legitimate user discusses the same concepts.

This release keeps those concepts present on both sides of the label boundary. The intended signal is the requested action and its relationship to authorization, trust, instruction hierarchy, confidentiality and human approval.

## Composition

- 1,200 rows
- 600 benign boundary rows
- 600 prompt-injection rows
- 600 pair IDs
- 50 scenario IDs
- 12 attack families
- 43 risk domains
- 19 source contexts
- English only

The canonical counts are generated in [`metadata/stats.json`](metadata/stats.json).

## Collection and generation

The dataset was created from 50 synthetic workflow specifications in [`source/scenarios.jsonl`](source/scenarios.jsonl). Each specification defines a role, assistant, asset, safe action, restricted action, approval condition, tool and content source.

The deterministic build script renders five phrasing variants for every attack family. Every generated attack is paired with a benign request from the same scenario. The source is synthetic and does not derive from customer prompts, support tickets or private conversations.

## Annotation process

Labels follow the rules in [`ANNOTATION_GUIDE.md`](ANNOTATION_GUIDE.md):

- `0 / benign_boundary`: the request preserves policy, authorization and approval requirements;
- `1 / prompt_injection`: the request attempts to replace, bypass or corrupt a security boundary.

The author manually reviewed a stratified sample covering all attack families, all splits and all phrasing variants. This was a single-author review, not independent double annotation. No inter-annotator agreement is claimed.

## Personal and sensitive information

The data is synthetic. Automated checks scan for email addresses, private IP addresses, credit-card-shaped values, long identifiers, common API-key patterns and private-key headers. These checks reduce accidental exposure risk but are not a formal privacy certification.

## Intended uses

- prompt-injection text classification;
- agentic AI red-team regression testing;
- hard-negative and false-positive analysis;
- tool-use, delegated-agent and approval-workflow evaluations;
- educational examples of trust-boundary failures.

## Out-of-scope uses

- treating a passing score as production security certification;
- making claims about all languages, domains or agent frameworks;
- using the labels as a substitute for deployment-specific authorization policy;
- training autonomous systems to execute restricted actions;
- inferring real-user behavior or prevalence from synthetic counts.

## Biases and limitations

The prompts reflect the author's threat-model choices and English writing style. Balanced labels do not represent real traffic prevalence. Paired templates can expose stylistic shortcuts. The scenarios emphasize enterprise and agentic workflows and therefore underrepresent casual consumer use.

External evaluation should include naturally occurring benign traffic, organization-specific policy, multilingual inputs, long-context attacks and tool-level execution traces.

## Maintenance

Issues and corrections are tracked at:

https://github.com/3nesdeniz/agentic-prompt-injection-boundary-pairs/issues

Changes that alter examples, labels or split membership will be documented in [`CHANGELOG.md`](CHANGELOG.md) and released with a new version.
