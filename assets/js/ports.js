import {
  createPhoenixSocket,
  createAbsintheSocket,
  updateSocketToken
} from "./socket";
import { Presence } from "phoenix";
import { getApiToken } from "./token";
import * as AbsintheSocket from "@absinthe/socket";
import autosize from "autosize";
import * as Background from "./background";

const logEvent = eventName => (...args) =>
  console.log("[ports." + eventName + "]", ...args);

export const attachPorts = app => {
  let phoenixSocket = createPhoenixSocket(getApiToken());
  let absintheSocket = createAbsintheSocket(phoenixSocket);
  let channels = {};

  const joinChannel = topic => {
    if (channels[topic]) return;

    let channel = phoenixSocket.channel(topic, {});
    let presence = new Presence(channel);

    presence.onJoin((userId, current, presence) => {
      const callback = 'onJoin';
      const data = { userId, current, presence };
      const payload = { callback, topic, data };

      app.ports.presenceIn.send(payload);
      logEvent("presenceIn")(payload);
    });

    presence.onLeave((userId, current, presence) => {
      const callback = 'onLeave';
      const data = { userId, current, presence };
      const payload = { callback, topic, data };

      app.ports.presenceIn.send(payload);
      logEvent("presenceIn")(payload);
    });

    presence.onSync(() => {
      const callback = 'onSync';

      const data = presence.list((userId, presence) => {
        return { userId, presence };
      });

      const payload = { callback, topic, data };

      app.ports.presenceIn.send(payload);
      logEvent("presenceIn")(payload);
    });

    channel.join();
    channels[topic] = channel;
  };

  const leaveChannel = topic => {
    let channel = channels[topic];
    if (!channel) return;

    channel.leave();
    delete channel[topic];
  };

  app.ports.updateToken.subscribe(token => {
    updateSocketToken(phoenixSocket, token);
    logEvent("updateToken")(token);
  });

  app.ports.sendSocket.subscribe(doc => {
    const notifier = AbsintheSocket.send(absintheSocket, doc);

    AbsintheSocket.observe(absintheSocket, notifier, {
      onAbort: data => {
        logEvent("socketAbort")(data);
        app.ports.socketAbort.send(data);
      },
      onError: data => {
        logEvent("socketError")(data);
        app.ports.socketError.send(data);
      },
      onStart: data => {
        logEvent("socketStart")(data);
        app.ports.socketStart.send(data);
      },
      onResult: data => {
        logEvent("socketResult")(data);
        app.ports.socketResult.send(data);
      }
    });

    logEvent("sendSocket")(doc);
  });

  app.ports.cancelSocket.subscribe(clientId => {
    const notifiers = absintheSocket.notifiers.filter(notifier => {
      return notifier.request.clientId == clientId;
    });

    notifiers.forEach(notifier => {
      logEvent("socket.cancel")(notifier);
      AbsintheSocket.cancel(absintheSocket, notifier);
    });
  });

  app.ports.presenceOut.subscribe(arg => {
    const { method, topic } = arg;

    switch (method) {
      case 'join':
        joinChannel(topic);
        break;

      case 'leave':
        leaveChannel(topic);
        break;
    }

    logEvent("presenceOut")(arg);
  });

  app.ports.scrollTo.subscribe(arg => {
    const { containerId, anchorId, offset } = arg;

    requestAnimationFrame(() => {
      if (containerId === "DOCUMENT") {
        let container = document.documentElement;
        let anchor = document.getElementById(anchorId);
        if (!anchor) return;

        let rect = anchor.getBoundingClientRect();
        container.scrollTop = container.scrollTop + rect.top - offset;
      } else {
        let container = document.getElementById(containerId);
        let anchor = document.getElementById(anchorId);
        if (!(container && anchor)) return;

        container.scrollTop = anchor.offsetTop + offset;
      }

      logEvent("scrollTo")(arg);
    });
  });

  app.ports.scrollToBottom.subscribe(arg => {
    const { containerId } = arg;

    requestAnimationFrame(() => {
      if (containerId === "DOCUMENT") {
        let container = document.documentElement;
        container.scrollTop = container.scrollHeight;
      } else {
        let container = document.getElementById(containerId);
        if (!container) return;
        container.scrollTop = container.scrollHeight;
      }

      logEvent("scrollToBottom")(arg);
    });
  });

  app.ports.autosize.subscribe(arg => {
    const { method, id } = arg;

    requestAnimationFrame(() => {
      let node = document.getElementById(id);
      autosize(node);
      if (method === "update") autosize.update(node);
      if (method === "destroy") autosize.destroy(node);

      logEvent("autosize")(arg);
    });
  });

  app.ports.select.subscribe(id => {
    requestAnimationFrame(() => {
      let node = document.getElementById(id);
      node.select();
      logEvent("select")(id);
    });
  });

  app.ports.requestFile.subscribe(id => {
    let node = document.getElementById(id);
    if (!node) return;

    let file = node.files[0];
    if (!file) return;

    let reader = new FileReader();

    reader.onload = event => {
      let payload = {
        id: id,
        name: file.name,
        type_: file.type,
        size: file.size,
        contents: event.target.result
      };

      app.ports.receiveFile.send(payload);
      logEvent("file.receive")(payload);
    };

    reader.readAsDataURL(file);

    logEvent("requestFile")({ id });
  });

  if (Background.isSupported) {
    app.ports.pushManagerOut.subscribe(method => {
      switch (method) {
        case "getSubscription":
          Background.getPushSubscription().then(subscription => {
            const payload = {
              type: "subscription",
              subscription: JSON.stringify(subscription)
            };

            app.ports.pushManagerIn.send(payload);
            logEvent("pushManagerIn")(payload);
          });

          break;

        case "subscribe":
          Background.subscribe()
            .then(subscription => {
              const payload = {
                type: "subscription",
                subscription: JSON.stringify(subscription)
              };

              app.ports.pushManagerIn.send(payload);
              logEvent("pushManagerIn")(payload);
            })
            .catch(err => {
              console.error(err);
            });

          break;
      }

      logEvent("pushManagerOut")(method);
    });
  }
};
