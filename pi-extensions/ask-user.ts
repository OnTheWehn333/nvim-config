import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const QUESTION_PAYLOAD_PREFIX = "pi.nvim:ask-user:";
const FREEFORM_SENTINEL = "Enter an answer";
const CONTEXT_ONLY_SENTINEL = "Provide context without selecting an answer";

const OptionSchema = Type.Object({
  value: Type.String({ description: "Value returned to the agent" }),
  label: Type.String({ description: "Label shown to the user" }),
  description: Type.Optional(
    Type.String({ description: "Optional detail shown beside the label" }),
  ),
});

const AskUserParams = Type.Object({
  question: Type.String({ description: "Question to ask the user" }),
  options: Type.Optional(
    Type.Array(OptionSchema, { description: "Choices presented to the user" }),
  ),
  multiple: Type.Optional(
    Type.Boolean({
      description:
        "Allow multiple choices instead of exactly one choice (default: false)",
    }),
  ),
  multiline: Type.Optional(
    Type.Boolean({
      description: "Use a multiline answer field for a free-form response",
    }),
  ),
  placeholder: Type.Optional(
    Type.String({ description: "Placeholder for a free-form answer" }),
  ),
});

type AnswerDetails = {
  question: string;
  answer: string | string[] | null;
  value: string | string[] | null;
  wasCustom: boolean;
  comment: string | null;
  cancelled: boolean;
};

function result(text: string, details: AnswerDetails) {
  return {
    content: [{ type: "text" as const, text }],
    details,
  };
}

function cancelled(question: string, wasCustom: boolean) {
  return result("User cancelled the question", {
    question,
    answer: null,
    value: null,
    wasCustom,
    comment: null,
    cancelled: true,
  });
}

async function askForContext(ctx: ExtensionContext) {
  const context = await ctx.ui.editor("Additional context (optional)", "");
  return context?.trim() ?? "";
}

export default function askUser(pi: ExtensionAPI) {
  pi.registerTool({
    name: "ask_user",
    label: "Ask User",
    description:
      "Ask the user one question through Pi's attention UI. Supports single- or multi-select choices and collects a selected answer, a custom response, and/or additional context.",
    promptSnippet:
      "Ask the user a question through the built-in attention-compatible UI",
    promptGuidelines: [
      "Use ask_user instead of asking a question in plain text when the answer is needed to continue.",
      "When ask_user asks the user to run a command, first show that command " +
        "in the normal assistant response as a fenced Markdown code block so it is " +
        "easy to copy; never leave the command only in the ask_user question.",
      "Set ask_user multiple to true when more than one option may be selected; otherwise choices are single-select.",
      "Treat ask_user choices as suggestions: the user can respond with context without selecting any option.",
      "Omit ask_user options for a free-form answer. Every question also provides an optional additional-context field.",
    ],
    parameters: AskUserParams,
    executionMode: "sequential",

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      if (!ctx.hasUI) {
        throw new Error("ask_user requires an interactive UI");
      }

      const options = params.options ?? [];
      const multiple = options.length > 0 && params.multiple === true;

      if (ctx.mode === "rpc") {
        const labels = options.map((option) =>
          option.description
            ? `${option.label} — ${option.description}`
            : option.label,
        );
        const request =
          QUESTION_PAYLOAD_PREFIX +
          JSON.stringify({
            question: params.question,
            kind: options.length > 0 ? "choices" : "freeform",
            multiple,
            multiline: params.multiline === true,
            placeholder: params.placeholder,
          });
        const response = await ctx.ui.select(
          request,
          labels.length > 0 ? labels : [FREEFORM_SENTINEL],
        );
        if (response === undefined)
          return cancelled(params.question, options.length === 0);

        if (options.length > 0) {
          let selectedLabels: string[] = [response];
          let comment = "";
          try {
            const combined = JSON.parse(response) as {
              answers?: string[];
              answer?: string;
              context?: string;
            };
            if (Array.isArray(combined.answers)) {
              selectedLabels = combined.answers.filter(
                (answer): answer is string => typeof answer === "string",
              );
            } else if (typeof combined.answer === "string") {
              selectedLabels = [combined.answer];
            }
            if (typeof combined.context === "string")
              comment = combined.context.trim();
          } catch {
            // A client without the combined Neovim dialog returns one selected label.
          }

          const selectedOptions = selectedLabels.map((label) => {
            const option = options[labels.indexOf(label)];
            if (!option) throw new Error("ask_user received an unknown answer");
            return option;
          });
          if (!multiple && selectedOptions.length > 1) {
            throw new Error(
              "ask_user received multiple answers for a single-select question",
            );
          }

          const answerLabels = selectedOptions.map((option) => option.label);
          const values = selectedOptions.map((option) => option.value);
          const answerText =
            answerLabels.length > 0
              ? answerLabels.join(", ")
              : "(no answer selected)";
          const text = comment
            ? `User selected: ${answerText}\nAdditional context: ${comment}`
            : `User selected: ${answerText}`;
          return result(text, {
            question: params.question,
            answer: multiple ? answerLabels : (answerLabels[0] ?? null),
            value: multiple ? values : (values[0] ?? null),
            wasCustom: false,
            comment: comment || null,
            cancelled: false,
          });
        }

        let answer = "";
        let comment = "";
        try {
          const combined = JSON.parse(response) as {
            answer?: string;
            context?: string;
          };
          if (typeof combined.answer === "string")
            answer = combined.answer.trim();
          if (typeof combined.context === "string")
            comment = combined.context.trim();
        } catch {
          answer = response === FREEFORM_SENTINEL ? "" : response.trim();
        }
        const text = comment
          ? `User answered: ${answer || "(empty response)"}\nAdditional context: ${comment}`
          : `User answered: ${answer || "(empty response)"}`;
        return result(text, {
          question: params.question,
          answer,
          value: answer,
          wasCustom: true,
          comment: comment || null,
          cancelled: false,
        });
      }

      if (options.length > 0) {
        const labels = options.map((option) =>
          option.description
            ? `${option.label} — ${option.description}`
            : option.label,
        );
        const remaining = [...labels, CONTEXT_ONLY_SENTINEL];
        const selected: string[] = [];
        do {
          const choice = await ctx.ui.select(
            multiple && selected.length > 0
              ? "Select another answer, or continue with context"
              : params.question,
            remaining,
          );
          if (choice === undefined) {
            if (!multiple || selected.length === 0)
              return cancelled(params.question, false);
            break;
          }
          if (choice === CONTEXT_ONLY_SENTINEL) break;
          selected.push(choice);
          remaining.splice(remaining.indexOf(choice), 1);
        } while (multiple && remaining.length > 1);

        const comment = await askForContext(ctx);
        const selectedOptions = selected.map(
          (label) => options[labels.indexOf(label)]!,
        );
        const answerLabels = selectedOptions.map((option) => option.label);
        const values = selectedOptions.map((option) => option.value);
        const answerText =
          answerLabels.length > 0
            ? answerLabels.join(", ")
            : "(no answer selected)";
        const text = comment
          ? `User selected: ${answerText}\nAdditional context: ${comment}`
          : `User selected: ${answerText}`;
        return result(text, {
          question: params.question,
          answer: multiple ? answerLabels : (answerLabels[0] ?? null),
          value: multiple ? values : (values[0] ?? null),
          wasCustom: false,
          comment: comment || null,
          cancelled: false,
        });
      }

      const answer = params.multiline
        ? await ctx.ui.editor(params.question, "")
        : await ctx.ui.input(params.question, params.placeholder);
      if (answer === undefined) return cancelled(params.question, true);
      const comment = await askForContext(ctx);
      const trimmed = answer.trim();
      const text = comment
        ? `User answered: ${trimmed || "(empty response)"}\nAdditional context: ${comment}`
        : `User answered: ${trimmed || "(empty response)"}`;
      return result(text, {
        question: params.question,
        answer: trimmed,
        value: trimmed,
        wasCustom: true,
        comment: comment || null,
        cancelled: false,
      });
    },
  });
}
