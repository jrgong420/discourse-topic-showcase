import { module, test } from "qunit";
import { createPromiseCache } from "../../../../javascripts/discourse/lib/promise-cache.js";

// Lets the cache's cleanup run.
const settle = () => new Promise((resolve) => setTimeout(resolve, 0));

module("Unit | Lib | promise-cache", function () {
  test("loads once per key, also for concurrent requests", async function (assert) {
    const cache = createPromiseCache();
    let loads = 0;
    const load = async () => ++loads;

    const [a, b] = await Promise.all([
      cache.get("k", load),
      cache.get("k", load),
    ]);
    const c = await cache.get("k", load);

    assert.strictEqual(loads, 1);
    assert.deepEqual([a, b, c], [1, 1, 1]);
  });

  test("keys are independent", async function (assert) {
    const cache = createPromiseCache();

    assert.strictEqual(await cache.get("a", async () => "A"), "A");
    assert.strictEqual(await cache.get("b", async () => "B"), "B");
  });

  test("a failed load is not cached", async function (assert) {
    const cache = createPromiseCache();

    await assert.rejects(
      cache.get("k", async () => {
        throw new Error("network");
      })
    );
    await settle();

    assert.strictEqual(await cache.get("k", async () => "ok"), "ok");
  });

  test("a missing response counts as a failure and is not cached", async function (assert) {
    const cache = createPromiseCache();

    await assert.rejects(cache.get("k", async () => undefined));
    await assert.rejects(cache.get("k", async () => null));
    await settle();

    assert.strictEqual(await cache.get("k", async () => "ok"), "ok");
  });

  test("an empty result is a result", async function (assert) {
    const cache = createPromiseCache();
    let loads = 0;
    const load = async () => {
      loads++;
      return [];
    };

    await cache.get("k", load);
    await cache.get("k", load);

    assert.strictEqual(loads, 1);
  });
});
