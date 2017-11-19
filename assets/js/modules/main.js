import { createSocket } from "../socket";
import { getApiToken } from "../token";
import * as AbsintheSocket from "@absinthe/socket";

const logEvent = eventName => (...args) => console.log(eventName, ...args);

export function initialize() {
  let app = Elm.Main.fullscreen({
    apiToken: getApiToken()
  });

  let socket = createSocket();

  app.ports.sendFrame.subscribe((operation) => {
    const notifier = AbsintheSocket.send(socket, {
      operation
    });

    const updatedNotifier = AbsintheSocket.observe(socket, notifier, {
      onAbort: logEvent("abort"),
      onError: logEvent("error"),
      onStart: logEvent("open"),
      onResult: logEvent("result")
    });
  });
};
