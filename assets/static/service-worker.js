// Register event listener for the 'push' event.
self.addEventListener('push', function (event) {
  // Retrieve the JSON payload from event.data (a PushMessageData object).
  // See https://developer.mozilla.org/en-US/docs/Web/API/PushMessageData.
  const data = event.data ? event.data.json() : {};

  let payload = { body: data.body };
  if (data.tag) payload.tag = data.tag;

  // Keep the service worker alive until the notification is created.
  event.waitUntil(self.registration.showNotification('Level', payload));
});
