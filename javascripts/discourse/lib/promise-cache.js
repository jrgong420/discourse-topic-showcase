/**
 * A cache of promises by key, so concurrent and repeated requests for the same
 * thing share one load. A load that rejects, or resolves to nothing (core's
 * ajax() resolves `undefined` when the session is logged off), is not kept:
 * the next request tries again.
 *
 * @returns {{get: (key: string, load: () => Promise<any>) => Promise<any>}}
 */
export function createPromiseCache() {
  const promises = new Map();

  return {
    get(key, load) {
      if (!promises.has(key)) {
        const promise = (async () => {
          const value = await load();

          if (value == null) {
            throw new Error(`No data for "${key}"`);
          }

          return value;
        })();

        promises.set(key, promise);
        promise.catch(() => {
          if (promises.get(key) === promise) {
            promises.delete(key);
          }
        });
      }

      return promises.get(key);
    },
  };
}
