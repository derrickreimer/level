import "@webcomponents/custom-elements";
import autosize from "autosize";

customElements.define(
  "post-composer",
  class PostComposer extends HTMLElement {
    connectedCallback() {
      this.setupAutosize();
      this.setupDragDrop();
    };

    disconnectedCallback() {
      this.teardownAutosize();
    }

    setupAutosize() {
      let textarea = this.querySelector("textarea");
      if (textarea) { autosize(textarea) };
    }

    teardownAutosize() {
      let textarea = this.querySelector("textarea");
      if (textarea) { autosize.destroy(textarea) };
    }

    setupDragDrop() {
      // We need to prevent the default dragover event to make this a valid drop zone:
      // "Calling the preventDefault() method during both a dragenter and dragover event will indicate that a drop is allowed at that location."
      // https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API/Drag_operations#droptargets#droptargets
      this.addEventListener('dragover', (event) => {
        event.preventDefault();
      })

      this.addEventListener('dragenter', (event) => {
        event.preventDefault();
        console.log('enter', event);
      });

      this.addEventListener('dragleave', (event) => {
        event.preventDefault();
        console.log('leave', event);
      });

      this.addEventListener('drop', (event) => {
        event.preventDefault();
        console.log('drop', event);

        let dt = event.dataTransfer;
        let files = dt.files;
        console.log(files);
      });
    }
  }
);
