import { ajax } from "discourse/lib/ajax";

/**
 * The tag groups with the given names and their tags, in one request, via the
 * tag group search. It only lists groups the current user can see, so an
 * unknown or invisible group is simply missing from the result.
 *
 * Resolves to null when the response has no usable result (core's ajax()
 * resolves `undefined` when the session is logged off); rejects when the
 * request fails.
 *
 * @param {string[]} names
 * @returns {Promise<{name: string, tags: {id: number, name: string, slug: string}[]}[]|null>}
 */
export async function fetchTagGroups(names) {
  const json = await ajax("/tag_groups/filter/search.json", {
    data: { names },
  });

  return Array.isArray(json?.results) ? json.results : null;
}
