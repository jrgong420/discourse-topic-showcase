import Component from "@glimmer/component";
import { trustHTML } from "@ember/template";
import { themePrefix } from "virtual:theme";
import CategoryLogo from "discourse/components/category-logo";
import { number } from "discourse/lib/formatter";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import dReplaceEmoji from "discourse/ui-kit/helpers/d-replace-emoji";
import { i18n } from "discourse-i18n";
import { categoryColor } from "../lib/subcategory-carousel.js";

/**
 * A subcategory as one link: logo or glyph on the left, name, description and
 * topic count on the right. The category colour accents the left edge.
 *
 * @param {Category} @category
 */
export default class ShowcaseSubcategoryTile extends Component {
  // Only a validated hex colour is written into the inline style.
  get style() {
    const color = categoryColor(this.args.category.color);

    return color
      ? trustHTML(`--tc-TopicShowcase-subcategory-color: ${color}`)
      : null;
  }

  get hasLogo() {
    return !!this.args.category.uploaded_logo?.url;
  }

  get hasIcon() {
    const { style_type: styleType, icon } = this.args.category;
    return styleType === "icon" && !!icon;
  }

  get emojiCode() {
    const { style_type: styleType, emoji } = this.args.category;
    return styleType === "emoji" && emoji ? `:${emoji}:` : null;
  }

  // The first character of the name, for categories without logo or glyph.
  get initial() {
    return Array.from(this.args.category.displayName ?? "")[0] ?? "";
  }

  get topicCount() {
    return this.args.category.topic_count ?? 0;
  }

  get formattedTopicCount() {
    return number(this.topicCount);
  }

  <template>
    <a class="showcase-subcategory" href={{@category.url}} style={{this.style}}>
      <span
        aria-hidden="true"
        class="showcase-subcategory__media
          {{if this.hasLogo '--logo' '--swatch'}}"
      >
        {{#if this.hasLogo}}
          <CategoryLogo @category={{@category}} />
        {{else if this.hasIcon}}
          <span class="showcase-subcategory__icon">
            {{dIcon @category.icon}}
          </span>
        {{else if this.emojiCode}}
          <span class="showcase-subcategory__emoji">
            {{dReplaceEmoji this.emojiCode}}
          </span>
        {{else}}
          <span class="showcase-subcategory__initial">{{this.initial}}</span>
        {{/if}}
      </span>

      <span class="showcase-subcategory__text">
        <span class="showcase-subcategory__name">
          {{~#if @category.read_restricted~}}
            {{dIcon "lock" class="showcase-subcategory__lock"}}
          {{~/if~}}
          {{@category.displayName}}
        </span>

        {{#if @category.descriptionText}}
          <span class="showcase-subcategory__description">
            {{@category.descriptionText}}
          </span>
        {{/if}}

        <span class="showcase-subcategory__count">
          {{i18n
            (themePrefix "showcase.subcategories.topic_count")
            count=this.topicCount
            number=this.formattedTopicCount
          }}
        </span>
      </span>
    </a>
  </template>
}
