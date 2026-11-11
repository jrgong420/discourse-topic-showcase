import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { settings, themePrefix } from "virtual:theme";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { smallestThumbnailUrl } from "../lib/thumbnail.js";
import ContestEntries, { ENTRIES_ID } from "./contest-entries.gjs";

// The inside of the strip, the same for the button and the link. Only
// phrasing content, as it sits in a button, and no interactive elements: the
// thumbnails are decoration.
const StripContent = <template>
  {{dIcon "certificate" class="contest-strip__icon"}}
  <span class="contest-strip__text">{{@countLabel}}</span>

  {{#if @thumbnails.length}}
    <span aria-hidden="true" class="contest-strip__thumbnails">
      {{#each @thumbnails key="topic.id" as |thumbnail|}}
        <img
          alt=""
          class="contest-strip__thumbnail"
          height="32"
          loading="lazy"
          src={{thumbnail.url}}
          width="32"
        />
      {{/each}}
    </span>
  {{/if}}

  <span class="contest-strip__action">
    {{@action}}
    {{dIcon @icon}}
  </span>
</template>;

/**
 * The compact row under the title of a contest announcement: entry count,
 * thumbnails of some entries and a control for the full list of entries. The
 * whole strip is the control.
 *
 * With contest_entries_position "after_first_post" the list is rendered after
 * the first post and the control leads there. Otherwise the control is a
 * disclosure button that opens the list right below the strip; it starts
 * closed on every visit of a topic, as the strip is created per topic view.
 *
 * @param {Object} @context The contest context of an announcement.
 * @param {Topic} @topic The announcement.
 */
export default class ContestStrip extends Component {
  @tracked expanded = false;

  get isDisclosure() {
    return settings.contest_entries_position !== "after_first_post";
  }

  get countLabel() {
    const { entries, hasMore } = this.args.context;

    return hasMore
      ? i18n(themePrefix("contest.entries_more"), { count: entries.length })
      : i18n(themePrefix("contest.entries"), { count: entries.length });
  }

  // Entries that have an image, in list order.
  get thumbnails() {
    const result = [];

    for (const topic of this.args.context.entries) {
      if (result.length >= settings.contest_strip_thumbnails) {
        break;
      }

      const url = smallestThumbnailUrl(topic);
      if (url) {
        result.push({ topic, url });
      }
    }

    return result;
  }

  // The list is part of the first post, so it is only in the DOM when the
  // first post is loaded. Otherwise the control is this link: the first post
  // of the topic, with the anchor of the list, which core scrolls to.
  get href() {
    return `${this.args.topic.urlForPostNumber(1)}#${ENTRIES_ID}`;
  }

  @action
  toggle() {
    this.expanded = !this.expanded;
  }

  @action
  showEntries(event) {
    const list = document.getElementById(ENTRIES_ID);
    if (!list) {
      // Not loaded: follow the link.
      return;
    }

    event.preventDefault();

    const reduceMotion = window.matchMedia(
      "(prefers-reduced-motion: reduce)"
    ).matches;

    list.scrollIntoView({
      behavior: reduceMotion ? "auto" : "smooth",
      block: "start",
    });
    list.querySelector(".contest-entries__heading")?.focus({
      preventScroll: true,
    });
  }

  <template>
    {{#if this.isDisclosure}}
      <button
        aria-controls={{ENTRIES_ID}}
        aria-expanded={{if this.expanded "true" "false"}}
        class="contest-strip"
        type="button"
        {{on "click" this.toggle}}
      >
        <StripContent
          @action={{if
            this.expanded
            (i18n (themePrefix "contest.hide_entries"))
            (i18n (themePrefix "contest.show_entries"))
          }}
          @countLabel={{this.countLabel}}
          @icon={{if this.expanded "chevron-up" "chevron-down"}}
          @thumbnails={{this.thumbnails}}
        />
      </button>

      {{#if this.expanded}}
        <ContestEntries @belowStrip={{true}} @context={{@context}} />
      {{/if}}
    {{else}}
      <a
        class="contest-strip"
        href={{this.href}}
        {{on "click" this.showEntries}}
      >
        <StripContent
          @action={{i18n (themePrefix "contest.show_entries")}}
          @countLabel={{this.countLabel}}
          @icon="arrow-down"
          @thumbnails={{this.thumbnails}}
        />
      </a>
    {{/if}}
  </template>
}
