import "@webcomponents/custom-elements";
import autosize from "autosize";

const isOutside = (rect, clientX, clientY) => {
  return (
    clientX >= rect.right ||
    clientX < rect.left ||
    clientY >= rect.bottom ||
    clientY < rect.top
  );
};

const generateRandomToken = () => {
  return [...Array(32)].map(_ => (~~(Math.random() * 36)).toString(36)).join('');
}

customElements.define(
  "post-composer",
  class PostComposer extends HTMLElement {
    /**
     * Callback function called when the element is connected to the DOM.
     */
    connectedCallback() {
      this.setupAutosize();
      this.setupDragDrop();
      this._dragging_over = false;
      this.files = [];
    }

    /**
     * Callback function called when the element is disconnected from the DOM.
     */
    disconnectedCallback() {
      this.teardownAutosize();
    }

    /**
     * Initialize the autosize functionality on the textarea.
     */
    setupAutosize() {
      let textarea = this.querySelector("textarea");
      if (textarea) {
        autosize(textarea);
      }
    }

    /**
     * Teardown the autosize binding when the node is disconnected.
     */
    teardownAutosize() {
      let textarea = this.querySelector("textarea");
      if (textarea) {
        autosize.destroy(textarea);
      }
    }

    /**
     * Set up listeners for drag events.
     */
    setupDragDrop() {
      // We need to prevent the default dragover event to make this a valid drop zone:
      // "Calling the preventDefault() method during both a dragenter and dragover
      // event will indicate that a drop is allowed at that location."
      // https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API/Drag_operations#droptargets#droptargets
      this.addEventListener("dragover", e => {
        e.stopPropagation();
        e.preventDefault();
      });

      this.addEventListener("dragenter", e => {
        e.stopPropagation();
        e.preventDefault();

        if (!this._dragging_over) {
          this._dragging_over = true;
          console.log("enter", e);
          this.classList.add("dragging-over");
        }
      });

      this.addEventListener("dragleave", e => {
        e.stopPropagation();
        e.preventDefault();

        const rect = this.getBoundingClientRect();

        if (isOutside(rect, e.clientX, e.clientY)) {
          this.stoppedDraggingOver();
          console.log("leave", e);
        }
      });

      this.addEventListener("dragenter", e => {
        e.stopPropagation();
        e.preventDefault();

        if (!this._dragging_over) {
          this.startedDraggingOver();
          console.log("enter", e);
        }
      });

      this.addEventListener("drop", e => {
        e.stopPropagation();
        e.preventDefault();

        this.stoppedDraggingOver();

        console.log("drop", e);

        let dt = e.dataTransfer;
        let files = dt.files;

        [].forEach.call(files, file => {
          console.log(file);
          this.handleFileDropped(file);
        });
      });

      this.addEventListener("dragend", e => {
        this.stoppedDraggingOver();
        console.log("dragend", e);
      });

      this.addEventListener("dragexit", e => {
        this.stoppedDraggingOver();
        console.log("dragexit", e);
      });
    }

    /**
     * Updates state to reflect that the user is dragging a file over the composer.
     */
    startedDraggingOver() {
      this._dragging_over = true;
      this.classList.add("dragging-over");
    }

    /**
     * Updates state to reflect that the user is not dragging over the composer.
     */
    stoppedDraggingOver() {
      this._dragging_over = false;
      this.classList.remove("dragging-over");
    }

    /**
     * Handles a file after it's been dropped on the composer.
     */
    handleFileDropped(file) {
      const clientId = generateRandomToken();

      const metadata = {
        clientId: clientId,
        state: "STAGED",
        name: file.name,
        type: file.type,
        size: file.size,
        contents: null
      }

      this.dispatchEvent(new CustomEvent("fileDropped", { detail: metadata }));
      this.uploadFile(clientId, file);
    }

    /**
     * Uploads the given file to the server.
     */
    uploadFile(clientId, file) {
      fetch("/api/tokens", { method: "POST" })
        .then(tokenResponse => {
          return tokenResponse.json().then(tokenData => {
            let uploadData = new FormData();
            uploadData.append('upload[client_id]', clientId);
            uploadData.append('upload[data]', file);

            return fetch("/api/uploads", {
              method: "POST",
              headers: {
                'x-api-token': tokenData.token
              },
              body: uploadData
            });
          });
        });
    }
  }
);
