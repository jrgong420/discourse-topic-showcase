import { settings } from "virtual:theme";
import { buildLayoutConfig, resolveLayout } from "./card-layout.js";
import { layoutTagGroups, loadLayoutTagGroups } from "./layout-tag-groups.js";

const LIST_ROUTE_PREFIXES = ["discovery.", "tag.", "tags."];
const TAG_ROUTE_PREFIXES = ["tag.", "tags."];

// What core's tag route calls the tag of the "untagged" pages (no id).
const NO_TAG = "none";

let config;

function layoutConfig() {
  config ??= buildLayoutConfig(settings);
  return config;
}

export function ancestorIdsOf(category) {
  const ids = [];
  let parent = category?.parentCategory;
  while (parent) {
    ids.push(parent.id);
    parent = parent.parentCategory;
  }
  return ids;
}

/**
 * Starts loading the tags of the tag groups named in the layout settings. Does
 * nothing when cards are off or no tag group is listed. Meant to be called once
 * from the initializer; the layout functions below pick the result up when it
 * arrives.
 */
export function preloadLayoutTagGroups() {
  const { enabled, groupList, groupGrid } = layoutConfig();

  if (enabled && (groupList.length || groupGrid.length)) {
    loadLayoutTagGroups([...new Set([...groupList, ...groupGrid])]);
  }
}

/**
 * The name of the tag a tag route lists, or null on other routes and on the
 * "no tags" page. With further tags (an intersection) it is the primary tag.
 */
export function tagNameOfRoute(router) {
  const name = router.currentRouteName;

  if (!name || !TAG_ROUTE_PREFIXES.some((prefix) => name.startsWith(prefix))) {
    return null;
  }

  const tag = router.currentRoute?.attributes?.tag;

  // The placeholder for the untagged pages has no id; a real tag called
  // "none" has one.
  if (!tag?.name || (tag.name === NO_TAG && !tag.id)) {
    return null;
  }

  return String(tag.name);
}

/**
 * Card layout ("list", "grid" or null) of a topic list on the current
 * viewport: the tag rules, then the category rules, then the defaults (see
 * `resolveLayout`). Every place that decides about cards goes through here, so
 * the list, the sort dropdown and the bulk select controls always agree.
 *
 * @param {Object} args
 * @param {Object} [args.category]
 * @param {string|null} [args.tagName] See `tagNameOfRoute`.
 * @param {Object} args.site
 */
export function layoutForList({ category, tagName, site }) {
  const cfg = layoutConfig();

  return resolveLayout({
    tagName,
    // Read only on tag pages, so other lists do not depend on the load.
    tagGroups: tagName ? layoutTagGroups() : undefined,
    categoryId: category?.id,
    ancestorIds: ancestorIdsOf(category),
    isMobile: site.mobileView,
    config: cfg,
  });
}

/**
 * Card layout of the topic list on the current route, for things rendered
 * outside the list itself (navigation controls). Null when the route has no
 * discovery topic list or cards are off for it.
 */
export function layoutForCurrentRoute(router, site) {
  const name = router.currentRouteName;

  if (
    !name ||
    !LIST_ROUTE_PREFIXES.some((prefix) => name.startsWith(prefix)) ||
    name.toLowerCase().includes("categories")
  ) {
    return null;
  }

  return layoutForList({
    category: router.currentRoute?.attributes?.category,
    tagName: tagNameOfRoute(router),
    site,
  });
}
