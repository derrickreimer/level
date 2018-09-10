import { getApiToken } from "../token";
import { attachPorts } from "../ports";
import { Elm } from "../../elm/src/Program/Main.elm";
import * as Background from "../background";

export function initialize() {
  const app = Elm.Program.Main.init({
    flags: {
      apiToken: getApiToken(),
      supportsNotifications: Background.isSupported()
    }
  });

  attachPorts(app);
}
