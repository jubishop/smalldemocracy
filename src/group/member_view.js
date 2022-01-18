import { Modal } from '../lib/modal'
import { post } from '../lib/ajax'

class Group {
  static domLoaded() {
    // Extract group `hashid` first.
    const listElement = document.getElementById('member-list');
    const hashID = listElement.getAttribute("data-id");

    // Leave group.
    const leaveButton = document.getElementById('leave-group');
    leaveButton.addEventListener('click', () => {
      const modal = new Modal(
        'Leave Group',
        'Are you sure you want to leave this group?',
        {
          'Cancel': {
            classes: ['secondary']
          },
          'Do It': {
            callback() {
              post('/group/leave',
                { hash_id: hashID },
                () => window.location.replace('/'), // successCallback
                false, // errorCallback
                () => modal.close()); // finallyCallback
            },
            classes: ['primary']
          }
        }).display();
    });
  }
}

document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
