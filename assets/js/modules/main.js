import { createSocket } from "../socket";
import { getApiToken } from "../token";
import * as AbsintheSocket from "@absinthe/socket";

const logEvent = eventName => (...args) => console.log(eventName, ...args);

export function initialize() {
  const app = Elm.Main.fullscreen({
    apiToken: getApiToken()
  });

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

  // TODO: This function is intended to scroll the messages container to the bottom
  // when a new message is appended if the scroll position is already at or near
  // the bottom. If the user has scrolled much further up the page, then we
  // don't want to set scroll position to the bottom every time a new message
  // comes in. There appears to be a race condition with triggering ports that
  // rely on firing _after_ virtual dom updates have been made.

  // app.ports.autoScroll.subscribe((id) => {
  //   const TOLERANCE = 200;
  //
  //   setTimeout(() => {
  //     let node = document.getElementById(id);
  //     if (!node) return;
  //
  //     let scrollHeight = node.scrollHeight;
  //     let clientHeight = node.clientHeight;
  //     let scrollTop = node.scrollTop;
  //     let distanceFromBottom = scrollHeight - scrollTop - clientHeight;
  //
  //     if (distanceFromBottom <= TOLERANCE) {
  //       node.scrollTop = scrollHeight;
  //     }
  //   }, 50);
  // });
};
