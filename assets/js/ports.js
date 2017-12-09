import { createSocket } from "./socket";
import * as AbsintheSocket from "@absinthe/socket";

const logEvent = eventName => (...args) => console.log(eventName, ...args);

export const attachPorts = (app) => {
  const socket = createSocket();

  app.ports.sendFrame.subscribe((doc) => {
    const notifier = AbsintheSocket.send(socket, doc);

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

  app.ports.getScrollPosition.subscribe((id) => {
    let node = document.getElementById(id);
    if (!node) return;

    let scrollHeight = node.scrollHeight;
    let clientHeight = node.clientHeight;
    let fromTop = node.scrollTop;
    let fromBottom = scrollHeight - fromTop - clientHeight;

    app.ports.scrollPosition.send({id, fromBottom, fromTop});
  });
};
