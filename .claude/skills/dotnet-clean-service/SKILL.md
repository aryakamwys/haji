---
name: dotnet-clean-service
description: Use when creating, refactoring, or reviewing .NET backend services — enforces clear naming, a 200-300 line target per file, minimal unnecessary loops, robust edge-case handling, and verified tests. Covers backend implementation and service refactoring.
---

# .NET Clean Service Engineering

## Objective

Produce production-minded .NET code that is readable, testable,
predictable, and easy to maintain.

Do not optimize for the fewest lines of code. Optimize for clear
responsibilities, correctness, and low maintenance cost.

## Step 1: Inspect Before Coding

1. Read CLAUDE.md and inspect the existing solution structure.
2. Check the target framework, dependencies, naming, and existing patterns.
3. Inspect related controllers, services, entities, DTOs, and tests.
4. Identify business rules, external dependencies, and failure scenarios.
5. Ask for clarification only when a missing requirement materially
   affects correctness, security, or business behavior.

Do not rewrite unrelated code or replace the architecture without need.

## Step 2: Design the Service

Before implementation, identify:

- The service's single primary responsibility.
- Inputs, outputs, and observable side effects.
- Business rules and validation boundaries.
- Database queries and transaction requirements.
- Authorization and data ownership requirements.
- Expected failures and edge cases.
- Required unit or integration tests.

Prefer cohesive services over large classes containing unrelated
business operations.

## Step 3: Code Size and Decomposition

- Aim for 200-300 lines or fewer per service implementation file.
- Count actual source lines; do not manipulate line counts by compressing
  formatting or removing necessary whitespace.
- If approaching 250 lines, inspect whether responsibilities can be
  separated cleanly.
- If exceeding 300 lines, explain the reason and evaluate a refactor.
- Never split a cohesive service into arbitrary classes merely to satisfy
  the limit.
- Extract a separate component only when it owns a meaningful responsibility.
- Avoid both god classes and excessive fragmentation.

## Step 4: Naming and Readability

Follow standard C# conventions:

- PascalCase: classes, methods, properties, public members.
- camelCase: parameters and local variables.
- _camelCase: private instance fields.
- Async suffix: asynchronous methods.
- Explicit domain names for entities, DTOs, services, and results.

Prefer:
- customerId over id when the identifier's meaning matters.
- paymentAmount over amount when the domain requires precision.
- GetCustomerByIdAsync over GetDataAsync.
- CreateVoucherRequest over RequestDto.
- IsEligibleForRedemption over Check.

Avoid vague names, misleading names, unnecessary abbreviations,
magic values, deeply nested conditionals, and clever expressions.

## Step 5: Loops and Data Access

For every loop, evaluate:

1. Is iteration necessary?
2. Is the collection size bounded?
3. Is there an avoidable nested iteration?
4. Is the same data fetched or calculated repeatedly?
5. Would a dictionary, hash set, or database query be clearer?
6. Is the algorithm's time complexity appropriate?

Do not replace every loop with LINQ automatically.
Prefer readable, explicit iteration when it communicates intent better.

For database access:
- Filter and project in the database when appropriate.
- Use pagination for potentially large result sets.
- Avoid N+1 queries and per-item database calls.
- Avoid loading entire tables for in-memory filtering.
- Inspect query translation and generated SQL when necessary.

## Step 6: Edge Cases and Correctness

Evaluate relevant cases before considering the implementation complete:

- Null, empty, missing, malformed, or out-of-range input.
- Record not found and unauthorized access.
- Duplicate requests and repeated submissions.
- Duplicate records and uniqueness conflicts.
- Invalid state transitions.
- Concurrent updates and stale data.
- Database failures and transaction rollback.
- Partial external-service failures and timeouts.
- Cancellation and asynchronous execution.
- Monetary precision and date/time boundaries.
- Pagination boundaries and unexpectedly large inputs.

Do not add meaningless checks for impossible states.
Handle each realistic case at the correct boundary.

For financial operations, evaluate atomicity, idempotency,
concurrency, and auditability explicitly.

## Step 7: Error Handling and Security

- Use appropriate validation and HTTP response semantics.
- Do not expose stack traces, secrets, or internal implementation details.
- Do not swallow exceptions.
- Catch only when recovery, translation, or useful context is needed.
- Enforce authorization on every protected operation.
- Never trust client-supplied ownership or account identifiers.
- Never store or log passwords, access tokens, or sensitive payment data.
- Use transactions for related database changes that must succeed together.
- Use cancellation tokens for supported asynchronous I/O operations.

## Step 8: Testing

Write tests for meaningful business behavior, not just line coverage.

Include when relevant:
- Happy path.
- Validation failures.
- Missing records.
- Boundary values.
- Duplicate operations.
- Invalid state transitions.
- Authorization failures.
- Concurrency and transactional behavior.

Use unit tests for isolated business logic and integration tests
for database mappings, API behavior, and transaction semantics.

Do not mock every dependency by default.
Use the smallest test setup that verifies the actual behavior.

## Step 9: Implementation and Verification

1. Implement the smallest correct change.
2. Build the affected project or solution.
3. Run relevant tests.
4. Review the diff for unintended changes.
5. Check service file lengths and naming consistency.
6. Check loops, database query patterns, and exception handling.
7. Report actual build and test results.

Never claim that a test, build, or verification succeeded unless
the corresponding command was executed and its result inspected.

## Completion Report

Summarize:
- What changed and why.
- Important edge cases handled.
- Tests and build commands executed.
- Results and remaining risks.
- Any service exceeding the target line count and why.
