import DAsyncContent from "discourse/ui-kit/d-async-content";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import HomepagePanelError from "./homepage-panel-error.gjs";
import HomepagePanelSkeleton from "./homepage-panel-skeleton.gjs";

// Chrome shared by the homepage panels: header, body, footer. The header and
// footer render from args and stay put while data loads; only the body is
// inside the data boundary, where a skeleton keeps the panel's height.
//
// @title, @icon        header
// @asyncData, @context passed to DAsyncContent; @skeleton shapes the placeholder
// @onRetry             a failed load shows a message and a retry button
// <:content as |data|> body; <:footer>, usually a .homepage-panel__link
// A load that resolves to null renders no body; the block decides whether the
// whole panel goes away (see `hidden` in the blocks).
const HomepagePanel = <template>
  <section class="homepage-panel" ...attributes>
    {{#if @title}}
      <header class="homepage-panel__header">
        {{#if @icon}}
          <span class="homepage-panel__icon">{{dIcon @icon}}</span>
        {{/if}}
        <h2 class="homepage-panel__title">{{@title}}</h2>
      </header>
    {{/if}}

    <div class="homepage-panel__body">
      {{#if @asyncData}}
        <DAsyncContent
          @asyncData={{@asyncData}}
          @context={{@context}}
          @retainWhileReloading={{true}}
        >
          <:loading>
            <div aria-busy="true" class="homepage-panel__loading">
              <HomepagePanelSkeleton @shape={{@skeleton}} />
            </div>
          </:loading>
          <:content as |data|>
            {{yield data to="content"}}
          </:content>
          <:error as |error InlineError|>
            {{#if @onRetry}}
              <HomepagePanelError @onRetry={{@onRetry}} />
            {{else}}
              <InlineError />
            {{/if}}
          </:error>
        </DAsyncContent>
      {{else}}
        {{yield null to="content"}}
      {{/if}}
    </div>

    {{#if (has-block "footer")}}
      <footer class="homepage-panel__footer">
        {{yield to="footer"}}
      </footer>
    {{/if}}
  </section>
</template>;

export default HomepagePanel;
