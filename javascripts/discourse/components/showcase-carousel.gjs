import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { settings, themePrefix } from "virtual:theme";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import {
  readCollapsed,
  readSeenAt,
  writeCollapsed,
  writeSeenAt,
} from "../lib/carousel-storage.js";
import { countNewSince, filterAndOrderTopics } from "../lib/carousel-topics.js";
import { canFilterTags, parseTagList } from "../lib/tag-filter.js";
import { fetchTopicsByTags } from "../lib/tag-topics.js";
import { smallestThumbnailUrl } from "../lib/thumbnail.js";
import ShowcaseCard from "./showcase-card.gjs";
import ShowcaseCarouselFrame from "./showcase-carousel-frame.gjs";

// Thumbnails in the collapsed chip.
const CHIP_THUMBNAILS = 3;

// Ids for the ARIA references between header and body.
let nextId = 0;

/**
 * The featured topics carousel. Fetches the topics once when it is created,
 * renders nothing while loading, on errors and without topics.
 *
 * `ShowcaseCarouselOutlet` decides where it appears; this component assumes
 * it is rendered when it should show.
 */
export default class ShowcaseCarousel extends Component {
  @service capabilities;
  @service currentUser;
  @service store;

  @tracked topics = [];
  @tracked collapsed = false;
  @tracked seenAt = null;

  id = nextId++;

  constructor() {
    super(...arguments);

    if (this.collapsible) {
      this.collapsed = readCollapsed(this.userId);
      this.seenAt = readSeenAt(this.userId);
    }

    this.load();
  }

  get userId() {
    return this.currentUser?.id ?? "anon";
  }

  get collapsible() {
    return !!settings.carousel_collapsible;
  }

  get title() {
    return (
      settings.carousel_title?.trim() ||
      i18n(themePrefix("showcase.carousel.default_title"))
    );
  }

  get titleId() {
    return `showcase-carousel-title-${this.id}`;
  }

  get bodyId() {
    return `showcase-carousel-body-${this.id}`;
  }

  get hasTopics() {
    return this.topics.length > 0;
  }

  get isCollapsed() {
    return this.collapsible && this.collapsed;
  }

  // The badge counts what expanding the carousel would show.
  get newCount() {
    return countNewSince(this.topics, this.seenAt);
  }

  // Cards visible at once, matching the breakpoints in showcase-carousel.scss.
  get slidesPerView() {
    const { viewport } = this.capabilities;
    const configured = settings.carousel_slides_per_view;

    if (viewport.lg) {
      return configured;
    }

    return viewport.sm ? Math.min(configured, 2) : 1;
  }

  // Up to three thumbnails for the collapsed chip, from the first topics that
  // have an image.
  get chipThumbnails() {
    const urls = [];

    for (const topic of this.topics) {
      const url = smallestThumbnailUrl(topic);

      if (url) {
        urls.push({ id: topic.id, url });
      }
      if (urls.length === CHIP_THUMBNAILS) {
        break;
      }
    }

    return urls;
  }

  get toggleLabel() {
    return i18n(
      themePrefix(
        this.isCollapsed
          ? "showcase.carousel.expand"
          : "showcase.carousel.collapse"
      ),
      { title: this.title }
    );
  }

  async load() {
    const tags = parseTagList(settings.carousel_filter_tags);

    // Core's topic filter ignores a tag clause it cannot parse and then
    // returns unfiltered topics. Such tag names are not supported here: show
    // nothing rather than unrelated topics.
    if (!canFilterTags(tags)) {
      // eslint-disable-next-line no-console
      console.warn(
        "[topic-showcase] carousel_filter_tags contains a tag the topic filter cannot match; carousel not shown."
      );
      return;
    }

    try {
      // "random" is applied on the client, so it fetches by activity like
      // "latest". Only topics that really carry every tag come back.
      const { topics } = await fetchTopicsByTags(
        this.store,
        tags,
        settings.carousel_order
      );

      if (this.isDestroying) {
        return;
      }

      const items = filterAndOrderTopics(topics, {
        order: settings.carousel_order,
        maxItems: settings.carousel_max_items,
        displayExpired: settings.carousel_display_expired_events,
        displayUpcoming: settings.carousel_display_upcoming_events,
        now: Date.now(),
        random: Math.random,
      });

      this.topics = items;

      if (this.hasTopics && !this.isCollapsed) {
        this.markSeen();
      }
    } catch (error) {
      // eslint-disable-next-line no-console
      console.warn(
        "[Topic Showcase] Could not load the carousel topics",
        error
      );
    }
  }

  // Remembers the last moment the carousel was in front of the user.
  markSeen() {
    if (!this.collapsible) {
      return;
    }

    this.seenAt = new Date().toISOString();
    writeSeenAt(this.userId, this.seenAt);
  }

  @action
  toggle() {
    this.collapsed = !this.collapsed;
    writeCollapsed(this.userId, this.collapsed);
    // Collapsing records when the user last looked; expanding clears the badge.
    this.markSeen();
  }

  <template>
    {{#if this.hasTopics}}
      <section
        aria-labelledby={{this.titleId}}
        aria-roledescription={{unless this.isCollapsed "carousel"}}
        class={{dConcatClass
          "showcase-carousel"
          (if this.isCollapsed "is-collapsed" "is-expanded")
        }}
      >
        <h2 class="showcase-carousel__header">
          {{#if this.collapsible}}
            <button
              aria-controls={{this.bodyId}}
              aria-expanded={{if this.isCollapsed "false" "true"}}
              class="showcase-carousel__toggle"
              title={{this.toggleLabel}}
              type="button"
              {{on "click" this.toggle}}
            >
              {{dIcon "star" class="showcase-carousel__icon"}}
              <span class="showcase-carousel__title" id={{this.titleId}}>
                {{this.title}}
              </span>

              {{#if this.isCollapsed}}
                <span
                  class="showcase-carousel__count"
                >{{this.topics.length}}</span>

                {{#if this.chipThumbnails.length}}
                  <span
                    aria-hidden="true"
                    class="showcase-carousel__thumbnails"
                  >
                    {{#each this.chipThumbnails key="id" as |thumbnail|}}
                      <img
                        alt=""
                        class="showcase-carousel__thumbnail"
                        src={{thumbnail.url}}
                      />
                    {{/each}}
                  </span>
                {{/if}}

                {{#if this.newCount}}
                  <span class="showcase-carousel__badge">
                    {{i18n
                      (themePrefix "showcase.carousel.new_count")
                      count=this.newCount
                    }}
                  </span>
                {{/if}}
              {{/if}}

              {{dIcon
                (if this.isCollapsed "chevron-down" "chevron-up")
                class="showcase-carousel__chevron"
              }}
            </button>
          {{else}}
            {{dIcon "star" class="showcase-carousel__icon"}}
            <span class="showcase-carousel__title" id={{this.titleId}}>
              {{this.title}}
            </span>
          {{/if}}
        </h2>

        <div class="showcase-carousel__body" id={{this.bodyId}}>
          {{#unless this.isCollapsed}}
            <ShowcaseCarouselFrame
              @items={{this.topics}}
              @slidesPerView={{this.slidesPerView}}
              as |topic|
            >
              <ShowcaseCard
                @context="carousel"
                @eventDate={{true}}
                @layout="grid"
                @topic={{topic}}
              />
            </ShowcaseCarouselFrame>
          {{/unless}}
        </div>
      </section>
    {{/if}}
  </template>
}
