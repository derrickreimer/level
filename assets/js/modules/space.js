import { getApiToken } from "../token";
import { attachPorts } from "../ports";
import { Main } from "../../elm/src/Main.elm";

export function initialize() {
  const spaceId = document.head.querySelector("meta[name='space_id']").content;

  const app = Main.fullscreen({
    apiToken: getApiToken(),
    spaceId: spaceId
  });

  attachPorts(app);
}
