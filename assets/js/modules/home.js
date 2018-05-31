import { getCsrfToken } from "../token";
import { Reservation } from "../../elm/src/Reservation.elm";

export function initialize() {
  const node = document.getElementById('reservation');
  const app = Reservation.embed(node, {
    csrfToken: getCsrfToken()
  });
}
