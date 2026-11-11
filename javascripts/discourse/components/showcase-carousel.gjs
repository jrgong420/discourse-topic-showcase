import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import { settings, themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import TopicList from "discourse/models/topic-list";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
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
import { loadEmbla } from "../lib/embla.js";
import ShowcaseCard from "./showcase-card.gjs";

// Core's ordering keywords for the filter endpoint. "random" is applied on the
// client, so it fetches by activity like "latest".
const FILTER_ORDERS = { latest: "activity", created: "created" };

// Thumbnails in the collapsed chip.
const CHIP_THUMBNAILS = 3;

// Ids for the ARIA references between header and body.
let nextId = 0;

function filterTags() {
  return String(settings.carousel_filter_tags ?? "")
    .split("|")
    .map((tag) => tag.trim())
    .filter(Boolean);
}

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

  @tracked slides = [];
  @tracked collapsed = false;
  @tracked seenAt = null;
  @tracked canScrollPrev = false;
  @tracked canScrollNext = false;
  // One entry per Embla scroll snap, for the pagination pills.
  @tracked pills = [];
  @tracked selectedSnap = 0;

  embla = null;
  id = nextId++;

  // Sets Embla up on the viewport once it is in the DOM and destroys it when
  // the viewport goes away (collapse, leaving the homepage).
  setupEmbla = modifier((element) => {
    let embla;
    let cancelled = false;

    // Arrow keys from a focused card scroll the carousel. Added here rather
    // than with {{on}}: the viewport is not an interactive element itself.
    element.addEventListener("keydown", this.onKeydown);

    const sync = () => {
      this.canScrollPrev = embla.canScrollPrev();
      this.canScrollNext = embla.canScrollNext();
      this.selectedSnap = embla.selectedScrollSnap();

      const count = embla.scrollSnapList().length;
      if (count !== this.pills.length) {
        this.pills = Array.from({ length: count }, (_, index) => ({
          index,
          label: i18n(themePrefix("showcase.carousel.pagination_label"), {
            number: index + 1,
          }),
        }));
      }
    };

    loadEmbla()
      .then((EmblaCarousel) => {
        if (cancelled) {
          return;
        }

        embla = EmblaCarousel(element, {
          align: "start",
          direction: this.isRtl ? "rtl" : "ltr",
          loop: !!settings.carousel_loop,
          // One page of slides per step, so on narrow screens (one slide per
          // view) it is one slide.
          slidesToScroll: "auto",
          breakpoints: {
            // Jump instead of animating when the user asks for less motion.
            "(prefers-reduced-motion: reduce)": { duration: 0 },
          },
        });
        this.embla = embla;

        embla.on("select", sync).on("reInit", sync);
        sync();
      })
      .catch((error) => {
        // eslint-disable-next-line no-console
        console.warn("[Topic Showcase] Could not start the carousel", error);
      });

    return () => {
      cancelled = true;
      element.removeEventListener("keydown", this.onKeydown);
      embla?.destroy();
      if (this.embla === embla) {
        this.embla = null;
      }
    };
  });

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

  get hasSlides() {
    return this.slides.length > 0;
  }

  get isCollapsed() {
    return this.collapsible && this.collapsed;
  }

  // The badge counts what expanding the carousel would show.
  get newCount() {
    return countNewSince(
      this.slides.map((slide) => slide.topic),
      this.seenAt
    );
  }

  get showNav() {
    return !this.isCollapsed && (this.canScrollPrev || this.canScrollNext);
  }

  // One pill per scroll snap; a single snap has nothing to paginate.
  get showPills() {
    return !this.isCollapsed && this.pills.length > 1;
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

  // The edge of the next card shows only when there is a next card to peek at;
  // when every slide fits, the cards fill the row instead.
  get hasPeek() {
    return this.slides.length > this.slidesPerView;
  }

  // Up to three thumbnails for the collapsed chip, from the first topics that
  // have an image.
  get chipThumbnails() {
    const urls = [];

    for (const { topic } of this.slides) {
      const thumbnails = [...(topic.thumbnails ?? [])].sort(
        (a, b) => a.width - b.width
      );
      const url = thumbnails[0]?.url ?? topic.image_url;

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

  get isRtl() {
    return document.documentElement.classList.contains("rtl");
  }

  async load() {
    const tags = filterTags();

    try {
      const order = FILTER_ORDERS[settings.carousel_order] ?? "activity";
      // `tag:a+b` matches topics carrying all the tags.
      const json = await ajax("/filter.json", {
        data: { q: `tag:${tags.join("+")} order:${order}` },
      });

      if (this.isDestroying) {
        return;
      }

      // Same conversion core's topic lists use, so cards get real Topic
      // models (category, creator, thumbnails, lastUnreadUrl).
      const topics = TopicList.topicsFrom(this.store, json) ?? [];

      const items = filterAndOrderTopics(topics, {
        order: settings.carousel_order,
        maxItems: settings.carousel_max_items,
        displayExpired: settings.carousel_display_expired_events,
        displayUpcoming: settings.carousel_display_upcoming_events,
        now: Date.now(),
        random: Math.random,
      });

      this.slides = items.map((topic, index) => ({
        topic,
        label: i18n(themePrefix("showcase.carousel.slide_label"), {
          current: index + 1,
          total: items.length,
        }),
      }));

      if (this.hasSlides && !this.isCollapsed) {
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

    // The slides go away with the collapse, and take Embla with them.
    this.canScrollPrev = false;
    this.canScrollNext = false;
    this.pills = [];
    this.selectedSnap = 0;
  }

  @action
  scrollPrev() {
    this.embla?.scrollPrev();
  }

  @action
  scrollNext() {
    this.embla?.scrollNext();
  }

  @action
  scrollToSnap(index) {
    this.embla?.scrollTo(index);
  }

  @action
  onKeydown(event) {
    if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") {
      return;
    }

    if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) {
      return;
    }

    event.preventDefault();

    // Arrow keys follow the reading direction.
    const forward = (event.key === "ArrowRight") !== this.isRtl;
    if (forward) {
      this.scrollNext();
    } else {
      this.scrollPrev();
    }
  }

  <template>
    {{#if this.hasSlides}}
      <section
        aria-labelledby={{this.titleId}}
        aria-roledescription={{unless this.isCollapsed "carousel"}}
        class={{dConcatClass
          "showcase-carousel"
          (if this.isCollapsed "is-collapsed" "is-expanded")
          (if this.hasPeek "--peek")
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
                >{{this.slides.length}}</span>

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
            <div class="showcase-carousel__stage">
              {{#if this.showNav}}
                <DButton
                  class="showcase-carousel__arrow --prev"
                  @action={{this.scrollPrev}}
                  @icon="chevron-left"
                  @translatedAriaLabel={{i18n
                    (themePrefix "showcase.carousel.previous")
                  }}
                  @translatedTitle={{i18n
                    (themePrefix "showcase.carousel.previous")
                  }}
                />
              {{/if}}

              <div class="showcase-carousel__viewport" {{this.setupEmbla}}>
                <div class="showcase-carousel__track">
                  {{#each this.slides key="topic.id" as |slide|}}
                    <div
                      aria-label={{slide.label}}
                      aria-roledescription="slide"
                      class="showcase-carousel__slide"
                      role="group"
                    >
                      <ShowcaseCard
                        @context="carousel"
                        @eventDate={{true}}
                        @layout="grid"
                        @topic={{slide.topic}}
                      />
                    </div>
                  {{/each}}
                </div>
              </div>

              {{#if this.showNav}}
                <DButton
                  class="showcase-carousel__arrow --next"
                  @action={{this.scrollNext}}
                  @icon="chevron-right"
                  @translatedAriaLabel={{i18n
                    (themePrefix "showcase.carousel.next")
                  }}
                  @translatedTitle={{i18n
                    (themePrefix "showcase.carousel.next")
                  }}
                />
              {{/if}}
            </div>

            {{#if this.showPills}}
              <div class="showcase-carousel__pills">
                {{#each this.pills key="index" as |pill|}}
                  <button
                    aria-current={{if (eq pill.index this.selectedSnap) "true"}}
                    aria-label={{pill.label}}
                    class={{dConcatClass
                      "showcase-carousel__pill"
                      (if (eq pill.index this.selectedSnap) "is-active")
                    }}
                    type="button"
                    {{on "click" (fn this.scrollToSnap pill.index)}}
                  ></button>
                {{/each}}
              </div>
            {{/if}}
          {{/unless}}
        </div>
      </section>
    {{/if}}
  </template>
}
