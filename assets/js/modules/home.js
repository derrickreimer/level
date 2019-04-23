import { getCsrfToken } from "../token";
import { Elm } from "../../elm/src/Program/Reservation.elm";

const getReservationCount = node => {
  return node.dataset.reservationCount;
};

export function initialize() {
  const node = document.getElementById("reservation");

  let app = Elm.Program.Reservation.init({
    node: node,
    flags: {
      csrfToken: getCsrfToken(),
      reservationCount: getReservationCount(node)
    }
  });

  app.ports.afterSubmit.subscribe(args => {
    window._dcq.push([
      "identify",
      {
        email: args.email
      }
    ]);
  });
}
