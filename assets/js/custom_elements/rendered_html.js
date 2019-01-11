import "@webcomponents/custom-elements";

customElements.define(
  "rendered-html",
  class RenderedHtml extends HTMLElement {
    constructor() {
      super();
      this._content = "";
    }

    connectedCallback() {
      this.addEventListener("click", e => {
        let target = e.target;

        if (
          target.tagName == "A" &&
          target.origin == document.location.origin
        ) {
          e.preventDefault();
          e.stopPropagation();

          this.dispatchEvent(
            new CustomEvent("internalLinkClicked", {
              detail: { pathname: target.pathname }
            })
          );
        }
      });
    }

    set content(value) {
      if (this._content === value);
      this._content = value;
      this.innerHTML = value;
    }

    get content() {
      return this._content;
    }
  }
);
