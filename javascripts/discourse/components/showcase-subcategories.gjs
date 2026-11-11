import Component from "@glimmer/component";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import ShowcaseCarouselFrame from "./showcase-carousel-frame.gjs";
import ShowcaseSubcategoryTile from "./showcase-subcategory-tile.gjs";

/**
 * A carousel of subcategory tiles above the topic list of a category.
 *
 * `ShowcaseSubcategoriesOutlet` decides where it appears and which
 * subcategories it gets; this component shows what it is given.
 *
 * @param {Category} @category The parent category.
 * @param {Category[]} @subcategories The subcategories, in display order.
 */
export default class ShowcaseSubcategories extends Component {
  @service capabilities;

  // Tiles visible at once, matching the breakpoints in
  // showcase-subcategories.scss.
  get slidesPerView() {
    const { viewport } = this.capabilities;

    if (viewport.lg) {
      return 3;
    }

    return viewport.sm ? 2 : 1;
  }

  <template>
    <section
      aria-label={{i18n
        (themePrefix "showcase.subcategories.label")
        category=@category.displayName
      }}
      aria-roledescription="carousel"
      class="showcase-subcategories"
    >
      <ShowcaseCarouselFrame
        @items={{@subcategories}}
        @slidesPerView={{this.slidesPerView}}
        as |subcategory|
      >
        <ShowcaseSubcategoryTile @category={{subcategory}} />
      </ShowcaseCarouselFrame>
    </section>
  </template>
}
