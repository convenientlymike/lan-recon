# Changelog

All notable changes to this project follow [Keep a Changelog](https://keepachangelog.com/)
and [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **Live landing page** (GitHub Pages, `docs/`) — a one-page walkthrough with the
  authorization + honesty-banding ethos and a live sample inventory, so the tool can
  be seen without cloning. Real screenshots wired into the README.
- **`external-surface.sh`** — authorized, read-only internet-facing exposure check:
  connect-probes a public target and risk-classifies each open port (CRITICAL /
  HIGH / MEDIUM / INFO), with an external-vantage caveat stated in the report.
- **`report-gen.sh`** — assembles a scaffolded client report from an inventory +
  findings CSV (mechanical assembly done; human-judgment sections flagged, not faked).
- **Real Linux support** in `lan-recon.sh` — the probe host's OS is auto-detected and
  the correct tools are used per-OS (`ip`/`arp` · `avahi-browse` · `nmblookup` on
  Linux). CI smoke now runs on ubuntu + macOS.
- A sanitized **sample client report** (`examples/sample-report.md`).

### Changed
- **`lan-recon.sh` is much faster and more correct on the `--jump` path** — bundles
  each host's probes into one SSH call (was 6) with a parallel port scan and batched
  host concurrency; MAC-vendor lookups are deduped by OUI and throttled (no more
  api.macvendors.com rate-limit errors leaking into the inventory).

### Fixed
- `--jump` runs previously probed only the first host — `ssh` inside the read loop
  swallowed the host list's stdin; fixed with `ssh -n`.
- Bounded `smbutil`/`nmblookup` (they could hang on non-responding hosts).

## [0.1.0] — 2026-07-18

### Added
- **`lan-recon.sh`** — read-only, parameterized LAN discovery + asset-inventory
  tool: bounded host sweep + ARP, per-host service/banner fingerprint, mDNS/Bonjour
  enumeration, MAC-vendor identification, and an evidence-graded Markdown report.
- **Authorization gate** — the tool refuses to run until scope is affirmed
  (interactive subnet re-type, or `--yes` + `--authorized-by`). Backed by CI
  negative-control tests that verify the gate bites.
- **Read-only by construction** — only ping, ARP, connect-probes, banner reads,
  mDNS browse, anonymous NetBIOS status, and vendor lookup. No logins/writes/auth.
- **Assessment methodology** — the four-phase process (scope → discover → assess →
  report) + the honesty-banding evidence standard (`VERIFIED` / `INFERRED` /
  `UNKNOWN`).
- **Templates** — engagement authorization, assessment report, findings register,
  remediation checklist.
- **Research knowledge base** — the SOHO/SMB vulnerability classes that matter.
- **Sample inventory** — a sanitized example of the tool's output.
- CI (ShellCheck + syntax + authorization-gate smoke), MIT license, security &
  contributing guidance.
