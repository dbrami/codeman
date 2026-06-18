#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# ///
"""Weekly throughput and cycle-time metrics for an engineering board.

For each repo it pulls *closed* issues via `gh` and reports, per ISO week:
  - throughput  : issues closed that week, plus a rolling 4-week average
  - cycle time  : days from issue open -> close, p50 and p85

It also prints a current WIP-aging summary (open issue count + age p50/p85 +
oldest), which is the leading indicator: when WIP grows with flat throughput,
cycle time degrades before throughput does (Little's Law).

This is the dashboard to watch instead of the GitHub Insights cumulative chart.
That chart is cumulative, so its "Open" line always rises and tells you nothing
about whether you are getting faster. Throughput slope + cycle time do.

Scope note: this measures repo-level issues (a superset of any project board).
To narrow to board membership you'd need the Projects v2 GraphQL API; repo-level
is the right first dashboard and matches arrival/departure at the source.

Usage:
  python3 flow-metrics.py                      # last 12 weeks, current repo
  python3 flow-metrics.py --weeks 8
  python3 flow-metrics.py --repo owner/name --repo owner/other
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import date, datetime, timedelta, timezone


def infer_repo() -> str:
    """Infer owner/name from the current repo's origin remote."""
    try:
        out = subprocess.run(
            ["git", "remote", "get-url", "origin"], capture_output=True, text=True
        )
    except FileNotFoundError:
        sys.exit("error: git not found and no --repo given.")
    url = (out.stdout or "").strip()
    if not url:
        sys.exit("error: no --repo given and no origin remote found.")
    m = re.search(r"[:/]([^/:]+/[^/]+?)(?:\.git)?$", url)
    if not m:
        sys.exit(f"error: could not parse owner/name from remote: {url}")
    return m.group(1)


def gh_search(repo: str, extra_flags: list[str], fields: str) -> list[dict]:
    """Run `gh search issues` (qualifiers via flags) and return parsed JSON.

    The positional arg of `gh search issues` is treated as a literal search
    term, so all qualifiers (repo, state, dates) are passed as flags.
    """
    cmd = ["gh", "search", "issues", "--repo", repo, "--limit", "1000",
           "--json", fields, *extra_flags]
    try:
        out = subprocess.run(cmd, capture_output=True, text=True)
    except FileNotFoundError:
        sys.exit("error: `gh` CLI not found on PATH. Install GitHub CLI first.")
    if out.returncode != 0:
        sys.exit(f"error: gh failed for {repo}\n  cmd: {' '.join(cmd)}\n  {out.stderr.strip()}")
    return json.loads(out.stdout or "[]")


def parse_ts(s: str) -> datetime:
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


def iso_week_monday(dt: datetime) -> date:
    """Monday (UTC) of the ISO week containing dt."""
    d = dt.astimezone(timezone.utc).date()
    return d - timedelta(days=d.weekday())


def pct(sorted_vals: list[float], p: float) -> float | None:
    """Linear-interpolation percentile (p in [0,1]). Input must be sorted."""
    if not sorted_vals:
        return None
    if len(sorted_vals) == 1:
        return sorted_vals[0]
    k = (len(sorted_vals) - 1) * p
    lo = int(k)
    hi = min(lo + 1, len(sorted_vals) - 1)
    return sorted_vals[lo] + (sorted_vals[hi] - sorted_vals[lo]) * (k - lo)


def collect_throughput(repo: str, week_keys: list[date], since: str):
    """Return (closed_by_week, cycle_days_by_week) for one repo."""
    issues = gh_search(
        repo, ["--closed", f">={since}"], "number,createdAt,closedAt"
    )
    closed = {wk: 0 for wk in week_keys}
    cycle: dict[date, list[float]] = {wk: [] for wk in week_keys}
    for it in issues:
        if not it.get("closedAt"):
            continue
        ca = parse_ts(it["closedAt"])
        wk = iso_week_monday(ca)
        if wk not in closed:
            continue  # fell outside the displayed window
        closed[wk] += 1
        if it.get("createdAt"):
            cycle[wk].append((ca - parse_ts(it["createdAt"])).total_seconds() / 86400)
    return closed, cycle


def collect_wip(repo: str, now: datetime) -> list[float]:
    """Return sorted ages (days) of currently-open issues."""
    issues = gh_search(repo, ["--state", "open"], "number,createdAt")
    return sorted(
        (now - parse_ts(i["createdAt"])).total_seconds() / 86400
        for i in issues
        if i.get("createdAt")
    )


def print_table(label: str, week_keys: list[date], closed, cycle) -> None:
    print(f"\n=== {label} ===")
    print(f"{'week':<15}{'closed':>7}{'4wk avg':>9}{'p50 d':>8}{'p85 d':>8}")
    counts = [closed[wk] for wk in week_keys]
    for i, wk in enumerate(week_keys):
        window = counts[max(0, i - 3) : i + 1]
        avg = sum(window) / len(window)
        cyc = sorted(cycle[wk])
        p50, p85 = pct(cyc, 0.50), pct(cyc, 0.85)
        iy, iw, _ = wk.isocalendar()
        wklabel = f"{iy}-W{iw:02d} {wk.strftime('%m-%d')}"
        p50s = f"{p50:>8.1f}" if p50 is not None else f"{'-':>8}"
        p85s = f"{p85:>8.1f}" if p85 is not None else f"{'-':>8}"
        print(f"{wklabel:<15}{closed[wk]:>7}{avg:>9.1f}{p50s}{p85s}")
    allc = sorted(d for wk in week_keys for d in cycle[wk])
    if allc:
        print(
            f"  window cycle-time: p50={pct(allc, 0.5):.1f}d  "
            f"p85={pct(allc, 0.85):.1f}d  (n={len(allc)} closed)"
        )


def print_wip(label: str, ages: list[float]) -> None:
    if not ages:
        print(f"  {label} WIP: 0 open")
        return
    print(
        f"  {label} WIP: {len(ages)} open  "
        f"age p50={pct(ages, 0.5):.0f}d  p85={pct(ages, 0.85):.0f}d  "
        f"oldest={ages[-1]:.0f}d"
    )


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--weeks", type=int, default=12, help="weeks of history to show (default 12)")
    ap.add_argument("--repo", action="append", dest="repos",
                    help="repo as owner/name (repeatable); default: current repo from git remote")
    args = ap.parse_args()
    repos = args.repos or [infer_repo()]

    now = datetime.now(timezone.utc)
    this_monday = iso_week_monday(now)
    start_monday = this_monday - timedelta(weeks=args.weeks - 1)
    since = start_monday.isoformat()
    week_keys = [start_monday + timedelta(weeks=i) for i in range(args.weeks)]

    combined_closed = {wk: 0 for wk in week_keys}
    combined_cycle: dict[date, list[float]] = {wk: [] for wk in week_keys}
    combined_wip: list[float] = []

    print(f"Flow metrics  |  window: {since} -> {now.date().isoformat()}  ({args.weeks} weeks)")

    for repo in repos:
        closed, cycle = collect_throughput(repo, week_keys, since)
        for wk in week_keys:
            combined_closed[wk] += closed[wk]
            combined_cycle[wk].extend(cycle[wk])
        print_table(repo, week_keys, closed, cycle)
        ages = collect_wip(repo, now)
        combined_wip.extend(ages)
        print_wip(repo, ages)

    if len(repos) > 1:
        print_table("COMBINED", week_keys, combined_closed, combined_cycle)
        print_wip("COMBINED", sorted(combined_wip))


if __name__ == "__main__":
    main()
