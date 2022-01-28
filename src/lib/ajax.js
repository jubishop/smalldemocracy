import { Modal } from './modal'
export { post }

function post(path,
  params,
  successCallback = () => {},
  errorCallback = false,
  finallyCallback = () => {}) {
  fetch(path, {
    method: 'POST',
    body: JSON.stringify(params),
    headers: { 'Content-Type': 'application/json' }
  }).then(response => {
    if (response.status == 201) {
      return undefined;
    } else {
      return response.text();
    }
  }).then(error_message => {
    if (error_message) {
      if (errorCallback) {
        errorCallback(error_message);
      } else {
        new Modal('Error', error_message).display();
      }
    } else {
      successCallback();
    }
  }).catch(error_message => {
    if (errorCallback) {
      errorCallback(error_message);
    } else {
      new Modal('Error', error_message).display();
    }
  }).finally(() => {
    finallyCallback();
  });
}
