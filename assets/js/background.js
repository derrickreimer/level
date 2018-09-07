const log = (...args) => console.log("[bg]", ...args);
const error = (...args) => console.error("[bg]", ...args);

const getPublicKey = () => {
  return document.head.querySelector("meta[name='web_push_public_key']")
    .content;
};

/**
 * Gets the subscription.
 */
export function getPushSubscription() {
  return new Promise((resolve, reject) => {
    navigator.serviceWorker.ready.then(registration => {
      registration.pushManager
        .getSubscription()
        .then(subscription => resolve(subscription))
        .catch(err => reject(err));
    });
  });
}

/**
 * Initiates a subscription flow.
 */
export function subscribe() {
  navigator.serviceWorker.ready.then(registration => {
    const convertedKey = urlBase64ToUint8Array(getPublicKey());

    registration.pushManager
      .subscribe({
        userVisibleOnly: true,
        applicationServerKey: convertedKey
      })
      .then(subscription => {
        // TODO: save subscription to the server
        log("Subscription established");
        return subscription;
      })
      .catch(err => {
        log("Permission setting", Notification.permission);

        if (Notification.permission === "denied") {
          // The user denied the notification permission which
          // means we failed to subscribe and the user will need
          // to manually change the notification permission to
          // subscribe to push messages
          log("Permission for notifications was denied.");
        } else {
          // A problem occurred with the subscription, this can
          // often be down to an issue or lack of the gcm_sender_id
          // and / or gcm_user_visible_only
          error("Unable to subscribe to push.", err);
        }
      });
  });
}

/**
 * Private: Convert a base64 string into format required 
 * for push manager subscriptions.
 */
function urlBase64ToUint8Array(base64String) {
  const padding = "=".repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding)
    .replace(/\-/g, "+")
    .replace(/_/g, "/");

  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

/**
 * Checks to see if service workers are supported.
 */
export const isSupported = () => {
  if (!("serviceWorker" in navigator)) return false;
  if (!("PushManager" in window)) return false;
  return true;
};

/**
 * Initializes the service worker.
 */
export function registerWorker() {
  if (!isSupported()) {
    log("Service workers not supported.");
    return;
  }

  navigator.serviceWorker
    .register("/service-worker.js")
    .then(subscription => {
      log("Service worker successfully registered.", subscription);
    })
    .catch(err => {
      error("Unable to register service worker.", err);
    });
}

/**
 * Prompts the user for permission to send notifications.
 */
export function askPermission() {
  return new Promise((resolve, reject) => {
    const permissionResult = Notification.requestPermission(result => {
      resolve(result);
    });

    if (permissionResult) {
      permissionResult.then(resolve, reject);
    }
  }).then(permissionResult => {
    if (permissionResult !== "granted") {
      throw new Error("We weren't granted permission.");
    }
  });
}
