# Topic Showcase

Discourse theme component, four parts, each toggled by settings:

1. **Topic cards** — list or grid cards with thumbnails in topic lists, chosen per category for desktop and mobile.
2. **Featured topics carousel** — collapsible carousel of topics with a featured tag, with a "new since you last looked" indicator. Shown above the topic list when the homepage is a topic list; for a block-based homepage it is also registered as the block `theme:topic-showcase:featured-carousel`, which another theme can place in its layout (`{ block: "theme:topic-showcase:featured-carousel?" }`).
3. **Contest entries** — on a contest announcement topic, lists every topic that shares the contest's tag.

4. **Custom homepage** — optional (`homepage_enabled`, off by default): a block-based homepage with the carousel, releases, documentation, latest topics, a showcase gallery, partners, open questions and deals. Every section is optional. While it is off, the homepage outlet is left to other themes.

Requires Discourse 2026.7 or newer. Install it as a theme component from this repository's URL and add it to your theme. Successor to `jrgong420/advanced-topic-cards`.

## Development

From this directory:

    pnpm install && pnpm lint

Agent skills live in `.claude/skills/` (official `discourse/discourse-theme-skills`).
