import {
  createPhoenixSocket,
  createAbsintheSocket,
  updateSocketToken
} from "./socket";
import { getApiToken } from "./token";
import * as AbsintheSocket from "@absinthe/socket";
import autosize from "autosize";

const logEvent = eventName => (...args) => console.log(eventName, ...args);

export const attachPorts = app => {
  let phoenixSocket = createPhoenixSocket(getApiToken());
  let absintheSocket = createAbsintheSocket(phoenixSocket);

  app.ports.updateToken.subscribe(token => {
    updateSocketToken(phoenixSocket, token);
    app.ports.socketTokenUpdated.send();
  });

  app.ports.push.subscribe(doc => {
    const notifier = AbsintheSocket.send(absintheSocket, doc);

    AbsintheSocket.observe(absintheSocket, notifier, {
      onAbort: data => {
        logEvent("abort")(data);
        app.ports.socketAbort.send(data);
      },
      onError: data => {
        logEvent("error")(data);
        app.ports.socketError.send(data);
      },
      onStart: data => {
        logEvent("start")(data);
        app.ports.socketStart.send(data);
      },
      onResult: data => {
        logEvent("result")(data);
        app.ports.socketResult.send(data);
      }
    });
  });

  app.ports.cancel.subscribe(clientId => {
    const notifiers = absintheSocket.notifiers.filter(notifier => {
      return notifier.request.clientId == clientId;
    });

    notifiers.forEach(notifier => {
      logEvent("cancel")(notifier);
      AbsintheSocket.cancel(absintheSocket, notifier);
    })
  })

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

  app.ports.autosize.subscribe(arg => {
    const { method, id } = arg;

    requestAnimationFrame(() => {
      let node = document.getElementById(id);
      autosize(node);
      if (method === "update") autosize.update(node);
      if (method === "destroy") autosize.destroy(node);
    });
  });

  app.ports.select.subscribe(id => {
    requestAnimationFrame(() => {
      let node = document.getElementById(id);
      node.select();
    });
  })
};
