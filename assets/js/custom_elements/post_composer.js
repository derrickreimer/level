import "@webcomponents/custom-elements";
import autosize from "autosize";

const isOutside = (rect, clientX, clientY) => {
  return clientX >= rect.right ||
    clientX < rect.left ||
    clientY >= rect.bottom ||
    clientY < rect.top;
}

customElements.define(
  "post-composer",
  class PostComposer extends HTMLElement {
    connectedCallback() {
      this.setupAutosize();
      this.setupDragDrop();
      this._dragging_over = false;
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
      // "Calling the preventDefault() method during both a dragenter and dragover 
      // event will indicate that a drop is allowed at that location."
      // https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API/Drag_operations#droptargets#droptargets
      this.addEventListener('dragover', (e) => {
        e.stopPropagation();
        e.preventDefault();
      });

      this.addEventListener('dragenter', (e) => {
        e.stopPropagation();
        e.preventDefault();

        if (!this._dragging_over) {
          this._dragging_over = true;
          console.log('enter', e);
          this.classList.add('dragging-over');
        }
      });

      this.addEventListener('dragleave', (e) => {
        e.stopPropagation();
        e.preventDefault();

        const rect = this.getBoundingClientRect();

        if (isOutside(rect, e.clientX, e.clientY)) {
          this.stoppedDraggingOver();
          console.log('leave', e);
        }
      });

      this.addEventListener('dragenter', (e) => {
        e.stopPropagation();
        e.preventDefault();

        if (!this._dragging_over) {
          this.startedDraggingOver();
          console.log('enter', e);
        }
      });

      this.addEventListener('drop', (e) => {
        e.stopPropagation();
        e.preventDefault();

        this.stoppedDraggingOver();

        console.log('drop', e);

        let dt = e.dataTransfer;
        let files = dt.files;
        console.log(files);
      });

      this.addEventListener('dragend', (e) => {
        this.stoppedDraggingOver();
        console.log('dragend', e);
      });

      this.addEventListener('dragexit', (e) => {
        this.stoppedDraggingOver();
        console.log('dragexit', e);
      });
    }

    startedDraggingOver() {
      this._dragging_over = true;
      this.classList.add('dragging-over');
    }

    stoppedDraggingOver() {
      this._dragging_over = false;
      this.classList.remove('dragging-over');
    }
  }
);
