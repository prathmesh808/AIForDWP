# Scope-Only Analysis: Floor 6 Copilot Unexpected Client Matter

## Constraint Statement
This analysis uses only the provided scope facts and does not assume additional telemetry, audit logs, permission exports, or prior change history beyond intake.

## Scope Facts Used
- Symptom: Floor 6 reports Copilot surfaced an unexpected client matter
- Who: Floor 6
- Since: 09:00 this morning
- Change: Nil

## Ranked Hypothesis List (Most Probable First)

### 1) Permission boundary mismatch (effective access broader than user expectation)
- Why this fits scope facts:
  - A user seeing an "unexpected" matter is most often an access-model issue where effective permissions differ from what the user believes they should have.
  - Floor-localized reporting can happen when a specific group membership or inherited access pattern affects that cohort.
- Fastest single check:
  - Open the exact source document returned by Copilot and run effective access for the reporting user at incident time.

### 2) Access change propagation or indexing delay after prior permission updates
- Why this fits scope facts:
  - If permission changes happened recently, search/grounding behavior may briefly reflect stale access views during propagation windows.
  - Morning reports can surface overnight or early-day synchronization lag effects.
- Fastest single check:
  - Compare current effective access with the access state recorded before/after incident time for the same document and user.

### 3) Shared workspace or folder inheritance exposing matter content indirectly
- Why this fits scope facts:
  - Users may not realize a parent folder/site/share grants inherited read access to matter documents.
  - "Unexpected" visibility frequently comes from inheritance chains, not direct item-level grants.
- Fastest single check:
  - Trace the full permission inheritance chain from document to parent container and verify inherited grants for the user/group.

### 4) Prompt/context ambiguity caused retrieval of similarly named but authorized matter
- Why this fits scope facts:
  - Copilot may retrieve an authorized but different matter with similar naming, interpreted by user as unauthorized access.
  - This can appear as "wrong client matter" even when permission boundaries are intact.
- Fastest single check:
  - Capture the original prompt and citation list, then validate whether returned source IDs match the alleged unauthorized matter or a similarly named authorized source.

### 5) Genuine Copilot access-enforcement defect
- Why this fits scope facts:
  - A true product defect is possible but should be last after disproving permission, inheritance, and propagation explanations.
  - Scope alone does not provide direct proof of an enforcement bug.
- Fastest single check:
  - Reproduce with controlled test accounts where one account has explicit denial and verify whether Copilot can still cite denied content.

## Current Position
- No single cause is selected yet.
- Next action is to run the five fastest checks in order and re-rank based on first verifiable evidence.