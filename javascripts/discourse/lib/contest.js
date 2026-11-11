// Pure helpers for contests: which topic is the announcement, which an entry,
// and which topics count as entries. No Ember, no DOM, so they are unit
// testable.
import { hasAllTags } from "./carousel-topics.js";

function nameOf(tag) {
  return String(tag?.name ?? tag);
}

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
    contestTagNames.map((n) => nameOf(n).toLowerCase())
  );

  const match = (topicTagNames ?? []).find((tag) =>
    contestTags.has(nameOf(tag).toLowerCase())
  );

  return match === undefined ? null : nameOf(match);
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
