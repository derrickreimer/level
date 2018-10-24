import * as AbsintheSocket from "@absinthe/socket";
import { Socket as PhoenixSocket } from "phoenix";

const protocol = window.location.protocol == "http:" ? "ws" : "wss";
const address = protocol + "://" + window.location.host + "/socket";

export const createPhoenixSocket = params =>
  new PhoenixSocket(address, { params });

export const createAbsintheSocket = phoenixSocket =>
  AbsintheSocket.create(phoenixSocket);
