import Component from "@glimmer/component";
import { settings } from "virtual:theme";
import { block } from "discourse/blocks";
import ShowcaseCarousel from "../components/showcase-carousel.gjs";

/**
 * The featured topics carousel as a block. It is the same carousel the
 * component shows above the topic list on the standard homepage, with the
 * same carousel_* settings; it renders nothing without carousel_filter_tags.
 *
 * Used by this component's own custom homepage (homepage_enabled) and
 * registered by name, so a theme that owns the homepage layout itself can
 * place it too:
 *
 *   { block: "theme:topic-showcase:featured-carousel?", id: "featured" }
 */
@block("theme:topic-showcase:featured-carousel", {
  description: "The featured topics carousel (carousel_* settings)",
})
export default class BlockFeaturedCarousel extends Component {
  // Placing the block is the opt-in. `carousel_enabled` only decides whether
  // the carousel also shows above the topic list of a standard homepage, so
  // it is not asked here: a forum can have that off and still use the block.
  get enabled() {
    return !!settings.carousel_filter_tags;
  }

  <template>
    {{#if this.enabled}}
      <div class="homepage-featured-carousel"><ShowcaseCarousel /></div>
    {{/if}}
  </template>
}
