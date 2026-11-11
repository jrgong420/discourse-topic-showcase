import Component from "@glimmer/component";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import ComboBox from "discourse/select-kit/components/combo-box";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

// Sort orders offered above card lists: [order param, core translation key].
// "default" has no core label, so it uses a theme string.
const ORDERS = [
  ["default", null],
  ["activity", "activity"],
  ["posts", "replies"],
  ["views", "views"],
  ["likes", "likes"],
];

/**
 * Header cell of the card list: a sort dropdown and a direction toggle.
 * Receives the same args as core's topic-list header cells.
 */
export default class ShowcaseSortHeader extends Component {
  get content() {
    return ORDERS.map(([id, key]) => ({
      id,
      name: key ? i18n(key) : i18n(themePrefix("showcase.sort.default")),
    }));
  }

  get value() {
    const active = this.args.activeOrder;
    return ORDERS.some(([id]) => id === active) ? active : "default";
  }

  @action
  changeOrder(order) {
    if (order !== this.value) {
      this.args.changeSort(order);
    }
  }

  // Core flips the direction when the active order is chosen again.
  @action
  reverse() {
    this.args.changeSort(this.value);
  }

  <template>
    <th class="topic-list-data topic-showcase__sort" scope="col">
      {{#if @sortable}}
        {{#unless @bulkSelectEnabled}}
          <span class="topic-showcase__sort-label">
            {{i18n (themePrefix "showcase.sort.label")}}
          </span>
          <ComboBox
            class="topic-showcase__sort-select"
            @content={{this.content}}
            @onChange={{this.changeOrder}}
            @value={{this.value}}
          />
          <DButton
            class="btn-flat topic-showcase__sort-reverse"
            @action={{this.reverse}}
            @icon={{if @ascending "arrow-up" "arrow-down"}}
            @title={{themePrefix "showcase.sort.reverse"}}
          />
        {{/unless}}
      {{/if}}
    </th>
  </template>
}
