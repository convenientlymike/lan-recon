# Toolkit

Reusable, **read-only**, parameterized assessment tooling. Nothing here logs in,
writes, or changes state on a target — by construction. Every tool is bounded (no
unbounded scans or hangs) and takes its target as a **parameter** (never hardcoded
— a tool that assumes one network is a latent bug the first time it's pointed at a
second one).

---

## `lan-recon.sh` — LAN discovery + asset inventory

Non-intrusive network reconnaissance: enumerate every live host on a subnet,
fingerprint each by open ports / service banners / mDNS / MAC-vendor, and emit an
evidence-graded Markdown inventory plus raw per-host evidence.

### What it does (the Phase-2 technique ladder, automated)

1. **Host sweep + ARP** — a bounded ping sweep populates the neighbor table; live
   hosts are extracted as `ip mac` pairs.
2. **Per-host fingerprint** — for each host, read-only: a TCP connect-probe of a
   curated port set, an HTTP banner (`Server:`/`Location:`), an SSH banner, an
   anonymous NetBIOS/SMB status, a MAC-vendor lookup, and a TTL OS-hint.
3. **mDNS/Bonjour enumeration** — browse the advertised service types on the link
   (the richest identity signal on Apple/IoT-heavy networks).
4. **Report** — assemble the inventory table; raw evidence lands in `evidence/`.

### Guarantees (by construction)

| Guarantee | How |
|---|---|
| **Read-only** | Only ping, ARP, `nc -z` connect-probes, banner reads, `dns-sd` browse, anonymous `smbutil status`, vendor lookup. No logins/writes/auth. |
| **Bounded** | Every probe wrapped in a `perl alarm` timeout + `nc -G/-w` + `curl --max-time`. Nothing loops or hangs. |
| **Never hardcoded** | Subnet, jump host, output dir, and port list are all parameters. |
| **Authorization-gated** | Refuses to run until scope is affirmed (interactive re-type of the subnet, or `--yes` + `--authorized-by`). |

### Usage

```bash
# Interactive (prompts to confirm the in-scope subnet + who authorized it):
./lan-recon.sh --subnet 192.168.1.0/24

# Probe FROM an on-site jump host over SSH (probes originate there, not here):
./lan-recon.sh --subnet 192.168.1.0/24 --jump user@onsite-box

# Derive the /24 from the machine running the probe:
./lan-recon.sh --local --jump user@onsite-box

# Non-interactive (CI/automation) — requires recording the authorizer:
./lan-recon.sh --subnet 192.168.1.0/24 --yes --authorized-by "Jane Doe, owner"

# See the plan without probing anything:
./lan-recon.sh --subnet 192.168.1.0/24 --dry-run
```

### Options

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

### Output

```
recon-<subnet>-<stamp>/
├── inventory.md            # the evidence-graded inventory table (working record)
└── evidence/               # raw per-host probe output (GITIGNORED — local only)
    ├── arp.txt
    ├── hosts.txt           # ip mac pairs
    ├── host-<ip>.txt       # per-host ports/banners/netbios/vendor/ttl
    └── mdns-types.txt
```

### After running

The `inventory.md` is a **working record**, not the deliverable. Apply the
[honesty-banding standard](../methodology/honesty-banding.md) when writing the
client report — the raw fingerprints mark ports as open, but an open port is not a
confirmed service until the banner says so. Promote to a client report via
[`../templates/assessment-report.md`](../templates/assessment-report.md).

### Requirements

- `perl` (bounded timeouts), `nc`, `curl`, `ping`.
- **macOS:** `arp`, `dns-sd`, `smbutil` — all built in.
- **Linux:** `ip`/`arp`, plus `avahi-browse` (avahi-utils) for mDNS and `nmblookup`
  (samba-common-bin) for NetBIOS. The probe host's OS is **auto-detected** and the
  right tools are used per-OS — no flags to set.
- For `--jump`: SSH key access to the jump host.

---

## `external-surface.sh` — internet-facing exposure check

Checks what a target exposes to the **internet** — the #1 SMB breach vector
(internet-facing RDP, SMB, databases, telnet). Read-only connect-probes against a
public IP/host, each open port **risk-classified** (CRITICAL / HIGH / MEDIUM / INFO).

```bash
# check your own connection's public IP (best from an EXTERNAL vantage):
./external-surface.sh --self --jump user@cloud-host

# check a specific authorized public host:
./external-surface.sh --target vpn.example.com --jump user@cloud-host
```

⚠️ **Vantage matters.** For a true reading, probe from an **external** vantage
(`--jump user@cloud-host`) — from inside the target's own network, NAT hairpinning can
mislead. The report states which vantage was used. Same authorization gate as
`lan-recon.sh`; **your own / authorized target only.**

---

## `report-gen.sh` — assemble a client report

Turns the raw `inventory.md` + a findings register (CSV) into a scaffolded
client-facing report: it does the **mechanical** assembly (embeds the inventory,
expands each finding, builds the remediation roadmap sorted by severity) and leaves
the **human-judgment** parts (executive summary, business-impact narrative) as clearly
marked `✍️` prompts. It never fabricates judgment — a scaffold you finish.

```bash
./report-gen.sh --inventory recon-…/inventory.md \
                --findings ../templates/findings-register.csv \
                --client "Example Business LLC"
```

---

### Roadmap (tools to add as engagements demand)

- `wifi-survey.sh` — read-only wireless SSID/encryption/guest-isolation survey.
- A local IEEE OUI database option (offline, rate-limit-free MAC-vendor lookup).
