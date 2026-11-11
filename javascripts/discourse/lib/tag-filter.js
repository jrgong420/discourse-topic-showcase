// Pure helpers for fetching topics by tag through core's topic filter
// (`/filter.json?q=...`), shared by the carousel and the contest entries.

// Core's ordering keywords for the filter endpoint. Anything else (such as the
// carousel's client-side "random") fetches by activity like "latest".
const FILTER_ORDERS = { latest: "activity", created: "created" };

// Tag names core's `tag:` topic filter can match (lib/topics_filter.rb).
const FILTERABLE_TAG = /^[\p{N}\p{L}\-_.]+$/u;

/**
 * Splits a pipe separated list setting into trimmed, non-empty names.
 *
 * @param {string|null|undefined} value
 * @returns {string[]}
 */
export function parseTagList(value) {
  return String(value ?? "")
    .split("|")
    .map((tag) => tag.trim())
    .filter(Boolean);
}

/**
 * Whether every tag name can be matched by core's `tag:` filter. Core ignores a
 * tag clause it cannot parse and then returns unfiltered topics, so callers
 * show nothing for such names rather than unrelated topics.
 *
 * @param {string[]} tags
 * @returns {boolean}
 */
export function canFilterTags(tags) {
  return tags.every((tag) => FILTERABLE_TAG.test(tag));
}

/**
 * The filter query for topics carrying all the tags (`tag:a+b` is an AND).
 *
 * @param {string[]} tags
 * @param {"latest"|"created"|string} order latest = most recently active
 *   first, created = newest topic first.
 * @returns {string}
 */
export function filterQuery(tags, order) {
  return `tag:${tags.join("+")} order:${FILTER_ORDERS[order] ?? "activity"}`;
}
