// Register event listener for the 'push' event.
self.addEventListener('push', function (event) {
  // Retrieve the JSON payload from event.data (a PushMessageData object).
  // See https://developer.mozilla.org/en-US/docs/Web/API/PushMessageData.
  const data = event.data ? event.data.json() : {};
  console.log("[sw]", "push received", data);

  let payload = {
    body: data.body,
    requireInteraction: data.require_interaction,
    data: {
      url: data.url
    }
  };

  if (data.tag) payload.tag = data.tag;

  // Keep the service worker alive until the notification is created.
  console.log("[sw]", "show notification", payload);
  event.waitUntil(self.registration.showNotification('Level', payload));
});

// Listen for notification clicks
self.addEventListener('notificationclick', function (event) {
  const data = event.notification.data;
  event.notification.close();
  console.log("[sw]", "notification click", event);

  if (data.url) {
    const fullUrl = new URL(data.url, self.location.origin).href;

    const promiseChain = clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    })
    .then((windowClients) => {
      let matchingClient = null;

      // Search for an exact matching window
      for (let i = 0; i < windowClients.length; i++) {
        const windowClient = windowClients[i];
        if (windowClient.url === fullUrl) {
          matchingClient = windowClient;
          break;
        }
      }

      // If there's an exact matching window, focus it
      if (matchingClient) {
        return matchingClient.focus();

      // If there are any windows, focus on the first one and redirect
      } else if (windowClients.length > 0) {
        let firstClient = windowClients[0];

        firstClient.postMessage({
          type: "redirect",
          url: fullUrl
        });

        return firstClient.focus();

      // Otherwise, open a new window
      } else {
        return clients.openWindow(fullUrl);
      }
    });

    event.waitUntil(promiseChain);
  }
});
