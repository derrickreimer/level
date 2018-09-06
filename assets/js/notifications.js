const isSupported = () => {
  if (!('serviceWorker' in navigator)) return false;
  if (!('PushManager' in window)) return false;
  return true;
};

export function initialize() {
  if (!isSupported()) return;

  // TODO: do the work
};
