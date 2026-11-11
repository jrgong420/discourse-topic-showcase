import Component from "@glimmer/component";
import { service } from "@ember/service";
import { settings } from "virtual:theme";
import { MAX_UNOPTIMIZED_CATEGORIES } from "discourse/lib/constants";
import { parseIdList } from "../lib/card-layout.js";
import {
  carouselSubcategories,
  subcategoryListIncomplete,
} from "../lib/subcategory-carousel.js";
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
  @service site;

  // Empty when the carousel should not show.
  get subcategories() {
    const { category, tag } = this.args.outletArgs ?? {};

    if (!category || tag) {
      return [];
    }

    const routeList = this.router.currentRoute?.attributes?.subcategoryList;
    const list =
      routeList?.parentCategory?.id === category.id ? routeList : null;

    return carouselSubcategories({
      categoryId: category.id,
      enabledIds: parseIdList(settings.subcategory_carousel_categories),
      minChildren: settings.subcategory_carousel_min_children,
      listed: list ? list.content : null,
      fallback: category.subcategories,
      // Same condition as core's own "load more" for the list.
      listIncomplete:
        !!list &&
        subcategoryListIncomplete({
          paginated:
            !!this.site.lazy_load_categories ||
            this.site.categories.length > MAX_UNOPTIMIZED_CATEGORIES,
          loaded: list.content?.length ?? 0,
          fetchedLastPage: !!list.fetchedLastPage,
        }),
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
