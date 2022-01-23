import { EditableList } from '../lib/editable_list'
import { Modal } from '../lib/modal'
import { post } from '../lib/ajax'

class Group {
  static domLoaded() {
    // Extract group `hashid` first.
    const listElement = document.getElementById('member-list');
    const hashID = listElement.getAttribute("data-id");

    // Edit name.
    const nameContainer = document.getElementById('group-name');
    const editGroupButton = document.getElementById('edit-group-button');
    editGroupButton.addEventListener('click', () => {
      const textElement = nameContainer.firstElementChild;
      textElement.remove();
      editGroupButton.remove();
      const inputElement = document.createElement('input');
      inputElement.value = textElement.textContent.trim();
      nameContainer.appendChild(inputElement);
      inputElement.focus();
      inputElement.addEventListener('keydown', (event) => {
        if (event.key == "Enter") {
          event.preventDefault();
          return false;
        }
      });
      inputElement.addEventListener("keyup", (event) => {
        if (event.key == "Enter") {
          event.preventDefault();
          inputElement.disabled = true;
          post('/group/name', {
            hash_id: hashID,
            name: inputElement.value.trim()
          }, () => { // successCallback
            inputElement.remove();
            const h2Element = document.createElement('h2');
            h2Element.textContent = inputElement.value.trim();
            const createLink = document.getElementById('create-link');
            createLink.innerHTML =
              `Create new poll for <em>${inputElement.value}</em>`;
            nameContainer.appendChild(h2Element);
            nameContainer.appendChild(editGroupButton);
          }, (error_message) => { // errorCallback
            new Modal('Error', error_message).display();
            inputElement.disabled = false;
          });
          return false;
        }
      });
    });

    // Add and remove members.
    const elementXPath = document.evaluate(
      "//li[@class='editable' and not(./div)]", document);
    const elements = [];
    let element = elementXPath.iterateNext();
    while (element) {
      elements.push(element);
      element = elementXPath.iterateNext()
    }
    new EditableList(
      listElement,
      elements,
      document.getElementById('add-member'),
      '/group/add_member',
      '/group/remove_member',
      (memberEmailToAdd) => {
        return {
          hash_id: hashID,
          email: memberEmailToAdd.trim(),
        }
      },
      (elementToDelete) => {
        return {
          hash_id: hashID,
          email: elementToDelete.firstElementChild.textContent.trim()
        }
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

document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
