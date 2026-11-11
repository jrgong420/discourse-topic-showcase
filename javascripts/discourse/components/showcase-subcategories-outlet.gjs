import Component from "@glimmer/component";
import { service } from "@ember/service";
import { settings } from "virtual:theme";
import { parseIdList } from "../lib/card-layout.js";
import { carouselSubcategories } from "../lib/subcategory-carousel.js";
import ShowcaseSubcategories from "./showcase-subcategories.gjs";

/**
 * Connector for `header-list-container-bottom`: renders the subcategory
 * carousel on the topic list pages of the listed categories.
 *
 * Core renders that outlet on every discovery list, right after its own
 * subcategory list. The carousel replaces that list (see
 * showcase-subcategories.scss). It shows the subcategories core lists for the
 * page when it has them, else the ones of the category.
 */
export default class ShowcaseSubcategoriesOutlet extends Component {
  @service router;

  // Empty when the carousel should not show.
  get subcategories() {
    const { category, tag } = this.args.outletArgs ?? {};

    if (!category || tag) {
      return [];
    }

    const list = this.router.currentRoute?.attributes?.subcategoryList;

    return carouselSubcategories({
      categoryId: category.id,
      enabledIds: parseIdList(settings.subcategory_carousel_categories),
      minChildren: settings.subcategory_carousel_min_children,
      listed: list?.parentCategory?.id === category.id ? list.content : null,
      fallback: category.subcategories,
    });
  }

  <template>
    {{#if this.subcategories.length}}
      <ShowcaseSubcategories
        @category={{@outletArgs.category}}
        @subcategories={{this.subcategories}}
      />
    {{/if}}
  </template>
}
