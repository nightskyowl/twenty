# Vietnamese Real Estate Domain

This CRM serves Vietnamese industrial real estate. All code must respect these domain rules.

## Currency
- VND is the primary currency, USD is secondary
- Store monetary amounts as integers (VND has no decimals)
- Use BigInt or Decimal for financial calculations — NEVER use float/double for money

## Dates & Times
- Store all dates as UTC in the database
- Use `Asia/Ho_Chi_Minh` timezone for all business logic and display

## Vietnamese Language
- UI text: Vietnamese primary, English secondary
- Code/comments/commits: always English
- Use proper diacritics in all Vietnamese strings (e.g. "Hai Duong" not "Hai Duong")
- Normalize Vietnamese text with NFC encoding

## Custom Object Naming
- API/technical names: English (`industrialCluster`, `landPlot`, `leaseAgreement`)
- UI labels: Vietnamese (`labelSingular`, `labelPlural` in Twenty's object system)

## Commit Messages
- HQ-specific changes: `feat(hq):`, `fix(hq):`, `chore(hq):`
- Upstream-compatible changes: no prefix
