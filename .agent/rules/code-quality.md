# Code Quality

Enforced on every code change. No exceptions.

## TypeScript
- No `any` type. Use `unknown` + type guards if needed.
- Named exports only. No default exports.
- Types over interfaces (except extending third-party).
- String literals over enums (except GraphQL enums).
- No abbreviations in names: `user` not `u`, `fieldMetadata` not `fm`.
- Descriptive generics: `TData` not `T`.

## Components & Files
- Functional components only. No class components.
- Components under 300 lines, services under 500 lines.
- Files use kebab-case with suffixes: `.component.tsx`, `.service.ts`, `.entity.ts`, `.dto.ts`, `.module.ts`.

## Before Committing
- Run `npx nx lint:diff-with-main` on all affected packages
- Run `npx nx typecheck` on all affected packages
- Run relevant unit tests
- Generate migrations if any entity file changed
- Run `graphql:generate` if GraphQL schema changed
