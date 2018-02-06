import * as AbsintheSocket from "@absinthe/socket";
import { Socket as PhoenixSocket } from "phoenix";

const ADDRESS = "ws://" + window.location.host + "/socket";

export const createPhoenixSocket = token =>
  new PhoenixSocket(ADDRESS, {
    params: { Authorization: "Bearer " + token }
  });

export const updateSocketToken = (socket, token) =>
  (socket.params = { Authorization: "Bearer " + token });

export const createAbsintheSocket = phoenixSocket =>
  AbsintheSocket.create(phoenixSocket);
