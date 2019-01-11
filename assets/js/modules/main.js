import { getInitialApiToken } from "../token";
import { attachPorts } from "../ports";
import { Elm } from "../../elm/src/Program/Main.elm";
import * as Background from "../background";
import { isMobile } from "../device_detection";
import jstz from "jstz";

export function initialize() {
  const app = Elm.Program.Main.init({
    flags: {
      apiToken: getInitialApiToken(),
      supportsNotifications: Background.isSupported(),
      timeZone: jstz.determine().name(),
      device: isMobile() ? "MOBILE" : "DESKTOP"
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

  // Initialize Beacon
  if (!isMobile()) {
    Beacon("init", "907003e9-12d8-4d63-ac3b-34356b2faec0");
  }
}
