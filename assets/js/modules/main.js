import { getApiToken } from "../token";
import { attachPorts } from "../ports";
import { Elm } from "../../elm/src/Program/Main.elm";

export function initialize() {
  const spaceId = document.head.querySelector("meta[name='space_id']").content;

  const app = Elm.Program.Main.init({
    flags: {
      apiToken: getApiToken(),
      spaceId: spaceId
    }
  });

  attachPorts(app);
}
