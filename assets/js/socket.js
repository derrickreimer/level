import * as AbsintheSocket from "@absinthe/socket";
import { Socket as PhoenixSocket } from "phoenix";
import { getApiToken } from "./token";

const ADDRESS = "ws://" + window.location.host + "/socket";

export const createSocket = () => AbsintheSocket.create(
  new PhoenixSocket(ADDRESS, {params: {Authorization: "Bearer " + getApiToken()}})
);
