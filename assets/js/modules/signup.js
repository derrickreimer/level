export function initialize() {
  var csrfToken = document.head.querySelector("meta[name='csrf_token']").content;

  var app = Elm.Signup.fullscreen({
    csrf_token: csrfToken
  });
};
