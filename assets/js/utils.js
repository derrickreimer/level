/**
 * Inserts a given snippet of text at the current cursor position in
 * an input/textarea node.
 *
 * Props to Everything Frontend:
 * https://www.everythingfrontend.com/posts/insert-text-into-textarea-at-cursor-position.html
 */
export const insertTextAtCursor = (node, textToInsert) => {
  // Newer browsers
  node.focus();
  const isSuccess = document.execCommand("insertText", false, textToInsert);

  // Firefox (non-standard method)
  if (!isSuccess && typeof node.setRangeText === "function") {
    const start = node.selectionStart;
    node.setRangeText(textToInsert);
    // update cursor to be at the end of insertion
    node.selectionStart = node.selectionEnd = start + textToInsert.length;

    // Notify any possible listeners of the change
    const e = document.createEvent("UIEvent");
    e.initEvent("input", true, false);
    node.dispatchEvent(e);
  }
};
