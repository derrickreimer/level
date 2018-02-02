export const getApiToken = () => {
  return document.head.querySelector("meta[name='api_token']").content;
};

export const getCsrfToken = () => {
  return document.head.querySelector("meta[name='csrf_token']").content;
};
