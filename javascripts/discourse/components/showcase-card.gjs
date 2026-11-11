import Component from "@glimmer/component";
import { settings, themePrefix } from "virtual:theme";
import TopicLink from "discourse/components/topic-list/topic-link";
import UnreadIndicator from "discourse/components/topic-list/unread-indicator";
import TopicPostBadges from "discourse/components/topic-post-badges";
import TopicStatus from "discourse/components/topic-status";
import { shortDate, smartShortDate } from "discourse/lib/formatter";
import { eq, gt, or } from "discourse/truth-helpers";
import DUserLink from "discourse/ui-kit/d-user-link";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dCategoryLink from "discourse/ui-kit/helpers/d-category-link";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dDirSpan from "discourse/ui-kit/helpers/d-dir-span";
import dDiscourseTags from "discourse/ui-kit/helpers/d-discourse-tags";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import dNumber from "discourse/ui-kit/helpers/d-number";
import { i18n } from "discourse-i18n";

// Width in CSS pixels the thumbnail should cover in the list layout.
const LIST_THUMBNAIL_TARGET_WIDTH = 360;
// Grid cards can grow beyond the minimum width, and screens can be dense.
const GRID_THUMBNAIL_WIDTH_FACTOR = 1.5;

/**
 * A topic card with thumbnail, title and metadata. Independent of the topic
 * list table: it can be rendered anywhere a topic is available.
 *
 * @param {Topic} @topic
 * @param {"list"|"grid"} @layout
 * @param {boolean} [@eventDate] Show the start date of the topic's calendar
 *   event (`event_starts_at`) as a badge over the thumbnail.
 */
export default class ShowcaseCard extends Component {
  get layout() {
    return this.args.layout === "grid" ? "grid" : "list";
  }

  get thumbnail() {
    const { thumbnails, image_url: imageUrl } = this.args.topic;

    if (!thumbnails?.length) {
      return imageUrl ? { url: imageUrl } : null;
    }

    const targetWidth =
      this.layout === "grid"
        ? settings.grid_card_min_width * GRID_THUMBNAIL_WIDTH_FACTOR
        : LIST_THUMBNAIL_TARGET_WIDTH;

    const bySize = [...thumbnails].sort((a, b) => a.width - b.width);
    return (
      bySize.find((thumbnail) => thumbnail.width >= targetWidth) ??
      bySize[bySize.length - 1]
    );
  }

  get hasMetadata() {
    return (
      settings.show_reply_count ||
      settings.show_likes ||
      settings.show_views ||
      settings.show_activity ||
      settings.show_publish_date
    );
  }

  get showAuthor() {
    return settings.show_author && this.args.topic.creator;
  }

  // Short localised date of the event start, with the year only when it is not
  // this year ("20 Jun", "Jun 20, 2025").
  get eventDate() {
    const start = this.args.topic.event_starts_at;
    if (!this.args.eventDate || !start) {
      return null;
    }

    const date = new Date(start);
    if (Number.isNaN(date.getTime())) {
      return null;
    }

    return { iso: date.toISOString(), label: smartShortDate(date, shortDate) };
  }

  get showExcerpt() {
    return settings.show_excerpt && this.args.topic.hasExcerpt;
  }

  <template>
    <article
      class={{dConcatClass
        "showcase-card"
        (if (eq this.layout "grid") "--grid" "--list")
        (if this.thumbnail "--has-thumbnail" "--no-thumbnail")
        (if @topic.visited "--visited")
      }}
      data-topic-id={{@topic.id}}
      ...attributes
    >
      <div class="showcase-card__media">
        {{#if this.thumbnail}}
          <img
            alt=""
            class="showcase-card__image"
            decoding="async"
            height={{this.thumbnail.height}}
            loading="lazy"
            src={{this.thumbnail.url}}
            width={{this.thumbnail.width}}
          />
        {{else}}
          <span aria-hidden="true" class="showcase-card__placeholder">
            {{dIcon settings.thumbnail_placeholder_icon}}
          </span>
        {{/if}}

        {{#if this.eventDate}}
          <time
            class="showcase-card__event-date"
            datetime={{this.eventDate.iso}}
          >
            {{this.eventDate.label}}
          </time>
        {{/if}}
      </div>

      <div class="showcase-card__body">
        {{#if settings.show_category}}
          {{#if @topic.category}}
            <div class="showcase-card__category">
              {{dCategoryLink @topic.category}}
            </div>
          {{/if}}
        {{/if}}

        <h3 class="showcase-card__title">
          {{~! no whitespace ~}}
          <TopicStatus @context="topic-list" @topic={{@topic}} />
          {{~! no whitespace ~}}
          <TopicLink
            class="showcase-card__link raw-link raw-topic-link"
            @topic={{@topic}}
          />
          {{~! no whitespace ~}}
          <UnreadIndicator @topic={{@topic}} />
          <TopicPostBadges
            @unreadPosts={{@topic.unread_posts}}
            @unseen={{@topic.unseen}}
            @url={{@topic.lastUnreadUrl}}
          />
        </h3>

        {{#if this.showExcerpt}}
          <p class="showcase-card__excerpt">
            {{dDirSpan @topic.escapedExcerpt htmlSafe="true"}}
          </p>
        {{/if}}

        {{#if settings.show_tags}}
          {{#if @topic.tags.length}}
            <div class="showcase-card__tags">
              {{dDiscourseTags @topic mode="list"}}
            </div>
          {{/if}}
        {{/if}}

        {{#if (or this.showAuthor this.hasMetadata)}}
          <div class="showcase-card__footer">
            {{#if this.showAuthor}}
              <DUserLink class="showcase-card__author" @user={{@topic.creator}}>
                {{dAvatar @topic.creator imageSize="small"}}
                <span
                  class="showcase-card__username"
                >{{@topic.creator.username}}</span>
              </DUserLink>
            {{/if}}

            {{#if this.hasMetadata}}
              <ul class="showcase-card__meta">
                {{#if settings.show_reply_count}}
                  <li
                    class="showcase-card__meta-item --replies"
                    title={{i18n (themePrefix "showcase.replies")}}
                  >
                    {{dIcon "comment"}}
                    <span class="sr-only">{{i18n
                        (themePrefix "showcase.replies")
                      }}</span>
                    {{dNumber @topic.replyCount noTitle="true"}}
                  </li>
                {{/if}}
                {{#if settings.show_likes}}
                  {{#if (gt @topic.like_count 0)}}
                    <li
                      class="showcase-card__meta-item --likes"
                      title={{i18n (themePrefix "showcase.likes")}}
                    >
                      {{dIcon "heart"}}
                      <span class="sr-only">{{i18n
                          (themePrefix "showcase.likes")
                        }}</span>
                      {{dNumber @topic.like_count noTitle="true"}}
                    </li>
                  {{/if}}
                {{/if}}
                {{#if settings.show_views}}
                  <li
                    class="showcase-card__meta-item --views"
                    title={{i18n (themePrefix "showcase.views")}}
                  >
                    {{dIcon "eye"}}
                    <span class="sr-only">{{i18n
                        (themePrefix "showcase.views")
                      }}</span>
                    {{dNumber @topic.views noTitle="true"}}
                  </li>
                {{/if}}
                {{#if settings.show_activity}}
                  <li
                    class="showcase-card__meta-item --activity"
                    title={{i18n (themePrefix "showcase.activity")}}
                  >
                    {{dIcon "clock-rotate-left"}}
                    <span class="sr-only">{{i18n
                        (themePrefix "showcase.activity")
                      }}</span>
                    {{dFormatDate
                      @topic.bumpedAt
                      format="medium"
                      leaveAgo="true"
                    }}
                  </li>
                {{/if}}
                {{#if settings.show_publish_date}}
                  <li
                    class="showcase-card__meta-item --published"
                    title={{i18n (themePrefix "showcase.published")}}
                  >
                    {{dIcon "calendar-days"}}
                    <span class="sr-only">{{i18n
                        (themePrefix "showcase.published")
                      }}</span>
                    {{dFormatDate
                      @topic.createdAt
                      format="medium"
                      noTitle="true"
                    }}
                  </li>
                {{/if}}
              </ul>
            {{/if}}
          </div>
        {{/if}}
      </div>
    </article>
  </template>
}
