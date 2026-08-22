#!/usr/bin/env python3
"""Create Herdr tabs + worktrees for GitHub issues and start agents."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import asdict, dataclass
from typing import Any, Callable, Iterable
from urllib.parse import urlparse

FIX_LABELS = frozenset({"bug", "fix", "regression"})
ISSUE_URL_RE = re.compile(r"/issues/(\d+)(?:/|$)", re.IGNORECASE)
PREFIXED_RE = re.compile(r"^(feat|fix)/#?(\d+)$", re.IGNORECASE)
NUMBER_RE = re.compile(r"^#?(\d+)$")


@dataclass(frozen=True)
class IssueSpec:
    number: int
    prefix: str | None = None


@dataclass(frozen=True)
class IssueInfo:
    number: int
    title: str
    url: str
    prefix: str
    branch: str

    @property
    def tab_label(self) -> str:
        return f"#{self.number}"

    @property
    def agent_name(self) -> str:
        return f"issue-{self.number}"


@dataclass(frozen=True)
class Lane:
    issue: IssueInfo
    worktree_path: str
    tab_id: str
    pane_id: str
    prompt: str
    started: bool


Runner = Callable[[list[str]], str]


def parse_issues(raw: Iterable[str]) -> list[IssueSpec]:
    specs: list[IssueSpec] = []
    seen: set[int] = set()
    for token in raw:
        for part in re.split(r"[,\s]+", token.strip()):
            if not part:
                continue
            spec = _parse_issue_token(part)
            if spec.number in seen:
                raise ValueError(f"duplicate issue {spec.number}")
            seen.add(spec.number)
            specs.append(spec)
    if not specs:
        raise ValueError("no issues given")
    return specs


def _parse_issue_token(token: str) -> IssueSpec:
    prefixed = PREFIXED_RE.match(token)
    if prefixed:
        return IssueSpec(number=int(prefixed.group(2)), prefix=prefixed.group(1).lower())
    numbered = NUMBER_RE.match(token)
    if numbered:
        return IssueSpec(number=int(numbered.group(1)))
    parsed = urlparse(token)
    if parsed.scheme and parsed.netloc:
        match = ISSUE_URL_RE.search(parsed.path)
        if match:
            return IssueSpec(number=int(match.group(1)))
    raise ValueError(f"unrecognized issue token: {token}")


def infer_prefix(labels: Iterable[str], forced: str) -> str:
    if forced != "auto":
        return forced
    names = {label.strip().lower() for label in labels}
    if names & FIX_LABELS:
        return "fix"
    return "feat"


def format_prompt(template: str, info: IssueInfo) -> str:
    return template.format(url=info.url, number=info.number, title=info.title)


def branch_name(prefix: str, number: int) -> str:
    return f"{prefix}/issue-{number}"


def run_cmd(cmd: list[str]) -> str:
    result = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "").strip()
        raise RuntimeError(f"{' '.join(cmd)} failed ({result.returncode}): {detail}")
    return result.stdout


def parse_json(payload: str) -> Any:
    text = payload.strip()
    if not text:
        raise RuntimeError("expected JSON from command, got empty output")
    return json.loads(text)


def herdr_result(runner: Runner, args: list[str]) -> dict[str, Any]:
    payload = parse_json(runner(["herdr", *args]))
    if not isinstance(payload, dict) or "result" not in payload:
        raise RuntimeError(f"unexpected herdr payload: {payload!r}")
    result = payload["result"]
    if not isinstance(result, dict):
        raise RuntimeError(f"unexpected herdr result: {result!r}")
    return result


def fetch_issue(runner: Runner, spec: IssueSpec, forced_prefix: str) -> IssueInfo:
    payload = parse_json(
        runner(["gh", "issue", "view", str(spec.number), "--json", "number,title,url,labels"])
    )
    labels = [item.get("name", "") for item in payload.get("labels", []) if isinstance(item, dict)]
    prefix = spec.prefix or infer_prefix(labels, forced_prefix)
    number = int(payload["number"])
    return IssueInfo(
        number=number,
        title=str(payload["title"]),
        url=str(payload["url"]),
        prefix=prefix,
        branch=branch_name(prefix, number),
    )


def existing_worktree_path(runner: Runner, cwd: str, branch: str) -> str | None:
    payload = parse_json(runner(["herdr", "worktree", "list", "--cwd", cwd]))
    result = payload.get("result", payload) if isinstance(payload, dict) else {}
    worktrees = result.get("worktrees", []) if isinstance(result, dict) else []
    for item in worktrees:
        if isinstance(item, dict) and item.get("branch") == branch:
            path = item.get("path")
            if path:
                return str(path)
    return None


def create_worktree(runner: Runner, workspace: str, info: IssueInfo, base: str, cwd: str) -> str:
    existing = existing_worktree_path(runner, cwd, info.branch)
    if existing:
        return existing
    result = herdr_result(
        runner,
        [
            "worktree",
            "create",
            "--workspace",
            workspace,
            "--branch",
            info.branch,
            "--base",
            base,
            "--label",
            info.tab_label,
            "--no-focus",
        ],
    )
    created = result.get("workspace") or {}
    extra_id = created.get("workspace_id") if isinstance(created, dict) else None
    if extra_id and extra_id != workspace:
        herdr_result(runner, ["workspace", "close", str(extra_id)])
    worktree = result.get("worktree") or {}
    path = worktree.get("path") if isinstance(worktree, dict) else None
    if not path:
        raise RuntimeError(f"worktree create for {info.branch} returned no path")
    return str(path)


def create_tab(runner: Runner, workspace: str, info: IssueInfo, path: str) -> tuple[str, str]:
    result = herdr_result(
        runner,
        ["tab", "create", "--workspace", workspace, "--cwd", path, "--label", info.tab_label, "--no-focus"],
    )
    tab = result.get("tab") or {}
    pane = result.get("root_pane") or {}
    tab_id = tab.get("tab_id") if isinstance(tab, dict) else None
    pane_id = pane.get("pane_id") if isinstance(pane, dict) else None
    if not tab_id or not pane_id:
        raise RuntimeError(f"tab create for {info.tab_label} returned no ids")
    return str(tab_id), str(pane_id)


def start_and_prompt(
    runner: Runner,
    info: IssueInfo,
    pane_id: str,
    prompt: str,
    agent: str,
    agent_args: list[str],
) -> None:
    start = ["agent", "start", info.agent_name, "--kind", agent, "--pane", pane_id, "--timeout", "60000"]
    if agent_args:
        start.extend(["--", *agent_args])
    herdr_result(runner, start)
    herdr_result(runner, ["agent", "prompt", info.agent_name, prompt])


def launch(
    specs: list[IssueSpec],
    *,
    agent: str,
    prompt_template: str,
    prefix: str,
    base: str,
    workspace: str,
    cwd: str,
    agent_args: list[str],
    start_agents: bool,
    runner: Runner = run_cmd,
) -> list[Lane]:
    lanes: list[Lane] = []
    for spec in specs:
        info = fetch_issue(runner, spec, prefix)
        path = create_worktree(runner, workspace, info, base, cwd)
        tab_id, pane_id = create_tab(runner, workspace, info, path)
        prompt = format_prompt(prompt_template, info)
        started = False
        if start_agents:
            start_and_prompt(runner, info, pane_id, prompt, agent, agent_args)
            started = True
        lanes.append(
            Lane(
                issue=info,
                worktree_path=path,
                tab_id=tab_id,
                pane_id=pane_id,
                prompt=prompt,
                started=started,
            )
        )
    return lanes


def print_report(lanes: list[Lane], agent: str) -> None:
    print("Lane   Tab      Branch              Worktree                              Agent")
    for lane in lanes:
        print(
            f"{lane.issue.tab_label:<6} "
            f"{lane.tab_id:<8} "
            f"{lane.issue.branch:<19} "
            f"{lane.worktree_path:<37} "
            f"{lane.issue.agent_name} ({agent})"
        )
    print(json.dumps({"lanes": [asdict(lane) for lane in lanes]}, indent=2))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--issues", required=True, help="Comma/space-separated issues, URLs, or feat|fix/N")
    parser.add_argument("--agent", default="pi", help="Herdr agent kind (default: pi)")
    parser.add_argument("--prompt", default="{url}", help="First prompt template")
    parser.add_argument("--prefix", choices=("auto", "feat", "fix"), default="auto")
    parser.add_argument("--base", default="origin/main")
    parser.add_argument("--workspace", default=os.environ.get("HERDR_WORKSPACE_ID", ""))
    parser.add_argument("--cwd", default=os.getcwd())
    parser.add_argument("--no-start", action="store_true", help="Create tabs/worktrees only")
    parser.add_argument("agent_args", nargs=argparse.REMAINDER, help="Native agent args after --")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if os.environ.get("HERDR_ENV") != "1":
        print("Not running inside Herdr (HERDR_ENV!=1). Stop.", file=sys.stderr)
        return 2
    if not args.workspace:
        print("HERDR_WORKSPACE_ID is unset and --workspace was not given.", file=sys.stderr)
        return 2
    agent_args = args.agent_args
    if agent_args and agent_args[0] == "--":
        agent_args = agent_args[1:]
    try:
        specs = parse_issues([args.issues])
        lanes = launch(
            specs,
            agent=args.agent,
            prompt_template=args.prompt,
            prefix=args.prefix,
            base=args.base,
            workspace=args.workspace,
            cwd=args.cwd,
            agent_args=agent_args,
            start_agents=not args.no_start,
        )
    except (ValueError, RuntimeError, json.JSONDecodeError, KeyError) as exc:
        print(str(exc), file=sys.stderr)
        return 1
    print_report(lanes, args.agent)
    return 0


if __name__ == "__main__":
    sys.exit(main())
