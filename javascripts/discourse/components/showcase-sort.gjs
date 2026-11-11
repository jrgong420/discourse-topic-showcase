import Component from "@glimmer/component";
import { hash } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import ComboBox from "discourse/select-kit/components/combo-box";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import { layoutForCurrentRoute } from "../lib/route-layout.js";

// Sort orders offered for card lists: [order param, core translation key].
// "default" has no core label, so it uses a theme string.
const ORDERS = [
  ["default", null],
  ["activity", "activity"],
  ["posts", "replies"],
  ["views", "views"],
  ["likes", "likes"],
];

/**
 * Sort dropdown and direction toggle for card lists, shown next to the
 * category and tag dropdowns. Card lists have no column headers to sort by,
 * so this drives the same `order` / `ascending` query params those use.
 */
export default class ShowcaseSort extends Component {
  @service router;
  @service site;

  get shouldShow() {
    return !!layoutForCurrentRoute(this.router, this.site);
  }

  get content() {
    return ORDERS.map(([id, key]) => ({
      id,
      name: key ? i18n(key) : i18n(themePrefix("showcase.sort.default")),
    }));
  }

  get queryParams() {
    return this.router.currentRoute?.queryParams ?? {};
  }

  get value() {
    const active = this.queryParams.order;
    return ORDERS.some(([id]) => id === active) ? active : "default";
  }

  get ascending() {
    return String(this.queryParams.ascending) === "true";
  }

  @action
  changeOrder(order) {
    if (order !== this.value) {
      this.router.transitionTo({ queryParams: { order, ascending: false } });
    }
  }

  @action
  reverse() {
    this.router.transitionTo({
      queryParams: { order: this.value, ascending: !this.ascending },
    });
  }

  <template>
    {{#if this.shouldShow}}
      <div class="showcase-sort">
        <ComboBox
          class="showcase-sort__select"
          @content={{this.content}}
          @onChange={{this.changeOrder}}
          @options={{hash
            headerAriaLabel=(i18n (themePrefix "showcase.sort.label"))
          }}
          @value={{this.value}}
        />
        <DButton
          class="btn-default showcase-sort__reverse"
          @action={{this.reverse}}
          @icon={{if this.ascending "arrow-up" "arrow-down"}}
          @title={{themePrefix "showcase.sort.reverse"}}
        />
      </div>
    {{/if}}
  </template>
}
