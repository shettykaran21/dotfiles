Here's a PR description based on the commits on this branch:

## Description

This PR aligns column headers with the metric definitions in the CTV content transparency report configuration. The previous `config.json` had only two columns (`viewable`, `blocked`) while the metrics layer was already producing data for four. Updating the header configuration ensures downstream rendering matches what's being computed.

## Changes

- Updated `src/main/resources/config.json`:
  - Added `totalEligible` (count)
  - Added `failed` (pct)
  - Preserved existing `viewable` and `blocked` columns
- Reordered columns to match the metric output order.

## Motivation

Headers in the rendered report were out of sync with the underlying metric columns, causing confusion for report consumers and potentially misattributing numbers to the wrong labels.

## How to test

1. Check out this branch.
2. Run the report pipeline with a known input and verify the rendered headers match the data columns.
3. Run existing unit tests to confirm nothing regressed.

## Risks

Low risk — change is configuration-only and affects only the header labels shown alongside metric output.

## Related

Ticket: PORT-1783-column-headers-v2

---

Let me know if you'd like me to adjust the tone, length, or structure!
