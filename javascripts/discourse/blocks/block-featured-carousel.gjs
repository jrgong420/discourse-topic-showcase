import Component from "@glimmer/component";
import { settings } from "virtual:theme";
import { block } from "discourse/blocks";
import ShowcaseCarousel from "../components/showcase-carousel.gjs";

/**
 * The featured topics carousel as a block, so a theme with a block-based
 * homepage can place it in its layout:
 *
 *   { block: "theme:topic-showcase:featured-carousel?", id: "featured" }
 *
 * The `discovery-list-container-top` connector only covers homepages that are
 * a topic list; a custom homepage has no such outlet. The block takes no
 * arguments: tags, order and size come from this component's own carousel
 * settings, exactly as for the connector.
 */
@block("theme:topic-showcase:featured-carousel", {
  description: "Featured topics carousel (configured in Topic Showcase)",
})
export default class BlockFeaturedCarousel extends Component {
  get enabled() {
    return settings.carousel_enabled && !!settings.carousel_filter_tags;
  }

  <template>
    {{#if this.enabled}}
      <ShowcaseCarousel />
    {{/if}}
  </template>
}
