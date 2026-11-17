import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { settings, themePrefix } from "virtual:theme";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { participantsOf } from "../lib/contest.js";
import ContestEntries, { ENTRIES_ID } from "./contest-entries.gjs";

// The inside of the strip, the same for the button and the link. Only
// phrasing content, as it sits in a button, and no interactive elements: the
// avatars are decoration (the participant count is in the text).
const StripContent = <template>
  {{dIcon "certificate" class="contest-strip__icon"}}
  <span class="contest-strip__text">{{@countLabel}}</span>

  {{#if @avatars.length}}
    <span aria-hidden="true" class="contest-strip__avatars">
      {{#each @avatars key="@index" as |user|}}
        <span class="contest-strip__avatar">
          {{dAvatar user imageSize=28 hideTitle=true loading="lazy"}}
        </span>
      {{/each}}
      {{#if @extra}}
        <span class="contest-strip__avatar --more">+{{@extra}}</span>
      {{/if}}
    </span>
  {{/if}}

  <span class="contest-strip__action">
    {{@action}}
    {{dIcon @icon}}
  </span>
</template>;

/**
 * The compact row under the title of a contest announcement: participant
 * count, avatars of some participants and a control for the full list of
 * entries. The whole strip is the control.
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

  // The participants among the loaded entries; the avatars are the first
  // contest_strip_avatars of them.
  @cached
  get participants() {
    return participantsOf(
      this.args.context.entries,
      settings.contest_strip_avatars
    );
  }

  get countLabel() {
    const { hasMore } = this.args.context;
    const { count } = this.participants;

    return hasMore
      ? i18n(themePrefix("contest.participants_more"), { count })
      : i18n(themePrefix("contest.participants"), { count });
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
          @avatars={{this.participants.avatars}}
          @countLabel={{this.countLabel}}
          @extra={{this.participants.extra}}
          @icon={{if this.expanded "chevron-up" "chevron-down"}}
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
          @avatars={{this.participants.avatars}}
          @countLabel={{this.countLabel}}
          @extra={{this.participants.extra}}
          @icon="arrow-down"
        />
      </a>
    {{/if}}
  </template>
}
