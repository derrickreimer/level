import { getApiToken, getCsrfToken } from "../token";
import { attachPorts } from "../ports";

export function initialize() {
  const app = Elm.Main.fullscreen({
    apiToken: getApiToken()
  });

  attachPorts(app);
}
