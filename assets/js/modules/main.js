// -- SCRATCH WORK --
//
// import { socket } from "./socket";
// import * as AbsintheSocket from "@absinthe/socket";
//
// const operation = `
//   subscription {
//     roomMessageCreated(roomId: "51077027888890883") {
//       roomMessage {
//         body
//       }
//     }
//   }
// `;
//
// const notifier = AbsintheSocket.send(socket, {
//   operation
// });

export function initialize() {
  var apiToken = document.head.querySelector("meta[name='api_token']").content;

  var app = Elm.Main.fullscreen({
    apiToken: apiToken
  });
};
