import { getApiToken } from "../token";
import { attachPorts } from "../ports";
import { Program } from "../../elm/src/Program/Space.elm";

export function initialize() {
  const spaceId = document.head.querySelector("meta[name='space_id']").content;

  const app = Program.Space.fullscreen({
    apiToken: getApiToken(),
    spaceId: spaceId
  });

  attachPorts(app);
}
