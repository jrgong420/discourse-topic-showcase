import { withPluginApi } from "discourse/lib/plugin-api";
import BlockFeaturedCarousel from "../blocks/block-featured-carousel.gjs";

// Blocks have to be registered before core freezes the block registry.
export default {
  name: "topic-showcase-blocks",
  before: "freeze-block-registry",

  initialize() {
    withPluginApi((api) => api.registerBlock(BlockFeaturedCarousel));
  },
};
