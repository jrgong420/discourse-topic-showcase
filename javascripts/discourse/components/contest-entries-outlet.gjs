import Component from "@glimmer/component";
import { eq } from "discourse/truth-helpers";
import ContestContext from "./contest-context.gjs";
import ContestEntries from "./contest-entries.gjs";

/**
 * Connector for `post-article__after`, which core renders after every post of
 * the stream: the list of entries goes after the first post of a contest
 * announcement only. Every other post renders nothing, without loading
 * anything.
 */
export default class ContestEntriesOutlet extends Component {
  get topic() {
    const post = this.args.outletArgs?.post;

    return post?.post_number === 1 ? post.topic : null;
  }

  <template>
    {{#if this.topic}}
      <ContestContext @topic={{this.topic}} as |context|>
        {{#if (eq context.role "announcement")}}
          <ContestEntries @context={{context}} />
        {{/if}}
      </ContestContext>
    {{/if}}
  </template>
}
