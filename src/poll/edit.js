import { EditableList } from '../lib/editable_list'
import { EditableField } from '../lib/editable_field'
import { Modal } from '../lib/modal'
import { post } from '../lib/ajax'

class Poll {
  static domLoaded() {
    // Extract poll `hashid` first.
    const choicesList = document.getElementById('choices');
    const hashID = choicesList.getAttribute("data-id");
    console.log(hashID);

    // Edit name.
    new EditableField(
      document.getElementById('group-name'),
      document.getElementById('edit-group-button'),
      '/group/name',
      (textContent) => { // editCallback
        return {
          hash_id: hashID,
          name: textContent
        };
      },
      (textContent) => { // successCallback
        const createLink = document.getElementById('create-link');
        createLink.innerHTML = `Create new poll for <em>${textContent}</em>`;
      }
    );

    // Add and remove members.
    new EditableList(
      listElement,
      getElementsByXPath("//li[@class='editable' and not(./div)]"),
      document.getElementById('add-member'),
      '/group/add_member',
      '/group/remove_member',
      (memberEmailToAdd) => {
        return {
          hash_id: hashID,
          email: memberEmailToAdd.trim(),
        };
      },
      (elementToDelete) => {
        return {
          hash_id: hashID,
          email: elementToDelete.firstElementChild.textContent.trim()
        };
      },
      {
        inputType: 'email',
        placeholderText: 'Add member'
      });

    // Delete group.
    const deleteButton = document.getElementById('delete-group');
    deleteButton.addEventListener('click', () => {
      const modal = new Modal(
        'Are you sure?',
        "Deleting this group will also delete all it's polls", {
        'Cancel': {
          classes: ['secondary']
        },
        'Do It': {
          callback: () => {
            post('/group/destroy',
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

document.addEventListener("DOMContentLoaded", () => Poll.domLoaded());
