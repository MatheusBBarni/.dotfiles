import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";

interface AskOption {
	label: string;
	value?: string;
	description?: string;
}

interface AskAnswer {
	type: "text" | "option" | "other";
	label: string;
	value: string;
	index?: number;
}

const OptionSchema = Type.Object({
	label: Type.String({
		description: 'Display label. Put the recommended option first and append "(Recommended)" when applicable.',
	}),
	value: Type.Optional(Type.String({ description: "Optional machine-readable value returned for this option." })),
	description: Type.Optional(Type.String({ description: "Optional detail shown to the user." })),
});

const AskUserQuestionParams = Type.Object({
	question: Type.String({ description: "Ask exactly one question." }),
	details: Type.Optional(Type.String({ description: "Optional context shown with the question." })),
	options: Type.Optional(
		Type.Array(OptionSchema, {
			description: "Optional choices. Omit for free-form text input.",
		}),
	),
	multiSelect: Type.Optional(Type.Boolean({ description: "Allow multiple options to be selected." })),
});

function normalizeOptions(options: AskOption[] | undefined): AskOption[] {
	return (options || [])
		.map((option) => ({
			label: option.label.trim(),
			value: option.value?.trim() || option.label.trim(),
			description: option.description?.trim() || undefined,
		}))
		.filter((option) => option.label.length > 0);
}

function formatOptions(options: AskOption[]): string {
	return options
		.map((option, index) => {
			const description = option.description ? ` - ${option.description}` : "";
			return `${index + 1}. ${option.label}${description}`;
		})
		.join("\n");
}

function buildResult(question: string, mode: string, answers: AskAnswer[], context?: string) {
	const text =
		answers.length === 0
			? "No answer provided"
			: answers.map((answer) => `User answered: ${answer.label}`).join("\n");

	return {
		content: [{ type: "text" as const, text }],
		details: {
			status: "answered",
			question,
			context,
			mode,
			answers,
		},
	};
}

export default function askUserQuestion(pi: ExtensionAPI) {
	pi.registerTool({
		name: "ask_user_question",
		label: "Ask User Question",
		description:
			"Ask the user exactly one clarifying, approval, or decision question and wait for the answer. Prefer this over guessing when requirements are ambiguous.",
		promptSnippet:
			"Use ask_user_question for one question at a time when requirements, terminology, product decisions, or approval are needed.",
		promptGuidelines: [
			"Ask exactly one question per tool call.",
			"If you need several answers, call this tool several times.",
			"Prefer options when there are 2-4 clear paths.",
			'Always include an "Other" path by asking for free-form input when the listed options do not fit.',
		],
		parameters: AskUserQuestionParams,
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const question = params.question.trim();
			const details = params.details?.trim() || undefined;
			const options = normalizeOptions(params.options);

			if (signal?.aborted) {
				return {
					content: [{ type: "text" as const, text: "User question was cancelled" }],
					details: { status: "cancelled", question, context: details, answers: [] },
				};
			}

			if (!ctx.hasUI) {
				return {
					content: [{ type: "text" as const, text: "ask_user_question requires interactive Pi UI" }],
					details: { status: "unavailable", question, context: details, answers: [] },
				};
			}

			if (options.length === 0) {
				const title = details ? `${question}\n\n${details}` : question;
				const answer = await ctx.ui.editor(title, "");
				if (answer === undefined) {
					return {
						content: [{ type: "text" as const, text: "User cancelled the question" }],
						details: { status: "cancelled", question, context: details, answers: [] },
					};
				}
				const trimmed = answer.trim();
				return buildResult(question, "text", [{ type: "text", label: trimmed, value: trimmed }], details);
			}

			if (params.multiSelect) {
				const prompt = [
					question,
					details ? `\n${details}` : "",
					"\nSelect one or more options by number, separated with commas. You can also type a custom answer.",
					"",
					formatOptions(options),
				].join("\n");
				const answer = await ctx.ui.editor(prompt, "");
				if (answer === undefined) {
					return {
						content: [{ type: "text" as const, text: "User cancelled the question" }],
						details: { status: "cancelled", question, context: details, answers: [] },
					};
				}

				const parts = answer
					.split(",")
					.map((part) => part.trim())
					.filter(Boolean);
				const answers: AskAnswer[] = parts.map((part) => {
					const index = Number(part);
					if (Number.isInteger(index) && index >= 1 && index <= options.length) {
						const option = options[index - 1];
						return { type: "option", label: option.label, value: option.value || option.label, index };
					}
					return { type: "other", label: part, value: part };
				});

				return buildResult(question, "multi-select", answers, details);
			}

			const labels = [...options.map((option, index) => `${index + 1}. ${option.label}`), "Other"];
			const selected = await ctx.ui.select(details ? `${question}\n\n${details}` : question, labels);
			if (!selected) {
				return {
					content: [{ type: "text" as const, text: "User cancelled the question" }],
					details: { status: "cancelled", question, context: details, answers: [] },
				};
			}

			if (selected === "Other") {
				const answer = await ctx.ui.editor(`${question}\n\nType your custom answer.`, "");
				if (answer === undefined) {
					return {
						content: [{ type: "text" as const, text: "User cancelled the question" }],
						details: { status: "cancelled", question, context: details, answers: [] },
					};
				}
				const trimmed = answer.trim();
				return buildResult(question, "single-select", [{ type: "other", label: trimmed, value: trimmed }], details);
			}

			const index = Number(selected.split(".")[0]);
			const option = options[index - 1];
			return buildResult(
				question,
				"single-select",
				[{ type: "option", label: option.label, value: option.value || option.label, index }],
				details,
			);
		},
		renderCall(args, theme) {
			return new Text(theme.fg("toolTitle", theme.bold("ask_user_question ")) + theme.fg("muted", args.question), 0, 0);
		},
		renderResult(result, _options, theme) {
			const details = result.details as { answers?: AskAnswer[]; status?: string } | undefined;
			if (!details?.answers?.length) {
				return new Text(theme.fg("warning", details?.status || "No answer"), 0, 0);
			}
			return new Text(
				details.answers.map((answer) => `${theme.fg("success", "OK")} ${answer.label}`).join("\n"),
				0,
				0,
			);
		},
	});
}
