import { getApiToken } from "../token";
import { Elm } from "../../elm/src/Program/NewSpace.elm";

export function initialize() {
  const app = Elm.Program.NewSpace.init({
    flags: {
      apiToken: getApiToken()
    }
  });
}
