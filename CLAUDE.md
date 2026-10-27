# VoucherUmrohHaji

Produk: aplikasi jual-beli voucher top-up Umroh/Haji dengan cashback MLM berjenjang.
Target produksi: **Flutter (folder `VoucherUmrohHaji/mobile/`)** + **ASP.NET Core Minimal API .NET 10 (folder `VoucherUmrohHaji/service`)** + **PostgreSQL** + pembayaran **Midtrans Snap** (sandbox dulu).

Folder `VoucherUmrohHaji/*.swift` adalah demo SwiftUI lama — hanya referensi fitur, jangan dikembangkan lagi.

## Backend Engineering Standards

### Technology
- Use the existing .NET SDK, target framework, and project conventions.
- Follow ASP.NET Core and Entity Framework Core best practices.
- Inspect the existing architecture before modifying code.
- Do not introduce dependencies without a clear reason.

### Code Size and Responsibility
- Target 200-300 lines per service implementation file or fewer.
- Treat 300 lines as a review threshold, not an absolute limit.
- Split code only when responsibilities are genuinely distinct.
- Each class and method must have one clear responsibility.
- Avoid god classes, duplicated logic, and unnecessary abstractions.
- Keep methods small enough to understand without excessive navigation.

### Naming
- Use PascalCase for types, methods, and public members.
- Use camelCase for local variables and parameters.
- Use _camelCase for private instance fields.
- Use meaningful names that explain intent.
- Use Async suffix for asynchronous methods.
- Use descriptive names for DTOs, commands, queries, and services.
- Avoid unclear abbreviations and generic names such as data, temp, obj,
  manager, or helper when a more precise name is available.

### Design
- Keep controllers thin: HTTP concerns, validation responses,
  and delegation to application logic.
- Keep business rules out of controllers and infrastructure classes.
- Use dependency injection and constructor injection.
- Separate API contracts, business logic, and persistence concerns
  according to the existing architecture.
- Prefer explicit, readable code over clever one-liners.
- Do not create interfaces or layers without a concrete benefit.

### Loops and Performance
- Avoid unnecessary nested loops and repeated database queries.
- Prefer database-side filtering, projection, and pagination for
  large datasets.
- Use dictionaries or hash sets when they simplify repeated lookups.
- Choose LINQ when it improves readability, not merely to reduce lines.
- Never optimize by sacrificing correctness or clarity.
- Check for N+1 queries and unbounded result sets.

### Reliability and Edge Cases
- Validate untrusted input at system boundaries.
- Handle missing records, null values, empty collections,
  invalid states, and duplicate requests where applicable.
- Consider authorization, concurrency, transaction boundaries,
  and partial failures.
- Use decimal for monetary calculations.
- Use UTC for persisted timestamps where appropriate.
- Never swallow exceptions or expose internal exception details.
- Do not catch exceptions unless handling or translating them adds value.
- Never hardcode credentials, tokens, or sensitive configuration.

### Quality Gates
- Build after meaningful code changes.
- Add or update tests for business rules and edge cases.
- Check cancellation tokens in asynchronous I/O paths.
- Use async/await for asynchronous I/O; avoid unnecessary Task.Run.
- Fix new compiler warnings when practical.
- Do not claim that a build or test passed without running it.
- Review changed code for regressions before finishing.

### Workflow
1. Inspect related files and existing conventions.
2. Understand requirements and edge cases before coding.
3. Propose the smallest maintainable change.
4. Implement the change.
5. Run relevant tests and build.
6. Report files changed, validation results, and known limitations.

## Git
- Conventional Commits (`feat(auth): ...`, `fix(wallet): ...`, dst.) — lihat skill `git-workflow`.
- Push hanya saat diminta atau sudah disepakati untuk tugas berjalan.
- Jangan pernah commit `bin/`, `obj/`, `.env`, atau secrets.
