// Pure helpers for the status badge on topic cards: which tag of a topic is its
// status, and how the status_badges setting is read. No Ember, no DOM, so they
// are unit testable.
import { tagNamesOf } from "./tag-names.js";

// Colours that may reach a `style` attribute: hex (#rgb, #rgba, #rrggbb,
// #rrggbbaa) or a plain colour name. Anything else (functions, `;`, quotes,
// `url(...)`) is dropped, so a typo or hostile value cannot inject CSS.
const HEX_COLOR = /^#(?:[0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/i;
const NAMED_COLOR = /^[a-z]{3,30}$/i;

/**
 * The colour if it is safe to put in a style attribute, else null.
 *
 * @param {*} value
 * @returns {string|null}
 */
export function safeColor(value) {
  const color = typeof value === "string" ? value.trim() : "";

  return HEX_COLOR.test(color) || NAMED_COLOR.test(color) ? color : null;
}

function text(value) {
  return typeof value === "string" ? value.trim() : "";
}

/**
 * Reads the status_badges setting once: keeps the objects that have a tag and
 * a label (the required properties), in their order, which is the priority.
 *
 * @param {Object[]|null|undefined} raw The value of the setting.
 * @returns {{tag: string, key: string, label: string, color: string|null, icon: string|null}[]}
 *   `key` is the lowercased tag name the badge is matched by.
 */
export function parseStatusBadges(raw) {
  if (!Array.isArray(raw)) {
    return [];
  }

  return raw
    .map((item) => ({
      tag: text(item?.tag),
      label: text(item?.label),
      color: safeColor(item?.color),
      icon: text(item?.icon) || null,
      showWeek: item?.show_week === true,
    }))
    .filter((badge) => badge.tag && badge.label)
    .map((badge) => ({ ...badge, key: badge.tag.toLowerCase() }));
}

/**
 * The status badge of a topic: the first badge (in setting order) whose tag the
 * topic carries, compared case-insensitively. At most one.
 *
 * @param {(string|{name: string})[]|null|undefined} topicTags
 * @param {ReturnType<typeof parseStatusBadges>} badges
 * @returns {ReturnType<typeof parseStatusBadges>[number]|null}
 */
export function statusBadgeOf(topicTags, badges) {
  if (!badges.length) {
    return null;
  }

  const names = new Set(
    tagNamesOf(topicTags).map((name) => name.toLowerCase())
  );

  return badges.find((badge) => names.has(badge.key)) ?? null;
}

/**
 * The topic's tags without the one shown as its status badge (the badge says
 * it already). Tags are returned as they came.
 *
 * @template T
 * @param {T[]|null|undefined} tags
 * @param {{key: string}|null} badge
 * @returns {T[]}
 */
export function tagsWithoutStatus(tags, badge) {
  const list = tags ?? [];

  if (!badge) {
    return list;
  }

  return list.filter((tag) => tagNamesOf([tag])[0].toLowerCase() !== badge.key);
}

const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

/**
 * The running week of something that started at `start`: 1 during the first
 * seven days, 2 during the next seven, and so on. Null without a valid start
 * or when the start lies in the future.
 *
 * @param {string|Date|null|undefined} start
 * @param {Date} [now]
 * @returns {number|null}
 */
export function weekSince(start, now = new Date()) {
  if (!start) {
    return null;
  }

  const elapsed = now.getTime() - new Date(start).getTime();

  return Number.isFinite(elapsed) && elapsed >= 0
    ? Math.floor(elapsed / WEEK_MS) + 1
    : null;
}
