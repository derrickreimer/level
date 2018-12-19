import { getInitialApiToken } from "../token";
import { attachPorts } from "../ports";
import { Elm } from "../../elm/src/Program/Main.elm";
import * as Background from "../background";
import jstz from "jstz";

const isMobile = () => {
  if (navigator.userAgent.match(/Mobi/)) {
    return true;
  }

  if ('screen' in window && window.screen.width < 1366) {
    return true;
  }

  var connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
  if (connection && connection.type === 'cellular') {
    return true;
  }

  return false;
}

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
}
