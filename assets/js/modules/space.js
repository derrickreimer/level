import { getApiToken } from "../token";
import { attachPorts } from "../ports";
import { Main } from "../../elm/src/Main.elm";

export function initialize() {
  const app = Main.fullscreen({
    apiToken: getApiToken()
  });

  attachPorts(app);
}
