import { module, test } from "qunit";
import {
  buildLayoutConfig,
  indexTagGroups,
  resolveLayout,
} from "../../../../javascripts/discourse/lib/card-layout.js";

function config(overrides = {}) {
  return {
    enabled: true,
    defaultDesktop: "none",
    defaultMobile: "none",
    desktopList: [],
    desktopGrid: [],
    mobileList: [],
    mobileGrid: [],
    inherit: false,
    tagList: [],
    tagGrid: [],
    groupList: [],
    groupGrid: [],
    ...overrides,
  };
}

module("Unit | Lib | card-layout", function () {
  test("disabled config always resolves to null", function (assert) {
    const cfg = config({
      enabled: false,
      defaultDesktop: "grid",
      desktopList: [1],
    });

    assert.strictEqual(
      resolveLayout({ categoryId: 1, isMobile: false, config: cfg }),
      null
    );
    assert.strictEqual(resolveLayout({ isMobile: false, config: cfg }), null);
  });

  test("uses the desktop sets on desktop and the mobile sets on mobile", function (assert) {
    const cfg = config({
      desktopList: [1],
      desktopGrid: [2],
      mobileList: [2],
      mobileGrid: [1],
    });

    assert.strictEqual(
      resolveLayout({ categoryId: 1, isMobile: false, config: cfg }),
      "list"
    );
    assert.strictEqual(
      resolveLayout({ categoryId: 2, isMobile: false, config: cfg }),
      "grid"
    );
    assert.strictEqual(
      resolveLayout({ categoryId: 1, isMobile: true, config: cfg }),
      "grid"
    );
    assert.strictEqual(
      resolveLayout({ categoryId: 2, isMobile: true, config: cfg }),
      "list"
    );
  });

  test("list wins when a category is in both sets", function (assert) {
    const cfg = config({
      desktopList: [5],
      desktopGrid: [5],
      mobileList: [5],
      mobileGrid: [5],
    });

    assert.strictEqual(
      resolveLayout({ categoryId: 5, isMobile: false, config: cfg }),
      "list"
    );
    assert.strictEqual(
      resolveLayout({ categoryId: 5, isMobile: true, config: cfg }),
      "list"
    );
  });

  test("an unlisted category without inherit falls back to the viewport default", function (assert) {
    const cfg = config({
      desktopGrid: [1],
      defaultDesktop: "list",
      defaultMobile: "grid",
    });

    assert.strictEqual(
      resolveLayout({
        categoryId: 9,
        ancestorIds: [1],
        isMobile: false,
        config: cfg,
      }),
      "list"
    );
    assert.strictEqual(
      resolveLayout({
        categoryId: 9,
        ancestorIds: [1],
        isMobile: true,
        config: cfg,
      }),
      "grid"
    );
  });

  test("inherit walks the ancestors nearest first", function (assert) {
    const cfg = config({
      inherit: true,
      desktopList: [2],
      desktopGrid: [1],
      defaultDesktop: "none",
    });

    // 3 -> parent 2 (list) -> grandparent 1 (grid): nearest wins
    assert.strictEqual(
      resolveLayout({
        categoryId: 3,
        ancestorIds: [2, 1],
        isMobile: false,
        config: cfg,
      }),
      "list"
    );
    // 4 -> parent 1 (grid)
    assert.strictEqual(
      resolveLayout({
        categoryId: 4,
        ancestorIds: [1],
        isMobile: false,
        config: cfg,
      }),
      "grid"
    );
  });

  test("inherit: list wins over grid within the same ancestor", function (assert) {
    const cfg = config({
      inherit: true,
      desktopList: [1],
      desktopGrid: [1],
    });

    assert.strictEqual(
      resolveLayout({
        categoryId: 3,
        ancestorIds: [1],
        isMobile: false,
        config: cfg,
      }),
      "list"
    );
  });

  test("a category's own rule beats an ancestor's rule", function (assert) {
    const cfg = config({
      inherit: true,
      desktopList: [1],
      desktopGrid: [3],
    });

    assert.strictEqual(
      resolveLayout({
        categoryId: 3,
        ancestorIds: [1],
        isMobile: false,
        config: cfg,
      }),
      "grid"
    );
  });

  test("inherit with no matching ancestor falls back to the default", function (assert) {
    const cfg = config({
      inherit: true,
      desktopList: [1],
      defaultDesktop: "grid",
    });

    assert.strictEqual(
      resolveLayout({
        categoryId: 3,
        ancestorIds: [7, 8],
        isMobile: false,
        config: cfg,
      }),
      "grid"
    );
  });

  test("without a category the viewport default applies", function (assert) {
    const cfg = config({
      desktopList: [1],
      defaultDesktop: "grid",
      defaultMobile: "list",
    });

    assert.strictEqual(resolveLayout({ isMobile: false, config: cfg }), "grid");
    assert.strictEqual(resolveLayout({ isMobile: true, config: cfg }), "list");
  });

  test("default 'none' resolves to null", function (assert) {
    const cfg = config({ desktopList: [1] });

    assert.strictEqual(resolveLayout({ isMobile: false, config: cfg }), null);
    assert.strictEqual(
      resolveLayout({ categoryId: 9, isMobile: true, config: cfg }),
      null
    );
  });

  test("buildLayoutConfig parses pipe-separated category ids", function (assert) {
    const cfg = buildLayoutConfig({
      cards_enabled: true,
      default_layout_desktop: "list",
      default_layout_mobile: "none",
      list_view_categories: "11|7",
      grid_view_categories: "",
      mobile_list_view_categories: "6",
      mobile_grid_view_categories: "3|x|4",
      inherit_layout_to_subcategories: true,
      list_view_tags: "Flowering|harvest",
      grid_view_tags: "",
      list_view_tag_groups: "Stages",
      grid_view_tag_groups: " Phases |Other",
    });

    assert.true(cfg.enabled);
    assert.strictEqual(cfg.defaultDesktop, "list");
    assert.strictEqual(cfg.defaultMobile, "none");
    assert.deepEqual(cfg.desktopList, [11, 7]);
    assert.deepEqual(cfg.desktopGrid, []);
    assert.deepEqual(cfg.mobileList, [6]);
    assert.deepEqual(cfg.mobileGrid, [3, 4]);
    assert.true(cfg.inherit);
    assert.deepEqual(cfg.tagList, ["flowering", "harvest"]);
    assert.deepEqual(cfg.tagGrid, []);
    assert.deepEqual(cfg.groupList, ["stages"]);
    assert.deepEqual(cfg.groupGrid, ["phases", "other"]);
  });

  test("buildLayoutConfig reads missing tag settings as empty lists", function (assert) {
    const cfg = buildLayoutConfig({ cards_enabled: true });

    assert.deepEqual(cfg.tagList, []);
    assert.deepEqual(cfg.tagGrid, []);
    assert.deepEqual(cfg.groupList, []);
    assert.deepEqual(cfg.groupGrid, []);
  });

  module("tag rules", function () {
    const groups = new Map([
      ["stages", new Set(["flowering", "harvest"])],
      ["topics", new Set(["tips"])],
    ]);

    test("a listed tag gets its layout, on desktop and mobile alike", function (assert) {
      const cfg = config({ tagList: ["flowering"], tagGrid: ["tips"] });

      for (const isMobile of [false, true]) {
        assert.strictEqual(
          resolveLayout({ tagName: "flowering", isMobile, config: cfg }),
          "list"
        );
        assert.strictEqual(
          resolveLayout({ tagName: "tips", isMobile, config: cfg }),
          "grid"
        );
      }
    });

    test("the tag name is compared case-insensitively", function (assert) {
      const cfg = config({ tagList: ["Flowering"] });

      assert.strictEqual(
        resolveLayout({ tagName: "FLOWERING", isMobile: false, config: cfg }),
        "list"
      );
    });

    test("list wins when a tag is in both lists", function (assert) {
      const cfg = config({ tagList: ["a"], tagGrid: ["a"] });

      assert.strictEqual(
        resolveLayout({ tagName: "a", isMobile: false, config: cfg }),
        "list"
      );
    });

    test("a tag beats the category", function (assert) {
      const cfg = config({
        tagGrid: ["flowering"],
        desktopList: [1],
        defaultDesktop: "list",
      });

      assert.strictEqual(
        resolveLayout({
          tagName: "flowering",
          categoryId: 1,
          isMobile: false,
          config: cfg,
        }),
        "grid"
      );
    });

    test("an unknown tag falls through to the category rules", function (assert) {
      const cfg = config({
        tagGrid: ["flowering"],
        desktopList: [1],
        inherit: true,
        desktopGrid: [2],
      });

      assert.strictEqual(
        resolveLayout({
          tagName: "other",
          categoryId: 1,
          isMobile: false,
          config: cfg,
        }),
        "list"
      );
      assert.strictEqual(
        resolveLayout({
          tagName: "other",
          categoryId: 3,
          ancestorIds: [2],
          isMobile: false,
          config: cfg,
        }),
        "grid"
      );
    });

    test("an unknown tag without a category falls through to the default", function (assert) {
      const cfg = config({ tagList: ["a"], defaultDesktop: "grid" });

      assert.strictEqual(
        resolveLayout({ tagName: "b", isMobile: false, config: cfg }),
        "grid"
      );
      assert.strictEqual(
        resolveLayout({ tagName: "b", isMobile: true, config: cfg }),
        null
      );
    });

    test("a tag in a listed tag group gets the layout of the group", function (assert) {
      const cfg = config({ groupGrid: ["stages"], groupList: ["topics"] });

      assert.strictEqual(
        resolveLayout({
          tagName: "Harvest",
          tagGroups: groups,
          isMobile: false,
          config: cfg,
        }),
        "grid"
      );
      assert.strictEqual(
        resolveLayout({
          tagName: "tips",
          tagGroups: groups,
          isMobile: true,
          config: cfg,
        }),
        "list"
      );
    });

    test("the group name is compared case-insensitively", function (assert) {
      const cfg = config({ groupList: ["Stages"] });

      assert.strictEqual(
        resolveLayout({
          tagName: "harvest",
          tagGroups: groups,
          isMobile: false,
          config: cfg,
        }),
        "list"
      );
    });

    test("list wins when a tag is in a list group and a grid group", function (assert) {
      const cfg = config({ groupList: ["topics"], groupGrid: ["stages"] });
      const both = new Map([
        ["stages", new Set(["x"])],
        ["topics", new Set(["x"])],
      ]);

      assert.strictEqual(
        resolveLayout({
          tagName: "x",
          tagGroups: both,
          isMobile: false,
          config: cfg,
        }),
        "list"
      );
    });

    test("a group beats the category", function (assert) {
      const cfg = config({ groupGrid: ["stages"], desktopList: [1] });

      assert.strictEqual(
        resolveLayout({
          tagName: "harvest",
          tagGroups: groups,
          categoryId: 1,
          isMobile: false,
          config: cfg,
        }),
        "grid"
      );
    });

    test("a tag beats a tag group", function (assert) {
      const cfg = config({ tagList: ["harvest"], groupGrid: ["stages"] });

      assert.strictEqual(
        resolveLayout({
          tagName: "harvest",
          tagGroups: groups,
          isMobile: false,
          config: cfg,
        }),
        "list"
      );
    });

    test("groups that are not loaded do not match", function (assert) {
      const cfg = config({
        groupGrid: ["stages"],
        desktopList: [1],
        defaultDesktop: "none",
      });

      assert.strictEqual(
        resolveLayout({
          tagName: "harvest",
          tagGroups: new Map(),
          categoryId: 1,
          isMobile: false,
          config: cfg,
        }),
        "list"
      );
      assert.strictEqual(
        resolveLayout({
          tagName: "harvest",
          categoryId: 1,
          isMobile: false,
          config: cfg,
        }),
        "list"
      );
    });

    test("a tag outside the listed groups falls through", function (assert) {
      const cfg = config({ groupGrid: ["topics"], defaultDesktop: "list" });

      assert.strictEqual(
        resolveLayout({
          tagName: "harvest",
          tagGroups: groups,
          isMobile: false,
          config: cfg,
        }),
        "list"
      );
    });

    test("disabled cards beat every tag rule", function (assert) {
      const cfg = config({
        enabled: false,
        tagList: ["a"],
        groupGrid: ["stages"],
      });

      assert.strictEqual(
        resolveLayout({ tagName: "a", isMobile: false, config: cfg }),
        null
      );
      assert.strictEqual(
        resolveLayout({
          tagName: "harvest",
          tagGroups: groups,
          isMobile: false,
          config: cfg,
        }),
        null
      );
    });

    test("without a tag the tag rules are not used", function (assert) {
      const cfg = config({ tagList: ["a"], desktopGrid: [1] });

      assert.strictEqual(
        resolveLayout({ categoryId: 1, isMobile: false, config: cfg }),
        "grid"
      );
    });
  });

  module("indexTagGroups", function () {
    test("keeps the wanted groups, lowercased, with their tag names", function (assert) {
      const index = indexTagGroups(
        [
          { name: "Stages", tags: [{ id: 1, name: "Flowering" }, "Harvest"] },
          { name: "Unwanted", tags: [{ id: 2, name: "x" }] },
        ],
        ["stages", "missing"]
      );

      assert.deepEqual([...index.keys()], ["stages"]);
      assert.true(index.get("stages").has("flowering"));
      assert.true(index.get("stages").has("harvest"));
      assert.false(index.has("missing"));
    });

    test("tolerates no results and groups without tags", function (assert) {
      assert.strictEqual(indexTagGroups(null, ["a"]).size, 0);
      assert.strictEqual(
        indexTagGroups([{ name: "A" }], ["a"]).get("a").size,
        0
      );
    });
  });
});
