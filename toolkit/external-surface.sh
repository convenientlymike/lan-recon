#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# external-surface.sh — authorized external / internet-facing exposure check
#
# Checks what a target exposes to the INTERNET — the #1 SMB breach vector
# (internet-facing RDP, SMB, databases, telnet). Read-only connect-probes +
# banner grabs against the target's public IP, each open port risk-classified.
#
# GUARANTEES (by construction):
#   • READ-ONLY  — TCP connect-probes + banner reads only. No logins, no writes,
#                  no exploits, no volumetric traffic.
#   • BOUNDED    — every probe has a timeout; nothing loops or hangs.
#   • AUTHORIZATION-GATED — refuses to run until scope is affirmed (forcing fn).
#
# ⚠️  VANTAGE MATTERS. For a TRUE reading of internet exposure, probe from an
#     EXTERNAL vantage (`--jump user@cloud-host`) — from inside the target's own
#     network, NAT hairpinning can make the result misleading (show ports that
#     aren't actually reachable from outside, or hide ones that are). This is
#     stated in the report.
#
# ⚠️  Probing a public IP you do not own or lack written authorization to test may
#     be illegal. See ../AUTHORIZATION.md. This is for YOUR OWN or an explicitly
#     authorized target only.
#
# Usage:
#   external-surface.sh --target HOST_OR_IP  [--jump user@cloud-host] [options]
#   external-surface.sh --self               [--jump user@cloud-host] [options]
#
# Options:
#   --target HOST/IP     the public host/IP to check (required unless --self)
#   --self               detect this connection's public IP and check it
#   --jump USER@HOST     probe FROM this external vantage (recommended)
#   --out DIR            output dir (default: ./external-<target>-<stamp>)
#   --authorized-by NAME record who authorized this scope (required with --yes)
#   --yes                skip the interactive confirmation (needs --authorized-by)
#   --dry-run            print the plan; probe nothing
#   -h | --help          this help.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

TARGET=""; USE_SELF=0; JUMP=""; OUTDIR=""; ASSUME_YES=0; AUTHORIZED_BY=""; DRYRUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --self) USE_SELF=1; shift ;;
    --jump) JUMP="${2:-}"; shift 2 ;;
    --out) OUTDIR="${2:-}"; shift 2 ;;
    --authorized-by) AUTHORIZED_BY="${2:-}"; shift 2 ;;
    --yes) ASSUME_YES=1; shift ;;
    --dry-run) DRYRUN=1; shift ;;
    -h|--help) sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
done

runx() {
  if [ -n "$JUMP" ]; then
    perl -e 'alarm 60; exec @ARGV' ssh -n -o BatchMode=yes -o ConnectTimeout=8 "$JUMP" "$@"
  else
    perl -e 'alarm 60; exec @ARGV' bash -c "$*"
  fi
}

# port → "risk|service" (internet-exposure weighted)
port_meta() { case "$1" in
  23)    echo "CRITICAL|Telnet (cleartext remote shell)";;
  3389)  echo "CRITICAL|RDP (top ransomware entry vector)";;
  445)   echo "CRITICAL|SMB (file sharing — never expose to WAN)";;
  5900)  echo "CRITICAL|VNC (remote desktop)";;
  1433)  echo "CRITICAL|MSSQL database";;
  3306)  echo "CRITICAL|MySQL database";;
  5432)  echo "CRITICAL|PostgreSQL database";;
  6379)  echo "CRITICAL|Redis (often unauthenticated)";;
  9200)  echo "CRITICAL|Elasticsearch (often unauthenticated)";;
  27017) echo "CRITICAL|MongoDB (often unauthenticated)";;
  11211) echo "CRITICAL|Memcached (amplification/exposure)";;
  1521)  echo "CRITICAL|Oracle database";;
  21)    echo "HIGH|FTP (often cleartext/anonymous)";;
  135)   echo "HIGH|MSRPC (Windows — should not be on WAN)";;
  139)   echo "HIGH|NetBIOS (should not be on WAN)";;
  22)    echo "MEDIUM|SSH (fine if key-only + patched)";;
  25)    echo "MEDIUM|SMTP (check open-relay/auth)";;
  53)    echo "MEDIUM|DNS (check not an open resolver)";;
  8080)  echo "MEDIUM|HTTP-alt (often an admin panel)";;
  8443)  echo "MEDIUM|HTTPS-alt (often an admin panel)";;
  110)   echo "MEDIUM|POP3";;
  143)   echo "MEDIUM|IMAP";;
  80)    echo "INFO|HTTP (web — expected if hosting a site)";;
  443)   echo "INFO|HTTPS (web — expected if hosting a site)";;
  *)     echo "INFO|service";;
esac; }

PORTS="21 22 23 25 53 80 110 135 139 143 443 445 993 995 1433 1521 3306 3389 5432 5900 6379 8080 8443 9200 11211 27017"

# resolve target
if [ "$USE_SELF" = 1 ]; then
  TARGET="$(runx 'curl -s --max-time 6 https://api.ipify.org 2>/dev/null || curl -s --max-time 6 https://ifconfig.me 2>/dev/null' 2>/dev/null | tr -d '[:space:]' || true)"
  [ -n "$TARGET" ] || die "--self: could not detect the public IP (pass --target)"
  echo "→ detected public IP: $TARGET"
fi
[ -n "$TARGET" ] || die "no target: pass --target HOST/IP or --self"

STAMP="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo run)"
[ -n "$OUTDIR" ] || OUTDIR="./external-${TARGET//[.:]/_}-${STAMP}"

# ---- authorization gate -----------------------------------------------------
cat <<BANNER

  ╔══════════════════════════════════════════════════════════════════════╗
  ║  AUTHORIZATION REQUIRED — read ../AUTHORIZATION.md                     ║
  ║  Probing a public host you do not own or lack written permission to    ║
  ║  test may be illegal. YOUR OWN / authorized target only.               ║
  ╚══════════════════════════════════════════════════════════════════════╝

  Target        : ${TARGET}
  Probe vantage : ${JUMP:-this machine (INTERNAL — NAT hairpinning may mislead)}
  Output dir    : ${OUTDIR}

BANNER
if [ "$ASSUME_YES" = 1 ]; then
  [ -n "$AUTHORIZED_BY" ] || die "--yes requires --authorized-by \"<name/role>\""
  echo "  Authorization affirmed (non-interactive) by: $AUTHORIZED_BY"
else
  printf '  Re-type the target to confirm you are authorized (%s): ' "$TARGET"
  read -r C; [ "$C" = "$TARGET" ] || die "scope not confirmed — aborting"
  printf '  Who authorized this scope? '; read -r AUTHORIZED_BY
  [ -n "$AUTHORIZED_BY" ] || die "authorization signer required — aborting"
fi

if [ "$DRYRUN" = 1 ]; then
  echo ""; echo "DRY RUN — would connect-probe ${TARGET} on: $PORTS"
  echo "would write to: $OUTDIR"; exit 0
fi

mkdir -p "$OUTDIR"
RPT="$OUTDIR/external-surface.md"
echo "→ probing internet-facing surface of ${TARGET} (read-only)…"

open_ports=""
for p in $PORTS; do
  if runx "nc -z -w3 $TARGET $p 2>/dev/null" >/dev/null 2>&1; then
    open_ports="$open_ports $p"
    echo "  OPEN $p"
  fi
done

{
  echo "# External Surface — ${TARGET}"
  echo ""
  echo "- **Assessed:** $STAMP"
  echo "- **Vantage:** ${JUMP:-INTERNAL (NAT hairpinning may mislead — see note)}"
  echo "- **Authorized by:** ${AUTHORIZED_BY:-<interactive>}"
  echo "- **Method:** read-only TCP connect-probe of ${PORTS// /, }"
  echo ""
  if [ -z "${JUMP:-}" ]; then
    echo "> ⚠️ **Vantage caveat:** this was probed from INSIDE the network, so NAT"
    echo "> hairpinning can make the result misleading. Re-run from an EXTERNAL vantage"
    echo "> (\`--jump user@cloud-host\`) for a true reading of internet exposure."
    echo ""
  fi
  if [ -z "$open_ports" ]; then
    echo "## ✅ No probed ports are open from this vantage"
    echo ""
    echo "None of the checked internet-exposure-relevant ports responded. (Confirm from"
    echo "an external vantage; a firewall may be dropping the probe silently.)"
  else
    echo "## Exposed ports (risk-classified)"
    echo ""
    echo "| Port | Risk | Service | Note |"
    echo "|---|---|---|---|"
    for p in $open_ports; do
      meta="$(port_meta "$p")"; risk="${meta%%|*}"; svc="${meta#*|}"
      note=""; case "$risk" in CRITICAL) note="**Close this or firewall it now.**";; esac
      echo "| $p | $risk | $svc | $note |"
    done
    echo ""
    echo "### Priorities"
    for p in $open_ports; do
      meta="$(port_meta "$p")"; [ "${meta%%|*}" = CRITICAL ] && echo "- 🔴 **Port $p (${meta#*|})** — should not be reachable from the internet. Put it behind a VPN or close it."
    done
  fi
  echo ""
  echo "_Read-only external exposure check. An open port here is reachability, not a"
  echo "confirmed vulnerability — but internet-facing RDP/SMB/DB is a finding on its own._"
} > "$RPT"

echo ""
echo "✓ done → $RPT"
