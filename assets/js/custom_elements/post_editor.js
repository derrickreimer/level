import "@webcomponents/custom-elements";
import autosize from "autosize";
import { fetchApiToken } from "../token";
import Tribute from "tributejs";

const isOutside = (rect, clientX, clientY) => {
  return (
    clientX >= rect.right ||
    clientX < rect.left ||
    clientY >= rect.bottom ||
    clientY < rect.top
  );
};

const generateRandomToken = () => {
  return [...Array(32)]
    .map(_ => (~~(Math.random() * 36)).toString(36))
    .join("");
};

customElements.define(
  "post-editor",
  class PostEditor extends HTMLElement {
    /**
     * Callback function called when the element is connected to the DOM.
     */
    connectedCallback() {
      this.setupAutosize();
      this.setupDragDrop();
      this.setupMentions();
      this._dragging_over = false;
    }

    /**
     * Callback function called when the element is disconnected from the DOM.
     */
    disconnectedCallback() {
      this.teardownAutosize();
      this.teardownMentions();
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
     * Initializes Tribute @-mention completion.
     */
    setupMentions() {
      let textarea = this.querySelector("textarea");
      if (!textarea) return;

      this.tribute = new Tribute({
        values: [
          {key: "Derrick Reimer", value: "derrick"},
          {key: "Don Johnson", value: "xact"}
        ],
        lookup: (obj) => {
          return obj.key + " (@" + obj.value + ")";
        },
        menuContainer: this,
        positionMenu: false
      });

      this.tribute.attach(textarea);

      // Trigger a synthetic "input" event when tribute programmatically
      // updates the textarea value to prevent Elm from clobbering it.
      textarea.addEventListener("tribute-replaced", (e) => {
        textarea.dispatchEvent(new CustomEvent("input", {}));
      });
    }

    /**
     * Teardown Tribute @-mention completion.
     */
    teardownMentions() {
      this.tribute.detach(this.querySelector("textarea"));
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
          this.classList.add("dragging-over");
        }
      });

      this.addEventListener("dragleave", e => {
        e.stopPropagation();
        e.preventDefault();

        const rect = this.getBoundingClientRect();

        if (isOutside(rect, e.clientX, e.clientY)) {
          this.stoppedDraggingOver();
        }
      });

      this.addEventListener("dragenter", e => {
        e.stopPropagation();
        e.preventDefault();

        if (!this._dragging_over) {
          this.startedDraggingOver();
        }
      });

      this.addEventListener("drop", e => {
        e.stopPropagation();
        e.preventDefault();

        console.log("[post-composer]", "drop", e);

        this.stoppedDraggingOver();
        this.handleDataTransfer(e.dataTransfer);
      });

      this.addEventListener("dragend", () => {
        this.stoppedDraggingOver();
      });

      this.addEventListener("dragexit", () => {
        this.stoppedDraggingOver();
      });

      this.addEventListener("paste", e => {
        let dt = e.clipboardData || window.clipboardData;

        if (dt.files.length > 0) {
          e.stopPropagation();
          e.preventDefault();

          console.log("[post-composer]", "paste", e);
          this.handleDataTransfer(dt);
        }
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
     * Handle data transfer.
     */
    handleDataTransfer(dt) {
      let files = dt.files;

      [].forEach.call(files, file => {
        this.handleFileDropped(file);
      });
    }

    /**
     * Handles a file after it's been dropped on the composer.
     */
    handleFileDropped(file) {
      const clientId = generateRandomToken();

      const metadata = {
        clientId: clientId,
        filename: file.name,
        contentType: file.type,
        size: file.size,
        contents: null
      };

      this.sendEvent("fileAdded", metadata);
      this.uploadFile(clientId, file);
    }

    /**
     * Dispatch an event.
     */
    sendEvent(name, detail) {
      this.dispatchEvent(new CustomEvent(name, { detail }));
      console.log("[post-composer]", name, detail);
    }

    /**
     * Uploads the given file to the server.
     */
    uploadFile(clientId, file) {
      fetchApiToken()
        .then(token => {
          let xhr = new XMLHttpRequest();
          let formData = new FormData();

          formData.append("file[space_id]", this.spaceId);
          formData.append("file[client_id]", clientId);
          formData.append("file[data]", file);

          xhr.open("POST", "/api/files", true);

          xhr.setRequestHeader("authorization", "Bearer " + token);

          xhr.upload.addEventListener("progress", e => {
            if (e.lengthComputable) {
              let percentage = Math.round(e.loaded * 100 / e.total);
              this.sendEvent("fileUploadProgress", { clientId, percentage });
            }
          });

          xhr.timeout = 60000; // 60 second timeout

          xhr.addEventListener("readystatechange", () => {
            if (xhr.readyState == 4) {
              switch (xhr.status) {
                case 201:
                  let response = JSON.parse(xhr.response);

                  this.sendEvent("fileUploaded", {
                    clientId: clientId,
                    id: response.file.id,
                    url: response.file.url
                  });

                  break;

                default:
                  this.sendEvent("fileUploadError", {
                    clientId: clientId,
                    status: xhr.status
                  });
                  break;
              }
            }
          });

          xhr.addEventListener("timeout", () => {
            this.sendEvent("fileTimeout", { clientId });
          });

          xhr.send(formData);
        })
        .catch(reason => {
          console.log("[post-composer]", "Upload failed", reason);
        });
    }
  }
);
