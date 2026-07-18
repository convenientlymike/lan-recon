# Phase 2 — Discovery & Asset Inventory

You cannot secure what you cannot see. This phase produces a **complete,
evidence-graded inventory** of every device on the in-scope network and a map of
how it's put together. It is strictly **read-only**.

The deliverable: a table where every row is a device, every device has an identity
(banded VERIFIED / INFERRED / UNKNOWN per [`honesty-banding.md`](honesty-banding.md)),
and nothing live is missing.

---

## Objectives

1. **Enumerate** every live host in scope (miss nothing).
2. **Identify** each — device type, OS, vendor, role, exposed services.
3. **Map** the topology — gateway/router, segments/VLANs, wireless, routed subnets.
4. **Grade** every claim by evidence.

---

## Technique ladder (read-only, least-intrusive first)

| Signal | How | What it tells you | Band |
|---|---|---|---|
| **Host liveness** | ICMP sweep, ARP table | which IPs are live | VERIFIED (live) |
| **MAC / OUI** | ARP → vendor lookup | NIC vendor (hint at device maker) | INFERRED |
| **Open ports** | TCP connect-probe (curated port set) | which services *might* run | VERIFIED (open) |
| **Service banner** | read the service's greeting (SSH/HTTP/SMB) | the actual service + version | VERIFIED |
| **mDNS / Bonjour** | passive service enumeration | device name, model, role (rich on Apple/IoT) | VERIFIED |
| **NetBIOS/SMB name** | anonymous name query | Windows/NAS hostname + workgroup | VERIFIED |
| **TTL** | from the ping reply | OS family hint | INFERRED |

**Always climb the ladder toward VERIFIED.** An open port is INFERRED as a service
until the banner confirms it. A MAC vendor is a hint until an advertisement names
the device. The [`../toolkit/lan-recon.sh`](../toolkit/lan-recon.sh) tool runs this
whole ladder read-only and emits the graded inventory.

---

## What NOT to do in discovery (the read-only line)

- ❌ No login attempts — not even default credentials (that's Phase 3, and it's
  separately authorized).
- ❌ No writes, no config reads that require auth, no state changes.
- ❌ No aggressive/volumetric scanning that could knock over fragile devices.
- ❌ No probing out-of-scope hosts, even ones discovered mid-sweep.

---

## Building the inventory

Every live host becomes a row:

```
IP · MAC · vendor(OUI) · device type · OS · identifying name (mDNS/NetBIOS) ·
open ports / services · confidence band · notes
```

Then **group by role** so the picture is legible:

- **Network gear** — gateway/router, switches, APs, mesh nodes
- **Computers** — servers, workstations, laptops (by OS)
- **Mobile** — phones, tablets
- **IoT / smart-home** — cameras, plugs, TVs, voice assistants, thermostats
- **Printers / NAS / media** — printers, storage, media servers
- **Unknown** — live but unidentified (explicitly, honestly)

---

## Mapping the topology

- **Gateway/router** — make/model (from its management banner, read-only — never
  log in), firmware if advertised.
- **Segments** — separate subnets, VLANs, a guest network. Is IoT segregated from
  the business LAN, or flat? (Flat is a finding.)
- **Routed subnets** — what other networks does the router expose a route to?
- **Wireless** — SSIDs, separate guest SSID, encryption (observed, not cracked).
- **Ingress** — is anything port-forwarded from the internet? (Confirm from the
  router config with the owner, or an authorized external check — don't assume.)

---

## Evidence handling

- Raw tool output → the engagement's `evidence/` folder (**gitignored**, local only).
- The graded inventory → the engagement's `findings.md` (the working record).
- Never let raw evidence (live IPs, MACs, exposed services) leak into a tracked/
  shareable layer — sanitize into the report.

---

## Exit criteria (Phase 2 is done when…)

- [ ] Every live in-scope host is enumerated (cross-checked: ARP vs. sweep vs. mDNS —
      no host appears in one and not the others without explanation).
- [ ] Each host has an identity **with a confidence band**.
- [ ] The topology (gateway, segments, wireless, routed subnets, ingress) is mapped.
- [ ] Raw evidence is saved locally; the graded inventory is written up.

The inventory is the input to Phase 3 — you can only assess the risk of assets you
have inventoried.
