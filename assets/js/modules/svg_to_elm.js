export function initialize() {
  let svgInput = document.getElementById("converter_svg");
  let elmOutput = document.getElementById("elm_output");

  const highlight = (ev) => {
    ev.currentTarget.select();
  };

  svgInput.addEventListener("focus", highlight);

  if (elmOutput) {
    elmOutput.addEventListener("focus", highlight);
    elmOutput.focus();
    elmOutput.select();
  }
}