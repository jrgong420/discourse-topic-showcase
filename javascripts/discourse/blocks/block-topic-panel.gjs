import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import { themePrefix } from "virtual:theme";
import { block } from "discourse/blocks";
import TopicLink from "discourse/components/topic-list/topic-link";
import { bind } from "discourse/lib/decorators";
import getURL from "discourse/lib/get-url";
import { eq } from "discourse/truth-helpers";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dCategoryLink from "discourse/ui-kit/helpers/d-category-link";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import dNumber from "discourse/ui-kit/helpers/d-number";
import { i18n } from "discourse-i18n";
import HomepagePanel from "../components/homepage-panel.gjs";
import ShowcaseCard from "../components/showcase-card.gjs";
import {
  fetchPanelTopics,
  filterSlug,
  homepageQuery,
} from "../lib/homepage-topics.js";
import { smallestThumbnailUrl } from "../lib/thumbnail.js";

const SKELETON_ROWS = { rows: "topic", cards: "card", tiles: "tile" };

/**
 * A homepage panel of topics, chosen by tags and/or a category, or a core
 * list. Renders nothing when it is not configured or finds no topics, so an
 * unused section simply disappears.
 *
 * display:
 * - rows:  compact rows (title, category, date, replies); for text-heavy lists
 * - cards: the showcase grid cards with thumbnails
 * - tiles: logo tiles (image contained, title below); for vendors or partners
 */
@block("theme:topic-showcase:topic-panel", {
  description: "Topics by tag, category or list, as rows, cards or tiles",
  args: {
    title: { type: "string", required: true },
    icon: { type: "string" },
    tags: { type: "array", itemType: "string", default: [] },
    categoryId: { type: "number" },
    list: { type: "string" },
    order: {
      type: "string",
      enum: ["activity", "created"],
      default: "activity",
    },
    status: { type: "string" },
    count: { type: "number", default: 5, min: 1, max: 30, integer: true },
    display: {
      type: "string",
      enum: ["rows", "cards", "tiles"],
      default: "rows",
    },
    showAvatars: { type: "boolean", default: false },
    linkLabel: { type: "string" },
  },
})
export default class BlockTopicPanel extends Component {
  @service site;
  @service store;

  @tracked empty = false;
  @tracked retryCount = 0;

  get category() {
    const id = this.args.categoryId;
    return id ? this.site.categories?.find((c) => c.id === id) : null;
  }

  get source() {
    const tags = this.args.tags ?? [];

    if (tags.length || this.args.categoryId) {
      // A configured category the visitor cannot see: show nothing rather
      // than an unfiltered list.
      if (this.args.categoryId && !this.category) {
        return null;
      }

      const query = homepageQuery({
        tags,
        categorySlug: filterSlug(this.category),
        order: this.args.order,
        status: this.args.status,
      });
      return query ? { query, tags } : null;
    }

    return this.args.list ? { list: this.args.list } : null;
  }

  get context() {
    return {
      source: this.source,
      count: this.args.count,
      retryCount: this.retryCount,
    };
  }

  get skeleton() {
    return { rows: SKELETON_ROWS[this.args.display], count: this.args.count };
  }

  // Where "see all" goes: the category, the tag, or the list.
  get moreUrl() {
    const tags = this.args.tags ?? [];

    if (this.category) {
      return this.category.url;
    }
    if (tags.length === 1) {
      return getURL(`/tag/${encodeURIComponent(tags[0])}`);
    }
    if (this.args.list) {
      return getURL(`/${this.args.list}`);
    }
    return null;
  }

  get dateField() {
    return this.args.order === "created" ? "created_at" : "bumped_at";
  }

  @bind
  retry() {
    this.retryCount++;
  }

  @bind
  async fetchTopics({ source, count }) {
    const result = source
      ? await fetchPanelTopics(this.store, source, count)
      : null;

    if (!this.isDestroying) {
      this.empty = !result;
    }
    return result;
  }

  <template>
    {{#if this.source}}
      {{#unless this.empty}}
        <HomepagePanel
          class="homepage-topic-panel --{{@display}}"
          @asyncData={{this.fetchTopics}}
          @context={{this.context}}
          @icon={{@icon}}
          @onRetry={{this.retry}}
          @skeleton={{this.skeleton}}
          @title={{i18n (themePrefix @title)}}
        >
          <:content as |result|>
            {{#if result}}
              {{#if (eq @display "cards")}}
                <div class="homepage-topic-panel__cards">
                  {{#each result.topics key="id" as |topic|}}
                    <ShowcaseCard @layout="grid" @topic={{topic}} />
                  {{/each}}
                </div>
              {{else if (eq @display "tiles")}}
                <ul class="homepage-topic-panel__tiles">
                  {{#each result.topics key="id" as |topic|}}
                    <li class="homepage-topic-panel__tile">
                      <a
                        class="homepage-topic-panel__tile-link"
                        href={{topic.url}}
                      >
                        <span class="homepage-topic-panel__tile-media">
                          {{#if (smallestThumbnailUrl topic)}}
                            <img
                              alt=""
                              loading="lazy"
                              src={{smallestThumbnailUrl topic}}
                            />
                          {{else}}
                            {{dIcon "image"}}
                          {{/if}}
                        </span>
                        <span class="homepage-topic-panel__tile-title">
                          {{trustHTML topic.fancyTitle}}
                        </span>
                      </a>
                    </li>
                  {{/each}}
                </ul>
              {{else}}
                <ul class="homepage-topic-panel__rows">
                  {{#each result.topics key="id" as |topic|}}
                    <li class="homepage-topic-panel__row">
                      {{#if @showAvatars}}
                        <span class="homepage-topic-panel__avatar">
                          {{dAvatar topic.creator imageSize="small"}}
                        </span>
                      {{/if}}
                      <div class="homepage-topic-panel__row-body">
                        <TopicLink
                          class="homepage-topic-panel__title raw-topic-link"
                          @topic={{topic}}
                        />
                        <div class="homepage-topic-panel__meta">
                          {{#if topic.category}}
                            {{dCategoryLink topic.category}}
                          {{/if}}
                          <span class="homepage-topic-panel__date">
                            {{dFormatDate
                              (if
                                (eq this.dateField "created_at")
                                topic.created_at
                                topic.bumped_at
                              )
                              format="tiny"
                              noTitle="true"
                            }}
                          </span>
                          {{#if topic.replyCount}}
                            <span
                              class="homepage-topic-panel__replies"
                              title={{i18n (themePrefix "showcase.replies")}}
                            >
                              {{dIcon "comment"}}
                              {{dNumber topic.replyCount}}
                            </span>
                          {{/if}}
                        </div>
                      </div>
                    </li>
                  {{/each}}
                </ul>
              {{/if}}
            {{/if}}
          </:content>
          <:footer>
            {{#if this.moreUrl}}
              <a class="homepage-panel__link" href={{this.moreUrl}}>
                {{i18n
                  (themePrefix (if @linkLabel @linkLabel "homepage.see_all"))
                }}
                {{dIcon "arrow-right"}}
              </a>
            {{/if}}
          </:footer>
        </HomepagePanel>
      {{/unless}}
    {{/if}}
  </template>
}
