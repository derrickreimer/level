import { getInitialApiToken } from "../token";
import { attachPorts } from "../ports";
import { Elm } from "../../elm/src/Program/Main.elm";
import * as Background from "../background";
import jstz from "jstz";

export function initialize() {
  const app = Elm.Program.Main.init({
    flags: {
      apiToken: getInitialApiToken(),
      supportsNotifications: Background.isSupported(),
      timeZone: jstz.determine().name()
    }
  });

  attachPorts(app);

  // Initialize Headway after a little delay
  // to give the async script time to load
  setTimeout(() => {
    if (window.Headway) {
      window.Headway.init({
        selector: "#headway",
        account: "7Q9Qv7"
      });
    }
  }, 3000);
}
