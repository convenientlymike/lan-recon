# Engagement Authorization — TEMPLATE

> Copy into a new engagement folder as `AUTHORIZATION.md`, fill every field, and get
> it **signed and dated before any assessment activity**. See the master
> [`../AUTHORIZATION.md`](../AUTHORIZATION.md) for the governing doctrine.

## Parties

| Role | Detail |
|---|---|
| **Network owner** | _<business / person who owns the network>_ |
| **Authorizer** | _<name + title — must have authority to consent for the org>_ |
| **Assessor** | _<your name / practice>_ |
| **Ownership verified?** | _<how you confirmed the authorizer controls this network>_ |

## Scope

| Dimension | Value |
|---|---|
| **In-scope targets** | _<IP ranges / subnets / hosts / domains explicitly IN>_ |
| **Out-of-scope** | _<explicitly OUT — tenant nets, production systems, third parties>_ |
| **Activity level** | ☐ Read-only discovery ☐ **+ Active testing** (initial each) |
| **Active testing (if any)** | _<exactly what active tests are authorized — default creds? exploit validation? — and the maintenance window for them>_ |
| **Assessment window** | _<start → end, timezone>_ |
| **Probe origin** | _<where the probes originate — on-site box, jump host, remote>_ |
| **Rate/impact limits** | Non-intrusive, bounded probes; stop-on-disruption |

## Fragile / do-not-touch

_<any device that must not be disrupted — medical, industrial, legacy, POS —
name it here so it is explicitly protected>_

## Data handling

| | |
|---|---|
| **Report recipients** | _<only these named people receive findings>_ |
| **Evidence retention** | _<how long raw evidence is kept, then purged>_ |
| **Confidentiality** | Raw evidence stays local; report sanitized before delivery |

## Rules of engagement

- Read-only unless active testing is separately authorized above.
- Every probe bounded (timeouts); no unbounded/looping scans.
- Stop and contact the owner if anything on the network degrades.
- The assessment traffic will appear in logs/IDS — the owner is informed.

## Affirmation / signatures

| | Name | Signature | Date |
|---|---|---|---|
| **Network owner / authorizer** | | | |
| **Assessor** | | | |

- ☐ In-scope and out-of-scope targets are explicit and understood.
- ☐ Activity level is agreed (active testing separately initialed, if any).
- ☐ Ownership / authority to consent is verified.
- ☐ Window, contacts, and report recipients are recorded.

*No assessment activity occurs until both signatures and all four boxes are complete.*
