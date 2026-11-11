import { settings } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import {
  announcementOf,
  contestTagOf,
  entriesOf,
  resolveAnnouncementTags,
  roleOf,
} from "./contest.js";
import { createPromiseCache } from "./promise-cache.js";
import { canFilterTags, parseTagList } from "./tag-filter.js";
import { fetchTopicsByTags } from "./tag-topics.js";

// Everything here is cached for the page session, so the strip, the full list
// and the backlink of one topic view share their requests, and moving between
// topics does not refetch. Failed requests are not cached (see
// createPromiseCache); a reload starts over.
const groupCache = createPromiseCache();
const entriesCache = createPromiseCache();
const announcementCache = createPromiseCache();

// One warning per kind, not one per topic view.
const warned = new Set();

function warnOnce(kind, message, error) {
  if (warned.has(kind)) {
    return;
  }
  warned.add(kind);
  // eslint-disable-next-line no-console
  console.warn(`[Topic Showcase] ${message}`, error ?? "");
}

/**
 * The contest settings in effect, or null when the feature is off: it needs
 * contest_enabled, a tag group and announcement tags (contest_announcement_tags,
 * else carousel_filter_tags).
 *
 * @returns {{tagGroup: string, announcementTags: string[], order: string, maxEntries: number}|null}
 */
export function contestConfig() {
  const tagGroup = String(settings.contest_tag_group ?? "").trim();
  const announcementTags = resolveAnnouncementTags(
    parseTagList(settings.contest_announcement_tags),
    parseTagList(settings.carousel_filter_tags)
  );

  if (!settings.contest_enabled || !tagGroup || !announcementTags.length) {
    return null;
  }

  if (!canFilterTags(announcementTags)) {
    warnOnce(
      "announcement-tags",
      "The contest announcement tags contain a tag the topic filter cannot match; contests are not shown."
    );
    return null;
  }

  return {
    tagGroup,
    announcementTags,
    order: settings.contest_entries_order,
    maxEntries: settings.contest_max_entries,
  };
}

// The tags ({id, name, slug}) of the contest tag group. One request, via the
// tag group search, which only lists groups the current user can see; an
// unknown or invisible group has no tags.
function loadGroupTags(group) {
  return groupCache.get(group.toLowerCase(), async () => {
    const json = await ajax("/tag_groups/filter/search.json", {
      data: { names: [group] },
    });

    if (!Array.isArray(json?.results)) {
      return null;
    }

    const match = json.results.find(
      (result) => String(result.name).toLowerCase() === group.toLowerCase()
    );

    return match?.tags ?? [];
  });
}

// Topics with the contest tag, minus announcements. `hasMore` tells whether
// the first page was full.
function loadEntries(store, config, tagName) {
  return entriesCache.get(
    `${tagName.toLowerCase()}|${config.order}|${config.announcementTags.join("+").toLowerCase()}`,
    async () => {
      const { topics, hasMore } = await fetchTopicsByTags(
        store,
        [tagName],
        config.order
      );

      return { entries: entriesOf(topics, config.announcementTags), hasMore };
    }
  );
}

// The announcement of a contest, or null (cached too, as "none").
async function loadAnnouncement(store, config, tagName) {
  // The contest tag may also be listed as an announcement tag. Core's filter
  // rejects a query that names the same tag twice, so each tag goes in once.
  const seen = new Set();
  const tags = [tagName, ...config.announcementTags].filter((tag) => {
    const key = tag.toLowerCase();
    return seen.has(key) ? false : seen.add(key);
  });

  const { announcement } = await announcementCache.get(
    tags.join("+").toLowerCase(),
    async () => {
      const { topics } = await fetchTopicsByTags(store, tags, "created");

      return {
        announcement: announcementOf(topics, tagName, config.announcementTags),
      };
    }
  );

  return announcement;
}

/**
 * What a topic is in a contest, with the data to show it. Resolves to null
 * when the feature is off, the topic is not part of a contest, the data cannot
 * be loaded or there is nothing to show; never rejects (a failure logs one
 * warning).
 *
 * - announcement: `{role, tag, entries, hasMore}`, with at least one entry.
 *   `tag` is `{id, name, slug}`.
 * - entry: `{role, tag, announcement}`.
 *
 * @param {Object} store The store service.
 * @param {Object} topic A topic model (anything with `tags`).
 */
export async function loadContestContext(store, topic) {
  const config = contestConfig();
  if (!config) {
    return null;
  }

  try {
    const groupTags = await loadGroupTags(config.tagGroup);
    const names = groupTags.map((tag) => tag.name);

    const role = roleOf(topic.tags, names, config.announcementTags);
    if (!role) {
      return null;
    }

    const topicTag = contestTagOf(topic.tags, names).toLowerCase();
    const tag = groupTags.find((t) => t.name.toLowerCase() === topicTag);

    if (!canFilterTags([tag.name])) {
      warnOnce(
        `tag:${tag.name}`,
        `The contest tag "${tag.name}" cannot be matched by the topic filter; the contest is not shown.`
      );
      return null;
    }

    if (role === "announcement") {
      const { entries, hasMore } = await loadEntries(store, config, tag.name);

      return entries.length ? { role, tag, entries, hasMore } : null;
    }

    const announcement = await loadAnnouncement(store, config, tag.name);

    return announcement ? { role, tag, announcement } : null;
  } catch (error) {
    warnOnce("fetch", "Could not load the contest data", error);
    return null;
  }
}
