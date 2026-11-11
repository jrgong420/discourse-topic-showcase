import { module, test } from "qunit";
import {
  carouselSubcategories,
  categoryColor,
  subcategoryListIncomplete,
} from "../../../../javascripts/discourse/lib/subcategory-carousel.js";

function child(id, parentId = 1) {
  return { id, parent_category_id: parentId };
}

function args(overrides = {}) {
  return {
    categoryId: 1,
    enabledIds: [1],
    minChildren: 2,
    listed: null,
    fallback: null,
    ...overrides,
  };
}

function ids(categories) {
  return categories.map((category) => category.id);
}

module("Unit | Lib | subcategory-carousel", function () {
  test("a category that is not enabled gets no carousel", function (assert) {
    const fallback = [child(10), child(11)];

    assert.deepEqual(
      carouselSubcategories(args({ enabledIds: [2], fallback })),
      []
    );
    assert.deepEqual(
      carouselSubcategories(args({ enabledIds: [], fallback })),
      []
    );
    assert.deepEqual(
      carouselSubcategories(args({ categoryId: undefined, fallback })),
      []
    );
  });

  test("core's list is preferred over the fallback and keeps its order", function (assert) {
    const listed = [child(12), child(10), child(11)];
    const fallback = [child(10), child(11), child(13)];

    assert.deepEqual(
      ids(carouselSubcategories(args({ listed, fallback }))),
      [12, 10, 11]
    );
  });

  test("the fallback is used when there is no core list", function (assert) {
    const fallback = [child(11), child(10)];

    assert.deepEqual(ids(carouselSubcategories(args({ fallback }))), [11, 10]);
    assert.deepEqual(
      ids(carouselSubcategories(args({ listed: undefined, fallback }))),
      [11, 10]
    );
  });

  test("missing sources count as empty", function (assert) {
    assert.deepEqual(carouselSubcategories(args()), []);
  });

  test("only direct children are kept", function (assert) {
    const listed = [child(10), child(20, 10), child(11), child(30, 2)];

    assert.deepEqual(ids(carouselSubcategories(args({ listed }))), [10, 11]);
  });

  test("fewer children than the minimum give no carousel", function (assert) {
    assert.deepEqual(
      carouselSubcategories(args({ fallback: [child(10)] })),
      []
    );
    assert.deepEqual(
      carouselSubcategories(args({ fallback: [child(10), child(20, 10)] })),
      []
    );
  });

  test("the minimum is never below two", function (assert) {
    const one = [child(10)];
    const two = [child(10), child(11)];

    assert.deepEqual(
      carouselSubcategories(args({ minChildren: 1, fallback: one })),
      []
    );
    assert.deepEqual(
      ids(carouselSubcategories(args({ minChildren: 1, fallback: two }))),
      [10, 11]
    );
    assert.deepEqual(
      ids(carouselSubcategories(args({ minChildren: "abc", fallback: two }))),
      [10, 11]
    );
  });

  test("a minimum above the number of children gives no carousel", function (assert) {
    const two = [child(10), child(11)];

    assert.deepEqual(
      carouselSubcategories(args({ minChildren: 3, fallback: two })),
      []
    );
    assert.deepEqual(
      ids(
        carouselSubcategories(
          args({ minChildren: 3, fallback: [...two, child(12)] })
        )
      ),
      [10, 11, 12]
    );
  });

  test("categoryColor accepts 3 and 6 digit hex colours", function (assert) {
    assert.strictEqual(categoryColor("0088cc"), "#0088cc");
    assert.strictEqual(categoryColor("ABCDEF"), "#ABCDEF");
    assert.strictEqual(categoryColor("abc"), "#abc");
  });

  test("categoryColor rejects everything else", function (assert) {
    for (const value of [
      "red",
      "12345",
      "#abc",
      "abc;}",
      "",
      "0088ccc",
      undefined,
      null,
      123456,
    ]) {
      assert.strictEqual(categoryColor(value), null, String(value));
    }
  });

  test("an incomplete core list keeps core's list", function (assert) {
    assert.deepEqual(
      carouselSubcategories(
        args({ listed: [child(2), child(3)], listIncomplete: true })
      ),
      []
    );
  });

  test("subcategoryListIncomplete only on paginated sites with a full page", function (assert) {
    const base = { paginated: true, loaded: 20, fetchedLastPage: false };

    assert.true(subcategoryListIncomplete(base));
    assert.false(subcategoryListIncomplete({ ...base, paginated: false }));
    assert.false(subcategoryListIncomplete({ ...base, loaded: 19 }));
    assert.false(subcategoryListIncomplete({ ...base, fetchedLastPage: true }));
  });
});
