# Code style
- Use ES modules (import/export) syntax, not CommonJS (require)
- Destructure imports when possible (eg. import { foo } from 'bar')
- TypeScript strict mode, no `any` types
- Prefer absolute imports over `../..`

# Workflow
- Be sure to typecheck when you're done making a series of code changes
- Prefer running single tests, and not the whole test suite, for performance

# Package Managers
- With Node projects prefer PNPM (and pnpx) over NPM (and npx). If there's a `package-lock.json` ask what to do, and offer `pnpm import` and to delete the `package-lock.json`
- With Python projects prefer UV and project files

# Spelling
- Use British English spellings like "colour" instead of "color" in documentation, comments, and conversations with me
