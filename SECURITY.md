# Security & Responsible Use

`lan-recon` is a tool for **authorized** network security assessment. This file
covers both responsible use and how to report a vulnerability in the tool itself.

## Responsible use — the one rule that matters

**Only assess networks you own or have explicit written authorization to test.**

Network reconnaissance tools are dual-use: the exact same probe is a professional
service when the network owner asked for it and a criminal act when they didn't.
Running this tool against networks without authorization may violate computer-misuse
laws (e.g. the CFAA in the US, the Computer Misuse Act in the UK, and equivalents
elsewhere).

- Read [`AUTHORIZATION.md`](AUTHORIZATION.md) before first use — it's the
  rules-of-engagement doctrine the tool is built around.
- The tool's **authorization gate** requires you to affirm scope before it runs.
  That gate is a reminder and a forcing function — it is **not** a legal
  authorization. The written consent of the network owner is.
- **Read-only ≠ invisible.** The tool sends no state-changing traffic, but its
  probes still appear in logs/IDS. Authorization must cover that traffic.

## What the tool does / does not do

- **Does:** ping, ARP, TCP connect-probes, service-banner reads, mDNS browse,
  anonymous NetBIOS status, MAC-vendor lookup — all read-only and bounded.
- **Does not:** log in, attempt credentials, write, change configuration, run
  exploits, or send volumetric/DoS-class traffic.

## Reporting a vulnerability in the tool

If you find a security issue **in this tool** (e.g. a way it could send unintended
traffic, a command-injection in argument handling, or a way the authorization gate
could be bypassed unintentionally):

- Please open a **private** report via GitHub Security Advisories
  (**Security → Report a vulnerability**) on this repository, or contact the
  maintainer directly rather than opening a public issue.
- Include the version/commit, the platform, and a minimal reproduction.

We aim to acknowledge reports promptly and fix confirmed issues in a timely manner.

## Supported versions

This is an actively-maintained single-branch project; fixes land on `main`.
