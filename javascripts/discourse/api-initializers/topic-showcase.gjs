import { settings } from "virtual:theme";
import HeaderTopicCell from "discourse/components/topic-list/header/topic-cell";
import { apiInitializer } from "discourse/lib/api";
import ShowcaseCard from "../components/showcase-card.gjs";
import { buildLayoutConfig, resolveLayout } from "../lib/card-layout.js";

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

function ancestorIdsOf(category) {
  const ids = [];
  let parent = category?.parentCategory;
  while (parent) {
    ids.push(parent.id);
    parent = parent.parentCategory;
  }
  return ids;
}

export default apiInitializer((api) => {
  const site = api.container.lookup("service:site");
  const config = buildLayoutConfig(settings);

  // Only plain discovery lists get cards. Everything else stays untouched.
  function layoutFor(context) {
    if (context?.listContext !== "discovery") {
      return null;
    }

    const { category } = context;
    return resolveLayout({
      categoryId: category?.id,
      ancestorIds: ancestorIdsOf(category),
      isMobile: site.mobileView,
      config,
    });
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

    // The topic header cell carries the bulk select actions and the topic
    // list tabs; the card column reuses it so the header keeps working.
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
