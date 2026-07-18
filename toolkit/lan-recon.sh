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
# Platform: macOS AND Linux. The probe host's OS is auto-detected and the right
# tools are used per-OS:
#   • macOS : arp · dns-sd · smbutil          (all built in)
#   • Linux : ip neigh/arp · avahi-browse · nmblookup   (install avahi-utils +
#             samba-common-bin/smbclient for full mDNS + NetBIOS coverage)
# Core deps everywhere: perl, nc, curl, ping.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ---- defaults ---------------------------------------------------------------
SUBNET=""; USE_LOCAL=0; JUMP=""; OUTDIR=""; ASSUME_YES=0; AUTHORIZED_BY=""; DRYRUN=0
DEFAULT_PORTS="22 23 53 80 81 88 111 135 139 143 161 443 445 515 548 554 587 631 \
993 995 1400 1883 2049 3000 3306 3389 5000 5001 5060 5357 5432 5900 6379 7000 \
8006 8009 8080 8081 8123 8443 9000 9100 32400 49152 62078"
PORTS="$DEFAULT_PORTS"
PROBE_OS=""     # detected: Darwin | Linux
PINGT=""        # per-OS ping timeout flag
NC_FLAGS=""     # per-OS nc connect-scan flags

# ---- helpers ----------------------------------------------------------------
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() { sed -n '2,52p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

# Run a command either locally or on the jump host. Read-only by contract.
runx() {
  # ssh -n redirects stdin from /dev/null: without it, ssh inside a `while read`
  # loop swallows the loop's stdin (the host list) and only the first host probes.
  if [ -n "$JUMP" ]; then
    perl -e 'alarm 90; exec @ARGV' ssh -n -o BatchMode=yes -o ConnectTimeout=8 "$JUMP" "$@"
  else
    perl -e 'alarm 90; exec @ARGV' bash -c "$*"
  fi
}

# Detect the probe host's OS (bounded), so the right per-OS tools are used.
detect_probe_os() {
  local os
  if [ -n "$JUMP" ]; then
    os="$(perl -e 'alarm 10; exec @ARGV' ssh -o BatchMode=yes -o ConnectTimeout=8 "$JUMP" 'uname -s' 2>/dev/null | tr -d '[:space:]')"
  else
    os="$(uname -s 2>/dev/null | tr -d '[:space:]')"
  fi
  case "$os" in Linux) echo Linux ;; *) echo Darwin ;; esac
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
  PROBE_OS="$(detect_probe_os)"
  if [ "$PROBE_OS" = Darwin ]; then
    LOCAL_IP="$(runx 'ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null' 2>/dev/null || true)"
  else
    LOCAL_IP="$(runx 'hostname -I 2>/dev/null | cut -d" " -f1' 2>/dev/null || true)"
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
  if [ "$PROBE_OS" = Darwin ]; then
    runx "for i in \$(seq 1 254); do (ping -c1 -t1 ${BASE}.\$i >/dev/null 2>&1) & done; wait; arp -an 2>/dev/null" \
      > "$OUTDIR/evidence/arp.txt" 2>/dev/null || true
    grep "(${BASE}." "$OUTDIR/evidence/arp.txt" 2>/dev/null | grep -vi incomplete \
      | sed -E 's/.*\(([0-9.]+)\) at ([0-9a-f:]+).*/\1 \2/' \
      | awk 'NF==2 && $2 ~ /:/{print}' | sort -t. -k4 -n -u > "$OUTDIR/evidence/hosts.txt" || true
  else
    runx "for i in \$(seq 1 254); do (ping -c1 -W1 ${BASE}.\$i >/dev/null 2>&1) & done; wait; ip neigh show 2>/dev/null || arp -n 2>/dev/null" \
      > "$OUTDIR/evidence/arp.txt" 2>/dev/null || true
    # ip neigh: "IP dev IF lladdr MAC STATE"  ·  arp -n: "IP ether MAC C IF"
    awk '/lladdr/{print $1, $5} / ether /{print $1, $3}' "$OUTDIR/evidence/arp.txt" 2>/dev/null \
      | grep "^${BASE}\." | awk 'NF==2 && $2 ~ /:/{print}' | sort -t. -k4 -n -u > "$OUTDIR/evidence/hosts.txt" || true
  fi
  local n; n="$(wc -l < "$OUTDIR/evidence/hosts.txt" | tr -d ' ')"
  echo "  found $n live host(s)."
}

probe_host() {
  local ip="$1" mac="$2"
  local f="$OUTDIR/evidence/host-${ip//./_}.txt"
  # netbios is bounded (perl alarm) — smbutil/nmblookup can hang on non-responders.
  local nb
  if [ "$PROBE_OS" = Darwin ]; then nb="perl -e 'alarm 6; exec @ARGV' smbutil status -a $ip"
  else nb="perl -e 'alarm 6; exec @ARGV' nmblookup -A $ip"; fi
  # ONE bundled ssh per host (not 6) with a PARALLEL port scan — cuts a filtered
  # host from ~90s to a few seconds and keeps the ssh connection count sane.
  # (MAC-vendor lookup is a separate deduped+throttled pass — see lookup_vendors.)
  # ONE bundled ssh per host with a PARALLEL port scan; the remaining probes run
  # sequentially inside that one connection (bundling 6 ssh→1 is the big win). NB:
  # do NOT also parallelize these — combined with 8 concurrent hosts it overloads
  # the probe host with hundreds of simultaneous procs and gets slower, not faster.
  runx "
    echo '### $ip ($mac)'
    echo '-- open ports --'; for p in $PORTS; do (nc $NC_FLAGS $ip \$p 2>/dev/null && echo OPEN \$p) & done; wait
    echo '-- http banner --'; curl -skI --max-time 3 http://$ip/ 2>/dev/null | grep -iE 'server:|location:'
    echo '-- ssh banner --'; nc -w2 $ip 22 </dev/null 2>/dev/null | head -1
    echo '-- netbios/smb --'; $nb 2>&1 | head -6
    echo '-- ttl --'; ping -c1 $PINGT $ip 2>/dev/null | grep -oE 'ttl=[0-9]+' | head -1
  " > "$f" 2>/dev/null || true
  echo "  probed $ip"
}

# Resolve MAC vendors in ONE deduped + throttled pass (unique OUIs only) so the
# free api.macvendors.com rate limit isn't tripped by parallel per-host lookups.
lookup_vendors() {
  echo "→ resolving MAC vendors (deduped by OUI, throttled)…"
  : > "$OUTDIR/evidence/vendors.tsv"
  local oui vendor
  awk '{print $2}' "$OUTDIR/evidence/hosts.txt" | awk -F: '{print $1":"$2":"$3}' | sort -u \
  | while read -r oui; do
      [ -n "$oui" ] || continue
      vendor="$(runx "curl -s --max-time 5 https://api.macvendors.com/$oui 2>/dev/null" 2>/dev/null || true)"
      case "$vendor" in ''|'{'*|*errors*|*Please*|*Not\ Found*) vendor="" ;; esac
      printf '%s\t%s\n' "$oui" "$vendor" >> "$OUTDIR/evidence/vendors.tsv"
      sleep 1   # stay under the free-tier rate limit (~2 req/s)
    done
}

enumerate_mdns() {
  echo "→ [3/4] mDNS/Bonjour service enumeration (read-only browse)…"
  if [ "$PROBE_OS" = Darwin ]; then
    runx "( dns-sd -B _services._dns-sd._udp local. > /tmp/bj_types.\$\$ 2>&1 & P=\$!; sleep 6; kill \$P 2>/dev/null ); \
          sort -u /tmp/bj_types.\$\$ | grep -E '_tcp|_udp'; rm -f /tmp/bj_types.\$\$" \
      > "$OUTDIR/evidence/mdns-types.txt" 2>/dev/null || true
  else
    runx "avahi-browse -atp 2>/dev/null | awk -F';' '/^\\+/{print \$5}' | sort -u" \
      > "$OUTDIR/evidence/mdns-types.txt" 2>/dev/null || true
  fi
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
    echo "- **Probe source:** ${JUMP:-local} (${PROBE_OS})"
    echo "- **Authorized by:** ${AUTHORIZED_BY:-<interactive>}"
    echo "- **Live hosts:** $n"
    echo "- **Method:** read-only (ping · ARP · TCP connect-probe · banner · mDNS · OUI)"
    echo ""
    echo "> Evidence-graded per ../methodology/honesty-banding.md. Raw per-host"
    echo "> evidence is in ./evidence/ (gitignored). This is the working inventory;"
    echo "> promote to a client report via ../templates/assessment-report.md"
    echo "> (or run report-gen.sh)."
    echo ""
    echo "| IP | MAC | Vendor (OUI) | Open ports | Name | Notes |"
    echo "|---|---|---|---|---|---|"
    while read -r ip mac; do
      [ -n "$ip" ] || continue
      local f="$OUTDIR/evidence/host-${ip//./_}.txt"
      local ports vendor name oui
      ports="$(grep '^OPEN ' "$f" 2>/dev/null | awk '{print $2}' | paste -sd, - 2>/dev/null || true)"
      oui="$(printf '%s' "$mac" | awk -F: '{print $1":"$2":"$3}')"
      vendor="$(grep -F "$oui	" "$OUTDIR/evidence/vendors.tsv" 2>/dev/null | head -1 | cut -f2 | cut -c1-30 || true)"
      name="$(grep -iE 'UNIQUE|Workstation|<20>|<00>' "$f" 2>/dev/null | head -1 | awk '{print $1}' || true)"
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

  have perl || die "perl required (for bounded timeouts)"
  [ -n "$PROBE_OS" ] || PROBE_OS="$(detect_probe_os)"
  if [ "$PROBE_OS" = Darwin ]; then PINGT="-t1"; NC_FLAGS="-z -G2 -w2"; else PINGT="-W1"; NC_FLAGS="-z -w2"; fi
  echo "→ probe host OS: $PROBE_OS"

  mkdir -p "$OUTDIR/evidence"
  sweep_and_arp
  echo "→ [2/4] per-host fingerprint (read-only, batched)…"
  local running=0
  while read -r ip mac; do
    [ -n "$ip" ] || continue
    probe_host "$ip" "$mac" &
    running=$((running + 1))
    if [ "$running" -ge 8 ]; then wait; running=0; fi
  done < "$OUTDIR/evidence/hosts.txt"
  wait
  lookup_vendors
  enumerate_mdns
  build_report
  echo ""
  echo "✓ done. Inventory: $OUTDIR/inventory.md   (raw evidence in $OUTDIR/evidence/)"
}
main
