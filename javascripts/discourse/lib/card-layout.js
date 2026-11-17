import { parseTagList } from "./tag-filter.js";
import { tagNamesOf } from "./tag-names.js";

const LAYOUTS = ["list", "grid"];

/**
 * Parses a pipe-separated id string from a list setting into numbers.
 */
export function parseIdList(value) {
  return String(value ?? "")
    .split("|")
    .map((id) => parseInt(id, 10))
    .filter((id) => Number.isFinite(id));
}

// Names from a pipe-separated list setting, lowercased: tags and tag groups
// are matched case-insensitively.
function parseNameList(value) {
  return parseTagList(value).map((name) => name.toLowerCase());
}

function normalizeDefault(value) {
  return LAYOUTS.includes(value) ? value : null;
}

/**
 * Builds the layout config from the theme `settings` object. Category lists
 * are pipe-separated id strings in the settings; tag and tag group lists are
 * pipe-separated names. The tag rules apply to desktop and mobile alike.
 */
export function buildLayoutConfig(settings) {
  return {
    enabled: !!settings.cards_enabled,
    defaultDesktop: settings.default_layout_desktop,
    defaultMobile: settings.default_layout_mobile,
    desktopList: parseIdList(settings.list_view_categories),
    desktopGrid: parseIdList(settings.grid_view_categories),
    mobileList: parseIdList(settings.mobile_list_view_categories),
    mobileGrid: parseIdList(settings.mobile_grid_view_categories),
    inherit: !!settings.inherit_layout_to_subcategories,
    tagList: parseNameList(settings.list_view_tags),
    tagGrid: parseNameList(settings.grid_view_tags),
    groupList: parseNameList(settings.list_view_tag_groups),
    groupGrid: parseNameList(settings.grid_view_tag_groups),
  };
}

/**
 * Indexes the result of the tag group search for the layout rules.
 *
 * @param {{name: string, tags: ({name: string}|string)[]}[]} results Tag
 *   groups with their tags.
 * @param {string[]} groupNames The groups to keep (any case).
 * @returns {Map<string, Set<string>>} Lowercased group name to the lowercased
 *   names of its tags. Groups that are not in the results are not in the map.
 */
export function indexTagGroups(results, groupNames) {
  const wanted = new Set(groupNames.map((name) => name.toLowerCase()));
  const index = new Map();

  for (const group of results ?? []) {
    const key = String(group?.name).toLowerCase();

    if (wanted.has(key)) {
      index.set(
        key,
        new Set(tagNamesOf(group.tags).map((n) => n.toLowerCase()))
      );
    }
  }

  return index;
}

// The layout a tag gets from the tag lists and, failing that, from the tag
// groups. Within each step, list wins over grid.
function resolveTagLayout(tagName, tagGroups, config) {
  const tag = tagName.toLowerCase();
  const listed = (names) => (names ?? []).some((n) => n.toLowerCase() === tag);
  const inGroup = (groupNames) =>
    (groupNames ?? []).some((name) =>
      tagGroups?.get(name.toLowerCase())?.has(tag)
    );

  if (listed(config.tagList)) {
    return "list";
  }
  if (listed(config.tagGrid)) {
    return "grid";
  }
  if (inGroup(config.groupList)) {
    return "list";
  }
  if (inGroup(config.groupGrid)) {
    return "grid";
  }
  return null;
}

/**
 * Decides which card layout applies to a topic list. First match wins:
 *
 * 1. the tag of the list is in the tag lists (list before grid),
 * 2. the tag belongs to a listed tag group (list before grid),
 * 3. the category rules (its own, then the inherited ones),
 * 4. the default of the viewport.
 *
 * Cards off (`config.enabled` false) beats all of it.
 *
 * @param {Object} args
 * @param {string} [args.tagName] The tag of the list, if it is a tag page.
 *   With further tags (an intersection) only the primary tag is given.
 * @param {Map<string, Set<string>>} [args.tagGroups] Lowercased tag group
 *   names to the lowercased names of their tags (see `indexTagGroups`). Groups
 *   that are not loaded (yet) are simply missing.
 * @param {number} [args.categoryId] Category of the list, if any.
 * @param {number[]} [args.ancestorIds] Ancestor category ids, nearest parent first.
 * @param {boolean} args.isMobile Whether the mobile rules apply.
 * @param {Object} args.config See `buildLayoutConfig`.
 * @returns {"list"|"grid"|null} `null` means: leave the list untouched.
 */
export function resolveLayout({
  tagName,
  tagGroups,
  categoryId,
  ancestorIds = [],
  isMobile,
  config,
}) {
  if (!config?.enabled) {
    return null;
  }

  if (tagName) {
    const tagLayout = resolveTagLayout(tagName, tagGroups, config);
    if (tagLayout) {
      return tagLayout;
    }
  }

  const listIds = (isMobile ? config.mobileList : config.desktopList) ?? [];
  const gridIds = (isMobile ? config.mobileGrid : config.desktopGrid) ?? [];

  const match = (id) => {
    if (listIds.includes(id)) {
      return "list";
    }
    if (gridIds.includes(id)) {
      return "grid";
    }
    return null;
  };

  if (categoryId != null) {
    const own = match(categoryId);
    if (own) {
      return own;
    }

    if (config.inherit) {
      for (const ancestorId of ancestorIds) {
        const inherited = match(ancestorId);
        if (inherited) {
          return inherited;
        }
      }
    }
  }

  return normalizeDefault(
    isMobile ? config.defaultMobile : config.defaultDesktop
  );
}
