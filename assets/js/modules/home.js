import { getCsrfToken } from "../token";
import { Elm } from "../../elm/src/Program/Reservation.elm";

const getReservationCount = node => {
  return node.dataset.reservationCount;
};

export function initialize() {
  const node = document.getElementById("reservation");
  const app = Elm.Program.Reservation.init(node, {
    flags: {
      csrfToken: getCsrfToken(),
      reservationCount: getReservationCount(node)
    }
  });
}
