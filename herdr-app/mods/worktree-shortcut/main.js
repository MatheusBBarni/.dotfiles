import { View, div } from "gpui-kit";
import { closeOverlay, openOverlay, panes, props, spaces } from "herdr";

export default class WorktreeShortcut extends View {
  init(_props, cx) {
    const space = spaces().find((candidate) => candidate.active);
    const folder = panes().find((pane) => pane.focused)?.cwd;
    const launcher = props()?.overlay;
    cx.timer.after(1, () => {
      if (space) {
        const worktreeProps = { space: space.id, action: "new" };
        if (folder) worktreeProps.folder = folder;
        openOverlay({
          mod: "worktree",
          kind: "dialog",
          width: 460,
          height: 280,
          props: worktreeProps,
        });
      }
      if (launcher) closeOverlay(launcher);
    });
  }

  render() {
    return div();
  }
}
