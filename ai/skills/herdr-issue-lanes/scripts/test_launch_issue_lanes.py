#!/usr/bin/env python3
"""Tests for launch_issue_lanes.py."""

from __future__ import annotations

import json
import unittest

from launch_issue_lanes import (
    IssueSpec,
    create_worktree,
    fetch_issue,
    format_prompt,
    infer_prefix,
    launch,
    parse_issues,
)


def herdr(result: dict) -> str:
    return json.dumps({"id": "cli", "result": result})


class ParseIssuesTests(unittest.TestCase):
    def test_mixed_tokens_preserve_order(self) -> None:
        specs = parse_issues(["26, #33", "fix/32 feat/30", "https://github.com/acme/repo/issues/31"])
        self.assertEqual(
            specs,
            [
                IssueSpec(26),
                IssueSpec(33),
                IssueSpec(32, "fix"),
                IssueSpec(30, "feat"),
                IssueSpec(31),
            ],
        )

    def test_rejects_duplicates_and_junk(self) -> None:
        with self.assertRaises(ValueError):
            parse_issues(["26,26"])
        with self.assertRaises(ValueError):
            parse_issues(["not-an-issue"])
        with self.assertRaises(ValueError):
            parse_issues(["", "  "])


class PrefixAndPromptTests(unittest.TestCase):
    def test_infer_prefix_from_labels_or_force(self) -> None:
        self.assertEqual(infer_prefix(["enhancement"], "auto"), "feat")
        self.assertEqual(infer_prefix(["Bug"], "auto"), "fix")
        self.assertEqual(infer_prefix(["bug"], "feat"), "feat")

    def test_format_prompt(self) -> None:
        info = fetch_issue(
            lambda cmd: json.dumps(
                {
                    "number": 26,
                    "title": "Reject corrupt logs",
                    "url": "https://github.com/acme/repo/issues/26",
                    "labels": [{"name": "bug"}],
                }
            ),
            IssueSpec(26),
            "auto",
        )
        self.assertEqual(info.prefix, "fix")
        self.assertEqual(info.branch, "fix/issue-26")
        self.assertEqual(format_prompt("{number}: {title} {url}", info), "26: Reject corrupt logs https://github.com/acme/repo/issues/26")


class LaunchTests(unittest.TestCase):
    def test_create_worktree_closes_extra_workspace(self) -> None:
        calls: list[list[str]] = []

        def runner(cmd: list[str]) -> str:
            calls.append(cmd)
            if cmd[:3] == ["herdr", "worktree", "list"]:
                return herdr({"worktrees": []})
            if cmd[:3] == ["herdr", "worktree", "create"]:
                return herdr(
                    {
                        "workspace": {"workspace_id": "w9"},
                        "worktree": {"path": "/tmp/issue-26", "branch": "fix/issue-26"},
                    }
                )
            if cmd[:3] == ["herdr", "workspace", "close"]:
                return herdr({"type": "ok"})
            raise AssertionError(cmd)

        from launch_issue_lanes import IssueInfo

        path = create_worktree(
            runner,
            "w5",
            IssueInfo(26, "title", "https://x/26", "fix", "fix/issue-26"),
            "origin/main",
            "/repo",
        )
        self.assertEqual(path, "/tmp/issue-26")
        self.assertEqual(calls[-1], ["herdr", "workspace", "close", "w9"])

    def test_launch_starts_agents_in_order(self) -> None:
        calls: list[list[str]] = []

        def runner(cmd: list[str]) -> str:
            calls.append(cmd)
            if cmd[:2] == ["gh", "issue"]:
                number = cmd[3]
                return json.dumps(
                    {
                        "number": int(number),
                        "title": f"Issue {number}",
                        "url": f"https://github.com/acme/repo/issues/{number}",
                        "labels": [{"name": "bug"}] if number == "26" else [],
                    }
                )
            if cmd[:3] == ["herdr", "worktree", "list"]:
                return herdr({"worktrees": []})
            if cmd[:3] == ["herdr", "worktree", "create"]:
                branch = cmd[cmd.index("--branch") + 1]
                return herdr(
                    {
                        "workspace": {"workspace_id": f"w-{branch}"},
                        "worktree": {"path": f"/tmp/{branch}", "branch": branch},
                    }
                )
            if cmd[:3] == ["herdr", "workspace", "close"]:
                return herdr({"type": "ok"})
            if cmd[:3] == ["herdr", "tab", "create"]:
                label = cmd[cmd.index("--label") + 1]
                n = label[1:]
                return herdr({"tab": {"tab_id": f"w5:t{n}"}, "root_pane": {"pane_id": f"w5:p{n}"}})
            if cmd[:3] == ["herdr", "agent", "start"]:
                return herdr({"type": "agent_started"})
            if cmd[:3] == ["herdr", "agent", "prompt"]:
                return herdr({"type": "agent_prompted"})
            raise AssertionError(cmd)

        lanes = launch(
            [IssueSpec(26), IssueSpec(33, "feat")],
            agent="pi",
            prompt_template="{url}",
            prefix="auto",
            base="origin/main",
            workspace="w5",
            cwd="/repo",
            agent_args=["--thinking", "xhigh"],
            start_agents=True,
            runner=runner,
        )
        self.assertEqual([lane.issue.branch for lane in lanes], ["fix/issue-26", "feat/issue-33"])
        self.assertEqual(lanes[0].prompt, "https://github.com/acme/repo/issues/26")
        starts = [cmd for cmd in calls if cmd[:3] == ["herdr", "agent", "start"]]
        self.assertEqual(starts[0][3], "issue-26")
        self.assertIn("--thinking", starts[0])
        self.assertTrue(all(lane.started for lane in lanes))


if __name__ == "__main__":
    unittest.main()
