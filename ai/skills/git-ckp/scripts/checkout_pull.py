#!/usr/bin/env python3
"""Fetch a remote, switch to a branch, and fast-forward pull it safely."""

from __future__ import annotations

import argparse
import shlex
import subprocess
import sys
from pathlib import Path


def format_cmd(cmd: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in cmd)


def run_git(
    args: list[str],
    repo: Path,
    *,
    check: bool = True,
    capture: bool = False,
) -> subprocess.CompletedProcess[str]:
    cmd = ["git", *args]
    if not capture:
        print(f"+ {format_cmd(cmd)}")
    result = subprocess.run(
        cmd,
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
        check=False,
    )
    if check and result.returncode != 0:
        if capture:
            if result.stdout:
                print(result.stdout, end="")
            if result.stderr:
                print(result.stderr, end="", file=sys.stderr)
        raise subprocess.CalledProcessError(result.returncode, cmd)
    return result


def git_output(args: list[str], repo: Path, *, check: bool = True) -> str:
    result = run_git(args, repo, check=check, capture=True)
    return result.stdout.strip()


def ref_exists(ref: str, repo: Path) -> bool:
    result = run_git(["show-ref", "--verify", "--quiet", ref], repo, check=False)
    return result.returncode == 0


def current_repo() -> Path:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        print("Not inside a Git repository.", file=sys.stderr)
        sys.exit(2)
    return Path(result.stdout.strip())


def normalize_branch(branch: str, remote: str) -> tuple[str, str]:
    prefix = f"{remote}/"
    if branch.startswith(prefix):
        remote_branch = branch[len(prefix) :]
        return remote_branch, remote_branch
    return branch, branch


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Fetch a remote, switch to a branch, and pull with --ff-only."
    )
    parser.add_argument("branch", help="Local branch name or <remote>/<branch>.")
    parser.add_argument(
        "--remote",
        default="origin",
        help="Remote to fetch and use for remote-only branches. Defaults to origin.",
    )
    parser.add_argument(
        "--allow-dirty",
        action="store_true",
        help="Allow switching/pulling with local worktree changes present.",
    )
    args = parser.parse_args()

    repo = current_repo()
    local_branch, remote_branch = normalize_branch(args.branch, args.remote)

    status = git_output(["status", "--short"], repo)
    if status and not args.allow_dirty:
        print("Worktree has local changes; refusing to switch or pull.")
        print(status)
        print("Commit/stash the changes, or rerun with --allow-dirty if intended.")
        return 3

    remote_check = run_git(["remote", "get-url", args.remote], repo, check=False, capture=True)
    if remote_check.returncode != 0:
        print(f"Remote not found: {args.remote}", file=sys.stderr)
        return 4

    run_git(["fetch", "--prune", args.remote], repo)

    local_ref = f"refs/heads/{local_branch}"
    remote_ref = f"refs/remotes/{args.remote}/{remote_branch}"

    if ref_exists(local_ref, repo):
        run_git(["switch", local_branch], repo)
    elif ref_exists(remote_ref, repo):
        run_git(["switch", "--track", "-c", local_branch, f"{args.remote}/{remote_branch}"], repo)
    else:
        print(
            f"Branch not found locally or on {args.remote}: {args.branch}",
            file=sys.stderr,
        )
        return 5

    upstream = run_git(
        ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"],
        repo,
        check=False,
        capture=True,
    )
    if upstream.returncode != 0 and ref_exists(remote_ref, repo):
        run_git(["branch", "--set-upstream-to", f"{args.remote}/{remote_branch}", local_branch], repo)
    elif upstream.returncode != 0:
        print(f"Branch has no upstream: {local_branch}", file=sys.stderr)
        return 6

    run_git(["pull", "--ff-only"], repo)
    print(f"Updated {local_branch}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
