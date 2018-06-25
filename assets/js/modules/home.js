import { getCsrfToken } from "../token";
import { Reservation } from "../../elm/src/Reservation.elm";

const getReservationCount = node => {
  return node.dataset.reservationCount;
};

export function initialize() {
  const node = document.getElementById("reservation");
  const app = Reservation.embed(node, {
    csrfToken: getCsrfToken(),
    reservationCount: getReservationCount(node)
  });
}
