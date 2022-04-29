import { Modal } from './lib/modal'
import { post } from './lib/ajax'

class API {
  static domLoaded() {
    const newAPIKeyButton = document.getElementById('new-api-key');
    newAPIKeyButton.addEventListener('click', () => {
      const modal = new Modal(
        'Are you sure?',
        'Your old key will no longer be usable.', {
        'Cancel': {
          classes: ['secondary']
        },
        'Do It': {
          callback: () => {
            post('/api/key/new',
              {}, // params
              () => window.location.reload(), // successCallback
              false, // errorCallback
              () => modal.close()); // finallyCallback
          },
          classes: ['primary']
        }
      }).display();
    });

    const apiKey = document.getElementById('api-key').textContent;
    const copyKeyButton = document.getElementById('copy-api-key');
    copyKeyButton.addEventListener('click', () => {
      navigator.clipboard.writeText(apiKey);
    });
  }
}

document.addEventListener("DOMContentLoaded", () => API.domLoaded());
