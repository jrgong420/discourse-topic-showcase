const HEX_COLOR = /^[0-9a-f]{3}([0-9a-f]{3})?$/i;

function toArray(value) {
  return Array.isArray(value) ? value : [];
}

/**
 * Picks the subcategories the carousel shows for a category.
 *
 * Core's own subcategory list for the page (`listed`) wins: it is already
 * permission-filtered and in the order core displays. Without it, the
 * category's subcategories (`fallback`) are used. Only direct children are
 * kept, in the order they come in.
 *
 * @param {Object} args
 * @param {number} args.categoryId Category of the page.
 * @param {number[]} args.enabledIds Categories that get a carousel.
 * @param {number|string} args.minChildren Minimum number of subcategories
 *   (never below 2).
 * @param {Object[]} [args.listed] Categories of core's subcategory list.
 * @param {Object[]} [args.fallback] Subcategories of the category.
 * @returns {Object[]} The subcategories, or an empty array when the carousel
 *   should not show.
 */
export function carouselSubcategories({
  categoryId,
  enabledIds,
  minChildren,
  listed,
  fallback,
}) {
  if (categoryId == null || !toArray(enabledIds).includes(categoryId)) {
    return [];
  }

  const source = Array.isArray(listed) ? listed : toArray(fallback);
  const children = source.filter(
    (category) => category?.parent_category_id === categoryId
  );

  const min = Math.max(2, Number(minChildren) || 2);
  return children.length >= min ? children : [];
}

/**
 * The CSS colour of a category: `#` plus the hex value, or `null` when the
 * value is not a 3 or 6 digit hex colour. Nothing else may reach inline CSS.
 */
export function categoryColor(value) {
  return typeof value === "string" && HEX_COLOR.test(value)
    ? `#${value}`
    : null;
}
