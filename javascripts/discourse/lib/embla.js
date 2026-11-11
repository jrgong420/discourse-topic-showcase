import { settings } from "virtual:theme";
import loadScript from "discourse/lib/load-script";

// Embla Carousel 8.6.0 (latest stable `latest` dist-tag on npm at the time of
// writing), file `package/embla-carousel.umd.js` of
// https://registry.npmjs.org/embla-carousel/-/embla-carousel-8.6.0.tgz,
// vendored unmodified as assets/embla-carousel.umd.js and registered in
// about.json under `assets` as `embla_carousel`.
//
// Core serves uploaded .js assets from its JavaScript cache at
// `/theme-javascripts/<digest>.js`, exposed as
// `settings.theme_uploads_local.embla_carousel`. The plain upload URL
// (`settings.theme_uploads.embla_carousel`) is only a fallback: JS uploads
// are not necessarily served from the upload store.
//
// The UMD wrapper falls back to a `window.EmblaCarousel` global: core's loader
// does not set `define.amd`, and there is no CommonJS `module` in the browser.

/**
 * Loads Embla on first use (it is only needed once an expanded carousel is
 * about to render) and resolves to the `EmblaCarousel` factory. Concurrent and
 * repeated calls share one script load.
 */
export async function loadEmbla() {
  if (!window.EmblaCarousel) {
    const url =
      settings.theme_uploads_local?.embla_carousel ??
      settings.theme_uploads?.embla_carousel;

    if (!url) {
      throw new Error("The Embla Carousel asset is not available");
    }

    await loadScript(url);
  }

  return window.EmblaCarousel;
}
