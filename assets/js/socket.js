import * as AbsintheSocket from "@absinthe/socket";
import {Socket as PhoenixSocket} from "phoenix";

const ADDRESS = "ws://" + window.location.host + "/socket";

export const socket = AbsintheSocket.create(
  new PhoenixSocket(ADDRESS)
);
