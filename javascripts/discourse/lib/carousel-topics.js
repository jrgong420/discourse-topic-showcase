// Pure helpers for the featured topics carousel: event filtering, ordering and
// the "new since you last looked" count. No Ember, no DOM, so they are unit
// testable; `now` and `random` are injected for the same reason.

function toTime(value) {
  if (value == null || value === "") {
    return null;
  }

  let time;
  if (typeof value === "number") {
    time = value;
  } else if (value instanceof Date) {
    time = value.getTime();
  } else {
    time = Date.parse(value);
  }

  return Number.isNaN(time) ? null : time;
}

/**
 * Where a topic stands relative to its calendar event, based on the
 * `event_starts_at` / `event_ends_at` the Discourse Calendar plugin adds to
 * topic list items.
 *
 * - "expired": the event ended (without an end date: started) in the past.
 * - "upcoming": the event starts in the future.
 * - "none": no event dates, or the event is running right now. Topics without
 *   event dates are never filtered.
 */
function eventState(topic, now) {
  const start = toTime(topic.event_starts_at);
  const end = toTime(topic.event_ends_at);

  if (start == null && end == null) {
    return "none";
  }

  if ((end ?? start) < now) {
    return "expired";
  }

  if (start != null && start > now) {
    return "upcoming";
  }

  return "none";
}

// Newest first. Topics with a missing or unparsable date go last, and ties
// keep their incoming order (Array#sort is stable).
function sortedBy(topics, field) {
  return [...topics].sort(
    (a, b) => (toTime(b[field]) ?? -Infinity) - (toTime(a[field]) ?? -Infinity)
  );
}

// Fisher-Yates, on a copy.
function shuffled(topics, random) {
  const result = [...topics];

  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [result[i], result[j]] = [result[j], result[i]];
  }

  return result;
}

/**
 * Applies event filtering, then ordering, then the item limit.
 *
 * @param {Object[]} topics Topics (or plain objects with the same fields).
 * @param {Object} options
 * @param {"latest"|"created"|"random"} options.order latest = most recently
 *   active first (`bumped_at`), created = newest topic first (`created_at`),
 *   random = shuffled.
 * @param {number} options.maxItems
 * @param {boolean} options.displayExpired
 * @param {boolean} options.displayUpcoming
 * @param {Date|number} options.now
 * @param {() => number} options.random Returns a number in [0, 1).
 * @returns {Object[]} A new array; the input is not modified.
 */
export function filterAndOrderTopics(
  topics,
  { order, maxItems, displayExpired, displayUpcoming, now, random }
) {
  const nowTime = toTime(now) ?? Date.now();

  const visible = topics.filter((topic) => {
    const state = eventState(topic, nowTime);
    return !(
      (state === "expired" && !displayExpired) ||
      (state === "upcoming" && !displayUpcoming)
    );
  });

  let ordered;
  if (order === "random") {
    ordered = shuffled(visible, random ?? Math.random);
  } else if (order === "created") {
    ordered = sortedBy(visible, "created_at");
  } else {
    ordered = sortedBy(visible, "bumped_at");
  }

  return Number.isFinite(maxItems)
    ? ordered.slice(0, Math.max(0, maxItems))
    : ordered;
}

/**
 * How many topics are new since `seenAt`: topics whose latest of
 * `created_at` and `bumped_at` is later than it. Without a usable `seenAt`
 * nothing can be called new.
 *
 * @param {Object[]} topics
 * @param {string|Date|number|null} seenAt
 * @returns {number}
 */
export function countNewSince(topics, seenAt) {
  const seenTime = toTime(seenAt);
  if (seenTime == null) {
    return 0;
  }

  return topics.filter((topic) => {
    const latest = Math.max(
      toTime(topic.created_at) ?? -Infinity,
      toTime(topic.bumped_at) ?? -Infinity
    );
    return latest > seenTime;
  }).length;
}

/**
 * Whether a topic carries every one of the given tag names. Topic tags are
 * serialised as objects with a name, or as plain names on older data.
 */
export function hasAllTags(topic, tagNames) {
  const names = (topic.tags ?? []).map((tag) =>
    String(tag?.name ?? tag).toLowerCase()
  );

  return tagNames.every((name) => names.includes(String(name).toLowerCase()));
}
