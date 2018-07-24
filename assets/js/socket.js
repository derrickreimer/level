import * as AbsintheSocket from "@absinthe/socket";
import { Socket as PhoenixSocket } from "phoenix";

const protocol = window.location.protocol == "http:" ? "ws" : "wss";
const address = protocol + "://" + window.location.host + "/socket";

export const createPhoenixSocket = token =>
  new PhoenixSocket(address, {
    params: { Authorization: "Bearer " + token }
  });

export const updateSocketToken = (socket, token) =>
  (socket.params = { Authorization: "Bearer " + token });

export const createAbsintheSocket = phoenixSocket =>
  AbsintheSocket.create(phoenixSocket);
