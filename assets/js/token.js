export const getApiToken = () => {
  return document.head.querySelector("meta[name='api_token']").content;
};
