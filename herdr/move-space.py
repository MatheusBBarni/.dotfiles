#!/usr/bin/env python3
"""Move the current Herdr space up or down in the sidebar."""

from __future__ import annotations

import json
import os
import socket
import sys
from typing import Any


def rpc(method: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
    sock_path = os.environ.get(
        "HERDR_SOCKET_PATH",
        os.path.expanduser("~/.config/herdr/herdr.sock"),
    )
    request = {
        "id": f"move-space:{method}",
        "method": method,
        "params": params or {},
    }
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.settimeout(2)
    try:
        sock.connect(sock_path)
        sock.sendall((json.dumps(request) + "\n").encode())
        buf = b""
        while b"\n" not in buf:
            chunk = sock.recv(65536)
            if not chunk:
                break
            buf += chunk
    finally:
        sock.close()
    if not buf:
        raise RuntimeError(f"empty response from herdr for {method}")
    response = json.loads(buf.decode())
    if "error" in response:
        raise RuntimeError(f"{method} failed: {response['error']}")
    return response["result"]


def workspace_groups(workspaces: list[dict[str, Any]]) -> list[list[dict[str, Any]]]:
    groups: list[list[dict[str, Any]]] = []
    index_by_key: dict[str, int] = {}
    for workspace in workspaces:
        worktree = workspace.get("worktree") or {}
        repo_key = worktree.get("repo_key")
        if repo_key:
            if repo_key in index_by_key:
                groups[index_by_key[repo_key]].append(workspace)
            else:
                index_by_key[repo_key] = len(groups)
                groups.append([workspace])
        else:
            groups.append([workspace])
    return groups


def current_workspace_id(workspaces: list[dict[str, Any]]) -> str:
    for key in ("HERDR_ACTIVE_WORKSPACE_ID", "HERDR_WORKSPACE_ID"):
        value = os.environ.get(key, "").strip()
        if value:
            return value
    for workspace in workspaces:
        if workspace.get("focused"):
            return workspace["workspace_id"]
    raise RuntimeError("could not determine the current herdr space")


def move_space(direction: str) -> None:
    if direction not in {"up", "down"}:
        raise SystemExit(f"usage: {sys.argv[0]} up|down")

    workspaces = rpc("workspace.list")["workspaces"]
    groups = workspace_groups(workspaces)
    current_id = current_workspace_id(workspaces)

    group_index = next(
        (
            index
            for index, group in enumerate(groups)
            if any(workspace["workspace_id"] == current_id for workspace in group)
        ),
        None,
    )
    if group_index is None:
        raise RuntimeError(f"space {current_id} not found")

    target_index = group_index - 1 if direction == "up" else group_index + 1
    if target_index < 0 or target_index >= len(groups):
        return

    workspace_ids = [workspace["workspace_id"] for workspace in groups[group_index]]
    if direction == "up":
        before_workspace_id = groups[target_index][0]["workspace_id"]
    elif target_index + 1 < len(groups):
        before_workspace_id = groups[target_index + 1][0]["workspace_id"]
    else:
        before_workspace_id = None

    params: dict[str, Any] = {"workspace_ids": workspace_ids}
    if before_workspace_id is not None:
        params["before_workspace_id"] = before_workspace_id
    rpc("workspace.move_block", params)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(f"usage: {sys.argv[0]} up|down")
    move_space(sys.argv[1])
