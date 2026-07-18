#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# lan-recon.sh — read-only LAN discovery + asset inventory
#
# Non-intrusive network reconnaissance for authorized security assessments.
# Enumerates live hosts, fingerprints each by service/banner/mDNS/OUI, and emits
# an evidence-graded Markdown inventory + raw evidence files.
#
# GUARANTEES (by construction):
#   • READ-ONLY  — ping, ARP, TCP connect-probes, banner reads, mDNS browse,
#                  anonymous NetBIOS status, MAC-vendor lookup. No logins, no
#                  writes, no auth attempts, no state-changing traffic.
#   • BOUNDED    — every probe has a timeout; nothing loops or hangs unbounded.
#   • NEVER HARDCODED — the target subnet, jump host, and output dir are all
#                  parameters. No target is ever baked into the logic.
#   • AUTHORIZATION-GATED — refuses to run until scope is affirmed (forcing fn).
#
# See ../AUTHORIZATION.md before every use. Read-only ≠ invisible: this traffic
# appears in logs/IDS and must be covered by the engagement's authorization.
#
# Usage:
#   lan-recon.sh --subnet 192.168.1.0/24 [options]
#   lan-recon.sh --local                 [options]   # derive subnet from this host
#
# Options:
#   --subnet CIDR        target /24 (e.g. 192.168.1.0/24). Required unless --local.
#   --local              derive the /24 from this machine's primary interface.
#   --jump USER@HOST     run all probes FROM this SSH jump host (e.g. an on-site
#                        box). Omit to run locally.
#   --out DIR            output directory (default: ./recon-<subnet>-<stamp>).
#   --ports "a b c"      space-separated TCP port list to probe (default below).
#   --authorized-by NAME record who authorized this scope (required with --yes).
#   --yes                skip the interactive scope confirmation (needs --authorized-by).
#   --dry-run            print the plan; probe nothing.
#   -h | --help          this help.
#
# Platform: macOS-first (uses `arp`, `dns-sd`, `smbutil`); Linux notes inline.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ---- defaults ---------------------------------------------------------------
SUBNET=""; USE_LOCAL=0; JUMP=""; OUTDIR=""; ASSUME_YES=0; AUTHORIZED_BY=""; DRYRUN=0
DEFAULT_PORTS="22 23 53 80 81 88 111 135 139 143 161 443 445 515 548 554 587 631 \
993 995 1400 1883 2049 3000 3306 3389 5000 5001 5060 5357 5432 5900 6379 7000 \
8006 8009 8080 8081 8123 8443 9000 9100 32400 49152 62078"
PORTS="$DEFAULT_PORTS"

# ---- helpers ----------------------------------------------------------------
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() { sed -n '2,45p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

# Run a command either locally or on the jump host. Read-only by contract.
runx() {
  if [ -n "$JUMP" ]; then
    perl -e 'alarm 90; exec @ARGV' ssh -o BatchMode=yes -o ConnectTimeout=8 "$JUMP" "$@"
  else
    perl -e 'alarm 90; exec @ARGV' bash -c "$*"
  fi
}

# ---- arg parse --------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --subnet) SUBNET="${2:-}"; shift 2 ;;
    --local) USE_LOCAL=1; shift ;;
    --jump) JUMP="${2:-}"; shift 2 ;;
    --out) OUTDIR="${2:-}"; shift 2 ;;
    --ports) PORTS="${2:-}"; shift 2 ;;
    --authorized-by) AUTHORIZED_BY="${2:-}"; shift 2 ;;
    --yes) ASSUME_YES=1; shift ;;
    --dry-run) DRYRUN=1; shift ;;
    -h|--help) usage ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
done

# ---- resolve the subnet (never hardcoded; explicit or derived) --------------
if [ "$USE_LOCAL" = 1 ]; then
  if [ -n "$JUMP" ]; then
    LOCAL_IP="$(runx 'ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null')"
  else
    LOCAL_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"
  fi
  [ -n "${LOCAL_IP:-}" ] || die "--local: could not derive a local IPv4 (specify --subnet)"
  SUBNET="$(echo "$LOCAL_IP" | awk -F. '{print $1"."$2"."$3".0/24"}')"
  echo "→ derived subnet from local interface: $SUBNET (from $LOCAL_IP)"
fi
[ -n "$SUBNET" ] || die "no target: pass --subnet CIDR or --local"

# parse the /24 base
BASE="$(echo "$SUBNET" | sed -E 's#\.[0-9]+/[0-9]+$##; s#/[0-9]+$##')"
echo "$BASE" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' || die "only /24 subnets are supported (got: $SUBNET)"

STAMP="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo run)"
[ -n "$OUTDIR" ] || OUTDIR="./recon-${BASE//./_}-${STAMP}"

# ---- AUTHORIZATION GATE (forcing function) ----------------------------------
authorization_gate() {
  cat <<BANNER

  ╔══════════════════════════════════════════════════════════════════════╗
  ║  AUTHORIZATION REQUIRED — read ../AUTHORIZATION.md                     ║
  ║                                                                        ║
  ║  This tool sends real (read-only) probe traffic to every host on the   ║
  ║  target subnet. Running it against a network you are not authorized    ║
  ║  to assess may be illegal. Proceed ONLY with the owner's written,      ║
  ║  scoped consent.                                                       ║
  ╚══════════════════════════════════════════════════════════════════════╝

  Target subnet : ${BASE}.0/24
  Probe source  : ${JUMP:-this machine (local)}
  Output dir    : ${OUTDIR}

BANNER
  if [ "$ASSUME_YES" = 1 ]; then
    [ -n "$AUTHORIZED_BY" ] || die "--yes requires --authorized-by \"<name/role>\""
    echo "  Authorization affirmed (non-interactive) by: $AUTHORIZED_BY"
    return 0
  fi
  printf '  To confirm you are authorized to assess this network,\n  re-type the target subnet base (%s): ' "${BASE}.0/24"
  read -r CONFIRM
  [ "$CONFIRM" = "${BASE}.0/24" ] || die "scope not confirmed — aborting"
  printf '  Who authorized this scope? '; read -r AUTHORIZED_BY
  [ -n "$AUTHORIZED_BY" ] || die "authorization signer required — aborting"
}

# ---- phases -----------------------------------------------------------------
sweep_and_arp() {
  echo "→ [1/4] host sweep + ARP (populating neighbor table, read-only)…"
  runx "for i in \$(seq 1 254); do (ping -c1 -t1 ${BASE}.\$i >/dev/null 2>&1) & done; wait; \
        arp -an 2>/dev/null | grep '(${BASE}.' | grep -vi incomplete" \
    > "$OUTDIR/evidence/arp.txt" 2>/dev/null || true
  # extract "ip mac" pairs
  sed -E 's/^.*\(([0-9.]+)\) at ([0-9a-f:]+).*/\1 \2/' "$OUTDIR/evidence/arp.txt" \
    | grep -E '^[0-9]' | sort -t. -k4 -n > "$OUTDIR/evidence/hosts.txt" || true
  local n; n="$(wc -l < "$OUTDIR/evidence/hosts.txt" | tr -d ' ')"
  echo "  found $n live host(s)."
}

probe_host() {
  local ip="$1" mac="$2"
  local f="$OUTDIR/evidence/host-${ip//./_}.txt"
  {
    echo "### $ip ($mac)"
    echo "-- open ports --"
    runx "for p in $PORTS; do nc -z -G2 -w2 $ip \$p 2>/dev/null && echo OPEN \$p; done" 2>/dev/null || true
    echo "-- http banner --"
    runx "curl -skI --max-time 3 http://$ip/ 2>/dev/null | tr -d '\r' | grep -iE 'server:|location:'" 2>/dev/null || true
    echo "-- ssh banner --"
    runx "nc -w2 $ip 22 </dev/null 2>/dev/null | head -1" 2>/dev/null || true
    echo "-- netbios/smb --"
    runx "smbutil status -a $ip 2>&1 | head -5" 2>/dev/null || true
    echo "-- mac vendor --"
    runx "curl -s --max-time 4 https://api.macvendors.com/$mac 2>/dev/null" 2>/dev/null || true
    echo ""
    echo "-- ttl --"
    runx "ping -c1 -t1 $ip 2>/dev/null | grep -oE 'ttl=[0-9]+' | head -1" 2>/dev/null || true
    echo ""
  } > "$f" 2>/dev/null || true
  echo "  probed $ip"
}

enumerate_mdns() {
  echo "→ [3/4] mDNS/Bonjour service enumeration (read-only browse)…"
  runx "( dns-sd -B _services._dns-sd._udp local. > /tmp/bj_types.\$\$ 2>&1 & P=\$!; sleep 6; kill \$P 2>/dev/null ); \
        sort -u /tmp/bj_types.\$\$ | grep -E '_tcp|_udp'; rm -f /tmp/bj_types.\$\$" \
    > "$OUTDIR/evidence/mdns-types.txt" 2>/dev/null || true
  echo "  mDNS service types captured."
}

build_report() {
  echo "→ [4/4] assembling report…"
  local rpt="$OUTDIR/inventory.md" n
  n="$(wc -l < "$OUTDIR/evidence/hosts.txt" | tr -d ' ')"
  {
    echo "# LAN Inventory — ${BASE}.0/24"
    echo ""
    echo "- **Assessed:** $STAMP"
    echo "- **Probe source:** ${JUMP:-local}"
    echo "- **Authorized by:** ${AUTHORIZED_BY:-<interactive>}"
    echo "- **Live hosts:** $n"
    echo "- **Method:** read-only (ping · ARP · TCP connect-probe · banner · mDNS · OUI)"
    echo ""
    echo "> Evidence-graded per ../methodology/honesty-banding.md. Raw per-host"
    echo "> evidence is in ./evidence/ (gitignored). This is the working inventory;"
    echo "> promote to a client report via ../templates/assessment-report.md."
    echo ""
    echo "| IP | MAC | Vendor (OUI) | Open ports | Name | Notes |"
    echo "|---|---|---|---|---|---|"
    while read -r ip mac; do
      [ -n "$ip" ] || continue
      local f="$OUTDIR/evidence/host-${ip//./_}.txt"
      local ports vendor name
      ports="$(grep '^OPEN ' "$f" 2>/dev/null | awk '{print $2}' | paste -sd, - 2>/dev/null || true)"
      vendor="$(grep -A1 'mac vendor' "$f" 2>/dev/null | tail -1 | cut -c1-30 || true)"
      name="$(grep -iE 'UNIQUE|Workstation' "$f" 2>/dev/null | head -1 | awk '{print $1}' || true)"
      echo "| $ip | $mac | ${vendor:-—} | ${ports:-—} | ${name:-—} | |"
    done < "$OUTDIR/evidence/hosts.txt"
    echo ""
    echo "_Fingerprints are raw; apply the honesty-banding standard when writing the"
    echo "client report — an open port is not a confirmed service until the banner says so._"
  } > "$rpt"
  echo "  → $rpt"
}

# ---- main -------------------------------------------------------------------
main() {
  authorization_gate

  if [ "$DRYRUN" = 1 ]; then
    echo ""; echo "DRY RUN — would probe ${BASE}.1-254 from ${JUMP:-local}, ports: $PORTS"
    echo "would write to: $OUTDIR"; exit 0
  fi

  mkdir -p "$OUTDIR/evidence"
  have perl || die "perl required (for bounded timeouts)"
  sweep_and_arp
  echo "→ [2/4] per-host fingerprint (read-only)…"
  while read -r ip mac; do [ -n "$ip" ] && probe_host "$ip" "$mac"; done < "$OUTDIR/evidence/hosts.txt"
  enumerate_mdns
  build_report
  echo ""
  echo "✓ done. Inventory: $OUTDIR/inventory.md   (raw evidence in $OUTDIR/evidence/)"
}
main
