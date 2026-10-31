import { View, div, svg, image } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { agents, spaces, panes, props, run, setAgentOrder, theme } from "herdr";

const STATES = [
  { key: "blocked", label: "Needs you" },
  { key: "working", label: "Working" },
  { key: "done", label: "Done" },
  { key: "idle", label: "Idle" },
];
const stateColor = (t, state) => t[state.key] ?? t.unknown ?? t.dim;
const dot = (color, size = 7) => div().size(size).rounded(size).bg(color).flex_none();
const icon = (program, size = 18, tint) => program?.icon
  ? (program.tint ? svg(program.icon).text_color(tint) : image(program.icon)).size(size).flex_none()
  : div().size(size).rounded(4).bg(tint);
const chip = (t, label, selected = false) => h_flex().h(27).px(11).gap(7).items_center().rounded(6)
  .bg(selected ? t.selected : t.raised).border(1).border_color(selected ? t.accent : t.border)
  .text_size(11).text_color(selected ? t.accent : t.muted).child(label);

export default class Board extends View {
  init(_p, cx) {
    this.observed = {};
    cx.timer.every(30000, (cx) => cx.notify());
  }
  card(a, state, t) {
    const old = this.observed[a.address];
    if (!old || old.status !== a.status) this.observed[a.address] = { status: a.status, at: Date.now() };
    const mins = Math.floor((Date.now() - this.observed[a.address].at) / 60000);
    const elapsed = mins ? `${mins}m observed` : "<1m observed";
    const color = stateColor(t, state);
    return h_flex().id(`agent-${a.address}`).w_full().h(86).flex_none().rounded(7).overflow_hidden()
      .bg(t.surface).border(1).border_color(t.border).cursor_pointer().hover(s => s.border_color(color))
      .on_click(() => run("agent.focus", { terminal: a.address }))
      .child(div().w(3).h_full().bg(color).flex_none())
      .child(v_flex().flex_1().min_w(0).px(12).py(10).gap(7)
        .child(h_flex().gap(7).items_center().text_size(10).text_color(t.muted)
          .child(icon(a.program, 15, t.foreground)).child(div().truncate().child(a.program.name)).child(div().flex_1()).child(div().child(a.address)))
        .child(div().text_size(13).font_semibold().text_color(t.foreground).truncate().child(a.tab_name))
        .child(h_flex().items_center().justify_between().text_size(10).text_color(t.muted)
          .child(div().truncate().child(a.space_name)).child(div().flex_none().child(elapsed))));
  }
  render() {
    const t = theme();
    const role = props()?.role;
    const list = agents();
    const active = spaces().find(s => s.active);
    if (role === "header") return v_flex().size_full().bg(t.chrome).px(26).justify_center().gap(12)
      .child(h_flex().items_center().gap(10)
        .child(image("frame/welcome/herdr.png").w(24).h(24).rounded(6).flex_none())
        .child(div().text_size(20).font_semibold().text_color(t.foreground).child(active?.name ?? "Project board"))
        .child(div().text_size(19).text_color(t.dim).child("/"))
        .child(div().text_size(14).text_color(t.muted).child("Agent board"))
        .child(div().flex_1())
        .child(div().text_size(11).text_color(t.muted).child(`${list.length} agents across ${spaces().length} spaces`)))
      .child(h_flex().gap(7).items_center().child(chip(t, "Board", true)).child(chip(t, "All spaces"))
        .child(chip(t, "All agents")).child(div().flex_1()).child(dot(t.done, 6))
        .child(div().text_size(10).text_color(t.muted).child("Live updates")));
    if (role === "terminals") {
      const tab = active?.tabs.find(t => t.active);
      return h_flex().size_full().px(16).items_center().gap(8).bg(t.chrome).border_b(1).border_color(t.border)
        .child(dot(t.accent)).child(div().text_size(12).font_semibold().text_color(t.foreground).child("Live workspace"))
        .child(div().text_size(11).text_color(t.muted).child(`${active?.name ?? ""} / ${tab?.name ?? ""}`))
        .child(div().flex_1()).child(div().text_size(10).text_color(t.dim).child("TERMINALS"));
    }
    if (role === "pane") {
      const p = panes().find(p => p.pane === props().pane);
      return h_flex().size_full().px(13).items_center().gap(7).bg(t.chrome).border_b(1).border_color(t.border)
        .child(icon(p?.program, 14, t.foreground)).child(div().text_size(11).text_color(t.foreground).child(p?.program?.name ?? "Terminal"))
        .child(div().flex_1()).child(dot(t[p?.status] ?? t.unknown ?? t.dim, 6));
    }
    setAgentOrder(STATES.flatMap(s => list.filter(a => a.status === s.key).map(a => a.address)));
    return h_flex().size_full().px(24).py(17).gap(16).bg(t.canvas).children(STATES.map(state => {
      const cards = list.filter(a => a.status === state.key);
      const color = stateColor(t, state);
      return v_flex().flex_1().min_w(0).h_full().gap(9)
        .child(h_flex().h(27).flex_none().items_center().gap(8).px(3)
          .child(dot(color, 8)).child(div().text_size(13).font_semibold().text_color(t.foreground).child(state.label))
          .child(div().px(6).py(2).rounded(4).bg(`${color}26`).text_size(10).text_color(color).child(String(cards.length)))
          .child(div().flex_1()).child(div().text_color(t.dim).text_size(17).child("+")))
        .child(v_flex().flex_1().min_h(0).overflow_y_scrollbar().gap(9).children(cards.map(a => this.card(a, state, t))));
    }));
  }
}
