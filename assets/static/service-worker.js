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
      clickUrl: data.click_url
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

  console.log("[sw]", "notification click", event);

  if (data.clickUrl) {
    event.notification.close();

    const urlToOpen = new URL(data.clickUrl, self.location.origin).href;

    const promiseChain = clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    })
    .then((windowClients) => {
      let matchingClient = null;

      for (let i = 0; i < windowClients.length; i++) {
        const windowClient = windowClients[i];
        if (windowClient.url === urlToOpen) {
          matchingClient = windowClient;
          break;
        }
      }

      if (matchingClient) {
        return matchingClient.focus();
      } else if (windowClients.length > 0) {
        let firstClient = windowClients[0];

        firstClient.postMessage({
          type: "redirect",
          url: urlToOpen
        });

        return firstClient.focus();
      } else {
        return clients.openWindow(urlToOpen);
      }
    });

    event.waitUntil(promiseChain);
  }
});
