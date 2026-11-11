import { module, test } from "qunit";
import {
  canFilterTags,
  filterQuery,
  parseTagList,
} from "../../../../javascripts/discourse/lib/tag-filter.js";

module("Unit | Lib | tag-filter", function () {
  test("parseTagList splits, trims and drops empty names", function (assert) {
    assert.deepEqual(parseTagList(" a | b ||c"), ["a", "b", "c"]);
    assert.deepEqual(parseTagList(""), []);
    assert.deepEqual(parseTagList(null), []);
    assert.deepEqual(parseTagList(undefined), []);
  });

  test("canFilterTags accepts names core's tag filter can match", function (assert) {
    assert.true(
      canFilterTags(["featured", "wettbewerb-2026", "ä.b_c", "2026"])
    );
    assert.true(canFilterTags([]));
  });

  test("canFilterTags rejects names with other characters", function (assert) {
    assert.false(canFilterTags(["ok", "a b"]));
    assert.false(canFilterTags(["a+b"]));
    assert.false(canFilterTags(["a,b"]));
    assert.false(canFilterTags([""]));
  });

  test("filterQuery joins the tags with + and maps the order", function (assert) {
    assert.strictEqual(
      filterQuery(["a", "b"], "latest"),
      "tag:a+b order:activity"
    );
    assert.strictEqual(filterQuery(["a"], "created"), "tag:a order:created");
  });

  test("filterQuery orders by activity for any other order", function (assert) {
    assert.strictEqual(filterQuery(["a"], "random"), "tag:a order:activity");
    assert.strictEqual(filterQuery(["a"], undefined), "tag:a order:activity");
  });
});
