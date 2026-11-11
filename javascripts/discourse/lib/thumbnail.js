/**
 * URL of the smallest thumbnail of a topic, falling back to its image. Null
 * for topics without an image.
 *
 * @param {Object} topic
 * @returns {string|null}
 */
export function smallestThumbnailUrl(topic) {
  const thumbnails = [...(topic.thumbnails ?? [])].sort(
    (a, b) => a.width - b.width
  );

  return thumbnails[0]?.url ?? topic.image_url ?? null;
}
