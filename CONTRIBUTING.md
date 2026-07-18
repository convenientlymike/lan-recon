# Contributing

Thanks for your interest. `lan-recon` values two things above all: it stays
**read-only** and it stays **honest** (evidence-graded). Contributions that uphold
both are very welcome.

## Ground rules

1. **Read-only stays read-only.** No contribution may add a login attempt, a write,
   an auth/credential guess, an exploit, or any state-changing / volumetric traffic
   to the core discovery path. Active-testing capability, if ever added, must be a
   clearly separate, off-by-default, explicitly-authorized module — never folded
   into the default read-only flow.
2. **Everything bounded.** Any new probe must have a timeout; nothing may loop or
   hang unbounded.
3. **Never hardcode a target.** Subnets, hosts, jump hosts, and ports are always
   parameters — never baked into logic.
4. **Honesty-banding is preserved.** New identification logic must grade its output
   `VERIFIED` / `INFERRED` / `UNKNOWN` per
   [`methodology/honesty-banding.md`](methodology/honesty-banding.md). Don't promote
   a guess to a fact.

## High-value contributions

- **New device fingerprints** — a port pattern + OUI + behavior that pins a device
  class, with the evidence band it earns.
- **Linux portability** — the core sweep/port/banner path is portable; mDNS
  (`avahi-browse`) and NetBIOS (`nmblookup`) need Linux equivalents.
- **Methodology refinements** — improvements to the four-phase process or the
  vulnerability-class knowledge base.

## Development

```bash
# lint (CI runs this)
shellcheck toolkit/lan-recon.sh
bash -n toolkit/lan-recon.sh

# smoke — the authorization gate + negative controls must bite
./toolkit/lan-recon.sh --subnet 192.168.1.0/24 --yes --authorized-by "me" --dry-run
./toolkit/lan-recon.sh --subnet 192.168.1.0/24 --yes --dry-run   # must FAIL (no authorizer)
./toolkit/lan-recon.sh --yes --authorized-by x --dry-run          # must FAIL (no subnet)
```

CI (shellcheck + the negative-control smoke) must be green before merge. Keep the
tool POSIX-friendly where practical and comment any macOS/Linux branch.

## Conduct

Be respectful and constructive. This is a tool for defenders; contributions should
serve authorized, defensive, and educational use.
