---
name: git-workflow
description: Use when committing, reviewing staged or unstaged changes, preparing a push, or organizing Git history — safely inspects Git changes, validates code, prepares clean Conventional Commits, and optionally pushes to the intended remote.
---

# Git Workflow and Commit Standards

## Objective

Maintain a clean, traceable, and safe Git history.

Use Conventional Commits and keep each commit focused on one logical change.

## 1. Inspect Repository State

Before changing Git state, run:

- `git status --short --branch`
- `git branch --show-current`
- `git remote -v`
- `git log -5 --oneline`
- `git diff --stat`
- `git diff`

Inspect staged changes separately using `git diff --cached`.

Understand the current branch, remote, existing user changes, and
repository conventions before proceeding.

Never assume the default branch is `main` or `master`.

## 2. Protect Existing Work

- Never discard, overwrite, or revert unrelated user changes.
- Never run `git reset --hard`, `git clean -fd`, or destructive cleanup commands.
- Never use `git push --force` or rewrite shared history unless explicitly authorized.
- Never amend an existing commit unless explicitly requested.
- Never stage every file blindly with `git add .` or `git add -A`.
- Stage specific, reviewed files.
- Preserve pre-existing staged changes.
- Do not include unrelated changes in the same commit.
- If changes from multiple tasks are mixed together, separate them carefully.
- If separation cannot be performed safely, stop and explain the conflict.

## 3. Check Sensitive Files

Before staging, inspect changed filenames and relevant diffs.

Do not commit:

- `.env` files containing secrets.
- API keys, tokens, passwords, private keys, or certificates.
- Database dumps containing sensitive information.
- Build artifacts, temporary files, and local IDE state.
- `bin/`, `obj/`, and other generated output unless intentionally required.
- Local configuration containing credentials.

Check `.gitignore` and repository conventions.

Do not print secret values in reports or terminal summaries.

If a secret is already tracked, do not assume adding it to `.gitignore`
removes it from Git history. Stop and explain the remediation required.

## 4. Validate Before Committing

For .NET projects:

1. Identify the relevant `.sln` or `.csproj`.
2. Run `dotnet restore` when needed.
3. Run `dotnet build` on the affected project or solution.
4. Run relevant tests using `dotnet test`.
5. Review compiler errors, warnings, and test failures.
6. Inspect the final diff for correctness and unintended changes.

Use the repository's existing build and test commands when available.

Do not claim validation succeeded unless commands actually ran successfully.

If tests fail because of an unrelated baseline issue, report the exact
limitation. Do not conceal failures or silently skip required tests.

Do not commit broken changes unless the user explicitly authorizes a
documented exception.

## 5. Conventional Commit Format

Use:

`type(scope): description`

Use lowercase types and concise imperative descriptions.

Allowed types:

- `feat`: new functionality.
- `fix`: bug fixes.
- `refactor`: restructuring without intentional behavior changes.
- `test`: adding or updating tests.
- `docs`: documentation changes.
- `style`: formatting without behavior changes.
- `perf`: performance improvements.
- `build`: build system or dependency changes.
- `ci`: CI/CD configuration.
- `chore`: maintenance tasks.
- `revert`: reverting a previous commit.

Examples:

- `feat(auth): add JWT refresh token flow`
- `feat(voucher): validate voucher redemption`
- `fix(wallet): prevent duplicate balance deductions`
- `fix(payment): handle repeated Midtrans callbacks`
- `refactor(voucher): separate eligibility validation`
- `test(wallet): cover concurrent withdrawals`
- `docs(api): document voucher endpoints`
- `build(docker): add production runtime configuration`
- `ci(github): add dotnet test workflow`

Use a scope that reflects the actual module or component.

Avoid vague messages such as:

- `update code`
- `fix bug`
- `changes`
- `final update`
- `misc fixes`

Do not claim behavior changed unless the diff supports that claim.

Use `!` and a `BREAKING CHANGE:` footer when a change breaks an
existing contract.

## 6. Keep Commits Focused

Prefer one logical change per commit.

If a task contains unrelated features, bug fixes, formatting changes, and
documentation updates, split them into separate commits when safe.

Do not create unnecessary commits for every file.

Do not split tightly coupled changes that must remain consistent to
build or function correctly.

Review the complete staged diff before every commit.

## 7. Commit Workflow

Follow this sequence:

1. Inspect branch, remotes, status, and recent history.
2. Inspect all relevant staged and unstaged changes.
3. Identify user changes and preserve them.
4. Check for secrets and generated files.
5. Stage only intended files.
6. Inspect `git diff --cached`.
7. Run the required build and tests.
8. Select an accurate Conventional Commit message.
9. Create the commit.
10. Verify the result using `git status --short --branch` and `git log -1 --oneline`.

If a check fails, stop before committing and report the failure unless
an explicit exception is authorized.

## 8. Push Policy

Creating a local commit and pushing to a remote are separate operations.

- Default to creating a local commit only.
- Push only when explicitly requested or covered by a clear prior
  instruction for the current task.
- Before pushing, verify the destination remote, branch, upstream, and
  commit range.
- Never push directly to a production branch without explicit authorization.
- Never force-push as a routine fix.
- If the remote contains commits not present locally, inspect and
  reconcile safely.
- Never silently change branches or remotes to make a push succeed.

After pushing, verify the command result and report the actual destination.

## 9. Failure Handling

If Git reports conflicts, rejected pushes, missing upstreams,
authentication errors, or unexpected repository state:

- Stop and inspect the cause.
- Preserve existing work.
- Explain the issue and propose the safest next action.
- Do not bypass hooks or branch protections without authorization.
- Do not report success after a failed command.

## 10. Final Report

After committing, report:

- Commit hash and message.
- Files included.
- Build and test results.
- Current branch.
- Whether the commit was pushed, and to which remote and branch.
- Any remaining risks or uncommitted changes.

Keep the report concise, accurate, and based on actual command output.
