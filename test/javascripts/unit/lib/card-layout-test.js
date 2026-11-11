import { module, test } from "qunit";
import {
  buildLayoutConfig,
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
    });

    assert.true(cfg.enabled);
    assert.strictEqual(cfg.defaultDesktop, "list");
    assert.strictEqual(cfg.defaultMobile, "none");
    assert.deepEqual(cfg.desktopList, [11, 7]);
    assert.deepEqual(cfg.desktopGrid, []);
    assert.deepEqual(cfg.mobileList, [6]);
    assert.deepEqual(cfg.mobileGrid, [3, 4]);
    assert.true(cfg.inherit);
  });
});
