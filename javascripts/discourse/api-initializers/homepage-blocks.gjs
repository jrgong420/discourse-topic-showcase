import { settings } from "virtual:theme";
import BlockGroup from "discourse/blocks/builtin/block-group";
import { apiInitializer } from "discourse/lib/api";
import BlockCategoryPanel from "../blocks/block-category-panel.gjs";
import BlockFeaturedCarousel from "../blocks/block-featured-carousel.gjs";
import BlockTopicPanel from "../blocks/block-topic-panel.gjs";
import { parseTagList } from "../lib/tag-filter.js";

// First id of a category list setting ("12|34" -> 12), or undefined.
const firstCategoryId = (value) =>
  Number(
    String(value ?? "")
      .split("|")
      .find(Boolean)
  ) || undefined;

// The custom homepage (homepage_enabled; about.json switches core to the
// custom homepage with the same setting). Every section is optional: a
// section without its tag/category, or with a count of 0, is left out, and a
// section that finds no topics renders nothing.
//
// Wide screens: carousel across the top, then a main column (releases,
// showcase cards, latest) and a side column (partners, deals, docs). Narrow
// screens stack them in reading order (see stylesheets/layouts/homepage.scss).
export default apiInitializer((api) => {
  // An outlet takes one layout for the whole site; leave it to other themes
  // unless the homepage is switched on.
  if (!settings.homepage_enabled) {
    return;
  }

  // Core shows the welcome banner on the homepage only when that is a discovery
  // list ("latest", "categories", ...). Show it on the custom homepage too,
  // wherever its page visibility would include the homepage.
  api.registerValueTransformer(
    "welcome-banner-display-for-route",
    ({ value, context }) =>
      value ||
      (context.currentRouteName === "discovery.custom" &&
        ["homepage", "top_menu_pages"].includes(
          context.welcomeBannerPageVisibility
        ))
  );

  const releasesTags = parseTagList(settings.homepage_releases_tags);
  const galleryCategoryId = firstCategoryId(settings.homepage_gallery_category);
  const partnersTags = parseTagList(settings.homepage_partners_tags);
  const partnersCategoryId = firstCategoryId(
    settings.homepage_partners_category
  );
  const dealsTags = parseTagList(settings.homepage_deals_tags);
  const docsCategoryId = firstCategoryId(settings.homepage_docs_category);

  const main = [
    releasesTags.length &&
      settings.homepage_releases_count > 0 && {
        block: BlockTopicPanel,
        id: "releases",
        args: {
          title: "homepage.releases.title",
          icon: "rocket",
          tags: releasesTags,
          order: "created",
          count: settings.homepage_releases_count,
          display: "rows",
        },
      },
    galleryCategoryId &&
      settings.homepage_gallery_count > 0 && {
        block: BlockTopicPanel,
        id: "gallery",
        args: {
          title: "homepage.gallery.title",
          icon: "screwdriver-wrench",
          categoryId: galleryCategoryId,
          order: "created",
          count: settings.homepage_gallery_count,
          display: "cards",
        },
      },
    settings.homepage_latest_count > 0 && {
      block: BlockTopicPanel,
      id: "latest",
      args: {
        title: "homepage.latest.title",
        icon: "clock",
        list: "latest",
        count: settings.homepage_latest_count,
        display: "rows",
        showAvatars: true,
      },
    },
  ].filter(Boolean);

  const side = [
    (partnersTags.length || partnersCategoryId) &&
      settings.homepage_partners_count > 0 && {
        block: BlockTopicPanel,
        id: "partners",
        args: {
          title: "homepage.partners.title",
          icon: "handshake-angle",
          tags: partnersTags,
          categoryId: partnersCategoryId,
          count: settings.homepage_partners_count,
          display: "tiles",
        },
      },
    dealsTags.length &&
      settings.homepage_deals_count > 0 && {
        block: BlockTopicPanel,
        id: "deals",
        args: {
          title: "homepage.deals.title",
          icon: "tag",
          tags: dealsTags,
          order: "created",
          count: settings.homepage_deals_count,
          display: "rows",
        },
      },
    docsCategoryId &&
      settings.homepage_docs_count > 0 && {
        block: BlockCategoryPanel,
        id: "docs",
        args: {
          title: "homepage.docs.title",
          icon: "book",
          categoryId: docsCategoryId,
          count: settings.homepage_docs_count,
          showDescriptions: settings.homepage_docs_descriptions,
        },
      },
  ].filter(Boolean);

  api.renderBlocks(
    "homepage-blocks",
    [
      settings.homepage_featured_carousel &&
        settings.carousel_filter_tags && {
          block: BlockFeaturedCarousel,
          id: "featured",
        },
      main.length && { block: BlockGroup, id: "main", children: main },
      side.length && { block: BlockGroup, id: "side", children: side },
    ].filter(Boolean)
  );
});
