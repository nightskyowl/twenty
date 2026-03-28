# AGENTS.md

> This file provides workspace context for Antigravity (and compatible IDEs).
> For Claude Code-specific context, see `CLAUDE.md`.

## Your Role

You are the **executor** in a multi-agent workflow:

```
Nathan + Claude Code  -->  Antigravity (you)  -->  Claude Code
   (plan & prompt)         (implement & test)       (review)
```

1. **Nathan and Claude Code** discuss, brainstorm, and plan the work together
2. **Claude Code prepares prompts** describing exactly what needs to be built
3. **You (Antigravity) implement the code and run tests** based on those prompts
4. **Claude Code reviews your work** and leaves comments if anything needs fixing
5. **You fix any issues** Claude Code raises

When you receive a prompt from Claude Code (usually pasted by Nathan), treat it as a detailed spec. Implement exactly what it asks — no more, no less. If something is unclear or seems wrong, say so before writing code.

## Project Identity

**Project:** Hoa Quan Real Estate CRM (HQ-CRM)
**Fork of:** [twentyhq/twenty](https://github.com/twentyhq/twenty) — Open-Source CRM
**Owner:** Nathan Nguyen — CEO of UpNext, Director of Hoa Quan
**Repo:** github.com/nightskyowl/twenty

## What This Is

A vertical CRM for Vietnamese industrial real estate companies, built on Twenty CRM. It serves:
- **Hoa Quan's own operations** — 4 industrial clusters in Hai Duong province (~258 ha total)
- **Commercial SaaS product** — sold to other Vietnamese RE companies

## Architecture

### Tech Stack
- **Frontend**: React 18, TypeScript, Jotai, Linaria, Vite
- **Backend**: NestJS, TypeORM, PostgreSQL, Redis, GraphQL (GraphQL Yoga)
- **Monorepo**: Nx workspace, Yarn 4

### Key Packages
```
packages/
├── twenty-front/       # React frontend
├── twenty-server/      # NestJS backend
├── twenty-ui/          # Shared UI components
├── twenty-shared/      # Common types and utilities
├── twenty-emails/      # Email templates
└── twenty-e2e-testing/ # Playwright E2E tests
```

### AI Layer (separate service, not in this repo)
A proprietary AI middleware communicates with Twenty via API. Do not add AI/LLM logic directly into this codebase.

## Key Commands

```bash
# Setup
bash packages/twenty-utils/setup-dev-env.sh

# Dev
yarn start                          # Start all
npx nx start twenty-front           # Frontend only
npx nx start twenty-server          # Backend only

# Test
npx jest path/to/test.test.ts --config=packages/PROJECT/jest.config.mjs
npx nx test twenty-front
npx nx test twenty-server

# Lint (always use diff mode)
npx nx lint:diff-with-main twenty-front
npx nx lint:diff-with-main twenty-server

# Typecheck
npx nx typecheck twenty-front
npx nx typecheck twenty-server

# Build (twenty-shared first)
npx nx build twenty-shared
npx nx build twenty-front
npx nx build twenty-server

# Database
npx nx database:reset twenty-server
npx nx run twenty-server:command workspace:sync-metadata

# GraphQL codegen (after schema changes)
npx nx run twenty-front:graphql:generate
```

## Coding Rules

### Must Follow
- Functional components only, no class components
- Named exports only, no default exports
- Types over interfaces (except extending third-party)
- String literals over enums (except GraphQL enums)
- No `any` type — strict TypeScript
- No abbreviations (`user` not `u`, `fieldMetadata` not `fm`)
- Components under 300 lines, services under 500 lines
- Event handlers over useEffect for state updates
- Props down, events up

### Naming
- Variables/functions: camelCase
- Constants: SCREAMING_SNAKE_CASE
- Types/Classes: PascalCase (props suffixed with `Props`)
- Files/directories: kebab-case (`.component.tsx`, `.service.ts`, `.entity.ts`)
- TypeScript generics: descriptive (`TData` not `T`)

### Comments
- Short-form `//` only, no JSDoc blocks
- Explain WHY, not WHAT
- Multi-line: multiple `//` lines, not `/** */`

### HQ-CRM Specific
- **Code language:** English for all code, comments, variable names, commits
- **UI language:** Vietnamese primary, English secondary
- **Currency:** VND primary (store as integers, use BigInt/Decimal), USD secondary. Never float for money.
- **Dates:** Store UTC in database, use Asia/Ho_Chi_Minh for business logic
- **Vietnamese text:** Proper diacritics always. Normalize with NFC.
- **Custom object names:** English for API (`objectName`), Vietnamese for UI labels (`labelSingular`/`labelPlural`)
- **Commits:** `feat(hq):`, `fix(hq):`, `chore(hq):` for HQ-specific changes. No prefix for upstream-compatible.

### State Management
- Jotai for global state (atoms, selectors, atom families)
- React hooks for component state
- Apollo Client for GraphQL cache

### Backend
- NestJS modules for features
- TypeORM + PostgreSQL
- Redis for caching/sessions
- BullMQ for background jobs

### Database & Migrations
- Always generate migrations for entity changes
- Migration names: kebab-case
- Include `up` and `down` logic
- Never delete or rewrite committed migrations

### Testing
- Test behavior, not implementation
- 70% unit, 20% integration, 10% E2E
- Query by user-visible elements over test IDs
- `@testing-library/user-event` for interactions
- Descriptive names: "should [behavior] when [condition]"
- `jest.clearAllMocks()` between tests

### Styling & i18n
- Linaria for CSS-in-JS
- Lingui for internationalization
- Sanitize before format

## Fork Safety

This is a fork of twentyhq/twenty. You MUST:
- Minimize changes to core Twenty files
- Prefer custom objects via UI/API over code changes
- Keep HQ-specific code in clearly separated modules/files
- Never break upstream merge compatibility without explicit approval
- Use existing helpers from `twenty-shared` (`isDefined()`, `isNonEmptyString()`, `isNonEmptyArray()`)

## After Every Change

1. Run `npx nx lint:diff-with-main` on affected packages
2. Run `npx nx typecheck` on affected packages
3. Run relevant tests
4. Generate migrations if entity files changed
5. Run `graphql:generate` if GraphQL schema changed
