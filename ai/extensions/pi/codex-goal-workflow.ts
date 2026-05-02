import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";
import { spawn } from "node:child_process";
import { chmodSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const SubmitCodexGoalParams = Type.Object({
	title: Type.String({ description: "Short title for the goal." }),
	kind: Type.Optional(Type.String({ description: "Document type, usually PRD or SPEC." })),
	document: Type.String({ description: "The complete PRD/SPEC to approve and send to Codex /goal." }),
});

function slugify(value: string): string {
	const slug = value
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, "-")
		.replace(/^-+|-+$/g, "")
		.slice(0, 60);
	return slug || "codex-goal";
}

function shellQuote(value: string): string {
	return `'${value.replace(/'/g, "'\\''")}'`;
}

function buildCodexPrompt(kind: string, title: string, document: string): string {
	return [
		"/goal",
		"",
		`# ${kind}: ${title}`,
		"",
		document.trim(),
		"",
		"Use this as the active goal. Ask only for missing decisions that block execution.",
	].join("\n");
}

function launchCodex(cwd: string, promptFile: string): { launched: boolean; command: string; message: string } {
	const command = `cd ${shellQuote(cwd)} && codex --no-alt-screen "$(cat ${shellQuote(promptFile)})"`;

	if (process.platform !== "darwin") {
		return {
			launched: false,
			command,
			message: "Codex launch command prepared. Run it from a terminal to start Codex /goal.",
		};
	}

	const commandFile = promptFile.replace(/\.md$/, ".command");
	writeFileSync(commandFile, `#!/usr/bin/env bash\n${command}\n`, "utf8");
	chmodSync(commandFile, 0o755);

	const child = spawn("open", [commandFile], {
		detached: true,
		stdio: "ignore",
	});
	child.unref();

	return {
		launched: true,
		command: `open ${shellQuote(commandFile)}`,
		message: "Opened a macOS terminal command for Codex /goal.",
	};
}

const WORKFLOW_PROMPT = `Use the grill-with-docs skill to turn the request below into an approved PRD/SPEC, then submit it to Codex /goal.

Workflow contract:
1. Load and follow the grill-with-docs skill before drafting.
2. Explore existing code and docs when an answer can be discovered locally.
3. Ask the user one question at a time with ask_user_question. Do not bundle unrelated questions.
4. Resolve terminology against CONTEXT.md or CONTEXT-MAP.md when present.
5. Update CONTEXT.md or ADRs only when grill-with-docs says the decision belongs there.
6. Draft a concise PRD/SPEC with: problem, goals, non-goals, user workflow, requirements, acceptance criteria, technical notes, risks, and open questions.
7. Call submit_codex_goal with the final document. That tool will ask the user to approve or edit the output and will send the approved PRD/SPEC to Codex /goal.
8. If submit_codex_goal is cancelled, ask what to revise with ask_user_question.

Request:`;

export default function codexGoalWorkflow(pi: ExtensionAPI) {
	pi.registerCommand("codex-goal", {
		description: "Grill an idea into an approved PRD/SPEC, then send it to Codex /goal",
		handler: async (args, ctx) => {
			const request = args.trim();
			if (!request) {
				ctx.ui.notify("Usage: /codex-goal <feature, plan, or problem>", "warning");
				return;
			}

			if (ctx.isIdle()) {
				pi.sendUserMessage(`${WORKFLOW_PROMPT}\n\n${request}`);
			} else {
				pi.sendUserMessage(`${WORKFLOW_PROMPT}\n\n${request}`, { deliverAs: "followUp" });
				ctx.ui.notify("Queued Codex goal workflow as a follow-up", "info");
			}
		},
	});

	pi.registerTool({
		name: "submit_codex_goal",
		label: "Submit Codex Goal",
		description:
			"Ask the user to approve or edit a completed PRD/SPEC, then send the approved document to Codex /goal.",
		promptSnippet:
			"After drafting an approved PRD/SPEC for Codex, call submit_codex_goal so the user can approve it before Codex receives /goal.",
		parameters: SubmitCodexGoalParams,
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			if (!ctx.hasUI) {
				return {
					content: [{ type: "text" as const, text: "submit_codex_goal requires interactive Pi UI for approval." }],
					details: { status: "unavailable" },
				};
			}

			const kind = (params.kind || "PRD/SPEC").trim();
			const title = params.title.trim();
			const approvedDocument = await ctx.ui.editor(
				`Review and edit ${kind} before sending to Codex /goal: ${title}`,
				params.document.trim(),
			);

			if (approvedDocument === undefined || approvedDocument.trim().length === 0) {
				return {
					content: [{ type: "text" as const, text: "User cancelled Codex /goal submission." }],
					details: { status: "cancelled" },
				};
			}

			const approved = await ctx.ui.confirm(
				"Send to Codex /goal?",
				`This will create a Codex /goal prompt for "${title}" and open it in Codex.`,
			);

			if (!approved) {
				return {
					content: [{ type: "text" as const, text: "User did not approve Codex /goal submission." }],
					details: { status: "rejected", title, kind },
				};
			}

			const goalDir = join(ctx.cwd, ".pi", "codex-goals");
			mkdirSync(goalDir, { recursive: true });

			const stamp = new Date().toISOString().replace(/[:.]/g, "-");
			const promptFile = join(goalDir, `${stamp}-${slugify(title)}.md`);
			const prompt = buildCodexPrompt(kind, title, approvedDocument);
			writeFileSync(promptFile, prompt, "utf8");

			const launch = launchCodex(ctx.cwd, promptFile);
			return {
				content: [
					{
						type: "text" as const,
						text: `${launch.message}\nPrompt file: ${promptFile}\nCommand: ${launch.command}`,
					},
				],
				details: {
					status: launch.launched ? "launched" : "prepared",
					title,
					kind,
					promptFile,
					command: launch.command,
				},
			};
		},
		renderCall(args, theme) {
			return new Text(theme.fg("toolTitle", theme.bold("submit_codex_goal ")) + theme.fg("muted", args.title), 0, 0);
		},
		renderResult(result, _options, theme) {
			const first = result.content[0];
			const text = first?.type === "text" ? first.text : "Codex goal submission finished";
			return new Text(theme.fg("success", text), 0, 0);
		},
	});
}
