import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";
import { spawn } from "node:child_process";
import { mkdirSync, openSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const SubmitCodexGoalParams = Type.Object({
	title: Type.String({ description: "Short title for the goal." }),
	kind: Type.Optional(Type.String({ description: "Document type, usually PRD or SPEC." })),
	document: Type.String({ description: "The complete PRD/SPEC to approve and run through Codex Loop." }),
	loopGoal: Type.Optional(Type.String({ description: "Completion goal for codex-loop. Defaults to verified implementation." })),
	confirmModel: Type.Optional(Type.String({ description: "codex-loop confirmation model. Defaults to gpt-5.5." })),
	confirmReasoningEffort: Type.Optional(
		Type.String({ description: "codex-loop confirmation reasoning effort. Defaults to high." }),
	),
});

function slugify(value: string): string {
	const slug = value
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, "-")
		.replace(/^-+|-+$/g, "")
		.slice(0, 60);
	return slug || "codex-goal";
}

function headerValue(value: string): string {
	return value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function buildCodexLoopPrompt(
	kind: string,
	title: string,
	document: string,
	loopGoal: string,
	confirmModel: string,
	confirmReasoningEffort: string,
): string {
	const name = slugify(title);
	const header = [
		`[[CODEX_LOOP name="${headerValue(name)}"`,
		`goal="${headerValue(loopGoal)}"`,
		`confirm_model="${headerValue(confirmModel)}"`,
		`confirm_reasoning_effort="${headerValue(confirmReasoningEffort)}"]]`,
	].join(" ");

	return [
		header,
		"",
		`# ${kind}: ${title}`,
		"",
		document.trim(),
		"",
		"Treat this approved PRD/SPEC as the active Codex task.",
		"Implement it end-to-end, verify it with fresh evidence, and keep going until codex-loop confirms the goal is complete.",
		"Ask only for missing decisions that block execution.",
	].join("\n");
}

function startCodexLoop(cwd: string, prompt: string, logFile: string, outputFile: string): number {
	const logFd = openSync(logFile, "a");
	const child = spawn("codex", ["exec", "--cd", cwd, "--skip-git-repo-check", "--output-last-message", outputFile, "-"], {
		detached: true,
		stdio: ["pipe", logFd, logFd],
	});

	child.stdin.end(prompt);
	child.unref();

	return child.pid ?? 0;
}

const WORKFLOW_PROMPT = `Use the grill-with-docs skill to turn the request below into an approved PRD/SPEC, then start a Codex Loop run for the approved work.

Workflow contract:
1. Load and follow the grill-with-docs skill before drafting.
2. Explore existing code and docs when an answer can be discovered locally.
3. Ask the user one question at a time with ask_user_question. Do not bundle unrelated questions.
4. Resolve terminology against CONTEXT.md or CONTEXT-MAP.md when present.
5. Update CONTEXT.md or ADRs only when grill-with-docs says the decision belongs there.
6. Draft a concise PRD/SPEC with: problem, goals, non-goals, user workflow, requirements, acceptance criteria, technical notes, risks, and open questions.
7. Call submit_codex_goal with the final document. That tool will ask the user to approve or edit the output and will start a headless codex exec run with a codex-loop activation header.
8. If submit_codex_goal is cancelled, ask what to revise with ask_user_question.

Request:`;

export default function codexGoalWorkflow(pi: ExtensionAPI) {
	pi.registerCommand("codex-goal", {
		description: "Grill an idea into an approved PRD/SPEC, then start a Codex Loop run",
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
			"Ask the user to approve or edit a completed PRD/SPEC, then start a headless Codex Loop run.",
		promptSnippet:
			"After drafting an approved PRD/SPEC for Codex, call submit_codex_goal so the user can approve it before starting codex-loop.",
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
			const loopGoal =
				params.loopGoal?.trim() ||
				`Implement "${title}" completely and stop only after fresh verification proves the PRD/SPEC is satisfied.`;
			const confirmModel = params.confirmModel?.trim() || "gpt-5.5";
			const confirmReasoningEffort = params.confirmReasoningEffort?.trim() || "high";
			const approvedDocument = await ctx.ui.editor(
				`Review and edit ${kind} before starting Codex Loop: ${title}`,
				params.document.trim(),
			);

			if (approvedDocument === undefined || approvedDocument.trim().length === 0) {
				return {
					content: [{ type: "text" as const, text: "User cancelled Codex Loop submission." }],
					details: { status: "cancelled" },
				};
			}

			const approved = await ctx.ui.confirm(
				"Start Codex Loop?",
				`This will start a headless codex exec run for "${title}".`,
			);

			if (!approved) {
				return {
					content: [{ type: "text" as const, text: "User did not approve Codex Loop submission." }],
					details: { status: "rejected", title, kind },
				};
			}

			const goalDir = join(ctx.cwd, ".pi", "codex-goals");
			mkdirSync(goalDir, { recursive: true });

			const stamp = new Date().toISOString().replace(/[:.]/g, "-");
			const promptFile = join(goalDir, `${stamp}-${slugify(title)}.md`);
			const logFile = join(goalDir, `${stamp}-${slugify(title)}.log`);
			const outputFile = join(goalDir, `${stamp}-${slugify(title)}.last.md`);
			const prompt = buildCodexLoopPrompt(
				kind,
				title,
				approvedDocument,
				loopGoal,
				confirmModel,
				confirmReasoningEffort,
			);
			writeFileSync(promptFile, prompt, "utf8");

			const pid = startCodexLoop(ctx.cwd, prompt, logFile, outputFile);

			return {
				content: [
					{
						type: "text" as const,
						text: `Started Codex Loop for "${title}".\nPID: ${pid}\nPrompt file: ${promptFile}\nLog file: ${logFile}\nLast message file: ${outputFile}`,
					},
				],
				details: {
					status: "started",
					title,
					kind,
					pid,
					promptFile,
					logFile,
					outputFile,
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
