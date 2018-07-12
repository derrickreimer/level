import { getApiToken } from "../token";
import { Program } from "../../elm/src/Program/NewSpace.elm";

export function initialize() {
  const app = Program.NewSpace.fullscreen({
    apiToken: getApiToken()
  });
}
