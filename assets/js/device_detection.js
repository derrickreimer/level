export function isMobile() {
  if (navigator.userAgent.match(/Mobi/)) {
    return true;
  }

  if ('screen' in window && window.screen.width < 1366) {
    return true;
  }

  var connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
  if (connection && connection.type === 'cellular') {
    return true;
  }

  return false;
}
