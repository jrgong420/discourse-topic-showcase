// Topic tags are serialised as objects with a name (`{id, name, slug}`), or as
// plain names on older data. These helpers are the one place that reads both.

/**
 * The name of a tag, whichever form it comes in.
 *
 * @param {string|{name: string}} tag
 * @returns {string}
 */
export function tagNameOf(tag) {
  return String(tag?.name ?? tag);
}

/**
 * The names of a topic's tags.
 *
 * @param {(string|{name: string})[]|null|undefined} tags
 * @returns {string[]}
 */
export function tagNamesOf(tags) {
  return (tags ?? []).map(tagNameOf);
}
