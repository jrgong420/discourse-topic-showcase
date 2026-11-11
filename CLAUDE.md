# Topic Showcase (Discourse theme component)

- Load the `discourse-theme-authoring` skill before writing theme code; `discourse-block-authoring` for blocks.
- Must work on Discourse 2026.7.x, on the default theme family and on Horizon: style with core CSS variables / theme tokens only.
- Runs on more than one forum: no site-specific values in code, everything site-specific is a theme setting.
- Never copy core SCSS into this repo. Use value/behavior transformers and plugin outlets, not template overrides.
- Carousel engine is Embla (decided; core's image carousel is not reusable).
- Lint before committing: `pnpm lint`.
