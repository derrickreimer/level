// Register event listener for the 'push' event.
self.addEventListener('push', function (event) {
  // Retrieve the JSON payload from event.data (a PushMessageData object).
  // See https://developer.mozilla.org/en-US/docs/Web/API/PushMessageData.
  const payload = event.data ? event.data.json() : {};

  // Keep the service worker alive until the notification is created.
  event.waitUntil(
    // Show a notification with title 'Level' and use the payload
    // as the body.
    self.registration.showNotification('Level', {
      body: payload.body || '',
      tag: payload.tag
    })
  );
});
