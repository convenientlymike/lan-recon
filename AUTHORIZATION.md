# Authorization & Rules of Engagement — the master doctrine

> **The single most important document in this practice.** Every engagement is
> governed by it. Read it before touching any client network. It is what separates
> legitimate, professional security work from a computer-crime.

Security assessment tools are dual-use. The exact same port probe is a
professional service when the network owner asked for it and a criminal act when
they didn't. **Written, scoped authorization is the line.** This practice never
crosses it, and documenting that discipline is itself a mark of a trustworthy
professional — clients hire the consultant who insists on a signed scope, not the
one who waves it off.

---

## The five non-negotiables

1. **Written authorization before any activity.** No sweep, no probe, no banner
   grab touches a network until the owner (or an officer with authority to consent
   for the organization) has signed a scoped authorization. Verbal "sure, go ahead"
   is not sufficient — it goes in writing.
   → Use [`templates/engagement-authorization.md`](templates/engagement-authorization.md).

2. **Scope is explicit and bounded.** The authorization names exactly:
   - **Targets** — which IP ranges / subnets / hosts / domains are in scope, and
     which are explicitly **out** of scope (a NAS with medical records, a
     production POS system, a tenant's separate network).
   - **Activity level** — read-only discovery vs. active/intrusive testing. These
     are separately authorized; discovery consent never implies exploit consent.
   - **Windows** — the date/time window the work may occur in.
   - **Contacts** — who to call if something breaks, and who receives the report.

3. **Ownership is verified, not assumed.** We confirm the person authorizing
   actually controls the network (they own the business / are IT-responsible / can
   consent for the org). We do **not** assess a network on a tenant's say-so if
   the landlord owns the infrastructure, or a personal device on a corporate LAN
   without the org's consent.

4. **Least intrusion for the goal.** We use the least disruptive technique that
   answers the question. Read-only discovery is the default and covers most SMB
   assessments. Active testing (credential checks, exploit validation, DoS-class
   tests) requires its own explicit scope line and a maintenance window — and we
   still prefer the non-destructive proof.

5. **Do no harm; fail safe.** Every tool is bounded (timeouts, no infinite scans)
   and read-only unless active testing is separately authorized. We never leave a
   network in a worse state than we found it. If a probe risks disrupting a fragile
   device (an old SCADA/medical/embedded system), we stop and ask.

---

## What "read-only / non-intrusive" means here (and its honest limits)

The default assessment posture is **passive/read-only**: we establish a TCP
connection and read what the service voluntarily advertises (its banner, its mDNS
broadcast, its HTTP `Server` header), we read ARP, we look up MAC vendors. We do
**not**:

- attempt any login, credential, or authentication (not even "admin/admin");
- send any write, config change, or state-changing request;
- run exploit payloads or fuzzing;
- perform volumetric/stress/DoS-class traffic.

**Honest limit:** even a read-only connect-scan generates traffic and appears in
logs/IDS. "Non-intrusive" means *non-state-changing and non-disruptive*, not
*invisible*. The authorization covers this traffic; we disclose it to the owner so
their monitoring doesn't misread the assessment as an attack.

---

## Active / intrusive testing — the higher bar

When an engagement genuinely needs active testing (validating that an exposed
service is actually exploitable, checking for default credentials, confirming a
misconfiguration is reachable), it is:

- **separately and explicitly authorized** (its own scope line, initialed);
- **scheduled** in an agreed maintenance window;
- **preceded by the read-only proof** (confirm the mechanism/exposure passively
  first, so the active step is the minimum necessary);
- **capture-exact and reversible** where possible — replicate the legitimate
  request, prefer the non-destructive demonstration, and register how to undo any
  change;
- **bounded and single-flight** — never an unbounded loop, never overlapping runs.

If we can prove the risk without firing the exploit, we prove it without firing
the exploit. The demonstration exists to convince the owner to fix it, not to
show off.

---

## The engagement lifecycle (where authorization lives)

```
1. INTAKE      → understand the business, the network, the concern
2. SCOPE       → write the authorization: targets, activity level, window, contacts
3. SIGN        → owner signs; ownership verified; countersigned; dated
4. ASSESS      → work stays strictly inside the signed scope
5. REPORT      → findings + remediation, delivered only to named contacts
6. RE-TEST     → verify fixes (re-uses the same authorization or a fresh one)
7. RETAIN/PURGE→ handle evidence per the agreed retention; purge on request
```

Every engagement folder opens with its own `AUTHORIZATION.md` — a filled copy of
the template, specific to that client and network. No engagement folder is
"active" until that file is signed.

---

## Forcing function

The [`toolkit/lan-recon.sh`](toolkit/lan-recon.sh) tool **prints an authorization
reminder and requires explicit confirmation of scope** before it runs — the
discipline is built into the tooling, not left to memory. A tool that would scan
a network without first making the operator affirm authorization is itself a
finding; ours refuses to.

---

*If you are ever unsure whether an action is authorized: stop. Ask. Get it in
writing. There is no assessment so urgent it justifies skipping this page.*
