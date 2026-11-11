import { settings } from "virtual:theme";
import HeaderTopicCell from "discourse/components/topic-list/header/topic-cell";
import { apiInitializer } from "discourse/lib/api";
import ContestEntriesOutlet from "../components/contest-entries-outlet.gjs";
import ContestTopicOutlet from "../components/contest-topic-outlet.gjs";
import ShowcaseCard from "../components/showcase-card.gjs";
import ShowcaseCarouselOutlet from "../components/showcase-carousel-outlet.gjs";
import ShowcaseSort from "../components/showcase-sort.gjs";
import {
  layoutForCategory,
  layoutForCurrentRoute,
} from "../lib/route-layout.js";

const BULK_SELECT_COLUMN = "bulk-select";
const CARD_COLUMN = "showcase-card";

// One stable cell component per layout, so recomputing the columns does not
// remount the cards.
const ListCell = <template>
  <td class="topic-showcase__cell topic-list-data">
    <ShowcaseCard @layout="list" @topic={{@topic}} />
  </td>
</template>;

const GridCell = <template>
  <td class="topic-showcase__cell topic-list-data">
    <ShowcaseCard @layout="grid" @topic={{@topic}} />
  </td>
</template>;

const CELLS = { list: ListCell, grid: GridCell };

export default apiInitializer((api) => {
  const site = api.container.lookup("service:site");
  const router = api.container.lookup("service:router");

  // Only plain discovery lists get cards. Everything else stays untouched.
  function layoutFor(context) {
    if (context?.listContext !== "discovery") {
      return null;
    }

    // Some list routes (tag intersections filtered by category) know their
    // category only through the route, so fall back to it; the navigation
    // controls resolve the layout from the route as well.
    const category =
      context.category ?? router.currentRoute?.attributes?.category;

    return layoutForCategory(category, site);
  }

  // Card lists have no header row, so the bulk select toggle and the sort
  // dropdown live in the navigation controls.
  api.registerValueTransformer("bulk-select-in-nav-controls", ({ value }) =>
    layoutForCurrentRoute(router, site) ? true : value
  );

  // Featured topics carousel above the homepage topic list. The outlet is
  // rendered on every discovery list; the component only shows on the homepage.
  if (settings.carousel_enabled && settings.carousel_filter_tags) {
    api.renderInOutlet("discovery-list-container-top", ShowcaseCarouselOutlet);
  }

  // Contests: a strip under the title of the announcement topic, the list of
  // entries (after the first post, or opened from the strip) and a link back to
  // the announcement on every entry. The outlets render on every topic; the
  // components decide whether the topic is part of a contest.
  // `topic-above-posts` sits under the topic title and, unlike
  // `topic-above-post-stream`, is also rendered when the topic is opened deep
  // in the stream (without its first post).
  if (settings.contest_enabled && settings.contest_tag_group) {
    api.renderInOutlet("topic-above-posts", ContestTopicOutlet);

    // At the top, the strip itself opens the list; no outlet after the post.
    if (settings.contest_entries_position === "after_first_post") {
      api.renderAfterWrapperOutlet("post-article", ContestEntriesOutlet);
    }
  }

  if (settings.show_sort_dropdown) {
    api.renderInOutlet("bread-crumbs-right", ShowcaseSort);
  }

  api.registerValueTransformer("topic-list-class", ({ value, context }) => {
    const layout = layoutFor(context);
    if (layout) {
      value.push("topic-showcase", `topic-showcase--${layout}`);
    }
    return value;
  });

  api.registerValueTransformer("topic-list-columns", ({ value, context }) => {
    const layout = layoutFor(context);
    if (!layout) {
      return value;
    }

    for (const [key] of value.entries()) {
      if (key !== BULK_SELECT_COLUMN) {
        value.delete(key);
      }
    }

    // The topic header cell carries the bulk select actions; the card column
    // reuses it so bulk select keeps working.
    value.add(CARD_COLUMN, { header: HeaderTopicCell, item: CELLS[layout] });

    return value;
  });

  api.registerValueTransformer(
    "topic-list-item-class",
    ({ value, context }) => {
      if (layoutFor(context)) {
        value.push("topic-showcase__row");
      }
      return value;
    }
  );

  api.registerValueTransformer(
    "topic-list-item-mobile-layout",
    ({ value, context }) => (layoutFor(context) ? false : value)
  );
});
