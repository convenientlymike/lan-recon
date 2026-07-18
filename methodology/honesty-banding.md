# Honesty-banding — the evidence standard

Every observation in an assessment carries a **confidence band**. This is the
single discipline that keeps a report trustworthy: it forces us to separate what we
*proved* from what we *inferred* from what we're *guessing at* — and to say so, out
loud, next to the claim. A report that bands its evidence is one a client (and their
insurer, and their auditor) can rely on.

The failure mode this prevents: identifying a device from its appearance or a single
weak signal and presenting it as fact. A screenshot is not an identity. A MAC-vendor
prefix is a hint, not a confirmation. An open port is not a running service until the
banner says so. **Read it, don't eyeball it** — and when you can only eyeball it,
band it down.

---

## The three bands

### 🟢 VERIFIED
Proven by a **byproduct at the sufficient layer** — a signal that could only be
produced by the thing being true.

- A service **banner** we read (`SSH-2.0-OpenSSH_9.6`, an HTTP `Server:` header).
- An **mDNS/Bonjour** advertisement naming the device/model/service.
- A **NetBIOS/SMB** name the host returned.
- A service **fingerprint** (a distinctive port set + response) that pins the role.

> *Example:* "192.0.2.10 is a macOS host — VERIFIED: advertises
> `_companion-link._tcp` + `_rdlink._tcp` over mDNS and returned
> `SSH-2.0-OpenSSH_9.x` on 22."

### 🟡 INFERRED
Reasoned from **indirect signal** — plausible, but not proven. Useful, but labeled.

- **MAC OUI vendor** (tells you the NIC maker, not the device or its owner — and
  randomized/locally-administered MACs tell you nothing).
- **TTL** (≈64 → *nix/Apple, ≈128 → Windows, ≈255 → network gear — a hint, spoofable).
- **DHCP hostname** or a **port pattern** without a confirming banner.

> *Example:* "192.0.2.20 is likely an IoT/smart-home device — INFERRED: OUI
> resolves to a smart-plug vendor and only 80/tcp answered; no banner confirmed it."

### ⚪ UNKNOWN
We **could not determine it.** Say so plainly. An honest "unknown" is worth more
than a confident wrong answer — it flags exactly where a follow-up (or the owner's
own knowledge) is needed.

> *Example:* "192.0.2.30 — UNKNOWN: responds to ARP (host is live) but every
> probed port was closed/filtered, no mDNS, MAC is locally-administered. Likely a
> hardened or randomized-MAC device; identity not established."

---

## Rules

1. **Never promote a band without a byproduct.** INFERRED does not become VERIFIED
   because it "seems obvious." It becomes VERIFIED when a banner/advertisement/name
   proves it.
2. **Band the headline, not just the detail.** If the inventory is 60% INFERRED,
   the report's summary says so — the reader must know the overall confidence.
3. **A guess is UNKNOWN, not a low-confidence VERIFIED.** There is no "probably
   verified." If it isn't proven, it's INFERRED or UNKNOWN.
4. **Findings inherit the weakest band in their chain.** A vulnerability claim built
   on an INFERRED device identity is at best a SUSPECTED finding — verify the
   identity (within scope) before rating it as confirmed risk.
5. **Distinguish "explicitly none" from "unrecognized."** "No services found (all
   ports closed)" is a VERIFIED observation. "We don't recognize this device" is
   UNKNOWN. They are not the same and must not be collapsed.

---

## Why it's a selling point

Anyone can run a scanner and paste its output. The value we add is telling the
client which of those 200 lines are *real*, which are *maybe*, and which are *noise*
— and being right about it. Evidence-banding is what makes the difference between a
tool's raw output and a professional's assessment.
