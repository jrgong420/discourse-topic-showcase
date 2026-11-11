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

function normalizeDefault(value) {
  return LAYOUTS.includes(value) ? value : null;
}

/**
 * Builds the layout config from the theme `settings` object. Category lists
 * are pipe-separated id strings in the settings.
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
  };
}

/**
 * Decides which card layout applies to a topic list.
 *
 * @param {Object} args
 * @param {number} [args.categoryId] Category of the list, if any.
 * @param {number[]} [args.ancestorIds] Ancestor category ids, nearest parent first.
 * @param {boolean} args.isMobile Whether the mobile rules apply.
 * @param {Object} args.config See `buildLayoutConfig`.
 * @returns {"list"|"grid"|null} `null` means: leave the list untouched.
 */
export function resolveLayout({
  categoryId,
  ancestorIds = [],
  isMobile,
  config,
}) {
  if (!config?.enabled) {
    return null;
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
