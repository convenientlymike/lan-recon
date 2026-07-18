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

- `perl` (bounded timeouts), `nc`, `curl`, `ping`, `arp`.
- macOS: `dns-sd`, `smbutil` (built in). Linux: `avahi-browse` for mDNS, `nmblookup`
  for NetBIOS — swap in as needed (the core sweep/port/banner path is portable).
- For `--jump`: SSH key access to the jump host.

### Roadmap (tools to add as engagements demand)

- `external-surface.sh` — authorized external/WAN-facing exposure check.
- `wifi-survey.sh` — read-only wireless SSID/encryption survey.
- `report-gen.sh` — inventory + findings register → formatted client report.
