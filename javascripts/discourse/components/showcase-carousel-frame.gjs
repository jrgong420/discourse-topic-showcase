import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { modifier } from "ember-modifier";
import { settings, themePrefix } from "virtual:theme";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";
import { loadEmbla } from "../lib/embla.js";

// Accessible name of a slide: its position among all slides.
function slideLabel(index, total) {
  return i18n(themePrefix("showcase.carousel.slide_label"), {
    current: index + 1,
    total,
  });
}

/**
 * The shared mechanics of the carousels: an Embla viewport with arrows,
 * pagination pills and keyboard support. What a slide contains is up to the
 * caller, who gets each item yielded.
 *
 * The sizes of the slides come from `--tc-TopicShowcase-carousel-size-per-view`
 * and `--tc-TopicShowcase-carousel-size-peek`, which the caller sets on an
 * ancestor.
 *
 * @param {Array} @items The items to show, one slide each.
 * @param {number} @slidesPerView Slides visible at once at the current
 *   viewport size. Only used to decide whether the next slide peeks in.
 */
export default class ShowcaseCarouselFrame extends Component {
  @tracked canScrollPrev = false;
  @tracked canScrollNext = false;
  // One entry per Embla scroll snap, for the pagination pills.
  @tracked pills = [];
  @tracked selectedSnap = 0;

  embla = null;

  // Sets Embla up on the viewport once it is in the DOM and destroys it when
  // the viewport goes away (collapse, leaving the page).
  setupEmbla = modifier((element) => {
    let embla;
    let cancelled = false;

    // Arrow keys from a focused slide scroll the carousel. Added here rather
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
          // Step size of the arrows and pills: one slide, or a full page of
          // visible slides (which is one slide on narrow screens anyway).
          slidesToScroll: settings.carousel_scroll_by === "page" ? "auto" : 1,
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

  get showNav() {
    return this.canScrollPrev || this.canScrollNext;
  }

  // One pill per scroll snap; a single snap has nothing to paginate.
  get showPills() {
    return this.pills.length > 1;
  }

  // The edge of the next slide shows only when there is a next slide to peek
  // at; when every slide fits, the slides fill the row instead.
  get hasPeek() {
    return this.args.items.length > this.args.slidesPerView;
  }

  get isRtl() {
    return document.documentElement.classList.contains("rtl");
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
    <div
      class={{dConcatClass
        "showcase-carousel-frame"
        (if this.hasPeek "--peek")
      }}
      ...attributes
    >
      <div class="showcase-carousel-frame__stage">
        {{#if this.showNav}}
          <DButton
            class="showcase-carousel-frame__arrow --prev"
            @action={{this.scrollPrev}}
            @icon="chevron-left"
            @translatedAriaLabel={{i18n
              (themePrefix "showcase.carousel.previous")
            }}
            @translatedTitle={{i18n (themePrefix "showcase.carousel.previous")}}
          />
        {{/if}}

        <div class="showcase-carousel-frame__viewport" {{this.setupEmbla}}>
          <div class="showcase-carousel-frame__track">
            {{#each @items as |item index|}}
              <div
                aria-label={{slideLabel index @items.length}}
                aria-roledescription="slide"
                class="showcase-carousel-frame__slide"
                role="group"
              >
                {{yield item}}
              </div>
            {{/each}}
          </div>
        </div>

        {{#if this.showNav}}
          <DButton
            class="showcase-carousel-frame__arrow --next"
            @action={{this.scrollNext}}
            @icon="chevron-right"
            @translatedAriaLabel={{i18n (themePrefix "showcase.carousel.next")}}
            @translatedTitle={{i18n (themePrefix "showcase.carousel.next")}}
          />
        {{/if}}
      </div>

      {{#if this.showPills}}
        <div class="showcase-carousel-frame__pills">
          {{#each this.pills key="index" as |pill|}}
            <button
              aria-current={{if (eq pill.index this.selectedSnap) "true"}}
              aria-label={{pill.label}}
              class={{dConcatClass
                "showcase-carousel-frame__pill"
                (if (eq pill.index this.selectedSnap) "is-active")
              }}
              type="button"
              {{on "click" (fn this.scrollToSnap pill.index)}}
            ></button>
          {{/each}}
        </div>
      {{/if}}
    </div>
  </template>
}
