customElements.define('rendered-html', class RenderedHtml extends HTMLElement {
  connectedCallback() {
    this.innerHTML = this.content;
  }
});