import { module, test } from "qunit";
import {
  parseStatusBadges,
  safeColor,
  statusBadgeOf,
  tagsWithoutStatus,
} from "../../../../javascripts/discourse/lib/status-badge.js";

const BADGES = parseStatusBadges([
  { tag: "flowering", label: "Flowering", color: "#8a3fa0", icon: "seedling" },
  { tag: "Growth", label: "Growth", color: "#3a8f3a" },
  { tag: "finished", label: "Finished" },
]);

module("Unit | Lib | status-badge", function () {
  module("safeColor", function () {
    test("accepts hex colours", function (assert) {
      assert.strictEqual(safeColor("#3a8f3a"), "#3a8f3a");
      assert.strictEqual(safeColor("#FFF"), "#FFF");
      assert.strictEqual(safeColor("#3a8f3a80"), "#3a8f3a80");
      assert.strictEqual(safeColor("  #abcd  "), "#abcd");
    });

    test("accepts plain colour names", function (assert) {
      assert.strictEqual(safeColor("tomato"), "tomato");
      assert.strictEqual(safeColor("RebeccaPurple"), "RebeccaPurple");
    });

    test("rejects anything else", function (assert) {
      assert.strictEqual(safeColor(""), null);
      assert.strictEqual(safeColor(null), null);
      assert.strictEqual(safeColor(undefined), null);
      assert.strictEqual(safeColor(42), null);
      assert.strictEqual(safeColor("#12"), null);
      assert.strictEqual(safeColor("#12345"), null);
      assert.strictEqual(safeColor("#ggg"), null);
      assert.strictEqual(safeColor("3a8f3a"), null);
      assert.strictEqual(safeColor("red; background: url(x)"), null);
      assert.strictEqual(safeColor("rgb(0, 0, 0)"), null);
      assert.strictEqual(safeColor('red"onclick="x'), null);
      assert.strictEqual(safeColor("var(--danger)"), null);
    });
  });

  module("parseStatusBadges", function () {
    test("keeps the order and adds a lowercase key", function (assert) {
      assert.deepEqual(
        BADGES.map((badge) => [badge.tag, badge.key]),
        [
          ["flowering", "flowering"],
          ["Growth", "growth"],
          ["finished", "finished"],
        ]
      );
    });

    test("normalises colour and icon", function (assert) {
      const [flowering, , finished] = BADGES;

      assert.strictEqual(flowering.color, "#8a3fa0");
      assert.strictEqual(flowering.icon, "seedling");
      assert.strictEqual(finished.color, null);
      assert.strictEqual(finished.icon, null);
    });

    test("drops an unsafe colour but keeps the badge", function (assert) {
      const [badge] = parseStatusBadges([
        { tag: "a", label: "A", color: "red; x: y" },
      ]);

      assert.strictEqual(badge.color, null);
      assert.strictEqual(badge.label, "A");
    });

    test("drops objects without a tag or a label", function (assert) {
      const badges = parseStatusBadges([
        { tag: "", label: "No tag" },
        { tag: "no-label", label: "  " },
        { label: "Missing tag" },
        null,
        { tag: " ok ", label: " Ok " },
      ]);

      assert.deepEqual(
        badges.map((badge) => [badge.tag, badge.label]),
        [["ok", "Ok"]]
      );
    });

    test("anything but an array gives no badges", function (assert) {
      assert.deepEqual(parseStatusBadges(undefined), []);
      assert.deepEqual(parseStatusBadges(null), []);
      assert.deepEqual(parseStatusBadges(""), []);
      assert.deepEqual(parseStatusBadges({}), []);
    });
  });

  module("statusBadgeOf", function () {
    test("finds the badge of a tag the topic carries", function (assert) {
      assert.strictEqual(
        statusBadgeOf(["news", "finished"], BADGES).label,
        "Finished"
      );
    });

    test("matches case-insensitively and accepts tag objects", function (assert) {
      assert.strictEqual(
        statusBadgeOf([{ name: "GROWTH" }], BADGES).label,
        "Growth"
      );
      assert.strictEqual(
        statusBadgeOf(
          ["flowering"],
          parseStatusBadges([{ tag: "FLOWERING", label: "F" }])
        ).label,
        "F"
      );
    });

    test("the first badge in setting order wins, not the first tag", function (assert) {
      assert.strictEqual(
        statusBadgeOf(["finished", "growth", "flowering"], BADGES).label,
        "Flowering"
      );
    });

    test("null without a matching tag, tags or badges", function (assert) {
      assert.strictEqual(statusBadgeOf(["news"], BADGES), null);
      assert.strictEqual(statusBadgeOf([], BADGES), null);
      assert.strictEqual(statusBadgeOf(null, BADGES), null);
      assert.strictEqual(statusBadgeOf(["growth"], []), null);
    });
  });

  module("tagsWithoutStatus", function () {
    test("removes the status tag and keeps the others in order", function (assert) {
      const badge = statusBadgeOf(["news", "growth", "tips"], BADGES);

      assert.deepEqual(tagsWithoutStatus(["news", "growth", "tips"], badge), [
        "news",
        "tips",
      ]);
    });

    test("compares case-insensitively and keeps tag objects as they are", function (assert) {
      const badge = statusBadgeOf([{ name: "Growth" }], BADGES);
      const news = { id: 1, name: "news" };

      assert.deepEqual(
        tagsWithoutStatus([news, { id: 2, name: "Growth" }], badge),
        [news]
      );
    });

    test("without a badge the tags stay as they are", function (assert) {
      assert.deepEqual(tagsWithoutStatus(["a", "b"], null), ["a", "b"]);
      assert.deepEqual(tagsWithoutStatus(undefined, null), []);
    });

    test("a status tag that was the only tag leaves nothing", function (assert) {
      const badge = statusBadgeOf(["growth"], BADGES);

      assert.deepEqual(tagsWithoutStatus(["growth"], badge), []);
    });
  });
});
