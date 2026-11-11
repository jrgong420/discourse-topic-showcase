import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { loadContestContext } from "../lib/contest-data.js";

// Loads the contest data of the topic when it is created and yields it. Shows
// nothing while loading, on errors and for topics outside a contest.
class ContestLoader extends Component {
  @service store;

  @tracked context = null;

  constructor() {
    super(...arguments);
    this.load();
  }

  async load() {
    const context = await loadContestContext(this.store, this.args.topic);

    // The topic view may be gone by now (client-side navigation).
    if (this.isDestroying) {
      return;
    }

    this.context = context;
  }

  <template>
    {{#if this.context}}
      {{yield this.context}}
    {{/if}}
  </template>
}

/**
 * Yields the contest context of a topic (see `loadContestContext`). The
 * loader lives per topic: when the outlet receives another topic (or the same
 * topic with other tags) client-side, the old loader and everything inside it
 * is torn down and a new one starts, so no stale content stays and a late
 * response never lands in the wrong view.
 *
 * @param {Topic} @topic
 */
export default class ContestContext extends Component {
  get instances() {
    const topic = this.args.topic;
    if (!topic?.id) {
      return [];
    }

    const tags = (topic.tags ?? []).map((tag) => tag?.name ?? tag);
    return [{ key: `${topic.id}:${tags.join("|")}`, topic }];
  }

  <template>
    {{#each this.instances key="key" as |instance|}}
      <ContestLoader @topic={{instance.topic}} as |context|>
        {{yield context}}
      </ContestLoader>
    {{/each}}
  </template>
}
