import { settings } from "virtual:theme";
import { buildLayoutConfig, resolveLayout } from "./card-layout.js";

const LIST_ROUTE_PREFIXES = ["discovery.", "tag.", "tags."];

let config;

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
 * Card layout ("list", "grid" or null) for a category on the current viewport.
 */
export function layoutForCategory(category, site) {
  config ??= buildLayoutConfig(settings);

  return resolveLayout({
    categoryId: category?.id,
    ancestorIds: ancestorIdsOf(category),
    isMobile: site.mobileView,
    config,
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

  return layoutForCategory(router.currentRoute?.attributes?.category, site);
}
