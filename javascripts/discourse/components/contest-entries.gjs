import Component from "@glimmer/component";
import { settings, themePrefix } from "virtual:theme";
import { getCategoryAndTagUrl } from "discourse/lib/url";
import { i18n } from "discourse-i18n";
import ShowcaseCard from "./showcase-card.gjs";

// Anchor of the list; the strip's control leads here.
export const ENTRIES_ID = "contest-entries";

/**
 * The full list of a contest's entries, as cards, rendered right after the
 * first post of the announcement.
 *
 * @param {Object} @context The contest context of an announcement.
 */
export default class ContestEntries extends Component {
  get displayed() {
    return this.args.context.entries.slice(0, settings.contest_max_entries);
  }

  get hasMore() {
    const { entries, hasMore } = this.args.context;

    return hasMore || entries.length > this.displayed.length;
  }

  get heading() {
    const { entries, hasMore } = this.args.context;

    return i18n(themePrefix("contest.heading"), {
      number: hasMore ? `${entries.length}+` : entries.length,
    });
  }

  get tagUrl() {
    return getCategoryAndTagUrl(null, true, this.args.context.tag);
  }

  <template>
    <section
      aria-labelledby="contest-entries-heading"
      class="contest-entries"
      id={{ENTRIES_ID}}
    >
      <h2
        class="contest-entries__heading"
        id="contest-entries-heading"
        tabindex="-1"
      >{{this.heading}}</h2>

      <ul class="contest-entries__grid">
        {{#each this.displayed key="id" as |topic|}}
          <li class="contest-entries__item">
            <ShowcaseCard @context="carousel" @layout="grid" @topic={{topic}} />
          </li>
        {{/each}}
      </ul>

      {{#if this.hasMore}}
        <a class="contest-entries__more" href={{this.tagUrl}}>
          {{i18n (themePrefix "contest.view_all")}}
        </a>
      {{/if}}
    </section>
  </template>
}
