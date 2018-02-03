import { getApiToken, getCsrfToken } from "../token";
import { attachPorts } from "../ports";

export function initialize() {
  const app = Elm.Main.fullscreen({
    csrfToken: getCsrfToken(),
    apiToken: getApiToken()
  });

  attachPorts(app);
};
