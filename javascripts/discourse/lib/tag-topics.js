import { ajax } from "discourse/lib/ajax";
import TopicList from "discourse/models/topic-list";
import { hasAllTags } from "./carousel-topics.js";
import { filterQuery } from "./tag-filter.js";

/**
 * Fetches the first page of topics carrying all the tags, through core's topic
 * filter. The tags must pass `canFilterTags`.
 *
 * Topics are converted the way core's topic lists convert them, so cards get
 * real Topic models (category, creator, thumbnails, lastUnreadUrl). Only
 * topics that really carry every tag are kept, whatever the server made of the
 * query.
 *
 * @param {Object} store The store service.
 * @param {string[]} tags
 * @param {string} order See `filterQuery`.
 * @returns {Promise<{topics: Object[], hasMore: boolean}>} `hasMore` tells
 *   whether the server has further pages. Rejects when the response has no
 *   topic list.
 */
export async function fetchTopicsByTags(store, tags, order) {
  const json = await ajax("/filter.json", {
    data: { q: filterQuery(tags, order) },
  });

  if (!json?.topic_list) {
    throw new Error("The topic filter returned no topic list");
  }

  return {
    topics: (TopicList.topicsFrom(store, json) ?? []).filter((topic) =>
      hasAllTags(topic, tags)
    ),
    hasMore: !!json.topic_list.more_topics_url,
  };
}
