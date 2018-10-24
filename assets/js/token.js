export const getInitialApiToken = () => {
  return document.head.querySelector("meta[name='api_token']").content;
};

export const getCsrfToken = () => {
  return document.head.querySelector("meta[name='csrf_token']").content;
};

export const fetchApiToken = () => {
  return new Promise((resolve, reject) => {
    fetch("/api/tokens", { method: "POST" })
      .then(response => {
        if (response.status == 201) {
          response
            .json()
            .then(data => resolve(data.token))
            .catch(reject);
        } else {
          reject({
            reason: "unauthorized",
            response: response
          });
        }
      })
      .catch(reject);
  });
};
