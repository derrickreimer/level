import "@webcomponents/custom-elements";

customElements.define(
  "rendered-html",
  class RenderedHtml extends HTMLElement {
    constructor() {
      super();
      this._content = "";
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
