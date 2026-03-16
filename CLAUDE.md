# Key Documents
- docs/GDD.md — Game design. Read relevant sections before implementing any feature.
- docs/PLAN.md — Phased plan. Update after each completed task.
- docs/SCRATCHPAD.md — Plan complex tasks here before coding.

# Development Workflow

## Before writing any code, describe your approach and wait for approval. Ask clarifying questions if requirements are ambiguous

## if a task requires changes to more than 3 files, stop and break it into smaller tasks first

## consider creating a `/decompose` command that takes a plan and outputs a list of small tasks to implement one at a time

## Describe your tech stack, folder structure, coding convention and any anti-patterns you'd like to avoid

## use `/memory` to save any personal preferences that should persist across projects

## create a `.claudeignore` file containing any files the agent shouldn't read or modify

## when there's a bug, start by writing a test that reproduces it, then fix it until the test passes

## after writing code, list what could break and suggest tests to cover it

## create a `/review-xyz` command that checks for correctness, edge cases, and consistency with codebase patterns

## create a `/test` command that invokes a test sub-agent that runs your test suite

## when I say something is wrong, ask clarifying questions before rewriting

## use the `/rewind` command to rollback changes, then give more specific feedback and try again

## use git worktrees to run parallel agent sessions on different tasks

## use `claude --dangerously-skip-permissions` on a disposable environment to iterate faster while still being able to recover when things go wrong

## every time I correct youo, add a new rule to the CLAUDE.md file so it never happens again

## convert any successful, repeatable prompt into a workflow by saving it as a slash command or a skill

## create sub-agents for any repetitive tasks that require a large context or specialized analysis. Reuse these agents without polluting your main context