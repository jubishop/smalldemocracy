import { Editable } from '../lib/editable'
import { Modal } from '../lib/modal'

class Group {
  static domLoaded() {
    // Extract group `hashid` first.
    const listElement = document.getElementById('member-list');
    const hashID = listElement.getAttribute("hash-id");

    // Edit name.
    const nameContainer = document.getElementById('group-name');
    const editGroupButton = document.getElementById('edit-group-button');
    editGroupButton.addEventListener('click', () => {
      const textElement = document.querySelector('#group-name h2');
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
          fetch('/group/name', {
            method: 'POST',
            body: JSON.stringify({
              hash_id: hashID,
              name: inputElement.value.trim()
            }),
            headers: { 'Content-Type': 'application/json' }
          }).then(res => {
            if (res.status == 201) {
              return false;
            } else {
              return res.text();
            }
          }).then(error_message => {
            if (error_message) {
              alert('Error: ' + error_message);
            } else {
              inputElement.remove();
              const h2Element  = document.createElement('h2');
              h2Element.textContent = inputElement.value.trim();
              nameContainer.appendChild(h2Element);
              nameContainer.appendChild(editGroupButton);
            }
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
    new Editable(
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
          email: elementToDelete.querySelector('p').textContent.trim()
        }
      },
      {
        inputType: 'email',
        placeholderText: 'Add member'
      });

    // Delete group.
    const deleteButton = document.getElementById('delete-group');
    deleteButton.addEventListener('click', () => {
      new Modal('hello', 'world').display();
      console.log("delete group");
    });
  }
}

document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
