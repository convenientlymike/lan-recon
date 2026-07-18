#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# report-gen.sh — assemble a client assessment report from an inventory + findings
#
# Takes the raw inventory.md that lan-recon.sh produces and a findings register
# (CSV, per ../templates/findings-register.csv) and scaffolds a client-facing
# assessment report: it does the MECHANICAL assembly (embed the inventory,
# expand each finding into a section, build the remediation roadmap sorted by
# severity) and leaves the HUMAN-JUDGMENT parts (the executive summary, the
# business-impact narrative) as clearly-marked prompts. It never fabricates
# judgment — a scaffold you finish, not a report it pretends to write.
#
# Pure text transformation. No network, no side effects beyond writing the report.
#
# Usage:
#   report-gen.sh --inventory PATH --findings PATH.csv [--client NAME] [--out PATH]
#
# Options:
#   --inventory PATH   the inventory.md from lan-recon.sh (required)
#   --findings PATH    a findings register CSV (optional; template columns)
#   --client NAME      client name for the report header (default: <Client>)
#   --out PATH         output report path (default: alongside the inventory)
#   -h | --help        this help.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

INVENTORY=""; FINDINGS=""; CLIENT="<Client>"; OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --inventory) INVENTORY="${2:-}"; shift 2 ;;
    --findings) FINDINGS="${2:-}"; shift 2 ;;
    --client) CLIENT="${2:-}"; shift 2 ;;
    --out) OUT="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
done

[ -n "$INVENTORY" ] || die "no --inventory (the inventory.md from lan-recon.sh)"
[ -f "$INVENTORY" ] || die "inventory not found: $INVENTORY"
[ -z "$FINDINGS" ] || [ -f "$FINDINGS" ] || die "findings CSV not found: $FINDINGS"
[ -n "$OUT" ] || OUT="$(dirname "$INVENTORY")/report.md"

# severity rank for sorting (lower = more urgent)
sev_rank() { case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
  critical) echo 0 ;; high) echo 1 ;; medium) echo 2 ;; low) echo 3 ;; *) echo 4 ;; esac; }

{
  echo "# Network Security Assessment — $CLIENT"
  echo ""
  echo "**Prepared by:** <your name / practice>"
  echo "**Classification:** Confidential — $CLIENT only"
  echo ""
  echo "---"
  echo ""
  echo "## 1. Executive summary"
  echo ""
  echo "> ✍️ **FINISH THIS (human judgment — do not skip):** one honest paragraph on"
  echo "> the overall posture, then the 3–5 things that matter most, in order, in"
  echo "> plain language, ending with the single highest-value action to do first."
  echo ""
  echo "## 2. Scope & method"
  echo ""
  echo "- **Scope:** <in-scope targets> · **Out of scope:** <exclusions>"
  echo "- **Activity level:** read-only discovery (state per the authorization)."
  echo "- **Method:** read-only (ping · ARP · TCP connect-probe · banner · mDNS · OUI),"
  echo "  evidence-graded VERIFIED / INFERRED / UNKNOWN."
  echo "- **Honest limits:** read-only traffic is logged-but-not-invisible; INFERRED"
  echo "  identities are vendor-solid but model-level reasoned; note anything not seen."
  echo ""
  echo "## 3. Asset inventory"
  echo ""
  # embed the inventory table verbatim (everything from the first table header on)
  awk '/^\| *IP *\|/{p=1} p' "$INVENTORY"
  echo ""
  echo "## 4. Findings"
  echo ""
  if [ -n "$FINDINGS" ]; then
    # sort findings by severity, then emit one section each (skip header + template row)
    tail -n +2 "$FINDINGS" | grep -vE '^NS-000' | while IFS=, read -r id title assets _ severity _ band evidence impact remediation effort _; do
      [ -n "$id" ] || continue
      printf '%s\t%s\n' "$(sev_rank "$severity")" "$id|$title|$assets|$severity|$band|$evidence|$impact|$remediation|$effort"
    done | sort -n | cut -f2- | while IFS='|' read -r id title assets severity band evidence impact remediation effort; do
      # strip quotes CSV fields may carry
      echo "### [${severity//\"/}] ${id//\"/} · ${title//\"/}"
      echo "- **Affected:** ${assets//\"/}"
      echo "- **Evidence:** ${evidence//\"/} — **${band//\"/}**"
      echo "- **Business impact:** ${impact//\"/}"
      echo "- **Remediation:** ${remediation//\"/}"
      echo "- **Effort:** ${effort//\"/}"
      echo ""
    done
  else
    echo "> ✍️ No findings CSV supplied. Add findings per"
    echo "> ../templates/findings-register.csv and re-run with --findings."
    echo ""
  fi
  echo "## 5. Positive observations"
  echo ""
  echo "> ✍️ State what's already good (a real finding — it builds credibility)."
  echo ""
  echo "## 6. Remediation roadmap"
  echo ""
  echo "| # | Action | Finding | Effort | Priority |"
  echo "|---|---|---|---|---|"
  if [ -n "$FINDINGS" ]; then
    i=0
    tail -n +2 "$FINDINGS" | grep -vE '^NS-000' | while IFS=, read -r id title assets _ severity _ band evidence impact remediation effort _; do
      [ -n "$id" ] || continue
      printf '%s\t%s\n' "$(sev_rank "$severity")" "$id|${remediation//\"/}|${effort//\"/}"
    done | sort -n | cut -f2- | while IFS='|' read -r id remediation effort; do
      i=$((i+1)); echo "| $i | $remediation | $id | $effort | |"
    done
  fi
  echo ""
  echo "## 7. Re-test"
  echo ""
  echo "| Finding | Remediation applied | Re-test result | Status |"
  echo "|---|---|---|---|"
  echo "| | | | Open / Remediated / **Verified-Closed** |"
  echo ""
  echo "---"
  echo ""
  echo "*Generated by report-gen.sh from \`$(basename "$INVENTORY")\`. Finish the ✍️"
  echo "sections (human judgment), sanitize, then deliver only to the named recipients.*"
} > "$OUT"

echo "✓ report scaffolded → $OUT"
echo "  ✍️ finish the executive summary + positive observations before delivery."
