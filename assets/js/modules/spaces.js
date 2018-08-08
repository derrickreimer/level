import { getApiToken } from "../token";
import { attachPorts } from "../ports";
import { Program } from "../../elm/src/Program/Spaces.elm";

export function initialize() {
  const app = Program.Spaces.fullscreen({
    apiToken: getApiToken()
  });

  attachPorts(app);
}
