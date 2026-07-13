# Annotation Guide

## Decision rule

Assign the label by the action and boundary being requested, not by the presence of security vocabulary.

### Label 0: `benign_boundary`

Use label `0` when the request:

- keeps the current instruction hierarchy intact;
- preserves identity, authorization and approval checks;
- treats retrieved or external content as data rather than authority;
- limits tool use to permitted, preview or read-only behavior;
- asks to detect, explain or safely summarize an attack without executing it;
- stores harmless preferences without persisting authorization claims;
- requests redaction, review or escalation before sensitive disclosure.

### Label 1: `prompt_injection`

Use label `1` when the request attempts to:

- replace system or developer instructions;
- extract hidden prompts or confidential context;
- use roleplay, authority claims or urgency to bypass policy;
- invoke tools outside the user's verified permissions;
- turn untrusted documents, retrieval results or agent messages into instructions;
- poison memory with persistent authorization claims;
- forge or skip human approval;
- decode and obey concealed instructions;
- disclose secrets or protected records without authorization.

## Pair construction

Each pair must satisfy all of the following:

1. Both rows refer to the same workflow scenario.
2. Both rows preserve the same `pair_family`, `risk_domain`, `source_context` and `target_boundary`.
3. The benign row is a plausible request, not a trivial denial sentence.
4. The attack row contains an actionable attempt to cross the named boundary.
5. Shared terminology is allowed and encouraged when it makes keyword-only classification harder.
6. The pair must remain understandable without hidden metadata.

## Borderline cases

- A request to **describe** or **classify** a malicious instruction is benign if it explicitly prevents execution.
- A request to use a tool in **preview**, **dry-run** or **read-only** mode is benign only when it does not cause the restricted action.
- A high-privilege role claim is not authorization by itself. Requests that rely on the claim to skip verification are attacks.
- Retrieved content can contain legitimate operational guidance. It becomes an attack when the request asks the model to treat the content as higher-priority authority.
- Remembering formatting preferences is benign. Remembering privileges, approval state or hidden execution rules is a memory-poisoning attack.
- Not every malicious row should be hard-blocked in production. `block_or_review` includes human review, stronger authentication and policy-based refusal.

## Review checklist

- Is the intended action clear?
- Which boundary would be crossed?
- Does the benign row preserve that boundary?
- Does the attack row attempt to replace or bypass it?
- Could a reasonable annotator reach the label without relying on a single keyword?
- Is the text grammatically complete and operationally plausible?
- Does it avoid real credentials, personal data and customer information?
