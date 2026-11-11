import Component from "@glimmer/component";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { block } from "discourse/blocks";
import dCategoryLink from "discourse/ui-kit/helpers/d-category-link";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import dNumber from "discourse/ui-kit/helpers/d-number";
import { i18n } from "discourse-i18n";
import HomepagePanel from "../components/homepage-panel.gjs";

/**
 * A homepage panel that opens a category with many subcategories, such as a
 * documentation tree: one row per subcategory (badge, description, topic
 * count) and a link to the category. Uses the categories the site already
 * has loaded, so it needs no request. Renders nothing when the category is not
 * set, not visible to the visitor, or has no subcategories.
 */
@block("theme:topic-showcase:category-panel", {
  description: "A category and its subcategories as a table of contents",
  args: {
    title: { type: "string", required: true },
    icon: { type: "string" },
    categoryId: { type: "number" },
    count: { type: "number", default: 8, min: 1, max: 30, integer: true },
    showDescriptions: { type: "boolean", default: true },
    linkLabel: { type: "string" },
  },
})
export default class BlockCategoryPanel extends Component {
  @service site;

  get category() {
    const id = this.args.categoryId;
    return id ? this.site.categories?.find((c) => c.id === id) : null;
  }

  // Subcategories in the site's category order, most used first when the
  // site sorts categories by position anyway.
  get subcategories() {
    const id = this.args.categoryId;
    return (this.site.categories ?? [])
      .filter((c) => c.parent_category_id === id)
      .slice(0, this.args.count);
  }

  get hiddenCount() {
    const id = this.args.categoryId;
    const all = (this.site.categories ?? []).filter(
      (c) => c.parent_category_id === id
    ).length;
    return Math.max(0, all - this.subcategories.length);
  }

  <template>
    {{#if this.subcategories.length}}
      <HomepagePanel
        class="homepage-category-panel"
        @icon={{@icon}}
        @title={{i18n (themePrefix @title)}}
      >
        <:content>
          <ul class="homepage-category-panel__rows">
            {{#each this.subcategories key="id" as |category|}}
              <li class="homepage-category-panel__row">
                <div class="homepage-category-panel__name">
                  {{dCategoryLink category hideParent=true}}
                  <span class="homepage-category-panel__count">
                    {{dNumber category.topic_count}}
                  </span>
                </div>
                {{#if @showDescriptions}}
                  {{#if category.descriptionText}}
                    <p class="homepage-category-panel__description">
                      {{category.descriptionText}}
                    </p>
                  {{/if}}
                {{/if}}
              </li>
            {{/each}}
          </ul>
        </:content>
        <:footer>
          <a class="homepage-panel__link" href={{this.category.url}}>
            {{#if this.hiddenCount}}
              {{i18n
                (themePrefix "homepage.category_more")
                name=this.category.displayName
                count=this.hiddenCount
              }}
            {{else}}
              {{i18n
                (themePrefix
                  (if @linkLabel @linkLabel "homepage.category_open")
                )
                name=this.category.displayName
              }}
            {{/if}}
            {{dIcon "arrow-right"}}
          </a>
        </:footer>
      </HomepagePanel>
    {{/if}}
  </template>
}
