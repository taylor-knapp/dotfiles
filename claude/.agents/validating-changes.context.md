# Code Validation: Quick Reference

When editing or writing files, load [validating-changes.md](.agents/validating-changes.md) for the full procedure.

**Validation commands (run prettier first — it fixes formatting that would show as lint errors):**

- Single file: `pnpm exec prettier --write FILE.ts` then `pnpm --filter ./packages/PKG typecheck` then `pnpm exec eslint FILE.ts` then run related tests (Jest: `pnpm exec jest --findRelatedTests --listTests FILE.ts`; Vitest: `pnpm exec vitest related FILE.ts --run`)
- Package: `pnpm exec prettier --write "packages/PKG/**/*.{ts,tsx,js,jsx,json,md}"` then `pnpm --filter ./packages/PKG typecheck` then `pnpm exec eslint packages/PKG`
- Monorepo: `pnpm format` then `pnpm typecheck` then `pnpm lint` then `pnpm test`

**Procedure:** Add "Validate changes" as final action item. Format with prettier first. Run remaining checks. Fix all errors, warnings, and deprecations. Mark complete only when validation is fully clean.
