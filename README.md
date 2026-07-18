<div align="center">

# 🛰️ lan-recon

### Read-only LAN discovery & asset inventory — authorization-gated, evidence-graded.

A non-intrusive network reconnaissance tool and assessment methodology for
**authorized** security work. It maps every device on a network, fingerprints each
by service/banner/mDNS/vendor, and emits an **evidence-graded** inventory — and it
**refuses to run** until you affirm you're authorized to assess the target.

Two disciplines baked in by construction: it **never presents a guess as a fact**
(every finding is banded `VERIFIED` / `INFERRED` / `UNKNOWN`), and it **never sends
a state-changing packet** (read-only banner-grabbing only).

[![CI](https://github.com/convenientlymike/lan-recon/actions/workflows/ci.yml/badge.svg)](https://github.com/convenientlymike/lan-recon/actions/workflows/ci.yml)
&nbsp;
![License: MIT](https://img.shields.io/badge/License-MIT-22d3ee.svg)
&nbsp;
![Shell: Bash](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)
&nbsp;
![ShellCheck](https://img.shields.io/badge/lint-shellcheck-89e051.svg)
&nbsp;
![Posture: read--only](https://img.shields.io/badge/posture-read--only-16a34a.svg)
&nbsp;
![Authorization: gated](https://img.shields.io/badge/authorization-gated-a855f7.svg)

</div>

---

## Why

Most networks have never been inventoried. Nobody knows the full list of what's
connected — the decade of accumulated devices, the forgotten smart-plug, the
unknown always-on box in the closet. You can't secure what you can't see.

`lan-recon` produces that list — completely, and **honestly.** The "honestly" is the
point: anyone can paste a scanner's raw output; the value is telling you which lines
are *proven*, which are *inferred*, and which are *unknown* — and being right about
it. And it does this without ever logging in, writing, or disrupting a thing.

It ships with the full **assessment methodology** behind it, so the tool's output
becomes a repeatable engagement, not a one-off dump.

---

## What it looks like

```
$ ./lan-recon.sh --subnet 192.168.1.0/24 --jump user@onsite-box

  ╔══════════════════════════════════════════════════════════════════════╗
  ║  AUTHORIZATION REQUIRED — read AUTHORIZATION.md                        ║
  ║  This tool sends real (read-only) probe traffic to every host on the   ║
  ║  target subnet. Proceed ONLY with the owner's written, scoped consent. ║
  ╚══════════════════════════════════════════════════════════════════════╝

  To confirm you are authorized, re-type the target subnet (192.168.1.0/24): ▉

→ [1/4] host sweep + ARP …            found 14 live host(s).
→ [2/4] per-host fingerprint …        probed 14
→ [3/4] mDNS/Bonjour enumeration …    service types captured.
→ [4/4] assembling report …           → recon-192_168_1-…/inventory.md
```

…and the inventory it produces (evidence-graded — see [a full sample](examples/sample-inventory.md)):

| IP | Device | Vendor | Open ports | Name | Band |
|---|---|---|---|---|---|
| 192.0.2.1 | Router / gateway | (router vendor) | 53 (DNS) | — | 🟢 VERIFIED |
| 192.0.2.20 | Windows workstation | Dell | 135, 139, 445 | `WS-01` | 🟢 VERIFIED |
| 192.0.2.31 | Network printer | HP | 80, 443, 515, 631, 9100 | `PRN-…` | 🟢 VERIFIED |
| 192.0.2.44 | IoT / smart-home | Samsung | none (cloud-tethered) | — | 🟡 INFERRED |
| 192.0.2.77 | **Unidentifiable device** | (withheld OUI) | none (all closed) | — | ⚪ UNKNOWN |

---

## ✨ Features

**Discovery & identification**
- 🧹 **Host sweep + ARP** — bounded ping sweep populates the neighbor table; live
  hosts extracted as `ip mac` pairs.
- 🔎 **Per-host fingerprint** — read-only TCP connect-probe of a curated port set,
  HTTP/SSH banners, anonymous NetBIOS/SMB status, MAC-vendor lookup, TTL OS-hint.
- 📡 **mDNS/Bonjour enumeration** — the richest identity signal on Apple/IoT-heavy
  networks (device names, models, roles).

**Discipline (the differentiators)**
- 🟢 **Evidence-graded** — every claim banded `VERIFIED` (a byproduct proved it),
  `INFERRED` (indirect signal), or `UNKNOWN`. Never a guess dressed as a fact.
- 🔒 **Read-only by construction** — only ping, ARP, connect-probes, banner reads,
  mDNS browse, anonymous status, vendor lookup. No logins, writes, or auth attempts.
- 🛑 **Authorization-gated** — refuses to run until scope is affirmed (interactive
  re-type of the subnet, or `--yes` + a recorded `--authorized-by`).
- ⏱️ **Bounded** — every probe is timeout-wrapped; nothing loops or hangs.
- 🎯 **Never hardcoded** — subnet, jump host, output dir, and port list are all
  parameters. Point it at any network (you're authorized to assess).

**Beyond the tool**
- 🧭 A complete four-phase **assessment methodology** (scope → discover → assess →
  report), framework-aligned (NIST SP 800-115 / PTES) but right-sized for SMBs.
- 📋 **Templates** — engagement authorization, assessment report, findings register,
  remediation checklist.
- 📚 A **research knowledge base** of the SOHO/SMB vulnerability classes that
  actually bite small businesses.

---

## ▶️ Try it

No target and no risk — see exactly what it *would* do:

```bash
git clone https://github.com/convenientlymike/lan-recon.git && cd lan-recon
./toolkit/lan-recon.sh --subnet 192.168.1.0/24 --dry-run
```

Then, **on a network you are authorized to assess**, run it for real:

```bash
# interactive — prompts to confirm the in-scope subnet + who authorized it
./toolkit/lan-recon.sh --subnet <your-subnet>/24

# or probe from an on-site jump host over SSH
./toolkit/lan-recon.sh --subnet <subnet>/24 --jump user@onsite-box
```

> ⚠️ **Only assess networks you own or have written authorization to test.** Read
> [`AUTHORIZATION.md`](AUTHORIZATION.md) first. Read-only ≠ invisible: probe traffic
> appears in logs/IDS and must be covered by authorization.

---

## 🧭 The methodology

The tool is Phase 2 of a four-phase assessment:

```
1. SCOPE & AUTHORIZE   → written scope, rules of engagement, owner consent
2. DISCOVER & INVENTORY→ enumerate every host, identify it, map the topology   ← lan-recon.sh
3. ASSESS VULNERABILITY→ find exposed/misconfigured/unpatched surface, rank by risk
4. REPORT & REMEDIATE  → prioritized report, remediation plan, re-test to green
```

Full guides in [`methodology/`](methodology/) · evidence standard in
[`methodology/honesty-banding.md`](methodology/honesty-banding.md).

---

## 🔒 The ethos

Two rules make the difference between a scanner and a professional assessment, and
both are enforced here — one by a forcing function, one by construction:

1. **Authorization first.** Security tooling is dual-use; the same probe is a
   service when the owner asked and a crime when they didn't. The tool's
   authorization gate makes affirming scope a step you can't skip. See
   [`AUTHORIZATION.md`](AUTHORIZATION.md).
2. **Honesty-banding.** A finding built on a guess is worse than no finding. Every
   observation is graded by evidence, and the report says so, out loud, next to the
   claim. See [`methodology/honesty-banding.md`](methodology/honesty-banding.md).

---

## 🛠 Usage

| Flag | Meaning |
|---|---|
| `--subnet CIDR` | Target /24 (required unless `--local`). |
| `--local` | Derive the /24 from the probe machine's primary interface. |
| `--jump USER@HOST` | Run all probes from this SSH jump host. |
| `--out DIR` | Output directory (default `./recon-<subnet>-<stamp>`). |
| `--ports "a b c"` | Override the probed TCP port list. |
| `--authorized-by NAME` | Record who authorized the scope (required with `--yes`). |
| `--yes` | Skip the interactive confirmation (needs `--authorized-by`). |
| `--dry-run` | Print the plan; probe nothing. |
| `-h`, `--help` | Help. |

Full toolkit docs: [`toolkit/README.md`](toolkit/README.md).

---

## 📁 What's inside

```
lan-recon/
├── toolkit/          # lan-recon.sh + docs  (the read-only tool)
├── methodology/      # the four-phase assessment methodology + honesty-banding
├── templates/        # authorization · report · findings register · remediation
├── research/         # SOHO/SMB vulnerability-class knowledge base
├── examples/         # a sanitized sample inventory (what the tool produces)
└── AUTHORIZATION.md  # the rules-of-engagement doctrine
```

---

## 💻 Supported OS

- **macOS** — first-class (uses `arp`, `dns-sd`, `smbutil`, all built in).
- **Linux** — the core sweep/port/banner path is portable; swap `avahi-browse` for
  mDNS and `nmblookup` for NetBIOS. (See inline notes in the script.)

Requires `perl` (bounded timeouts), `nc`, `curl`, `ping`, `arp`.

---

## 🔐 Security & responsible use

This is a tool for **authorized** assessment only. See [`SECURITY.md`](SECURITY.md)
and [`AUTHORIZATION.md`](AUTHORIZATION.md). Using it against networks you do not own
or lack written permission to test may be illegal.

## 🤝 Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). New device fingerprints, Linux-portability
patches, and methodology refinements are especially welcome.

## 📄 License

[MIT](LICENSE) © convenientlymike

<div align="center"><sub>Map what's there. Prove what you claim. Change nothing.</sub></div>
