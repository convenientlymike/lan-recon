# Phase 4 — Reporting & Remediation

The phase where the assessment becomes **value the client can act on**. A findings
register in our heads helps nobody; a clear report with a prioritized fix list, in
language the owner understands, is the deliverable they paid for. And a finding
isn't done until we've **re-tested and proven it closed.**

---

## The report — structure

A right-sized report (3–5 pages for a micro engagement, more for larger) with:

1. **Executive summary** (½ page, for the owner). What we assessed, the overall
   posture in one honest sentence, the 3–5 things that matter most, and what to do
   first. No jargon. A business owner should be able to read *only* this and know
   what to do Monday morning.

2. **Scope & method.** What was in/out of scope, the activity level (read-only vs.
   active), the window, and the **honest limits** (e.g. "read-only discovery
   generates log traffic; a guest network, if L2-isolated, could not be confirmed
   from our vantage"). Transparency about what we *didn't* / *couldn't* see is part
   of the professionalism.

3. **Asset inventory.** The evidence-graded device list + topology map (Phase 2
   output). This alone is often worth the engagement — many owners have never seen
   a complete list of what's on their network.

4. **Findings**, ordered by severity. Each finding:
   - **Title + severity** (Critical / High / Medium / Low / Info)
   - **Affected assets**
   - **Evidence** + its confidence band (VERIFIED / INFERRED / UNKNOWN)
   - **Business impact** — what this means for *them*, concretely
   - **Remediation** — the specific fix, in steps they (or their IT) can follow
   - **Effort** — a rough sense (quick setting change vs. hardware replacement)

5. **Remediation roadmap.** The findings re-sorted into a do-this-first action plan:
   quick wins (a setting toggle) up top, longer projects (segmentation, an EOL
   replacement) sequenced after. See [`../templates/remediation-checklist.md`](../templates/remediation-checklist.md).

6. **Appendix.** The raw-but-sanitized detail, the full inventory, methodology
   reference.

---

## Writing findings well

- **Lead with impact, not mechanism.** "An unknown always-on device is on the same
  network as your accounting PC and we can't identify it" beats "Host at .46 has a
  Private OUI and TTL 255."
- **Be honest about severity.** Don't inflate an Info finding to Medium to pad the
  report. Credibility is the asset. An owner who catches one inflated finding
  distrusts all of them.
- **Band the evidence, visibly.** A finding built on an INFERRED identity says so,
  and names what would confirm it.
- **Every finding gets a remediation.** No "consider reviewing." Concrete steps:
  "In your router's app → Guest Network, enable it, then move the smart-home
  devices (camera, speakers, smart plugs) onto it."
- **Rank for the business.** The order of findings *is* the recommendation.

---

## Remediation guidance — the SMB/SOHO greatest hits

Most SMB remediations fall into a small, repeatable set:

| Finding class | Typical remediation |
|---|---|
| Exposed remote-access (RDP/VNC/SSH) | Restrict to LAN/VPN; strong creds + MFA; disable if unused; never port-forward RDP to WAN |
| Default/weak creds | Change them; set a real admin password on every router/printer/camera/NAS |
| Unpatched / EOL | Patch; plan replacement for EOL hardware/OS (it's unfixable-by-design) |
| Unnecessary exposed services | Disable the service; firewall it to only who needs it |
| Flat network | Enable the guest/IoT network; segment cameras & smart-home off the business LAN |
| Weak wireless | WPA2/WPA3, strong PSK, separate guest SSID, disable WPS |
| Router misconfig | Disable UPnP if not needed; close WAN admin; keep firmware current |
| Unknown device | Physically identify it; remove or segment if unaccounted-for |

---

## Re-test — the finding isn't done until it's green

- After the client remediates, **re-run the relevant checks** and confirm the hole
  is closed (the service now refuses, the guest device is now segmented, the admin
  page now requires auth).
- Update the finding status: `Open → Remediated → Verified-Closed`.
- A finding is only **Verified-Closed** when a re-test byproduct proves it — the
  same evidence standard as discovery. We don't take "we fixed it" on faith; we
  confirm it.

---

## Delivery & data handling

- Deliver **only to the named report recipients** from the authorization.
- **Sanitize before anything leaves the engagement folder** — the shareable report
  names what's needed to fix the problem, not every raw MAC/IP.
- **Retain or purge** the raw evidence per the agreed retention. A client's network
  map is sensitive; we don't keep it longer than agreed.

---

## Exit criteria (Phase 4, and the engagement, is done when…)

- [ ] The report is delivered to the named recipients.
- [ ] Every finding has a severity, evidence band, business impact, and remediation.
- [ ] The remediation roadmap sequences the fixes (quick wins first).
- [ ] Re-test is scheduled/completed; fixed findings are Verified-Closed.
- [ ] Evidence is retained/purged as agreed.
