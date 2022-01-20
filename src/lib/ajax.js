import { Modal } from './modal'
export { post }

function post(path,
  params,
  successCallback,
  errorCallback = false,
  finallyCallback = () => {}) {
  fetch(path, {
    method: 'POST',
    body: JSON.stringify(params),
    headers: { 'Content-Type': 'application/json' }
  }).then(res => {
    if (res.status == 201) {
      return false;
    } else {
      return res.text();
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
    finallyCallback();
  }).catch((error_message) => {
    if (errorCallback) {
      errorCallback(error_message);
    } else {
      new Modal('Error', error_message).display();
    }
    finallyCallback();
  });
}
