import { module, test } from "qunit";
import {
  announcementOf,
  contestTagOf,
  entriesOf,
  participantsOf,
  resolveAnnouncementTags,
  roleOf,
} from "../../../../javascripts/discourse/lib/contest.js";

const CONTEST_TAGS = ["contest-2026", "contest-2025"];
const ANNOUNCEMENT_TAGS = ["featured", "news"];

function topic(id, tags) {
  return { id, tags };
}

module("Unit | Lib | contest", function () {
  module("contestTagOf", function () {
    test("returns the first topic tag that is a contest tag", function (assert) {
      assert.strictEqual(
        contestTagOf(["a", "contest-2025", "contest-2026"], CONTEST_TAGS),
        "contest-2025"
      );
    });

    test("matches case-insensitively and keeps the topic's spelling", function (assert) {
      assert.strictEqual(
        contestTagOf(["Contest-2026"], CONTEST_TAGS),
        "Contest-2026"
      );
      assert.strictEqual(
        contestTagOf(["contest-2026"], ["CONTEST-2026"]),
        "contest-2026"
      );
    });

    test("accepts tag objects with a name", function (assert) {
      assert.strictEqual(
        contestTagOf([{ name: "x" }, { name: "contest-2026" }], CONTEST_TAGS),
        "contest-2026"
      );
    });

    test("returns null without a contest tag", function (assert) {
      assert.strictEqual(contestTagOf(["a", "b"], CONTEST_TAGS), null);
      assert.strictEqual(contestTagOf([], CONTEST_TAGS), null);
      assert.strictEqual(contestTagOf(null, CONTEST_TAGS), null);
      assert.strictEqual(contestTagOf(["contest-2026"], []), null);
    });
  });

  module("roleOf", function () {
    test("announcement: contest tag and every announcement tag", function (assert) {
      assert.strictEqual(
        roleOf(
          ["contest-2026", "news", "featured", "other"],
          CONTEST_TAGS,
          ANNOUNCEMENT_TAGS
        ),
        "announcement"
      );
    });

    test("entry: contest tag without every announcement tag", function (assert) {
      assert.strictEqual(
        roleOf(["contest-2026"], CONTEST_TAGS, ANNOUNCEMENT_TAGS),
        "entry"
      );
      assert.strictEqual(
        roleOf(["contest-2026", "featured"], CONTEST_TAGS, ANNOUNCEMENT_TAGS),
        "entry"
      );
    });

    test("null without a contest tag, even with the announcement tags", function (assert) {
      assert.strictEqual(
        roleOf(["featured", "news"], CONTEST_TAGS, ANNOUNCEMENT_TAGS),
        null
      );
    });

    test("null when there are no announcement tags", function (assert) {
      assert.strictEqual(roleOf(["contest-2026"], CONTEST_TAGS, []), null);
    });

    test("is case-insensitive and accepts tag objects", function (assert) {
      assert.strictEqual(
        roleOf(
          [{ name: "CONTEST-2026" }, { name: "Featured" }, { name: "NEWS" }],
          CONTEST_TAGS,
          ANNOUNCEMENT_TAGS
        ),
        "announcement"
      );
      assert.strictEqual(
        roleOf([{ name: "CONTEST-2026" }], CONTEST_TAGS, ANNOUNCEMENT_TAGS),
        "entry"
      );
    });

    test("a topic without tags has no role", function (assert) {
      assert.strictEqual(
        roleOf(undefined, CONTEST_TAGS, ANNOUNCEMENT_TAGS),
        null
      );
    });
  });

  module("resolveAnnouncementTags", function () {
    test("uses the configured tags, else the fallback", function (assert) {
      assert.deepEqual(resolveAnnouncementTags(["a"], ["b"]), ["a"]);
      assert.deepEqual(resolveAnnouncementTags([], ["b"]), ["b"]);
      assert.deepEqual(resolveAnnouncementTags([], []), []);
    });
  });

  module("entriesOf", function () {
    test("drops announcements and keeps the order", function (assert) {
      const topics = [
        topic(1, ["contest-2026", "featured", "news"]),
        topic(2, ["contest-2026"]),
        topic(3, ["contest-2026", "featured"]),
        topic(4, [
          { name: "contest-2026" },
          { name: "NEWS" },
          { name: "featured" },
        ]),
      ];

      assert.deepEqual(
        entriesOf(topics, ANNOUNCEMENT_TAGS).map((t) => t.id),
        [2, 3]
      );
    });
  });

  module("announcementOf", function () {
    test("returns the first topic with the contest and every announcement tag", function (assert) {
      const topics = [
        topic(1, ["contest-2026", "featured"]),
        topic(2, ["contest-2026", "featured", "news"]),
        topic(3, ["contest-2026", "featured", "news"]),
      ];

      assert.strictEqual(
        announcementOf(topics, "contest-2026", ANNOUNCEMENT_TAGS).id,
        2
      );
    });

    test("returns null without a match", function (assert) {
      assert.strictEqual(
        announcementOf(
          [topic(1, ["contest-2026"])],
          "contest-2026",
          ANNOUNCEMENT_TAGS
        ),
        null
      );
      assert.strictEqual(announcementOf([], "contest-2026", ["x"]), null);
    });
  });

  module("participantsOf", function () {
    function entry(id, creator) {
      return { id, creator };
    }

    const ann = { id: 1, username: "ann" };
    const bob = { id: 2, username: "bob" };
    const cy = { id: 3, username: "cy" };

    test("counts distinct creators, in entry order", function (assert) {
      const result = participantsOf(
        [entry(10, ann), entry(11, bob), entry(12, ann), entry(13, cy)],
        8
      );

      assert.strictEqual(result.count, 3);
      assert.deepEqual(
        result.avatars.map((user) => user.username),
        ["ann", "bob", "cy"]
      );
      assert.strictEqual(result.extra, 0);
    });

    test("an entry without a creator is a participant of its own", function (assert) {
      const result = participantsOf(
        [entry(10, ann), entry(11, undefined), entry(12, null), entry(13, ann)],
        8
      );

      assert.strictEqual(result.count, 3);
      assert.deepEqual(
        result.avatars.map((user) => user.username),
        ["ann"]
      );
      assert.strictEqual(result.extra, 2);
    });

    test("shows at most maxAvatars and reports the rest as extra", function (assert) {
      const result = participantsOf(
        [entry(10, ann), entry(11, bob), entry(12, cy)],
        2
      );

      assert.strictEqual(result.count, 3);
      assert.deepEqual(
        result.avatars.map((user) => user.username),
        ["ann", "bob"]
      );
      assert.strictEqual(result.extra, 1);
    });

    test("0 avatars shows none and no extra, but still counts", function (assert) {
      const result = participantsOf([entry(10, ann), entry(11, bob)], 0);

      assert.strictEqual(result.count, 2);
      assert.deepEqual(result.avatars, []);
      assert.strictEqual(result.extra, 0);
    });

    test("tells creators apart by username when they have no id", function (assert) {
      const result = participantsOf(
        [
          entry(10, { username: "Ann" }),
          entry(11, { username: "ann" }),
          entry(12, { username: "bob" }),
        ],
        8
      );

      assert.strictEqual(result.count, 2);
    });

    test("a creator with neither id nor username counts as unknown", function (assert) {
      const result = participantsOf([entry(10, {}), entry(11, {})], 8);

      assert.strictEqual(result.count, 2);
      assert.deepEqual(result.avatars, []);
      assert.strictEqual(result.extra, 0);
    });

    test("no entries, no participants", function (assert) {
      assert.deepEqual(participantsOf([], 5), {
        count: 0,
        avatars: [],
        extra: 0,
      });
      assert.deepEqual(participantsOf(undefined, 5), {
        count: 0,
        avatars: [],
        extra: 0,
      });
    });
  });
});
