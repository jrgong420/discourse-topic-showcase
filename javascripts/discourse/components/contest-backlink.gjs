import { themePrefix } from "virtual:theme";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

/**
 * A small line on a contest entry that links back to the announcement.
 *
 * @param {Object} @context The contest context of an entry.
 */
const ContestBacklink = <template>
  <p class="contest-backlink">
    {{dIcon "certificate" class="contest-backlink__icon"}}
    <span class="contest-backlink__text">
      {{i18n (themePrefix "contest.backlink")}}
      <a
        class="contest-backlink__link"
        href={{@context.announcement.url}}
      >{{@context.announcement.title}}</a>
    </span>
  </p>
</template>;

export default ContestBacklink;
