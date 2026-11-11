import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { settings, themePrefix } from "virtual:theme";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { smallestThumbnailUrl } from "../lib/thumbnail.js";
import { ENTRIES_ID } from "./contest-entries.gjs";

/**
 * The compact row under the title of a contest announcement: entry count,
 * thumbnails of some entries and a control that leads to the full list.
 *
 * @param {Object} @context The contest context of an announcement.
 * @param {Topic} @topic The announcement.
 */
export default class ContestStrip extends Component {
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

      <a
        class="contest-strip__link"
        href={{this.href}}
        {{on "click" this.showEntries}}
      >
        {{i18n (themePrefix "contest.show_entries")}}
        {{dIcon "arrow-down" class="contest-strip__link-icon"}}
      </a>
    </section>
  </template>
}
