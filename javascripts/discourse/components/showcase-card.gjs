import Component from "@glimmer/component";
import { settings, themePrefix } from "virtual:theme";
import TopicLink from "discourse/components/topic-list/topic-link";
import UnreadIndicator from "discourse/components/topic-list/unread-indicator";
import TopicPostBadges from "discourse/components/topic-post-badges";
import TopicStatus from "discourse/components/topic-status";
import { shortDate, smartShortDate } from "discourse/lib/formatter";
import { eq, gt } from "discourse/truth-helpers";
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
 * @param {"list"|"carousel"} [@context] Where the card is used. In the
 *   "carousel" context the card has a fixed height (clamped text) and reads
 *   the carousel_show_* settings for excerpt, tags, replies, likes and
 *   activity instead of the global show_* ones; views and publish date are
 *   not shown.
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

  // list_card_height gives list cards one fixed height (from sm up).
  get hasFixedHeight() {
    return this.layout === "list" && settings.list_card_height > 0;
  }

  get isCarousel() {
    return this.args.context === "carousel";
  }

  // The parts that differ between the carousel and the topic lists. Everything
  // else on the card keeps using the global show_* settings.
  get showReplyCount() {
    return this.isCarousel
      ? settings.carousel_show_reply_count
      : settings.show_reply_count;
  }

  get showLikes() {
    return this.isCarousel ? settings.carousel_show_likes : settings.show_likes;
  }

  get showViews() {
    return !this.isCarousel && settings.show_views;
  }

  get showActivity() {
    return this.isCarousel
      ? settings.carousel_show_activity
      : settings.show_activity;
  }

  get showPublishDate() {
    return !this.isCarousel && settings.show_publish_date;
  }

  get hasMetadata() {
    return (
      this.showReplyCount ||
      this.showLikes ||
      this.showViews ||
      this.showActivity ||
      this.showPublishDate
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

  // Carousel cards reserve the space of the parts they show (the elements
  // render even when empty), so every card has the same height.
  get showExcerpt() {
    return this.isCarousel
      ? settings.carousel_show_excerpt
      : settings.show_excerpt && this.args.topic.hasExcerpt;
  }

  get showTags() {
    return this.isCarousel
      ? settings.carousel_show_tags
      : settings.show_tags && this.args.topic.tags?.length;
  }

  get showCategory() {
    return (
      settings.show_category && (this.args.topic.category || this.isCarousel)
    );
  }

  get showFooter() {
    return (
      this.showAuthor ||
      this.hasMetadata ||
      (this.isCarousel && settings.show_author)
    );
  }

  <template>
    <article
      class={{dConcatClass
        "showcase-card"
        (if (eq this.layout "grid") "--grid" "--list")
        (if this.thumbnail "--has-thumbnail" "--no-thumbnail")
        (if @topic.visited "--visited")
        (if this.isCarousel "--carousel")
        (if this.hasFixedHeight "--fixed-height")
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
        {{#if this.showCategory}}
          <div class="showcase-card__category">
            {{#if @topic.category}}
              {{dCategoryLink @topic.category}}
            {{/if}}
          </div>
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
            {{#if @topic.hasExcerpt}}
              {{dDirSpan @topic.escapedExcerpt htmlSafe="true"}}
            {{/if}}
          </p>
        {{/if}}

        {{#if this.showTags}}
          <div class="showcase-card__tags">
            {{#if @topic.tags.length}}
              {{dDiscourseTags @topic mode="list"}}
            {{/if}}
          </div>
        {{/if}}

        {{#if this.showFooter}}
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
                {{#if this.showReplyCount}}
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
                {{#if this.showLikes}}
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
                {{#if this.showViews}}
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
                {{#if this.showActivity}}
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
                {{#if this.showPublishDate}}
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
