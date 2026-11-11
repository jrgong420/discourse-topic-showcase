import { eq } from "discourse/truth-helpers";
import ContestBacklink from "./contest-backlink.gjs";
import ContestContext from "./contest-context.gjs";
import ContestStrip from "./contest-strip.gjs";

/**
 * Connector for the outlet above a topic's posts: the strip on a contest
 * announcement, the link back to the announcement on a contest entry.
 */
const ContestTopicOutlet = <template>
  <ContestContext @topic={{@outletArgs.model}} as |context|>
    {{#if (eq context.role "announcement")}}
      <ContestStrip @context={{context}} @topic={{@outletArgs.model}} />
    {{else}}
      <ContestBacklink @context={{context}} />
    {{/if}}
  </ContestContext>
</template>;

export default ContestTopicOutlet;
