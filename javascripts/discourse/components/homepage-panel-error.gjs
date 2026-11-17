import { themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

// The failed-load message and retry button of a panel body.
const HomepagePanelError = <template>
  <div class="homepage-panel-error">
    <p class="homepage-panel-error__message" role="alert">
      {{i18n (themePrefix "homepage.load_error")}}
    </p>
    <DButton
      class="btn-small homepage-panel-error__button"
      @action={{@onRetry}}
      @label={{themePrefix "homepage.retry"}}
    />
  </div>
</template>;

export default HomepagePanelError;
