# Assessment Methodology

The repeatable process behind every engagement. It exists so that each assessment
is **consistent, thorough, and defensible** — the same rigor applied whether the
target is a five-person office or a 50-device operation, scaled to fit.

The methodology is deliberately **framework-aligned but right-sized**. It borrows
the phase structure of established standards (NIST SP 800-115 *Technical Guide to
Information Security Testing*, the PTES stages, OWASP's testing guidance) without
burdening a small business with enterprise-scale ceremony. We take the parts that
find real risk and drop the parts that only generate paperwork.

---

## The four phases

```
┌─ 1. SCOPE & AUTHORIZE ──────────────────────────────────────────────┐
│  Understand the business + network. Write and sign the scoped         │
│  authorization. Verify ownership. Define read-only vs. active.        │
└───────────────────────────────────────────────────────────────────────┘
                              │
┌─ 2. DISCOVER & INVENTORY ───▼───────────────────────────────────────┐
│  Enumerate every live host. Identify each (what it is, what it runs,  │
│  what it exposes). Map the topology. Grade every claim by evidence.   │
└───────────────────────────────────────────────────────────────────────┘
                              │
┌─ 3. ASSESS VULNERABILITY ───▼───────────────────────────────────────┐
│  Turn the inventory into risk: exposed services, default/weak creds,  │
│  unpatched/EOL systems, misconfig, weak segmentation, remote-access   │
│  hygiene. Rank by real business impact.                               │
└───────────────────────────────────────────────────────────────────────┘
                              │
┌─ 4. REPORT & REMEDIATE ─────▼───────────────────────────────────────┐
│  Prioritized, plain-English report. Concrete remediation per finding. │
│  Re-test to prove each fix is green. Retain/purge evidence as agreed. │
└───────────────────────────────────────────────────────────────────────┘
```

| Phase | Guide | Output artifact |
|---|---|---|
| 1 | [Scoping & Authorization](01-scoping-and-authorization.md) | Signed authorization + scope |
| 2 | [Discovery & Asset Inventory](02-discovery-and-asset-inventory.md) | Evidence-graded inventory + topology |
| 3 | [Vulnerability Assessment](03-vulnerability-assessment.md) | Prioritized findings register |
| 4 | [Reporting & Remediation](04-reporting-and-remediation.md) | Client report + re-test verification |

Cross-cutting standard: [**Honesty-banding**](honesty-banding.md) — how every
observation is graded VERIFIED / INFERRED / UNKNOWN so the report never presents a
guess as a fact.

---

## Principles that run through all four phases

- **Authorization gates everything** (Phase 1 is not optional and not a formality).
- **Read-only until active testing is separately authorized.** Most SMB value is
  found without ever sending a state-changing packet.
- **Evidence over assertion.** If we can't point to the byproduct that proves a
  claim, the claim is banded down or dropped.
- **Business risk over raw score.** We rank by what could hurt *this* business, not
  by a CVSS number in isolation.
- **The fix is the point.** A finding without an actionable remediation is
  incomplete work.
- **Everything bounded.** No unbounded scans, no overlapping runs, no tool that can
  hang or flood.

---

## Scaling the methodology

| Engagement size | Discovery | Assessment | Report |
|---|---|---|---|
| **Micro** (≤10 devices, home-office) | Single read-only sweep | Exposed-service + default-cred + posture review | 3–5 page report + checklist |
| **Small** (10–50 devices) | Full inventory + segmentation review | + patch/EOL review, wireless, remote-access | Full report + findings register |
| **Mid** (50+ / multi-VLAN) | Per-segment inventory | + authorized active validation of the top risks | Full report + exec summary + roadmap |

Right-size, but never skip a phase — a micro engagement still scopes, still grades
evidence, still re-tests.
