import Component from "@glimmer/component";
import { eq } from "discourse/truth-helpers";

// Loading placeholder shaped like what it stands in for, so the panel keeps
// its height when the data arrives (core 2026.7 has no DSkeleton yet):
//   { rows: "topic", count }  title line + meta line
//   { rows: "card", count }   thumbnail + two lines, in the card grid
//   { rows: "tile", count }   logo + one line, in the tile grid
export default class HomepagePanelSkeleton extends Component {
  get rows() {
    const count = this.args.shape?.count ?? 5;
    return Array.from({ length: count }, (_, index) => index);
  }

  get layoutClass() {
    const rows = this.args.shape?.rows;
    return rows === "card" || rows === "tile" ? `--${rows}s` : "--topics";
  }

  <template>
    <div
      aria-hidden="true"
      class="homepage-panel-skeleton {{this.layoutClass}}"
    >
      {{#each this.rows as |row|}}
        {{#if (eq @shape.rows "card")}}
          <div class="homepage-panel-skeleton__item --card" data-row={{row}}>
            <span class="homepage-panel-skeleton__media"></span>
            <span class="homepage-panel-skeleton__line --long"></span>
            <span class="homepage-panel-skeleton__line --short"></span>
          </div>
        {{else if (eq @shape.rows "tile")}}
          <div class="homepage-panel-skeleton__item --tile" data-row={{row}}>
            <span class="homepage-panel-skeleton__media"></span>
            <span class="homepage-panel-skeleton__line --long"></span>
          </div>
        {{else}}
          <div class="homepage-panel-skeleton__item --topic" data-row={{row}}>
            <span class="homepage-panel-skeleton__line --long"></span>
            <span class="homepage-panel-skeleton__line --short"></span>
          </div>
        {{/if}}
      {{/each}}
    </div>
  </template>
}
