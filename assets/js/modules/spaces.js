import { getApiToken } from "../token";
import { attachPorts } from "../ports";
import { Elm } from "../../elm/src/Program/Spaces.elm";

export function initialize() {
  const app = Elm.Program.Spaces.init({
    flags: {
      apiToken: getApiToken()
    }
  });

  attachPorts(app);
}
