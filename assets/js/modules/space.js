import { getApiToken } from "../token";
import { attachPorts } from "../ports";
import { Space } from "../../elm/src/Space.elm";

export function initialize() {
  const spaceId = document.head.querySelector("meta[name='space_id']").content;

  const app = Space.fullscreen({
    apiToken: getApiToken(),
    spaceId: spaceId
  });

  attachPorts(app);
}
