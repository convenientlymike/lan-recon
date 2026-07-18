# Research knowledge base

Reusable security knowledge that makes each engagement start smarter than the last:
vulnerability-class references, service/port fingerprints, device-identification
signatures, and remediation references. Distilled from real engagements + external
sources, so the practice compounds instead of re-deriving.

## Index

- [SOHO / SMB vulnerability classes](soho-smb-vulnerability-classes.md) — the
  weaknesses that actually bite small and mid-sized businesses, and how to spot +
  fix each.

## How this grows

Every engagement contributes back:

- A **new device signature** we had to work out (a port pattern + OUI + behavior that
  pins a device class) → add it to a fingerprints note.
- A **new vulnerability class** or a variant we hit → add it to the vuln-class ref.
- A **remediation** that worked (or didn't) → refine the remediation reference in
  `../templates/remediation-checklist.md`.
- A **methodology improvement** → fold it into `../methodology/`.

The rule: when an engagement teaches something reusable, it lands here or in the
methodology **before the engagement closes** — so the knowledge survives, and the
next assessment is faster and sharper.

## External references (authoritative)

- **NIST SP 800-115** — Technical Guide to Information Security Testing & Assessment.
- **PTES** — Penetration Testing Execution Standard (phase structure).
- **OWASP** — testing guides + the IoT Top 10.
- **CIS Controls** — prioritized safeguards (esp. Controls 1–4: inventory, config,
  data, access — the SMB core).
- **Vendor advisories** — router, printer, and IoT vendor firmware + CVE feeds for
  the device classes routinely encountered.
