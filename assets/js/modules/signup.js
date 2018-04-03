import { getCsrfToken } from "../token";

export function initialize() {
  const app = Elm.Signup.fullscreen({
    csrfToken: getCsrfToken()
  });
}
