// Data helpers for the homepage panels. Topics come from core's topic filter
// (`/filter.json?q=...`) or, for plain lists such as "latest", from the same
// endpoint core's own lists use, so the user's muted categories still apply.
import { ajax } from "discourse/lib/ajax";
import TopicList from "discourse/models/topic-list";
import { hasAllTags } from "./carousel-topics.js";
import { canFilterTags } from "./tag-filter.js";

const FILTER_ORDERS = { activity: "activity", created: "created" };

/**
 * The topic filter query for a panel, or null when the panel cannot be
 * filtered safely (core ignores a tag clause it cannot parse and would return
 * unrelated topics).
 *
 * @param {Object} options
 * @param {string[]} [options.tags] Topics must carry all of them.
 * @param {string} [options.categorySlug] Topics in this category and its
 *   subcategories. A subcategory is given as "parent-slug:child-slug".
 * @param {"activity"|"created"} [options.order]
 * @param {string} [options.status] A topic filter status such as "unsolved"
 *   (needs the plugin that provides it, e.g. Solved).
 * @returns {string|null}
 */
export function homepageQuery({ tags = [], categorySlug, order, status }) {
  if (!tags.length && !categorySlug) {
    return null;
  }

  if (tags.length && !canFilterTags(tags)) {
    return null;
  }

  const parts = [];
  if (categorySlug) {
    parts.push(`category:${categorySlug}`);
  }
  if (tags.length) {
    parts.push(`tag:${tags.join("+")}`);
  }
  if (status && /^[a-z_]+$/.test(status)) {
    parts.push(`status:${status}`);
  }
  parts.push(`order:${FILTER_ORDERS[order] ?? "activity"}`);

  return parts.join(" ");
}

/**
 * The slug the topic filter takes for a category: "slug", or
 * "parent-slug:slug" for a subcategory.
 *
 * @param {Object|null|undefined} category
 * @returns {string|null}
 */
export function filterSlug(category) {
  if (!category?.slug) {
    return null;
  }

  const parent = category.parentCategory;
  return parent?.slug ? `${parent.slug}:${category.slug}` : category.slug;
}

/**
 * Whether a topic is the "About the … category" topic of its category. Those
 * are pinned definitions, not content, so panels skip them.
 *
 * @param {Object} topic
 * @returns {boolean}
 */
export function isCategoryDefinition(topic) {
  const definitionId = topic.category?.topic_id;
  return definitionId != null && definitionId === topic.id;
}

/**
 * Fetches topics for a panel.
 *
 * @param {Object} store The store service.
 * @param {Object} source
 * @param {string} [source.query] A topic filter query (see `homepageQuery`).
 * @param {string} [source.list] A core list name ("latest", "top", ...),
 *   used when there is no query.
 * @param {string[]} [source.tags] Tags every returned topic must carry
 *   (re-checked on the client, whatever the server made of the query).
 * @param {number} count Maximum number of topics.
 * @returns {Promise<{topics: Object[], hasMore: boolean}|null>} null when
 *   there is nothing to show.
 */
export async function fetchPanelTopics(store, { query, list, tags }, count) {
  let topics;
  let hasMore;

  if (query) {
    const json = await ajax("/filter.json", { data: { q: query } });
    if (!json?.topic_list) {
      throw new Error("The topic filter returned no topic list");
    }
    topics = TopicList.topicsFrom(store, json) ?? [];
    hasMore = !!json.topic_list.more_topics_url;
  } else if (list) {
    const topicList = await store.findFiltered("topicList", { filter: list });
    topics = topicList.topics ?? [];
    hasMore = !!topicList.more_topics_url;
  } else {
    return null;
  }

  const kept = topics.filter(
    (topic) =>
      !isCategoryDefinition(topic) && (!tags?.length || hasAllTags(topic, tags))
  );

  if (!kept.length) {
    return null;
  }

  return {
    topics: kept.slice(0, count),
    hasMore: hasMore || kept.length > count,
  };
}
