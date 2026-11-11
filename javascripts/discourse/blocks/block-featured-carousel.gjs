import Component from "@glimmer/component";
import { block } from "discourse/blocks";
import ShowcaseCarousel from "../components/showcase-carousel.gjs";

/**
 * The featured topics carousel as a homepage block. It is the same carousel
 * the component shows above the topic list on the standard homepage, with the
 * same carousel_* settings; the layout only adds it when those are set.
 */
@block("theme:topic-showcase:featured-carousel", {
  description: "The featured topics carousel (carousel_* settings)",
})
export default class BlockFeaturedCarousel extends Component {
  <template>
    <div class="homepage-featured-carousel"><ShowcaseCarousel /></div>
  </template>
}
