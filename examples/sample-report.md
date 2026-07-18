# Sample assessment report (synthetic)

> A **fabricated** example of the client-facing report an assessment produces, so you
> can see the end deliverable. All addresses are RFC 5737 documentation IPs and all
> details are generic — this is not a real client or network. Real reports are
> confidential and delivered only to named recipients.

---

# Network Security Assessment — Example Business LLC

**Prepared by:** <practice> · **Window:** 2026-01-08 → 2026-01-10 ·
**Classification:** Confidential — Example Business LLC only

## 1. Executive summary

We assessed your office network (a ~25-device small-office network) over two days
using read-only discovery. **Overall your network is in reasonable shape — no
critical exposures.** There's no remote-desktop open to the internet, no exposed
databases, and remote access is sensibly consolidated on a VPN.

The things that matter most, in order:

1. **Your smart devices share the same network as your business computers.** A
   hacked camera or smart speaker could reach the PC that holds your files. This is
   the highest-value improvement, and it's a free setting change.
2. **There's one device on your network nobody could identify.** It should be
   physically tracked down and accounted for.
3. **Routine hardening** on the file-sharing PC, the two printers, and the office
   Mac's remote-access settings.

**Do first:** turn on your router's separate "guest" network and move the cameras,
speakers, and TVs onto it — it isolates them from your business machines in five
minutes.

## 2. Scope & method

- **In scope:** the office LAN (`192.0.2.0/24`). **Out of scope:** the tenant network
  next door, all external testing.
- **Activity level:** read-only discovery. No logins, no changes, no disruption.
- **Method:** read-only host discovery + service fingerprinting, evidence-graded
  (VERIFIED / INFERRED / UNKNOWN).
- **Honest limits:** read-only probing appears in logs but changes nothing; a guest
  network, if already enabled, could not be confirmed from our vantage; a few device
  *types* are inferred from vendor + behavior, not positively confirmed.

## 3. Asset inventory

25 devices discovered. Highlights (full inventory in the appendix):

| IP | Device | Vendor | Key services | Confidence |
|---|---|---|---|---|
| 192.0.2.1 | Router / gateway | (mesh vendor) | DNS | VERIFIED |
| 192.0.2.20 | Windows PC (file share) | Dell | SMB (445) | VERIFIED |
| 192.0.2.31 | Network printer | HP | web admin + print | VERIFIED |
| 192.0.2.40 | Office Mac (remote-managed) | Apple | SSH + Screen Sharing | VERIFIED |
| 192.0.2.61 | Security camera | (camera vendor) | cloud-only | INFERRED |
| 192.0.2.77 | **Unidentified device** | (withheld) | none (all closed) | UNKNOWN |

## 4. Findings

### [Medium] F-1 · Smart devices share the network with business computers
- **Affected:** the whole network (cameras, speakers, TVs alongside the PCs).
- **Evidence:** one flat network, no separation — **VERIFIED**.
- **Business impact:** smart devices are the most-hacked, least-updated things on any
  network. On a flat network, one compromised device can reach your file-sharing PC
  directly.
- **Remediation:** enable your router's guest network and move all smart-home /
  entertainment devices onto it. **Effort: low (a setting).**

### [Medium] F-2 · An unidentified always-on device
- **Affected:** `192.0.2.77`.
- **Evidence:** live on the network, but a hidden manufacturer and no response to any
  probe — **UNKNOWN**.
- **Business impact:** a device nobody can account for is a gap by definition. Likely
  a smart appliance, but worth confirming.
- **Remediation:** physically locate it (match it to a device on-site); remove or
  isolate it if unaccounted-for. **Effort: low.**

### [Low] F-3 · File-sharing exposed on a Windows PC
- **Affected:** `192.0.2.20`.
- **Evidence:** Windows file-sharing (SMB) reachable across the network — **VERIFIED**.
- **Business impact:** normal for a shared-files PC, but it's the highest-value target
  on the LAN and the classic ransomware path.
- **Remediation:** confirm old SMBv1 is disabled, keep Windows updated, review which
  folders are shared and with whom. **Effort: low–medium.**

### [Low] F-4 · Printer admin pages without passwords
- **Affected:** two HP printers.
- **Evidence:** printer web-admin reachable — **VERIFIED**.
- **Business impact:** printers are common footholds (default/blank admin passwords,
  old firmware) and can leak documents.
- **Remediation:** set an admin password on each printer, update firmware. **Effort: low.**

## 5. Positive observations

- ✅ **No remote-desktop or databases exposed to the internet** — the most common
  serious SMB exposures are absent here.
- ✅ **Remote access is consolidated on a VPN**, not scattered port-forwards — better
  than most small businesses.

## 6. Remediation roadmap

| # | Action | Finding | Effort | Priority |
|---|---|---|---|---|
| 1 | Enable guest network; move smart devices onto it | F-1 | Low | **First** |
| 2 | Physically identify the unknown device | F-2 | Low | **First** |
| 3 | Set admin passwords + update firmware on printers | F-4 | Low | Quick win |
| 4 | Confirm SMBv1 off + review shares on the file PC | F-3 | Low–Med | Soon |

## 7. Re-test

After you've made the changes, I'll re-check each item and confirm it's closed.

| Finding | Fix applied | Re-test | Status |
|---|---|---|---|
| F-1 | Guest network enabled, devices moved | pending | Open |

---

*Delivered only to the named recipients. Raw evidence retained per our agreement and
available on request. Generated with the [lan-recon](https://github.com/convenientlymike/lan-recon)
methodology + toolkit.*
