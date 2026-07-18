# Changelog

All notable changes to this project follow [Keep a Changelog](https://keepachangelog.com/)
and [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
