import { getApiToken } from "../token";
import { NewSpace } from "../../elm/src/NewSpace.elm";

export function initialize() {
  const app = NewSpace.fullscreen({
    apiToken: getApiToken()
  });
}
