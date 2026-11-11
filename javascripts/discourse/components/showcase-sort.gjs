import Component from "@glimmer/component";
import { hash } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import ComboBox from "discourse/select-kit/components/combo-box";
import { selectKitOptions } from "discourse/select-kit/components/select-kit";
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

// ComboBox only forwards options it declares; declaring headerAriaLabel lets
// the dropdown be named "Sort by" instead of select-kit's "Filter by".
@selectKitOptions({ headerAriaLabel: null })
class SortComboBox extends ComboBox {}

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

  get queryParams() {
    return this.router.currentRoute?.queryParams ?? {};
  }

  // What the list is actually sorted by: a category can have its own default
  // order, which shows up in the loaded list's params, not in the URL.
  get listParams() {
    return this.router.currentRoute?.attributes?.list?.params ?? {};
  }

  // The order chosen through the URL, or "default" when the list uses its
  // own (site or category) default.
  get value() {
    return this.queryParams.order ?? "default";
  }

  get effectiveOrder() {
    return this.queryParams.order ?? this.listParams.order;
  }

  get ascending() {
    return (
      String(this.queryParams.ascending ?? this.listParams.ascending) === "true"
    );
  }

  get content() {
    const content = ORDERS.map(([id, key]) => ({
      id,
      name: key ? i18n(key) : i18n(themePrefix("showcase.sort.default")),
    }));

    // An order reached through a link (e.g. "created") still gets an entry,
    // so the dropdown never claims a different order than the list has.
    if (!content.some((item) => item.id === this.value)) {
      content.push({ id: this.value, name: this.value });
    }

    return content;
  }

  @action
  changeOrder(order) {
    if (order === this.value) {
      return;
    }

    // "Default" clears the params, so a category's own default order applies.
    this.router.transitionTo({
      queryParams: {
        order: order === "default" ? null : order,
        ascending: null,
      },
    });
  }

  // Reverses the direction of whatever the list is currently sorted by.
  @action
  reverse() {
    this.router.transitionTo({
      queryParams: {
        order: this.effectiveOrder ?? "default",
        ascending: !this.ascending,
      },
    });
  }

  <template>
    {{#if this.shouldShow}}
      <div class="showcase-sort">
        <SortComboBox
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
