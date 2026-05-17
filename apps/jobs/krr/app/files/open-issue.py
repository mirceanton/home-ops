import json
import os
import urllib.parse
import urllib.request
from datetime import datetime, timezone

REPO = "mirceanton/home-ops"
ISSUE_TITLE = "KRR Dashboard"

with open("/data/krr.json") as f:
    data = json.load(f)

score = data.get("score", 0)
letter = "F" if score < 30 else "D" if score < 55 else "C" if score < 70 else "B" if score < 90 else "A"
today = datetime.now(timezone.utc).strftime("%Y-%m-%d")


def fmt_cpu(v):
    if v is None:
        return "unset"
    if isinstance(v, str):
        return "?"
    return f"{int(v * 1000)}m"


def fmt_mem(v):
    if v is None:
        return "unset"
    if isinstance(v, str):
        return "?"
    mib = v / (1024 * 1024)
    return f"{mib / 1024:.1f}Gi" if mib >= 1024 else f"{int(mib)}Mi"


def arrow(cur, rec, fmt):
    c = fmt(cur)
    r = fmt(rec["value"] if isinstance(rec, dict) else rec)
    return c if c == r else f"~~{c}~~ → **{r}**"


icons = {"CRITICAL": "🔴", "WARNING": "🟡", "OK": "🟢", "GOOD": "💚"}

actionable = [s for s in data["scans"] if s["severity"] in ("WARNING", "CRITICAL")]
actionable.sort(key=lambda s: ["CRITICAL", "WARNING"].index(s["severity"]))

lines = [
    f"## KRR Resource Recommendations — {today}",
    f"",
    f"**Cluster score: {score}/100 ({letter})**",
    f"",
]

if not actionable:
    lines += ["All workloads are within acceptable resource bounds. No changes needed."]
else:
    lines += [
        f"### {len(actionable)} workload(s) need attention",
        f"",
        f"| Severity | Namespace | Workload | Container | CPU req | Mem req | Mem limit |",
        f"|---|---|---|---|---|---|---|",
    ]
    for s in actionable:
        obj = s["object"]
        rec = s["recommended"]
        cur = obj["allocations"]
        icon = icons.get(s["severity"], "❓")
        cpu_req = arrow(cur["requests"].get("cpu"), rec["requests"]["cpu"], fmt_cpu)
        mem_req = arrow(cur["requests"].get("memory"), rec["requests"]["memory"], fmt_mem)
        mem_lim = arrow(cur["limits"].get("memory"), rec["limits"]["memory"], fmt_mem)
        lines.append(
            f"| {icon} {s['severity']} | {obj['namespace']} | {obj['name']} | {obj['container']} | {cpu_req} | {mem_req} | {mem_lim} |"
        )

body = "\n".join(lines)
token = os.environ["GH_TOKEN"]

headers = {
    "Authorization": f"Bearer {token}",
    "Accept": "application/vnd.github+json",
    "Content-Type": "application/json",
    "X-GitHub-Api-Version": "2022-11-28",
}


def gh(method, path, payload=None):
    url = f"https://api.github.com{path}"
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode() if payload else None,
        headers=headers,
        method=method,
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


# Find an existing open issue to update rather than opening a new one each run
q = urllib.parse.urlencode({"q": f"repo:{REPO} is:issue is:open in:title {ISSUE_TITLE}"})
results = gh("GET", f"/search/issues?{q}")
existing = next((i for i in results["items"] if i["title"] == ISSUE_TITLE), None)

if existing:
    result = gh("PATCH", f"/repos/{REPO}/issues/{existing['number']}", {"body": body})
    print(f"Updated: {result['html_url']}")
else:
    result = gh("POST", f"/repos/{REPO}/issues", {"title": ISSUE_TITLE, "body": body})
    print(f"Opened: {result['html_url']}")
