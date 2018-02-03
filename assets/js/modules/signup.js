import { getCsrfToken } from "../token";

export function initialize() {
  const app = Elm.Signup.fullscreen({
    csrf_token: getCsrfToken()
  });
}
