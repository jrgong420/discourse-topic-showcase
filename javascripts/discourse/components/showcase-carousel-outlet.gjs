import Component from "@glimmer/component";
import { service } from "@ember/service";
import { defaultHomepage } from "discourse/lib/utilities";
import ShowcaseCarousel from "./showcase-carousel.gjs";

/**
 * Connector for `discovery-list-container-top`: renders the carousel on the
 * forum homepage only.
 *
 * Core renders that outlet above every discovery list. The homepage is the
 * discovery route named after the site's (or the user's) default homepage
 * (`defaultHomepage()`, e.g. "latest" for `discovery.latest`), without a
 * category or tag. The carousel sits behind the check, so it is created
 * (and fetches) when the homepage is entered and torn down when it is left,
 * even if the discovery layout itself stays mounted between list routes.
 */
export default class ShowcaseCarouselOutlet extends Component {
  @service router;

  get isHomepage() {
    const { category, tag } = this.args.outletArgs ?? {};

    return (
      !category &&
      !tag &&
      this.router.currentRouteName === `discovery.${defaultHomepage()}`
    );
  }

  <template>
    {{#if this.isHomepage}}
      <ShowcaseCarousel />
    {{/if}}
  </template>
}
