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

        if (target.tagName == "A") {
          e.preventDefault();
          e.stopPropagation();

          if (target.origin == document.location.origin) {
            this.dispatchEvent(
              new CustomEvent("internalLinkClicked", {
                detail: { pathname: target.pathname }
              })
            );
          } else {
            window.open(target.href, "_blank");
          }
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
