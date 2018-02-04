import { createSocket } from "./socket";
import { getApiToken } from "./token";
import * as AbsintheSocket from "@absinthe/socket";

const logEvent = eventName => (...args) => console.log(eventName, ...args);

export const attachPorts = app => {
  let socket = createSocket(getApiToken());

  app.ports.refreshToken.subscribe(token => {
    socket = createSocket(token);
    app.ports.socketReset.send();
  });

  app.ports.sendFrame.subscribe(doc => {
    const notifier = AbsintheSocket.send(socket, doc);

    const observedNotifier = AbsintheSocket.observe(socket, notifier, {
      onAbort: logEvent("abort"),
      onError: error => {
        let message = error.message;
        app.ports.socketError.send({ message });
      },
      onStart: data => {
        logEvent("start")(data);
        app.ports.startFrameReceived.send(data);
      },
      onResult: data => {
        logEvent("result")(data);
        app.ports.resultFrameReceived.send(data);
      }
    });
  });

  app.ports.getScrollPosition.subscribe(arg => {
    const { containerId, anchorId } = arg;

    requestAnimationFrame(() => {
      let container = document.getElementById(containerId);
      let anchor = document.getElementById(anchorId);
      if (!container) return;

      let scrollHeight = container.scrollHeight;
      let clientHeight = container.clientHeight;
      let fromTop = container.scrollTop;
      let fromBottom = scrollHeight - fromTop - clientHeight;

      if (anchor) {
        var anchorOffset = anchor.offsetTop;
      } else {
        var anchorOffset = null;
      }

      app.ports.scrollPositionReceived.send({
        containerId,
        fromBottom,
        fromTop,
        anchorOffset
      });
    });
  });

  app.ports.scrollTo.subscribe(arg => {
    const { containerId, anchorId, offset } = arg;

    requestAnimationFrame(() => {
      let container = document.getElementById(containerId);
      let anchor = document.getElementById(anchorId);
      if (!(container && anchor)) return;

      container.scrollTop = anchor.offsetTop + offset;
    });
  });
};
