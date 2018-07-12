import { getCsrfToken } from "../token";
import { Program } from "../../elm/src/Program/Reservation.elm";

const getReservationCount = node => {
  return node.dataset.reservationCount;
};

export function initialize() {
  const node = document.getElementById("reservation");
  const app = Program.Reservation.embed(node, {
    csrfToken: getCsrfToken(),
    reservationCount: getReservationCount(node)
  });
}
