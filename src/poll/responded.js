import { Modal } from '../lib/modal'
import { post } from '../lib/ajax'

class Poll {
  static domLoaded() {
    const deleteButton = document.getElementById('delete-response');
    const hashID = deleteButton.getAttribute('data-id');
    deleteButton.addEventListener('click', () => {
      const modal = new Modal(
        'Are you sure?',
        'You can still enter a new response after deleting.', {
        'Cancel': {
          classes: ['secondary']
        },
        'Do It': {
          callback: () => {
            post('/poll/remove_responses',
              { hash_id: hashID },
              () => location.reload()); // successCallback
          },
          classes: ['primary']
        }
      }).display();
    })
  }
}

document.addEventListener("DOMContentLoaded", () => Poll.domLoaded());
