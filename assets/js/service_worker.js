const log = (...args) => console.log("[sw client]", ...args);
const error = (...args) => console.error("[sw client]", ...args);

/**
 * Fetches the VAPID public key.
 * @returns {String}
 */
const getPublicKey = () => {
  return document.head.querySelector("meta[name='web_push_public_key']")
    .content;
};

/**
 * Fetches the subscription, which will resolve to null if it does not exist.
 * @returns {Promise}
 */
export function getPushSubscription() {
  return navigator.serviceWorker.ready.then(registration => {
    return registration.pushManager.getSubscription();
  });
}

/**
 * Initiates a subscription flow.
 * @returns {Promise}
 */
export function pushSubscribe() {
  return navigator.serviceWorker.ready.then(registration => {
    const convertedKey = urlBase64ToUint8Array(getPublicKey());

    return registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: convertedKey
    });
  });
}

/**
 * Convert a base64 string into format required  for push manager subscriptions.
 * @param {String} base64String A url-safe base64-encoded value.
 * @returns {Uint8Array}
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
 * Checks to see if push notifications are supported.
 * @returns {Boolean}
 */
export const isPushSupported = () => {
  if (!isSupported()) return false;
  if (!("PushManager" in window)) return false;
  return true;
};

/**
 * Checks to see if service workers are supported.
 * @returns {Boolean}
 */
export const isSupported = () => {
  if (!("serviceWorker" in navigator)) return false;
  return true;
};

/**
 * Adds an event listener to the service worker.
 */
export function addEventListener(eventName, callback) {
  navigator.serviceWorker.addEventListener(eventName, callback);
}

/**
 * Initializes the service worker.
 * @returns {Promise}
 */
export function registerWorker() {
  if (!isSupported()) {
    log("Service workers not supported.");
    return;
  }

  return navigator.serviceWorker
    .register("/service-worker.js")
    .then(registration => {
      log("Service worker successfully registered.", { registration });
      return registration;
    })
    .catch(err => {
      error("Unable to register service worker.", err);
    });
}
