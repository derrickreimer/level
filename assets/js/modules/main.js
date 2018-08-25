import { getApiToken } from "../token";
import { attachPorts } from "../ports";
import { Elm } from "../../elm/src/Program/Main.elm";

export function initialize() {
  const app = Elm.Program.Main.init({
    flags: {
      apiToken: getApiToken()
    }
  });

  attachPorts(app);
}
