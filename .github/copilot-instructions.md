# Copilot instructions

This is ObibaOpal.jl, a Julia client for the Opal data warehouse (OBiBA); a close port of the Opal R
client. The original R reference code is kept in `test/opal.r` — stick to it when translating: keep
the same variable names and stay close to the original structure.

Before coding, read [AGENTS.md](../AGENTS.md) for exact commands, test setup, and repo conventions.

## Rules

- Use idiomatic Julia and existing libraries; avoid introducing new features unless explicitly
  requested.
- Always verify information before presenting it; do not speculate without clear evidence.
- Never use apologies or express regret in comments or documentation.
- Don't summarize changes made in code or documentation.
- Don't invent changes other than what's explicitly requested, and don't remove unrelated code.
- Provide all edits in a single chunk instead of multi-step instructions.
- Don't suggest updates when there are no actual modifications needed.
- Do not add notes or references in docstrings; do not spell out tuples in the returns section.
- For large files (>300 lines) or complex changes: create a detailed plan first and wait for
  confirmation before editing.
