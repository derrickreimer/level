import { socket } from "../socket";
import * as AbsintheSocket from "@absinthe/socket";

const logEvent = eventName => (...args) => console.log(eventName, ...args);
const getApiToken = () => document.head.querySelector("meta[name='api_token']").content;

export function initialize() {
  var app = Elm.Main.fullscreen({
    apiToken: getApiToken()
  });

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
