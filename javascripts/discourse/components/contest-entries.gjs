import Component from "@glimmer/component";
import { settings, themePrefix } from "virtual:theme";
import { getCategoryAndTagUrl } from "discourse/lib/url";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";
import ShowcaseCard from "./showcase-card.gjs";

// Anchor of the list; the strip's control leads or points here.
export const ENTRIES_ID = "contest-entries";

/**
 * The full list of a contest's entries, as cards in the contest_entries_layout
 * (list or grid): either right after the first post of the announcement, or
 * opened in place below the strip.
 *
 * @param {Object} @context The contest context of an announcement.
 * @param {boolean} [@belowStrip] The list sits directly below the strip.
 */
export default class ContestEntries extends Component {
  get layout() {
    return settings.contest_entries_layout === "grid" ? "grid" : "list";
  }

  get isGrid() {
    return this.layout === "grid";
  }

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
      class={{dConcatClass
        "contest-entries"
        (if this.isGrid "--grid" "--list")
        (if @belowStrip "--below-strip")
      }}
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
            <ShowcaseCard
              @context="carousel"
              @layout={{this.layout}}
              @topic={{topic}}
            />
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
