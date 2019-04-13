import { createPhoenixSocket, createAbsintheSocket } from "./socket";
import { Presence } from "phoenix";
import { getInitialApiToken, fetchApiToken } from "./token";
import { insertTextAtCursor } from "./utils";
import * as AbsintheSocket from "@absinthe/socket";
import * as ServiceWorker from "./service_worker";
import autosize from "autosize";

const logEvent = eventName => (...args) =>
  console.log("[ports." + eventName + "]", ...args);

const logError = eventName => (...args) =>
  console.error("[ports." + eventName + "]", ...args);

export const attachPorts = app => {
  // Start with the initial API token generated at page-load time.
  // This variable may get mutated over time as tokens expire.
  let token = getInitialApiToken();

  let socketParams = () => {
    return { Authorization: "Bearer " + token };
  };

  let phoenixSocket = createPhoenixSocket(socketParams, (...args) =>
    console.log("[socket]", ...args)
  );
  let absintheSocket = createAbsintheSocket(phoenixSocket);
  let channels = {};

  // Expose a helper function for getting the current state of the socket
  window.phoenixSocket = () => {
    return phoenixSocket;
  };

  phoenixSocket.onOpen(args => {
    const payload = { type: "opened" };
    app.ports.socketIn.send(payload);
    logEvent("socketIn")(payload);
  });

  phoenixSocket.onError(args => {
    fetchApiToken()
      .then(newToken => {
        console.log("New token fetched", newToken);
        token = newToken;
      })
      .catch(() => {
        console.log("Token refresh failed");
      });
  });

  phoenixSocket.onClose(e => {
    const payload = { type: "closed" };
    app.ports.socketIn.send(payload);
    logEvent("socketIn")(payload);

    // If the event indicates this was a "normal closure (code = 1000), that
    // means something has gone wrong and the socket has given up retrying to connect.
    if (e.code == 1000) {
      console.log("Socket hard reconnecting", phoenixSocket);
      phoenixSocket.disconnect(() => phoenixSocket.connect());
    }
  });

  const joinChannel = topic => {
    let channel = phoenixSocket.channel(topic, {});
    let presence = new Presence(channel);

    presence.onJoin((userId, current, presence) => {
      const callback = "onJoin";
      const data = { userId, current, presence };
      const payload = { callback, topic, data };

      app.ports.presenceIn.send(payload);
      logEvent("presenceIn")(payload);
    });

    presence.onLeave((userId, current, presence) => {
      const callback = "onLeave";
      const data = { userId, current, presence };
      const payload = { callback, topic, data };

      app.ports.presenceIn.send(payload);
      logEvent("presenceIn")(payload);
    });

    presence.onSync(() => {
      const callback = "onSync";

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
    delete channels[topic];
  };

  const updatePresence = (topic, data) => {
    let channel = channels[topic];
    if (!channel) return;

    channel.push("meta:update", data);
  };

  app.ports.updateToken.subscribe(newToken => {
    token = newToken;
    logEvent("updateToken")(token);
  });

  app.ports.socketOut.subscribe(args => {
    switch (args.method) {
      case "sendSubscription":
        const notifier = AbsintheSocket.send(absintheSocket, args);

        AbsintheSocket.observe(absintheSocket, notifier, {
          onResult: data => {
            data.type = "message";
            app.ports.socketIn.send(data);
            logEvent("socketIn")(data);
          }
        });

        break;

      case "cancelSubscription":
        const notifiers = absintheSocket.notifiers.filter(notifier => {
          return notifier.request.clientId == args.clientId;
        });

        notifiers.forEach(notifier => {
          // Sometimes if you navigate quickly in the app, an "unsubscribe"
          // command gets sent before Absinthe has a chance to actually
          // join the Phoenix channel. In this case, we can safely just
          // swallow the exception and move along.
          //
          // https://github.com/levelhq/level/issues/123
          try {
            AbsintheSocket.cancel(absintheSocket, notifier);
          } catch (error) {
            logError("socketIn")(error);
          }
        });

        break;
    }

    logEvent("socketOut")(args);
  });

  app.ports.presenceOut.subscribe(arg => {
    const { method, topic } = arg;

    switch (method) {
      case "join":
        joinChannel(topic);
        break;

      case "leave":
        leaveChannel(topic);
        break;

      case "update":
        updatePresence(topic, arg.data);
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
        let scrollTop = container.scrollTop + rect.top - offset;
        window.scroll({ top: scrollTop, left: 0, behavior: "smooth" });
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
        clientId: id,
        filename: file.name,
        contentType: file.type,
        size: file.size,
        contents: event.target.result
      };

      app.ports.receiveFile.send(payload);
      logEvent("file.receive")(payload);
    };

    reader.readAsDataURL(file);

    logEvent("requestFile")({ id });
  });

  if (ServiceWorker.isPushSupported()) {
    app.ports.serviceWorkerOut.subscribe(method => {
      switch (method) {
        case "getPushSubscription":
          ServiceWorker.getPushSubscription().then(subscription => {
            const payload = {
              type: "pushSubscription",
              subscription: JSON.stringify(subscription)
            };

            app.ports.serviceWorkerIn.send(payload);
            logEvent("serviceWorkerIn")(payload);
          });

          break;

        case "pushSubscribe":
          ServiceWorker.pushSubscribe()
            .then(subscription => {
              const payload = {
                type: "pushSubscription",
                subscription: JSON.stringify(subscription)
              };

              app.ports.serviceWorkerIn.send(payload);
              logEvent("serviceWorkerIn")(payload);
            })
            .catch(err => {
              console.error(err);
            });

          break;
      }

      logEvent("serviceWorkerOut")(method);
    });

    ServiceWorker.addEventListener("message", event => {
      const payload = event.data;
      app.ports.serviceWorkerIn.send(payload);
      logEvent("serviceWorkerIn")(payload);
    });
  }

  app.ports.postEditorOut.subscribe(args => {
    logEvent("postEditorOut")(args);

    requestAnimationFrame(() => {
      let node = document.getElementById(args.id);
      let textarea = document.getElementById(args.id + "__textarea");
      let storage = window.localStorage;
      const key = "level:postEditor:" + args.id;
      if (!node || !textarea) return;

      switch (args.command) {
        case "insertAtCursor":
          insertTextAtCursor(textarea, args.text);
          break;

        case "saveLocal":
          if (!storage) break;

          if (args.body === "") {
            storage.removeItem(key);
          } else {
            storage.setItem(key, args.body);
          }

          break;

        case "clearLocal":
          if (!storage) break;
          storage.removeItem(key);
          break;

        case "fetchLocal":
          if (!storage) break;
          let value = storage.getItem(key);
          if (!value) break;

          const payload = {
            id: args.id,
            type: "localDataFetched",
            body: value
          };

          app.ports.postEditorIn.send(payload);
          logEvent("postEditorIn")(payload);

          break;

        case "triggerBodyChanged":
          node.dispatchEvent(new CustomEvent("bodyChanged", {}));
          break;
      }
    });
  });

  app.ports.beaconOut.subscribe(args => {
    logEvent("beaconOut")(args);

    switch (args.method) {
      case "init":
        Beacon("init", "907003e9-12d8-4d63-ac3b-34356b2faec0");
        break;

      case "destroy":
        Beacon("destroy");
        break;

      case "open":
        Beacon("open");
        break;
    }
  });
};
