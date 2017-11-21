import { createSocket } from "../socket";
import { getApiToken } from "../token";
import * as AbsintheSocket from "@absinthe/socket";

const logEvent = eventName => (...args) => console.log(eventName, ...args);

export function initialize() {
  const app = Elm.Main.fullscreen({
    apiToken: getApiToken()
  });

  const socket = createSocket();

  app.ports.sendFrame.subscribe((operation) => {
    const notifier = AbsintheSocket.send(socket, {
      operation
    });

    const observedNotifier = AbsintheSocket.observe(socket, notifier, {
      onAbort: logEvent("abort"),
      onError: logEvent("error"),
      onStart: data => {
        logEvent("start")(data);
        app.ports.startFrames.send(data);
      },
      onResult: data => {
        logEvent("result")(data);
        app.ports.resultFrames.send(data);
      }
    });
  });
};
