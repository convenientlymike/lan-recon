# Remediation Checklist — <Client>

A do-this-first action list, ordered so the client gets the most risk reduction for
the least effort up front. Each item links back to a finding and closes with a
re-test.

## Quick wins (a setting change — do these first)

- [ ] **<action>** — closes <finding ID>. _How:_ <steps>. _Re-test:_ <what proves it closed>.
- [ ] **<action>** — closes <finding ID>. _How:_ <steps>. _Re-test:_ <…>.

## Soon (low–medium effort)

- [ ] **<action>** — <finding ID> — <steps> — _Re-test:_ <…>.

## Projects (planning / hardware / budget)

- [ ] **<action>** — <finding ID> — <steps> — _Re-test:_ <…>.

---

## Standard SOHO/SMB remediation reference

Reusable "how to close it" steps for the common finding classes:

### Remote access (RDP / VNC / SSH)
- [ ] Never port-forward RDP to the internet; put remote access behind a VPN (e.g.
      Tailscale/WireGuard) or an identity-gated tunnel.
- [ ] Strong credentials; **key-only** for SSH; MFA where supported.
- [ ] Disable the service on hosts that don't need it.

### Default / weak credentials
- [ ] Change every default admin password — router, printers, cameras, NAS.
- [ ] Use unique, strong passwords (a password manager for the business).

### Segmentation
- [ ] Enable the guest/IoT network; move cameras, speakers, TVs, smart-home, and any
      unidentified device off the business LAN.
- [ ] Keep the POS / accounting / file-server on the trusted segment only.

### Printers / IoT
- [ ] Set an admin password on every printer's web console; update firmware.
- [ ] Disable unused print protocols (raw 9100 / LPD) if only IPP is used.
- [ ] Physically identify any unknown device; remove or segment it.

### Wireless
- [ ] WPA2/WPA3 with a strong PSK; separate guest SSID; disable WPS.

### Router / gateway
- [ ] Keep firmware current (or confirm auto-update).
- [ ] Strong admin/cloud-account password **+ MFA**.
- [ ] Disable UPnP unless required; close any WAN-side admin.

### Windows hosts
- [ ] Patch current; disable SMBv1; audit and restrict shares.
- [ ] Host firewall limiting SMB/RDP to only the machines that need it.

---

*A finding is only **Verified-Closed** when a re-test byproduct proves it — the same
evidence standard as discovery. "We fixed it" is not proof; the re-test is.*
