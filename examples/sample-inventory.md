# Sample inventory (synthetic)

> A **fabricated** example inventory showing what `lan-recon.sh` produces, so you can
> see the output quality before running it. All IPs are in the RFC 5737
> documentation range (`192.0.2.0/24`, `198.51.100.0/24`) and all device names are
> generic — this is not a real network.

# LAN Inventory — 192.0.2.0/24

- **Assessed:** 2026-01-01 (example)
- **Probe source:** on-site jump host
- **Live hosts:** 12
- **Method:** read-only (ping · ARP · TCP connect-probe · banner · mDNS · OUI)

## Inventory (evidence-graded)

| IP | Device | Vendor (OUI) | Open ports / services | Name | Band |
|---|---|---|---|---|---|
| 192.0.2.1 | Router / gateway | (router vendor) | 53 (DNS resolver) | — | 🟢 VERIFIED |
| 192.0.2.10 | Linux server | Supermicro | 22 (OpenSSH 9.6), 443 (nginx) | `srv-01` | 🟢 VERIFIED |
| 192.0.2.20 | Windows workstation | Dell | 135, 139, **445 (SMB)**, 5357 | `WS-01` (WORKGROUP) | 🟢 VERIFIED |
| 192.0.2.21 | Windows workstation | Intel | 5357 (WSDAPI) | — | 🟢 VERIFIED |
| 192.0.2.31 | Network printer / MFP | HP | 80, 443, 515, 631, **9100** | `PRN-A` | 🟢 VERIFIED |
| 192.0.2.40 | macOS host | Apple | 22 (SSH), `_rfb` (Screen Sharing) | `mac-studio` | 🟢 VERIFIED |
| 192.0.2.50 | Streaming media player | Amazon | 8009 (Cast), 55442 | — | 🟢 VERIFIED |
| 192.0.2.55 | Cast receiver | (Cast ODM) | 8009 (Cast) | — | 🟢 VERIFIED |
| 192.0.2.60 | IoT / smart-home | Samsung | none (cloud-tethered) | — | 🟡 INFERRED |
| 192.0.2.61 | IoT camera / doorbell | (camera vendor) | none (cloud-tethered) | — | 🟡 INFERRED |
| 192.0.2.70 | Mobile (randomized MAC) | — (local MAC) | none (filtered) | — | 🟡 INFERRED |
| 192.0.2.77 | **Unidentifiable device** | (withheld OUI) | none (TTL 255, all closed) | — | ⚪ UNKNOWN |

**Overall confidence:** 8 / 12 VERIFIED (a banner, mDNS advertisement, or NetBIOS
name pinned them). The 3 INFERRED hosts are pinned by MAC vendor + closed-behavior
signature only. `192.0.2.77` is genuinely UNKNOWN — live, but a withheld OUI and a
fully-closed surface leave no way to identify it from the wire.

## How to read this

- 🟢 **VERIFIED** — a byproduct proved it (a service banner, an mDNS advertisement,
  a NetBIOS name).
- 🟡 **INFERRED** — reasoned from indirect signal (MAC vendor, TTL, port pattern).
  Vendor is solid; exact device class is a reasoned inference.
- ⚪ **UNKNOWN** — live but not identifiable from the wire. Honestly flagged, not
  guessed — this is exactly the device an assessor would recommend **physically
  identifying**.

This raw inventory is the *working record*. In a client engagement it's promoted to
a report (see [`../templates/assessment-report.md`](../templates/assessment-report.md))
with each device's exposure assessed and ranked by business risk.
