import { tracked } from "@glimmer/tracking";
import { indexTagGroups } from "./card-layout.js";
import { fetchTagGroups } from "./tag-group-fetch.js";

// The tags of the tag groups the card layout rules refer to. It is tracked
// state: the topic list transformers and the navigation controls read it while
// they resolve the layout, so they run again when the groups arrive. Until
// then (and if the request fails) a tag group rule simply does not match.
class LayoutTagGroups {
  @tracked groups = new Map();
}

const state = new LayoutTagGroups();

let started = false;

/**
 * The loaded tag groups: lowercased group name to the lowercased names of its
 * tags. Reading it inside a template, getter or transformer makes that code
 * depend on the load.
 *
 * @returns {Map<string, Set<string>>}
 */
export function layoutTagGroups() {
  return state.groups;
}

/**
 * Loads the tags of the given tag groups, once per page session; further calls
 * do nothing. Never rejects: a failure logs one warning and leaves the tag
 * group rules unmatched.
 *
 * @param {string[]} groupNames
 */
export async function loadLayoutTagGroups(groupNames) {
  if (started || !groupNames.length) {
    return;
  }
  started = true;

  try {
    const results = await fetchTagGroups(groupNames);

    if (!results) {
      throw new Error("No tag group data");
    }

    // Replaced as a whole, so the tracked property changes once.
    state.groups = indexTagGroups(results, groupNames);
  } catch (error) {
    // eslint-disable-next-line no-console
    console.warn(
      "[Topic Showcase] Could not load the tag groups of the layout rules",
      error
    );
  }
}
