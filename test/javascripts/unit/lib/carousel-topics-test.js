import { module, test } from "qunit";
import {
  countNewSince,
  filterAndOrderTopics,
} from "../../../../javascripts/discourse/lib/carousel-topics.js";

const NOW = Date.parse("2026-06-15T12:00:00Z");

function topic(id, fields = {}) {
  return {
    id,
    created_at: "2026-01-01T00:00:00Z",
    bumped_at: "2026-01-01T00:00:00Z",
    ...fields,
  };
}

function ids(topics) {
  return topics.map((t) => t.id);
}

function run(topics, overrides = {}) {
  return filterAndOrderTopics(topics, {
    order: "latest",
    maxItems: 20,
    displayExpired: false,
    displayUpcoming: true,
    now: NOW,
    random: () => 0,
    ...overrides,
  });
}

module("Unit | Lib | carousel-topics | filterAndOrderTopics", function () {
  test("latest orders by bumped_at, newest first", function (assert) {
    const topics = [
      topic(1, { bumped_at: "2026-03-01T00:00:00Z" }),
      topic(2, { bumped_at: "2026-05-01T00:00:00Z" }),
      topic(3, { bumped_at: "2026-04-01T00:00:00Z" }),
    ];

    assert.deepEqual(ids(run(topics)), [2, 3, 1]);
  });

  test("created orders by created_at, newest first", function (assert) {
    const topics = [
      topic(1, { created_at: "2026-02-01T00:00:00Z" }),
      topic(2, { created_at: "2026-04-01T00:00:00Z" }),
      topic(3, { created_at: "2026-03-01T00:00:00Z" }),
    ];

    assert.deepEqual(ids(run(topics, { order: "created" })), [2, 3, 1]);
  });

  test("random shuffles with the injected random function", function (assert) {
    const topics = [topic(1), topic(2), topic(3), topic(4)];

    // random() === 0 always swaps with index 0: [1,2,3,4] -> [2,3,4,1]
    assert.deepEqual(ids(run(topics, { order: "random" })), [2, 3, 4, 1]);
    // random() just below 1 always picks the current index: order unchanged.
    assert.deepEqual(
      ids(run(topics, { order: "random", random: () => 0.999999 })),
      [1, 2, 3, 4]
    );
  });

  test("does not modify the input array", function (assert) {
    const topics = [
      topic(1, { bumped_at: "2026-01-01T00:00:00Z" }),
      topic(2, { bumped_at: "2026-02-01T00:00:00Z" }),
    ];

    run(topics);
    run(topics, { order: "random" });

    assert.deepEqual(ids(topics), [1, 2]);
  });

  test("cuts to maxItems after filtering and ordering", function (assert) {
    const topics = [
      topic(1, { bumped_at: "2026-01-01T00:00:00Z" }),
      topic(2, {
        bumped_at: "2026-06-01T00:00:00Z",
        event_ends_at: "2026-05-01T00:00:00Z",
      }),
      topic(3, { bumped_at: "2026-03-01T00:00:00Z" }),
      topic(4, { bumped_at: "2026-02-01T00:00:00Z" }),
    ];

    // Topic 2 is the most active but expired: it is dropped before the cut.
    assert.deepEqual(ids(run(topics, { maxItems: 2 })), [3, 4]);
  });

  test("topics without event dates are never filtered", function (assert) {
    const topics = [topic(1), topic(2)];

    assert.deepEqual(
      ids(run(topics, { displayExpired: false, displayUpcoming: false })),
      [1, 2]
    );
  });

  test("expired: the end, or without an end the start, is in the past", function (assert) {
    const topics = [
      topic(1, { event_ends_at: "2026-06-01T00:00:00Z" }),
      topic(2, { event_starts_at: "2026-06-01T00:00:00Z" }),
      topic(3, {
        event_starts_at: "2026-06-01T00:00:00Z",
        event_ends_at: "2026-06-01T10:00:00Z",
      }),
    ];

    assert.deepEqual(ids(run(topics, { displayExpired: false })), []);
    assert.deepEqual(
      ids(run(topics, { displayExpired: true })).sort(),
      [1, 2, 3]
    );
  });

  test("an event that is running now is neither expired nor upcoming", function (assert) {
    const topics = [
      topic(1, {
        event_starts_at: "2026-06-15T10:00:00Z",
        event_ends_at: "2026-06-15T14:00:00Z",
      }),
    ];

    assert.deepEqual(
      ids(run(topics, { displayExpired: false, displayUpcoming: false })),
      [1]
    );
  });

  test("upcoming: the start is in the future", function (assert) {
    const topics = [
      topic(1, {
        event_starts_at: "2026-07-01T00:00:00Z",
        event_ends_at: "2026-07-02T00:00:00Z",
      }),
      topic(2, { event_starts_at: "2026-07-01T00:00:00Z" }),
    ];

    assert.deepEqual(ids(run(topics, { displayUpcoming: false })), []);
    assert.deepEqual(
      ids(run(topics, { displayUpcoming: true })).sort(),
      [1, 2]
    );
  });

  test("expired and upcoming flags are independent", function (assert) {
    const topics = [
      topic(1, { event_ends_at: "2026-06-01T00:00:00Z" }),
      topic(2, { event_starts_at: "2026-07-01T00:00:00Z" }),
      topic(3),
    ];

    assert.deepEqual(
      ids(run(topics, { displayExpired: true, displayUpcoming: false })).sort(),
      [1, 3]
    );
    assert.deepEqual(
      ids(run(topics, { displayExpired: false, displayUpcoming: true })).sort(),
      [2, 3]
    );
  });

  test("unparsable event dates count as no event", function (assert) {
    const topics = [topic(1, { event_starts_at: "not a date" })];

    assert.deepEqual(
      ids(run(topics, { displayExpired: false, displayUpcoming: false })),
      [1]
    );
  });

  test("now accepts a Date", function (assert) {
    const topics = [topic(1, { event_ends_at: "2026-06-01T00:00:00Z" })];

    assert.deepEqual(ids(run(topics, { now: new Date(NOW) })), []);
  });
});

module("Unit | Lib | carousel-topics | countNewSince", function () {
  const topics = [
    // Created after seenAt.
    topic(1, {
      created_at: "2026-06-10T00:00:00Z",
      bumped_at: "2026-06-10T00:00:00Z",
    }),
    // Old topic, bumped after seenAt.
    topic(2, {
      created_at: "2026-01-01T00:00:00Z",
      bumped_at: "2026-06-11T00:00:00Z",
    }),
    // Nothing after seenAt.
    topic(3, {
      created_at: "2026-01-01T00:00:00Z",
      bumped_at: "2026-02-01T00:00:00Z",
    }),
  ];

  test("counts topics whose latest of created_at and bumped_at is later", function (assert) {
    assert.strictEqual(countNewSince(topics, "2026-06-01T00:00:00.000Z"), 2);
  });

  test("a topic exactly at seenAt is not new", function (assert) {
    assert.strictEqual(countNewSince(topics, "2026-06-11T00:00:00.000Z"), 0);
  });

  test("everything is new since the year 2000", function (assert) {
    assert.strictEqual(countNewSince(topics, "2000-01-01T00:00:00.000Z"), 3);
  });

  test("nothing is new without a usable seenAt", function (assert) {
    assert.strictEqual(countNewSince(topics, null), 0);
    assert.strictEqual(countNewSince(topics, undefined), 0);
    assert.strictEqual(countNewSince(topics, "garbage"), 0);
  });

  test("an empty list has nothing new", function (assert) {
    assert.strictEqual(countNewSince([], "2000-01-01T00:00:00.000Z"), 0);
  });

  test("a missing bumped_at falls back to created_at", function (assert) {
    assert.strictEqual(
      countNewSince(
        [{ id: 1, created_at: "2026-06-10T00:00:00Z" }],
        "2026-06-01T00:00:00Z"
      ),
      1
    );
  });
});
