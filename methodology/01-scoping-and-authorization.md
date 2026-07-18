# Phase 1 — Scoping & Authorization

The phase that makes everything after it legitimate. Nothing touches the network
until this phase is complete and signed. See the master
[`../AUTHORIZATION.md`](../AUTHORIZATION.md) for the governing doctrine; this is the
operational how-to.

---

## Objectives

1. Understand the business, the network, and the concern well enough to scope well.
2. Produce a **written, signed, bounded authorization**.
3. **Verify** the authorizer actually controls the network.
4. Decide the **activity level** (read-only discovery vs. authorized active testing).

---

## Intake questions (understand before scoping)

- **What does the business do**, and what would "a bad day" look like (ransomware?
  a leaked client list? POS downtime? a wired-transfer fraud)? This anchors risk
  ranking later.
- **What's on the network** that they know of — servers, POS, cameras, NAS, guest
  Wi-Fi, personal devices, anything with regulated data (PII, PHI, PCI)?
- **Who runs IT** — the owner, a nephew, a managed-service provider, nobody?
- **What's the concern** that prompted this — an incident, an insurance
  requirement, a compliance ask, or general prudence?
- **What's fragile** — any device that must not be disrupted (medical, industrial,
  a legacy box running the whole operation)?

---

## Defining scope (write it down, make it explicit)

A good scope is unambiguous about all of:

| Dimension | Example |
|---|---|
| **In-scope targets** | `192.168.1.0/24` (the main office LAN) |
| **Out-of-scope** | The tenant's separate `192.168.9.0/24`; the landlord's cameras |
| **Activity level** | Read-only discovery + posture review. Active testing: **not** authorized this engagement. |
| **Window** | 2026-07-20 08:00 → 2026-07-22 18:00, local |
| **Rate/impact limit** | Non-intrusive; bounded probes only; stop-on-disruption |
| **Owner contact** | Name, phone — reachable during the window |
| **Report recipients** | Only the named owner/officer |

**Scope creep is a discipline failure.** A device discovered at `.9.x` when the
scope says `.1.x` is out of scope — note that it exists, do not probe it, and raise
it with the owner for a scope amendment if it matters.

---

## Verifying ownership / authority

- Confirm the signer **owns the business or is IT-responsible** and can consent for
  the organization.
- On shared infrastructure (co-working, strip-mall, MDU), confirm the network is
  **theirs** and not a shared/landlord segment — assess only what they control.
- For a company, the authorizer should have **authority to bind the org** (owner,
  CTO/IT director, or written delegation).

---

## Activity level — read-only vs. active

The **default is read-only discovery** (see `../AUTHORIZATION.md` for what that
means and its honest limits). It answers most SMB questions — what's here, what's
exposed, what's misconfigured — without a single state-changing packet.

**Active testing** (default-credential checks, exploit validation, anything
state-changing) is a **separate, initialed scope line** with its own window, and is
preceded by the read-only proof. If read-only evidence already makes the risk
obvious and the owner is convinced to fix it, active testing may be unnecessary.

---

## Rules of engagement (the operational guardrails)

- **Bounded tools only** — every scan has a timeout; no unbounded/looping probes.
- **Stop-on-disruption** — if anything on the network appears to degrade, stop and
  contact the owner.
- **Disclose the traffic** — tell the owner the assessment will appear in logs/IDS
  so their monitoring doesn't misread it as an attack (and so an *actual* attacker
  hiding behind the noise isn't excused).
- **Handle data least-disclosure** — findings go only to named recipients; raw
  evidence stays local and is retained/purged as agreed.

---

## Exit criteria (Phase 1 is done when…)

- [ ] The engagement's `AUTHORIZATION.md` is filled from the template, **signed, and
      dated**.
- [ ] In-scope and out-of-scope targets are explicit.
- [ ] Activity level is set (and active testing, if any, is separately initialed).
- [ ] The window, contacts, and report recipients are recorded.
- [ ] Ownership/authority is verified.

Only then does Phase 2 begin.
