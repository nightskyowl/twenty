# CLAUDE.md

This file provides guidance to Claude Code when working on this repository.

## Multi-Agent Workflow

```
Nathan + Claude Code  -->  Antigravity  -->  Claude Code
   (plan & prompt)      (implement & test)    (review)
```

### Your Role (Claude Code)
1. **Discuss & brainstorm** with Nathan — explore ideas, tradeoffs, approaches
2. **Plan the work** — break down into clear, actionable steps
3. **Prepare prompts for Antigravity** — write detailed implementation specs that Antigravity can execute. Include: what files to create/modify, exact behavior expected, test criteria, and verification steps.
4. **Review Antigravity's output** — read the code Antigravity wrote, check correctness, style, fork safety, and domain rules. Leave clear, actionable comments for Antigravity to fix.
5. **Verify fixes** — confirm Antigravity addressed review feedback correctly

### Writing Prompts for Antigravity
When preparing work for Antigravity, structure prompts as:
- **Goal:** One sentence describing what to build
- **Files:** Which files to create or modify (be specific)
- **Spec:** Exact behavior, field names, types, relationships
- **Constraints:** Fork safety rules, naming conventions, anything non-obvious
- **Verify:** Commands to run after implementation (lint, typecheck, test)
- **Done when:** Clear acceptance criteria

### Antigravity's Config
Antigravity reads `AGENTS.md` and `.agent/rules/` in this repo. Those files mirror the coding guidelines, fork safety rules, and domain rules from this file, plus define Antigravity's role as executor.

## Project Identity

**Project:** Hoa Quan Real Estate CRM (codename: HQ-CRM)
**Fork of:** [twentyhq/twenty](https://github.com/twentyhq/twenty) — The #1 Open-Source CRM
**Owner:** Nathan Nguyen (Nguyen Nam Thanh) — CEO of UpNext, Director of Hoa Quan
**Repo:** github.com/nightskyowl/twenty

## What We Are Building

A vertical CRM platform for Vietnamese real estate companies, built on top of Twenty CRM. The product serves two purposes:

1. **Internal tool** — Powers Hoa Quan's own industrial park leasing operations (4 industrial clusters in Hai Duong province, Vietnam)
2. **Commercial product** — A productized RE CRM sold to other Vietnamese real estate companies (industrial parks, residential developers, commercial RE firms)

The business model is SaaS (hosted) — we host the platform, customers pay per-user or per-company monthly. This avoids GPL distribution obligations since we never distribute the binary.

## Business Domain: Vietnamese Industrial Real Estate

Hoa Quan owns and operates industrial parks and clusters in Hai Duong province:
- **Doan Tung 2** — 46.8 ha
- **Nghia An** — 61.8 ha
- **Ngu Hung - Thanh Giang** — 75 ha
- **An Duc** — 75 ha

The sales cycle:
```
Inquiry -> Qualification -> Site Visit -> Negotiation -> Contract Signing -> Land Handover -> Post-lease Management
```

Key personas:
- **Sales team** — manages investor inquiries, site visits, negotiations
- **Operations team** — manages infrastructure, handover, ongoing tenant relations
- **Finance team** — manages lease payments, deposits, commissions
- **Management** — dashboards, reporting, strategic decisions

## Architecture Overview

### Tech Stack
- **Frontend**: React 18, TypeScript, Jotai (state management), Linaria (styling), Vite
- **Backend**: NestJS, TypeORM, PostgreSQL, Redis, GraphQL (with GraphQL Yoga)
- **Monorepo**: Nx workspace managed with Yarn 4

### Package Structure
```
packages/
├── twenty-front/          # React frontend application
├── twenty-server/         # NestJS backend API
├── twenty-ui/             # Shared UI components library
├── twenty-shared/         # Common types and utilities
├── twenty-emails/         # Email templates with React Email
├── twenty-website/        # Next.js documentation website
├── twenty-zapier/         # Zapier integration
└── twenty-e2e-testing/    # Playwright E2E tests
```

### AI Integration Layer
```
┌─────────────────────────────────────────┐
│           Twenty CRM (this repo)         │
│     Frontend (React) + Backend (NestJS)  │
│        Data: PostgreSQL + Redis          │
└──────────────┬───────────────────────────┘
               │ GraphQL / REST API
               ▼
┌─────────────────────────────────────────┐
│        AI Middleware Service              │
│   (separate repo/service — proprietary)  │
│                                          │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐ │
│  │  Sales   │ │Operations│ │ Finance  │ │
│  │  Agent   │ │  Agent   │ │  Agent   │ │
│  └─────────┘ └──────────┘ └──────────┘ │
│              │                           │
│         LLM APIs (Claude)                │
│         Vector DB (context/RAG)          │
└─────────────────────────────────────────┘
```

The AI layer is a **separate service** — it communicates with Twenty via API. This keeps:
- The fork clean and mergeable with upstream
- The AI logic as proprietary IP (not GPL)
- Deployment independently scalable

### AI Capabilities (phased)
- **Phase 1:** Chat assistant inside CRM — natural language queries, email drafting, data summaries
- **Phase 2:** Proactive automation — lease renewal reminders, lead scoring, payment alerts
- **Phase 3:** Intelligence — pricing recommendations, investor matching, churn prediction
- **Phase 4:** Autonomous agents — specialized agents per department

## Custom Data Model

These extend Twenty's default objects (People, Companies, Opportunities, Notes, Tasks).

### Industrial Clusters (Cum/Khu Cong Nghiep)
- `name` (text) — cluster name
- `location` (address) — Hai Duong province location
- `totalAreaHa` (number) — total area in hectares
- `availableAreaHa` (number) — remaining leasable area
- `occupancyRate` (number) — percentage occupied
- `infrastructureStatus` (select) — Planning / Under Construction / Operational / Expanding
- `basePricePerSqm` (currency) — base leasing price per m2
- `utilities` (multi-select) — Power / Water / Drainage / Telecom / Road / Wastewater Treatment
- `managementCompany` (relation -> Company) — link to Hoa Quan entity

### Land Plots (Lo Dat)
- `plotCode` (text) — unique plot identifier
- `cluster` (relation -> Industrial Cluster)
- `areaSqm` (number) — plot area in square meters
- `frontageM` (number) — road frontage in meters
- `status` (select) — Available / Reserved / Leased / Built / Returned
- `pricePerSqm` (currency) — actual or asking price
- `utilities` (multi-select) — available infrastructure on this plot
- `currentTenant` (relation -> Company) — if leased
- `leaseAgreement` (relation -> Lease Agreement) — active lease

### Lease Agreements (Hop Dong Thue)
- `contractNumber` (text) — official contract ID
- `tenant` (relation -> Company)
- `plot` (relation -> Land Plot)
- `startDate` (date)
- `endDate` (date)
- `termYears` (number)
- `rentPerSqm` (currency)
- `totalRentAnnual` (currency)
- `paymentFrequency` (select) — Monthly / Quarterly / Semi-annual / Annual
- `deposit` (currency)
- `status` (select) — Draft / Active / Expiring / Expired / Terminated / Renewed
- `renewalDate` (date) — when renewal negotiation should begin
- `specialConditions` (rich text)

### Investors/Tenants (Nha Dau Tu) — extends Companies
- `investorType` (select) — FDI / Domestic / Joint Venture
- `countryOfOrigin` (text) — for FDI investors
- `industryType` (select) — Manufacturing / Logistics / Tech / Food Processing / Other
- `investmentCapital` (currency) — registered investment amount
- `workforceSize` (number) — projected or actual employee count
- `businessLicense` (text) — Vietnamese business registration number
- `taxCode` (text) — Ma so thue

### Transactions (Giao Dich Tai Chinh)
- `type` (select) — Deposit / Rent Payment / Commission / Refund / Penalty / Infrastructure Fee
- `lease` (relation -> Lease Agreement)
- `amount` (currency)
- `currency` (select) — VND / USD
- `dueDate` (date)
- `paidDate` (date)
- `status` (select) — Pending / Paid / Overdue / Partial / Cancelled
- `paymentMethod` (select) — Bank Transfer / Cash / LC
- `reference` (text) — bank reference or receipt number
- `notes` (rich text)

### Infrastructure Progress (Tien Do Ha Tang)
- `cluster` (relation -> Industrial Cluster)
- `category` (select) — Road / Power Grid / Water Supply / Drainage / Wastewater / Telecom / Landscaping
- `status` (select) — Not Started / In Progress / Completed / Maintenance
- `contractor` (relation -> Company)
- `startDate` (date)
- `expectedCompletion` (date)
- `actualCompletion` (date)
- `budget` (currency)
- `actualCost` (currency)
- `progressPercent` (number)

### Pipeline Stages (Opportunities)

Rename default Opportunity stages to match RE sales cycle:
```
Inquiry -> Qualified -> Site Visit Scheduled -> Site Visit Done -> Negotiation -> Contract Draft -> Contract Signed -> Handover -> Post-lease
```

## Development Priorities

### Phase 1: Foundation (current)
- [ ] Run Twenty locally, explore default features
- [ ] Create custom objects via UI (all objects listed above)
- [ ] Configure pipeline stages for RE sales cycle
- [ ] Vietnamese language pack / i18n
- [ ] Basic Zalo OA webhook integration

### Phase 2: Core Product
- [ ] Transaction tracking and payment management
- [ ] Occupancy dashboard per cluster
- [ ] Lease lifecycle management (renewal alerts, expiration tracking)
- [ ] Document attachment and management (contracts, licenses, permits)
- [ ] Role-based access (Sales vs Operations vs Finance vs Management views)

### Phase 3: AI & Automation
- [ ] AI middleware service (separate repo)
- [ ] Chat widget in Twenty frontend
- [ ] Workflow automations (lease renewal, payment overdue, lead assignment)
- [ ] Email templates for Vietnamese RE communications

### Phase 4: Productization
- [ ] Multi-tenant support (one instance, many RE companies)
- [ ] Onboarding flow for new RE company customers
- [ ] Billing integration
- [ ] Marketing site and documentation
- [ ] Custom branding per tenant

## Technical Decisions

### Fork Strategy
- Keep upstream `twentyhq/twenty` as a remote: `git remote add upstream https://github.com/twentyhq/twenty.git`
- Regularly merge upstream changes into our fork
- Minimize core codebase modifications — prefer custom objects (via UI/API), separate services, and configuration over code changes
- When code changes are necessary, keep them in clearly separated modules/files

### What Lives Where
| Layer | Location | License |
|-------|----------|---------|
| Twenty CRM core | This repo (fork) | AGPL (upstream) |
| Custom objects & config | Twenty UI/API (no code) | N/A — data |
| Vietnamese i18n | This repo (contribution back upstream possible) | AGPL |
| AI middleware | Separate repo (TBD) | Proprietary |
| Zalo/VN integrations | Separate service or Twenty webhook | Proprietary |
| Marketing site | Separate repo | Proprietary |

### Stack Additions (beyond Twenty's stack)
- **AI middleware:** Node.js or Python service, Anthropic Claude API, vector DB (Qdrant or Pinecone)
- **Zalo integration:** Zalo OA API -> webhook receiver -> Twenty REST API
- **Vietnamese payments:** VNPay / Momo API integration (for future SaaS billing)
- **Analytics:** Metabase connected to Twenty's PostgreSQL (for BI dashboards beyond Twenty's built-in views)

## Key Commands

### Development
```bash
# Start development environment (frontend + backend + worker)
yarn start

# Individual package development
npx nx start twenty-front     # Start frontend dev server
npx nx start twenty-server    # Start backend server
npx nx run twenty-server:worker  # Start background worker
```

### Dev Environment Setup
```bash
bash packages/twenty-utils/setup-dev-env.sh
```
This handles everything: starts Postgres + Redis (auto-detects local services vs Docker), creates databases, and copies `.env` files. Idempotent — safe to run multiple times.
- `--docker` — force Docker mode (uses `packages/twenty-docker/docker-compose.dev.yml`)
- `--down` — stop services
- `--reset` — wipe data and restart fresh

### Testing
```bash
# Preferred: run a single test file (fast)
npx jest path/to/test.test.ts --config=packages/PROJECT/jest.config.mjs

# Run all tests for a package
npx nx test twenty-front
npx nx test twenty-server
npx nx run twenty-server:test:integration:with-db-reset

# Individual test pattern
cd packages/{workspace} && npx jest "pattern or filename"

# Storybook
npx nx storybook:build twenty-front
npx nx storybook:test twenty-front

# When testing the UI end to end, click on "Continue with Email" and use the prefilled credentials.
```

### Code Quality
```bash
# Linting (diff with main - fastest, always prefer this)
npx nx lint:diff-with-main twenty-front
npx nx lint:diff-with-main twenty-server
npx nx lint:diff-with-main twenty-front --configuration=fix  # Auto-fix

# Type checking
npx nx typecheck twenty-front
npx nx typecheck twenty-server

# Format code
npx nx fmt twenty-front
npx nx fmt twenty-server
```

### Build
```bash
# Build packages (twenty-shared must be built first)
npx nx build twenty-shared
npx nx build twenty-front
npx nx build twenty-server
```

### Database Operations
```bash
npx nx database:reset twenty-server
npx nx run twenty-server:database:init:prod
npx nx run twenty-server:database:migrate:prod

# Generate migration (replace [name] with kebab-case descriptive name)
npx nx run twenty-server:typeorm migration:generate src/database/typeorm/core/migrations/common/[name] -d src/database/typeorm/core/core.datasource.ts

# Sync metadata
npx nx run twenty-server:command workspace:sync-metadata
```

### Database Inspection (Postgres MCP)

A read-only Postgres MCP server is configured in `.mcp.json`. Use it to:
- Inspect workspace data, metadata, and object definitions while developing
- Verify migration results (columns, types, constraints) after running migrations
- Explore the multi-tenant schema structure (core, metadata, workspace-specific schemas)
- Debug issues by querying raw data
- Inspect metadata tables to debug GraphQL schema generation or `workspace:sync-metadata` issues

### GraphQL
```bash
# Generate GraphQL types (run after schema changes)
npx nx run twenty-front:graphql:generate
npx nx run twenty-front:graphql:generate --configuration=metadata
```

## Coding Guidelines

### Key Development Principles
- **Functional components only** (no class components)
- **Named exports only** (no default exports)
- **Types over interfaces** (except when extending third-party interfaces)
- **String literals over enums** (except for GraphQL enums)
- **No 'any' type allowed** — strict TypeScript enforced
- **Event handlers preferred over useEffect** for state updates
- **Props down, events up** — unidirectional data flow
- **Composition over inheritance**
- **No abbreviations** in variable names (`user` not `u`, `fieldMetadata` not `fm`)

### Naming Conventions
- **Variables/functions**: camelCase
- **Constants**: SCREAMING_SNAKE_CASE
- **Types/Classes**: PascalCase (suffix component props with `Props`, e.g. `ButtonProps`)
- **Files/directories**: kebab-case with descriptive suffixes (`.component.tsx`, `.service.ts`, `.entity.ts`, `.dto.ts`, `.module.ts`)
- **TypeScript generics**: descriptive names (`TData` not `T`)

### File Structure
- Components under 300 lines, services under 500 lines
- Components in their own directories with tests and stories
- Use `index.ts` barrel exports for clean imports
- Import order: external libraries first, then internal (`@/`), then relative

### Comments
- Use short-form comments (`//`), not JSDoc blocks
- Explain WHY (business logic), not WHAT
- Do not comment obvious code
- Multi-line comments use multiple `//` lines, not `/** */`

### State Management
- **Jotai** for global state: atoms for primitive state, selectors for derived state, atom families for dynamic collections
- Component-specific state with React hooks (`useState`, `useReducer` for complex logic)
- GraphQL cache managed by Apollo Client
- Use functional state updates: `setState(prev => prev + 1)`

### Backend Architecture
- **NestJS modules** for feature organization
- **TypeORM** for database ORM with PostgreSQL
- **GraphQL** API with code-first approach
- **Redis** for caching and session management
- **BullMQ** for background job processing

### Database & Migrations
- Always generate migrations when changing entity files
- Migration names must be kebab-case (e.g. `add-agent-turn-evaluation`)
- Include both `up` and `down` logic in migrations
- Never delete or rewrite committed migrations

### Utility Helpers
Use existing helpers from `twenty-shared` instead of manual type guards:
- `isDefined()`, `isNonEmptyString()`, `isNonEmptyArray()`

### HQ-CRM Specific Guidelines
- **Language in code:** All code, comments, variable names, and commit messages in English
- **Language in UI/content:** Vietnamese as primary user-facing language, English as secondary
- **Currency:** Always support VND as primary, USD as secondary. Store amounts as integers (VND has no decimals). Use BigInt or Decimal for financial calculations — never float.
- **Dates/times:** Use Asia/Ho_Chi_Minh timezone for all business logic. Store as UTC in database.
- **Vietnamese text:** Use proper diacritics (Hai Duong, not Hai Duong). Normalize with NFC.
- **Naming custom objects:** Use English for technical names (objectName in API), Vietnamese for labels (labelSingular/labelPlural displayed in UI)
- **Commit convention:** `feat(hq):`, `fix(hq):`, `chore(hq):` prefix for Hoa Quan-specific changes. No prefix for upstream-compatible changes.

### Testing Strategy
- **Test behavior, not implementation** — focus on user perspective
- **Test pyramid**: 70% unit, 20% integration, 10% E2E
- Query by user-visible elements (text, roles, labels) over test IDs
- Use `@testing-library/user-event` for realistic interactions
- Descriptive test names: "should [behavior] when [condition]"
- Clear mocks between tests with `jest.clearAllMocks()`

### Style & i18n
- Use **Linaria** for styling with zero-runtime CSS-in-JS (styled-components pattern)
- Use **Lingui** for internationalization
- Apply security first, then formatting (sanitize before format)

## Development Workflow

### Before Making Changes
1. Always run linting (`lint:diff-with-main`) and type checking after code changes
2. Test changes with relevant test suites (prefer single-file test runs)
3. Ensure database migrations are generated for entity changes
4. Check that GraphQL schema changes are backward compatible
5. Run `graphql:generate` after any GraphQL schema changes

### Environment
- **Dev IDE:** Google Antigravity (primary), Claude Code for planning and review
- **Workflow:** Nathan + Claude brainstorm/plan -> Claude writes prompts -> Antigravity implements -> Claude reviews

## Key URLs

- Hoa Quan current site: https://vi.hoaquanland.com/
- Twenty docs: https://docs.twenty.com
- Twenty API docs: Available at `http://localhost:3000/rest` after setup
- Twenty GraphQL: `http://localhost:3000/graphql`
- Twenty GitHub (upstream): https://github.com/twentyhq/twenty
- This fork: https://github.com/nightskyowl/twenty

## Important Files
- `nx.json` - Nx workspace configuration with task definitions
- `tsconfig.base.json` - Base TypeScript configuration
- `package.json` - Root package with workspace definitions
- `.mcp.json` - MCP server configurations (Postgres, Playwright, Context7)
