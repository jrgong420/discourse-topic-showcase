import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { settings, themePrefix } from "virtual:theme";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { smallestThumbnailUrl } from "../lib/thumbnail.js";
import ContestEntries, { ENTRIES_ID } from "./contest-entries.gjs";

/**
 * The compact row under the title of a contest announcement: entry count,
 * thumbnails of some entries and a control for the full list of entries.
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
    <section
      aria-label={{i18n (themePrefix "contest.strip_label")}}
      class="contest-strip"
    >
      {{dIcon "certificate" class="contest-strip__icon"}}
      <span class="contest-strip__text">{{this.countLabel}}</span>

      {{#if this.thumbnails.length}}
        <ul class="contest-strip__thumbnails">
          {{#each this.thumbnails key="topic.id" as |thumbnail|}}
            <li class="contest-strip__thumbnail-item">
              <a
                aria-label={{thumbnail.topic.title}}
                class="contest-strip__thumbnail-link"
                href={{thumbnail.topic.url}}
                title={{thumbnail.topic.title}}
              >
                <img
                  alt=""
                  class="contest-strip__thumbnail"
                  height="32"
                  loading="lazy"
                  src={{thumbnail.url}}
                  width="32"
                />
              </a>
            </li>
          {{/each}}
        </ul>
      {{/if}}

      {{#if this.isDisclosure}}
        <button
          aria-controls={{ENTRIES_ID}}
          aria-expanded={{if this.expanded "true" "false"}}
          class="contest-strip__link"
          type="button"
          {{on "click" this.toggle}}
        >
          {{if
            this.expanded
            (i18n (themePrefix "contest.hide_entries"))
            (i18n (themePrefix "contest.show_entries"))
          }}
          {{dIcon
            (if this.expanded "chevron-up" "chevron-down")
            class="contest-strip__link-icon"
          }}
        </button>
      {{else}}
        <a
          class="contest-strip__link"
          href={{this.href}}
          {{on "click" this.showEntries}}
        >
          {{i18n (themePrefix "contest.show_entries")}}
          {{dIcon "arrow-down" class="contest-strip__link-icon"}}
        </a>
      {{/if}}
    </section>

    {{#if this.expanded}}
      <ContestEntries @belowStrip={{true}} @context={{@context}} />
    {{/if}}
  </template>
}
