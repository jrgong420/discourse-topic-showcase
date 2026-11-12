// Pure helpers for contests: which topic is the announcement, which an entry,
// and which topics count as entries. No Ember, no DOM, so they are unit
// testable.
import { hasAllTags } from "./carousel-topics.js";
import { tagNameOf } from "./tag-names.js";

/**
 * The first of the topic's tags that is a contest tag, or null. Case
 * insensitive; the topic's own spelling is returned. Topic tags are objects
 * with a name, or plain names.
 *
 * @param {(string|{name: string})[]|null|undefined} topicTagNames
 * @param {string[]} contestTagNames
 * @returns {string|null}
 */
export function contestTagOf(topicTagNames, contestTagNames) {
  const contestTags = new Set(
    contestTagNames.map((n) => tagNameOf(n).toLowerCase())
  );

  const match = (topicTagNames ?? []).find((tag) =>
    contestTags.has(tagNameOf(tag).toLowerCase())
  );

  return match === undefined ? null : tagNameOf(match);
}

/**
 * The role of a topic in a contest.
 *
 * - "announcement": it has a contest tag and every announcement tag.
 * - "entry": it has a contest tag but not all announcement tags.
 * - null: no contest tag, or no announcement tags configured (nothing can be
 *   told apart then).
 *
 * @param {(string|{name: string})[]|null|undefined} topicTagNames
 * @param {string[]} contestTagNames
 * @param {string[]} announcementTagNames
 * @returns {"announcement"|"entry"|null}
 */
export function roleOf(topicTagNames, contestTagNames, announcementTagNames) {
  if (
    !announcementTagNames.length ||
    contestTagOf(topicTagNames, contestTagNames) === null
  ) {
    return null;
  }

  return hasAllTags({ tags: topicTagNames ?? [] }, announcementTagNames)
    ? "announcement"
    : "entry";
}

/**
 * The announcement tags in use: the contest setting, or when it is empty the
 * fallback (the carousel's tags).
 *
 * @param {string[]} configured
 * @param {string[]} fallback
 * @returns {string[]}
 */
export function resolveAnnouncementTags(configured, fallback) {
  return configured.length ? configured : fallback;
}

/**
 * The entries among topics fetched by a contest tag: everything except
 * announcements (topics carrying all the announcement tags).
 *
 * @param {Object[]} topics
 * @param {string[]} announcementTagNames
 * @returns {Object[]}
 */
export function entriesOf(topics, announcementTagNames) {
  return topics.filter((topic) => !hasAllTags(topic, announcementTagNames));
}

/**
 * The announcement among topics fetched by a contest tag and the announcement
 * tags: the first topic carrying all of them, or null.
 *
 * @param {Object[]} topics
 * @param {string} contestTagName
 * @param {string[]} announcementTagNames
 * @returns {Object|null}
 */
export function announcementOf(topics, contestTagName, announcementTagNames) {
  return (
    topics.find((topic) =>
      hasAllTags(topic, [contestTagName, ...announcementTagNames])
    ) ?? null
  );
}

// What identifies a creator across entries: the user id, else the username.
// Null when the creator carries neither (nothing to tell it apart by).
function creatorKey(creator) {
  if (creator?.id != null) {
    return `id:${creator.id}`;
  }
  if (creator?.username) {
    return `username:${String(creator.username).toLowerCase()}`;
  }
  return null;
}

/**
 * The participants of a contest: the distinct creators of its entries.
 *
 * - `count`: the number of participants. An entry without a (usable) creator
 *   counts as a participant of its own, as it cannot be matched to another
 *   entry.
 * - `avatars`: the first `maxAvatars` distinct creators in entry order. Only
 *   creators can be shown, so entries without one add to the count only.
 * - `extra`: the participants not covered by `avatars`. 0 when no avatar is
 *   shown at all, as a lone "+n" would say nothing.
 *
 * @param {Object[]} entries Topics (anything with a `creator`).
 * @param {number} maxAvatars
 * @returns {{count: number, avatars: Object[], extra: number}}
 */
export function participantsOf(entries, maxAvatars) {
  const seen = new Set();
  const creators = [];
  let unknown = 0;

  for (const entry of entries ?? []) {
    const key = creatorKey(entry?.creator);

    if (key === null) {
      unknown += 1;
    } else if (!seen.has(key)) {
      seen.add(key);
      creators.push(entry.creator);
    }
  }

  const count = creators.length + unknown;
  const limit = Number.isFinite(maxAvatars) ? Math.max(0, maxAvatars) : 0;
  const avatars = creators.slice(0, limit);

  return {
    count,
    avatars,
    extra: avatars.length ? count - avatars.length : 0,
  };
}
